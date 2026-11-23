#!/bin/bash
set -euo pipefail

pkg=${1:?usage: verify-export.sh INSTALLER.pkg VERSION BUILD_NUMBER EXPECTED_TEAM_ID}
version=${2:?missing expected marketing version}
build=${3:?missing expected build number}
team=${4:?missing expected developer team ID}
[[ -f "$pkg" && "$pkg" == *.pkg ]]
signature=$(pkgutil --check-signature "$pkg" 2>&1) || {
  printf '%s\n' "$signature" >&2
  exit 1
}
printf '%s\n' "$signature" | grep -Eq 'Status: signed by a certificate trusted by Mac OS X|Status: signed by a certificate trusted by macOS'
printf '%s\n' "$signature" | grep -Eq "3rd Party Mac Developer Installer:|Mac Installer Distribution:|Apple Distribution:"
printf '%s\n' "$signature" | grep -Fq "$team"
temporary=$(mktemp -d)
expanded="$temporary/unpacked"
trap 'rm -rf "$temporary"' EXIT
pkgutil --expand-full "$pkg" "$expanded"
app=$(find "$expanded" -type d -name '*.app' -prune -print -quit)
[[ -n "$app" ]]
[[ $(find "$expanded" -type d -name '*.app' -prune -print | wc -l | tr -d ' ') -eq 1 ]]
"$(dirname "$0")/verify-app.sh" "$app" "$version" "$build" "$team"
printf 'CmdIME installer verified: %s\n' "$pkg"
