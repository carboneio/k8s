[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/carbone)](https://artifacthub.io/packages/search?repo=carbone)

This repo contains helm and YAML for deploying Carbone into a Kubernetes environment. Follow the applicable instructions for your edition / deployment methodology below:

- [Deploying with Helm](#deploying-with-helm)
- [Carbone configuration](#carbone-configuration)

# Deploying with Helm

Install the repository:

```
helm repo add carbone https://bin.carbone.io/helm/
helm repo update
```

## Running Carbone

Few options are available in values.yaml with 2 main configuration : ingress paramater and persistent storage.

Exemple with kubernetes on docker desktop deployment with S3 persistent storage : 
```bash
## First setup nginx ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.5/deploy/static/provider/cloud/deploy.yaml

## Install Carbone
helm install --create-namespace -n carbone carbone-ee carbone/carbone-ee \
    --set applicationConfiguration.license=${CARBONE_EE_LICENSE} \
    --set ingress.className=nginx \
    --set 'ingress.hosts[0].host=carbone.local' \
    --set 'ingress.hosts[0].paths[0].path=/' \
    --set 'ingress.hosts[0].paths[0].pathType=Prefix' \
    --set persistentStorage.s3.enabled=true \
    --set persistentStorage.s3.endpoint=s3.eu-west-1.amazonaws.com \
    --set persistentStorage.s3.region=eu-west-1 \
    --set persistentStorage.s3.accessKeyId=${S3_ACCESS_KEY} \
    --set persistentStorage.s3.accessKeySecret=${S3_ACCESS_KEY_SECRET} \
    --set persistentStorage.s3.templatesBucket=${S3_TEMPLATES_BUCKET} \
    --set persistentStorage.s3.rendersBucket=${S3_RENDERS_BUCKET}
```

## Carbone configuration

We recommand to set options in you own values.yaml file and start Carbone with ; 
```bash
helm install --create-namespace -n carbone -f values.yaml carbone-ee carbone/carbone-ee
```

 Few examples are available for main cloud provider:
- [Docker desktop configuration with AWS S3 storage](/values-docker.yaml)
- [Azure Kubernetes with Blob storage](/values-azure.yaml)
- [AWS EKS with AWS S3 storage](/values-eks.yaml)
- [Google Kubernetes Engine (GKE) with S3 compatible Object storage ](/values-gcp.yaml)
- [OVH Manages Kubernetes with S3 compatible Object storage ](/values-ovh.yaml)
- [Scaleway Manages Kubernetes with S3 compatible Object storage ](/values-scaleway.yaml)
