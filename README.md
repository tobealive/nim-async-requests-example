# Nim-async-requests-example

Example in Nim that focuses on concurrent / parallel async requests.

Supplementary information:

- The geographical location from which the requests were sent was Germany
- Response errors do not increase the request time. On the contrary, they are handled immediately. Nevertheless, the response quota when using Nim should be improved.

```
1: 14.87s
2: 9.22s
3: 8.32s
4: 9.56s
5: 13.71s
6: 8.30s
7: 7.99s
8: 8.87s
9: 8.99s
10: 9.94s
Iterations: 10. Total errors: 94.
Average time to request 100 websites: 9.98s.
```

Request only `google.com/search?q=%s` (where the search queries are the numbers from 1 to 100)<br>
When using this nim example it may result in a `Too Many Requests` error if this amount of Google searches are performed repeatedly.

```
Iterations: 1. Total errors: 0.
Time to request 100 google searches: 3.75s.
```

---

If you have thoughts on how to improve performance, please feel free to share them the discussions or submit a pull request.

## Equivalents in other languages

<details>
<summary><b>Python</b> - <code>Average time to request 100 websites: 7.92s.</code></summary>

<br>

Repository: https://github.com/tobealive/python-async-requests-example

```
1: 6.04s
2: 6.87s
3: 6.82s
4: 6.38s
5: 10.75s
6: 6.41s
7: 6.02s
8: 11.53s
9: 11.07s
10: 7.35s

Iterations: 10. Total errors: 10.
Average time to request 100 websites: 7.92s.
```

Request only `google.com/search?q=%s` (where the search queries are the numbers from 1 to 100)

```
Iterations: 1. Total errors: 0.
Time to request 100 google searches: 1.38s.
```

</details>
