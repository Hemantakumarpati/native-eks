# Production EKS Cluster Implementation Plan

This plan outlines the creation of a production-ready EKS cluster using modular CloudFormation templates. The architecture follows AWS best practices for high availability, security, and scalability.

## User Review Required

> [!IMPORTANT]
> **GitHub Actions Security**: We will use **AWS IAM OpenID Connect (OIDC)** as the security provider. This is the best practice for GitHub Actions because it uses short-lived tokens and eliminates the need for long-lived IAM Access Keys/Secrets.

> [!IMPORTANT]
> **Demo Optimization**: To balance cost and performance for the demo, we will use **1 NAT Gateway** (instead of 3) and **1 Managed Worker Node**. The EKS Control Plane remains highly available as it is managed by AWS.

> [!NOTE]
> This setup uses Managed Node Groups for simplified maintenance. If you require specialized compute (like Graviton or Spot), let me know.

## Proposed Changes

The infrastructure will be modularized using nested stacks to ensure components can be managed independently.

---

### [Component] Networking (VPC)
#### [NEW] [vpc.yaml](file:///c:/Users/heman/learning/aws/native-eks/templates/vpc.yaml)
- Create a VPC with 10.0.0.0/16 CIDR.
- 3 Public Subnets (for ALBs/IGW).
- 3 Private Subnets (for EKS Nodes/Workloads).
- **1 NAT Gateway** (for cost-efficiency during demo).
- VPC Endpoints for S3, ECR, and Logging (optional but recommended for private clusters).

---

### [Component] IAM & Security
#### [NEW] [iam.yaml](file:///c:/Users/heman/learning/aws/native-eks/templates/iam.yaml)
- Cluster Role: Permissions for EKS to manage AWS resources.
- Node Group Role: Permissions for nodes to pull images from ECR, log to CloudWatch, and join the cluster.
- **GitHub Actions OIDC Role**: A role that GitHub Actions can assume using OIDC to deploy the CloudFormation stacks.
- **OIDC Identity Provider**: Resource to trust GitHub as a federated identity provider.
- EKS Pod Identity / IRSA setup.

#### [NEW] [security-groups.yaml](file:///c:/Users/heman/learning/aws/native-eks/templates/security-groups.yaml)
- Security groups for Cluster Control Plane and Node Groups.

---

### [Component] EKS Control Plane
#### [NEW] [eks-cluster.yaml](file:///c:/Users/heman/learning/aws/native-eks/templates/eks-cluster.yaml)
- EKS Cluster resource.
- Logging (API, Audit, Authenticator, ControllerManager, Scheduler) enabled.
- OIDC Identity Provider for IAM Roles for Service Accounts (IRSA).

---

### [Component] Compute (Node Groups)
#### [NEW] [node-group.yaml](file:///c:/Users/heman/learning/aws/native-eks/templates/node-group.yaml)
- Managed Node Group with **1 worker node**.
- Instance type: `t3.medium` (Cost-effective for demo).
- Auto-scaling set to Desired: 1, Min: 1, Max: 2.
- Disk encryption (EBS).

---

### [Component] CI/CD Pipelines (Decoupled Architecture)

#### 1. Infrastructure Pipeline ([NEW] [.github/workflows/deploy-infra.yml](file:///c:/Users/heman/learning/aws/native-eks/.github/workflows/deploy-infra.yml))
- **Trigger**: Pushes to `main` branch affecting `templates/`.
- **Security**: AWS OIDC for GitHub Actions.
- **Process**: Validates and deploys the `master.yaml` CloudFormation stack to provision VPC, IAM, and EKS Cluster.

#### 2. Application Pipeline ([NEW] [cicd-app-pipeline.yaml](file:///c:/Users/heman/learning/aws/native-eks/templates/cicd-app-pipeline.yaml))
- **Trigger**: Automatic on source code change in `java-app/`.
- **AWS CodeBuild**:
    - **Phase 1**: Compile Java code using **Maven** (`mvn clean package`).
    - **Phase 2**: Build Docker image and push to ECR.
    - **Phase 3**: Deploy to EKS using `kubectl`.
- **HA Strategy**:
    - **Replicas**: Managed by **Horizontal Pod Autoscaler (HPA)**.
    - **Distribution**: **Pod Anti-Affinity** to ensure replicas are scheduled across different nodes/AZs.
    - **Health**: Liveness and Readiness probes configured for Spring Boot Actuator endpoints.

---

### [Component] Orchestration & Deployment
#### [NEW] [master.yaml](file:///c:/Users/heman/learning/aws/native-eks/templates/master.yaml)
- Root stack to deploy VPC, IAM, EKS, Node Groups, and CI/CD Pipeline.

#### [NEW] [walkthrough.md](file:///C:/Users/heman/.gemini/antigravity/brain/e564411b-bd8d-4ecb-815d-7ea531b62ad2/walkthrough.md)
- Comprehensive guide for the customer demo.
- Detailed answers to technical architecture and security questionnaires.

#### [NEW] [deploy.sh](file:///c:/Users/heman/learning/aws/native-eks/deploy.sh)
- Script to upload templates to S3 (required for nested stacks) and execute `aws cloudformation create-stack`.

## Verification Plan

### Automated Verification
- **CloudFormation Linting**: Run `cfn-lint` on all templates.
- **Dry Run**: Use `aws cloudformation validate-template`.

### Manual Verification
1. Deploy the master stack.
2. Verify AWS Console for EKS Cluster "Active" status.
3. Use `aws eks update-kubeconfig --name <cluster-name>` to connect.
4. Run `kubectl get nodes` to verify nodes are ready.
5. Verify OIDC provider is created and working.
