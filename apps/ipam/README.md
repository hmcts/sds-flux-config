# IPAM
We have deployed ipam following some of the documetation here - https://azure.github.io/ipam/#/  , please note that there is no official documentation on ipam on AKS so we manage to deploy it by doing some research and then some help from the ipam support team.

ipam is available here, you would NOT need VPN as we have configured it behind app proxy - https://ipam.hmcts.net/

## IPAM resources
This are the resources deployed part of the ipam deployment on AKS.
App Registration X 2  - details listed below

### AKS resources
ipam engine deployment

ipam ui deployment

services X 2

ingress

cosmos DB using ASO

ipam-sop-secrets

#### ipam-sop-secrets
Please note that incase you need to change value of the secret e.g. if app registration's secret expires. 

You can able to run below example,

```
NAMESPACE=ipam
ENGINEID=<ENGINE APP ID>
SECRET=<SECRET>
TENANTID=<Tenant ID>
UIID=<UI APP ID>
KEY=<SOPS key from dtssdsptl keyvault>

kubectl create secret generic ipam-sop-secrets \
  -n $NAMESPACE --from-literal=ENGINE-ID=${ENGINEID} --from-literal=ENGINE-SECRET=${SECRET} --from-literal=TENANT-ID=${TENANTID} --from-literal=UI-ID=${UIID} --type=Opaque -o yaml \
  --dry-run=client > ./apps/ipam/ptl/sops-secrets/ipam-sop-secrets.enc.yaml


sops --encrypt --azure-kv ${KEY}  --encrypted-regex "^(data|stringData)$" --in-place ./apps/ipam/ptl/sops-secrets/ipam-sop-secrets.enc.yaml

```


## IPAM Apps registration

Two apps has been registered for ipam to work and have required permissions.  
[HMCTS-IPAM-ENGINE](https://portal.azure.com/?feature.msaljs=true#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Overview/appId/3fa0259b-86c8-4cd7-bd2a-e5ab28625fe7/isMSAApp~/false)
[HMCTS-IPAM-UI](https://portal.azure.com/?feature.msaljs=true#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Overview/appId/d2529ca9-ca84-401a-ac98-131e5aaa8075/isMSAApp~/false)

Above apps has been deployed using this [script](https://github.com/Azure/ipam/blob/main/deploy/deploy.ps1).  

We can deploy apps only by passing below flag, [see documentation](https://azure.github.io/ipam/#/deployment/README?id=app-registration-only-deployment)

```
./deploy.ps1 -AppsOnly
```


