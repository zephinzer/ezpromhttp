package ezpromhttp

import (
	"github.com/prometheus/client_golang/prometheus"
)

var (
	variableRequestLabels = []string{"method", "path", "status"}
	variableSummaryLabels = []string{"status"}
	durationMsBuckets     = []float64{10, 50, 100, 200, 300, 500, 1000, 2000, 3000, 5000, 10000, 15000, 20000, 30000}
	sizeBytesBuckets      = []float64{1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4194304}
)

func createTotalRequestsCollector() *prometheus.CounterVec {
	return prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Namespace:   "http",
			Subsystem:   "request",
			Name:        "total",
			Help:        "Count of the requests by method, path, and status",
			ConstLabels: prometheus.Labels{"instance": getHostname()},
		},
		variableRequestLabels,
	)
}

func createRequestDurationsCollector() *prometheus.HistogramVec {
	return prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Namespace:   "http",
			Subsystem:   "request",
			Name:        "duration_ms",
			Help:        "The duration of a request in milliseconds",
			ConstLabels: prometheus.Labels{"instance": getHostname()},
			Buckets:     durationMsBuckets,
		},
		variableRequestLabels,
	)
}

func createRequestSizesCollector() *prometheus.HistogramVec {
	return prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Namespace:   "http",
			Subsystem:   "response",
			Name:        "size_bytes",
			Help:        "The size of the response in bytes",
			ConstLabels: prometheus.Labels{"instance": getHostname()},
			Buckets:     sizeBytesBuckets,
		},
		variableRequestLabels,
	)
}

func createResponseCodesCollector() *prometheus.CounterVec {
	return prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Namespace:   "http",
			Subsystem:   "response",
			Name:        "codes",
			Help:        "Summary of returned HTTP status codes",
			ConstLabels: prometheus.Labels{"instance": getHostname()},
		},
		variableSummaryLabels,
	)
}
