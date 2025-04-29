## Quick Setup: NGINX Ingress Controller

### Prerequisites
- Kubernetes cluster (v1.22 or later)
- `kubectl` and `helm` installed and configured

### Installation Steps

1. **nstall Ingress CRDs**:
  ```bash
  kubectl apply -f https://raw.githubusercontent.com/nginx/kubernetes-ingress/v5.0.0/deploy/crds.yaml
  ```

2. **Install NGINX Ingress Controller**:
  ```bash
  helm install ingress-nginx oci://ghcr.io/nginx/charts/nginx-ingress --version 2.1.0 --create-namespace -n ingress-nginx
  ```

3. **Verify Installation**:
  ```bash
  kubectl get pods -n ingress-nginx
  ```

  Ensure all pods are running.

4. **Get Ingress external IP**:
  Retrieve the external IP of the Ingress Controller:
  ```bash
  kubectl get svc -n ingress-nginx
  ```
  
5. **Create an Ingress Resource**:
  Update the [Ingress](ingress.yaml) file to include the desired namespace (`{{ Namespace }}`) and replace the placeholder domain with your required domain. Once updated, apply the configuration:

  ```bash
  kubectl apply -f ingress.yaml
  ```

  > **Note**: Verify the service names in your `backend` with the services available in your namespace. For example:
  > ```yaml
  > backend:
  >   service:
  >     name: qmig-app
  > ```

6. **Verify the Setup**:
  Access the application in your browser or via `curl`:
  ```bash
  curl http://<EXTERNAL-IP>
  ```

  If domain mapped, access your application using `http://your-domain.com`.


### Quick Setup: cert-manager for TLS Configuration

1. **Add Helm cert-manager**:
  ```bash
  helm repo add jetstack https://charts.jetstack.io --force-update
  ```

2. **Install cert-manager**:
  ```bash
  helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --set crds.enabled=true --create-namespace
  ```

3. **Verify Installation**:
  ```bash
  kubectl get pods -n cert-manager
  ```

  Ensure all cert-manager pods are running.

4. **Create a ClusterIssuer**:
  Update the [ClusterIssuer](ingress-cluster-issuer.yaml) for Let's Encrypt (staging or production). Once updated, apply the configuration:
  
  ```bash
  kubectl apply -f ingress-cluster-issuer.yaml
  ```
  
  OR
  Update the [Issuer](ingress-issuer.yaml) at namespaced scoped with desired namespace (`{{ Namespace }}`). Once updated, apply the configuration:
  
  ```bash
  kubectl apply -f ingress-issuer.yaml
  ```

5. **Map Domain to External IP**:
  Update your domain's DNS settings with your domain provider to point to the external IP of the Ingress. Create an `A` record with the following details:

  - **Type**: A
  - **Name**: `@` (or your desired subdomain, e.g., `www`)
  - **Value**: `<EXTERNAL-IP>` (replace with the external IP retrieved in the previous step)
  - **TTL**: Default or as per your provider's recommendation

  Once updated, allow some time for DNS propagation before accessing your application using your domain.

6. **Update Ingress Route for TLS**:

  Modify the [Ingress](ingress-tls.yaml) file to include the `tls` block and reference the `ClusterIssuer` or `Issuer`. Add the appropriate annotations based on your setup. Example:

    annotations:
     cert-manager.io/cluster-issuer: letsencrypt # Use this if a ClusterIssuer is created
     # cert-manager.io/issuer: letsencrypt # Use this if an Issuer is created

  ```bash
  kubectl apply -f ingress-tls.yaml
  ```

  > **Note**: Verify the service names in your `backend` with the services available in your namespace. For example:
  > ```yaml
  > backend:
  >   service:
  >     name: qmig-app
  > ```

7. **Verify TLS Setup**:
  Access your application using `https://your-domain.com` to confirm the TLS configuration is working.


## References

For detailed installation and configuration instructions, refer to the official documentation:

- [NGINX Ingress Controller Installation Guide](https://docs.nginx.com/nginx-ingress-controller/installation/installing-nic/installation-with-helm/)
- [cert-manager Installation Guide](https://cert-manager.io/docs/installation/helm/)
