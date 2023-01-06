#? replace(sub = "\t", by = "  ")
import asyncdispatch, httpclient, strformat, times, strutils

let urls = newHttpClient().getContent(
	"https://gist.githubusercontent.com/tobealive/b2c6e348dac6b3f0ffa150639ad94211/raw/31524a7aac392402e354bced9307debd5315f0e8/100-popular-urls.txt"
).splitLines()[0..99]
var durations: seq[float]
var errorNum = 0

proc getHttpResp(client: AsyncHttpClient, url: string): Future[string] {.async.} =
	try:
		result = await client.getContent(url)
		echo &"{url} - response length: {len(result)}"
	except Exception as e:
		errorNum += 1
		echo &"Error: {url} - {e.name}"

proc requestUrls(urls: seq[string]) {.async.} =
	let start = epochTime()
	echo "Starting requests..."

	var futures: seq[Future[string]]
	for url in urls:
		var client = newAsyncHttpClient()
		futures.add client.getHttpResp(&"http://www.{url}")
	for i in 0..urls.len-1:
		discard await futures[i]

	let duration = epochTime() - start
	durations.add(duration)
	echo &"Requested {len(urls)} websites in {duration}."

let iterations = 1

for i in 1..iterations:
	echo &"Iteration {i}/{iterations}"
	waitFor requestUrls(urls)

var sum = 0.0

for i, v in durations:
	sum += v
	echo &"{i+1}: {v}"
	
echo &"""
Iterations: {iterations}. Total errors: {errorNum}.
Average time to request {len(urls)} websites: {sum / float(durations.len)}.
"""
