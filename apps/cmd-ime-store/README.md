# CmdIME Mac App Store build

This is an isolated App Store build target. The direct-distribution app remains under `apps/cmd-ime-swift` and keeps its own Sparkle/release path.

## Project and metadata

- `project.yml` is the Xcode project source. `make generate` creates `CmdIMEStore.xcodeproj`; the generated project is intentionally ignored and must not be committed.
- `Package.swift` owns the Store core and unit tests. It has no remote package dependencies.
- `manifest.toml` at repository root owns the marketing version. `make` reads it when constructing the app bundle.
- `CmdIMEStore.entitlements` grants only App Sandbox. The app target links the Store Core, not the direct-distribution package.
- `PrivacyInfo.xcprivacy` declares UserDefaults reason `CA92.1`; collected data and tracking are both empty/false.
- `Assets.xcassets/AppIcon.appiconset` is generated from the repository's canonical `AppIcon.icns`.

## Local checks

```sh
make test
make build
./scripts/verify-app.sh .build/DerivedData/Build/Products/Debug/CmdIME.app "$(python3 -c 'import tomllib; print(tomllib.load(open("../../manifest.toml", "rb"))["project"]["version"])')" 1
```

`make build` is unsigned and only checks compilation and bundle resources. It is not a submission artifact.

## App Store archive/export

Use a unique positive App Store build number for each archive. `CMDIME_EXPECTED_TEAM_ID` defaults to the public repository value `XTUTN7X562`; the Makefile refuses a different team. The archive target uses automatic signing and `-allowProvisioningUpdates`, which lets Xcode create or update signing assets in the associated Apple Developer account. Run it only in the authorized Apple signing environment:

```sh
make archive-app-store BUILD_NUMBER=123
make export-app-store BUILD_NUMBER=123
make verify-export BUILD_NUMBER=123
```

The export target only creates a local App Store Connect package. It does not upload it. `verify-export` requires one signed `.pkg`, checks the installer certificate and team, expands the installer, and verifies the embedded app's distribution signature, sandbox entitlement, bundle ID, manifest version, build number, icon, privacy manifest, and absence of Sparkle. A no-account or unsigned export fails closed.

A successful archive/export is packaging evidence only. It does not establish that Command key monitoring works under App Sandbox, App Review acceptance, or that a build has been uploaded or published.
