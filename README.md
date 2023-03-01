# Nim-async-requests-example

Example in Nim that focuses on concurrent async requests.

## Test runs

```
-------------------------------------------------------------------------------
1: Time: 11.62s. Sent: 99. Successful: 86. Errors: 11. Timeouts: 2. Transferred 25.86 MB (2.23 MB/s).
2: Time: 8.15s. Sent: 99. Successful: 87. Errors: 11. Timeouts: 1. Transferred 26.61 MB (3.27 MB/s).
3: Time: 7.42s. Sent: 99. Successful: 88. Errors: 10. Timeouts: 1. Transferred 27.18 MB (3.66 MB/s).
4: Time: 7.28s. Sent: 99. Successful: 88. Errors: 10. Timeouts: 1. Transferred 26.34 MB (3.62 MB/s).
5: Time: 10.59s. Sent: 99. Successful: 87. Errors: 11. Timeouts: 1. Transferred 26.63 MB (2.51 MB/s).
6: Time: 12.19s. Sent: 99. Successful: 86. Errors: 12. Timeouts: 1. Transferred 25.37 MB (2.08 MB/s).
7: Time: 12.82s. Sent: 99. Successful: 88. Errors: 10. Timeouts: 1. Transferred 27.01 MB (2.11 MB/s).
8: Time: 8.64s. Sent: 99. Successful: 88. Errors: 10. Timeouts: 1. Transferred 27.02 MB (3.13 MB/s).
9: Time: 12.86s. Sent: 99. Successful: 87. Errors: 10. Timeouts: 2. Transferred 27.02 MB (2.10 MB/s).
10: Time: 18.95s. Sent: 99. Successful: 87. Errors: 10. Timeouts: 2. Transferred 26.92 MB (1.42 MB/s).
-------------------------------------------------------------------------------
Runs: 10. Average Time: 11.05s. Total Errors: 105. Total Timeouts: 13. Transferred: 265.96 MB (2.41 MB/s).
-------------------------------------------------------------------------------
```

---

Single source requests (for simplicity `google.com/search?q=<1..100>`)<br>
It may result in a `Too Many Requests` error repeatedly performing this amount requests.

```
Time: 2.90s. Sent: 100. Successful: 100. Errors: 0. Timeouts: 0. Transferred 10.85 MB (3.74 MB/s).
```

---

If you have thoughts on how to improve performance, please feel free to share them the discussions or submit a pull request.

## Equivalents in other languages

- Python: https://github.com/tobealive/python-async-requests-example
- Haskell: https://github.com/tobealive/haskell-async-requests-example
