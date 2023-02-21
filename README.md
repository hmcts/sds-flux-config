# sds-flux-config

All SDS applications are now being managed by Flux v2.

## Encrypting Secrets With Sops

(docs/secrets-sops-encryption.md)


### SOPs

Sops fails linting by default as we require 2 spaces while it uses 4 spaces.
You can use `yq` to fix this:

```
yq eval -I 2 --inplace apps/mi/mi-adf-shir/sbox/mi-adf-auth-values.enc.yaml
```

upstream issue: https://github.com/mozilla/sops/issues/900
