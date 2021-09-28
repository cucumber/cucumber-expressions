GO_SOURCE_FILES := $(wildcard *.go)

default: .linted .tested
.PHONY: default

.linted: $(GO_SOURCE_FILES)
	gofmt -w $^
	touch $@

.tested: $(GO_SOURCE_FILES)
	go test ./...
	touch $@

update-dependencies:
	go get -u && go mod tidy
.PHONY: update-dependencies

clean:
	rm -rf .linted .tested
.PHONY: clean

