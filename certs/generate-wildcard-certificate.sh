#!/usr/bin/env bash

# # print usage
# DOMAIN=$1
# if [ -z "$1" ]; then
    # echo "USAGE: $0 tld"
    # echo ""
    # echo "This will generate a non-secure self-signed wildcard certificate for "
    # echo "a given development tld."
    # echo "This should only be used in a development environment."
    # exit
# fi

# # Add wildcard
# WILDCARD="*.$DOMAIN"

# # Set our variables
# cat <<EOF > req.cnf
# [req]
# default_bits = 4096
# distinguished_name = req_distinguished_name
# x509_extensions = v3_ca
# req_extensions = v3_req
# prompt = no
# [req_distinguished_name]
# C = US
# ST = MD
# O = home
# localityName = home
# commonName = $WILDCARD
# organizationalUnitName = home
# emailAddress = $(git config user.email)
# [v3_req]
# basicConstraints = CA:FALSE
# keyUsage = nonRepudiation, digitalSignature, keyEncipherment
# subjectAltName = @alt_names
# [alt_names]
# DNS.1   = $DOMAIN
# DNS.2   = *.$DOMAIN
# DNS.3   = localhost
# [v3_ca]
# subjectKeyIdentifier=hash
# authorityKeyIdentifier=keyid:always,issuer
# basicConstraints = critical, CA:TRUE, pathlen:0
# keyUsage = critical, cRLSign, keyCertSign
# extendedKeyUsage = serverAuth, clientAuth
# EOF

# # Generate our Private Key, and Certificate directly
# openssl req -x509 -nodes -days 3650 -newkey rsa:4096 \
  # -subj "/CN=$DOMAIN" -extensions v3_ca -extensions v3_req \
  # -keyout "$DOMAIN.key" -config req.cnf \
  # -out "$DOMAIN.crt" -sha256
# rm req.cnf

# echo ""
# echo "Next manual steps:"
# echo "- Use $DOMAIN.crt and $DOMAIN.key to configure Apache/nginx"
# echo "- Import $DOMAIN.crt into Chrome settings: chrome://settings/certificates > tab 'Authorities'"

set -e

if [ -f "ca.crt" ] || [ -f "ca.key" ]; then
    echo -e "\e[41mCertificate Authority files already exist!\e[49m"
    echo
    echo -e "You only need a single CA even if you need to create multiple certificates."
    echo -e "This way, you only ever have to import the certificate in your browser once."
    echo
    echo -e "If you want to restart from scratch, delete the \e[93mca.crt\e[39m and \e[93mca.key\e[39m files."
    exit
fi

# Generate private key
openssl genrsa -out ca.key 2048

# Generate root certificate
openssl req -x509 -new -nodes -subj "/C=US/O=_Development CA/CN=Development certificates" -key ca.key -sha256 -days 3650 -out ca.crt

echo -e "\e[42mSuccess!\e[49m"
echo
echo "The following files have been written:"
echo -e "  - \e[93mca.crt\e[39m is the public certificate that should be imported in your browser"
echo -e "  - \e[93mca.key\e[39m is the private key that will be used by \e[93mcreate-certificate.sh\e[39m"
echo
echo "Next steps:"
echo -e "  - Import \e[93mca.crt\e[39m in your browser"
echo -e "  - run \e[93mcreate-certificate.sh example.com\e[39m"

# Generates a wildcard certificate for a given domain name.

set -e

if [ -z "$1" ]; then
    echo -e "\e[43mMissing domain name!\e[49m"
    echo
    echo "Usage: $0 example.com"
    echo
    echo "This will generate a wildcard certificate for the given domain name and its subdomains."
    exit
fi

DOMAIN=$1

if [ ! -f "ca.key" ]; then
    echo -e "\e[41mCertificate Authority private key does not exist!\e[49m"
    echo
    echo -e "Please run \e[93mcreate-ca.sh\e[39m first."
    exit
fi

# Generate a private key
openssl genrsa -out "$DOMAIN.key" 2048

# Create a certificate signing request
openssl req -new -subj "/C=US/O=Local Development/CN=$DOMAIN" -key "$DOMAIN.key" -out "$DOMAIN.csr"

# Create a config file for the extensions
>"$DOMAIN.ext" cat <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = $DOMAIN
DNS.2 = *.$DOMAIN
DNS.3 = localhost
EOF

# Create the signed certificate
openssl x509 -req \
    -in "$DOMAIN.csr" \
    -extfile "$DOMAIN.ext" \
    -CA ca.crt \
    -CAkey ca.key \
    -CAcreateserial \
    -out "$DOMAIN.crt" \
    -days 365 \
    -sha256

rm "$DOMAIN.csr"
rm "$DOMAIN.ext"

echo -e "\e[42mSuccess!\e[49m"
echo
echo -e "You can now use \e[93m$DOMAIN.key\e[39m and \e[93m$DOMAIN.crt\e[39m in your web server."
echo -e "Don't forget that \e[1myou must have imported \e[93mca.crt\e[39m in your browser\e[0m to make it accept the certificate."