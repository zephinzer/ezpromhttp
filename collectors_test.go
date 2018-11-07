package ezpromhttp

import (
	"strings"
	"testing"
)

func TestRequestLabels(t *testing.T) {
	labels := strings.Join(variableRequestLabels, ",")
	if !strings.Contains(labels, "method") {
		t.Errorf("does not contain method")
	}
	if !strings.Contains(labels, "path") {
		t.Errorf("does not contain path")
	}
	if !strings.Contains(labels, "status") {
		t.Errorf("does not contain status")
	}
}

func TestSummaryLabels(t *testing.T) {
	labels := strings.Join(variableRequestLabels, ",")
	if !strings.Contains(labels, "status") {
		t.Errorf("does not contain status")
	}
}
