# Assume that K8S cluster has been deployed using terraform and its state is stored in S3. We use the remote state as data source.

data "terraform_remote_state" "eks" {
    backend= "s3" 
    config = {
        bucket = "ie-terraform-backend"
        key    = "env:/dev/operations/eks/terraform.tfstate"
        region = "eu-west-1"
    }
}