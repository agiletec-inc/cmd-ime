SHELL := /bin/bash
ROOT := $(abspath ../..)
MANIFEST := $(ROOT)/manifest.toml
VERSION := $(shell python3 -c 'import tomllib; print(tomllib.load(open("$(MANIFEST)", "rb"))["project"]["version"])')
BUILD_NUMBER ?= 1
CMDIME_EXPECTED_TEAM_ID ?= XTUTN7X562
PROJECT := CmdIMEStore.xcodeproj
SCHEME := CmdIMEStore
DERIVED := $(abspath .build/DerivedData)
ARCHIVE := $(abspath .build/CmdIMEStore.xcarchive)

.PHONY: generate build test archive-unsigned archive-app-store export-app-store verify-build verify-export validate-app-store clean

generate:
	xcodegen generate --spec project.yml

build: generate
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -clonedSourcePackagesDirPath $(abspath .build/SourcePackages) -configuration Debug -destination 'platform=macOS,arch=arm64' build \
		-derivedDataPath $(DERIVED) CMDIME_MARKETING_VERSION=$(VERSION) CMDIME_BUILD_NUMBER=$(BUILD_NUMBER) \
		CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

test:
	swift test --package-path .

archive-unsigned: generate
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -clonedSourcePackagesDirPath $(abspath .build/SourcePackages) -configuration Release -destination 'generic/platform=macOS' archive \
		-derivedDataPath $(DERIVED) -archivePath $(ARCHIVE) CMDIME_MARKETING_VERSION=$(VERSION) CMDIME_BUILD_NUMBER=$(BUILD_NUMBER) \
		CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=-

archive-app-store: generate
	@test "$(origin BUILD_NUMBER)" != file || (echo 'Set a unique BUILD_NUMBER explicitly for App Store archives.' >&2; exit 1)
	@test "$(BUILD_NUMBER)" -eq "$(BUILD_NUMBER)" 2>/dev/null && test "$(BUILD_NUMBER)" -gt 0 || (echo 'BUILD_NUMBER must be a positive integer' >&2; exit 1)
	@test "$${ALLOW_APPLE_PROVISIONING:-}" = 1 || (echo 'Set ALLOW_APPLE_PROVISIONING=1 to enable Xcode provisioning updates.' >&2; exit 1)
	@test "$(CMDIME_EXPECTED_TEAM_ID)" = XTUTN7X562 || (echo 'EXPECTED_TEAM_ID does not match the public repository team ID' >&2; exit 1)
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -clonedSourcePackagesDirPath $(abspath .build/SourcePackages) -configuration Release -destination 'generic/platform=macOS' archive \
		-derivedDataPath $(DERIVED) -archivePath $(ARCHIVE) CMDIME_MARKETING_VERSION=$(VERSION) CMDIME_BUILD_NUMBER=$(BUILD_NUMBER) \
		DEVELOPMENT_TEAM=$(CMDIME_EXPECTED_TEAM_ID) CODE_SIGN_STYLE=Automatic CODE_SIGNING_ALLOWED=YES \
		-allowProvisioningUpdates

export-app-store:
	@test -d "$(ARCHIVE)" || (echo 'App Store archive not found.' >&2; exit 1)
	xcodebuild -exportArchive -archivePath $(ARCHIVE) -exportPath $(abspath .build/AppStoreExport) \
		-exportOptionsPlist ExportOptions-AppStore.plist

verify-build:
	./scripts/verify-app.sh $(DERIVED)/Build/Products/Debug/CmdIME.app $(VERSION) $(BUILD_NUMBER)

clean:
	rm -rf .build $(PROJECT)

verify-export:
	@set -euo pipefail; \
	pkg=$$(find .build/AppStoreExport -maxdepth 1 -type f -name '*.pkg' -print -quit); \
	test -n "$$pkg" || { echo 'No exported installer .pkg found.' >&2; exit 1; }; \
	test "$$(find .build/AppStoreExport -maxdepth 1 -type f -name '*.pkg' | wc -l | tr -d ' ')" -eq 1 || { echo 'Expected exactly one exported installer .pkg.' >&2; exit 1; }; \
	./scripts/verify-export.sh "$$pkg" "$(VERSION)" "$(BUILD_NUMBER)" "$(CMDIME_EXPECTED_TEAM_ID)"

validate-app-store: verify-export
	@test -n "$${APP_STORE_CONNECT_API_KEY_ID:-}" -a -n "$${APP_STORE_CONNECT_ISSUER_ID:-}" || { echo 'Set App Store Connect API key ID and issuer ID in the environment.' >&2; exit 1; }
	@set -euo pipefail; pkg=$$(find .build/AppStoreExport -maxdepth 1 -type f -name '*.pkg' -print -quit); \
	xcrun altool --validate-app --file "$$pkg" --type macos --apiKey "$$APP_STORE_CONNECT_API_KEY_ID" --apiIssuer "$$APP_STORE_CONNECT_ISSUER_ID"
