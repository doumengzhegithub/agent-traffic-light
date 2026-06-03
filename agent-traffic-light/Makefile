APP := $(CURDIR)/.build/x86_64-apple-macosx/debug/AgentTrafficLight
LABEL := com.littlehld.agent-traffic-light
PID_FILE := /tmp/agent-traffic-light.pid
LOG_FILE := /tmp/agent-traffic-light.log
PLIST_FILE := /tmp/agent-traffic-light.plist

.PHONY: build test run run-built run-tty start stop restart status logs clean

build:
	swift build

test:
	swift test

run:
	swift run AgentTrafficLight

run-built: build
	$(APP)

run-tty: build
	script -q /dev/null $(APP)

start: build
	@printf '%s\n' \
		'<?xml version="1.0" encoding="UTF-8"?>' \
		'<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' \
		'<plist version="1.0">' \
		'<dict>' \
		'  <key>Label</key>' \
		'  <string>$(LABEL)</string>' \
		'  <key>ProgramArguments</key>' \
		'  <array>' \
		'    <string>$(APP)</string>' \
		'  </array>' \
		'  <key>RunAtLoad</key>' \
		'  <true/>' \
		'  <key>StandardOutPath</key>' \
		'  <string>$(LOG_FILE)</string>' \
		'  <key>StandardErrorPath</key>' \
		'  <string>$(LOG_FILE)</string>' \
		'</dict>' \
		'</plist>' > "$(PLIST_FILE)"
	@launchctl bootout "gui/$$(id -u)/$(LABEL)" >/dev/null 2>&1 || true
	@launchctl bootstrap "gui/$$(id -u)" "$(PLIST_FILE)"
	@launchctl kickstart "gui/$$(id -u)/$(LABEL)"
	@launchctl print "gui/$$(id -u)/$(LABEL)" | awk '/pid = / { print $$3; exit }' > "$(PID_FILE)" || true
	@echo "AgentTrafficLight started with launchctl: $(LABEL)"
	@echo "Log: $(LOG_FILE)"

stop:
	@launchctl bootout "gui/$$(id -u)/$(LABEL)" >/dev/null 2>&1 || true
	@rm -f "$(PID_FILE)"
	@echo "AgentTrafficLight stopped: $(LABEL)"

restart: stop start

status:
	@if launchctl print "gui/$$(id -u)/$(LABEL)" >/dev/null 2>&1; then \
		echo "AgentTrafficLight is loaded: $(LABEL)"; \
		launchctl print "gui/$$(id -u)/$(LABEL)" | awk '/pid = / { print "pid: " $$3; found = 1 } END { if (!found) print "pid: not running" }'; \
	else \
		echo "AgentTrafficLight is not loaded"; \
	fi

logs:
	tail -f "$(LOG_FILE)"

clean:
	swift package clean
