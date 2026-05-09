# Makefile Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a Swift-enhanced Makefile for build, test, and release management.

**Architecture:** A standard Makefile using .PHONY targets to wrap Swift Package Manager commands and Git commands for tagging.

**Tech Stack:** Make, Swift PM, Git.

---

### Task 1: Create Makefile

**Files:**
- Create: `Makefile`

- [ ] **Step 1: Write Makefile content**

```makefile
.PHONY: help build test clean tag push-tag release

REMOTE ?= origin

help:
	@echo "Usage:"
	@echo "  make build             - Compile the project"
	@echo "  make test              - Run all tests"
	@echo "  make clean             - Remove build artifacts"
	@echo "  make tag VERSION=v1.0.0      - Create a local git tag"
	@echo "  make push-tag VERSION=v1.0.0 - Push the tag to $(REMOTE)"
	@echo "  make release VERSION=v1.0.0  - Tag and push in one command"

build:
	swift build

test:
	swift test

clean:
	swift package clean

tag:
	@test -n "$(VERSION)" || (echo "VERSION is required, e.g. make tag VERSION=v1.0.0" && exit 1)
	git tag $(VERSION)

push-tag:
	@test -n "$(VERSION)" || (echo "VERSION is required, e.g. make push-tag VERSION=v1.0.0" && exit 1)
	git push $(REMOTE) $(VERSION)

release: tag push-tag
```

- [ ] **Step 2: Verify help output**

Run: `make help`
Expected: PASS (Displays usage menu)

- [ ] **Step 3: Verify build target**

Run: `make build`
Expected: PASS (Swift build succeeds)

- [ ] **Step 4: Verify clean target**

Run: `make clean`
Expected: PASS (Swift package clean succeeds)

- [ ] **Step 5: Verify tag validation**

Run: `make tag`
Expected: FAIL (Displays "VERSION is required" error)

- [ ] **Step 6: Commit**

```bash
git add Makefile docs/
git commit -m "chore: add Swift-enhanced Makefile"
```
