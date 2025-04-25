# Qmigrator Helm

## Pre-requisites
- Obtain project details such as Project ID, Name, and Login credentials from Quadrant.
- Acquire Docker/Helm registry credentials provided by Quadrant.

> [!NOTE]
These parameters are essential for creating secrets. Refer to the `secret` and `imageCredentials` sections in `values.yaml`.

### Preparing the Values File
- Customize the `values.yaml` file with the required properties.
- A minimal configuration is available in [values.example.yaml](values.example.yaml), which can be further modified as needed.

### Namespace Setup
Create a namespace or use an existing one:
```bash
kubectl create namespace qmig-ns
kubectl config set-context --current --namespace=qmig-ns
```

### Helm Installation
Login to Qmigrator helm registry:
```bash
helm registry login qmigrator.azurecr.io --username <username> --password <password>
```
Install Qmigrator using the following command:
```bash
helm install <name> oci://qmigrator.azurecr.io/helm/admin -f values.example.yaml
```

## Ingress Controller
- Qmigrator uses an ingress controller to expose the application.
- You can either use an existing ingress controller in the cluster by updating its properties or enable the ingress controller installation via the Helm chart:
```bash
--set ingressController.enabled=true
```
- Supported ingress controller providers: `kubernetes` and `nginx-inc`. Specify the provider using the `provider` flag.

> [!NOTE]
For more information, refer to:
- [Kubernetes Ingress NGINX](https://github.com/kubernetes/ingress-nginx)
- [NGINX Kubernetes Ingress](https://github.com/nginxinc/kubernetes-ingress)


## Data Persistence
Qmigrator Admin requires two types of storage:
1. **Shared Disk**: Shared across applications (ReadWriteMany).
2. **Block Storage**: Dedicated storage for the database and cache (ReadWriteOnce).

- The Helm chart supports both dynamic and static provisioning of PV/PVC. However, you must manage the storage class and manually create persistent volumes if required.

> [!IMPORTANT]
Avoid using ReadWriteMany or shared persistent volumes for the Metadata Database (Postgres) and Cache components.

> [!TIP]
Refer to the following examples for more details:
- [Shared Storage Example](example/shared-storage/)
- [Storage Class Example](example/storage-classes/)

### Storage Options
#### Docker Desktop (Windows)
- Use `LocalPath` as the Windows device path for Docker Desktop Kubernetes.

#### Minikube (Linux, Windows, macOS)
- Mount the local path when starting Minikube:
```bash
minikube start --mount --mount-string={LOCAL_PATH}:/hostpc
```

#### Azure Cloud
- Use Azure Fileshare for Kubernetes storage.
- Requires a secret key for access and mounting.
- Learn more: [Azure CSI Files Storage Provisioning](https://learn.microsoft.com/en-us/azure/aks/azure-csi-files-storage-provision)

#### Google Cloud
- Mount GCS buckets on Kubernetes using the `gcsfuse` driver.
- Requires a service account with appropriate permissions.
- Learn more: [GCS Fuse CSI Driver](https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/cloud-storage-fuse-csi-driver#create-persistentvolume)

#### AWS Cloud
- Use AWS EFS for shared storage.
- Supports user and OIDC-based authentication for AWS clusters.
- Learn more: [AWS EFS CSI Driver](https://github.com/kubernetes-sigs/aws-efs-csi-driver/blob/master/examples/kubernetes/static_provisioning/README.md)


## Values.YAML
### Globals
| Property | Description | Default | 
| :--- | :--- | :--- | 
| nameOverride | String to partially override name template (will maintain the release name) | "" |
| clusterDomain | Kubernetes Cluster Domain | "cluster.local" | 
| secret.secretName | Name for project secret | "" (name: qmig-secret) | 
| secret.annotations | Annotations for secrets | {} | 
| secret.labels | Labels for secrets | {} | 
| secret.data.PROJECT_ID | ID of project | null | 
| secret.data.PROJECT_NAME | Name of project | null | 
| secret.data.POSTGRES_PASSWORD | Admin Password for metadata DB | null | 
| secret.data.REDIS_PASS | Admin Password for Cache | null | 
| imageCredentials.create | Create docker pull secret | true | 
| imageCredentials.secretName | Name for docker secret | "" (name: qmig-docker) | 
| imageCredentials.annotations | Annotations for docker secret | {} | 
| imageCredentials.labels | Labels for docker secret | {} | 
| imageCredentials.data.registry | Server/Registry host | qmigrator.azurecr.io | 
| imageCredentials.data.username | Username for given docker host | null | 
| imageCredentials.data.password | Password for given docker host | null | 

### Shared Volume
| Property | Description | Default | 
| :--- | :--- | :--- | 
| shared.persistentVolume.enabled | If false, use emptyDir | true | 
| shared.persistentVolume.accessModes | How should the volume be accessible in App | ReadWriteMany | 
| shared.persistentVolume.annotations | Persistent Volume Claim annotations | {} | 
| shared.persistentVolume.labels | Labels for persistentVolume | {} | 
| shared.persistentVolume.existingClaim | Name of PVC created manually before volume | "" | 
| shared.persistentVolume.subPath | Subdirectory of data Persistent Volume to mount | "" | 
| shared.persistentVolume.size | Persistent Volume size | 5Gi | 
| shared.persistentVolume.storageClass | Persistent Volume Storage Class | "" (Default from Kubernetes) | 
| shared.persistentVolume.volumeBindingMode | Persistent Volume Binding Mode | "" (Default from Kubernetes) | 
| shared.folderPath.extraSubpath | Subpath for Extra folder in a shared volume | "extra" | 
| shared.folderPath.dagsSubpath | Subpath for Dag's folder of airflow in a shared volume | "dags" | 
| shared.folderPath.logsSubpath | Subpath for logs folder of airflow in a shared volume | "logs" | 

### Ingress Controller
| Property | Description | Default | 
| :--- | :--- | :--- | 
| ingressController.enabled | Whether or not to install the ingressController | false | 
| ingressController.provider | The name of the ingressController provider either nginx-inc or kubernetes | "kubernetes" | 
| ingressController.name | The name of the ingressController to use | "" (name: nginx-ingress) | 
| ingressController.labels | Labels for ingressController | {} | 
| ingressController.controllerImage.repository | Ingress controller image repository | qmigrator.azurecr.io/ingress-nginx/controller | 
| ingressController.controllerImage.tag | Ingress controller image tag/version | "v1.9.4" | 
| ingressController.webhookImage.repository | Ingress controller image repository | qmigrator.azurecr.io/ingress-nginx/kube-webhook-certgen | 
| ingressController.webhookImage.tag | Ingress controller image tag/version | "v20231011-8b53cabe0" | 
| ingressController.image.repository | Ingress image repository for Nginx Inc | nginx/nginx-ingress | 
| ingressController.image.tag | Ingress image tag/version for Nginx Inc | "3.6.1" | 
| ingressController.imagePullSecrets | Ingress Controller component pull secrets | {} | 
| ingressController.isDefaultClass | Set Ingress class as default to cluster | true | 
| ingressController.securityContexts.pod | Default security context for Ingress Controller pods | {} | 
| ingressController.securityContexts.container | Default security context for Ingress Controller containers | {} | 
| ingressController.tolerations | Tolerations for Ingress Controller pods assignment | {} | 
| ingressController.affinity | Affinity for Ingress Controller pods assignment (evaluated as a template) | {} | 
| ingressController.nodeSelector | Node labels for Ingress Controller pods assignment | {} | 
| ingressController.resources | Set container requests and limits for different resources like CPU or memory (essential for production workloads) | 

### Ingress
| Property | Description | Default | 
| :--- | :--- | :--- | 
| ingress.enabled | Enable ingress record generation | true | 
| ingress.className | IngressClass that will be used to implement the Ingress (Kubernetes 1.18+) | "nginx" | 
| ingress.annotations | Additional annotations for the Ingress resource | {} | 
| ingress.labels | Add labels for the Ingress | {} | 
| ingress.host | Default host for the ingress record | "" | 
| ingress.tls | TLS configuration for additional hostname(s) to be covered with this ingress record | {} | 

### Gateway
| Property | Description | Default | 
| :--- | :--- | :--- | 
| gateway.enabled | Enable create gateway | false | 
| gateway.className | GatewayClass that will be used to implement the gateway | "nginx" | 
| gateway.annotations | Additional annotations for the gateway resource | {} | 
| gateway.labels | Add labels for the gateway | {} | 
| gateway.listeners | Add listeners for the gateway | [] | 

### HTTPRoute
| Property | Description | Default | 
| :--- | :--- | :--- | 
| httpRoutes.enabled | Create the routes on gateway | false | 
| httpRoutes.className | GatewayClass name | "nginx" | 
| httpRoutes.annotations | Additional annotations for the httpRoutes | {} | 
| httpRoutes.labels | Add labels for the httpRoutes | {} | 
| httpRoutes.parentRefs | Define route parents to gateway | [] | 
| httpRoutes.hostnames | Hostnames in routes record | [] | 
| httpRoutes.redirectHttp | Create redirect filter http to https | false | 

### Service Account
| Property | Description | Default | 
| :--- | :--- | :--- | 
| serviceAccount.create | Enable creation of ServiceAccount | true | 
| serviceAccount.name | The name of the ServiceAccount to use | "" (name: qmig-opr) | 
| serviceAccount.annotations | Additional custom annotations for the ServiceAccount | {} | 
| serviceAccount.labels | Labels for ServiceAccount | {} | 
| rbac.create | Create Role and RoleBinding | true | 

### App Components
| Property | Description | Default | 
| :--- | :--- | :--- | 
| app.name | Name for App component | "app" | 
| app.replicas | Number of App Components replicas | 1 | 
| app.image.repository | App component image repository | "qmigrator.azurecr.io/qubeapp" | 
| app.image.tag | App component image tag/version | "q1002" | 
| app.image.pullPolicy | App component pull policy | "IfNotPresent" | 
| app.imagePullSecrets | App component pull secrets | {} | 
| app.readinessProbe.enabled | Enable readinessProbe on App Component containers | true | 
| app.livenessProbe.enabled | Enable livenessProbe on App Component containers | true | 
| app.annotations | Add extra annotations to the App Component | {} | 
| app.podAnnotations | Add extra Pod annotations to the App Component pods | {} | 
| app.securityContexts.pod | Default security context for App Component pods | {} | 
| app.securityContexts.container | Default security context for App Component containers | {} | 
| app.tolerations | Tolerations for App Component pods assignment | {} | 
| app.affinity | Affinity for App Component pods assignment (evaluated as a template) | {} | 
| app.nodeSelector | Node labels for App Component pods assignment | {} | 
| app.labels | Labels for App Component | {} | 
| app.service.annotations | Additional custom annotations for App Component service | {} | 
| app.service.type | App Component service type | ClusterIP | 
| app.service.port | App Component service HTTP port | 4200 | 
| app.resources | Set container requests and limits for different resources like CPU or memory (essential for production workloads) | 
| app.autoscaling.enabled | Whether to enable horizontal pod autoscaler | true | 
| app.autoscaling.minReplicas | Configure a minimum amount of pods | 1 | 
| app.autoscaling.maxReplicas | Configure a maximum amount of pods | 2 | 
| app.autoscaling.targetCPUUtilizationPercentage | Define the CPU target to trigger the scaling actions (utilization percentage) | 80 | 
| app.autoscaling.targetMemoryUtilizationPercentage | Define the memory target to trigger the scaling actions (utilization percentage) | 80 | 

### Engine Components
| Property | Description | Default | 
| :--- | :--- | :--- | 
| eng.name | Name for Engine component | "eng" | 
| eng.replicas | Number of Engine component replicas | 1 | 
| eng.image.repository | Engine component image repository | "qmigrator.azurecr.io/qubeeng" | 
| eng.image.tag | Engine component image tag/version | "q836" | 
| eng.image.pullPolicy | Engine component pull policy | "IfNotPresent" | 
| eng.imagePullSecrets | Engine component pull secrets | {} | 
| eng.readinessProbe.enabled | Enable readinessProbe on Engine component containers | true | 
| eng.livenessProbe.enabled | Enable livenessProbe on Engine component containers | true | 
| eng.annotations | Add extra annotations to the Engine component | {} | 
| eng.podAnnotations | Add extra Pod annotations to the Engine component pods | {} | 
| eng.securityContexts.pod | Default security context for Engine component pods | {} | 
| eng.securityContexts.container | Default security context for Engine component containers | {} | 
| eng.tolerations | Tolerations for Engine component pods assignment | {} | 
| eng.affinity | Affinity for Engine component pods assignment (evaluated as a template) | {} | 
| eng.nodeSelector | Node labels for Engine component pods assignment | {} | 
| eng.labels | Labels for Engine Component | {} | 
| eng.service.annotations | Additional custom annotations for Engine component service | {} | 
| eng.service.type | Engine component service type | ClusterIP | 
| eng.service.port | Engine component service HTTP port | 8080 | 
| eng.extraVolumeMounts | Optionally specify an extra list of additional volumeMounts for all the Engine component pods | [] | 
| eng.extraVolumes | Optionally specify an extra list of additional volumes for all the Engine component pods | [] | 
| eng.resources | Set container requests and limits for different resources like CPU or memory (essential for production workloads) | 
| eng.autoscaling.enabled | Whether to enable horizontal pod autoscaler | true | 
| eng.autoscaling.minReplicas | Configure a minimum amount of pods | 1 | 
| eng.autoscaling.maxReplicas | Configure a maximum amount of pods | 2 | 
| eng.autoscaling.targetCPUUtilizationPercentage | Define the CPU target to trigger the scaling actions (utilization percentage) | 80 | 
| eng.autoscaling.targetMemoryUtilizationPercentage | Define the memory target to trigger the scaling actions (utilization percentage) | 80 | 
| eng.env | Add extra environment variables for the Engine component pods | [TZ] | 
| eng.envSecret | List of secrets with extra environment variables for all the component pods | [] | 

### Metadata Database
| Property | Description | Default | 
| :--- | :--- | :--- | 
| db.enabled | Provision the postgres deployment | true | 
| db.dbConnection.hostname | Provide the hostname if used external connection | "" (Auto Generates) | 
| db.dbConnection.username | Username for connection to DB | "postgres" | 
| db.dbConnection.port | Port for connection to DB | "5432" | 
| db.name | Name for DB component | "db" | 
| db.replicas | Number of DB component replicas | 1 | 
| db.strategy | Update strategy for DB component pods | "Recreate" | 
| db.image.repository | DB component image repository | "postgres" (hub.docker.com) | 
| db.image.tag | DB component image tag/version | "14.2" | 
| db.image.pullPolicy | DB component pull policy | "IfNotPresent" | 
| db.imagePullSecrets | DB component pull secrets | {} | 
| db.dbshConfig.stringOverride | Override shell script to be run on the initial time of DB | "" | 
| db.annotations | Add extra annotations to the DB component | {} | 
| db.podAnnotations | Add extra Pod annotations to the DB component pods | {} | 
| db.securityContexts.pod | Default security context for DB Component pods | {} | 
| db.securityContexts.container | Default security context for DB Component containers | {} | 
| db.tolerations | Tolerations for DB component pods assignment | {} | 
| db.affinity | Affinity for DB component pods assignment (evaluated as a template) | {} | 
| db.nodeSelector | Node labels for DB component pods assignment | {} | 
| db.labels | Labels for DB Component | {} | 
| db.initContainers.image.repository | Load DB image repository | "qmigrator.azurecr.io/qmigdb-ini" | 
| db.initContainers.image.tag | Load DB image tag/version | "1164" | 
| db.initContainers.resources | Set Init container requests and limits for different resources like CPU or memory | {} | 
| db.persistentVolume.enabled | If false, use emptyDir | true | 
| db.persistentVolume.accessModes | How should the volume be accessible in App | ReadWriteOnce | 
| db.persistentVolume.annotations | Persistent Volume Claim annotations | {} | 
| db.persistentVolume.existingClaim | Name of PVC created manually before volume | "" | 
| db.persistentVolume.subPath | Subdirectory of data Persistent Volume to mount | "" | 
| db.persistentVolume.size | Persistent Volume size | 5Gi | 
| db.persistentVolume.storageClass | Persistent Volume Storage Class | "" (Default from Kubernetes) | 
| db.persistentVolume.volumeBindingMode | Persistent Volume Binding Mode | "" (Default from Kubernetes) | 
| db.service.annotations | Additional custom annotations for DB component service | {} | 
| db.service.type | DB component service type | "ClusterIP" | 
| db.service.port | DB component service HTTP port | 5432 | 
| db.resources | Set container requests and limits for different resources like CPU or memory (essential for production workloads) | 
| db.env | Add extra environment variables for the DB component pods | [JDBC_PARAMS] | 
| db.envSecret | List of secrets with extra environment variables for all the component pods | [] | 
| db.extraVolumeMounts | Optionally specify an extra list of additional volumeMounts for all the DB component pods | [] | 
| db.extraVolumes | Optionally specify an extra list of additional volumes for all the DB component pods | [] | 
