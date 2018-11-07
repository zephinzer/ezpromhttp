package ezpromhttp

import (
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"testing"
)

const expectedTestResponse = "ok"
const expectedStatusCode = http.StatusTeapot

func TestInstrumentedResponseWriter(t *testing.T) {
	var responseWriter InstrumentedResponseWriter
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		responseWriter = InstrumentedResponseWriter{w, 0, 0}
		responseWriter.WriteHeader(expectedStatusCode)
		responseWriter.Write([]byte(expectedTestResponse))
	}))
	url := createURL(ts.URL, "/")
	res, err := http.Get(url)
	if err != nil {
		t.Errorf("%v", err)
	}
	_response, err := ioutil.ReadAll(res.Body)
	if err != nil {
		t.Errorf("%v", err)
	}
	response := string(_response)
	res.Body.Close()
	if res.StatusCode != expectedStatusCode {
		t.Errorf("expected status code was not returned")
	}
	if response != expectedTestResponse {
		t.Errorf("expected response text was not returned")
	}
	if responseWriter.Length() != len(expectedTestResponse) {
		t.Errorf("instrumented response writer did not record the correct content length")
	}
	if responseWriter.StatusCode() != expectedStatusCode {
		t.Errorf("instrumented response writer did not record the correct status code")
	}
}
