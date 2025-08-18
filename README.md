# DevOps Take‑Home (Interview Submission)

This repository implements a production‑style, cost‑aware deployment using **AWS + Terraform + Docker + Auto Scaling Group + Application Load Balancer**, with **CI/CD via GitHub Actions**, **monitoring/logging in CloudWatch**, and a simple **hello‑world Node.js** service.

---

## 1) System Architecture

- **Compute**: EC2 instances in an **Auto Scaling Group (ASG)** run the containerized app (Docker).
- **Registry**: Images are stored in **Amazon ECR**.
- **Load Balancer**: **ALB** forwards traffic to healthy instances via a Target Group.
- **CI/CD**: **GitHub Actions** builds/pushes images to ECR, updates the **SSM image tag**, then triggers an **ASG Instance Refresh** for zero‑downtime rollout.
- **Observability**: **CloudWatch Logs** for container logs, **CloudWatch Alarms** (CPU, ALB 5XX). Alerts go to **SNS**.
- **Security**: CI assumes an IAM role using **GitHub OIDC** (no long‑lived AWS keys).

### Mermaid Diagram
```mermaid
flowchart LR
  subgraph AWS[VPC (2 AZs)]
    ALB[Application Load Balancer] --> TG[Target Group]
    subgraph AZ1
      EC2a[EC2 in ASG]
    end
    subgraph AZ2
      EC2b[EC2 in ASG]
    end
  end

  Dev[GitHub Actions CI/CD] -->|OIDC AssumeRole| AWS
  Dev -->|Push image| ECR[ECR Repository]
  EC2a -->|pull & run| ECR
  EC2b -->|pull & run| ECR
  EC2a -->|logs/metrics| CW[CloudWatch]
  EC2b -->|logs/metrics| CW
  CW -->|alarms| SNS[SNS Alerts]
```

## 2) Tradeoffs & Decisions

- **EKS vs EC2+Docker**: EC2+Docker avoids per‑cluster control plane costs while meeting LB/HA requirements; simpler for a take‑home.
- **Zero‑downtime rollouts**: **ASG Instance Refresh** is reliable and native; can extend to Blue/Green with two target groups if required.
- **Secrets**: Uses **SSM Parameter Store** by default (no extra cost). Can switch to Secrets Manager if rotation/auditing needed.
- **TLS**: Optional ACM certificate supported; HTTP→HTTPS redirect when configured.
- **Public subnets** (for simplicity/cost). Production can move to private subnets + NAT if desired.

---

## 3) Deliverables Checklist (included)

- ✅ **README.md**: architecture, deploy steps, checks (logs/alerts/monitoring)
- ✅ **Infrastructure code (Terraform)**: `terraform/`
- ✅ **CI/CD config**: `.github/workflows/cicd.yml`
- ✅ **Dockerfile** at repo root
- ✅ **Docker Compose** (`docker-compose.yml`) for local run
- ✅ **Diagrams**: Mermaid (above)
- ✅ **Replication instructions**: below

---

## 4) How to Deploy (Step‑by‑Step)

### Prereqs
- AWS account with privileges to create VPC/ALB/ASG/ECR/SSM/IAM/SNS.
- Installed: **Terraform**, **AWS CLI**, **Docker**.

### Provision infrastructure
```bash
cd terraform
# edit terraform.tfvars as needed (project_name, region, etc.)
terraform init
terraform apply -auto-approve
```
Record outputs: **ALB DNS**, **ECR repo**, **ASG name**, **GitHub OIDC role ARN**.

### Configure GitHub Actions
In your GitHub repo > Settings > Secrets and variables > Actions > **Variables**:
- `AWS_ACCOUNT_ID`
- `AWS_REGION`
- `ECR_REPOSITORY`  (value from Terraform output)
- `IAM_ROLE_ARN`    (GitHub OIDC deploy role from Terraform output)
- `SSM_IMAGE_TAG_PARAM` = `/hello-app/image_tag`

### CI/CD deploy
Push to `main`:
- Build image → Push to ECR → Update SSM image tag → **ASG Instance Refresh**.
- After rollout, open the **ALB DNS**. You should see: **“Hello from Node.js!”**

### (Optional) HTTPS
- Request an ACM certificate and set `acm_certificate_arn` in `terraform.tfvars`.
- `terraform apply` to add HTTPS listener and 80→443 redirect.

### Tear down (to avoid charges)
```bash
cd terraform
terraform destroy -auto-approve
```

---

## 5) How to Check Alerting & Monitoring

- **Logs**: CloudWatch Logs group `/<project_name>/app` (container stdout/stderr).
- **Alarms**: CloudWatch Alarms:
  - `<project_name>-HighCPU` (EC2 CPUUtilization)
  - `<project_name>-ALB-5XX` (ALB 5xx count)
- **Notifications**: Subscribe email or webhook to the SNS topic `<project_name>-alerts`.

---

## 6) Local Run (Optional)

```bash
docker compose up --build
# open http://localhost:3000
```

---

## 7) Repo Layout

```
.
├─ app/                     # hello‑world Node.js
│  ├─ package.json
│  └─ server.js
├─ Dockerfile
├─ docker-compose.yml
├─ terraform/               # IaC: VPC, ALB, ASG, ECR, IAM, SSM, CloudWatch, SNS
├─ .github/workflows/cicd.yml

```
