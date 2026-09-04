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
| `image.tag` | Carbone image tag | `5.11.0` |
| `image.pullPolicy` | Image pull policy | `Always` |
| `replicaCount` | Number of replicas | `4` |
| `applicationConfiguration.license` | Carbone EE license key | `""` |
| `applicationConfiguration.port` | HTTP port | `4000` |
| `applicationConfiguration.peerPort` | Port of the peer replication WebSocket, used when several pods synchronize template metadata | `5001` |
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
| `applicationConfiguration.jobBalancer` | Distribute rendering jobs evenly across instances (requires `templateManagement: true`, Carbone ≥ 5.9.0) | `false` |

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

> **The peer port is unauthenticated.** It carries template replication and job balancing, and it accepts any connection that reaches it: a workload able to open a WebSocket on it can register itself as a Carbone peer, read this deployment's template metadata and be handed rendering jobs queued by its tenants. It is never exposed by a Service or the Ingress, so it is reachable on the pod network only — and the chart ships a [NetworkPolicy](#network-policy) that closes it to everything but the pods of the release. Keep that policy on, or replace it with an equivalent control of your own.

To distribute rendering jobs evenly across instances, enable the job balancer (requires Carbone ≥ 5.9.0):

```yaml
applicationConfiguration:
  templateManagement: true  # required
  jobBalancer: true
```

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

## Network policy

Peer replication is what makes the port above worth protecting, so the chart renders a `NetworkPolicy` exactly when replication is active — `templateManagement: true` together with more than one replica or with autoscaling. It selects the pods of the release and allows two things:

- the API port, from every source, so the ingress controller, the kubelet probes and your in-cluster clients are unaffected;
- the peer port, from the pods of this release only.

It is enabled by default:

```yaml
networkPolicy:
  enabled: true
```

> **A NetworkPolicy is enforced by the CNI plugin, not by Kubernetes.** Calico, Cilium and Antrea enforce it. Plain Flannel and a few managed offerings accept the object and ignore it, leaving the peer port open with nothing to show for it. Check what your cluster runs before relying on this.

When legitimate peers live in another namespace, add them rather than turning the policy off:

```yaml
networkPolicy:
  peerIngressFrom:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: carbone-staging
      podSelector:
        matchLabels:
          app.kubernetes.io/name: carbone-ee
```

If you know which workloads call the API, you can narrow the HTTP port too. Leave it empty to keep it open to everything, which is the default:

```yaml
networkPolicy:
  httpIngressFrom:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: ingress-nginx
```

Verify the policy is in place after an install:

```bash
kubectl get networkpolicy -n carbone
kubectl describe networkpolicy carbone-ee-production -n carbone
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
