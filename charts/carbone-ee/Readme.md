# Carbone EE — Helm Chart

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/carbone)](https://artifacthub.io/packages/search?repo=carbone)

[Carbone](https://carbone.io) is a fast document generation engine that converts JSON data into PDF, DOCX, XLSX, and other formats using Office templates. This chart deploys **Carbone Enterprise Edition** on Kubernetes.

## Prerequisites

- Kubernetes 1.23+
- Helm 3.8+
- An ingress controller (nginx, traefik…) if external access is required
- A persistent storage backend (S3, Azure Blob, or a RWX PersistentVolume) for production use

## Installation

Add the Carbone Helm repository:

```bash
helm repo add carbone https://bin.carbone.io/helm/
helm repo update
```

Install the chart:

```bash
helm upgrade --install carbone-ee carbone/carbone-ee \
  --create-namespace -n carbone \
  -f values.yaml
```

After installation, run the built-in connectivity test:

```bash
helm test carbone-ee -n carbone
```

## Configuration

The recommended approach is to maintain a `values.yaml` file and pass it with `-f`. The key parameters are listed below.

### Application

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.tag` | Carbone image tag | `5.8.0` |
| `image.pullPolicy` | Image pull policy | `Always` |
| `replicaCount` | Number of replicas | `4` |
| `applicationConfiguration.license` | Carbone EE license key | `""` |
| `applicationConfiguration.port` | HTTP port | `4000` |
| `applicationConfiguration.studio` | Enable Carbone Studio UI | `true` |
| `applicationConfiguration.studioBasicAuthentication` | Basic auth for Studio (`user:password`) | `""` |
| `applicationConfiguration.authentication` | Enable JWT authentication on the API | `false` |
| `applicationConfiguration.authenticationPublicKey` | RSA public key for JWT verification | `""` |
| `applicationConfiguration.lang` | Default locale | `fr` |
| `applicationConfiguration.timezone` | Default timezone | `Europe/Paris` |
| `applicationConfiguration.nbConvertThread` | Number of LibreOffice conversion threads per pod | `1` |
| `applicationConfiguration.timeoutConversion` | Conversion timeout in ms | `60000` |
| `applicationConfiguration.maxInputSize` | Max request body size in bytes | `62914560` |
| `applicationConfiguration.templateManagement` | Enable template CRUD API | `true` |

### Autoscaling

| Parameter | Description | Default |
|-----------|-------------|---------|
| `autoscaling.enabled` | Enable HorizontalPodAutoscaler | `false` |
| `autoscaling.minReplicas` | Minimum replicas | `1` |
| `autoscaling.maxReplicas` | Maximum replicas | `100` |
| `autoscaling.targetCPUUtilizationPercentage` | CPU target for scaling | `70` |

### Ingress

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.className` | Ingress class name | `""` |
| `ingress.annotations` | Ingress annotations | `{}` |
| `ingress.hosts` | List of hosts and paths | `[{host: "", paths: [{path: /}]}]` |
| `ingress.tls` | TLS configuration | `[]` |

## Storage backends

A persistent storage backend is required for production. Templates and renders need to survive pod restarts and be shared across replicas. Choose **one** of the following options.

### S3 (or S3-compatible)

Works with AWS S3, Scaleway Object Storage, OVH Object Storage, GCS (S3-compatible mode), MinIO, and others.

```yaml
persistentStorage:
  s3:
    enabled: true
    endpoint: s3.eu-west-1.amazonaws.com
    region: eu-west-1
    templatesBucket: my-carbone-templates
    rendersBucket: my-carbone-renders
    accessKeyId: <ACCESS_KEY_ID>
    accessKeySecret: <ACCESS_KEY_SECRET>
```

### Azure Blob Storage

```yaml
persistentStorage:
  azureBlobStorage:
    enabled: true
    storageAccount: mystorageaccount
    storageKey: <STORAGE_KEY>
    templatesContainer: carbone-templates
    rendersContainer: carbone-renders
```

### PersistentVolume (RWX)

Suitable for on-premise or single-node setups. For multi-replica deployments, the volume must support `ReadWriteMany`.

```yaml
persistentStorage:
  persistentVolume:
    enabled: true
    persistentVolumeClaimName: carbone-pvc
    templateFolder: templates
    rendersFolder: renders
```

## Multi-instance and high availability

When `replicaCount > 1` or `autoscaling.enabled: true`, pods automatically discover each other via WebSocket (port 5001) and synchronize template metadata. No additional configuration is required — peer discovery is handled by the headless service.

For optimal availability with multiple replicas, consider adding topology spread constraints to your `values.yaml`:

```yaml
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchLabels:
              app.kubernetes.io/name: carbone-ee
          topologyKey: kubernetes.io/hostname
```

## Upgrade

```bash
helm upgrade carbone-ee carbone/carbone-ee -n carbone -f values.yaml
```

To preview changes before applying:

```bash
helm diff upgrade carbone-ee carbone/carbone-ee -n carbone -f values.yaml
```

## Uninstall

```bash
helm uninstall carbone-ee -n carbone
kubectl delete namespace carbone
```

## Values file examples

Ready-to-use values files are available for common environments:

| Environment | File |
|-------------|------|
| Docker Desktop + AWS S3 | [values-docker.yaml](../../values-docker.yaml) |
| AWS EKS + S3 | [values-eks.yaml](../../values-eks.yaml) |
| Azure Kubernetes Service + Blob Storage | [values-azure.yaml](../../values-azure.yaml) |
| Google Kubernetes Engine + S3-compatible | [values-gcp.yaml](../../values-gcp.yaml) |
| OVH Managed Kubernetes + S3-compatible | [values-ovh.yaml](../../values-ovh.yaml) |
| Scaleway Kapsule + S3-compatible | [values-scaleway.yaml](../../values-scaleway.yaml) |
