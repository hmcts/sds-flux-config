# Themis test/00 Workload Identity CSI check

This is a Key Vault authentication smoke test, not a Themis application
deployment. It runs in `ss-test-00-aks`, namespace `met`, beside the existing
test deployment. A digest-pinned BusyBox container only sleeps. It does not
start Themis, connect to databases, consume Service Bus queues, or read/log
secret contents. The CSI provider must contact Key Vault to mount secrets.
The image-automation CI check excludes only this migration HelmRelease from
the production tag convention so BusyBox can remain pinned by digest.

## Isolation and wiring

- Only [clusters/test/00](../../../../clusters/test/00/kustomization.yaml)
  includes Flux Kustomization and GitRepository `met-themis-chart-migration`.
- [kustomize.yaml](kustomize.yaml) reconciles independently of `met-schema`.
- [base/kustomization.yaml](base/kustomization.yaml) owns only its HelmRelease.
  It does not own the shared namespace, namespace ServiceAccount, alerts, jobs
  or federation. The migration's former AzureIdentity and AzureIdentityBinding
  are removed through Flux pruning; the existing `met-schema` objects remain.
- [base/helmrelease.yaml](base/helmrelease.yaml) uses HelmRelease/release
  `met-themis-chart-migration`. Chart resource names use the `met-themis-chart-migration-nodejs` prefix,
  distinct from the existing `met-themis-fe-nodejs` resources and selectors.
  The existing nightly deletion job selects only `met-themis-fe-nodejs`.
- The new chart selects existing ServiceAccount `met` in namespace `met`,
  annotated with test client ID `f50fe277-9215-4519-a1d4-8b88e8f7cb92`.
  It reuses `libragob-test-mi` and federated credential `libragob-test-00-fic`
  with subject `system:serviceaccount:met:met`. Neither is modified here.
- [gitrepo.yaml](gitrepo.yaml) supplies the root chart from
  `hmcts/chart-libragob-frontend`, branch `main`
  (parent `0.3.0`, Java `6.1.1`). The Helm chart follows source revisions;
  record the deployed artifact revision.
- Values now use `java`, with Workload Identity enabled. The parent preserves
  the `<release>-nodejs` resource names. The smoke-test anti-affinity selector
  is overridden to match only `met-themis-chart-migration-nodejs`, not the
  original Themis deployment.
- The configuration is independent of test application values. It retains all
  20 `libragob-test-kv` secret definitions for comparison.
- There is one idle replica, no application ingress or HTTP probes, no
  autoscaling, and no Helm tests. The post-renderer explicitly disables
  Kubernetes API token automounting.
- Sandbox wiring is removed. Test/01 and production wiring are unchanged.
  Removing the previous sandbox Kustomization through Flux can prune its
  previously managed resources, including the sandbox `met` namespace.
  Confirm that namespace contains no unrelated workloads before deploying
  the sandbox cleanup.

The shared namespace, cluster capacity and managed identity are still shared
dependencies. Unique names prevent resource takeover; they do not provide
complete runtime isolation. ServiceAccount `met` and its federation are also
shared prerequisites, not migration-owned resources.

## Accepted AAD Pod Identity baseline

On 2026-11-19, the old parent `0.1.3` with nodejs `2.4.5` mounted all 20 objects
using AAD Pod Identity. The user confirmed the mounted files were populated.
The read-only status check reported `mounted: true` and object count `20` for
pod `met-themis-chart-migration-nodejs-7b74b5785f-9d76s`.
This is the comparison baseline, not proof of Workload Identity authentication.

## Prerequisites and deployment

1. Confirm this branch has passed review and is selected by the test/00 Flux
   source. Local edits do not deploy anything.
2. Confirm namespace `met` exists and the original `themis-fe` release is
   healthy. After applying this change, require GitRepository
   `met-themis-chart-migration` to be Ready at the intended chart revision.
3. Confirm ServiceAccount `met` retains the test client-ID annotation and
   `libragob-test-00-fic` is Ready for the test/00 issuer and subject
   `system:serviceaccount:met:met`. The Java library performs a live
   ServiceAccount lookup when rendering CSI configuration. If that lookup
   fails, it can fall back to pod identity; reject that result.
4. Reuse the identity's existing secret-read access to `libragob-test-kv`.
   Do not grant broad Contributor permissions.
5. Deploy through the normal GitOps review process. Do not apply raw application
   output without Flux defaults and substitutions.

## Read-only acceptance checks

```bash
CTX=ss-test-00-aks
kubectl --context="$CTX" -n flux-system get gitrepository sds-helm-charts
kubectl --context="$CTX" -n flux-system get gitrepository met-themis-chart-migration
kubectl --context="$CTX" -n flux-system get kustomization met-schema met-themis-chart-migration
kubectl --context="$CTX" -n met get helmrelease themis-fe met-themis-chart-migration
kubectl --context="$CTX" -n met get serviceaccount met -o json |
  jq '{name:.metadata.name,clientID:.metadata.annotations["azure.workload.identity/client-id"]}'
kubectl --context="$CTX" -n met get federatedidentitycredential libragob-test-00-fic -o json |
  jq '{issuer:.spec.issuer,subject:.spec.subject,audiences:.spec.audiences,
       conditions:.status.conditions}'
kubectl --context="$CTX" -n met get deployment met-themis-chart-migration-nodejs -o json |
  jq '{replicas:.spec.replicas,ready:.status.readyReplicas,
       labels:.spec.template.metadata.labels,
       account:.spec.template.spec.serviceAccountName,
       automountServiceAccountToken:.spec.template.spec.automountServiceAccountToken,
       containers:[.spec.template.spec.containers[] |
         {image,command,args,startupProbe,livenessProbe,readinessProbe}]}'
kubectl --context="$CTX" -n met get pods \
  -l app.kubernetes.io/name=met-themis-chart-migration-nodejs \
  -o 'custom-columns=NAME:.metadata.name,UID:.metadata.uid,READY:.status.containerStatuses[*].ready,CREATED:.metadata.creationTimestamp'
kubectl --context="$CTX" -n met get secretproviderclass met-themis-chart-migration-nodejs-libragob-test-kv -o json |
  jq '{apiVersion,parameters:(.spec.parameters | {keyvaultName,clientID,usePodIdentity})}'
kubectl --context="$CTX" -n met get secretproviderclasspodstatuses -o json |
  jq '[.items[] |
       select(.status.secretProviderClassName == "met-themis-chart-migration-nodejs-libragob-test-kv") |
       {pod:.status.podName,mounted:.status.mounted,
        objectCount:((.status.objects // []) | length)}]'
```

Workload Identity pass: source and smoke-test release are Ready; the sole fresh
pod runs only the idle command with API-token automount disabled and
ServiceAccount `met`; its label `azure.workload.identity/use` is `"true"` and
it has no `aadpodidbinding` label. CSI uses the test `clientID`, with
`usePodIdentity` absent or `"false"`, and all 20 expected objects are mounted.
The Workload Identity webhook may inject its own projected token; that is
separate from automatic Kubernetes API token mounting.

Record a new pod UID, chart source revision, mounted object metadata and the
existing Themis release's health. Require a pod created after the upgrade;
the old pod's mounted files do not prove Workload Identity works. Inspect
metadata only, never mounted file contents. Readiness does not validate Themis
or any downstream integration.

## Cleanup

After both checks, remove only `met-themis-chart-migration` wiring and its owned resources
through reviewed GitOps cleanup. Do not remove the shared namespace, original
Themis release, shared chart sources, test managed identity, ServiceAccount
`met`, its federated credential or existing identity binding. The dedicated
migration GitRepository can be removed with the migration wiring.
