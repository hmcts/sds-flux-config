# sds-flux-config

### Flux V2 Migration status

| Environment | Instances running | Status            |
| ----------- | ----------------- | ----------------- |
| Prod        | Flux V2           | Completed         |
| Staging     | Flux v2           | Completed         |
| Demo        | Flux V2           | Completed         |
| ITHC        | Flux V2           | Completed         |
| Test        | Flux V2           | Completed         |
| Dev         | Flux V2           | Completed         |
| Sbox        | Flux V2           | Completed         |
| Ptl         | Flux V1, Flux v2  | Started Migration |
| Ptlsbox     | Flux V1           | Started Migration |

### SOPs

Sops fails linting by default as we require 2 spaces while it uses 4 spaces.
You can use `yq` to fix this:

```
yq eval -I 2 --inplace apps/mi/mi-adf-shir/sbox/mi-adf-auth-values.enc.yaml
```

upstream issue: https://github.com/mozilla/sops/issues/900
