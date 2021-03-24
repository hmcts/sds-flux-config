#!/usr/bin/env bash
set -ex

yamllint -c .yamllint.yaml $(find . -not -path '*/\.*' -not -path '**/charts/**' -not -path '**/templates/**' -type f -name '*.yaml')
