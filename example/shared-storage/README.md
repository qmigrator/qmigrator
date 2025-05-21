# Shared Persistent Volumes for Cloud Providers

This folder contains example static PersistentVolume (PV) configurations for various cloud environments.  
**Each YAML manifest includes the StorageClass, PersistentVolume, and PersistentVolumeClaim for its cloud provider.**

- **AWS** (`aws-pv.yaml`)
- **Azure** (`azure-pv.yaml`)
- **Docker Desktop** (`docker-desktop-pv.yaml`)
- **GCP** (`gcp-pv.yaml`)
- **Minikube** (`minikube-pv.yaml`)

### Cloud-specific updates

#### AWS
- Update the EFS filesystem ID from AWS:
  ```yaml
  csi:
    driver: efs.csi.aws.com
    volumeHandle: {{FileSystemId}} # Volume ID from EFS system
  ```
> [!NOTE]
> Only applicable to managed EKS, not EKS Auto Mode.

#### Azure
- Create a Kubernetes secret for your Azure file share credentials:
  ```sh
  kubectl create secret generic fileshare-secret -n qmig-ns \
    --from-literal=azurestorageaccountname=<storage_account_name> \
    --from-literal=azurestorageaccountkey=<storage_key>
  ```
  Replace `<storage_account_name>` and `<storage_key>` with your Azure Storage account name and key.

- Update the parameters for your Azure file share:
  ```yaml
  csi:
    driver: file.csi.azure.com
    readOnly: false
    volumeHandle: qmig-shared-pv0
    volumeAttributes:
      resourceGroup: {{AZURE_RG}} # Resource Group
      shareName: {{AZURE_FILESHARE}} # Fileshare name
    nodeStageSecretRef:
      name: {{STG_KEY_SECRET_NAME}} # Storage account key secret created before
      namespace: qmig-ns
  ```

#### Docker Desktop
- Update the local path to be mounted:
  ```yaml
  hostPath:
    path: {{LOCAL_PATH}} # Path to be mounted from Local
  ```
> [!NOTE]
> You may need to use the WSL mounted path for your drive C: as `/run/desktop/mnt/host/c/`.

#### GCP
- Update the GCP bucket name:
  ```yaml
  csi:
    driver: gcsfuse.csi.storage.gke.io
    volumeHandle: {{BUCKET_NAME}} # GCP Bucket name
    readOnly: false
  ```
> [!IMPORTANT]
> Ensure the service account used by Pods has read-write permission and add the following to your podSpec

  ```yaml
  annotations:
    gke-gcsfuse/volumes: "true"
  ```

#### Minikube
- Update the local path to be mounted:
  ```yaml
  hostPath:
    path: {{LOCAL_PATH}} # Path to be mounted from Local
  ```
     
## Usage

1. **Select your cloud provider:**  
   Choose the appropriate YAML file for your environment (e.g., `aws-pv.yaml`, `azure-pv.yaml`, etc.).  
   Each file contains the StorageClass, PersistentVolume, and PersistentVolumeClaim definitions for that cloud.

2. **Review and update the manifest:**  
   - Edit the manifest to match your environment (e.g., file system IDs, storage size, access modes).
   - Ensure the `storageClassName` is consistent across StorageClass, PV, and PVC sections.

3. **Apply the manifest:**  
   ```sh
   kubectl apply -f aws-pv.yaml
   ```
   *(Replace `aws-pv.yaml` with the file for your provider, e.g., `azure-pv.yaml`, `gcp-pv.yaml`, etc.)*

4. **Reference the PVC in your workloads:**  
   In your Pod or Deployment YAML, reference the PVC by name:
   ```yaml
   volumes:
     - name: shared-storage
       persistentVolumeClaim:
         claimName: <your-pvc-name>
   ```

## Notes

- Each manifest is tailored for its respective cloud provider's shared file system (e.g., EFS for AWS, Azure Files for Azure, Filestore for GCP).
- Review and customize the parameters as needed for your cluster setup.

## Refrences

- [Kubernetes Persistent Volumes documentation](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [AWS EFS CSI Driver for EKS](https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html)
- [GCP Cloud Storage FUSE CSI Driver (static provisioning)](https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/cloud-storage-fuse-csi-driver#provision-static)
- [Azure Files CSI Driver for AKS](https://learn.microsoft.com/en-us/azure/aks/azure-csi-files-storage-provision)

