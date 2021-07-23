#!/usr/bin/env bash
set -e

yq --version 
which yq 
VERSION=v4.11.1
BINARY=yq_linux_amd64
wget https://github.com/mikefarah/yq/releases/download/${VERSION}/${BINARY}.tar.gz -O - | \
  tar xz && sudo mv ${BINARY} /usr/local/bin/yq
