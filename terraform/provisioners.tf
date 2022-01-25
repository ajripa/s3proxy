# Build and upload container to ECR

resource "null_resource" "build_and_upload" {
  triggers = {
        build_number = local.timestamp
    }
  
  provisioner "local-exec" {
    working_dir = "../api"
    command = "sh build_and_upload.sh ${var.docker_image_name} ${element(split("/",aws_ecr_repository.s3proxy.repository_url),0)} ${var.aws_role} ${local.timestamp}"
  }

  depends_on = [aws_ecr_repository.s3proxy]
}

# Populate S3
resource "null_resource" "populate_s3" {

  provisioner "local-exec" {
    working_dir = "../stuff"
    command = "sh populate_s3.sh ${aws_s3_bucket.bucket.id} ${var.aws_role}"
  }

  depends_on = [aws_s3_bucket.bucket]
}
