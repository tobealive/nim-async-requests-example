#? replace(sub = "\t", by = "  ")
import asyncdispatch, httpclient, strformat, times, strutils, tables, sequtils

const
	url_source = "https://gist.githubusercontent.com/tobealive/b2c6e348dac6b3f0ffa150639ad94211/raw/31524a7aac392402e354bced9307debd5315f0e8/100-popular-urls.txt"
	seperator = "-------------------------------------------------------------------------------"

type 
	ResultStatus = enum success, error, timeout, pending
	TestResult = Table[string, tuple[status: ResultStatus, transferred: float, time: float]]
	Stats = tuple[successes: int, errors: int, timeouts: int, transferred: float, time: float]

var
	results: TestResult
	summary: Stats
	outputs: seq[string]

let
	iterations = 10
	single_source = false
	response_timeout = 3000
	verbose = true


proc prep_urls(): seq[string] =
	if single_source:
		var urls: seq[string]
		for i in 0..<100:
			urls.add(&"google.com/search?q={i}")
		return urls
	try:
		var urls = newHttpClient().getContent(url_source).splitLines.deduplicate()
		if urls.len > 100:
			urls.setLen(100)
		return urls
	except Exception as e:
		echo &"Error: {e.name}"


proc get_http_resp(client: AsyncHttpClient, url: string): Future[string] {.async.} =
	try:
		result = await client.getContent(&"http://www.{url}")
		if results[url].status != timeout:
			results[url].status = success
		results[url].transferred = result.len.float
		return ""
	except Exception as e:
		results[url].status = error
		return &"Error: {e.name}"


proc spawn_requests(urls: seq[string]) {.async.} =
	var futures: seq[Future[string]]
	for url in urls:
		var client = newAsyncHttpClient()
		futures.add client.get_http_resp(url)

	for i in 0..<urls.len:
		let url = urls[i]
		let start_time = epochTime()

		if await futures[i].withTimeout(response_timeout):
			let output = await futures[i]
			results[url].time = epochTime() - start_time
			if verbose:
				echo &"{url}: - Transferred: {results[url].transferred} Bytes. Time: {results[url].time:.4f}s. {output}"

		else:
			results[url].time = epochTime() - start_time
			results[urls[i]].status = timeout
			if verbose:
				echo &"Timeout: {urls[i]} Time: {results[url].time:.4f}s"

proc eval(): Stats =
	var stats: Stats

	for key, val in results:
		stats.transferred += val.transferred
		summary.transferred += val.transferred
		case val.status:
			of success:
				stats.successes += 1
				summary.successes += 1
			of error:
				stats.errors += 1
				summary.errors += 1
			of timeout:
				stats.timeouts += 1
				summary.timeouts += 1
			else: 
				continue
			
	stats.transferred = stats.transferred.float/(1024 * 1024)
			
	return stats

proc main() =
	let urls = prep_urls()
	echo "Starting requests..."

	for i in 1..iterations:
		echo &"Run: {i}/{iterations}"

		for url in urls:
			results[url] = (status: pending, transferred: 0.0, time: 0.0)

		let start_time = epochTime()
		waitFor spawn_requests(urls)
		let end_time = epochTime()

		var stats = eval()
		stats.time = end_time - start_time
		summary.time += stats.time

		let output = &"{i}: Time: {stats.time:.2f}s. Sent: {stats.successes + stats.errors + stats.timeouts}. Successful: {stats.successes}. Errors: {stats.errors}. Timeouts: {stats.timeouts}. Transferred {stats.transferred:.2f} MB ({stats.transferred/stats.time:.2f} MB/s)."
		outputs.add(output)
		
		if verbose:
			echo &"{seperator}\n{output}\n"

	if outputs.len <= 1 and verbose:
		return

	echo &"{seperator}"

	for output in outputs:
		echo &"{output}"

	summary.transferred = summary.transferred/(1024 * 1024)

	echo &"""{seperator}
Runs: {iterations}. Average Time: {summary.time / float(outputs.len):.2f}s. Total Errors: {summary.errors}. Total Timeouts: {summary.timeouts}. Transferred: {summary.transferred:.2f} MB ({summary.transferred/summary.time:.2f} MB/s).
{seperator}
"""


main()
