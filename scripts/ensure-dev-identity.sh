#!/bin/sh
# One stable codesign identity in the login keychain. Ad-hoc cdhash
# changes every rebuild; this certificate hash does not, so Keychain ACL,
# TCC, WebKit, and the legacy Keychain ACL keep treating Thravik as the same app.
set -e
CERT_NAME="Redent Development"
if security find-certificate -c "$CERT_NAME" >/dev/null 2>&1; then
	exit 0
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
openssl req -x509 -newkey rsa:2048 -sha256 -nodes -days 3650 \
	-subj "/CN=$CERT_NAME/OU=REDENT/O=Redent/C=US" \
	-addext "extendedKeyUsage=codeSigning" \
	-addext "keyUsage=critical,digitalSignature" \
	-keyout "$tmp/key.pem" -out "$tmp/cert.pem"
# OpenSSL 3 defaults to AES + SHA-256 MACs, which `security import` rejects
# as a wrong password; the SHA-1/3DES pair is what the Keychain still reads.
openssl pkcs12 -export \
	-keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1 \
	-inkey "$tmp/key.pem" -in "$tmp/cert.pem" \
	-out "$tmp/cert.p12" -passout pass:redent \
	-name "$CERT_NAME"
security import "$tmp/cert.p12" \
	-k "$HOME/Library/Keychains/login.keychain-db" \
	-P redent -T /usr/bin/codesign -T /usr/bin/security >/dev/null
