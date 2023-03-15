#? replace(sub = "\t", by = "  ")
import asyncdispatch, httpclient, strformat, times, strutils, sequtils, sugar

let
	url_source = "https://gist.githubusercontent.com/tobealive/b2c6e348dac6b3f0ffa150639ad94211/raw/3db61fe72e1ce6854faa025298bf4cdfd2b2f250/100-popular-urls.txt"
	seperator = "-".repeat(80)
	iterations = 10
	single_source = false
	response_timeout = 10000
	verbose = true

type
	Stats = tuple[successes: int, errors: int, timeouts: int, transferred: float, time: float]
	ResultStatus = enum success, error, timeout, pending
	TestResult = tuple[url: string, status: ResultStatus, transferred: int, time: float]

var
	summary: Stats
	outputs: seq[string]


proc prep_urls(): seq[string] =
	if single_source:
		return collect newSeq: (for i in 1..100: (&"google.com/search?q={i}"))
	try:
		result = newHttpClient().getContent(url_source).splitLines.deduplicate()
		if result.len > 100:
			result.setLen(100)
	except Exception as e:
		echo &"Error: {e.name}"


proc get_http_resp(url: string): Future[TestResult] {.async.} =
	result.url = url
	let client = newAsyncHttpClient()
	let start_time = epochTime()

	try:
		let request = client.get(&"http://www.{url}")
		if await request.withTimeout(response_timeout):
			let resp = await request
			let body = await resp.body
			result.status = success
			result.transferred = body.len
			result.time = epochTime() - start_time
			if verbose:
				echo &"{result.url} — Transferred: {result.transferred} Bytes. Time: {result.time:.2f}s."
		else:
			result.status = timeout
			if verbose:
				echo &"TIMEOUT: {url}"
	except Exception as e:
		result.status = error
		result.time = epochTime() - start_time
		if verbose:
			echo &"ERROR: {result.url} — {e.name}. Time: {result.time:.2f}s."
	finally:
		client.close()


proc spawn_requests(urls: seq[string]): Future[seq[TestResult]] {.async.} =
	let futures: seq[Future[TestResult]] = collect newSeq: (for url in urls: get_http_resp(url))
	result = waitFor all(futures)


proc eval(results: seq[TestResult]): Stats =
	for res in results:
		result.transferred += res.transferred.float
		summary.transferred += res.transferred.float
		case res.status:
			of success:
				result.successes += 1
				summary.successes += 1
			of error:
				result.errors += 1
				summary.errors += 1
			of timeout:
				result.timeouts += 1
				summary.timeouts += 1
			else:
				continue

	result.transferred = result.transferred.float/(1024 * 1024)


proc main() =
	let urls = prep_urls()
	echo "Starting requests..."

	for i in 1..iterations:
		echo &"Run: {i}/{iterations}"

		let start_time = epochTime()
		let results = waitFor spawn_requests(urls)
		let end_time = epochTime()

		var stats = eval(results)
		stats.time = end_time - start_time
		summary.time += stats.time

		let output = (&"{i}: Time: {stats.time:.2f}s. " &
							&"Sent: {stats.successes + stats.errors + stats.timeouts}. " &
							&"Successful: {stats.successes}. " &
							&"Errors: {stats.errors}. " &
							&"Timeouts: {stats.timeouts}. " &
							&"Transferred {stats.transferred:.2f} MB ({stats.transferred/stats.time:.2f} MB/s).")
		outputs.add(output)

		if verbose:
			echo &"{seperator}\n{output}\n"

	if outputs.len <= 1 and verbose:
		return

	echo &"{seperator}"

	for output in outputs:
		echo &"{output}"

	summary.transferred = summary.transferred/(1024 * 1024)

	echo (&"{seperator}\n" &
				&"Runs: {iterations}. " &
				&"Average Time: {summary.time / float(outputs.len):.2f}s. " &
				&"Total Errors: {summary.errors}. " &
				&"Total Timeouts: {summary.timeouts}. " &
				&"Transferred: {summary.transferred:.2f} MB ({summary.transferred/summary.time:.2f} MB/s)." &
				&"\n{seperator}")


main()
