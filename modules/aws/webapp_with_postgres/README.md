# AWS Web App with Postgres Module

This Terraform module deploys a simple 2-tier web application architecture on AWS. It consists of a web tier running on Spot Instances (managed by an Auto Scaling Group) and a database tier running on a dedicated EC2 instance.

## Architecture

* OS: Ubuntu 24.04 LTS (Noble Numbat) for both tiers.
* Web Tier:
  * Managed by an Auto Scaling Group (ASG).
  * Uses **Spot Instances** with a "capacity-optimized" allocation strategy to minimize costs.
  * Includes a fallback to `t3.micro` and `t3a.micro` instance types.
  * Security Group allows HTTP (80) and HTTPS (443) from anywhere (`0.0.0.0/0`).
* Database Tier:
  * Single EC2 instance running Postgres (software installation not included in Terraform).
  * Security Group allows traffic on port 5432 only from the Web Tier Security Group.
  * **Note**: SSH access is currently disabled.

## Prerequisites

* Terraform v1.0+
* AWS Provider ~> 5.0
* An existing VPC ID is required.

## Usage

```hcl
module "webapp" {
  source = "./modules/aws/webapp_with_postgres"

  # Required
  vpc_id = "vpc-12345678"

  # Optional
  region            = "us-east-1"
  environment_name  = "production-app"
  web_instance_type = "t3.small"
  db_instance_type  = "t3.large"
}
```

## Inputs

| Name | Description | Type | Default | Required |
| ----- | ------------- | ------ | --------- | -------- |
| `vpc_id` | The ID of the VPC to deploy into. Must start with `vpc-`. | `string` | n/a | yes |
| `region` | AWS Region to deploy into. | `string` | `"eu-west-2"` | no |
| `environment_name` | Name prefix for resources (e.g., SGs, Instances). | `string` | `"my-app"` | no |
| `web_instance_type` | Instance type for the Web App (Spot instances). | `string` | `"t3.micro"` | no |
| `db_instance_type` | Instance type for the Postgres DB. | `string` | `"t3.medium"` | no |

## Outputs

| Name | Description |
| ------ | ------------- |
| `db_public_ip` | Public IP address of the Postgres DB instance. |
| `db_private_ip` | Private IP address of the Postgres DB instance (recommended for app connection). |
| `web_public_ip` | Public IP of one of the Web App instances (retrieved dynamically from the ASG). |

## Notes

* Spot Instances: The web tier relies on Spot instances. While cost-effective, they can be reclaimed by AWS with a 2-minute warning. The ASG is configured to handle replacements automatically.
* State Management: This module uses local state by default. For production use, configure a remote backend.
