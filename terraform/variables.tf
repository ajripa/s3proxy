### AWS Config ### 
variable "aws_region" {
    type = string
    description = "AWS Region"
}

variable "aws_role" {
    type = string
    description = "AWS Role to be assumed"
}

### S3 ###
variable "s3_bucket_prefix" {
    type = string
    description = "S3 bucket prefix"
}

### S3Proxy Hostname ###
variable "s3proxy_hostname" {
    type = string
    description = "S3 proxy hostname for ingress"
}

### EKS ###
variable "eks_namespace" {
    type = string
    description = "EKS namespace to be used"
}

variable "eks_service_account_name" {
    type = string
    description = "EKS service account name"
}

### Docker ###
variable "docker_image_name" {
    type = string
    description = "Docker image name"
}

### HTTP Basic auth ###
variable "http_auth_user" {
    type        = string
    description = "HTTP user name"
    sensitive   = true
}

variable "http_auth_pass" {
    type        = string
    description = "HTTP user pass"
    sensitive   = true
}

### Tags ###

variable "tags" {
    type = map
    description = "Project tags"
}