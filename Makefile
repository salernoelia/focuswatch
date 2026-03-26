PROJECT := focuswatch.xcodeproj
IOS_SCHEME := companion
WATCH_SCHEME := watch

IOS_SIM_NAME ?= 24.11.25
WATCH_SIM_NAME ?= 24.11.25 (W)
IOS_TEST_SIM_NAME ?= iPhone 17
WATCH_TEST_SIM_NAME ?= Apple Watch Series 11 (46mm)

IOS_BUNDLE_ID := net.com.fokusuhr.FokusUhr
WATCH_BUNDLE_ID := net.com.fokusuhr.FokusUhr.watchkitapp

DERIVED_DATA := .build/DerivedData

.PHONY: help ios-build ios-test ios-run ios-launch watch-build watch-test watch-run watch-launch dev all-test clean

help:
	@echo "focuswatch Make targets"
	@echo "  make ios-build        Build iOS scheme for simulator"
	@echo "  make ios-test         Run iOS tests on simulator"
	@echo "  make ios-run          Build + install + launch iOS app on simulator"
	@echo "  make watch-build      Build watchOS scheme for simulator"
	@echo "  make watch-test       Run watchOS tests on simulator"
	@echo "  make watch-run        Build + install + launch watch app on simulator"
	@echo "  make dev         	   Launch iOS + watch apps concurrently"
	@echo "  make all-test         Run both iOS and watchOS test suites"
	@echo ""
	@echo "Overrides:"
	@echo "  IOS_SIM_NAME='24.11.25'"
	@echo "  WATCH_SIM_NAME='24.11.25 (W)'"
	@echo "  IOS_TEST_SIM_NAME='iPhone 17'"
	@echo "  WATCH_TEST_SIM_NAME='Apple Watch Series 11 (46mm)'"

ios-build:
	@set -e; \
	device=$$(xcrun simctl list devices available | grep "$(IOS_SIM_NAME)" | grep -v "Plus\|Pro\|Max\|Paired" | head -1 | sed 's/.*(\([A-F0-9-]*\)).*/\1/'); \
	if [ -z "$$device" ]; then \
		echo "No available iOS simulator matched: $(IOS_SIM_NAME)"; \
		exit 1; \
	fi; \
	echo "Using iOS simulator UDID: $$device"; \
	xcodebuild build \
		-scheme "$(IOS_SCHEME)" \
		-project "$(PROJECT)" \
		-destination "platform=iOS Simulator,arch=arm64,id=$$device" \
		-derivedDataPath "$(DERIVED_DATA)"

ios-test:
	@set -e; \
	device=$$(xcrun simctl list devices available | grep "$(IOS_TEST_SIM_NAME)" | grep -v "Plus\|Pro\|Max\|Paired" | head -1 | sed 's/.*(\([A-F0-9-]*\)).*/\1/'); \
	if [ -z "$$device" ]; then \
		echo "No available iOS simulator matched: $(IOS_TEST_SIM_NAME)"; \
		exit 1; \
	fi; \
	echo "Using iOS simulator UDID: $$device"; \
	xcodebuild test \
		-scheme "$(IOS_SCHEME)" \
		-project "$(PROJECT)" \
		-destination "platform=iOS Simulator,arch=arm64,id=$$device" \
		-derivedDataPath "$(DERIVED_DATA)"

ios-run: ios-build ios-launch

ios-launch:
	@set -e; \
	device=$$(xcrun simctl list devices available | grep "$(IOS_SIM_NAME)" | grep -v "Plus\|Pro\|Max\|Paired" | head -1 | sed 's/.*(\([A-F0-9-]*\)).*/\1/'); \
	if [ -z "$$device" ]; then \
		echo "No available iOS simulator matched: $(IOS_SIM_NAME)"; \
		exit 1; \
	fi; \
	xcrun simctl boot "$${device}" >/dev/null 2>&1 || true; \
	open -a Simulator >/dev/null 2>&1 || true; \
	app_path=$$(find "$(DERIVED_DATA)/Build/Products" -type d -path "*/Debug-iphonesimulator/*.app" | head -1); \
	if [ -z "$$app_path" ]; then \
		echo "Could not find built iOS app under $(DERIVED_DATA)/Build/Products"; \
		exit 1; \
	fi; \
	echo "Installing $$app_path on $$device"; \
	xcrun simctl install "$$device" "$$app_path"; \
	xcrun simctl launch "$$device" "$(IOS_BUNDLE_ID)"

watch-build:
	@set -e; \
	device=$$(xcrun simctl list devices available | grep "$(WATCH_SIM_NAME)" | head -1 | sed 's/.*(\([A-F0-9-]*\)).*/\1/'); \
	if [ -z "$$device" ]; then \
		echo "No available watchOS simulator matched: $(WATCH_SIM_NAME)"; \
		exit 1; \
	fi; \
	echo "Using watchOS simulator UDID: $$device"; \
	xcodebuild build \
		-scheme "$(WATCH_SCHEME)" \
		-project "$(PROJECT)" \
		-destination "platform=watchOS Simulator,arch=arm64,id=$$device" \
		-derivedDataPath "$(DERIVED_DATA)"

watch-test:
	@set -e; \
	device=$$(xcrun simctl list devices available | grep "$(WATCH_TEST_SIM_NAME)" | head -1 | sed 's/.*(\([A-F0-9-]*\)).*/\1/'); \
	if [ -z "$$device" ]; then \
		echo "No available watchOS simulator matched: $(WATCH_TEST_SIM_NAME)"; \
		exit 1; \
	fi; \
	echo "Using watchOS simulator UDID: $$device"; \
	xcodebuild test \
		-scheme "$(WATCH_SCHEME)" \
		-project "$(PROJECT)" \
		-destination "platform=watchOS Simulator,arch=arm64,id=$$device" \
		-derivedDataPath "$(DERIVED_DATA)"

watch-run: watch-build watch-launch

watch-launch:
	@set -e; \
	device=$$(xcrun simctl list devices available | grep "$(WATCH_SIM_NAME)" | head -1 | sed 's/.*(\([A-F0-9-]*\)).*/\1/'); \
	if [ -z "$$device" ]; then \
		echo "No available watchOS simulator matched: $(WATCH_SIM_NAME)"; \
		exit 1; \
	fi; \
	xcrun simctl boot "$${device}" >/dev/null 2>&1 || true; \
	open -a Simulator >/dev/null 2>&1 || true; \
	app_path=$$(find "$(DERIVED_DATA)/Build/Products" -type d -path "*/Debug-watchsimulator/*.app" | head -1); \
	if [ -z "$$app_path" ]; then \
		echo "Could not find built watch app under $(DERIVED_DATA)/Build/Products"; \
		exit 1; \
	fi; \
	echo "Installing $$app_path on $$device"; \
	xcrun simctl install "$$device" "$$app_path"; \
	xcrun simctl launch "$$device" "$(WATCH_BUNDLE_ID)"

dev:
	@set -e; \
	$(MAKE) --no-print-directory ios-build watch-build; \
	$(MAKE) --no-print-directory ios-launch & ios_pid=$$!; \
	$(MAKE) --no-print-directory watch-launch & watch_pid=$$!; \
	ios_status=0; watch_status=0; \
	wait $$ios_pid || ios_status=$$?; \
	wait $$watch_pid || watch_status=$$?; \
	if [ $$ios_status -ne 0 ] || [ $$watch_status -ne 0 ]; then \
		echo "dev failed: ios-run=$$ios_status watch-run=$$watch_status"; \
		exit 1; \
	fi; \
	echo "Both iOS and watch apps were launched."

all-test: ios-test watch-test

clean:
	rm -rf "$(DERIVED_DATA)"
