#!/usr/bin/env bash
set -euo pipefail

# This script generates a self-signed certificate for code signing.
# It can be used as a stable identity for macOS TCC (Accessibility) grants
# without paying $99/yr for the Apple Developer Program.

IDENTITY_NAME="CmdIME Self-Signed Publisher"
OUT_P12="cmdime-signing.p12"
PASSWORD=$(openssl rand -base64 12)
KEYCHAIN="tmp.keychain"

echo ">> Generating self-signed certificate for: $IDENTITY_NAME"

# Ensure cleanup on exit (success or failure)
trap 'security delete-keychain "$KEYCHAIN" 2>/dev/null; rm -f key.pem cert.pem' EXIT

# Create a temporary keychain (used by codesign when importing below)
security create-keychain -p "" "$KEYCHAIN"

# Generate EC P-256 certificate (Apple recommends EC over RSA 2048 for code signing)
openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 \
    -keyout key.pem -out cert.pem -days 3650 -nodes \
    -subj "/CN=$IDENTITY_NAME"

# Combine into P12
openssl pkcs12 -export -out "$OUT_P12" -inkey key.pem -in cert.pem \
    -name "$IDENTITY_NAME" -passout "pass:$PASSWORD"

echo "----------------------------------------------------------"
echo "Success! Generated: $OUT_P12"
echo "Password: $PASSWORD"
echo "Identity Name: $IDENTITY_NAME"
echo "----------------------------------------------------------"
echo ""
echo "TO USE IN GITHUB ACTIONS:"
echo "1. Set Secret 'CMDIME_SIGNING_CERT_P12_BASE64' to the output of:"
echo "   base64 -i $OUT_P12 | pbcopy"
echo "2. Set Secret 'CMDIME_SIGNING_CERT_PASSWORD' to the password above."
echo "3. Set Variable 'CMDIME_SIGNING_IDENTITY' to: $IDENTITY_NAME"
echo ""
echo "Keep $OUT_P12 and its password safe! You will need them if you"
echo "want to regenerate the same identity in the future (though for"
echo "TCC stability, the SHA-1 of the cert must remain the same)."
