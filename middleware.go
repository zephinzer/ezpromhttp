package ezpromhttp

import (
	"github.com/prometheus/client_golang/prometheus"
	"net/http"
	"strconv"
	"strings"
	"time"
)

var (
	initialized     = false
	requestCounter  *prometheus.CounterVec
	requestDuration *prometheus.HistogramVec
	responseSize    *prometheus.HistogramVec
	responseCode    *prometheus.CounterVec
)

func initializeMetricsMiddleware() {
	if initialized != true {
		requestCounter = createTotalRequestsCollector()
		prometheus.Register(requestCounter)
		requestDuration = createRequestDurationsCollector()
		prometheus.Register(requestDuration)
		responseSize = createRequestSizesCollector()
		prometheus.Register(responseSize)
		responseCode = createResponseCodesCollector()
		prometheus.Register(responseCode)
		initialized = true
	}
}

func InstrumentHandler(next http.Handler) http.Handler {
	if !initialized {
		initializeMetricsMiddleware()
	}
	return http.HandlerFunc(func(writer http.ResponseWriter, r *http.Request) {
		instrumentedWriter := &InstrumentedResponseWriter{writer, 0, 0}
		defer func(begun time.Time) {
			size := float64(instrumentedWriter.Length())
			status := strconv.Itoa(instrumentedWriter.StatusCode())
			method := strings.ToLower(r.Method)
			route := r.URL.Path
			requestCounter.WithLabelValues(method, route, status).Inc()
			requestDuration.WithLabelValues(method, route, status).Observe(float64(time.Since(begun).Seconds() * 1000))
			responseCode.WithLabelValues(status).Inc()
			responseSize.WithLabelValues(method, route, status).Observe(size)
		}(time.Now())
		next.ServeHTTP(instrumentedWriter, r)
	})
}
