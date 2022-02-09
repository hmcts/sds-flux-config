# sds-flux-config

### Flux V2 Migration status

| Environment  | Instances running | Status |
| ------------- | ------------- | ------------- |
| Prod | Flux V1  | Not Migrated
| Staging |  Flux V1  | Not Migrated
| Demo|  Flux V1  | Not Migrated
| ITHC | Flux V1 | Not Migrated
| Test | Flux V1| Not Migrated
| Dev | Flux V2  | Completed
| Sbox | Flux V2  | Completed
| Ptl | Flux V1,Flux v2 | Started Migration
| Ptlsbox | Flux V1  | Not Migrated


### SOPs

Sops fails linting by default as we require 2 spaces while it uses 4 spaces.
You can use `yq` to fix this:

```
yq eval -I 2 --inplace apps/mi/mi-adf-shir/sbox/mi-adf-auth-values.enc.yaml
```

upstream issue: https://github.com/mozilla/sops/issues/900
