# Create S3 resource

resource "random_string" "random" {
  length = 8
  special = false
  upper = false
}

resource "aws_s3_bucket" "bucket" {
  bucket = "${var.s3_bucket_prefix}-${random_string.random.result}"
  acl    = "private"

  tags = var.tags
}
