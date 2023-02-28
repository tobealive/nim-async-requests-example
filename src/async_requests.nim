#? replace(sub = "\t", by = "  ")
import asyncdispatch, httpclient, strformat, times, strutils, sequtils, sugar

let
	url_source = "https://gist.githubusercontent.com/tobealive/b2c6e348dac6b3f0ffa150639ad94211/raw/3db61fe72e1ce6854faa025298bf4cdfd2b2f250/100-popular-urls.txt"
	seperator = "-".repeat(80)
	iterations = 10
	single_source = false
	response_timeout = 5000
	verbose = true

type
	Stats = tuple[successes: int, errors: int, timeouts: int, transferred: float, time: float]
	ResultStatus = enum success, error, timeout, pending
	TestResult = tuple[url: string, status: ResultStatus, transferred: int, response_time: float,
			process_time: float]

var
	summary: Stats
	outputs: seq[string]


proc prep_urls(): seq[string] =
	if single_source:
		let urls = collect newSeq: (for i in 1..100: (&"google.com/search?q={i}"))
		return urls
	try:
		var urls = newHttpClient().getContent(url_source).splitLines.deduplicate()
		if urls.len > 100:
			urls.setLen(100)
		return urls
	except Exception as e:
		echo &"Error: {e.name}"


proc get_http_resp(client: AsyncHttpClient, test_item: TestResult): Future[TestResult] {.async.} =
	var test_result = test_item
	# this tracks the time to process, not the time until response
	let start_time = epochTime()

	try:
		let result = await client.getContent(&"http://www.{test_item.url}")
		test_result.status = success
		test_result.transferred = result.len
		test_result.process_time = epochTime() - start_time
		if verbose:
			echo &"{test_result.url}: - Transferred: {test_result.transferred} Bytes. Time: {test_result.process_time:.2f}s."
	except Exception as e:
		test_result.status = error
		test_result.process_time = epochTime() - start_time
		if verbose:
			echo &"Error: {test_result.url} - {e.name}. Time: {test_result.process_time:.2f}s."

	return test_result


proc spawn_requests(test_items: seq[TestResult]): Future[seq[TestResult]] {.async.} =
	var futures: seq[Future[TestResult]]
	for test_item in test_items:
		var client = newAsyncHttpClient()
		futures.add client.get_http_resp(test_item)

	var results = test_items
	for i in 0..<results.len:

		if await futures[i].withTimeout(response_timeout):
			var result = await futures[i]
			results[i] = result
		else:
			results[i].status = timeout

	return results

proc eval(results: seq[TestResult]): Stats =
	var stats: Stats

	for res in results:
		stats.transferred += res.transferred.float
		summary.transferred += res.transferred.float
		case res.status:
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
	# prepare test items
	let test_items = collect newSeq: (for url in urls: (url: url, status: pending, transferred: 0,
			response_time: 0.0, process_time: 0.0))

	echo "Starting requests..."

	for i in 1..iterations:
		echo &"Run: {i}/{iterations}"

		let start_time = epochTime()
		let results = waitFor spawn_requests(test_items)
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
