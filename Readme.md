[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/carbone)](https://artifacthub.io/packages/search?repo=carbone)

This repository contains the official Helm chart for deploying [Carbone Enterprise Edition](https://carbone.io) on Kubernetes.

- [Prerequisites](#prerequisites)
- [Quick start](#quick-start)
- [Using a values file](#using-a-values-file)
- [Cloud provider examples](#cloud-provider-examples)
- [Upgrade](#upgrade)
- [Uninstall](#uninstall)

## Prerequisites

- Kubernetes 1.23+
- Helm 3.8+
- An ingress controller deployed in your cluster (see below)
- A persistent storage backend (S3, Azure Blob, or a RWX PersistentVolume)

### Install an ingress controller

If your cluster does not already have an ingress controller, install [ingress-nginx](https://kubernetes.github.io/ingress-nginx/deploy/):

```bash
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace
```

> For cloud-managed clusters (EKS, GKE, AKS), refer to the [provider-specific examples](#cloud-provider-examples) below — a managed load balancer is often available instead.

## Quick start

Add the Carbone Helm repository:

```bash
helm repo add carbone https://bin.carbone.io/helm/
helm repo update
```

Install Carbone with S3 storage:

```bash
helm upgrade --install carbone-ee carbone/carbone-ee \
  --create-namespace -n carbone \
  --set applicationConfiguration.license=$CARBONE_EE_LICENSE \
  --set ingress.className=nginx \
  --set 'ingress.hosts[0].host=carbone.example.com' \
  --set 'ingress.hosts[0].paths[0].path=/' \
  --set 'ingress.hosts[0].paths[0].pathType=Prefix' \
  --set persistentStorage.s3.enabled=true \
  --set persistentStorage.s3.endpoint=s3.eu-west-1.amazonaws.com \
  --set persistentStorage.s3.region=eu-west-1 \
  --set persistentStorage.s3.accessKeyId=$S3_ACCESS_KEY_ID \
  --set persistentStorage.s3.accessKeySecret=$S3_ACCESS_KEY_SECRET \
  --set persistentStorage.s3.templatesBucket=$S3_TEMPLATES_BUCKET \
  --set persistentStorage.s3.rendersBucket=$S3_RENDERS_BUCKET
```

Verify the installation:

```bash
kubectl get pods -n carbone
helm test carbone-ee -n carbone
```

## Using a values file

For anything beyond a quick test, maintain a `values.yaml` file and pass it with `-f`. This avoids long command lines and makes configuration reviewable in version control.

```bash
helm upgrade --install carbone-ee carbone/carbone-ee \
  --create-namespace -n carbone \
  -f values.yaml
```

Minimal `values.yaml`:

```yaml
applicationConfiguration:
  license: <your-license-key>

ingress:
  className: nginx
  hosts:
    - host: carbone.example.com
      paths:
        - path: /
          pathType: Prefix

persistentStorage:
  s3:
    enabled: true
    endpoint: s3.eu-west-1.amazonaws.com
    region: eu-west-1
    templatesBucket: my-carbone-templates
    rendersBucket: my-carbone-renders
    accessKeyId: <access-key-id>
    accessKeySecret: <access-key-secret>
```

The full list of configurable parameters is documented in the [chart README](charts/carbone-ee/Readme.md).

## Cloud provider examples

Ready-to-use values files are available for common environments. Copy the relevant file, fill in your values, and pass it with `-f`.

| Provider | Storage | Values file |
|----------|---------|-------------|
| Docker Desktop | AWS S3 | [values-docker.yaml](values-docker.yaml) |
| AWS EKS | S3 | [values-eks.yaml](values-eks.yaml) |
| Azure Kubernetes Service | Azure Blob Storage | [values-azure.yaml](values-azure.yaml) |
| Google Kubernetes Engine | GCS (S3-compatible) | [values-gcp.yaml](values-gcp.yaml) |
| OVH Managed Kubernetes | OVH Object Storage | [values-ovh.yaml](values-ovh.yaml) |
| Scaleway Kapsule | Scaleway Object Storage | [values-scaleway.yaml](values-scaleway.yaml) |

## Upgrade

```bash
helm repo update
helm upgrade carbone-ee carbone/carbone-ee -n carbone -f values.yaml
```

To preview what will change before upgrading:

```bash
helm diff upgrade carbone-ee carbone/carbone-ee -n carbone -f values.yaml
```

## Uninstall

```bash
helm uninstall carbone-ee -n carbone
kubectl delete namespace carbone
```
