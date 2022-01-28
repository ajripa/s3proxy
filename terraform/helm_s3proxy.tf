# Helm is used to deploy our application.
# The app requires access to the S3 bucket where de assets are stored.
# To avoid using AWS Credentials, we leverage IRSA. An IAM role is created and attached to the pod.
# To avoid anonymous access to the ingress, basic-auth is enabled. Credentials are stored using K8S secrets.
# OIDC approach is a far better solution

# IAM Role
module "iam_assumable_s3_proxy_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "3.6.0"

  create_role                   = true
  role_name                     = "s3proxy-role"
  provider_url                  = replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")
  role_policy_arns              = [aws_iam_policy.s3proxy_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${var.eks_namespace}:${var.eks_service_account_name}"]

  tags = var.tags
}


# IAM Policy for S3Proxy

resource "aws_iam_policy" "s3proxy_policy" {
  name_prefix = "s3proxy"
  description = "Allow access to S3Proxy bucket"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "s3:*",
            "Effect": "Allow",
            "Resource": [
                "${aws_s3_bucket.bucket.arn}",
                "${aws_s3_bucket.bucket.arn}/*"
            ]
        }
    ]
}
EOF

    tags = var.tags
}

### Install s3proxy using helm

resource "helm_release" "s3proxy" {

  name             = "s3proxy"
  repository       = "../charts/"
  chart            = "s3proxy"
  namespace        = "s3proxy"
  create_namespace = true
  atomic           = true
  timeout          = 300
  recreate_pods    = true

  values = [
    <<-EOF
    image:
        repository: ${aws_ecr_repository.s3proxy.repository_url}
        tag: "${local.timestamp}"
        pullPolicy: Always
    serviceAccount:
        create: true
        annotations:
            eks.amazonaws.com/role-arn: ${module.iam_assumable_s3_proxy_role.this_iam_role_arn}
        name: "${var.eks_service_account_name}"
    ingress:
        enabled: true
        className: ""
        annotations:
            kubernetes.io/ingress.class: nginx
            kubernetes.io/tls-acme: "true"
            nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
            nginx.ingress.kubernetes.io/auth-type: basic
            nginx.ingress.kubernetes.io/auth-secret: basic-auth
            nginx.ingress.kubernetes.io/auth-realm: "Authentication Required"
        hosts:
            - host: ${var.s3proxy_hostname}
              paths:
                - path: /
                  pathType: ImplementationSpecific
    
    healthcheck: /health

    http_auth:
        user: ${var.http_auth_user}
        password: ${var.http_auth_pass}

    env:
        S3_BUCKET: ${aws_s3_bucket.bucket.id}
    EOF
]

    depends_on = [null_resource.build_and_upload]
}