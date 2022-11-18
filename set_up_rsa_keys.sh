#!/usr/bin/bash
#generates the private key for uploading plugins directly to SolrCloud
openssl genrsa -out demo.pem 512

#generates the public key for uploading plugins directly to SolrCloud
openssl rsa -in demo.pem -pubout -outform DER -out demo_public.der

