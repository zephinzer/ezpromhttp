# Convenience Prometheus HTTP Metrics Middleware for Go

[![Build Status](https://travis-ci.org/zephinzer/ezpromhttp.svg?branch=master)](https://travis-ci.org/zephinzer/ezpromhttp)
[![GitHub tag (latest SemVer)](https://img.shields.io/github/tag/zephinzer/ezpromhttp.svg)](https://github.com/zephinzer/ezpromhttp/releases)

Convenience middleware for adding of Prometheus HTTP metrics to a server that includes path, status, and method labels by default.

> See [this issue](https://github.com/prometheus/client_golang/issues/491) for potential performance issues.

# Scope
This middleware automatically adds convenience labels to Prometheus HTTP metrics.

The following metrics are exposed:

- `http_request_total{method="${method}",path="/x/y/z",status="xxx"}`
- `http_request_duration_ms{method="${method}",path="/x/y/z",status="xxx"}`
- `http_response_size_bytes{method="${method}",path="/x/y/z",status="xxx"}`
- `http_response_codes{status="xxx"}`

`xxx` corresponds to a HTTP status code.

`${method}` corresponds to a HTTP verb such as `get`, `post`, `put`, `delete`, *et cetera*.


# Installation

```
go get github.com/zephinzer/ezpromhttp
```

# Usage

## Import It

```go
import (
  "github.com/prometheus/client_golang/prometheus/promhttp"
  // ...
  "github.com/zephinzer/ezpromhttp"
)
```

## Summon the Middleware

Expose the Prometheus handler and instrument the main handler.

```go
func main() {
  // ... assume a main handler named `handler`
  handler.Handle("/metrics", promhttp.Handler())
  // ... other setup
  handler = ezpromhttp.InstrumentHandler(handler)
  http.ListenAndServe("0.0.0.0:8080", handler)
}
```

# License

This package is licensed under the MIT license. See [the LICENSE file](./LICENSE) for the full text.

# Contributing

You will need the following software to run the development environment based off [this boilerplate at github.com/zephinzer/goboil](https://github.com/zephinzer/goboil):

- Docker
- Make

If you don't have Docker, you'll also need:

- Go
- Python
- Dep (Go)
- Realize (Go)

## Development

### Getting Started in Development

Copy `./sample.properties` into `./Makefile.properties` and set your required values there. These configurations are mostly for production image releasing so you may not need to change anything.

## Testing

Append a `.local` to run the below on your host machine (`test.local`, `testc.local`, `testw.local`). Note that this may or may not work depending on what you have available on your host machine.

### Standalone Tests

Run `make test` to run the tests once.

### Standalone Tests with Live-Reload

Run `make testw` to run the tests in automated live-reload mode.

> Requires `python` to be installed on your machine. The script is at `./.scripts/auto-run.py` courtesy of GoConvey.

### Standalone Tests with Coverage

Run `make testc` to run the tests once and output the coverage.

## Releasing

To get the latest version of the application, use `make version.get`.

To bump the **patch** version, use `make version.bump`

To bump the **minor** version, use `make version.bump BUMP=minor`

To bump the **major** version, use `make version.bump BUMP=major`