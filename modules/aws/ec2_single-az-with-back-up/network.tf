resource "aws_vpc" "new_network" {
  count      = local.create_vpc ? 1 : 0
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${var.application_name}-vpc"
  }
}

# 2. The Internet Gateway (Allows the store to talk to the internet)
resource "aws_internet_gateway" "igw_new_network" {
  count  = local.create_vpc ? 1 : 0
  vpc_id = aws_vpc.new_network[count.index].id

  tags = { Name = var.application_name }
}

# 3. A Public Subnet in ap-east-1a
resource "aws_subnet" "new_network" {
  count                   = local.create_vpc ? 1 : 0
  vpc_id                  = aws_vpc.new_network[count.index].id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = local.selected_az
  map_public_ip_on_launch = true # Gives your EC2 a public IP automatically
}

# 4. Route Table (The "map" telling traffic to go to the Gateway)
resource "aws_route_table" "public_rt" {
  count          = local.create_vpc ? 1 : 0
  vpc_id = aws_vpc.new_network[count.index].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_new_network[count.index].id
  }
}

resource "aws_route_table_association" "a" {
  count          = local.create_vpc ? 1 : 0
  subnet_id      = aws_subnet.new_network[count.index].id
  route_table_id = aws_route_table.public_rt[count.index].id
}

# 1. The VPC
resource "aws_vpc" "cms_vpc" {
  count                = local.create_vpc ? 0 : 1
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = var.application_name }
}

# 5. Security Group (The Firewall)
resource "aws_security_group" "cms_sg" {
  name        = "cms-security-group"
  description = "Allow web and SSH traffic"
  vpc_id      = local.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open to the world for the store
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}