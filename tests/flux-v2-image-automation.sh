#!/usr/bin/env bash
set -ex -o pipefail

EXCLUSIONS_LIST=(
  apps/flux-system/*
  apps/vh/*/stg.yaml
  .*demo.*.yaml
  .*test.*.yaml
  .*ithc.*.yaml
  .*sbox.*.yaml
  .*dev.*.yaml
)

EXCLUSIONS=$(IFS="|" ; echo "${EXCLUSIONS_LIST[*]}")
FILE_LOCATIONS="apps"

for FILE_LOCATION in $(echo ${FILE_LOCATIONS}); do

    IMAGE_POLICIES=()
    for FILE in $(grep -lr "imagepolicy" $FILE_LOCATION | grep -Ev "$EXCLUSIONS" ); do

        if [ $(yq eval '.kind' $FILE) != "HelmRelease" ]
        then
            continue
        fi

        IFS=$'\n'
        IMAGE_POLICIES+=($(grep -o "flux-system:.*" $FILE | cut -d ':' -f2 | sed 's/..$//'))

    done

    ./kustomize build --load-restrictor LoadRestrictionsNone "clusters/ptl/base" | yq eval 'select(.metadata and .kind == "ImagePolicy")' -  > imagepolicies_list.yaml
    [ $? -eq 0 ] || (echo "Kustomize build has failed" && exit 1)

    for IMAGE_POLICY in "${IMAGE_POLICIES[@]}"; do

        echo "Checking image policy: $IMAGE_POLICY"

        for path in $(echo "clusters/ptl/base"); do

        IMAGE_AUTOMATION=$(cat imagepolicies_list.yaml | \
        IMAGE_POLICY_NAME="${IMAGE_POLICY}" yq eval 'select(.metadata and .kind == "ImagePolicy" and .metadata.name == env(IMAGE_POLICY_NAME) )' -)



            if [ "$IMAGE_AUTOMATION" == "" ]
            then
                echo "No ImagePolicy for $IMAGE_POLICY in clusters/ptl-intsvc/base" && exit 1
            fi

            IMAGE_AUTOMATION_CHECK=$(cat imagepolicies_list.yaml  | \
            IMAGE_POLICY_NAME="${IMAGE_POLICY}" yq eval 'select(.metadata and .kind == "ImagePolicy" and .metadata.name == env(IMAGE_POLICY_NAME) )' - | yq eval '.spec.filterTags.pattern == "^prod-[a-f0-9]+-(?P<ts>[0-9]+)"' -)

            if [ $IMAGE_AUTOMATION_CHECK == false ]
            then
                echo "Non whitelisted pattern found in ImagePolicy: $IMAGE_POLICY it should be ^prod-[a-f0-9]+-(?P<ts>[0-9]+)" && exit 1
            fi
        done

        OUTPUTFILE="kustomization_images.txt"
        DIRECTORIES=$(find $FILE_LOCATIONS -type d -not -path "$EXCLUSIONS")

        for dir in $DIRECTORIES; do
            find "$dir" -not -name "*sbox*" -not -name "*ithc*" -not -name "*perftest*" -not -name "*test*" -not -name "*demo*" -not -name "*stg*" -not -name "*dev*" -not -name "*00*" -not -name "*aat*"  -not -name "*sandbox*"
            ./kustomize build --load-restrictor LoadRestrictionsNone "$dir" 2>&1 | yq eval 'select(.kind == "HelmRelease" and (.spec.values.nodejs.image != null or .spec.values.java.image != null))' >> $OUTPUTFILE

            IMAGE_PATTERN="^prod-[a-f0-9]+-(?P<ts>[0-9]+)"

            if ! grep -q "$IMAGE_PATTERN" "$OUTPUTFILE"; then
                echo "No match found in $OUTPUTFILE. Exiting with status 1."
                exit 1
            fi
        done
    done
done