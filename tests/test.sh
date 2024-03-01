#!/usr/bin/env bash
EXCLUSIONS_LIST=(
  /flux-system/*
  /vh/*/stg.yaml
  .*demo.*.yaml
  .*test.*.yaml
  .*ithc.*.yaml
  .*sbox.*.yaml
  .*dev.*.yaml
)

EXCLUSIONS=$(IFS="|" ; echo "${EXCLUSIONS_LIST[*]}")
OUTPUTFILE="kustomization_images.txt"

cd ../apps


DIRECTORIES=$(find . -type d -not -path "${EXCLUSIONS[*]}")

for dir in $DIRECTORIES; do
    find "$dir" -name "prod.yaml" -name "base.yaml" |
    kustomize build --load-restrictor LoadRestrictionsNone "$dir" 2>&1 | yq eval 'select(.kind == "HelmRelease" and (.spec.values.nodejs.image != null or .spec.values.java.image != null))' >> $OUTPUTFILE
done
