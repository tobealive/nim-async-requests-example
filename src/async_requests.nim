#? replace(sub = "\t", by = "  ")
import asyncdispatch, httpclient, strformat, times, strutils

const
	urlSource = "https://gist.githubusercontent.com/tobealive/b2c6e348dac6b3f0ffa150639ad94211/raw/31524a7aac392402e354bced9307debd5315f0e8/100-popular-urls.txt"

type Stats =
	tuple[sent: int, errors: int, successes: int, timeouts: int]

var
	stats: Stats
	summary: tuple[stats: seq[string], time: float]

let
	response_timeout = 3000
	verbose = true


proc prepareUrls(): seq[string] =
	try:
		var urls = newHttpClient().getContent(urlSource).splitLines
		if urls.len > 100:
			urls.setLen(100)
		return urls
	except Exception as e:
		echo &"Error: {e.name}"


proc getHttpResp(client: AsyncHttpClient, url: string): Future[string] {.async.} =
	stats.sent += 1
	try:
		result = await client.getContent(url)
		if verbose:
			echo &"{url} - {result.len}"
	except Exception as e:
		stats.errors += 1
		if verbose:
			echo &"Error: {url} - {e.name}"


proc spawnRequests(urls: seq[string]) {.async.} =
	var futures: seq[Future[string]]
	for url in urls:
		var client = newAsyncHttpClient()
		futures.add client.getHttpResp(&"http://www.{url}")

	for i in 0..urls.len-1:
		if await futures[i].withTimeout(response_timeout):
			stats.successes += 1
			discard await futures[i]
		else:
			stats.timeouts += 1
			if verbose:
				echo &"Timeout: http://www.{urls[i]}"


proc main() =
	let
		urls = prepareUrls()
		iterations = 5

	echo "Starting requests..."

	for i in 1..iterations:
		stats = (sent: 0, errors: 0, successes: 0, timeouts: 0)
		echo &"Iteration {i}/{iterations}"

		let start = epochTime()
		waitFor spawnRequests(urls)
		let duration = epochTime() - start
		summary.time += duration

		let outcome =
			&"{i}: Time {duration:.2f}s. Requested: {stats.sent}/{urls.len}.  Successful: {stats.successes}. Errors: {stats.errors}. Timeouts: {stats.timeouts}."
		summary.stats.add(outcome)
		if verbose:
			echo outcome

	if summary.stats.len > 1:
		echo "\n--------------------------------------------------------------------------------"

		for s in summary.stats:
			echo &"{s}"

		echo &"""
--------------------------------------------------------------------------------
Iterations: {iterations}. Average time: {summary.time / float(summary.stats.len):.2f}s. Total errors: {stats.errors}. Timeouts: {stats.timeouts}.
--------------------------------------------------------------------------------
"""


main()
