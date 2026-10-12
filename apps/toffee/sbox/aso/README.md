# Toffee PostgreSQL version example

The [Toffee upgrade-test server](./toffee-postgres-upgrade.yaml) uses:

```yaml
apiVersion: dbforpostgresql.azure.com/v20250801
kind: FlexibleServer
spec:
  version: "17"
```

This is a documentation-only excerpt, not a complete deployable manifest.
Both versions are already configured on `master`; this example does not change
the deployed server or verify a successful in-place upgrade.
