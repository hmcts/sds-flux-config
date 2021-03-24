#!/usr/bin/env bash
set -x

curl -s "https://raw.githubusercontent.com/\
kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" -o install_kustomize.sh && chmod +x install_kustomize.sh && ./install_kustomize.sh 3.7.0


kustomizepaths=(
    k8s/environments/demo/cluster-00-overlay
    k8s/environments/demo/cluster-01-overlay
    # k8s/environments/demo/common-overlay
    k8s/environments/dev/cluster-00-overlay
    k8s/environments/dev/cluster-01-overlay
    k8s/environments/dev/common-overlay
    k8s/environments/ithc/cluster-00-overlay
    k8s/environments/ithc/cluster-01-overlay
    k8s/environments/ithc/common-overlay
    # k8s/environments/prod/cluster-00-overlay
    k8s/environments/prod/cluster-01-overlay
    k8s/environments/prod/common-overlay
    k8s/environments/sbox/cluster-00-overlay
    k8s/environments/sbox/cluster-01-overlay
    k8s/environments/sbox/common-overlay
    k8s/environments/stg/cluster-00-overlay
    k8s/environments/stg/cluster-01-overlay
    k8s/environments/stg/common-overlay
    k8s/environments/test/cluster-00-overlay
    k8s/environments/test/cluster-01-overlay
    k8s/environments/test/common-overlay
)

for filepath in "${kustomizepaths[@]}"; do
     ./kustomize build --load_restrictor none "$filepath" >/dev/null
     if [ $? -eq 1 ]
     then
      echo "Kustomize failing for env $filepath" && exit 1
     fi
done

prod_whitelist_helm_release_pattern='vh\|toffee' # Helm Release names seperated by `\|`

for env in $(echo "prod"); do
 env_white_list=${env}_whitelist_helm_release_pattern
  for filepath in $(echo "k8s/environments/$env/cluster-00-overlay" "k8s/environments/$env/cluster-01-overlay k8s/environments/$env/common-overlay"); do
    ./kustomize build --load_restrictor none "$filepath" | yq e 'del(.metadata)' -j - |  (grep \"hmcts.github.com/prod-automated\":\"disabled\" || true ) | grep -v "${!env_white_list}"
    if [ $? -eq 0 ]
    then
      echo "Non whitelisted HelmReleases found with hmcts.github.com/prod-automated annotation in $filepath" && exit 1
    fi
done
done
