#? replace(sub = "\t", by = "  ")
import strformat, strutils, sequtils, sugar, uri, chronos/[apps/http/httpclient, timer], stew/byteutils

let
	url_source = "https://gist.githubusercontent.com/tobealive/b2c6e348dac6b3f0ffa150639ad94211/raw/3db61fe72e1ce6854faa025298bf4cdfd2b2f250/100-popular-urls.txt"
	seperator = "-".repeat(80)
	iterations = 1
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


proc prep_urls(): Future[seq[string]] {.async.} =
	if single_source:
		let urls = collect newSeq: (for i in 1..100: (&"google.com/search?q={i}"))
		return urls
	try:
		let resp = await HttpSessionRef.new().fetch(parseUri(url_source))
		var urls = string.fromBytes(resp.data).splitLines.deduplicate()
		if urls.len > 100:
			urls.setLen(100)
		return urls
	except Exception as e:
		echo &"Error: {e.name}"


# proc retrievePage(httpSession: HttpSessionRef, url: string): Future[string] {.async.} =
proc get_http_resp(url: string): Future[TestResult] {.async.} =
	var result: TestResult = (url: url, status: pending, transferred: 0, time: 0.0)
	let start_time = Moment.now()
	let httpSession = HttpSessionRef.new(connectTimeout = timer.secs(10))
	try:
		let resp = await httpSession.fetch(parseUri(&"http://{url}"))
		let data = string.fromBytes(resp.data)
		result.status = success
		result.transferred = data.len
		result.time = millis(Moment.now() - start_time).int / 1000
		if verbose:
			# echo &"{uri} — Transferred: {result.transferred} Bytes. Time: {result.time:.2f}s."
			echo &"{url} — Transferred: {result.transferred} Bytes. Time: {result.time}s."
	except Exception as e:
		result.status = error
		result.time = millis(Moment.now() - start_time).int / 1000
		if verbose:
			echo &"ERROR: {url} — {e.name}. Time: {result.time}s."
	finally:
		# be sure to always close the session
		await httpSession.closeWait()
	
	return result


proc spawn_requests(urls: seq[string]) {.async.} =
	# let httpSession = HttpSessionRef.new(connectTimeout = timer.secs(10))
	# let futs: seq[Future[TestResult]] = collect newSeq: (for url in urls: retrievePage(session, url))
	let futs: seq[Future[TestResult]] = collect newSeq: (for url in urls: get_http_resp(url))
	let finishedFut = await allFinished(futs)
	discard allFutures finishedFut 


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
	let urls = waitFor prep_urls()
	echo "Starting requests..."

	waitFor spawn_requests(urls)
	#
	# for i in 1..iterations:
	# 	echo &"Run: {i}/{iterations}"
	#
	# 	let start_time = epochTime()
	# 	let results = waitFor spawn_requests(urls)
	# 	let end_time = epochTime()
	#
	# 	var stats = eval(results)
	# 	stats.time = end_time - start_time
	# 	summary.time += stats.time
	#
	# 	let output = (&"{i}: Time: {stats.time:.2f}s. " &
	# 						&"Sent: {stats.successes + stats.errors + stats.timeouts}. " &
	# 						&"Successful: {stats.successes}. " &
	# 						&"Errors: {stats.errors}. " &
	# 						&"Timeouts: {stats.timeouts}. " &
	# 						&"Transferred {stats.transferred:.2f} MB ({stats.transferred/stats.time:.2f} MB/s).")
	# 	outputs.add(output)
	#
	# 	if verbose:
	# 		echo &"{seperator}\n{output}\n"
	#
	# if outputs.len <= 1 and verbose:
	# 	return
	#
	# echo &"{seperator}"
	#
	# for output in outputs:
	# 	echo &"{output}"
	#
	# summary.transferred = summary.transferred/(1024 * 1024)
	#
	# echo (&"{seperator}\n" &
	# 			&"Runs: {iterations}. " &
	# 			&"Average Time: {summary.time / float(outputs.len):.2f}s. " &
	# 			&"Total Errors: {summary.errors}. " &
	# 			&"Total Timeouts: {summary.timeouts}. " &
	# 			&"Transferred: {summary.transferred:.2f} MB ({summary.transferred/summary.time:.2f} MB/s)." &
	# 			&"\n{seperator}")


main()
