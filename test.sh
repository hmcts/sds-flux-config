# !/usr/bin/env bash

# OUTPUTFILE="images.yaml"
# DIRECTORIES=$(find apps -type d -not -path '*dev*' -not -path '*stg*' -not -path '*test*' -not -path '*ithc*' -not -path '*demo*' -not -path '*sbox*' -not -path 'apps' -not -path '*dynatrace*' -not -path '*azureserviceoperator-system*' -not -path '*flux-system*' -not -path '*neuvector*' -not -path '*traefik2*')

# for dir in $DIRECTORIES; do
#     if ls "$dir" | grep -q -E 'kustomization\.ya?ml'; then

#         echo "Checking Directory $dir"
#         kustomize build --load-restrictor LoadRestrictionsNone "$dir" 2>&1 | yq eval 'select(.kind == "HelmRelease" and (.spec.values.nodejs.image != null or .spec.values.java.image != null))' >> $OUTPUTFILE

#         IMAGE_PATTERN="^prod-[a-f0-9]+-(?P<ts>[0-9]+)"
#         nodejs_image=$(echo "$output" | yq eval '.spec.values.nodejs.image' -)
#         java_image=$(echo "$output" | yq eval '.spec.values.java.image' -)

#         extract_nodejs_image=$(echo $nodejs_image | cut -d ':' -f 2-)
#         extract_java_image=$(echo $java_image | cut -d ':' -f 2-)

#         if ! echo "\"$extract_nodejs_image\"" | jq --arg pattern "^prod-[a-f0-9]+-([0-9]+)" 'test($pattern)' > /dev/null || ! echo "\"$extract_java_image\"" | jq --arg pattern "^prod-[a-f0-9]+-([0-9]+)" 'test($pattern)'; then
#             echo "image do not match"
#             exit 1
#         fi

# done

IMAGE_PATTERN="^prod-[a-f0-9]+-(?P<ts>[0-9]+)"
nodejs_image=sdshmctspublic.azurecr.io/toffee/frontend:prod-tbc
java_image=sdshmctspublic.azurecr.io/pip/subscription-management:prod-9283bd1-20240216103949


extract_nodejs_image=$(echo $nodejs_image | cut -d ':' -f 2-)
extract_java_image=$(echo $java_image | cut -d ':' -f 2-)

if ! echo "\"$extract_nodejs_image\"" | jq  'test("^prod-[a-f0-9]+-([0-9]+)")' || ! echo "\"$extract_java_image\"" | jq 'test("^prod-[a-f0-9]+-([0-9]+)")'; then
    echo "image do not match"
    exit 1
fi
