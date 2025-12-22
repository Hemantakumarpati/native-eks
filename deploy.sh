#!/bin/bash
# Usage: ./deploy.sh <bucket-name> <stack-name> <github-connection-arn> <github-repo>

BUCKET_NAME=$1
STACK_NAME=$2
CONNECTION_ARN=$3
REPO=$4

if [ -z "$BUCKET_NAME" ] || [ -z "$STACK_NAME" ]; then
    echo "Usage: ./deploy.sh <s3-bucket-name> <stack-name> <github-connection-arn> <github-repo>"
    exit 1
fi

echo "Uploading templates to S3..."
aws s3 cp templates/ s3://$BUCKET_NAME/eks-demo/templates/ --recursive

echo "Deploying Master Stack..."
aws cloudformation create-stack \
    --stack-name $STACK_NAME \
    --template-body file://templates/master.yaml \
    --parameters \
        ParameterKey=GitHubConnectionArn,ParameterValue=$CONNECTION_ARN \
        ParameterKey=GitHubRepo,ParameterValue=$REPO \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND

echo "Waiting for stack creation..."
aws cloudformation wait stack-create-complete --stack-name $STACK_NAME
echo "Deployment Finished!"
