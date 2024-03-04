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
    .*perftest*
    .*sbox*
    .*test*
    .*stg*
    .*dev*
    .*aat*
    .*toffee*
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

        OUTPUTFILE="images.yaml"
        DIRECTORIES=$(find apps -type d -not -path "$EXCLUSIONS")
        cd ../apps

        for dir in $DIRECTORIES; do

            echo "Checking HelmRelease in $dir"
            kustomize build --load-restrictor LoadRestrictionsNone "$dir" | yq eval 'select(.kind == "HelmRelease" and (.spec.values.nodejs.image != null or .spec.values.java.image != null))' > $OUTPUTFILE

            # IMAGE_PATTERN="^prod-[a-f0-9]+-(?P<ts>[0-9]+)"

            # while read -r output; do
            #     nodejs_image=$(echo "$output" | yq eval '.spec.values.nodejs.image' -)
            #     java_image=$(echo "$output" | yq eval '.spec.values.java.image' -)

            #     if [[ "$nodejs_image" && "$java_image" != $IMAGE_PATTERN ]]; then
            #         echo "Error: No match found for image pattern in line: $output"
            #     fi
            # done
        done
    done
done