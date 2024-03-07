#!/usr/bin/env bash
# set -ex -o pipefail

EXCLUSIONS_LIST=(
    apps/flux-system/*
    apps/my-time/my-time-frontend/my-time-frontend.yaml
    apps/met/themis-fe/prod.yaml
    apps/aspnet/dotnet48/dotnet48.yaml
    apps/hmi/hmi-rota-dtu/hmi-rota-dtu.yaml
    apps/juror-digital/jd-public/*
    apps/juror-digital/jd-bureau/*
    apps/juror-digital/moj-reverse-proxy/*
    apps/jenkins/jenkins/*
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

    ##############################################################################################################
    # This section compiles a list of files that contains `imagepolicy` and stores them in an array IMAGE_POLICIES
    # Only files that follow these rules will be added to the array:
    # - Contains the `imagepolicy` string 
    # - Is NOT in the exclusions list
    # - Is not HelmRelease type document
    ##############################################################################################################
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

    ##############################################################################################################
    # This section will scan the PTL cluster to find all ImagePolicy configs and add them to temporary yaml file
    # Only scans `clusters/ptl/base` because thats where Image Policies are found, scanning other clusters will
    # result in no output
    ##############################################################################################################
    ./kustomize build --load-restrictor LoadRestrictionsNone "clusters/ptl/base" | yq eval 'select(.metadata and .kind == "ImagePolicy")' -  > imagepolicies_list.yaml
    [ $? -eq 0 ] || (echo "Kustomize build has failed" && exit 1)

    ##############################################################################################################
    # This section loops over each file in the IMAGE_POLICIES array and compares the file with the documents added 
    # to the temporary file imagepolicies_list.yaml
    # If a document is found in the temporary file with the matching name of a policy it is then checked to see
    # if its pattern value matches the specified Prod regex.
    # If this results in a false (i.e. it doesnt match) the script will fail and print the offending Policy name.
    ##############################################################################################################
    for IMAGE_POLICY in "${IMAGE_POLICIES[@]}"; do

        for path in $(echo "clusters/ptl/base"); do

            IMAGE_AUTOMATION=$(cat imagepolicies_list.yaml | \
            IMAGE_POLICY_NAME="${IMAGE_POLICY}" yq eval 'select(.metadata and .kind == "ImagePolicy" and .metadata.name == env(IMAGE_POLICY_NAME) )' -)

            if [ "$IMAGE_AUTOMATION" == "" ]
            then
                echo "No ImagePolicy for $IMAGE_POLICY in clusters/ptl/base" && exit 1
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

    ##############################################################################################################
    # This section loops over each file in the HELMRELEASES array and checks that it contains an image
    # field that is not null.
    # If not null the image field value is then stripped out and the image Tag value is stored in a variable TAG
    # If that value is not null we then check if the value matches the specificed Prod regex pattern
    # If this results in a false (i.e. it doesnt match) the script will fail and print the offending Policy name.
    ##############################################################################################################

    for RELEASE in "${HELMRELEASES[@]}"; do
    
        IMAGE_TAG_FOUND=$(yq eval 'select(.spec.values.image) or (.spec.values.*.image) != null' $RELEASE)
        
        if [ "$IMAGE_TAG_FOUND" != "" ]
        then
            TAG=$(grep -o "image:.*" $RELEASE | cut -d ':' -f3 | cut -d ' ' -f1  | tr -d \')
            if [ "$TAG" != "" ]
            then
                while read -r doc; do
                    if [ "$doc" == false ]; then
                        echo "!! Non whitelisted pattern found in HelmRelease: $RELEASE it should be prod-[a-f0-9]+-(?P<ts>[0-9]+)" && exit 1
                    fi
                done < <(yq '((.spec.values.image) or (.spec.values.*.image) | test("prod-[a-f0-9]+-(?P<ts>[0-9]+)"))' $RELEASE)
            fi
        fi
    done

    ##############################################################################################################
    # Print success if ALL Helm Release image fields are valid
    ##############################################################################################################
    printf "\n\n ########## Helm Release documents checked and passing ########## \n\n"

done

