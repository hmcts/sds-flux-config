#!/usr/bin/env bash
# set -ex -o pipefail

EXCLUSIONS_LIST=(
    # apps/flux-system/*
    # apps/my-time/my-time-frontend/my-time-frontend.yaml
    # apps/met/themis-fe/prod.yaml
    # apps/aspnet/dotnet48/dotnet48.yaml
    # apps/hmi/hmi-rota-dtu/hmi-rota-dtu.yaml
    .*perftest.*
    .*sbox.*
    .*test.*
    .*stg.*
    .*staging.*
    .**dev.*
    .*aat.*
    .*demo.*
    .*ithc.*
    .*toffee.*
)

EXCLUSIONS=$(IFS="|" ; echo "${EXCLUSIONS_LIST[*]}")

FILE_LOCATIONS="apps"

for FILE_LOCATION in $(echo ${FILE_LOCATIONS}); do

    IMAGE_POLICIES=()
    for FILE in $(grep -lr "imagepolicy" $FILE_LOCATION | grep -Ev "$EXCLUSIONS" ); do

        while read -r doc; do
            if [ "$doc" != "HelmRelease" ]; then
                continue
            fi
        done < <(yq eval '.kind' $FILE)

        IFS=$'\n'
        IMAGE_POLICIES+=($(grep -o "flux-system:.*" $FILE | cut -d ':' -f2 | sed 's/..$//'))

    done

    ./kustomize build --load-restrictor LoadRestrictionsNone "clusters/ptl/base" | yq eval 'select(.metadata and .kind == "ImagePolicy")' -  > imagepolicies_list.yaml
    [ $? -eq 0 ] || (echo "Kustomize build has failed" && exit 1)

    for IMAGE_POLICY in "${IMAGE_POLICIES[@]}"; do

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
    done

    ##############################################################################################################
    # Print success if ALL image policies are clean
    ##############################################################################################################
    printf "\n\n########## Image Policy documents checked and passing ########## \n\n"

    ##############################################################################################################
    # This section compiles a list of files that contains `image:` and stores them in an array HELMRELEASES
    # Only files that follow these rules will be added to the array:
    # - Contains the `image:` string
    # - Is HelmRelease type document
    ##############################################################################################################

    HELMRELEASES=()
    for FILE in $(grep -lr "image:" $FILE_LOCATION | grep -Ev "$EXCLUSIONS" ); do
        while read -r doc; do
            if [ "$doc" == "HelmRelease" ]; then
                IFS=$'\n'
                HELMRELEASES+=("$FILE")
            fi
        done < <(yq eval '.kind' $FILE)
    done

    OUTPUTFILE="images.yaml"
    DIRECTORIES=("apps")  # Define DIRECTORIES as an array

    for dir in $DIRECTORIES; do
        exclude=false
        for EXCLUDED_PATH in "${HELMRELEASES[@]}"; do
            if [[ $dir == $EXCLUDED_PATH* ]]; then
                exclude=true
                break
            fi
        done

        if ! $exclude && ls "$dir" | grep -q -E 'kustomization\.ya?ml'; then
            kustomize build --load-restrictor LoadRestrictionsNone "$dir" 2>&1 | yq eval 'select(.kind == "HelmRelease" and (.spec.values.image or .spec.values.*.image != null))' >> $OUTPUTFILE
        fi
    done

    for RELEASE in "${HELMRELEASES[@]}"; do
        nodejs_image=$(yq eval '.spec.values.nodejs.image' $RELEASE) && java_image=$(yq eval '.spec.values.java.image' $RELEASE)
        extract_nodejs_image=$(echo $nodejs_image | cut -d ':' -f 2-)
        extract_java_image=$(echo $java_image | cut -d ':' -f 2-)

        if [ "$(yq eval 'test("^prod-[a-f0-9]+-([0-9]+)")' <<< "$extract_nodejs_image")" = "false" ] || [ "$(yq eval 'test("^prod-[a-f0-9]+-([0-9]+)")' <<< "$extract_java_image")" = "false" ]; then
            echo "!! Non whitelisted pattern found in HelmRelease: $RELEASE it should be prod-[a-f0-9]+-(?P<ts>[0-9]+)" && exit 1
        fi
    done
    ##############################################################################################################
    # Print success if ALL Helm Release image fields are valid
    ##############################################################################################################
    printf "\n\n ########## Helm Release documents checked and passing ########## \n\n"
done