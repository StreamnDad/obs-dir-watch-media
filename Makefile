SHELL := /bin/bash

PRESET ?= default
BUILD_DIR ?= build
OBS_INCLUDE_DIR ?=
OBS_LIBRARY ?=

.PHONY: help setup find-obs-dev-paths configure build install run check-plugin-log dev clean reconfigure

help:
	@echo "obs-dir-watch-media development targets"
	@echo ""
	@echo "Usage:"
	@echo "  make <target> [PRESET=default|debug|ninja] [OBS_INCLUDE_DIR=...] [OBS_LIBRARY=...]"
	@echo ""
	@echo "Targets:"
	@echo "  find-obs-dev-paths   Search for OBS headers/libs and print configure guidance"
	@echo "  configure            Configure CMake (passes OBS_INCLUDE_DIR/OBS_LIBRARY if set)"
	@echo "  build                Build plugin"
	@echo "  install              Install plugin artifact to OBS user plugin folder"
	@echo "  run                  Launch OBS with verbose logging"
	@echo "  check-plugin-log     Check latest OBS log for plugin load lines"
	@echo "  dev                  configure + build"
	@echo "  clean                Remove build directory"
	@echo "  reconfigure          clean + configure"

find-obs-dev-paths:
	./scripts/find-obs-dev-paths.sh

configure:
	@if [[ -n "$(OBS_INCLUDE_DIR)" && -n "$(OBS_LIBRARY)" ]]; then \
		./scripts/configure.sh "$(PRESET)" -DOBS_INCLUDE_DIR="$(OBS_INCLUDE_DIR)" -DOBS_LIBRARY="$(OBS_LIBRARY)"; \
	else \
		./scripts/configure.sh "$(PRESET)"; \
	fi

build:
	./scripts/build.sh "$(PRESET)"

install:
	./scripts/install-dev-plugin.sh "$(BUILD_DIR)"

run:
	./scripts/run-obs.sh

check-plugin-log:
	@LOG=$$(ls -t ~/Library/Application\ Support/obs-studio/logs/*.txt 2>/dev/null | head -1); \
	if [ -z "$$LOG" ]; then echo "No OBS log files found"; exit 1; fi; \
	echo "Latest log: $$LOG"; \
	grep -i "dir.watch\|dir_watch" "$$LOG" || echo "No dir-watch-media entries found in log"

dev: configure build

clean:
	rm -rf "$(BUILD_DIR)"

reconfigure: clean configure
