#!/usr/bin/env bash
set -ex

yamllint -c .yamllint.yaml $(find . -not -path '*/\.*' -type f -name '*.yaml')
