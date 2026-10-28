# Static authentication secrets

Demo, ITHC and test apply these shared patches to Helm releases in `darts-magistrates`.
The API and automated tasks releases use the following mappings for both `java` and `function` workloads:

| Key Vault secret | Application alias |
|------------------|-------------------|
| `StaticAzureAdB2CTenantId` | `AAD_B2C_TENANT_ID` |
| `StaticAzureAdB2CClientId` | `AAD_B2C_CLIENT_ID` |
| `StaticAzureAdB2CClientSecret` | `AAD_B2C_CLIENT_SECRET` |
| `StaticAzureADTenantIdJustice` | `AAD_TENANT_ID_JUSTICE` |
| `StaticAzureADClientIdJustice` | `AAD_CLIENT_ID_JUSTICE` |
| `StaticAzureADClientSecretJustice` | `AAD_CLIENT_SECRET_JUSTICE` |

The gateway uses the same static B2C tenant and client ID. The portal delegates authentication to the API and does not load these credentials.
ROPC functional test credentials and the separate legacy `AzureAD` credentials retain their existing names.
Staging and production do not apply these patches.

Provision the six static secrets in each environment's DARTS Key Vault before reconciliation.
These files reference secret names only; secret values remain in Key Vault.
The mappings must identify the same app registrations across all consumers in each environment.

Helm replaces secret lists, so the patches retain complete lists from `hmcts-charts/stable/darts-api/values.yaml`
and `hmcts-charts/stable/darts-gateway/values.yaml`. Keep unrelated mappings aligned when those charts add or remove secrets.

Validate by rendering each environment with `kubectl kustomize apps/darts-magistrates/<environment>/base --load-restrictor LoadRestrictionsNone`.
To roll back, remove the two shared patch references from each affected environment and reconcile Flux;
the chart's original secret mappings will be restored.
