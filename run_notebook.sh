#!/bin/bash

docker run --rm -it -v "${PWD}":/root/data -p 8080:8080 qqep685d/ilas2017
