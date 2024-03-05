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

cd /apps


DIRECTORIES=$(find . -type d -not -path "$IFS")

for dir in $DIRECTORIES; do
    kustomize build --load-restrictor LoadRestrictionsNone "$dir" 2>&1 | yq eval 'select(.kind == "HelmRelease" and (.spec.values.nodejs.image != null or .spec.values.java.image != null))' >> $OUTPUTFILE
    IMAGE_PATTERN="^prod-[a-f0-9]+-(?P<ts>[0-9]+)"

    # while read -r output; do
    #     nodejs_image=$(echo "$output" | yq eval '.spec.values.nodejs.image' -)
    #     java_image=$(echo "$output" | yq eval '.spec.values.java.image' -)

    #     if [[ "$nodejs_image" && "$java_image" != $IMAGE_PATTERN ]]; then
    #         echo "Error: No match found for image pattern in line: $output"
    #     fi
    # done < $OUTPUTFILE
done
