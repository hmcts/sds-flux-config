
# ASO Configuration

We use [Azure Service Operator](https://azure.github.io/azure-service-operator/) to manage ephemeral infrastructure in environments like preview. The section covers how to configure ASO resources in this repository.

## Postgres Flexible Server

- Run [postgres-setup.sh](../bin/v2/postgres-setup.sh) with your namespace and app name.
   ```bash
    ./bin/v2/postgres-setup.sh <your namespace> <app name>
   ```