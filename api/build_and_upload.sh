#!/bin/bash
set -euo pipefail

# First argument is the container name
# Second argument is the repo name
# Third argument is the role to be assumed
# Fourth argument is the timestamp
# Fifth argument (optional) is the AWS region

CONTAINER_NAME="${1:?Container name is required}"
REPO_NAME="${2:?Repository name is required}"
ROLE_ARN="${3:?Role ARN is required}"
TIMESTAMP="${4:?Timestamp is required}"
AWS_REGION="${5:-eu-west-1}"

echo "Building container: ${CONTAINER_NAME}"
echo "Repository: ${REPO_NAME}"
echo "Role: ${ROLE_ARN}"
echo "Timestamp: ${TIMESTAMP}"
echo "Region: ${AWS_REGION}"

# Build container
docker build --platform linux/amd64 -t "${CONTAINER_NAME}:${TIMESTAMP}" .

# Assume role and set credentials
output=$(aws sts assume-role --role-arn "${ROLE_ARN}" --role-session-name awscli-session)
export AWS_ACCESS_KEY_ID=$(echo "${output}" | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo "${output}" | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo "${output}" | jq -r '.Credentials.SessionToken')

# Upload container to ECR Repo
aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${REPO_NAME}"
docker tag "${CONTAINER_NAME}:${TIMESTAMP}" "${REPO_NAME}/${CONTAINER_NAME}:${TIMESTAMP}"
docker push "${REPO_NAME}/${CONTAINER_NAME}:${TIMESTAMP}"

# Unset credentials
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN

echo "Successfully pushed ${REPO_NAME}/${CONTAINER_NAME}:${TIMESTAMP}"
