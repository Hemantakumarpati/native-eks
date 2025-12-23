Step 1: Prerequisites (Manual Setup)
You need two things that cannot be created by the script:

S3 Bucket for Artifacts:
This stores your CloudFormation templates.
Action: Create a bucket (e.g., eks-demo-artifacts).
Command if needed: aws s3 mb s3://eks-demo-artifacts-heman
GitHub Connection (AWS Console):
This allows AWS CodePipeline to talk to your GitHub repo.
Action:
Go to AWS Console > Developer Tools > Settings > Connections.
The easiest way to find it is to search for CodePipeline explicitly, because "Developer Tools" isn't a single clickable service icon.

Search: In the top search bar of the AWS Console, type CodePipeline.
Click: Select CodePipeline from the results.
Sidebar: Look at the menu on the left side.
Scroll Down: Go to the very bottom of that menu.
Expand: You will see a section called Settings.
Click: Connections.
Click Create connection.
Select GitHub, give it a name (e.g., MyGitHubConnection), and click Connect.
Important: Complete the "Install a new app" handshake inside the popup.
Copy the Connection ARN (it looks like arn:aws:codestar-connections:us-east-1:123456789012:connection/abcd-1234...).
Step 2: Run the Deployment Script
Once you have the Bucket Name and Connection ARN, run this command in your terminal (PowerShell).

Replace the placeholders structure <...> with your actual values:

powershell
.\deploy.ps1 `
  -BucketName <YOUR_UNIQUE_BUCKET_NAME> `
  -StackName eks-native-demo `
  -ConnectionArn <YOUR_CONNECTION_ARN> `
  -Repo <YOUR_GITHUB_USERNAME>/<YOUR_REPO_NAME>
Example Command:

powershell
.\deploy.ps1 `
  -BucketName eks-demo-artifacts-heman `
  -StackName eks-native-demo `
  -ConnectionArn arn:aws:codestar-connections:us-east-1:123456789012:connection/a1b2c3d4-5678 `
  -Repo hemantakumarpati/native-eks
What happens next?
Packaging: The script uploads your local templates to your S3 bucket.
Deployment: It triggers CloudFormation to create the eks-native-demo stack.
Wait Time: It will take ~20-25 minutes for the EKS Cluster and Node Group to fully provision.


AWS_ROLE_ARN
S3_BUCKET
GITHUB_CONNECTION_ARN


That is exactly why we have the deploy.sh script!

You do not need to create the role manually. The deploy.sh script does it for you.

The CloudFormation templates I created (iam.yaml) contain the definition for GitHubActionsRole. When you run the deploy script, it will:

Read the templates.
Create the GitHubActionsRole in your AWS account.
Create the EKS Cluster and other resources.
Action Plan: Please run this command in your VS Code terminal (Git Bash or PowerShell). This single command will set up everything, including the Role you need.

powershell
./deploy.sh <YOUR_S3_BUCKET> eks-prod-stack <YOUR_CONNECTION_ARN> <GITHUB_USER>/<REPO>
Example:

powershell
./deploy.sh my-eks-bucket eks-prod-stack arn:aws:codestar-connections:us-east-1:xxx:connection/xxx heman/native-eks
Once this finishes (it will take ~15 mins), the Role will exist, and I will show you how to get its ARN for GitHub Actions!



