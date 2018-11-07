package ezpromhttp

import (
	"fmt"
	prometheusHttp "github.com/prometheus/client_golang/prometheus/promhttp"
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestInstrumentHandler(t *testing.T) {
	createTestServer(InstrumentHandler, func(ts *httptest.Server) {
		_, err := http.Get(createURL(ts.URL, "/test"))
		if err != nil {
			t.Fatalf("Error %v", err)
			return
		}
		reqURL := createURL(ts.URL, "/metrics")
		fmt.Println(reqURL)
		res, _ := http.Get(reqURL)
		_message, err := ioutil.ReadAll(res.Body)
		if err != nil {
			t.Fatalf("Error %v", err)
			return
		}
		res.Body.Close()
		metrics := string(_message)
		metricsArray := strings.Split(metrics, "\n")

		defer func() {
			if r := recover(); r != nil {
				t.Errorf("%s", r)
			}
		}()
		assertMetricExists("http_request_duration_ms_bucket", metricsArray)
		assertMetricExists("http_request_total", metricsArray)
		assertMetricExists("http_response_codes", metricsArray)
		assertMetricExists("http_response_size_bytes_bucket", metricsArray)
	})
}

func assertMetricExists(metricName string, allMetrics []string) {
	fmt.Printf("%s... ", metricName)
	metricOfInterest := getMetric(allMetrics, metricName)
	if len(metricOfInterest) == 0 {
		fmt.Println("not found")
		panic("metric `" + metricName + "` was not found")
	} else {
		fmt.Println("found")
	}
}

func createTestServer(handler func(http.Handler) http.Handler, then func(*httptest.Server)) {
	mux := http.NewServeMux()
	mux.Handle("/metrics", prometheusHttp.Handler())
	mux.Handle("/test", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("hi"))
	}))
	ts := httptest.NewServer(handler(mux))
	defer ts.Close()
	then(ts)
}

func getMetric(metrics []string, metricName string) (ret []string) {
	for _, s := range metrics {
		if strings.HasPrefix(s, metricName+"{") {
			ret = append(ret, s)
		}
	}
	return
}
