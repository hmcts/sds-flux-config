#!/usr/bin/env bash
# set -ex

NAMESPACE='${NAMESPACE}'
ENVIRONMENT='${ENVIRONMENT}'
NAMESPACE_NAME="$1"
APP_NAME="$2"
APPS_DIR="../../apps/"
CLUSTERS_DIR="../../clusters"

PASSWORD=$(openssl rand -base64 15)

function usage() {
  echo 'usage: ./postgres-setup.sh <namespace> <app_name>'
}

if [ -z "${NAMESPACE_NAME}" ] || [ -z "${APP_NAME}" ]; then
  usage
  exit 1
fi

if [ ! -f "apps/$NAMESPACE_NAME/dev/aso" ]; then
  echo "Creating aso"
  mkdir -p apps/$NAMESPACE_NAME
  mkdir -p apps/$NAMESPACE_NAME/dev
  mkdir -p apps/$NAMESPACE_NAME/dev/aso

  (
    cat <<EOF
apiVersion: dbforpostgresql.azure.com/v1api20210601
kind: FlexibleServersConfiguration
metadata:
  name: extensions
  namespace: ${NAMESPACE}
  annotations:
    serviceoperator.azure.com/reconcile-policy: detach-on-delete
spec:
  owner:
    name: ${NAMESPACE}-${ENVIRONMENT}
  azureName: azure.extensions
  source: user-override
  value: "btree_gin"
EOF
  ) >"apps/$NAMESPACE_NAME/dev/aso/$NAMESPACE_NAME-postgres-config.yaml"

  (
    cat <<EOF
apiVersion: dbforpostgresql.azure.com/v1api20210601
kind: FlexibleServer
metadata:
  name: ${NAMESPACE}-${ENVIRONMENT}
  namespace: ${NAMESPACE}
spec:
  version: "16"
EOF
  ) >"apps/$NAMESPACE_NAME/dev/aso/$NAMESPACE_NAME-postgres.yaml"
fi

if [ ! -f "apps/$NAMESPACE_NAME/dev/sops-secrets" ]; then
  echo "Creating sops-secrets"
  mkdir -p apps/$NAMESPACE_NAME
  mkdir -p apps/$NAMESPACE_NAME/dev
  mkdir -p apps/$NAMESPACE_NAME/dev/sops-secrets
fi

(
  cat <<EOF
apiVersion: v1
data:
  PASSWORD: $PASSWORD
kind: Secret
metadata:
    creationTimestamp: null
    name: postgres
    namespace: $NAMESPACE_NAME
type: Opaque
EOF
) >"apps/$NAMESPACE_NAME/dev/sops-secrets/$APP_NAME-values.enc.yaml"

if ! [ -f /usr/local/bin/sops ]; then
  echo "Sops is not installed... installing..."
  curl -LO https://github.com/getsops/sops/releases/download/v3.9.1/sops-v3.9.1.darwin.amd64
  mv sops-v3.9.1.darwin.amd64 /usr/local/bin/sops
  chmod +x /usr/local/bin/sops
fi

sops --encrypt --azure-kv https://dtssharedservicesdevkv.vault.azure.net/keys/sops-key/2beba064ddfe454482ad0133af2cf0fd --encrypted-regex "^(data|stringData)$" --in-place apps/$NAMESPACE_NAME/dev/sops-secrets/$APP_NAME-values.enc.yaml

(
  cat <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../../azureserviceoperator-system/resources/resource-group.yaml
  - ../../../azureserviceoperator-system/resources/flexibleserver-postgres.yaml
  - ../../../azureserviceoperator-system/resources/flexibleserver-postgres-config.yaml
  - $APP_NAME-postgres.enc.yaml
namespace: $NAMESPACE_NAME
EOF
) >"apps/$NAMESPACE_NAME/dev/sops-secrets/kustomization.yaml"
