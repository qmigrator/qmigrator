## Quick Setup: NGINX Fabric GatewayAPI

### Prerequisites
- Kubernetes cluster (v1.22 or later)
- `kubectl` and `helm` installed and configured

### Installation Steps

1. **Install GatewayAPI CRDs**:
  ```bash
  kubectl kustomize "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=v1.6.2" | kubectl apply -f -
  ```

2. **Deploy NGINX GatewayAPI Controller**:
  ```bash
  helm install ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric --create-namespace -n nginx-gateway
  ```

3. **Verify Installation**:
  ```bash
  kubectl get pods -n nginx-gateway
  ```

  Ensure all pods are running.

4. **Create a Gateway Resource**:
  Update the [gateway-route.yaml](gateway-route.yaml) file to include the desired namespace (`{{ Namespace }}`) and replace the placeholder domain with your required domain. Once updated, apply the configuration:

  ```bash
  kubectl apply -f gateway-route.yaml
  ```

5. **Access the Application**:
  Retrieve the external IP of the Gateway:
  ```bash
  kubectl get svc -n nginx-gateway
  ```

  Access the application in your browser or via `curl`:
  ```bash
  curl http://<EXTERNAL-IP>
  ```

### Quick Setup: cert-manager for TLS Configuration

1. **Add Helm cert-manager**:
  ```bash
  helm repo add jetstack https://charts.jetstack.io --force-update
  ```

1. **Install cert-manager**:
  ```bash
  helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --set config.enableGatewayAPI=true --set crds.enabled=true --create-namespace
  ```

2. **Verify Installation**:
  ```bash
  kubectl get pods -n cert-manager
  ```

  Ensure all cert-manager pods are running.

3. **Create a ClusterIssuer**:
  Update the [ClusterIssuer](gateway-cluster-issuer.yaml) for Let's Encrypt (staging or production). Once updated, apply the configuration:
  
  ```bash
  kubectl apply -f gateway-cluster-issuer.yaml
  ```
  
  OR
  Update the [Issuer](gateway-issuer.yaml) at namespaced scoped with desired namespace (`{{ Namespace }}`). Once updated, apply the configuration:
  
  ```bash
  kubectl apply -f gateway-issuer.yaml
  ```


4. **Update Gateway Route for TLS**:

  Modify the [Gateway](gateway-route-tls.yaml) file to include the `tls` block and reference the `ClusterIssuer` or `Issuer`. Add the appropriate annotations based on your setup. Example:

    annotations:
     cert-manager.io/cluster-issuer: letsencrypt # Use this if a ClusterIssuer is created
     # cert-manager.io/issuer: letsencrypt # Use this if an Issuer is created

  ```bash
  kubectl apply -f gateway-route-tls.yaml
  ```

6. **Verify TLS Setup**:
  Access your application using `https://your-domain.com` to confirm the TLS configuration is working.


## References

For detailed installation and configuration instructions, refer to the official documentation:

- [NGINX Gateway Fabric Installation Guide](https://docs.nginx.com/nginx-gateway-fabric/installation/installing-ngf/helm/)
- [cert-manager Installation Guide](https://cert-manager.io/docs/installation/helm/)
