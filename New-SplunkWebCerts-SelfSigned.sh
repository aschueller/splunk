#!/bin/sh

############################
# Author: Alexander Schüller
# Version: 1.0

# ###########
# SCRIPT INFO
# This script automates the generation of new, self signed certificates for Splunk Web
# Splunk documentation: https://docs.splunk.com/Documentation/Splunk/7.0.0/Security/Howtoself-signcertificates
# What this script does:
# * Backup current Splunk Web certs
# * Create a new, self signed Root CA
# * Create a new server key and cert with this CA
# * Build a certificate chain
# * Copy the certs to Splunks default location for Web certs

######################
# SCRIPT CONFIGURATION
SPLUNK_HOME = /opt/splunk
SSLSUBJROOT="/C=AT/ST=SelfsignedRoot/L=SelfsignedRoot/O=SelfsignedRoot/CN=selfsignedroot.org"
SSLSUBJSERVER="/C=AT/ST=Selfsigned/L=Selfsigned/O=Selfsigned/CN=selfsigned.org"
CERTPATH="$SPLUNK_HOME/etc/auth/splunkweb/"

##############################
echo "BACKUP OLD CERTIFICATES"
cd $CERTPATH
mkdir -p "certbackup.$(date +%F_%R)"
cp -a *.pem "certbackup.$(date +%F_%R)"

###################################
echo "GENERATE SELF SIGNED ROOT CA"
openssl genrsa -out myCAPrivateKey.key 2048
openssl req -new -key myCAPrivateKey.key -subj $SSLSUBJROOT -out myCACertificate.csr 
openssl x509 -req -in myCACertificate.csr -sha256 -signkey myCAPrivateKey.key -out myCACertificate.pem -days 3650

###########################
echo "GENERATE PRIVATE KEY"
openssl genrsa -out mySplunkWebPrivateKey.key 2048

##########################
echo "GENERATE SERVER KEY"
openssl req -new -key mySplunkWebPrivateKey.key -subj $SSLSUBJSERVER -out mySplunkWebCert.csr 
openssl x509 -req -in mySplunkWebCert.csr -sha256 -CA myCACertificate.pem -CAkey myCAPrivateKey.key -CAcreateserial -out myCACertificate.csr -out mySplunkWebCert.pem -days 3650

##############################
echo "BUILD CERTIFICATE CHAIN"
cat mySplunkWebCert.pem myCACertificate.pem > mySplunkWebCertificate.pem

############################################
echo "MOVE CERTS TO SPLUNK DEFAULT LOCATION"
mv -f mySplunkWebPrivateKey.key privkey.pem
mv -f mySplunkWebCertificate.pem cert.pem

####################
echo "END OF SCRIPT"
