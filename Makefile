-include .env

PROJECTNAME=$(shell basename "$(PWD)")
# Binary package name for release
BINARY=go_trans
VERSION=0.0.3

# Go related variables.
GOBASE=$(shell pwd)

GOPATH :=$(shell echo ${GOPATH})
# Go binary store place.
GOBIN=$(GOBASE)/bin
GORELEASE=$(GOBASE)/release
GOFILES=$(wildcard *.go)
GOBUILD_RACE=go build -race -o 
GOBUILD=go build -o

# Redirect error output to a file, so we can show it in development mode.
STDERR=/tmp/.$(PROJECTNAME)-stderr.txt

# PID file will keep the process id of the server
PID=/tmp/.$(PROJECTNAME).pid

# Make is verbose in Linux. Make it silent.
MAKEFLAGS += --silent


.PHONY: help
all: help
help: Makefile
	@echo
	@echo " Choose a command run in "$(PROJECTNAME)":"
	@echo
	@sed -n 's/^##//p' $< | column -t -s ':' |  sed -e 's/^/ /'
	@echo


go-compile: clean-bin go-get go-build


go-build:
	@echo "  >  Building binary..."
	@GOOS=linux GOARCH=amd64 $(GOBUILD) $(GOBIN)/$(PROJECTNAME)
	@echo "  >  Building done."


go-race-check: go-get
	@echo "  >  Race check start..."
	@GOOS=linux GOARCH=amd64 $(GOBUILD_RACE) $(GOBIN)/$(PROJECTNAME)_tmp
	@echo "  >  Race check done."
	@-rm $(GOBIN)/$(PROJECTNAME)_tmp


go-generate:
	@echo "  >  Generating dependency files..."
	@GOPATH=$(GOPATH) GOBIN=$(GOBIN) go generate $(generate)

go-get:
	@echo "  >  Checking if there is any missing dependencies..."
	#@GOPATH=$(GOPATH) GOBIN=$(GOBIN) go get $(get)

go-install:
	@GOPATH=$(GOPATH) GOBIN=$(GOBIN) go install $(GOFILES)

clean-bin:
	@echo "  >  Cleaning build cache..."
	@-rm $(GOBIN)/* 2> /dev/null


clean-release:
	@echo "  >  Cleaning release file..."
	@-rm $(GORELEASE)/* 2> /dev/null

## test: Run all test.
test:
	echo "Test Not Implement."

## install: Install missing dependencies. Runs `go get` internally. e.g; make install get=github.com/foo/bar
install: go-get

stop: stop-server

start-server: stop-server
	@echo "  >  $(PROJECTNAME) is available at $(ADDR)"
	@-$(GOBIN)/$(PROJECTNAME) 2>&1 & echo $$! > $(PID)
	@cat $(PID) | sed "/^/s/^/  \>  PID: /"

stop-server:
	@-touch $(PID)
	@-kill `cat $(PID)` 2> /dev/null || true
	@-rm $(PID)

restart-server: stop-server start-server

## compile: Compile the x86_64 Linux binary without race check.
compile:
	@-touch $(STDERR)
	@-rm $(STDERR)
	@-$(MAKE) go-compile 2> $(STDERR)
	@cat $(STDERR) | sed -e '1s/.*/\nError:\n/'  | sed 's/make\[.*/ /' | sed "/^/s/^/     /" 1>&2


## clean: Clean build files and release file.
clean: clean-bin clean-release



## race: Race check.
race:
	@-touch $(STDERR)
	@-rm $(STDERR)
	@-$(MAKE) go-race-check 2> $(STDERR)
	@cat $(STDERR) | sed -e '1s/.*/\nError:\n/'  | sed 's/make\[.*/ /' | sed "/^/s/^/     /" 1>&2

## release: Release arm64 and x86_64 linux binary package.
release: clean-release
	@echo "  >  Creating release file..."
	# Build for arm linux
	@CGO_ENABLED=0 GOOS=linux GOARCH=arm64 $(GOBUILD) $(GORELEASE)/$(BINARY)-arm64-liunx-$(VERSION)
	# Build for x86_64 linux
	@CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GOBUILD) $(GORELEASE)/$(BINARY)-x86-64-linux-$(VERSION)
