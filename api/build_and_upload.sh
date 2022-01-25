#/bin/sh
# First argument is the container name
# Second argument is the repo name
# Third argument is the role to be assumed
# Fourth argument is the timestamp
echo $1
echo $2
echo $3
echo $4


# Build container
docker build --platform linux/amd64 -t $1:$4 .

# Assume role and set credentials
output=$(aws sts assume-role --role-arn $3 --role-session-name awscli-session)
AccessKeyId=$(echo $output | jq -r '.Credentials''.AccessKeyId')
SecretAccessKey=$(echo $output | jq -r '.Credentials''.SecretAccessKey')
SessionToken=$(echo $output | jq -r '.Credentials''.SessionToken')
export AWS_ACCESS_KEY_ID=$AccessKeyId
export AWS_SECRET_ACCESS_KEY=$SecretAccessKey
export AWS_SESSION_TOKEN=$SessionToken

# Upload container to ECR Repo
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin $2
docker tag $1:$4 $2/$1:$4
docker push $2/$1:$4

#Unset credentials
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN