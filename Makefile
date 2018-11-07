include Makefile.properties

PROJECT_NAME=$(notdir $(CURDIR))

# http://patorjk.com/software/taag/#p=display&h=2&f=Small&t=golang
#           _                
#  __ _ ___| |__ _ _ _  __ _ 
# / _` / _ \ / _` | ' \/ _` |
# \__, \___/_\__,_|_||_\__, |
# |___/                |___/ 
#
# verbs: dkbuild, build, dep, start
# - dkbuild: docker build
# - build: go build
# - dep: dep
# - start: runs app
#
# subverbs: local, dev, prd
# - local: uses local binaries
# - dev: indicates development environment
# - prd: indicates production environment
#
# build 				- generates the binary using a docker image
# build.local 	- generates the binary using native go
# dep 					- runs the dep command in a docker image
# dep.local 		- runs the dep command using native dep
# dkbuild.dev 	- generates a development docker image
# dkbuild.prd 	- generates a production docker image
# dkbuild 			- alias for dkbuild.prd
# dkpublish.dev - publishes the development docker image
# dkpublish.prd - publishes production docker image
# dkpublish 		- alias for dkpublish.prd
# shell					- creates a shell as the root user into a running development container
# start 				- starts the application in development mode using a docker image
# start.local 	- starts the application in development mode using native go
# test					- runs the tests using a docker image
# test.local		- runs the tests using native go
# testc					- runs the tests and outputs coverage info using a docker image
# testc.local		- runs the tests and outputs coverage info using native go
# testw					- runs the tests with live-reloading of tests using a docker image
# testw.local		- runs the tests with live-reloading of tests on the local box
# version.get		- retrieves the current version from the git tags
# version.bump	- bumps the application version using git tags

build: dkbuild.dev
	docker run \
		--env PROJECT_NAME=$(PROJECT_NAME) \
		--workdir /go/src/$(PROJECT_NAME) \
		-v $(CURDIR):/go/src/$(PROJECT_NAME) \
		-u $$(id -u) \
		--entrypoint=go \
		$(PROJECT_NAME):latest-dev \
		build

build.local:
	@GOPATH="$$(pwd)" go build

dep: dkbuild.dev
	@if [ -z "${ARGS}" ]; then \
		$(MAKE) log.error MSG='"ARGS" parameter not specified.'; \
		exit 1; \
	else \
		docker run \
			--workdir /go/src/$(PROJECT_NAME) \
			-v $(CURDIR):/go/src/$(PROJECT_NAME) \
			-v $(CURDIR)/.cache:/.cache \
			-u $$(id -u) \
			--entrypoint=dep \
			$(PROJECT_NAME):latest-dev \
			${ARGS}; \
	fi

dep.local:
	@if [ -z "${ARGS}" ]; then \
		$(MAKE) log.error MSG='"ARGS" parameter not specified.'; \
		exit 1; \
	fi
	-@$(eval _GOPATH=$(shell go env GOPATH))
	@mkdir -p ${_GOPATH}/src
	-@rm -rf ${_GOPATH}/src/${PROJECT_NAME}
	@ln -s $(CURDIR) ${_GOPATH}/src/${PROJECT_NAME}
	@cd ${_GOPATH}/src/${PROJECT_NAME} \
		&& dep ${ARGS}
	-@rm -rf ${_GOPATH}/src/${PROJECT_NAME}

dkbuild:
	@$(MAKE) dkbuild.prd

dkbuild.dev:
	-@mkdir -p $(CURDIR)/.cache/go-build
	@docker build \
		--file $(CURDIR)/Dockerfile \
		--target development \
		--tag $(PROJECT_NAME):latest-dev .

dkbuild.prd:
	@docker build \
		--file $(CURDIR)/Dockerfile \
		--target production \
		--tag $(PROJECT_NAME):latest .

dkpublish:
	@$(MAKE) dkpublish.prd VERSION=${VERSION}

dkpublish.dev: dkbuild.dev
	@if [ -z "$(DOCKER_IMAGE)" ]; then \
		$(MAKE) dkpublish._cmd IMAGE_NAME=$(PROJECT_NAME) VERSION=${VERSION} TAG=latest-dev POSTFIX=-dev; \
	else \
		$(MAKE) dkpublish._cmd IMAGE_NAME=$(PROJECT_NAME) VERSION=${VERSION} TAG=latest-dev POSTFIX=-dev; \
	fi

dkpublish.prd: dkbuild.prd
	@if [ -z "$(DOCKER_IMAGE)" ]; then \
		$(MAKE) dkpublish._cmd IMAGE_NAME=$(PROJECT_NAME) VERSION=${VERSION} TAG=latest; \
	else \
		$(MAKE) dkpublish._cmd IMAGE_NAME=$(DOCKER_IMAGE) VERSION=${VERSION} TAG=latest; \
	fi

dkpublish._cmd:
	$(eval GIT_TAG_VERSION=$(shell docker run -v "$(CURDIR):/app" zephinzer/vtscripts:latest get-latest -q))
	if [ -z "${VERSION}" ]; then \
		$(MAKE) log.info MSG="Publishing $(DOCKER_REGISTRY)/$(DOCKER_NAMESPACE)/${IMAGE_NAME}:(${TAG}|$(GIT_TAG_VERSION))${POSTFIX}..."; \
		$(MAKE) log.warn MSG="  (hit ctrl+c within 3 seconds to stop this from happening)"; sleep 3; \
		$(MAKE) dkpublish._tagandpush FROM="$(PROJECT_NAME):${TAG}${POSTFIX}" TO="$(DOCKER_REGISTRY)/$(DOCKER_NAMESPACE)/${IMAGE_NAME}:${TAG}${POSTFIX}"; \
		$(MAKE) dkpublish._tagandpush FROM="$(PROJECT_NAME):${TAG}${POSTFIX}" TO="$(DOCKER_REGISTRY)/$(DOCKER_NAMESPACE)/${IMAGE_NAME}:$(GIT_TAG_VERSION)${POSTFIX}"; \
	else \
		$(MAKE) log.info MSG="Publishing $(DOCKER_REGISTRY)/$(DOCKER_NAMESPACE)/${IMAGE_NAME}:(${TAG}|${VERSION})${POSTFIX}..."; \
		$(MAKE) log.warn MSG="  (hit ctrl+c within 3 seconds to stop this from happening)"; sleep 3; \
		$(MAKE) dkpublish._tagandpush FROM="$(PROJECT_NAME):${TAG}${POSTFIX}" TO="$(DOCKER_REGISTRY)/$(DOCKER_NAMESPACE)/${IMAGE_NAME}:${TAG}${POSTFIX}"; \
		$(MAKE) dkpublish._tagandpush FROM="$(PROJECT_NAME):${TAG}${POSTFIX}" TO="$(DOCKER_REGISTRY)/$(DOCKER_NAMESPACE)/${IMAGE_NAME}:${VERSION}${POSTFIX}"; \
	fi

dkpublish._tagandpush:
	docker tag ${FROM} ${TO}
	docker push ${TO}

shell:
	docker exec  -u root -it $(PROJECT_NAME)-dev /bin/bash -l

start:
	-@touch $(CURDIR)/.env
	-@$(eval ENV_PORT=$(shell cat $(CURDIR)/.env | grep 'PORT' | cut -f 2 -d '='))
	@if [ -z "${PORT}" ]; then \
		if [ -z "${ENV_PORT}" ]; then \
			$(MAKE) start._cmd PORT=8080; \
		else \
			$(MAKE) start._cmd PORT=$(ENV_PORT); \
		fi \
	else \
		$(MAKE) start._cmd PORT=$(PORT); \
	fi

start.local:
	-@realize start --run main.go

start._cmd: dkbuild.dev
	-@if [ -z "${PORT}" ]; then \
		$(MAKE) log.error MSG='"PORT" parameter not specified.'; \
		exit 1; \
	else \
		$(MAKE) log.info MSG="PORT was set to ${PORT}"; \
		docker stop $(PROJECT_NAME)-dev; \
		docker rm $(PROJECT_NAME)-dev; \
		docker run \
			--env-file $(CURDIR)/.env \
			--env PORT=${PORT} \
			--workdir /go/src/$(PROJECT_NAME) \
			-p ${PORT}:${PORT} \
			-v $(CURDIR):/go/src/$(PROJECT_NAME) \
			-v $(CURDIR)/.cache:/.cache \
			-u $$(id -u) \
			--entrypoint=realize \
			--name $(PROJECT_NAME)-dev \
			$(PROJECT_NAME):latest-dev \
			start --no-config --run main.go; \
	fi

test: dkbuild.dev
	-@docker stop $(PROJECT_NAME)-test
	-@docker rm $(PROJECT_NAME)-test
	docker run \
		--env-file $(CURDIR)/.env \
		--workdir /go/src/$(PROJECT_NAME) \
		-v $(CURDIR):/go/src/$(PROJECT_NAME) \
		-v $(CURDIR)/.cache:/.cache \
		-u $$(id -u) \
		--entrypoint=go \
		--name $(PROJECT_NAME)-test \
		$(PROJECT_NAME):latest-dev \
		test -v

test.local:
	-@go test -v

testc: dkbuild.dev
	-@mkdir -p ./coverage
	-@docker stop $(PROJECT_NAME)-test
	-@docker rm $(PROJECT_NAME)-test
	docker run \
		--env-file $(CURDIR)/.env \
		--workdir /go/src/$(PROJECT_NAME) \
		-v $(CURDIR):/go/src/$(PROJECT_NAME) \
		-v $(CURDIR)/.cache:/.cache \
		-u $$(id -u) \
		--entrypoint=go \
		--name $(PROJECT_NAME)-test \
		$(PROJECT_NAME):latest-dev \
		test -v -coverprofile=coverage/coverage.out

testc.local:
	-@mkdir -p ./coverage
	-@go test -coverprofile=coverage/coverage.out

testw: dkbuild.dev
	-@docker stop $(PROJECT_NAME)-test
	-@docker rm $(PROJECT_NAME)-test
	docker run \
		--env-file $(CURDIR)/.env \
		--workdir /go/src/$(PROJECT_NAME) \
		-v $(CURDIR):/go/src/$(PROJECT_NAME) \
		-v $(CURDIR)/.cache:/.cache \
		-u $$(id -u) \
		--entrypoint=autorun-tests \
		--name $(PROJECT_NAME)-test \
		$(PROJECT_NAME):latest-dev

testw.local:
	-@python ./.scripts/auto-run.py promhttp

version.get:
	@docker run -v "$$(pwd):/app" zephinzer/vtscripts:latest get-latest -q

version.bump:
	@if [ -z "${BUMP}" ]; then \
		docker run -v "$$(pwd):/app" zephinzer/vtscripts:latest iterate patch -i; \
	else \
		docker run -v "$$(pwd):/app" zephinzer/vtscripts:latest iterate ${BUMP} -i; \
	fi

# src: http://patorjk.com/software/taag/#p=display&h=2&f=Small&t=pretty%20logging
#               _   _          _                _           
#  _ __ _ _ ___| |_| |_ _  _  | |___  __ _ __ _(_)_ _  __ _ 
# | '_ \ '_/ -_)  _|  _| || | | / _ \/ _` / _` | | ' \/ _` |
# | .__/_| \___|\__|\__|\_, | |_\___/\__, \__, |_|_||_\__, |
# |_|                   |__/         |___/|___/       |___/ 
#
# verbs: debug, info, warn, error
#
# log.debug	- blue output
# log.info 	- green output
# log.warn 	- yellow output
# log.error - red output
log.debug:
	-@printf -- "\033[36m\033[1m_ [DEBUG] ${MSG}\033[0m\n"
log.info:
	-@printf -- "\033[32m\033[1m>  [INFO] ${MSG}\033[0m\n"
log.warn:
	-@printf -- "\033[33m\033[1m?  [WARN] ${MSG}\033[0m\n"
log.error:
	-@printf -- "\033[31m\033[1m! [ERROR] ${MSG}\033[0m\n"
