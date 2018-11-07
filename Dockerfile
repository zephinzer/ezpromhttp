# for use in development
# this image contains just the source code
FROM golang:1.11-alpine as development
# defines the name of this application
ARG PROJECT_NAME="app"
# defines extra `apk` dependencies if required
ARG APK=""
# due dilligence
RUN apk update --no-cache
# system dependencies for `go get`
RUN apk add --no-cache git curl
# installs realize for server live-reloading
RUN go get -v github.com/oxequa/realize
# installs dep for dependency management
RUN curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh
# system dependencies for `go test`
RUN apk add --no-cache gcc libc-dev python
# system dependencies for production parity
RUN apk add --no-cache ca-certificates ${APK}
# system dependencies for developer happiness
RUN apk add --no-cache bash jq ncurses
# create the caching directories for golang/dep
RUN mkdir -p /.cache/go-build && chmod 777 -R /.cache
# sets the working directory to a valid GOPATH
WORKDIR /go/src/${PROJECT_NAME}
# create autorun-tests script
COPY ./.scripts/auto-run.py /bin/autorun-tests
# assign execution permissions to autorun-tests
RUN chmod +x /bin/autorun-tests
# add convenience scripts
COPY ./.scripts/.bash_profile /root/.bash_profile
# assign execution permissions to the .bash_profile
RUN chmod +x /root/.bash_profile

# for use in the binary generating process
# this image will contain both the source code and the binaries
FROM golang:1.11-alpine as compile
# defines the name of this application
ARG PROJECT_NAME="app"
# copies everything in this directory 
COPY . /go/src/${PROJECT_NAME}
# sets the working directory to a valid GOPATH
WORKDIR /go/src/${PROJECT_NAME}
# generate the binary and create a symlink to /bin
RUN go build \
  && ln -s /go/src/${PROJECT_NAME}/${PROJECT_NAME} /bin/start
# defines the symlink `start` as the entrypoint
ENTRYPOINT [ "start" ]

# for use in the production environment
# this image contains just the binary
FROM alpine:3.8 as production
# defines the name of this application
ARG PROJECT_NAME="app"
# defines any other `apk` dependencies to install
ARG APK=""
# due dilligence
RUN apk update --no-cache
# install system level depnedencies
RUN apk add --no-cache ca-certificates ${APK}
# copies the binary from the `compile` image - no symlink required
COPY --from=compile /go/src/${PROJECT_NAME}/${PROJECT_NAME} /bin/start
# create app user so we can prevent running as root
RUN adduser -D -H app
# make /bin/start non-writable
RUN chmod 550 /bin/start && chown app:root /bin/start
# allocate a data directory for read/write by app, and also root group for openshift compatibility
RUN mkdir -p /data && chmod 770 /data && chown app:root /data
# sets the primary working directory to the root directory
WORKDIR /
# sets the user to app as a final touch
USER app
# defines the entrypoint to the system `start` command at /bin
ENTRYPOINT [ "start" ]
