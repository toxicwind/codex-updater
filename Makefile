SHELL := /usr/bin/env bash

.PHONY: check fmt lint

check: fmt lint

fmt:
	@shfmt -w codex codex-updater

lint:
	@shellcheck codex codex-updater
