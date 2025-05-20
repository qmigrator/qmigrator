# Deploy QMigrator on Elastic Kubernetes Service (EKS) from AWS Marketplace

This guide explains how to deploy QMigrator on Elastic Kubernetes Service (EKS) using the QMigrator Marketplace Helm chart. It also covers basic usage, including creating and consuming messages.

## Prerequisites

Ensure you have the following before starting:

- **EKS cluster:** An existing Elastic Kubernetes Service cluster.
- **kubectl:** The Kubernetes CLI, installed and configured for your cluster.
- **EFS storage**: Set up an EFS by following the [AWS EFS storage creation guide](https://docs.aws.amazon.com/efs/latest/ug/creating-using-create-fs.html) and ensure the EFS is attached to EKS cluster network/subnets.
- **Project details:** Project ID, name, and credentials from Quadrant.


## Deployment Steps
1. Obtain the following project details from Quadrant, which you will receive via email after subscribing as a subscriber user:
    - `projectID`
    - `projectName`
2. Generate and configure the following Kubernetes secrets for Qmigrator:
    
   - Use the following command to create a Kubernetes secret for all required inputs (`PROJECT_ID`, `POSTGRES_PASSWORD`, `PROJECT_NAME`, `REDIS_PASS`) within the specified namespace:

    ```bash
    kubectl create secret generic qmigrator-secrets \
    --from-literal=PROJECT_ID=<project_id> \
    --from-literal=POSTGRES_PASSWORD=<postgres_password> \
    --from-literal=PROJECT_NAME=<project_name> \
    --from-literal=REDIS_PASS=<redis_password> \
    -n <namespace>
    ```
    Replace `<project_id>`, `<postgres_password>`, `<project_name>`, `<redis_password>`, and `<namespace>` with your actual values.

    - To configure Airflow, create the following Kubernetes secrets:

    ```bash
    kubectl create secret generic airflow-secrets \
    --from-literal=airflow-secret-key=$(openssl rand -hex 16) \
    --from-literal=airflow-fernet-key=$(openssl rand -hex 16) \
    --from-literal=airflow-password=<airflow_password> \
    --from-literal=connection="postgresql://postgres:<POSTGRES_PASSWORD>@qmigrator-db.<namespace>.svc:5432/postgres" \
    -n <namespace>
    ```
    Replace `<airflow_password>`, `<POSTGRES_PASSWORD>`, and `<namespace>` with your actual values.

3. During deployment, ensure that the names of the secrets created above (`qmigrator-secrets` and `airflow-secrets`) are correctly referenced in your Kubernetes manifests or Helm charts. For example:
    - Use `secret.secretName` to reference `qmigrator-secrets`.
    - Use `airflow.secret.secretName` to reference `airflow-secrets`.

4. Specify the `efs.fileSystemId` obtained during the EFS setup in your deployment configuration to enable proper storage integration.

## Post-Deployment Steps

### Check Pod Status

1. List pods created by the deployment:
    ```sh
    kubectl get pods -n <namespace>
    ```

2. To expose QMigrator externally, follow the [Gateway Guide](../../example/gatewayapi/README.md) for gateway configuration, or refer to the [Ingress Guide](../../example/ingress/README.md) for legacy ingress setup (deprecated).
