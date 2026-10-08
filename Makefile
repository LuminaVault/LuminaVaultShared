.PHONY: help build test clean tag push-tag release lint

REMOTE ?= origin

help:
	@echo "Usage:"
	@echo "  make build             - Compile the project"
	@echo "  make test              - Run all tests"
	@echo "  make clean             - Remove build artifacts"
	@echo "  make tag VERSION=v1.0.0      - Create a local git tag"
	@echo "  make push-tag VERSION=v1.0.0 - Push the tag to $(REMOTE)"
	@echo "  make release VERSION=v1.0.0  - Tag and push in one command"
	@echo "  make lint              - Check SwiftFormat, SwiftLint, and Periphery"

build:
	swift build

test:
	swift test

clean:
	swift package clean

lint:
	swiftformat . --lint
	swiftlint
	periphery scan

tag:
	@test -n "$(VERSION)" || (echo "VERSION is required, e.g. make tag VERSION=v1.0.0" && exit 1)
	git tag $(VERSION)

push-tag:
	@test -n "$(VERSION)" || (echo "VERSION is required, e.g. make push-tag VERSION=v1.0.0" && exit 1)
	git push $(REMOTE) $(VERSION)

release: tag push-tag
