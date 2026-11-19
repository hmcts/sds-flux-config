# Themis test/00 CSI baseline

This is a Key Vault authentication smoke test, not a Themis application
deployment. It runs in `ss-test-00-aks`, namespace `met`, beside the existing
test deployment. A digest-pinned BusyBox container only sleeps. It does not
start Themis, connect to databases, consume Service Bus queues, or read/log
secret contents. The CSI provider must contact Key Vault to mount secrets.

## Isolation and wiring

- Only [clusters/test/00](../../../../clusters/test/00/kustomization.yaml)
  includes Flux Kustomization `met-themis-chart-migration`.
- [kustomize.yaml](kustomize.yaml) depends on the existing `met-schema`
  Kustomization for namespace/platform prerequisites. It does not change it.
- [base/kustomization.yaml](base/kustomization.yaml) owns only its HelmRelease,
  AzureIdentity and AzureIdentityBinding. It does not own the shared namespace,
  namespace ServiceAccount, alerts, jobs or federation.
- [base/helmrelease.yaml](base/helmrelease.yaml) uses HelmRelease/release
  `met-themis-chart-migration`. Chart resource names use the `met-themis-chart-migration-nodejs` prefix,
  distinct from the existing `met-themis-fe-nodejs` resources and selectors.
  The existing nightly deletion job selects only `met-themis-fe-nodejs`.
- [base/identity.yaml](base/identity.yaml) uses separate Kubernetes identity
  objects and selector `met-themis-chart-migration`, referencing the existing
  `libragob-test-mi` Azure managed identity. It does not change Azure permissions.
- The archived `sds-helm-charts` GitRepository supplies `./charts/met`
  (parent `0.1.3`, nodejs `2.4.5`). Record its actual artifact revision.
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
complete runtime isolation.

## Prerequisites and deployment

1. Confirm this branch has passed review and is selected by the test/00 Flux
   source. Local edits do not deploy anything.
2. Confirm `met-schema` and `sds-helm-charts` are Ready and the new resource
   names do not already belong to another workload.
3. Confirm AAD Pod Identity MIC/NMI and the legacy CSI API work on test/00.
   MIC must be able to assign `libragob-test-mi` to the test node VM scale set.
   The former sandbox run failed with `LinkedAuthorizationFailed` on this
   identity; being in test alone does not prove assignment permission.
4. Reuse the identity's existing secret-read access to `libragob-test-kv`.
   Do not grant broad Contributor permissions.
5. Deploy through the normal GitOps review process. Do not apply raw application
   output without Flux defaults and substitutions.

## Read-only acceptance checks

```bash
CTX=ss-test-00-aks
kubectl --context="$CTX" -n flux-system get gitrepository sds-helm-charts
kubectl --context="$CTX" -n flux-system get kustomization met-schema met-themis-chart-migration
kubectl --context="$CTX" -n met get helmrelease themis-fe met-themis-chart-migration
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
  jq '{apiVersion,parameters:(.spec.parameters | {keyvaultName,usePodIdentity})}'
kubectl --context="$CTX" -n met get secretproviderclasspodstatuses -o json |
  jq '[.items[] |
       select(.status.secretProviderClassName == "met-themis-chart-migration-nodejs-libragob-test-kv") |
       {pod:.status.podName,mounted:.status.mounted,
        objectCount:((.status.objects // []) | length)}]'
```

Baseline pass: source and smoke-test release are Ready; the sole fresh pod runs
only the idle command with token automount disabled; its ServiceAccount is
`met-themis-chart-migration-nodejs`; CSI uses pod identity; all 20 expected objects are
mounted. Record the pod UID, chart source revision, mounted object metadata and
the existing Themis release's health. Inspect metadata only, never mounted file
contents. Readiness does not validate Themis or any downstream integration.

## Later migration and cleanup

Only after the AAD Pod Identity baseline passes, make a separate reviewed
change to this same smoke test: select the Java chart, convert `nodejs` values
to `java`, and configure Workload Identity with the correct ServiceAccount and
federated credential. Keep BusyBox and the same secret list for comparison.
No Workload Identity stage or federation is provisioned here.

After both checks, remove only `met-themis-chart-migration` wiring and its owned resources
through reviewed GitOps cleanup. Do not remove the shared namespace, original
Themis release, chart source, test managed identity or existing identity binding.
