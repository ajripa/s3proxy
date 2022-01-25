# Creates ECR Repository where the s3proxy-api container will be stored.

resource "aws_ecr_repository" "s3proxy" {
  name                 = var.docker_image_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

}



