# S3 Proxy project

The Engineering Productivity team would like to expose the contents of an S3 bucket through a Kubernetes Ingress resource. Some internal pipelines push content to specific private s3 buckets, which in turn we want to reach via our Kubernetes Ingress endpoint(s)

# Requirements

- Terraform to deploy the needed resources
- Docker to containerize the workloas
- Helm to create the kubernetes manifests
- AWS CLI to populate S3 buckets and get access to ECR repositories

# Assumptions and trade-offs

- A client credentials and a role with the minimum permission needed to deploy the resources and to access to K8S cluster has been provided by our administrator.
- The EKS cluster was deployed using Terraform. Access to an S3 bucket where the terraform state of the cluster is stored has been provided by our administrator. Our terraform template will use the state to read the required information about the cluster.
- An NGINX ingress controller is installed in the cluster.
- Self-signed SSL certificates are used. 
- The flask application will only accept GET requests.
- S3 keys are equal to HTTP requests path.
- Basic-auth is used to access the ingress.

# Solution

A flask application translates HTTP requests into S3 object keys, retrieve them from the bucket and response back to the client. The flask app runs containerized, listening on port 5000. The port is exposed using and nginx ingress in K8S.

A couple of endpoints are exposed by the app:

- /health: it is used by K8S to check the status of the pod.
- /: catch-all endpoint. Using Boto3 library, a s3 client is created and get the object which key is equal to the path. A response to the client with the object is sent back.

An environment variable with the name of the bucket (S3_BUCKET) is required by the app.

# Resources

All required resources are deployed using Terraform:

- S3 bucket.
- IAM Policy with that allows access to the bucket.
- IAM rol assumable by our pod with the previous policy attached.
- ECR repository.
- Provisioner to populate the S3 bucket.
- Provisioner to build the container image and upload it to ECR
- Helm provider to install our app in the cluster.

# Helm charts

The application is installed in our Kubernetes cluster using a Helm chart. Heml is a powerful tool to create Kubernetes manifests as template.

A Helm chart has been created in "chart" folder and the values for our app (ingress config, image name, tags, enviroment variables and secrets) are defined in terraform.

# Installation

First of all we need to install the terraform modules required:

```bash
cd terraform
terraform init
```
Once the modules are installed, we need to create a tfvars file to customize the solution:

```bash
aws_region = "eu-west-1"
aws_role = "arn:aws:iam::<aws-account-number>:role/<role-name>"
s3_bucket_prefix = "s3proxy-bucket"
s3proxy_hostname = "s3proxy.dummy.local"
eks_namespace = "s3proxy"
eks_service_account_name = "s3proxy"
docker_image_name = "s3proxy-api"
http_auth_user = "s3proxy"
http_auth_pass = "s3proxypass"

tags = {
    CostCenter = "Automation"
    Project    = "S3Proxy"
    Terraform  = "True"
}
```

Run terraform plan to review the changes that terraform will apply:

```bash
terraform plan --var-file=vars.tfvars
````

If we are happy with the changes, we can apply them:

```bash
terraform apply --var-file=vars.tfvars
```

## Usage

One of the outputs of terraform is an example URL:

```bash
app_url_example = "https://s3proxy.dummy.local/1.jpg"
```

We can change the path to get access to different assets.
