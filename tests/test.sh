#!/usr/bin/env bash
EXCLUSIONS_LIST=(
    apps/flux-system/*
    apps/vh/*/stg.yaml
    .*demo.*.yaml
    .*test.*.yaml
    .*ithc.*.yaml
    .*sbox.*.yaml
    .*dev.*.yaml
)

# EXCLUSIONS=$(IFS="|" ; echo "${EXCLUSIONS_LIST[*]}")
# FILE_LOCATIONS="apps"
OUTPUTFILE="kustomization_images_list.txt"
DIRECTORIES=$(find ../apps -type d -not -path $EXCLUSIONS_LIST )
# echo $DIRECTORIES
    for dir in $DIRECTORIES; do
        kustomize build --load-restrictor LoadRestrictionsNone "$dir" > $OUTPUTFILE
done