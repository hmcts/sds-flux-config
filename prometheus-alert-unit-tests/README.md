# Prometheus alert unit tests

## Files

- `rules/monitoring-alerts.yaml` — a real `PrometheusRule` CRD copied from the repo.
- `tests/monitoring-alerts_test.yaml` — the promtool unit tests and their synthetic data.
- `extract-and-test.sh` — extracts the rules from the CRD with `yq`, then runs `promtool`.

## Run it

Requires `promtool` (ideally v3.11.3) and `yq` on your PATH.

```bash
./extract-and-test.sh
```

## What to expect

```
==> Validating extracted rule syntax with promtool
  SUCCESS: 2 rules found
==> Running unit tests
  SUCCESS
```
