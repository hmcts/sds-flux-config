# Themis sandbox CSI baseline

This is a Key Vault authentication smoke test, not a Themis application
deployment. Its sandbox-owned configuration copies the test settings and uses
`libragob-test-kv`, but replaces the application image with a digest-pinned
BusyBox image from the existing HMCTS registry. The container only sleeps:
it does not start Themis,
connect to databases, consume Service Bus queues, or read/log secret contents.
HTTP probes, application ingress and Helm tests are disabled.
The pod also disables automatic Kubernetes API token mounting to satisfy the
sandbox admission policy; the idle container does not use the Kubernetes API.

The archived chart still generates the CSI provider and pod mounts. A Helm
post-renderer replaces the container command and removes probes. Successful pod
readiness means the idle container is running after its mounts, not that Themis
or its WSDL is healthy.

## Scope and wiring

- Only `clusters/sbox/01` includes `met-schema`.
- Its path resolves to `apps/met/sbox/base`, using the existing
  `sds-helm-charts` GitRepository and chart path `./charts/met` (parent `0.1.3`,
  nodejs `2.4.5`). That shared source follows the archived repository's
  `master` branch; record the actual revision during deployment.
- The baseline uses namespace `met`, release `met-themis-fe`, one replica, the
  test managed identity and all 20 test-vault secret definitions.
- It shares generic platform and Themis base resources, but does not reference
  any test environment YAML. Future changes to those test files do not change
  this sandbox configuration.
- There is no separate chart source, upgrade overlay, federated credential or
  patch that converts `nodejs` values to `java`.
- Batch jobs and the nightly pod-delete CronJob are not included. Test and
  production compositions are unchanged; sandbox/00 does not include Themis.
- Common application resources receive namespace `met` through the existing
  Flux substitutions.

## Files

| File | Purpose |
|---|---|
| [base/kustomization.yaml](base/kustomization.yaml) | Composes shared bases and sandbox-owned settings |
| [sbox.yaml](../../themis-fe/sbox.yaml) | Copied test settings, idle image, resources and probe-removal post-renderer |
| [base/identity.yaml](base/identity.yaml) | Sandbox AzureIdentity and binding using the existing test identity |
| [base/serviceaccount.yaml](base/serviceaccount.yaml) | Sandbox namespace-account annotation |

## Prerequisites

1. Use the existing sandbox/01 cluster and confirm API connectivity.
2. Ensure namespace `met` is available for this test and no existing release or
   resources with these names would be taken over.
3. Ensure sandbox Flux follows the Git branch containing these changes. Merely
   pushing a branch does not switch the cluster's existing source.
4. Ensure the shared `sds-helm-charts` source is Ready, chart dependencies are
   retrievable and the node identity can pull the BusyBox image.
5. Sandbox MIC/NMI must support using the existing
   test managed identity from the sandbox nodes, including any required
   cross-subscription identity-assignment permissions. Creating AzureIdentity
   and AzureIdentityBinding objects alone does not establish those permissions.
   The old chart also needs the CSI `v1alpha1` API to be served. Treat a missing
   prerequisite as a baseline blocker.
6. Reuse the test identity's existing secret-read access to `libragob-test-kv`.
   Its client ID is `f50fe277-9215-4519-a1d4-8b88e8f7cb92`.
   Do not grant a broad Contributor role.

No Azure permissions, cluster resources or Flux source branches are changed by
editing these files locally.

## Deployment and checks

Deploy this branch through the sandbox/01 GitOps source using the normal review
process. The cluster composition already includes the baseline. Do not apply
the raw application Kustomize output without Flux substitutions/defaults.

Use explicit context for read-only checks:

```bash
CTX=ss-sbox-01-aks
kubectl --context="$CTX" -n flux-system get gitrepository sds-helm-charts
kubectl --context="$CTX" -n flux-system get kustomization met-schema
kubectl --context="$CTX" -n met get helmrelease themis-fe
kubectl --context="$CTX" -n met get deployment met-themis-fe-nodejs -o json |
  jq '{replicas:.spec.replicas,ready:.status.readyReplicas,
       labels:.spec.template.metadata.labels,
       account:.spec.template.spec.serviceAccountName,
<<<<<<< HEAD
       automountServiceAccountToken:.spec.template.spec.automountServiceAccountToken,
=======
>>>>>>> master
       containers:[.spec.template.spec.containers[] |
         {image,command,args,startupProbe,livenessProbe,readinessProbe}]}'
kubectl --context="$CTX" -n met get pods \
  -l app.kubernetes.io/name=met-themis-fe-nodejs \
  -o 'custom-columns=NAME:.metadata.name,UID:.metadata.uid,READY:.status.containerStatuses[*].ready,CREATED:.metadata.creationTimestamp'
kubectl --context="$CTX" -n met get secretproviderclass met-themis-fe-nodejs-libragob-test-kv -o json |
  jq '{apiVersion,parameters:(.spec.parameters | {keyvaultName,usePodIdentity,clientID})}'
kubectl --context="$CTX" -n met get secretproviderclasspodstatuses -o json |
  jq '[.items[] | {pod:.status.podName,mounted:.status.mounted,
       objectCount:((.status.objects // []) | length)}]'
```

Baseline pass: the source and release are Ready; the sole fresh pod runs only
the idle command; all 20 expected secret objects are mounted; account is
`met-themis-fe-nodejs`; CSI uses pod identity. Record the pod UID and source
revision. Inspect status and object metadata only, never mounted file contents.
<<<<<<< HEAD
The pod must explicitly set `automountServiceAccountToken: false`; otherwise
sandbox Gatekeeper rejects pod creation before scheduling or CSI mounting.
=======
>>>>>>> master

This proves only the old chart's CSI authentication path. It does not validate
Themis startup, databases, Service Bus, WSDL, ingress, sticky sessions, JVM
options or production replica scheduling.

## Later migration

The Java migration is a later reviewed code change to the sandbox configuration:
rename its `nodejs` values block to `java`, change the chart source/path and
configure Workload Identity with the required federation. There is no
preconfigured upgrade stage or values-conversion patch.

## Cleanup

After testing, remove the sandbox/01 wiring and sandbox-only resources through
a reviewed Git change. Do not remove the shared chart source, test managed
identity, platform components or test/production Themis deployments.
