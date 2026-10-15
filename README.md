# sds-flux-config

## Flux

    `GitOps` leverages Git as the single source of truth to define every part of a cloud-native system. `Flux`is a tool for keeping Kubernetes clusters in sync with sources of configuration (like Git repositories and OCI artifacts), and automating updates to configuration when there is new code to deploy. Flux v2 is constructed with the GitOps Toolkit, a set of composable APIs and specialized tools for building Continuous Delivery on top of Kubernetes.

Please follow [cnp-flux-config](https://github.com/hmcts/cnp-flux-config) for documentation as both repos use `Flux` tool.

## Service account API token automounting

Applications inheriting `apps/base` disable API token automounting through
environment-specific patches in `apps/<application>/serviceaccount/`, referenced
by their environment Kustomizations. This rollout covers non-production
environments, including `ptlsbox`, but excludes `prod` and `ptl`.

Namespaces excluded by the `mg:HMCTS` and SDS `DTS-SHAREDSERVICES*` assignments of
[`assign.aks.disable_automount_creds.json`](https://github.com/search?q=repo%3Ahmcts%2Fazure-policy+assign.aks.disable_automount_creds.json&type=code)
are left unchanged, including existing explicit `true` opt-ins. CFT subscription
exclusions are not used for this repository.

The shared `apps/base/service-account.yaml` remains unchanged during the staged
rollout. When its default is eventually set to `false`, explicit `true` patches
will take precedence and redundant `false` patches can be removed.

## Encrypting Secrets With Sops

Secrets can be stored in this repository but they must be encrypted using the SOPS tool.

[Click here for info on how to setup SOPS](docs/secrets-sops-encryption.md).

## Preventing commit of secrets

To prevent unencrypted secrets being committed to this repository, a pre-commit hook has been provided via `.pre-commit-config.yaml`

To install it, run `brew install pre-commit` and then `pre-commit install` on macOS or Linux (with homebrew).

On the first commit after installing, `pyyaml` will be downloaded and installed to parse the yaml files in the repo.

This will take a bit longer than normal to install but future commits should take place at the normal speed.

This hook will also run as a github action to ensure bypass has not occurred.

The action can be found at [sops-secrets](.github/workflows/sops-secrets.yml)
