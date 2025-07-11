# Qmigrator Helm

## Pre-requisites
- Obtain project details such as Project ID, Name, and Login credentials from Quadrant.
- Acquire Docker/Helm registry credentials provided by Quadrant.

> [!IMPORTANT]
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
helm install <name> oci://qmigrator.azurecr.io/helm/qmig -f values.example.yaml
```

## Ingress Controller
- Qmigrator uses an ingress controller to expose the application.
- You can either use an existing ingress controller in the cluster by updating its properties or enable the ingress controller installation via the Helm chart:
```bash
--set ingressController.enabled=true
```
- Supported ingress controller providers: `kubernetes` and `nginx-inc`. Specify the provider using the `provider` flag.

> [!NOTE]
> For more information, refer to:
> [Kubernetes Ingress NGINX](https://github.com/kubernetes/ingress-nginx) **and**
> [NGINX Kubernetes Ingress](https://github.com/nginxinc/kubernetes-ingress)

## Enabling Airflow Data Migration
To enable Airflow, pass the following flags during installation:
```bash
--set airflow.enabled=true --set airflow.secret.data.airflow_password="passxxxx"
```
> [!IMPORTANT]
The Airflow password is mandatory for access.

## Data Persistence
Qmigrator requires two types of storage:
1. **Shared Disk**: Shared across applications (ReadWriteMany).
2. **Block Storage**: Dedicated storage for the database and cache (ReadWriteOnce).

- The Helm chart supports both dynamic and static provisioning of PV/PVC. However, you must manage the storage class and manually create persistent volumes if required.

> [!IMPORTANT]
Avoid using ReadWriteMany or shared persistent volumes for the Metadata Database (Postgres) and Cache components.

> [!TIP]
Refer to the following examples for more details:
> - [Shared Storage Example](example/shared-storage/)
> - [Storage Class Example](example/storage-classes/)

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


## Post-Deployment Steps

### Check Pod Status

1. List pods created by the deployment:
    ```sh
    kubectl get pods -n qmig-ns
    ```

2. To expose QMigrator externally, follow the [Gateway Guide](../../example/gatewayapi/README.md) for gateway configuration, or refer to the [Ingress Guide](../../example/ingress/README.md) for legacy ingress setup (deprecated).


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

### Cache Components
| Property | Description | Default | 
| :--- | :--- | :--- | 
| msg.name | Name for Cache component | "msg" | 
| msg.replicas | Number of Cache component replicas | 1 | 
| msg.strategy | Update strategy for Cache component pods | "Recreate" | 
| msg.image.repository | Cache component image repository | "eqalpha/keydb" | 
| msg.image.tag | Cache component image tag/version | "x86_64_v6.3.4" | 
| msg.image.pullPolicy | Cache component pull policy | IfNotPresent | 
| msg.imagePullSecrets | Cache component pull secrets | {} | 
| msg.args | Args to override Cache component containers | [] | 
| msg.keyDBConfig.stringOverride | Override shell script to be run on the initial time of Cache | "" | 
| msg.annotations | Add extra annotations to the Cache component | {} | 
| msg.podAnnotations | Add extra Pod annotations to the Cache component pods | {} | 
| msg.securityContexts.pod | Default security context for Cache Component pods | {} | 
| msg.securityContexts.container | Default security context for Cache Component containers | {} | 
| msg.tolerations | Tolerations for Cache component pods assignment | {} | 
| msg.affinity | Affinity for Cache component pods assignment (evaluated as a template) | {} | 
| msg.nodeSelector | Node labels for Cache component pods assignment | {} | 
| msg.labels | Labels for Cache Component | {} | 
| msg.persistentVolume.enabled | If false, use emptyDir | true | 
| msg.persistentVolume.accessModes | How should the volume be accessible in App | ReadWriteOnce | 
| msg.persistentVolume.annotations | Persistent Volume Claim annotations | {} | 
| msg.persistentVolume.existingClaim | Name of PVC created manually before volume | "" | 
| msg.persistentVolume.subPath | Subdirectory of data Persistent Volume to mount | "" | 
| msg.persistentVolume.size | Persistent Volume size | 5Gi | 
| msg.persistentVolume.storageClass | Persistent Volume Storage Class | "" (Default from Kubernetes) | 
| msg.persistentVolume.volumeBindingMode | Persistent Volume Binding Mode | "" (Default from Kubernetes) | 
| msg.service.annotations | Additional custom annotations for Cache component service | {} | 
| msg.service.type | Cache component service type | "ClusterIP" | 
| msg.service.port | Cache component service HTTP port | 6378 | 
| msg.resources | Set container requests and limits for different resources like CPU or memory (essential for production workloads) | 
| msg.master.enabled | Run Cache component as master node | true | 
| msg.auth.enabled | Enable authentication with password on Cache component | true | 
| msg.env | Add extra environment variables for the Cache component pods | [] | 
| msg.envSecret | List of secrets with extra environment variables for all the component pods | [] | 
| msg.extraVolumeMounts | Optionally specify an extra list of additional volumeMounts for all the Cache component pods | [] | 
| msg.extraVolumes | Optionally specify an extra list of additional volumes for all the Cache component pods | [] | 

### Assessment
| Property | Description | Default | 
| :--- | :--- | :--- | 
| asses.enabled | Enable Assessment | true | 
| asses.image.repository | Assessment image repository | "qmigrator.azurecr.io/webassotp" | 
| asses.image.tag | Assessment image tag/version | "992" | 
| asses.image.pullPolicy | Assessment pull policy | "IfNotPresent" | 
| asses.imagePullSecrets | Assessment pull secrets | {} | 
| asses.annotations | Add extra annotations to the Assessment | {} | 
| asses.podAnnotations | Add extra Pod annotations to the Assessment pods | {} | 
| asses.securityContexts.pod | Default security context for Assessment pods | {} | 
| asses.securityContexts.container | Default security context for Assessment containers | {} | 
| asses.tolerations | Tolerations for Assessment pods assignment | {} | 
| asses.affinity | Affinity for Assessment pods assignment (evaluated as a template) | {} | 
| asses.nodeSelector | Node labels for Assessment pods assignment | {} | 
| asses.labels | Labels for Assessment | {} | 
| asses.schedule | Specifies the cron job schedule using the standard cron syntax | "*/10 * * * *" | 
| asses.failedJobsHistoryLimit | How many failed executions to track in history. | 2 | 
| asses.successfulJobsHistoryLimit | How many successful executions to track in history. | 3 | 
| asses.startingDeadlineSeconds | How many seconds a job is allowed to miss its scheduled start time before it is considered failed | 500 | 
| asses.concurrencyPolicy | Handle scenario when concurrent jobs are scheduled | Forbid | 
| asses.restartPolicy | Restart the container keeping the same Pod in Node | Never | 
| asses.ttlSecondsAfterFinished | Clean up finished Jobs after the specific seconds | 600 | 
| asses.backoffLimit | Each pod failure is counted towards the specified limit | 2 | 
| asses.resources | Set container requests and limits for different resources like CPU or memory (essential for production workloads) | 
| asses.env | Add extra environment variables for the Assessment pods | [] | 
| asses.envSecret | List of secrets with extra environment variables for all the component pods | [] | 
| asses.extraVolumeMounts | Optionally specify an extra list of additional volumeMounts for all the Assessment pods | [] | 
| asses.extraVolumes | Optionally specify an extra list of additional volumes for all the Assessment pods | [] |

### Conversion
| Property | Description | Default | 
| :--- | :--- | :--- | 
| convs.enabled | Enable Conversion | true | 
| convs.image.repository | Conversion image repository | "qmigrator.azurecr.io/webconvotp" | 
| convs.image.tag | Conversion image tag/version | "993" | 
| convs.image.pullPolicy | Conversion pull policy | "IfNotPresent" | 
| convs.imagePullSecrets | Conversion pull secrets | {} | 
| convs.annotations | Add extra annotations to the Conversion | {} | 
| convs.podAnnotations | Add extra Pod annotations to the Conversion pods | {} | 
| convs.securityContexts.pod | Default security context for Conversion pods | {} | 
| convs.securityContexts.container | Default security context for Conversion containers | {} | 
| convs.tolerations | Tolerations for Conversion pods assignment | {} | 
| convs.affinity | Affinity for Conversion pods assignment (evaluated as a template) | {} | 
| convs.nodeSelector | Node labels for Conversion pods assignment | {} | 
| convs.labels | Labels for Conversion | {} | 
| convs.schedule | Specifies the cron job schedule using the standard cron syntax | "*/10 * * * *" | 
| convs.failedJobsHistoryLimit | How many failed executions to track in history. | 2 | 
| convs.successfulJobsHistoryLimit | How many successful executions to track in history. | 2 | 
| convs.startingDeadlineSeconds | How many seconds a job is allowed to miss its scheduled start time before it is considered failed | 500 | 
| convs.concurrencyPolicy | Handle scenario when concurrent jobs are scheduled | Forbid | 
| convs.restartPolicy | Restart the container keeping the same Pod in Node | Never | 
| convs.ttlSecondsAfterFinished | Clean up finished Jobs after the specific seconds | 600 | 
| convs.backoffLimit | Each pod failure is counted towards the specified limit | 2 | 
| convs.resources | Set container requests and limits for different resources like CPU or memory (essential for production workloads) | 
| convs.env | Add extra environment variables for the Conversion pods | [] | 
| convs.envSecret | List of secrets with extra environment variables for all the component pods | [] | 
| convs.extraVolumeMounts | Optionally specify an extra list of additional volumeMounts for all the Conversion pods | [] | 
| convs.extraVolumes | Optionally specify an extra list of additional volumes for all the Conversion pods | [] | 

### Migration
| Property | Description | Default | 
| :--- | :--- | :--- | 
| migrt.enabled | Enable Migration | true | 
| migrt.image.repository | Migration image repository | "qmigrator.azurecr.io/webdmotp" | 
| migrt.image.tag | Migration image tag/version | "994" | 
| migrt.image.pullPolicy | Migration pull policy | "IfNotPresent" | 
| migrt.imagePullSecrets | Migration pull secrets | {} | 
| migrt.annotations | Add extra annotations to the Migration | {} | 
| migrt.podAnnotations | Add extra Pod annotations to the Migration pods | {} | 
| migrt.securityContexts.pod | Default security context for Migration pods | {} | 
| migrt.securityContexts.container | Default security context for Migration containers | {} | 
| migrt.tolerations | Tolerations for Migration pods assignment | {} | 
| migrt.affinity | Affinity for Migration pods assignment (evaluated as a template) | {} | 
| migrt.nodeSelector | Node labels for Migration pods assignment | {} | 
| migrt.labels | Labels for Migration | {} | 
| migrt.schedule | Specifies the cron job schedule using the standard cron syntax | "*/10 * * * *" | 
| migrt.failedJobsHistoryLimit | How many failed executions to track in history. | 2 | 
| migrt.successfulJobsHistoryLimit | How many successful executions to track in history. | 2 | 
| migrt.startingDeadlineSeconds | How many seconds a job is allowed to miss its scheduled start time before it is considered failed | 500 | 
| migrt.concurrencyPolicy | Handle scenario when concurrent jobs are scheduled | "Forbid" | 
| migrt.restartPolicy | Restart the container keeping the same Pod in Node | "Never" | 
| migrt.ttlSecondsAfterFinished | Clean up finished Jobs after the specific seconds | 600 | 
| migrt.backoffLimit | Each pod failure is counted towards the specified limit | 2 | 
| migrt.resources | Set container requests and limits for different resources like CPU or memory (essential for production workloads) | 
| migrt.env | Add extra environment variables for the Migration pods | [] | 
| migrt.envSecret | List of secrets with extra environment variables for all the component pods | [] | 
| migrt.extraVolumeMounts | Optionally specify an extra list of additional volumeMounts for all the Migration pods | [] | 
| migrt.extraVolumes | Optionally specify an extra list of additional volumes for all the Migration pods | [] | 

### Testing
| Property | Description | Default | 
| :--- | :--- | :--- | 
| tests.enabled | Enable Testing | false | 
| tests.image.repository | Testing image repository | "qmigrator.azurecr.io/webtestotp" | 
| tests.image.tag | Testing image tag/version | "971" | 
| tests.image.pullPolicy | Testing pull policy | "IfNotPresent" | 
| tests.imagePullSecrets | Testing pull secrets | {} | 
| tests.annotations | Add extra annotations to the Testing | {} | 
| tests.podAnnotations | Add extra Pod annotations to the Testing pods | {} | 
| tests.securityContexts.pod | Default security context for Testing pods | {} | 
| tests.securityContexts.container | Default security context for Testing containers | {} | 
| tests.tolerations | Tolerations for Testing pods assignment | {} | 
| tests.affinity | Affinity for Testing pods assignment (evaluated as a template) | {} | 
| tests.nodeSelector | Node labels for Testing pods assignment | {} | 
| tests.labels | Labels for Testing | {} | 
| tests.schedule | Specifies the cron job schedule using the standard cron syntax | "*/10 * * * *" | 
| tests.failedJobsHistoryLimit | How many failed executions to track in history. | 2 | 
| tests.successfulJobsHistoryLimit | How many successful executions to track in history. | 2 | 
| tests.startingDeadlineSeconds | How many seconds a job is allowed to miss its scheduled start time before it is considered failed | 500 | 
| tests.concurrencyPolicy | Handle scenario when concurrent jobs are scheduled | "Forbid" | 
| tests.restartPolicy | Restart the container keeping the same Pod in Node | "Never" | 
| tests.ttlSecondsAfterFinished | Clean up finished Jobs after the specific seconds | 600 | 
| tests.backoffLimit | Each pod failure is counted towards the specified limit | 2 | 
| tests.resources | Set container requests and limits for different resources like CPU or memory (essential for production workloads) | 
| tests.env | Add extra environment variables for the Testing pods | [] | 
| tests.envSecret | List of secrets with extra environment variables for all the component pods | [] | 
| tests.extraVolumeMounts | Optionally specify an extra list of additional volumeMounts for all the Testing pods | [] | 
| tests.extraVolumes | Optionally specify an extra list of additional volumes for all the Testing pods | [] |

### Performance
| Property | Description | Default | 
| :--- | :--- | :--- | 
| perfs.enabled | Enable Performance | false | 
| perfs.image.repository | Performance image repository | "qmigrator.azurecr.io/webperfotp" | 
| perfs.image.tag | Performance image tag/version | "985" | 
| perfs.image.pullPolicy | Performance pull policy | "IfNotPresent" | 
| perfs.imagePullSecrets | Performance pull secrets | {} | 
| perfs.annotations | Add extra annotations to the Performance | {} | 
| perfs.podAnnotations | Add extra Pod annotations to the Performance pods | {} | 
| perfs.securityContexts.pod | Default security context for Performance pods | {} | 
| perfs.securityContexts.container | Default security context for Performance containers | {} | 
| perfs.tolerations | Tolerations for Performance pods assignment | {} | 
| perfs.affinity | Affinity for Performance pods assignment (evaluated as a template) | {} | 
| perfs.nodeSelector | Node labels for Performance pods assignment | {} | 
| perfs.labels | Labels for Performance | {} | 
| perfs.schedule | Specifies the cron job schedule using the standard cron syntax | "*/10 * * * *" | 
| perfs.failedJobsHistoryLimit | How many failed executions to track in history. | 2 | 
| perfs.successfulJobsHistoryLimit | How many successful executions to track in history. | 2 | 
| perfs.startingDeadlineSeconds | How many seconds a job is allowed to miss its scheduled start time before it is considered failed | 500 | 
| perfs.concurrencyPolicy | Handle scenario when concurrent jobs are scheduled | Forbid | 
| perfs.restartPolicy | Restart the container keeping the same Pod in Node | Never | 
| perfs.ttlSecondsAfterFinished | Clean up finished Jobs after the specific seconds | 600 | 
| perfs.backoffLimit | Each pod failure is counted towards the specified limit | 2 | 
| perfs.resources | Set container requests and limits for different resources like CPU or memory (essential for production workloads) | 
| perfs.env | Add extra environment variables for the Performance pods | [] | 
| perfs.envSecret | List of secrets with extra environment variables for all the component pods | [] | 
| perfs.extraVolumeMounts | Optionally specify an extra list of additional volumeMounts for all the Performance pods | [] | 
| perfs.extraVolumes | Optionally specify an extra list of additional volumes for all the Performance pods | [] | 

### Deployment
| Property | Description | Default | 
| :--- | :--- | :--- | 
| deplo.enabled | Enable Deployment | false | 
| deplo.image.repository | Deployment image repository | "qmigrator.azurecr.io/webdeployotp" | 
| deplo.image.tag | Deployment image tag/version | "1.0.0" | 
| deplo.image.pullPolicy | Deployment pull policy | "IfNotPresent" | 
| deplo.imagePullSecrets | Deployment pull secrets | {} | 
| deplo.annotations | Add extra annotations to the Deployment | {} | 
| deplo.podAnnotations | Add extra Pod annotations to the Deployment pods | {} | 
| deplo.securityContexts.pod | Default security context for Deployment pods | {} | 
| deplo.securityContexts.container | Default security context for Deployment containers | {} | 
| deplo.tolerations | Tolerations for Deployment pods assignment | {} | 
| deplo.affinity | Affinity for Deployment pods assignment (evaluated as a template) | {} | 
| deplo.nodeSelector | Node labels for Deployment pods assignment | {} | 
| deplo.labels | Labels for Deployment | {} | 
| deplo.schedule | Specifies the cron job schedule using the standard cron syntax | "*/10 * * * *" | 
| deplo.failedJobsHistoryLimit | How many failed executions to track in history. | 2 | 
| deplo.successfulJobsHistoryLimit | How many successful executions to track in history. | 2 | 
| deplo.startingDeadlineSeconds | How many seconds a job is allowed to miss its scheduled start time before it is considered failed | 500 | 
| deplo.concurrencyPolicy | Handle scenario when concurrent jobs are scheduled | Forbid | 
| deplo.restartPolicy | Restart the container keeping the same Pod in Node | Never | 
| deplo.ttlSecondsAfterFinished | Clean up finished Jobs after the specific seconds | 600 | 
| deplo.backoffLimit | Each pod failure is counted towards the specified limit | 2 | 
| deplo.resources | Set container requests and limits for different resources like CPU or memory (essential for production workloads) | 
| deplo.env | Add extra environment variables for the Deployment pods | [] | 
| deplo.envSecret | List of secrets with extra environment variables for all the component pods | [] | 
| deplo.extraVolumeMounts | Optionally specify an extra list of additional volumeMounts for all the Deployment pods | [] | 
| deplo.extraVolumes | Optionally specify an extra list of additional volumes for all the Deployment pods | [] | 

### DBA
| Property | Description | Default | 
| :--- | :--- | :--- | 
| dba.enabled | Enable DBA | false | 
| dba.image.repository | DBA image repository | "qmigrator.azurecr.io/webdbaotp" | 
| dba.image.tag | DBA image tag/version | "986" | 
| dba.image.pullPolicy | DBA pull policy | "IfNotPresent" | 
| dba.imagePullSecrets | DBA pull secrets | {} | 
| dba.annotations | Add extra annotations to the DBA | {} | 
| dba.podAnnotations | Add extra Pod annotations to the DBA pods | {} | 
| dba.securityContexts.pod | Default security context for DBA pods | {} | 
| dba.securityContexts.container | Default security context for DBA containers | {} | 
| dba.tolerations | Tolerations for DBA pods assignment | {} | 
| dba.affinity | Affinity for DBA pods assignment (evaluated as a template) | {} | 
| dba.nodeSelector | Node labels for DBA pods assignment | {} | 
| dba.labels | Labels for DBA | {} | 
| dba.schedule | Specifies the cron job schedule using the standard cron syntax | "*/10 * * * *" | 
| dba.failedJobsHistoryLimit | How many failed executions to track in history. | 2 | 
| dba.successfulJobsHistoryLimit | How many successful executions to track in history. | 2 | 
| dba.startingDeadlineSeconds | How many seconds a job is allowed to miss its scheduled start time before it is considered failed | 500 | 
| dba.concurrencyPolicy | Handle scenario when concurrent jobs are scheduled | Forbid | 
| dba.restartPolicy | Restart the container keeping the same Pod in Node | Never | 
| dba.ttlSecondsAfterFinished | Clean up finished Jobs after the specific seconds | 600 | 
| dba.backoffLimit | Each pod failure is counted towards the specified limit | 2 | 
| dba.resources | Set container requests and limits for different resources like CPU or memory (essential for production workloads) | 
| dba.env | Add extra environment variables for the DBA pods | [] | 
| dba.envSecret | List of secrets with extra environment variables for all the component pods | [] | 
| dba.extraVolumeMounts | Optionally specify an extra list of additional volumeMounts for all the DBA pods | [] | 
| dba.extraVolumes | Optionally specify an extra list of additional volumes for all the DBA pods | [] | 


### Airflow Global
| Property | Description | Default | 
| :--- | :--- | :--- | 
| airflow.enabled | Enable Airflow | false | 
| airflow.name | Name for Airflow | "airflow" | 
| airflow.uid | User id for Airflow | "106665" | 
| airflow.gid | group id for Airflow | "106966" | 
| airflow.image.repository | Airflow image repository | "qmigrator.azurecr.io/qmigair" | 
| airflow.image.tag | Airflow image tag/version | "2.8.4-ofjv-lvs" | 
| airflow.image.pullPolicy | Airflow pull policy | "IfNotPresent" | 
| airflow.imagePullSecrets | Airflow pull secrets | {} | 
| airflow.rbac.create | Create Role and RoleBinding | true | 
| airflow.baseUrl | Base URL of Airflow Webserver | http://0.0.0.0:8080/airflow | 
| airflow.config | Config settings to go into the mounted airflow.cfg | | 
| airflow.airflowLocalSettings | file as a string (can be templated) | ~ | 
| airflow.podTemplate | is a templated string containing the contents of `pod_template_file.yaml` used for KubernetesExecutor workers | ~ | 
| airflow.webserverConfig | string (can be templated) will be mounted into the Airflow Webserver | ~ | 
| airflow.securityContexts.pod | Detailed default security context for Airflow Pods | {} | 
| airflow.securityContexts.containers | Detailed default security context for Airflow Container | {} | 
| airflow.tolerations | Tolerations for Airflow pods | {} | 
| airflow.affinity | Affinity for Airflow pods (evaluated as a template) | {} | 
| airflow.nodeSelector | Node labels for Airflow pods | {} | 
| airflow.labels | Labels for Airflow | {} | 
| airflow.env | Add extra environment variables for the Airflow pods | [] | 
| airflow.envSecret | List of secrets with extra environment variables for all the component pods | [] | 

#### Airflow Secret
| Property | Description | Default | 
| :--- | :--- | :--- | 
| airflow.secret.secretName | Name for project secret | "" (name: qmig-air-secret) | 
| airflow.secret.data.airflow_secret_key | Random generated key for webserver | null | 
| airflow.secret.data.airflow_fernet_key | Random generated key for airflow | null | 
| airflow.secret.data.airflow_password | Airflow login password | null | 
| airflow.secret.data.connection | Connection string for Airflow metadata DB | null | 

#### Airflow Webserver
| Property | Description | Default | 
| :--- | :--- | :--- | 
| airflow.webserver.replicas | Number of Airflow Webserver replicas | 1 | 
| airflow.webserver.safeToEvict | This setting tells Kubernetes that its ok to evict | true | 
| airflow.webserver.annotations | Add extra annotations to the Airflow Webserver | {} | 
| airflow.webserver.podAnnotations | Add extra Pod annotations to the Airflow Webserver pods | {} | 
| airflow.webserver.securityContexts.pod | default security context for Webserver pods | {} | 
| airflow.webserver.securityContexts.container | default security context for Webserver containers | {} | 
| airflow.webserver.tolerations | Tolerations for Airflow Webserver pods | {} | 
| airflow.webserver.affinity | Affinity for Airflow Webserver pods (evaluated as a template) | {} | 
| airflow.webserver.nodeSelector | Node labels for Airflow Webserver pods | {} | 
| airflow.webserver.livenessProbe | livenessProbe on Airflow webserver | 
| airflow.webserver.readinessProbe | readinessProbe on Airflow webserver | 
| airflow.webserver.startupProbe | startupProbe on Airflow webserver | 
| airflow.webserver.command | Command to use when running the Airflow webserver | {} | 
| airflow.webserver.args | Args to use when running the Airflow webserver | ["bash", "-c", "exec airflow webserver"] | 
| airflow.webserver.resources | Set container requests and limits for different resources like CPU or memory (essential for production workloads) | 
| airflow.webserver.service.annotations | Additional custom annotations for Airflow Webserver service | {} | 
| airflow.webserver.service.type | Airflow Webserver service type | "ClusterIP" | 
| airflow.webserver.service.port | Airflow Webserver service HTTP port | 8080 | 

#### Airflow Scheduler
| Property | Description | Default | 
| :--- | :--- | :--- | 
| airflow.scheduler.replicas | Number of Airflow Scheduler replicas | 1 | 
| airflow.scheduler.safeToEvict | This setting tells Kubernetes that its ok to evict | true | 
| airflow.scheduler.annotations | Add extra annotations to the Airflow Scheduler | {} | 
| airflow.scheduler.podAnnotations | Add extra Pod annotations to the Airflow Scheduler pods | {} | 
| airflow.scheduler.securityContexts.pod | default security context for Scheduler pods | {} | 
| airflow.scheduler.securityContexts.container | default security context for Scheduler containers | {} | 
| airflow.scheduler.tolerations | Tolerations for Airflow Scheduler pods | {} | 
| airflow.scheduler.affinity | Affinity for Airflow Scheduler pods (evaluated as a template) | {} | 
| airflow.scheduler.nodeSelector | Node labels for Airflow Scheduler pods | {} | 
| airflow.scheduler.livenessProbe | livenessProbe on Airflow Scheduler | 
| airflow.scheduler.readinessProbe | readinessProbe on Airflow Scheduler | 
| airflow.scheduler.startupProbe | startupProbe on Airflow Scheduler | 
| airflow.scheduler.command | Command to use when running the Airflow scheduler | ~ | 
| airflow.scheduler.args | Args to use when running the Airflow scheduler | ["bash", "-c", "exec airflow scheduler"] | 
| airflow.scheduler.resources | Set container requests and limits for different resources like CPU or memory (essential for production workloads) | 

#### Airflow Worker
| Property | Description | Default | 
| :--- | :--- | :--- | 
| airflow.worker.safeToEvict | This setting tells Kubernetes that its ok to evict | true | 
| airflow.worker.annotations | Add extra annotations to the Airflow Worker | {} | 
| airflow.worker.podAnnotations | Add extra Pod annotations to the Airflow Worker pods | {} | 
| airflow.worker.securityContexts.pod | default security context for Worker pods | {} | 
| airflow.worker.securityContexts.container | default security context for Worker containers | {} | 
| airflow.worker.tolerations | Tolerations for Airflow Worker pods | {} | 
| airflow.worker.affinity | Affinity for Airflow Worker pods (evaluated as a template) | {} | 
| airflow.worker.nodeSelector | Node labels for Airflow Worker pods | {} | 
| airflow.worker.resources | Set container requests and limits for different resources like CPU or memory (essential for production workloads) | 

#### Init-container to wait migration
| Property | Description | Default | 
| :--- | :--- | :--- | 
| airflow.waitForMigrations.enabled | Whether to create an init container to wait for db migrations | true | 
| airflow.waitForMigrations.safeToEvict | This setting tells Kubernetes that its ok to evict | true | 
| airflow.waitForMigrations.annotations | Add extra annotations to the waitForMigrations | {} | 
| airflow.waitForMigrations.podAnnotations | Add extra Pod annotations to the waitForMigrations pods | {} | 
| airflow.waitForMigrations.securityContexts.container | default security context for waitForMigrations containers | {} | 
| airflow.waitForMigrations.resources | Set container requests and limits for different resources like CPU or memory (essential for production workloads) | 

#### Airflow Create User Job
| Property | Description | Default | 
| :--- | :--- | :--- | 
| airflow.createUserJob.safeToEvict | This setting tells Kubernetes that its ok to evict | true | 
| airflow.createUserJob.annotations | Add extra annotations to the createUserJob | {} | 
| airflow.createUserJob.podAnnotations | Add extra Pod annotations to the createUserJob pods | {} | 
| airflow.createUserJob.useHelmHooks | Helm hook for job pod | true | 
| airflow.createUserJob.securityContexts.pod | default security context for createUserJob pods | {} | 
| airflow.createUserJob.securityContexts.container | default security context for createUserJob containers | {} | 
| airflow.createUserJob.tolerations | Tolerations for Airflow createUserJob pods | {} | 
| airflow.createUserJob.affinity | Affinity for Airflow createUserJob pods (evaluated as a template) | {} | 
| airflow.createUserJob.nodeSelector | Node labels for Airflow createUserJob pods | {} | 
| airflow.createUserJob.resources | Set container requests and limits for different resources like CPU or memory (essential for production workloads) | 

#### Airflow DB Migration Job
| Property | Description | Default | 
| :--- | :--- | :--- | 
| airflow.migrateDatabaseJob.enabled | Whether to create airflow database migration job | true | 
| airflow.migrateDatabaseJob.safeToEvict | This setting tells Kubernetes that its ok to evict | true | 
| airflow.migrateDatabaseJob.annotations | Add extra annotations to the migrateDatabaseJob | {} | 
| airflow.migrateDatabaseJob.podAnnotations | Add extra Pod annotations to the migrateDatabaseJob pod | {} | 
| airflow.migrateDatabaseJob.useHelmHooks | Helm hook for job pod | true | 
| airflow.migrateDatabaseJob.securityContexts.pod | default security context for migrateDatabaseJob pod | {} | 
| airflow.migrateDatabaseJob.securityContexts.container | default security context for migrateDatabaseJob containers | {} | 
| airflow.migrateDatabaseJob.tolerations | Tolerations for Airflow migrateDatabaseJob pods | {} | 
| airflow.migrateDatabaseJob.affinity | Affinity for Airflow migrateDatabaseJob pods (evaluated as a template) | {} | 
| airflow.migrateDatabaseJob.nodeSelector | Node labels for Airflow migrateDatabaseJob pods | {} | 
| airflow.migrateDatabaseJob.resources | Set container requests and limits for different resources like CPU or memory (essential for production workloads) |
