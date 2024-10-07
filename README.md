# Qmigrator Helm

## Visit GitHub On for more information
https://github.com/quadnaren/Qmig

# Pre-requisites
- Project information from vendor like project ID, Name, Login information, etc.
- Docker Image registry credentials given by the vendor

> [!NOTE]
The above parameters are required for secret. Check the secret & imageCredentials section of values.yaml

## Required namespace or create your own
```
Kubectl create namespace qmig-ns 
Kubectl config set-context --current --namespace=qmig-ns
```

## Install Qmigrator
```
helm repo add qmigrator https://quadnaren.github.io/Qmig
helm repo update
helm install <name> qmigrator/qmig \
  --set secret.data.PROJECT_ID="1234" --set secret.data.PROJECT_NAME="example" \
  --set secret.data.POSTGRES_PASSWORD="xxxx" --set secret.data.REDIS_PASS="xxxx" \
  --set imageCredentials.data.username="userxxxx" --set imageCredentials.data.password="passxxxx"
```

## Ingress Controller
- Qmigrator uses ingress to expose the application
- You may use existing ingress if present in the cluster by updating the properties of
  - ingress
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
- Qmigrator uses shared volume for components like App, Engine & Others
- While Metadata DB (Postgres) & Cache Component have their own
- Override the pre-created PVC from persistentVolume.existingClaim flag in values.yaml
- You may use the existing/default StorageClass for dynamic volume creation

> [!Tip]
Please check the examples for creating custom StorageClass, PV & PVC from this repo & override persistentVolume.existingClaim <br>
More Ref: http://kubernetes.io/docs/user-guide/persistent-volumes/

> [!IMPORTANT]
DO NOT USE ReadWriteMany or Shared Persistent volume given here to the Metadata DB (Postgres) & Cache Component

# Customise Qmigrator
- Use values.yaml from this repo, edit as required, and use while installing Helm
```
helm install <name> qmigrator/qmig -f values.yaml
```