GitHub Actions
   │
   │  OIDC Token (JWT)
   ▼
AWS IAM OIDC Provider (token.actions.githubusercontent.com)
   │
   ▼
IAM Role (Trust Policy)
   │
   ▼
AWS STS → Temporary Credentials

STEP 1️⃣ Create OIDC Identity Provider (One-Time)
🔹 AWS Console Steps

Open AWS Console

Go to IAM → Identity providers

Click Add provider

🔹 Fill Details
Field	Value
Provider type	OpenID Connect
Provider URL	https://token.actions.githubusercontent.com
Audience	sts.amazonaws.com

Click Add provider

✅ Done (this is global for the account)

STEP 2️⃣ Create IAM Role for GitHub Actions
🔹 AWS Console Steps

Go to IAM → Roles

Click Create role

Select Web identity

Identity provider → token.actions.githubusercontent.com

Audience → sts.amazonaws.com

Click Next

STEP 3️⃣ Configure Trust Policy (VERY IMPORTANT)

When prompted, edit the trust policy and replace it with this:

Trust Policy (Branch-restricted)
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:ORG_NAME/REPO_NAME:ref:refs/heads/main"
        }
      }
    }
  ]
}


🔁 Replace:

<ACCOUNT_ID> → your AWS account ID

ORG_NAME → GitHub org or username

REPO_NAME → GitHub repo

main → branch name (if needed)

 Allow all branches (optional):

"repo:ORG_NAME/REPO_NAME:*"


Click Next

STEP 4️⃣ Attach Permissions Policy
Example: S3 + CloudFormation access

Click Create policy

Choose JSON

Paste:

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*",
        "cloudformation:*"
      ],
      "Resource": "*"
    }
  ]
}


Save policy

Attach it to the role

STEP 5️⃣ Name & Create Role

Role name:
github-actions-deploy-role

Create role

📌 Copy the Role ARN, you will need it

STEP 6️⃣ Configure GitHub Actions Workflow
🔹 Create Workflow File

In your GitHub repo:

.github/workflows/deploy.yml

🔹 GitHub Actions YAML (Minimal Working Example)
name: AWS OIDC Test

on:
  push:
    branches:
      - main

permissions:
  id-token: write
  contents: read

jobs:
  aws-test:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repo
        uses: actions/checkout@v4

      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::<ACCOUNT_ID>:role/github-actions-deploy-role
          aws-region: us-west-2

      - name: Verify AWS identity
        run: aws sts get-caller-identity


🔁 Replace:

<ACCOUNT_ID>

Region if needed

STEP 7️⃣ Push Code & Verify

Commit & push to main

Go to GitHub → Actions

Open the workflow

You should see:

{
  "Account": "<ACCOUNT_ID>",
  "Arn": "arn:aws:sts::<ACCOUNT_ID>:assumed-role/github-actions-deploy-role/..."
}


✅ OIDC is working!

STEP 8️⃣ Remove AWS Secrets (If Any)

In GitHub repo:

Settings → Secrets

❌ Delete:

AWS_ACCESS_KEY_ID

AWS_SECRET_ACCESS_KEY

You do NOT need them anymore

STEP 9️⃣ Production Best Practices (Strongly Recommended)
🔐 Use GitHub Environments

Trust Policy (prod only):

"repo:ORG/REPO:environment:prod"

🧱 Separate Roles per Environment
Env	Role
dev	github-actions-dev
test	github-actions-test
prod	github-actions-prod
🔑 Least Privilege

Avoid Resource: "*" in prod

🛠 Common Errors & Fixes
Error	Fix
No OpenID provider found	Create OIDC provider
AccessDenied AssumeRole	Check repo/branch in trust policy
InvalidIdentityToken	Missing id-token: write
Works locally but not in CI	Remove AWS keys
