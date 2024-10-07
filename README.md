# Qmigrator Helm

## Pre-requisites
- Project information from Quadrant like project ID, Name, Login information, etc.
- Docker/Helm registry credentials given by the Quadrant
> [!NOTE]
The above parameters are required for secret. Check the secret & imageCredentials section of values.yaml

### Namespace creation or use own
```
Kubectl create namespace qmig-ns 
Kubectl config set-context --current --namespace=qmig-ns
```

### Install Qmigrator
```
helm registry login qmigrator.azurecr.io --username <username> --password <password>
helm install <name> oci://qmigrator.azurecr.io/helm/qmig \
  --set secret.data.PROJECT_ID="1234" --set secret.data.PROJECT_NAME="example" \
  --set secret.data.POSTGRES_PASSWORD="xxxx" --set secret.data.REDIS_PASS="xxxx" \
  --set imageCredentials.data.username="userxxxx" --set imageCredentials.data.password="passxxxx"
```

## Ingress Controller
- Qmigrator uses ingress to expose the application
- You may use existing ingress if present in the cluster by updating the properties of
<br>OR 
- Enable the flag of Ingress controller installation within the Helm chart
```
  --set ingressController.enabled=true
```
- Two providers of Ingress Controller available ["kubernetes", "nginx-inc"] which can be set via provider flag

> [!NOTE]
More Ref: https://github.com/kubernetes/ingress-nginx <br>
https://github.com/nginxinc/kubernetes-ingress

## Enable Airflow DataMigration
- Pass extra flag for Airflow installation within Helm chart
- Password is mandatory to access the Airflow
```
  --set airflow.enabled=true --set airflow.secret.data.airflow_password="passxxxx"
```

## Data Persistence
- Qmigrator Application requires two Storage 
  - Shared Disk – Sharable across application (ReadWriteMany) 
  - Block Storage – Each Disk for Database & Cache (ReadWriteOnce) 

- Helm chart does support dynamic or static provisioning of PV/PVC creation; however, you need to manage the storage class and manual creation of persistent volume, etc. 

> [!IMPORTANT]
DO NOT USE ReadWriteMany or Shared Persistent volume given here to the Metadata DB (Postgres) & Cache Component

> [!TIP]
Check more [examples](example) in the repository

### Docker Desktop volume (Windows)
- Use on Docker Desktop Kubernetes, LocalPath as Windows device path

### Minikube volume (Linux, Windows, MacOS, etc.)
- Mount the local path while starting the minikube
- eg. /hostpc on minikube points to {LOCAL_PATH} of device
```
minikube start --mount --mount-string={LOCAL_PATH}:/hostpc
```

### Azure Cloud volume
- Fileshare in Azure can be mounted on Kubernetes
- Required secret key to access & mount
- See more: https://learn.microsoft.com/en-us/azure/aks/azure-csi-files-storage-provision

### Google Cloud volume
- GSC bucket can be mounted on Kubernetes, using gscfuse driver
- Service account required with permission to access & attach
- See more: https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/cloud-storage-fuse-csi-driver#create-persistentvolume

### AWS Cloud volume
- Shared system in AWS using EFS can be mounted
- User & ODIC based login in AWS cluster can use & attach
- See more: https://github.com/kubernetes-sigs/aws-efs-csi-driver/blob/master/examples/kubernetes/static_provisioning/README.md

## TLS Certificate (Optional) 
The APIs & GUI can be served over a TLS1.2+ connection. Ingress TLS can be set up using cert-manager &  letsencrypt, which manager auto-renew before expiration too.

- Install the cert-managaer using Helm
 https://cert-manager.io/docs/installation/helm/

- Create certificate issuer on namespace/cluster
  https://cert-manager.io/docs/concepts/issuer/

- Update the annotation of ingress in ingress section of Qmigrator Helm
https://cert-manager.io/docs/concepts/issuer/

> [!NOTE]
Depending on the requirement you can use the other provider or bring your own TLS certificate 
https://kubernetes.io/docs/concepts/services-networking/ingress/#tls 

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
| imageCredentials.create | create docker pull secret | true 
| imageCredentials.secretName | Name for docker secret | "" (name: qmig-docker) | 
| imageCredentials.annotations | Annotations for docker secret | {} | 
| imageCredentials.labels | Labels for docker secret | {} | 
| imageCredentials.data.registry | Server/Registry host. | qmigrator.azurecr.io | 
| imageCredentials.data.username | Username for given docker host | null | 
| imageCredentials.data.password | Password for given docker host | null | 
### Shared Volume
| Property | Description | Default | 
| :--- | :--- | :--- | 
| shared.persistentVolume.enabled | If false, use emptyDir | true | 
| shared.persistentVolume.accessModes | How should the volume be accessible in App | ReadWriteMany | 
| shared.persistentVolume.annotations | Persistent Volume Claim annotations | {} | 
| shared.persistentVolume.labels | Labels for docker persistentVolume | {} | 
| shared.persistentVolume.existingClaim | Name of PVC created manually before volume | "" | 
| shared.persistentVolume.subPath | Subdirectory of data Persistent Volume to mount | "" | 
| shared.persistentVolume.size | Persistent Volume size | 5Gi | 
| shared.persistentVolume.storageClass | Persistent Volume Storage Class | "" (Default from Kubernetes) | 
| shared.persistentVolume.volumeBindingMode | Persistent Volume Binding Mode | "" (Default from Kubernetes) | 
| shared.folderPath.extraSubpath | subpath for Extra folder in a shared volume | "extra" | 
| shared.folderPath.dagsSubpath | subpath for Dag's folder of airflow in a shared volume | "dags" | 
| shared.folderPath.logsSubpath | subpath for logs folder of airflow in a shared volume | "logs" | 
### Ingress Controller
| Property | Description | Default | 
| :--- | :--- | :--- | 
| ingressController.enabled | Whether or not to install the ingressController | false | 
| ingressController.provider | The name of the ingressController provider either nginx-inc or kubernetes |"kubernetes" | 
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
| ingressController.securityContexts.pod | default security context for Ingress Controller pods | {} | 
| ingressController.securityContexts.container | default security context for Ingress Controller containers | | 
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
| gateway.enabled | Enable create gateway | false
| gateway.className | GatewayClass that will be used to implement the gateway | "nginx"
| gateway.annotations | Additional annotations for the gateway resource | {}
| gateway.labels | Add labels for the gateway | {}
| gateway.listeners | Add listerners for the gateway | - 
### HTTPRoute
| Property | Description | Default | 
| :--- | :--- | :--- | 
| httpRoutes.enabled | Create the routes on gateway | false
| httpRoutes.className | GatewayClass name | "nginx"
| httpRoutes.annotations | Additional annotations for the httpRoutes | {}
| httpRoutes.labels | Add labels for the httpRoutes | {}
| httpRoutes.parentRefs | define route parents to gateway | -
| httpRoutes.hostnames | hostnames in routes record | []
| httpRoutes.redirectHttp | create redirect filter http to https | false
### Service Account
| Property | Description | Default | 
| :--- | :--- | :--- | 
| serviceAccount.create | Enable creation of ServiceAccount | true | 
| serviceAccount.name | The name of the ServiceAccount to use | "" (name: qmig-opr) | 
| serviceAccount.annotations | Additional custom annotations for the ServiceAccount | {} | 
| serviceAccount.labels | Labels for ServiceAccount | {} | 
| rbac.create | Create Role and RoleBinding | true | 
| rbac.namespaced | Restrict to namespaced role | false |
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
| app.securityContexts.pod | default security context for App Component pods | {} | 
| app.securityContexts.container | default security context for App Component containers | {} | 
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
| eng.securityContexts.pod | default security context for Engine component pods | {} | 
| eng.securityContexts.container | default security context for Engine component containers | {} | 
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
| eng.env | Add extra environment variables for the Engine component pods | [] | 
| eng.envSecret | List of secrets with extra environment variables for all the component pods | [] | 
### Metadata Database
| Property | Description | Default | 
| :--- | :--- | :--- | 
| db.enabled Provision the postgres deployment | true |
| db.dbConnection.hostname Provide the hostname if used external connection | "" (Auto Generates) |
| db.dbConnection.username username for connection to DB | "postgres" |
| db.dbConnection.port port for connection to DB | "5432" |
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
| db.securityContexts.pod | default security context for DB Component pods | {} | 
| db.securityContexts.container | default security context for DB Component containers | {} | 
| db.tolerations | Tolerations for DB component pods assignment | {} | 
| db.affinity | Affinity for DB component pods assignment (evaluated as a template) | {} | 
| db.nodeSelector | Node labels for DB component pods assignment | {} | 
| db.labels | Labels for DB Component | {} | 
| db.initContainers.image.repository | Load DB image repository | "qmigrator.azurecr.io/qmigdb-ini" | 
| db.initContainers.image.tag | Load DB image tag/version | "1164" | 
| db.initContainers.resources | Set Init container requests and limits for different resources like CPU or memory | 
| db.persistentVolume.enabled | If false, use emptyDir | true | 
| db.persistentVolume.accessModes | How should the volume accessible in App | ReadWriteOnce | 
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
