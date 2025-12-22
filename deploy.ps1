# Usage: .\deploy.ps1 -BucketName <bucket-name> -StackName <stack-name> -ConnectionArn <arn> -Repo <user/repo>

param (
    [Parameter(Mandatory=$true)]
    [string]$BucketName,

    [Parameter(Mandatory=$true)]
    [string]$StackName,

    [Parameter(Mandatory=$true)]
    [string]$ConnectionArn,

    [Parameter(Mandatory=$true)]
    [string]$Repo
)

Write-Host "Packaging CloudFormation templates..."
aws cloudformation package `
    --template-file templates/master.yaml `
    --s3-bucket $BucketName `
    --output-template-file packaged.yaml

if ($LASTEXITCODE -ne 0) {
    Write-Error "Packaging failed!"
    exit 1
}

Write-Host "Deploying Master Stack..."
aws cloudformation deploy `
    --template-file packaged.yaml `
    --stack-name $StackName `
    --parameter-overrides GitHubConnectionArn=$ConnectionArn GitHubRepo=$Repo `
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND

if ($LASTEXITCODE -ne 0) {
    Write-Error "Deployment failed!"
    exit 1
}

Write-Host "Deployment Finished!"
