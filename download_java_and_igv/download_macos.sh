#!/bin/bash

# Java SE Development Kit 8
wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-macosx-x64.dmg

# IGV
wget http://data.broadinstitute.org/igv/projects/downloads/IGV_2.3.94.zip
unzip IGV_2.3.94.zip -d ../
