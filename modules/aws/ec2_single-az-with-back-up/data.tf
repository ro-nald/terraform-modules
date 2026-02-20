data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's official AWS ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server-*"]
  }
}

data "aws_availability_zones" "available" {
  # This only sees the region defined in the provider (ap-east-1)
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }

  # Ensure we only get standard AZs, not "Local Zones" (e.g. for low latency)
  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}


data "aws_vpc" "provided" {
  count = local.create_vpc ? 0 : 1
  id    = var.vpc_id
}

# 1. The VPC
data "aws_subnets" "provided" {
  count = local.create_vpc ? 0 : 1
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.provided[0].id]
  }
}