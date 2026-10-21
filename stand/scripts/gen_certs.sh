#!/usr/bin/env bash
set -euo pipefail

CERT_DIR="/certs"
mkdir -p "$CERT_DIR"

# 1. CA
openssl req -x509 -newkey rsa:4096 -days 365 -nodes \
  -keyout "$CERT_DIR/ca.key" -out "$CERT_DIR/ca.crt" \
  -subj "/C=UA/O=PR DB Security Lab/CN=TestCA"

# 2. Server Key & CSR
openssl req -newkey rsa:2048 -nodes \
  -keyout "$CERT_DIR/server.key" -out "$CERT_DIR/server.csr" \
  -subj "/C=UA/O=PR DB Security Lab/CN=db"

# 3. Server Cert SAN
cat <<EOF > "$CERT_DIR/san.ext"
subjectAltName = DNS:db, DNS:restore, DNS:localhost, IP:127.0.0.1, IP:172.28.0.10, IP:172.28.0.11
EOF

openssl x509 -req -in "$CERT_DIR/server.csr" \
  -CA "$CERT_DIR/ca.crt" -CAkey "$CERT_DIR/ca.key" -CAcreateserial \
  -out "$CERT_DIR/server.crt" -days 365 \
  -extfile "$CERT_DIR/san.ext"

chmod 0600 "$CERT_DIR/server.key" "$CERT_DIR/ca.key"
echo "Сертифікати успішно створено у $CERT_DIR"