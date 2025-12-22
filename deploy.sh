# Usage: ./deploy.sh <bucket-name> <stack-name> <github-connection-arn> <github-repo>

BUCKET_NAME=$1
STACK_NAME=$2
CONNECTION_ARN=$3
REPO=$4

if [ -z "$BUCKET_NAME" ] || [ -z "$STACK_NAME" ] || [ -z "$CONNECTION_ARN" ] || [ -z "$REPO" ]; then
    echo "Usage: ./deploy.sh <s3-bucket-name> <stack-name> <github-connection-arn> <github-repo>"
    exit 1
fi

echo "Packaging CloudFormation templates..."
aws cloudformation package \
    --template-file templates/master.yaml \
    --s3-bucket $BUCKET_NAME \
    --output-template-file packaged.yaml

if [ $? -ne 0 ]; then
    echo "Packaging failed!"
    exit 1
fi

echo "Deploying Master Stack..."
aws cloudformation deploy \
    --template-file packaged.yaml \
    --stack-name $STACK_NAME \
    --parameter-overrides GitHubConnectionArn=$CONNECTION_ARN GitHubRepo=$REPO \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND

echo "Deployment Finished!"
