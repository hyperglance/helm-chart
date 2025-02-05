<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/hyperglance/helm-chart/main/files/hyperglance_logo_dark.svg">
  <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/hyperglance/helm-chart/main/files/hyperglance_logo_dark.svg">
  <img alt="Hyperglance logo" src="https://raw.githubusercontent.com/hyperglance/helm-chart/master/main/hyperglance_logo_dark.svg">
</picture>


- [Hyperglance - Helm](#hyperglance-helm)
- [Using The Helm Chart](#using-the-helm-chart)
   * [Pre-Requisites](#pre-requisites)
      + [General](#general)
      + [EKS With Fargate or Managed Nodes](#eks-with-fargate-or-managed-nodes)
   * [Acquire the Hyperglance-helm chart](#acquire-the-hyperglance-helm-chart)
   * [Provenance (optional)](#provenance-optional)
   * [Accessing Hyperglance WebUI & Login](#accessing-hyperglance-webui-login)
   * [Customize The Installation](#customize-the-installation)
- [Use With EKS](#use-with-eks)
   * [Create An IAM Role And Policy for Hyperglance](#create-an-iam-role-and-policy-for-hyperglance)
   * [EKS With Fargate](#eks-with-fargate)
   * [EKS With Managed Nodes](#eks-with-managed-nodes)
- [Use With AKS - Instructions coming soon](#use-with-aks)
- [Use With GKE - Instructions coming soon](#use-with-gke)
- [Use With ISTIO](#use-with-istio)
   * [Terminate SSL With The Included Apache container](#terminate-ssl-with-the-included-apache-container)
   * [Terminate SSL With Istio](#terminate-ssl-with-istio)
- [Single-Sign-On (SAML)](#single-sign-on-saml)
- [Using existing secrets](#using-existing-secrets)


# Hyperglance - Helm

This Repository contains a helm chart that can be used to deploy Hyperglance to your Kubernetes cluster.

:information_source: Please note that this chart is still in active development, so checking for any breaking changes prior to upgrading is highly recommneded. These will all be noted in [BREAKING_CHANGES.md](BREAKING_CHANGES.md)

# Using The Helm Chart
## Pre-Requisites
### General
:information_source: This README assumes that you already have a Kubernetes Cluster deployed, and that you already have [helm](https://helm.sh/docs/intro/install/) and [kubectl](https://kubernetes.io/docs/tasks/tools/) installed.

### EKS With Fargate or Managed Nodes
Please see the dedicated sections for detailed information on the requirements for deploying to EKS with Fargate or managed nodes.

- [EKS With Fargate](#eks-with-fargate)
- [EKS With Managed Nodes](#eks-with-managed-nodes)

## Acquire the Hyperglance-helm chart

:information_source: The preferred method of installing the helm chart is via the our public chart repository. Our charts are released with the app version and chart version in lockstep. 

To download the helm chart from our public repository (preferred):
```bash
helm repo add hyperglance https://hyperglance.github.io/helm-chart/
helm repo update
```
Download the example `values.yaml` file from the repo, and amend as required.
```bash
wget https://raw.githubusercontent.com/hyperglance/helm-chart/refs/heads/main/values.yaml
```

To install Hyperglance. Omit `-n hyperglance` and `--create-namespace` if deploying to the default namespace.
```bash
helm install hyperglance hyperglance/hyperglance-helm -n hyperglance -f values.yaml --create-namespace
```

Tp update Hyperglance. Omit `-n hyperglance` if hyperglance was deployed to the default namespace.
```bash
helm upgrade hyperglance hyperglance/hyperglance-helm -n hyperglance -f values.yaml
```

## Provenance (optional)
The Hyperglance helm charts are signed by our gpg key. You can verify the release prior to installation by appending `--verify` to the helm install command.

```bash
helm install hyperglance hyperglance/hyperglance-helm -n hyperglance -f values.yaml --verify
```

If you wish to make use of this functionality, you will need to import our public gpg key.

```bash
# Download our public gpg key
wget https://hyperglance-public-keys.s3.eu-west-2.amazonaws.com/hyperglance-pub.gpg

# Import the key
gpg --import hyperglance-pub.gpg

# Export key to pubring so helm can access
gpg --export >~/.gnupg/pubring.gpg
```

## Accessing Hyperglance WebUI & Login
The Hyperglance web interface will be accessible on the ip address of the instance. For example `https://IP_ADDRESS`. On initial deployment, you will be presented with a certificate warning. This is due to the default provided ssl certificated being self signed. This can be changed by amending the parameters in the `values.yaml`.

The defaul credentials to log into the instance are:

```
Username: admin
Password: admin
```

It is highly recommended you [change the password](https://support.hyperglance.com/knowledge/how-to-change-hyperglance-login-password) once you login.

Upon login, you will need to go into settings and add your license.
After that, go ahead and add your first cloud provider account or kubernetes cluster. You can find guides for all our supported cloud providers [here](https://support.hyperglance.com/knowledge/setup-configuration).


## Customize The Installation
To customize the Hyperglance deployment, a values.yaml can be created and passed to the helm command. 

The minimum configuration options to provide are:
```yaml
## @param URL Set the URL that Hyperglance can be reached on.
URL: ''
```

A number of additional configuration parameters are exposed. Please see the `values.yaml` file for all the available parameters and associated documentation.

# Use With EKS
## Create An IAM Role And Policy for Hyperglance

Hyperglance will utilise the service account configured during setup to poll AWS for resources.

Create a role, select the trusted entity as the OIDC provider created in the prerequisites and assign a policy with the permissions required for Hyperglance - [these can be found here](https://support.hyperglance.com/knowledge/aws-iam-policy-requirements)

We'll reduce the scope of this trust to only the service account we will create on EKS. On the newly created role in AWS IAM, edit the trust policy/trust relationship. It will look something like this by default:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789012:oidc-provider/oidc.eks.eu-west-3.amazonaws.com/id/183E80BB183ABCDE102232070EDC421B"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.<AWS REGION>.amazonaws.com/id/183E80BB183AB941111111110EDC4969:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
```

Change the line after string equals to the following, substituting  <namespace>, <service-account-username> and changing :aud to :sub:

```json
"StringEquals": {
          "oidc.eks.<AWS REGION>.amazonaws.com/id/183E80BB183AB941111111110EDC4969:sub": "system:serviceaccount:<namespace>:<service-account-username>"
}
```

Make a note of the ARN of the role. You will need to populate this value in your values.yaml.

Populate the values.yaml with the options shown below. 

```yaml
## @param serviceAccount.enabled Enable a AWS service account.
## @param serviceAccount.name Service account name
## @param serviceAccount.iamRole Service account role ARN
serviceAccount:
  enabled: false
  name: hyperglance
  iamRole: 
```  

## EKS With Fargate
:warning: Deploying on EKS with Fargate is considerably more involved, and extensive prerequisites are required.

This deployment assumes you already have the following prerequisites satisfied:

:information_source: [This guide may be useful in assisting you to satisfy these prerequisites](https://aws.amazon.com/blogs/containers/running-stateful-workloads-with-amazon-eks-on-aws-fargate-using-amazon-efs/)

1. A functioning AWS EKS using Fargate cluster - [AWS guide](https://docs.aws.amazon.com/eks/latest/userguide/fargate-getting-started.html) or [EKSCTL guide](https://eksctl.io/usage/fargate-support/)
2. EKS ALB controller provisioned and configured - [AWS guide](https://aws.amazon.com/premiumsupport/knowledge-center/eks-alb-ingress-controller-fargate/)
3. Kubernetes EFS CSIDriver and Storage class deployed to the cluster - 
   If you don't have this loaded currently, you can apply this using the following csi driver and storageclass examples below. ```kubectl apply -f csidriver.yaml -f storageclass.yaml```

    csidriver.yaml

    ```yaml
    ---
    apiVersion: storage.k8s.io/v1
    kind: CSIDriver
    metadata:
      name: efs.csi.aws.com
    spec:
      attachRequired: false
    ```

    storageclass.yaml

    ```yaml
    ---
    kind: StorageClass
    apiVersion: storage.k8s.io/v1
    metadata:
      name: efs-sc
    provisioner: efs.csi.aws.com
    volumeBindingMode: Immediate
    ```

4. An EFS filesystem configured and accessible from your EKS cluster with [two access points configured](https://docs.aws.amazon.com/efs/latest/ug/create-access-point.html) to be used for persistent volumes - confirming the paths exist on EFS for the access points
5. A TLS certificate available in [Amazon Certificate Manager](https://aws.amazon.com/certificate-manager/) for use with the Application Load Balancer
6. An IAM OIDC identity provider is configured for your cluster, to allow service account authentication into AWS - [AWS guide](https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html)
7. Kubectl installed and configured for use with your EKS cluster - [AWS guide](https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html)
8. Helm installed - [Helm guide](https://helm.sh/docs/intro/install/)
9. IAM Role and Policy as described above. [Create an IAM role and policy for Hyperglance](#create-an-iam-role-and-policy-for-hyperglance).
10. Once those requirements are met, you can update the following section in the `values.yaml`.

```yaml
## @param fargate.enabled [default: false] Set to true to enable eks fargate deployment. Please check the readme for further information regarding deployment to EKS Fargate.
## @param fargate.namespace EKS Fargate namespace Hyperglance is deployed to.
## @param fargate.hg_url Hyperglance url - Can be mapped to .Values.URL
## @param fargate.service.type [default: LoadBalancer] Service typer
## @param fargate.service.https.port [default: 443] HTTPS port
## @param fargate.efs.filesystem_id EFS Filesystem ID (fs-xxxxx)
## @param fargate.efs.postgresql.accesspoint_id EFS Access Point ID for postgresql data (fsap-xxxx)
## @param fargate.efs.postgresql.sub_path EFS sub path for postgresql data.
## @param fargate.efs.hyperglance.accesspoint_id EFS Access Point ID for Hyperglance data (fsap-xxxx)
## @param fargate.efs.hyperglance.sub_path EFS sub path for Hyperglance data.
## @param fargate.albCertificateArn AWS Loadbalancer Certificate ARN arn:aws:acm:xxxx)
fargate:
  enabled: false
  namespace: 
  hg_url: 
  service:
    type: LoadBalancer
    https:
      port: 443
  efs:
    storageClassName: efs-sc
    filesystem_id: fs-xxxx
    postgresql:
      accesspoint_id: fsap-xxxx
      sub_path: 
      storageCapacity: 20Gi
    hyperglance:
      accesspoint_id: fsap-xxxx
      sub_path: 
      storageCapacity: 20Gi
  albCertificateArn: arn:aws:acm:xxxx
```

## EKS With Managed Nodes
Please note, if installing to EKS, you will need to ensure that EBS CSI driver is installed on the cluster. Official documentation can be found [here](https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html).

The following steps are provided as a overview of the steps required, however we recommend following the official documentation provided in the link above.

1. Associate a oidc iam provider. An example command using `eksctl` is provided below. Replace `region` and `cluster-name` with the appropriate values for your cluster. This will return a OIDC url.
```
eksctl utils associate-iam-oidc-provider --region=region --cluster=cluster-name --approve
```
2. Create a file called `aws-ebs-csi-driver-trust-policy.json` and populate it with the following json. Replace `111122223333` with your account id, `EXAMPLED539D4633E53DE1B71EXAMPLE` with the relevant value from your OIDC url and `region-code` with the region of your eks cluster.
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::111122223333:oidc-provider/oidc.eks.region-code.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.region-code.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE:aud": "sts.amazonaws.com",
          "oidc.eks.region-code.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }
  ]
}
```
3. You can use the aws cli to apply this policy by running:
```bash
aws iam create-role \
      --role-name AmazonEKS_EBS_CSI_DriverRole \
      --assume-role-policy-document file://"aws-ebs-csi-driver-trust-policy.json"
```
4. Locate the policy ARN for the EBS CSI Driver Role using the aws cli.
```bash
aws iam list-policies --query "Policies[?PolicyName=='AmazonEBSCSIDriverPolicy'].Arn" --output text
```
5. Run the following command, replacing the `your-arn` value with the return value of the above command.
```bash
aws iam attach-role-policy \
      --policy-arn your-arn \
      --role-name AmazonEKS_EBS_CSI_DriverRole
```
6. Now install the EBS CSI Driver using one of the methods described in the [official documentation](https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html). As an example, the `eksctl` cli tool command is provided below. Replace `cluster-name`
with your clusters name, and the `account-id` with your account id.

NOTE the usage of `aws-us-gov`. This command is specifically for AWS Gov Cloud. Amend for other regions as required.

```bash
eksctl create addon --cluster cluster-name --name aws-ebs-csi-driver --version latest \
    --service-account-role-arn arn:aws-us-gov:iam::account-id:role/AmazonEKS_EBS_CSI_DriverRole --force
```
7. Check the AWS EKS cluster to ensure the addon has been successfully installed and an IAM role is attached. You can also run the following command to check for the existence of ebs related pods.
```bash
kubectl get pods -A
```
8. Create a file called `storageclass.yml` and populate it with the following data:
```bash
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-sc
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer
parameters:
  type: gp3 # Change to gp2, io2, etc., depending on your needs
  encrypted: "true"
```
9. Apply the above file to your cluster by running:
```bash
kubectl apply -f storageclass.yml
```
10. Update the `pvc.storageClassName` value in the`values.yaml` file for the hyperglance helm chart to `ebs-sc` like the example below.
```yaml
pvc:
  storageClassName: ebs-sc
  annotations: {}
  storageRequest: 
    hyperglance: 3Gi
    postgres: 3Gi  
```

You can use the following command to get the public url for Hyperglance. Omit -n hyperglance if deployed to the default namespace, or provide the correct namespace if deployed into another namespace.

```bash
kubectl get svc -n hyperglance

# Output
NAME               TYPE           CLUSTER-IP       EXTERNAL-IP                               PORT(S)                      AGE
hyperglance-helm   LoadBalancer   redacted   redacted-redacted.us-east-1.elb.amazonaws.com   80:32368/TCP,443:30848/TCP   56s
```

# Use With AKS

Instructions coming soon. If this is of interest to you please [contact us](https://www.hyperglance.com/contact/).

# Use With GKE

Instructions coming soon. If this is of interest to you please [contact us](https://www.hyperglance.com/contact/).

# Use With ISTIO
Hyperglance has support for [istio](https://istio.io/). There are 2 methods, depending on how you wish to terminate tls. These are detailed further below.

## Terminate SSL With The Included Apache container
For this method, we need to have the following configuration optios set in the values.yaml file.

```yaml
# Default is of type loadbalancer. Set to ClusterIP to prevent an additional load balancer being exposed.
service:
  type: ClusterIP

# The default policy for our marketplace images is "Default", but ClusterFirst is required for the istio sidecar to function correctly.
dnsPolicy: ClusterFirst

# Optional. Hyperglance ships with a self signed default ssl keypair. Replace these with your own trusted certificates here.
httpdSSL:
  certificate: |
    -----BEGIN CERTIFICATE-----
    CERTIFICATE DATA HERE - NOTE THE YAML INDENTATION
    -----END CERTIFICATE-----
  key: |
    -----BEGIN PRIVATE KEY-----
    CERTIFICATE DATA HERE - NOTE THE YAML INDENTATION
    -----END PRIVATE KEY-----
```

Next, we need to apply the following Istio gateway and virtualservice files. Please amend as required for your set up.

```yaml
---
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: hyperglance-gw
  namespace: "hyperglance"
spec:
  selector:
    istio: ingressgateway
  servers:
  - hosts:
    - "hyperglance.example.com"
    port:
      name: http
      number: 80
      protocol: HTTP
    tls:
      httpsRedirect: true
  - hosts:
    - "hyperglance.example.com"
    port:
      name: https
      number: 443
      protocol: HTTPS
    tls:
      mode: PASSTHROUGH
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: hyperglance-vs
  namespace: "hyperglance"
spec:
  gateways:
  - hyperglance/hyperglance-gw
  hosts:
  - "hyperglance.example.com"
  tls:
  - match:
    - port: 443
      sniHosts:
      - "hyperglance.example.com"
    route:
    - destination:
        host: hyperglance-helm.hyperglance.svc.cluster.local
        port:
          number: 443

```
Please note, the default destination for the hyperglance pod, when running in the hyperglance namespace is hyperglance-helm.hyperglance.svc.cluster.local. Amend this if you have deployed hyperglance to another namespace.

## Terminate SSL With Istio
Terminating SSL with Istio requires your values.yaml to include the following options set correctly for your deployment, otherwise SAML may not work correctly.

```yaml
# Default is of type loadbalancer. Set to ClusterIP to prevent an additional load balancer being exposed.
service:
  type: ClusterIP

# The default policy for our marketplace images is "Default", but ClusterFirst is required for the istio sidecar to function correctly.
dnsPolicy: ClusterFirst

# This must be set to the fqdn of your hyperglance instance, including the scheme.
URL: 'https://hyperglance.example.com'
# This disable tls on the apache container

APACHE_DISABLE_HTTPS: true
```

Next, we need to create a secret of type tls within the cluster to store the tls certificate and key. That can be done by:

```bash
kubectl create -n istio-ingress secret tls apache-ssl \
  --key=path/to/key.key \
  --cert=path/to/cert.crt
```

Please note. Depending on your Istio installation method, the namespace for your istio-ingress pod may be different. The secret needs to be in the same namespace your ingress pod resides in.

You can skip this step if you already have a gateway defined that you wish to reuse.

With those options applied, you can then use the following Istio gateway and virtual service. Pleae amend as required for your own scenario. You may wish to remove the Gateway section if you are reusing and exising gateway.

```yaml
---
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: hyperglance-gw
  namespace: "hyperglance"
spec:
  selector:
    istio: ingressgateway
  servers:
  - hosts:
    - "hyperglance.example.com"
    port:
      name: http
      number: 80
      protocol: HTTP
    tls:
      httpsRedirect: true
  - hosts:
    - "hyperglance.example.com"
    port:
      name: https
      number: 443
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: apache-ssl
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: hyperglance-vs
  namespace: "hyperglance"
spec:
  gateways:
  - hyperglance/hyperglance-gw
  hosts:
  - "hyperglance.example.com"
  http:
  - match:
    - headers:
        ":authority":
          regex: "hyperglance.example.com"
    route:
    - destination:
        host: hyperglance-helm.hyperglance.svc.cluster.local
        port:
          number: 80
```

Please note, the default destination for the hyperglance pod, when running in the hyperglance namespace is `hyperglance-helm.hyperglance.svc.cluster.local`. Amend this if you have deployed hyperglance to another namespace.


# Single-Sign-On (SAML)

1. To enable SAML, you first need to generate some files. Within this repo, download the [mellon_create_metadata.sh](https://raw.githubusercontent.com/hyperglance/helm-chart/main/files/mellon_create_metadata.sh) script. A linux system is required to run the script.

2. Make the script executable
```bash
wget https://raw.githubusercontent.com/hyperglance/helm-chart/main/files/mellon_create_metadata.sh
chmod +x mellon_create_metadata.sh
```

3. Ensure you have ```openssl``` installed on your system

4. Run the script, and provide the `entity-id-uri` (nromally the url for your Hyperglance instance) and `saml-endpoint-url` (normally the url for your Hyperglance instance with /saml appended). 
```bash
./mellon_create_metadata.sh entity-id-uri saml-endpoing-url
```

5. The script will print out the ACS URL which will be: https://{ip-address-of-your-hyperglance}/saml/postResponse. Make sure that the IP address or DNS name used for SAML endpoint URL is one that your browser will use. SAML works using browser redirects!

6. Use the generated information to configure your idp with the information from the previous step. See our in depth documentation for further information.

- [How to enable SAML](https://support.hyperglance.com/knowledge/saml-support-in-hyperglance)
- [How to set up SSO with SAML for Azure AD](https://support.hyperglance.com/knowledge/setup-sso-with-saml-for-azure-ad)

7. You should now have 4 files.

- idp.xml
- sp.cert
- sp.key
- sp.xml

8. Update your values.yaml file with the contents of these file, and ensure ```saml.enabled` is set to true. Please note, yaml expects correct indentation. Below is a example of what the saml section of the values.yaml should look like. Use the # as an indicator of where to indent the values to. Where multiple lines are used, the entire block must be at the same indentation level.

```yaml
saml:
  enabled: true
  spXml: |
    # NOTE: Use the # as an indicator of where to indent your data to.
  idpXml: |
    # NOTE: Use the # as an indicator of where to indent your data to.
  spCert: |
    # NOTE: Use the # as an indicator of where to indent your data to.
  spKey: |
    # NOTE: Use the # as an indicator of where to indent your data to.
```

9. Apply the updated values.yaml

```bash
helm upgrade hyperglance hyperglance/hyperglance-helm -n hyperglance -f values.yaml
```

Alternatively, you can use the ```--set-file``` option with the helm command to pass in your files instead of using the values.yaml.

```bash
helm upgrade hyperglance hyperglance/hyperglance-helm -n hyperglance -f values.yaml \
--set saml.enabled=true \
--set-file saml.spXml=sp.xml \
--set-file saml.idpXml=idp.xml \
--set-file saml.spCert=sp.cert \
--set-file saml.spKey=sp.key
```

For further information and troubleshooting tips, please see the guide [here](https://support.hyperglance.com/knowledge/saml-support-in-hyperglance).

# Using Existing Secrets

The helm chart has support for using manually created secrets. You may use the `.Values.<PARAMETER>.existingSecretName` parameter to pass the name of a secret to use.

The chart expects these secrets to be provided in a particular format. Please see `hyperglance/templates/secret.yaml` for expected layout. Use of `existingSecretname` takes precedence over other values if set.

Below is an example yaml you can use to apply your secrets separately from the main values.yaml. This can be applied by by running `kubectl apply -f secret.yaml -n <namespace>`. 

Please note, secrets must be in the same namespace as the deployment.

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: "custom-httpd-ssl"
stringData:
  hyperglance.crt: |
    -----BEGIN CERTIFICATE-----
    -----END CERTIFICATE-----

  hyperglance.key: |
    -----BEGIN RSA PRIVATE KEY-----
    -----END RSA PRIVATE KEY-----

---
apiVersion: v1
kind: Secret
metadata:
  name: "custom-httpd-saml"
stringData:
  idp.xml: |
    <?xml version="1.0" encoding="utf-8"?><EntityDescriptor ID=""
  sp.xml: |
    <EntityDescriptor entityID=""
    </EntityDescriptor>
  sp.cert: |
    -----BEGIN CERTIFICATE-----
    -----END CERTIFICATE-----  
  sp.key: |
    -----BEGIN PRIVATE KEY-----
    -----END PRIVATE KEY-----  
---
apiVersion: v1
kind: Secret
metadata:
  name: "custom-postgresql-db-settings"
stringData:
  POSTGRESQL_HOST: ""
  POSTGRESQL_PORT: ""
  POSTGRESQL_USERNAME: ""
  POSTGRESQL_PASSWORD: ""
---
apiVersion: v1
kind: Secret
metadata:
  name: "custom-proxy-settings"
stringData:
  PROXY_HOST: ""
  PROXY_PORT: ""
  PROXY_USER: ""
  PROXY_PASSWORD: ""
```