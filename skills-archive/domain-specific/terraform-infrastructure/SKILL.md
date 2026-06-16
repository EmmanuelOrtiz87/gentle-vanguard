---
name: terraform-infrastructure
description: >
  Infrastructure as Code using Terraform with modular components, state management, and multi-cloud
  deployments. Use for provisioning and managing cloud resources.
metadata:
  source: GV-native
---

# Terraform Infrastructure

## Table of Contents

- [Overview](#overview)
- [When to Use](#when-to-use)
- [Quick Start](#quick-start)
- [Best Practices](#best-practices)

## Overview

Build scalable infrastructure as code with Terraform, managing AWS, Azure, GCP, and on-premise
resources through declarative configuration, remote state, and automated provisioning.

## When to Use

- Cloud infrastructure provisioning
- Multi-environment management (dev, staging, prod)
- Infrastructure versióning and code review
- Cost tracking and resource optimization
- Disaster recovery and environment replication
- Automated infrastructure testing
- Cross-region deployments

## Quick Start

Minimal working example:

```hcl
# terraform/main.tf
terraform {
  required_versión = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      versión = "~> 5.0"
    }
  }

  # Remote state configuration
  backend "s3" {
    bucket         = "terraform-state-prod"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
// ... (expand this skeleton directly in this skill when needed)
```

## Best Practices

### DO

- Use remote state (S3, Terraform Cloud)
- Implement state locking (DynamoDB)
- Organize code into modules
- Use workspaces for environments
- Apply tags consistently
- Use variables for flexibility
- Implement code review before apply
- Keep sensitive data in separate variable files

### DON'T

- Store state files locally in git
- Use hardcoded values
- Mix environments in single state
- Skip terraform plan review
- Use root module for everything
- Store secrets in code
- Disable state locking
