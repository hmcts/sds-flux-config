#!/usr/bin/env bash
set -ex

cd ../
workdir=$(dirname $0)
yamllint -c $workdir/.yamllint.yaml $(find . -not -path '*/\.*' -type f -name '*.yaml')