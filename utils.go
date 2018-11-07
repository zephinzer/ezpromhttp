package ezpromhttp

import (
	"fmt"
	"net/url"
	"os"
	"path"
)

var hostname = ""

func createURL(baseURL string, pathURL string) string {
	returnURL, err := url.Parse(baseURL)
	if err != nil {
		panic(err)
	}
	returnURL.Path = path.Join(returnURL.Path, pathURL)
	return returnURL.String()
}

func getHostname() string {
	if len(hostname) == 0 {
		var err error
		hostname, err = os.Hostname()
		if err != nil {
			_ = fmt.Errorf("unable to retrieve hostname - setting to unknown")
			hostname = "unknown"
		}
	}
	return hostname
}
