#!/usr/bin/env bash
set -ex

yamllint -c .yamllint.yaml $(find . -not -path '*/\.*' -not -path '**/charts/**' -type f -name '*.yaml')
