# !/usr/bin/env bash

# OUTPUTFILE="images.yaml"
# DIRECTORIES=$(find apps -type d -not -path '*dev*' -not -path '*stg*' -not -path '*test*' -not -path '*ithc*' -not -path '*demo*' -not -path '*sbox*' -not -path 'apps' -not -path '*dynatrace*' -not -path '*azureserviceoperator-system*' -not -path '*flux-system*' -not -path '*neuvector*' -not -path '*traefik2*')

# for dir in $DIRECTORIES; do
#     if ls "$dir" | grep -q -E 'kustomization\.ya?ml'; then
#         echo "Checking Directory $dir"
#         kustomize build --load-restrictor LoadRestrictionsNone "$dir" | yq eval 'select(.kind == "HelmRelease" and (.spec.values.nodejs.image != null or .spec.values.java.image != null))' >> $OUTPUTFILE


#             while read -r output; do
#                 nodejs_image=$(echo "$output" | yq eval '.spec.values.nodejs.image' -)

#                     echo "Error: No match found for image pattern in line: $output"
#                 fi
#             done < $OUTPUTFILE
#     fi
# done

IMAGE_PATTERN="^prod-[a-f0-9]+"
image="sdshmctspublic.azurecr.io/vh/admin-web:prod-67ad08e-202402071717"
extract_image=$(echo $image | cut -d ':' -f 2-)
# echo $extract_image

if [[  "$extract_image" =~  $IMAGE_PATTERN ]]; then
    echo "Images match the pattern"
else
    echo "Images do not match the pattern"
fi

# image: sdshmctspublic.azurecr.io/vh/admin-web:prod-67ad08e-202402071717
