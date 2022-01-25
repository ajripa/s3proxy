#/bin/sh
# First argument is s3 bucket name
# Second argument is the role to be assumed

echo $1
echo $2

# Assume role and set credentials
output=$(aws sts assume-role --role-arn $2 --role-session-name awscli-session)
AccessKeyId=$(echo $output | jq -r '.Credentials''.AccessKeyId')
SecretAccessKey=$(echo $output | jq -r '.Credentials''.SecretAccessKey')
SessionToken=$(echo $output | jq -r '.Credentials''.SessionToken')
export AWS_ACCESS_KEY_ID=$AccessKeyId
export AWS_SECRET_ACCESS_KEY=$SecretAccessKey
export AWS_SESSION_TOKEN=$SessionToken

# Upload container to ECR Repo
aws s3 cp ./ s3://$1 --recursive --include "*.jpg" --exclude "*.sh"

#Unset credentials
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN