locals {
  # If a VPC ID is provided, use it. Otherwise, use the ID of the new VPC.
  create_vpc = var.vpc_id == null || var.vpc_id == ""
  vpc_id     = local.create_vpc ? aws_vpc.this[0].id : var.vpc_id

  # If a VPC ID is provided, fetch its subnets. Otherwise, use the new subnets.
  subnet_ids = local.create_vpc ? [for s in aws_subnet.this : s.id] : data.aws_subnets.selected[0].ids
}

# --- VPC (Conditionally Created) ---
resource "aws_vpc" "this" {
  count      = local.create_vpc ? 1 : 0
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${var.environment_name}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  count  = local.create_vpc ? 1 : 0
  vpc_id = aws_vpc.this[0].id

  tags = {
    Name = "${var.environment_name}-igw"
  }
}

resource "aws_route_table" "this" {
  count  = local.create_vpc ? 1 : 0
  vpc_id = aws_vpc.this[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this[0].id
  }

  tags = {
    Name = "${var.environment_name}-rt"
  }
}

resource "aws_subnet" "this" {
  count             = local.create_vpc ? 1 : 0 # Create one public subnet
  vpc_id            = aws_vpc.this[0].id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.region}a"

  tags = {
    Name = "${var.environment_name}-subnet-a"
  }
}

resource "aws_route_table_association" "this" {
  count          = local.create_vpc ? 1 : 0
  subnet_id      = aws_subnet.this[0].id
  route_table_id = aws_route_table.this[0].id
}

# --- Data Sources ---
# Fetch the specified VPC (only if a VPC ID is provided)
data "aws_vpc" "selected" {
  count = local.create_vpc ? 0 : 1
  id    = var.vpc_id
}

# Fetch subnets in the VPC (only if a VPC ID is provided)
data "aws_subnets" "selected" {
  count = local.create_vpc ? 0 : 1

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected[0].id]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# --- Security Groups ---

# Web App SG: Allow HTTP/HTTPS from world
resource "aws_security_group" "web_sg" {
  name        = "${var.environment_name}-web-sg"
  description = "Security group for Web App"
  vpc_id      = local.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# DB SG: Allow Postgres from Web SG
resource "aws_security_group" "db_sg" {
  name        = "${var.environment_name}-db-sg"
  description = "Security group for Postgres DB"
  vpc_id      = local.vpc_id

  ingress {
    description     = "Postgres from Web App"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Database Instance (Dedicated/Fixed) ---
resource "aws_instance" "postgres_db" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.db_instance_type
  subnet_id     = tolist(local.subnet_ids)[0]

  vpc_security_group_ids = [aws_security_group.db_sg.id]

  tags = {
    Name = "${var.environment_name}-postgres-db"
    Role = "database"
  }
}

# --- Web App (Spot with Fallback) ---

# 1. Launch Template defines the config for the instances
resource "aws_launch_template" "web_lt" {
  name_prefix   = "${var.environment_name}-web-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.web_instance_type

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web_sg.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.environment_name}-web-spot"
      Role = "web"
    }
  }
}

# 2. Auto Scaling Group manages the Spot/On-Demand logic
resource "aws_autoscaling_group" "web_asg" {
  name                = "${var.environment_name}-web-asg"
  desired_capacity    = 1
  max_size            = 1
  min_size            = 1
  vpc_zone_identifier = local.subnet_ids

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.web_lt.id
        version            = "$Latest"
      }

      # Overrides allow ASG to find capacity in similar instance types if the primary is out of stock
      override {
        instance_type = "t3.micro"
      }
      override {
        instance_type = "t3a.micro"
      }
    }

    instances_distribution {
      # 0 Base On-Demand means we try Spot immediately
      on_demand_base_capacity = 0
      # 0% On-Demand above base means 100% Spot
      on_demand_percentage_above_base_capacity = 0
      # "capacity-optimized" is the best strategy to ensure you actually get a Spot instance
      spot_allocation_strategy = "capacity-optimized"
    }
  }
}
