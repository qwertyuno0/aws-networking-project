<div align="center">

# AWS Networking Project with Terraform

**A modular, self-healing, low-cost AWS web tier: custom VPC, bastion host, Application Load Balancer, Auto Scaling in private subnets, CloudWatch monitoring and SNS alerts, delivered through a GitHub Actions CI/CD pipeline.**

![Terraform](https://img.shields.io/badge/Terraform-%3E%3D%201.11-7B42BC?logo=terraform&logoColor=white)
![AWS Provider](https://img.shields.io/badge/AWS%20Provider-~%3E%206.0-FF9900?logo=amazonaws&logoColor=white)
![Region](<https://img.shields.io/badge/Region-ap--south--1%20(Mumbai)-232F3E?logo=amazonaws&logoColor=white>)
![State](https://img.shields.io/badge/Remote%20State-S3%20%2B%20native%20locking-3F8624)
![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=githubactions&logoColor=white)
![Security](https://img.shields.io/badge/Security%20Scan-Trivy-1904DA?logo=aqua&logoColor=white)
![Cost](https://img.shields.io/badge/NAT%20Gateway-none-success)

[Architecture](#architecture) · [Quick start](#quick-start) · [CI/CD pipeline](#cicd-pipeline) · [Verify](#verify-it-works) · [Self-healing demo](#self-healing-demo) · [Monitoring](#monitoring-and-alerts) · [Troubleshooting](#troubleshooting-log)

</div>

<p align="center">
  <img src="docs/images/00-architecture-hero.png" alt="Architecture overview" width="850">
</p>

---

## Overview

Everything in this project is built with Terraform: a custom VPC, a bastion host, an Application Load Balancer in front of an Auto Scaling group in **private** subnets, CloudWatch monitoring with email alerts, and remote state in S3.

Changes are delivered through a **GitHub Actions pipeline** that signs in to AWS with short-lived OIDC credentials: every pull request is checked and planned, and only a merge to `main` followed by a manual approval can change AWS.

It is designed to stay cheap. There is **no NAT Gateway**: the private servers install their software from an internal package repository hosted on the bastion.

### Highlights

|                                |                                                                                                                                         |
| ------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------- |
| 🔒 **Private by default**      | App servers have no public IP and no route to the internet                                                                              |
| 🩺 **Self-healing**            | ALB health checks drive the Auto Scaling group, so unhealthy instances are replaced automatically                                       |
| 📬 **Observable**              | 5 CloudWatch alarms, a 6-widget dashboard and SNS email alerts for alarms and for every launch or terminate event                       |
| 🚀 **Automated delivery**      | GitHub Actions runs checks, a Trivy report and `terraform plan` on every PR, and applies the saved plan on merge to `main` behind a manual approval gate |
| 🔑 **No stored AWS keys**      | The pipeline assumes an IAM role through GitHub OIDC and gets short-lived credentials for each run                                      |
| 💸 **Low cost**                | No NAT Gateway: an internal APT repository on the bastion replaces it                                                                   |
| 🧱 **Modular**                 | 8 reusable modules, wired together in a single `environment/dev` root module                                                            |
| 🗄️ **Safe state**              | S3 remote state with versioning, encryption and native lock file (no DynamoDB)                                                          |

### Preview

<table>
  <tr>
    <td align="center"><img src="docs/images/02-alb-server-1.png" alt="Load balanced page" width="280"><br><sub>Load balancing</sub></td>
    <td align="center"><img src="docs/images/08-asg-activity-history.png" alt="ASG self-healing" width="280"><br><sub>Self-healing</sub></td>
    <td align="center"><img src="docs/images/20-pipeline-apply-success.png" alt="CI/CD pipeline run" width="280"><br><sub>CI/CD pipeline</sub></td>
    <td align="center"><img src="docs/images/12-cloudwatch-dashboard.png" alt="CloudWatch dashboard" width="280"><br><sub>Monitoring</sub></td>
  </tr>
</table>

---

## Table of contents

- [Architecture](#architecture)
- [What it deploys](#what-it-deploys)
- [Key design decisions](#key-design-decisions)
- [Repository structure](#repository-structure)
- [Quick start](#quick-start)
- [CI/CD pipeline](#cicd-pipeline)
- [Verify it works](#verify-it-works)
- [Self-healing demo](#self-healing-demo)
- [Monitoring and alerts](#monitoring-and-alerts)
- [Troubleshooting log](#troubleshooting-log)
- [Cost](#cost)
- [Limitations and next steps](#limitations-and-next-steps)
- [Clean up](#clean-up)
- [Author and acknowledgements](#author-and-acknowledgements)

---

## Architecture

```mermaid
flowchart TB
    users([Internet users])
    admin([Admin laptop])

    subgraph VPC["VPC 10.0.0.0/16 - ap-south-1"]
        subgraph PUB["Public subnets 10.0.1.0/24 and 10.0.2.0/24"]
            alb[Application Load Balancer]
            bastion["Bastion host + internal APT repo (nginx)"]
        end
        subgraph PRIV["Private subnets 10.0.11.0/24 and 10.0.12.0/24 - no NAT, no internet route"]
            app1["EC2 Apache - AZ a"]
            app2["EC2 Apache - AZ b"]
        end
    end

    asg[Auto Scaling Group 2 to 4]
    cw[CloudWatch alarms and dashboard]
    sns[SNS email alerts]
    state[(S3 remote state)]

    users -->|HTTP 80| alb
    admin -->|SSH 22 from my IP only| bastion
    alb -->|HTTP 80| app1
    alb -->|HTTP 80| app2
    bastion -.->|SSH jump host| app1
    bastion -.->|SSH jump host| app2
    app1 -.->|apt over HTTP 80| bastion
    app2 -.->|apt over HTTP 80| bastion
    asg --- app1
    asg --- app2
    cw --> sns
    asg -->|launch and terminate events| sns
```

**Traffic paths**

| Path             | Flow                                                                                           |
| ---------------- | ---------------------------------------------------------------------------------------------- |
| Web traffic      | Internet → ALB (public subnets) → Apache on EC2 (private subnets)                              |
| Admin access     | Admin laptop (your IP only) → bastion → private instances over SSH                             |
| Package installs | Private instances → bastion's internal APT repo over HTTP 80                                   |
| Alerts           | CloudWatch alarms and ASG events → SNS → email                                                 |
| Deployments      | Developer → pull request → GitHub Actions (checks, scan, plan) → approved apply → AWS + S3 state |

---

## What it deploys

| Module                | What it creates                                                                                                                             |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `backend/`            | S3 bucket for Terraform state (versioning, AES256 encryption, all public access blocked). Created once, separately from the pipeline.       |
| `modules/vpc`         | VPC, 2 public + 2 private subnets across 2 AZs, internet gateway, public route table.                                                       |
| `modules/security`    | Security groups for bastion, ALB and private servers, plus custom network ACLs for the public and private tiers.                            |
| `modules/iam`         | EC2 role and instance profile (baseline, no policies attached yet).                                                                         |
| `modules/bastion`     | Ubuntu 22.04 `t3.micro` with an Elastic IP. Acts as SSH jump host and as the internal APT repository.                                       |
| `modules/alb`         | Internet-facing Application Load Balancer, target group with health checks, HTTP listener.                                                  |
| `modules/autoScaling` | Launch template, Auto Scaling group (min 2, desired 2, max 4), CPU target-tracking policy (35%), and launch/terminate notifications to SNS. |
| `modules/cloudWatch`  | 5 alarms and a 6-widget dashboard.                                                                                                          |
| `modules/sns`         | Alerts topic with an email subscription.                                                                                                    |
| `.github/workflows/`  | `terraform-ci.yml` (checks, plan on PR, approval-gated apply of the saved plan on merge) and `terraform-destroy.yml` (manual teardown with typed confirmation and approval). |

---

## Key design decisions

**1. No NAT Gateway, internal package repository.**
Private instances have no route to the internet. On boot, the bastion downloads Apache and its dependencies, builds an APT repository with `dpkg-scanpackages`, and serves it over nginx. The private instances disable the public Ubuntu mirrors and install Apache from the bastion. This avoids the NAT Gateway's hourly and data charges.

**2. Layered network security.**
Private servers have no public IP. Security groups reference each other instead of IP ranges: the private SG accepts HTTP only from the ALB's SG and SSH only from the bastion's SG. Custom NACLs add a second, stateless layer. SSH to the bastion is restricted to the deployer's public IP, detected automatically at apply time.

**3. Self-healing through the load balancer.**
The Auto Scaling group uses `health_check_type = "ELB"`. If the ALB marks a target unhealthy, the ASG terminates that instance and launches a replacement automatically. Launch and terminate events are published to the same SNS topic as the alarms, so every replacement sends an email.

**4. Remote state with native locking.**
State lives in S3 with versioning and encryption. Locking uses Terraform's native S3 lock file (`use_lockfile = true`), so no DynamoDB table is needed.

**5. Modular layout.**
Each concern is its own module. `environment/dev` wires them together and is the only place with environment-specific values.

**6. Pipeline with guard rails.**
Infrastructure changes go through a pull request. Every PR runs formatting, validation and TFLint checks, a Trivy report and `terraform plan`, so reviewers see exactly what will change. Only a merge to `main` can trigger `apply`, the apply job waits for a manual approval, and it applies the exact plan that was reviewed. The pipeline signs in with short-lived OIDC credentials rather than stored keys. Destroy lives in its own manually triggered workflow with a typed confirmation and a separate approval, so it can never run by accident.

**7. State bucket kept outside the pipeline.**
The S3 bucket that holds Terraform state is created once, up front, and is never created or destroyed by the workflows. This avoids the pipeline deleting the state it depends on.

---

## Repository structure

```
.
├── .github/
│   └── workflows/
│       ├── terraform-ci.yml       # checks, plan on PR, approval-gated apply on merge
│       └── terraform-destroy.yml  # manual destroy (typed confirmation + approval)
├── backend/                       # one-time bootstrap: S3 bucket for remote state
├── environment/
│   └── dev/                       # root module: wires everything together
│       ├── main.tf
│       ├── backend.tf             # S3 backend config
│       ├── variables.tf
│       ├── outputs.tf
│       ├── provider.tf
│       └── versions.tf
├── modules/
│   ├── vpc/
│   ├── security/
│   ├── iam/
│   ├── bastion/
│   ├── alb/
│   ├── autoScaling/               # includes user_data.sh.tpl
│   ├── cloudWatch/
│   └── sns/
└── docs/images/                   # screenshots used in this README
```

---

## Quick start

You can deploy this project in two ways:

- **Through the pipeline** (recommended): fork the repo, add the secret and variables, open a pull request. See [CI/CD pipeline](#cicd-pipeline).
- **From your machine**: follow the steps below.

### Prerequisites

| Requirement         | Notes                                                           |
| ------------------- | --------------------------------------------------------------- |
| Terraform `>= 1.11` | Needed for native S3 state locking                              |
| AWS CLI             | Configured with credentials that can create the resources above |
| EC2 key pair        | Must already exist in `ap-south-1`                              |
| Email address       | Where alarm and ASG notifications are sent                      |
| GitHub repository   | Only needed to use the pipeline                                 |

### 1. Clone the repository

```bash
git clone https://github.com/qwertyuno0/aws-networking-project.git
cd aws-networking-project
```

### 2. Bootstrap remote state (once)

S3 bucket names are globally unique. Change `devops-project-aws-tf-01` to your own name in both `backend/main.tf` and `environment/dev/backend.tf` first.

```bash
cd backend
terraform init
terraform apply
```

### 3. Deploy the environment

Copy the example variables file and fill in your own values (`terraform.tfvars` is gitignored):

```bash
cd environment/dev
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: set key_name and alert_email
```

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### 4. Confirm the SNS subscription

AWS sends a confirmation email. Click the link, otherwise no alerts will arrive.

<p align="center">
  <img src="docs/images/01-terraform-apply-outputs.png" alt="terraform apply complete with outputs" width="800"><br>
  <sub><i><code>terraform apply</code> completing and printing the outputs.</i></sub>
</p>

---

## CI/CD pipeline

Infrastructure changes are delivered with **GitHub Actions** on **GitHub-hosted runners**. Nothing runs on a laptop. The pipeline signs in to AWS with **short-lived OIDC credentials** (no AWS keys are stored in GitHub), and every change is checked, planned and approved by a person before it reaches AWS.

```mermaid
flowchart LR
    subgraph PR["Pull request"]
        direction LR
        c1["Checks<br/>fmt, validate, TFLint, Trivy"] --> p1["terraform plan<br/>(job summary)"] --> s1["apply: skipped"]
    end
    subgraph MAIN["Merge to main, or manual run on main"]
        direction LR
        c2["Checks"] --> p2["terraform plan<br/>(saved artifact)"] --> a2{{"Approval: dev"}} --> ap["terraform apply<br/>(saved plan)"]
    end
    subgraph DEL["terraform-destroy.yml (manual)"]
        direction LR
        t["Type destroy-dev<br/>main only"] --> a3{{"Approval: dev-destroy"}} --> d["plan -destroy,<br/>then destroy"]
    end
    PR -->|review and merge| MAIN
    ap --> aws[(AWS)]
    d --> aws
```

### Workflows

| Workflow                | Trigger                                                                                              | What it does                                                                                                                                                  |
| ----------------------- | ---------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `terraform-ci.yml`      | Pull request to `main` that changes `environment/**`, `modules/**` or the workflow file               | Runs the checks, then `terraform plan`. The apply job is **skipped**, so nothing changes in AWS.                                                              |
| `terraform-ci.yml`      | Push (merge) to `main` that changes `environment/**` or `modules/**`                                  | Re-runs the checks and plan, saves the plan, **waits for approval** in the `dev` environment, then applies that exact plan.                                   |
| `terraform-ci.yml`      | Manual run (`workflow_dispatch`)                                                                      | Same as a push when started from `main`. From any other branch the apply job is skipped.                                                                     |
| `terraform-destroy.yml` | Manual run only. You must type `destroy-dev` as the confirmation input.                               | Runs only on `main`, waits for approval in the `dev-destroy` environment, then runs `terraform plan -destroy` and applies it. A wrong confirmation skips the job. |

The path filters mean a docs-only change (such as this README) does not start the pipeline.

### What the checks job runs

| Step                | Purpose                                                                                                                   |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| `terraform fmt`     | Fails if the code is not formatted                                                                                        |
| `terraform init -backend=false` | Initializes without touching the remote state, so no AWS access is needed for the checks                      |
| `terraform validate`| Fails on invalid configuration                                                                                            |
| TFLint              | Fails on lint errors across all modules                                                                                   |
| Trivy IaC scan      | Scans for HIGH and CRITICAL misconfigurations and lists them in the run log. **Report-only for now**: findings do not fail the run (see [Limitations](#limitations-and-next-steps)). |

The plan job only starts after the checks job passes.

### Guard rails

- **No stored AWS keys:** jobs assume an IAM role through GitHub OIDC and receive short-lived credentials for the run.
- **Checks before plan:** formatting, validation and TFLint must pass before a plan is produced.
- **Plan on every PR:** the full `terraform plan` is written to the run's job summary, so reviewers see exactly what will be added, changed or destroyed.
- **Apply exactly what was planned:** the plan is saved as an artifact (kept for 1 day) and the apply job downloads and applies that file. It never re-plans, so what was reviewed is what runs. Approve within a day, or re-run.
- **Approval gates:** apply runs in the protected `dev` environment and destroy in `dev-destroy`. Both require a reviewer, and administrators cannot bypass the rule.
- **Deliberate teardown:** destroy is a separate workflow. It needs a manual start, the typed confirmation `destroy-dev`, the `main` branch and its own approval.
- **One run at a time:** a `terraform-dev` concurrency group queues runs instead of cancelling them, and S3 native state locking protects the state file as a second layer.
- **State bucket out of scope:** the bucket is created once, by hand, and is never created or destroyed by the workflows.

> **Note:** the reviewer on both environments is the repository owner, and "Prevent self-review" is off because this is a solo project. On a team, turn it on so a different person must approve.

### One-time setup

1. **Create the state bucket** once (see [Quick start](#quick-start), step 2).
2. **Set up AWS for GitHub OIDC:** add GitHub as an OIDC identity provider (`token.actions.githubusercontent.com`) and create an IAM role that GitHub can assume. Limit the role's trust policy to this repository and remember that the token's subject differs for pull requests, branch pushes and jobs that use an environment. The role needs permission to manage the resources in this project and to use the state bucket.
3. **Add the repository secret and variables** under *Settings → Secrets and variables → Actions*:

   | Name                 | Type     | Purpose                                         |
   | -------------------- | -------- | ----------------------------------------------- |
   | `AWS_ROLE_ARN`       | Secret   | ARN of the IAM role the pipeline assumes        |
   | `AWS_REGION`         | Variable | AWS region, for example `ap-south-1`            |
   | `TF_VAR_KEY_NAME`    | Variable | EC2 key pair name for the bastion               |
   | `TF_VAR_ALERT_EMAIL` | Variable | Email address that receives SNS alerts          |

   Use the exact names referenced in `.github/workflows/`. Never commit credentials or `terraform.tfvars`.

4. **Create two Environments** under *Settings → Environments*: `dev` (used by apply) and `dev-destroy` (used by destroy). Add a **required reviewer** to each. This is what creates the approval gates.
5. **Protect `main`** (optional but recommended) so changes can only arrive through a pull request.

### How a change flows

1. Create a branch and change the Terraform code.
2. Open a pull request. `terraform-ci.yml` runs the checks and the plan. The apply job shows as *skipped* on purpose.
3. Read the plan in the run's job summary, then merge into `main`.
4. The push to `main` re-runs the checks and plan, saves the plan, and the apply job **waits for approval**. Review and approve it in the Actions tab.
5. Terraform applies the saved plan. Confirm the SNS email subscription if this is a fresh deployment.

### Tearing down

Open the **Actions** tab, choose **terraform-destroy**, click **Run workflow** on `main`, type `destroy-dev`, and approve the run in the `dev-destroy` environment. When the environment is gone, delete the state bucket manually (see [Clean up](#clean-up)).

### Pipeline in action

<p align="center">
  <img src="docs/images/15-actions-workflows-overview.png" alt="GitHub Actions workflows overview" width="800"><br>
  <sub><i>The two workflows in the Actions tab: <code>terraform-ci</code> and <code>terraform-destroy</code>.</i></sub>
</p>

<p align="center">
  <img src="docs/images/16-pr-checks-passing.png" alt="Pull request with checks and plan passing and apply skipped" width="800"><br>
  <sub><i>On a pull request the checks and plan run, and the apply job is skipped. Nothing changes in AWS until the change is merged and approved.</i></sub>
</p>

<p align="center">
  <img src="docs/images/17-terraform-plan-output.png" alt="terraform plan in the job summary" width="800"><br>
  <sub><i>The <code>terraform plan</code> output in the run's job summary, so changes are reviewed before merge.</i></sub>
</p>

<p align="center">
  <img src="docs/images/18-trivy-scan.png" alt="Checks job: format, validate, TFLint and Trivy" width="800"><br>
  <sub><i>The checks job: format, validate, TFLint and the Trivy IaC scan.</i></sub>
</p>

<p align="center">
  <img src="docs/images/22-environment-protection-rules.png" alt="dev environment with a required reviewer" width="800"><br>
  <sub><i>The <code>dev</code> environment requires a reviewer before apply can run, and administrators cannot bypass the rule. <code>dev-destroy</code> is configured the same way.</i></sub>
</p>

<p align="center">
  <img src="docs/images/22b-environments-list.png" alt="Environments list showing dev and dev-destroy" width="800"><br>
  <sub><i>Two environments: <code>dev</code> for apply and <code>dev-destroy</code> for destroy.</i></sub>
</p>

<p align="center">
  <img src="docs/images/19-approval-gate.png" alt="Apply job waiting for approval" width="800"><br>
  <sub><i>The apply job paused until a reviewer approves.</i></sub>
</p>

<p align="center">
  <img src="docs/images/19b-approval-gate.png" alt="Review pending deployments dialog" width="800"><br>
  <sub><i>The reviewer approves the deployment to <code>dev</code>.</i></sub>
</p>

<p align="center">
  <img src="docs/images/20-pipeline-apply-success.png" alt="Successful apply run" width="800"><br>
  <sub><i>An approved apply completing successfully: checks, plan, apply.</i></sub>
</p>

<p align="center">
  <img src="docs/images/21-destroy-run.png" alt="Manual destroy workflow run" width="800"><br>
  <sub><i>The manually triggered destroy workflow tearing the environment down.</i></sub>
</p>

---

## Verify it works

### Load balancing across two private servers

Open the ALB DNS name (`terraform output alb_dns_name`) in a browser and refresh. The hostname on the page alternates between the two servers.

<table>
  <tr>
    <th align="center">Server 1</th>
    <th align="center">Server 2</th>
  </tr>
  <tr>
    <td><img src="docs/images/02-alb-server-1.png" alt="ALB response from server 1" width="400"></td>
    <td><img src="docs/images/03-alb-server-2.png" alt="ALB response from server 2" width="400"></td>
  </tr>
</table>

<sub><i>Same URL, two different private instances serving the request.</i></sub>

### Both targets healthy

<p align="center">
  <img src="docs/images/04-target-group-healthy.png" alt="target group with two healthy targets" width="800"><br>
  <sub><i>Target group <code>dev-app-tg</code> with both instances healthy.</i></sub>
</p>

### Private servers have no public IP

<p align="center">
  <img src="docs/images/05-ec2-instances.png" alt="EC2 instances: bastion public, app servers private" width="800"><br>
  <sub><i>The bastion is the only instance with a public address. The app servers sit in private subnets in different AZs.</i></sub>
</p>

### SSH to a private server through the bastion

```bash
ssh -i your-key.pem -J ubuntu@<bastion_public_ip> ubuntu@<private_instance_ip>
```

<p align="center">
  <img src="docs/images/06-bastion-ssh-jump.png" alt="SSH jump through the bastion" width="800"><br>
  <sub><i>Reaching a private instance only via the bastion.</i></sub>
</p>

### Remote state

<p align="center">
  <img src="docs/images/07-s3-remote-state.png" alt="Terraform state stored in S3" width="800"><br>
  <sub><i>State stored remotely in a versioned, encrypted bucket.</i></sub>
</p>

---

## Self-healing demo

**Goal:** prove that an unhealthy instance is removed and replaced automatically, with no manual action.

### 1. Break one server

Connect through the bastion and stop Apache:

```bash
sudo systemctl stop apache2
```

Alternatively, mark it unhealthy from the CLI:

```bash
aws autoscaling set-instance-health \
  --instance-id <id> \
  --health-status Unhealthy \
  --region ap-south-1
```

### 2. What happens next, with no further input

| Step                                                                    | Roughly when          |
| ----------------------------------------------------------------------- | --------------------- |
| ALB health check fails twice, target marked `unhealthy`                 | within about a minute |
| `dev-alb-unhealthy-targets` alarm emails you                            | a few minutes         |
| ASG terminates the unhealthy instance and launches a replacement        | within a few minutes  |
| Old instance drains for 90 seconds, then is terminated                  | about 90 seconds      |
| Replacement boots, installs Apache from the bastion repo, turns healthy | a few more minutes    |

The site stays up throughout because the other instance keeps serving traffic.

<p align="center">
  <img src="docs/images/08-asg-activity-history.png" alt="ASG activity history showing terminate and launch" width="800"><br>
  <sub><i>The ASG terminating the unhealthy instance and launching a replacement.</i></sub>
</p>

<p align="center">
  <img src="docs/images/09-target-group-replacement.png" alt="target group during replacement" width="800"><br>
  <sub><i>The target group mid-replacement: one target draining, a new one registering.</i></sub>
</p>

<p align="center">
  <img src="docs/images/10-asg-notification-email.png" alt="ASG launch and terminate notification emails" width="800"><br>
  <sub><i>Every launch and terminate event is emailed through SNS.</i></sub>
</p>

---

## Monitoring and alerts

All alarms notify the SNS topic, which emails the address you provide.

| Alarm                        | Metric                             | Condition                        |
| ---------------------------- | ---------------------------------- | -------------------------------- |
| `dev-asg-high-cpu`           | EC2 `CPUUtilization` (ASG average) | above 30% for 1 period of 5 min  |
| `dev-alb-unhealthy-targets`  | ALB `UnHealthyHostCount`           | above 0 for 2 periods of 1 min   |
| `dev-alb-request-count`      | ALB `RequestCount` (sum)           | above 50 for 2 periods of 1 min  |
| `dev-alb-high-response-time` | ALB `TargetResponseTime` (avg)     | above 5 s for 3 periods of 1 min |
| `dev-alb-http-errors`        | ALB `HTTPCode_ELB_5XX_Count` (sum) | above 5 for 1 period of 1 min    |

> **Note:** EC2 publishes CPU data every 5 minutes with basic monitoring, so that alarm uses a 300-second period. The CPU threshold is deliberately low so it is easy to trigger in a demo. Use 70 to 80% for real workloads.

<p align="center">
  <img src="docs/images/12-cloudwatch-dashboard.png" alt="CloudWatch dashboard" width="800"><br>
  <sub><i>Dashboard: ASG CPU, group capacity, request count, response time, target health, 5xx errors.</i></sub>
</p>

<p align="center">
  <img src="docs/images/13-cloudwatch-alarms.png" alt="CloudWatch alarms list" width="800"><br>
  <sub><i>The five alarms managed by Terraform.</i></sub>
</p>

<p align="center">
  <img src="docs/images/14-sns-alarm-email.png" alt="SNS alarm email" width="800"><br>
  <sub><i>An alarm notification delivered by SNS.</i></sub>
</p>

---

## Troubleshooting log

Problems hit while building this, and how they were fixed.

<details>
<summary><b>Click to expand the full table (9 issues)</b></summary>
<br>

| Symptom                                                                               | Cause                                                                                                         | Fix                                                                                       |
| ------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| Only some alarms sent emails                                                          | Two alarms had no `alarm_actions`                                                                             | Added `alarm_actions` and `ok_actions` pointing to the SNS topic                          |
| Unhealthy instances were never replaced                                               | ASG used the default EC2 health check, which ignores the ALB                                                  | Set `health_check_type = "ELB"`                                                           |
| CPU alarm with a 60 s period rarely had data                                          | Basic monitoring publishes EC2 CPU every 5 minutes                                                            | Changed the period to 300 s                                                               |
| `user_data` script behaved oddly                                                      | Indented heredoc terminator in an inline Terraform string                                                     | Moved the script to `user_data.sh.tpl` and load it with `templatefile()`                  |
| VPC used `172.32.0.0/16`                                                              | That range is outside the private RFC1918 space                                                               | Switched to `10.0.0.0/16`, defined once in a `local`                                      |
| `use_lockfile` needed a newer Terraform than declared; DynamoDB lock table was unused | Native S3 locking requires Terraform 1.10+                                                                    | Required `>= 1.11` and removed the DynamoDB table                                         |
| On fresh deploys, one of two instances sometimes stayed unhealthy                     | Intermittent `apt` failure at first boot (likely lock contention with first-boot apt services or repo timing) | Wrapped `apt-get update` and `install` in a retry loop with a lock timeout                |
| Replaced instance kept running about 5 minutes                                        | Default target group deregistration delay is 300 s                                                            | Set `deregistration_delay = 90`                                                           |
| Pipeline applied successfully but no SNS email arrived                                | Typo in the alert email variable, so the subscription went to the wrong address                               | Corrected the email value, re-applied through the pipeline and confirmed the subscription |

</details>

---

## Cost

**Billable while running:**

- Application Load Balancer
- Three `t3.micro` instances (bastion plus two app servers, up to five at maximum scale)
- Public IPv4 addresses (load balancer nodes and the bastion's Elastic IP)

GitHub Actions on GitHub-hosted runners is free within the included minutes for public repositories. Free-tier coverage for AWS depends on when the account was created, so check the Billing console and the AWS Pricing Calculator.

> **Tip:** Run the **terraform-destroy** workflow (or `terraform destroy`) when you finish a session. The state bucket costs almost nothing and can stay until you are completely done with the project.

---

## Limitations and next steps

### Known limitations

- **The bastion is a dependency at boot.** New instances need its package repository to install Apache. Existing instances keep working if it goes down, but scale-out and replacements will wait until it is back.
- **HTTP only.** No TLS certificate, HTTPS listener or custom domain yet.
- **The IAM role is a baseline.** The instance profile exists but has no policies attached.
- **Not yet hardened:** IMDSv2 is not enforced, EBS volumes are not explicitly encrypted, and the AMI is the latest Ubuntu 22.04 at plan time rather than a pinned ID.
- **Package signatures are not verified.** The internal APT repository is configured with `[trusted=yes]`, which skips signature checks because the bastion builds the repo itself. Anyone who could modify `/var/www/html/repo` on the bastion could push malicious packages to every new instance. A production setup would sign the repository with a GPG key or bake the packages into an AMI.
- **SSH access uses the IP detected at apply time.** If your IP changes, re-run `terraform apply` to update the security group and NACL.
- **Trivy is report-only.** The scan lists HIGH and CRITICAL findings in the run log but does not fail the pipeline yet. Some findings overlap with the hardening items above.
- **Self-review is allowed on the approval gates.** This is a solo project, so the owner approves their own deployments. On a team, enable "Prevent self-review" on both environments.
- **Dev-only settings:** demo-level alarm thresholds, and `force_destroy = true` on the state bucket.

### Roadmap

- [x] GitHub Actions CI/CD: checks, Trivy report, plan on PR, approval-gated apply of the saved plan, manual destroy
- [x] GitHub OIDC for the pipeline instead of stored AWS keys
- [ ] Enforce the Trivy scan (fail the pipeline on HIGH and CRITICAL findings)
- [ ] HTTPS with ACM
- [ ] SSM Session Manager with VPC endpoints in place of SSH
- [ ] Pinned AMI
- [ ] IMDSv2 enforced

---

## Clean up

**Recommended:** run the **terraform-destroy** workflow from the **Actions** tab (*Run workflow* on `main`), type `destroy-dev` as the confirmation, and approve the run in the `dev-destroy` environment.

**From your machine:**

```bash
cd environment/dev
terraform destroy
```

When the environment is gone, remove the state bucket last. The pipeline never manages it, so delete it manually (empty it, including all object versions, then delete the bucket), or run `terraform destroy` in `backend/`.

---

## Author and acknowledgements

**Raj Vardhan**: B.Tech (AI & ML) student and aspiring Cloud Engineer, learning AWS, Kubernetes, Terraform and CI/CD.

[![GitHub](https://img.shields.io/badge/GitHub-qwertyuno0-181717?logo=github)](https://github.com/qwertyuno0)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-rajvardhan2004-0A66C2?logo=linkedin&logoColor=white)](https://linkedin.com/in/rajvardhan2004)

Inspired by [NotHarshhaa/DevOps-Projects (DevOps-Project-02)](https://github.com/NotHarshhaa/DevOps-Projects/tree/master/DevOps-Project-02), then extended with a bastion-hosted package repository, self-healing through ELB health checks, CloudWatch monitoring, SNS alerting and a GitHub Actions CI/CD pipeline.

If this project helped you, consider giving it a ⭐
