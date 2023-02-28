#? replace(sub = "\t", by = "  ")
import asyncdispatch, httpclient, strformat, times, strutils, sequtils

const
	url_source = "https://gist.githubusercontent.com/tobealive/b2c6e348dac6b3f0ffa150639ad94211/raw/3db61fe72e1ce6854faa025298bf4cdfd2b2f250/100-popular-urls.txt"
	seperator = "-".repeat(80)

type 
	ResultStatus = enum success, error, timeout, pending
	TestResult = tuple[url: string, status: ResultStatus, transferred: int, response_time: float, process_time: float]
	Stats = tuple[successes: int, errors: int, timeouts: int, transferred: float, time: float]

var
	summary: Stats
	outputs: seq[string]

let
	iterations = 10
	single_source = false
	response_timeout = 5000
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


proc get_http_resp(client: AsyncHttpClient, test_item: TestResult): Future[TestResult] {.async.} =
	let start_time = epochTime()
	var test_item = test_item
	try:
		let result = await client.getContent(&"http://www.{test_item.url}")
		test_item.status = success
		test_item.transferred = result.len
		test_item.process_time = epochTime() - start_time
		if verbose:
			echo &"{test_item.url}: - Transferred: {test_item.transferred} Bytes. Processing Time After Response: {test_item.process_time}s."
	except Exception as e:
		test_item.status = error
		test_item.process_time = epochTime() - start_time
		echo &"Error: {test_item.url} - {e.name}. Processing Time After Response: {test_item.process_time}s."

	return test_item


proc spawn_requests(test_items: seq[TestResult]): Future[seq[TestResult]] {.async.} =
	var futures: seq[Future[TestResult]]
	for test_item in test_items:
		var client = newAsyncHttpClient()
		futures.add client.get_http_resp(test_item)

	var results = test_items
	for i in 0..<results.len:
		let start_time = epochTime()

		if await futures[i].withTimeout(response_timeout):
			var result = await futures[i]
			result.response_time = epochTime() - start_time
			results[i] = result

		else:
			results[i].response_time = epochTime() - start_time
			results[i].status = timeout
			if verbose:
				echo &"Timeout: {results[i].url} No Response After: {results[i].response_time:.4f}s"
	
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
	var test_items: seq[TestResult]
	for url in urls: 
		test_items.add((url: url, status: pending, transferred: 0, response_time: 0.0, process_time: 0.0))

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
