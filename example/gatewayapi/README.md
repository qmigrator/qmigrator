## Update Existing Controller ClassName

If an existing GatewayAPI Controller is already installed, ensure the `className` in the [gateway-route.yaml](gateway-route.yaml) file matches the controller's configured class name. Update the `className` field as needed:

```yaml
spec:
  gatewayClassName: <YOUR_CONTROLLER_CLASSNAME>
```

Replace `<YOUR_CONTROLLER_CLASSNAME>` with the appropriate class name for your controller. Once updated, apply the configuration:

```bash
kubectl apply -f gateway-route.yaml
```

## Quick Setup: NGINX Fabric GatewayAPI

### Prerequisites
- Kubernetes cluster (v1.22 or later)
- `kubectl` and `helm` installed and configured

### Installation Steps

1. **Install GatewayAPI CRDs**:
  ```bash
  kubectl kustomize "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=v2.0.1" | kubectl apply -f -
  ```

2. **Deploy NGINX GatewayAPI Controller**:

  - **Default**
  ```bash
  helm install ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric --create-namespace -n nginx-gateway --version 2.0.1
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

  > [!IMPORTANT]
  > Verify the service names in your `backendRefs` with the services available in your namespace. For example:
  > ```yaml
  > backendRefs:
  >   - name: qmig-airflow-webserver
  > ```

  > [!IMPORTANT]
  > **AWS NLB Configuration:**  
  > If deploying on AWS and using a Network Load Balancer (NLB), ensure your Gateway specs includes the following annotations for proper cross-zone load balancing and external access:
  > 
  > ```yaml
  > kind: Gateway
  > spec:
  >   infrastructure:
  >     annotations:
  >       service.beta.kubernetes.io/aws-load-balancer-attributes: |
  >         load_balancing.cross_zone.enabled=true
  >       service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: instance
  >       service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
  >       service.beta.kubernetes.io/aws-load-balancer-type: external
  > ```

5. **Get Gateway external IP**:
  Retrieve the external IP of the Gateway in your `<namespace>`:
  ```bash
  kubectl get svc -n <namespace>
  ```

6. **(Optional) Map Domain to External IP**:
  Update your domain's DNS settings with your domain provider to point to the external IP of the Gateway. Create an `A` record with the following details:

  - **Type**: A
  - **Name**: `@` (or your desired subdomain, e.g., `www`)
  - **Value**: `<EXTERNAL-IP>` (replace with the external IP retrieved in the previous step)
  - **TTL**: Default or as per your provider's recommendation

  Once updated, allow some time for DNS propagation before accessing your application using your domain.

7. **Verify the Setup**:
  Access the application in your browser or via `curl`:
  ```bash
  curl http://<EXTERNAL-IP>
  ```

  If domain mapped, access your application using `http://your-domain.com`.


### (Only for TLS) Quick Setup: cert-manager for TLS Configuration

1. **Add Helm cert-manager**:
  ```bash
  helm repo add jetstack https://charts.jetstack.io --force-update
  ```

2. **Install cert-manager**:
  ```bash
  helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --set config.enableGatewayAPI=true --set crds.enabled=true --create-namespace
  ```

3. **Verify Installation**:
  ```bash
  kubectl get pods -n cert-manager
  ```

  Ensure all cert-manager pods are running.

4. **Create a ClusterIssuer**:
  Update the [ClusterIssuer](gateway-cluster-issuer.yaml) for Let's Encrypt (staging or production). Once updated, apply the configuration:
  
  ```bash
  kubectl apply -f gateway-cluster-issuer.yaml
  ```
  
  OR
  Update the [Issuer](gateway-issuer.yaml) at namespaced scoped with desired namespace (`{{ Namespace }}`). Once updated, apply the configuration:
  
  ```bash
  kubectl apply -f gateway-issuer.yaml
  ```

5. **Update Gateway Route for TLS**:

  Modify the [Gateway](gateway-route-tls.yaml) file to include the `tls` block and reference the `ClusterIssuer` or `Issuer`. Add the appropriate annotations based on your setup. Example:

    annotations:
     cert-manager.io/cluster-issuer: letsencrypt # Use this if a ClusterIssuer is created
     # cert-manager.io/issuer: letsencrypt # Use this if an Issuer is created

  ```bash
  kubectl apply -f gateway-route-tls.yaml
  ```

  > [!IMPORTANT]
  > Verify the service names in your `backendRefs` with the services available in your namespace. For example:
  > ```yaml
  > backendRefs:
  >   - name: qmig-airflow-webserver
  > ```

6. **Get Gateway external IP**:
  Retrieve the external IP of the Gateway in your `<namespace>`:
  ```bash
  kubectl get svc -n <namespace>
  ```

7. **Map Domain to External IP**:
  Update your domain's DNS settings with your domain provider to point to the external IP of the Gateway. Create an `A` record with the following details:

  - **Type**: A
  - **Name**: `@` (or your desired subdomain, e.g., `www`)
  - **Value**: `<EXTERNAL-IP>` (replace with the external IP retrieved in the previous step)
  - **TTL**: Default or as per your provider's recommendation

  Once updated, allow some time for DNS propagation before accessing your application using your domain.

8. **Verify TLS Setup**:
  Access your application using `https://your-domain.com` to confirm the TLS configuration is working.


## References

For detailed installation and configuration instructions, refer to the official documentation:

- [NGINX Gateway Fabric Installation Guide](https://docs.nginx.com/nginx-gateway-fabric/installation/installing-ngf/helm/)
- [cert-manager Installation Guide](https://cert-manager.io/docs/installation/helm/)
