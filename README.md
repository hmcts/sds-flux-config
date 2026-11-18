# sds-flux-config

## Sandbox Jenkins Java mitigation

For CVE-2026-114938, the [sandbox Jenkins overlay](apps/jenkins/jenkins/ptlsbox/jenkins.yaml)
sets `JDK_JAVA_OPTIONS=-XX:-UseBASE64Intrinsics` for the controller, Java build
processes and Kubernetes agent containers. The [VM agent overlay](apps/jenkins/jenkins/ptlsbox/jenkins-azure-vm-agent.yaml)
sets the same flag in agent `jvmOptions`. Existing Java options are preserved;
production and shared defaults are unchanged.

After an approved rollout, confirm the controller has restarted and drain/recreate
existing agents so their JVMs pick up the mitigation. Check
`jcmd <pid> VM.flags -all` for `UseBASE64Intrinsics = false` on the controller
and each agent type, and run a representative sandbox build checking the same flag
in its build JVMs. Pipeline-defined containers or environment overrides need
separate verification; Jenkins environment variables do not automatically enter
nested Docker containers. `JDK_JAVA_OPTIONS` requires Java 9 or later, so verify
any older build toolchains before rollout.

This is a temporary mitigation, not a JDK patch. Remove the flag from all the
above locations only after patched JDK images are deployed and verified.

## Flux

    `GitOps` leverages Git as the single source of truth to define every part of a cloud-native system. `Flux`is a tool for keeping Kubernetes clusters in sync with sources of configuration (like Git repositories and OCI artifacts), and automating updates to configuration when there is new code to deploy. Flux v2 is constructed with the GitOps Toolkit, a set of composable APIs and specialized tools for building Continuous Delivery on top of Kubernetes.

Please follow [cnp-flux-config](https://github.com/hmcts/cnp-flux-config) for documentation as both repos use `Flux` tool.

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
