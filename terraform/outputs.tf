output "image" {
    value = "${var.docker_image_name}:${local.timestamp}"
}
output "s3_bucket_arn" {
    value = aws_s3_bucket.bucket.arn
}

output "erc_repository_url" {
    value = aws_ecr_repository.s3proxy.repository_url
}

output "app_url_example" {
    value = "https://${var.s3proxy_hostname}/1.jpg"
}