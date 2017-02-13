help:
	@echo "usage:"
	@echo "  make docker-build - build using docker container"
	@echo "  make docker-run   - run   using docker container"

docker-build:
	docker run --rm \
		-v "$$PWD":/go/src/github.com/gzl-io/gzl \
		-w /go/src/github.com/gzl-io/gzl \
		golang:1.7 go build -v

docker-run:
	docker run --rm \
		-v "$$PWD":/go/src/github.com/gzl-io/gzl \
		-w /go/src/github.com/gzl-io/gzl \
		golang:1.7 go run main.go

.PHONY: docker-build docker-run help
