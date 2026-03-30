# Deploy Carbone using Helm Chart

Before proceeding, ensure to create a namespace in advance.
For instance:
```bash
kubectl create namespace carbone
```

# Install the chart repository

```bash
helm repo add carbone https://bin.carbone.io/helm/
helm repo update
```

# Installing the Chart
Execute the following for installing the chart:

```bash
helm upgrade -i -n carbone carbone-ee carbone/carbone-ee
```

# Deleting the Chart
Execute the following for deleting the chart:

```bash
## Delete the Helm Chart
helm delete -n carbone carbone-ee
## Delete the Namespace
kubectl delete namespace carbone
```

# Chart Configuration
Lists the configurable parameters of the Carbone chart and their default values  can be found under `carbone-ee/values.yaml`.
