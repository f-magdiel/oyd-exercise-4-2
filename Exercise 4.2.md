# **Exercise 4.2 — Orders Service Remote State Migration**

**Course:** Optimizaciones y Desempeño — Cloud Deployment Automation  
**Session:** 4 — May 14, 2026  
**Time allowed:** 30 minutes  
**Submission:** Initialize a new repository called oyd-exercise-4-2 and commit/push everything into it. Submit the repository URL only.

# Context

You have inherited an orders service Terraform workspace that uses local state. Your task is to bootstrap an S3 remote backend with DynamoDB locking, migrate the existing state into it, and prove the locking mechanism works.

Create the following four starter files in a new directory oyd-exercise-4-2/. Commit them as your initial commit, then run terraform init and terraform apply \-var-file=terraform.tfvars once to create local state before beginning the migration tasks.

### provider.tf

terraform {  
  required\_providers {  
    aws \= {  
      source  \= "hashicorp/aws"  
      version \= "\~\> 5.0"  
    }  
  }  
}  
provider "aws" {  
  region \= var.region  
}

### main.tf

resource "aws\_s3\_bucket" "order\_attachments" {  
  bucket \= "${var.app\_name}-order-attachments-${var.environment}"  
  tags \= {  
    Environment \= var.environment  
    ManagedBy   \= "terraform"  
  }  
}

### variables.tf

variable "app\_name" {  
  type        \= string  
  description \= "Application name. Used in resource naming."  
}  
variable "environment" {  
  type        \= string  
  description \= "Deployment environment: dev, staging, or prod."  
}  
variable "region" {  
  type        \= string  
  description \= "AWS region."  
  default     \= "us-east-1"  
}

### terraform.tfvars

app\_name    \= "orders-svc"  
environment \= "dev"

After running the initial apply, you will have a terraform.tfstate file on disk. Do not run apply again until Task 3 instructs you to.

# Setup

## Prerequisites

* AWS CLI configured with credentials that can create S3 buckets and DynamoDB tables.  
* Terraform \>= 1.8 installed and on PATH.  
* The four starter files above committed as the initial commit and the initial apply completed (local state exists on disk).

# Tasks

## Task 1 — Bootstrap the Remote Backend

Create the S3 bucket and DynamoDB lock table that will store your Terraform state. Choose one of the two approaches below. Both are acceptable.

### Option A — AWS CLI

\# Create the state bucket (replace \<your-name\> with a short unique identifier)  
aws s3api create-bucket \\  
  \--bucket \<your-name\>-orders-tfstate \\  
  \--region us-east-1

\# Enable versioning  
aws s3api put-bucket-versioning \\  
  \--bucket \<your-name\>-orders-tfstate \\  
  \--versioning-configuration Status\=Enabled

\# Create the DynamoDB lock table  
aws dynamodb create-table \\  
  \--table-name \<your-name\>-orders-locks \\  
  \--attribute-definitions AttributeName\=LockID,AttributeType\=S \\  
  \--key-schema AttributeName\=LockID,KeyType\=HASH \\  
  \--billing-mode PAY\_PER\_REQUEST

### Option B — Terraform bootstrap workspace

Create a separate bootstrap/ directory at the root of your repository with its own main.tf, variables.tf, and outputs.tf. Provision an aws\_s3\_bucket (with versioning) and an aws\_dynamodb\_table (hash key LockID, PAY\_PER\_REQUEST) using prevent\_destroy \= true on both. Apply this workspace with local state and commit the resulting terraform.tfstate inside bootstrap/.

## Task 2 — Configure the S3 Backend

Add a backend.tf file to the root workspace with the S3 backend configuration. Use literal string values — do not use variable references inside the backend block.

terraform {  
  backend "s3" {  
    bucket         \= "\<your-bucket-name\>"  
    key            \= "orders/terraform.tfstate"  
    region         \= "us-east-1"  
    dynamodb\_table \= "\<your-lock-table-name\>"  
    encrypt        \= true  
  }  
}

## Task 3 — Migrate State

* Run terraform init. When prompted to copy existing local state to the new backend, confirm with yes.  
* Run terraform state list to confirm the state was migrated and is readable from the remote backend.  
* Run aws s3 ls s3://\<your-bucket\>/orders/ to confirm the state object exists in S3.  
* Add terraform.tfstate and terraform.tfstate.backup to .gitignore. Remove the local state from version control: git rm \--cached terraform.tfstate. Commit the .gitignore update.

## Task 4 — Prove Lock Contention

Demonstrate that the DynamoDB lock table prevents concurrent applies.

* Add the following resource to main.tf and the corresponding required provider entry to provider.tf. Run terraform init to download the time provider.

\# Add to main.tf  
resource "time\_sleep" "lock\_demo" {  
  create\_duration \= "20s"  
}

\# Add to required\_providers in provider.tf  
hashicorp/time \= {  
  source  \= "hashicorp/time"  
  version \= "\~\> 0.11"  
}

* In Terminal 1, run: terraform apply \-var-file=terraform.tfvars \-auto-approve  
* While Terminal 1 is still running (before the time\_sleep completes), open Terminal 2 in the same directory and run: terraform apply \-var-file=terraform.tfvars \-auto-approve  
* Take a screenshot of the lock error in Terminal 2\. It will show Error: Error acquiring the state lock and include the lock holder information.

## Task 5 — Evidence

* Save the lock error screenshot as evidence/lock-contention.png.  
* Run terraform state list after the migration. Save the output to evidence/state-remote.txt.  
* Run aws s3 ls s3://\<your-bucket\>/orders/. Save the output to evidence/s3-state.txt.  
* Create README.md. Under a \#\# Evidence section, render the state-remote.txt and s3-state.txt files inline as fenced code blocks, and embed the lock-contention.png screenshot inline.

# Acceptance Criteria

* S3 bucket exists and versioning is enabled on it.  
* DynamoDB lock table exists with hash key LockID.  
* backend.tf is present with bucket, key, region, dynamodb\_table, and encrypt \= true. No variable references appear in the backend block.  
* terraform init migration completed — evidence/state-remote.txt shows at least one resource from terraform state list.  
* terraform.tfstate is absent from version control and listed in .gitignore.  
* evidence/lock-contention.png shows the text Error: Error acquiring the state lock from Terminal 2\.  
* evidence/s3-state.txt shows the state object at the path orders/terraform.tfstate in S3.  
* All evidence files committed to the repository and rendered in README.md under \#\# Evidence.