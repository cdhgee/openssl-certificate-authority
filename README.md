# OpenSSL certification authority

Some configuration and scripts to create a very basic SSL certificate authority and issue certificates. It can:

## Features

- Create RSA or ECDSA keys
  - RSA keys will be 4096 bits
  - ECDSA keys will be created using the NIST P-256 curve
- CA certificates will have
  - Key usage limited to digital signature and certificate signing
  - keyid-based authority key identifier
  - hash-based subject key identifier
- Entity certificates will have
  - Key usage limited to digital signature and key encipherment
  - Extended key usage limited to TLS server authentication and TLS client authentication
  - keyid-based authority key identifier
  - hash-based subject key identifier

## General notes

When creating a CA (either root or intermediate), the following directory structure will be used:

    <ca directory>
    |- certificate.pem - the CA certificate (public key)
    |- chain.pem - the CA certificate plus all parent CA certificates in the chain
    |- private-key.pem - the CA private key
    |- request.pem - the CSR used to generate the certificate
    |- ecparams.pem - the elliptic curve params used (ECDSA keys only)

## Creating a root certification authority

Example:

    ./New-SSLCertificateAuthority.ps1 -Subject "/C=US/ST=Texas/L=Austin/O=ACME/CN=ACME Root CA" -CAPath acme-root  -PrivateKeyType [ECDSA|RSA]

The root CA is configured by default to allow only one intermediate CA in the chain; to change this, increase the `pathlen` parameter in `root-ca-extensions.ext`. If you wish to use a root CA to sign certificates directly (without an intermediate CA), set the `pathlen` parameter to 0.

## Creating an intermediate certification authority

Example:

    ./New-SSLCertificateAuthority.ps1 -Subject "/C=US/ST=Texas/L=Austin/O=ACME/CN=ACME Intermediate CA" -CAPath acme-intermediate  -PrivateKeyType [ECDSA|RSA] -CASigningPath acme-root

You must reference the directory of the CA you want to use to sign the intermediate CA's certificate; normally, this will be the root CA.

Intermediate CAs are configured by default to allow no subordinate CAs in the chain; to change this, increase the `pathlen` parameter in `root-ca-extensions.ext`.
