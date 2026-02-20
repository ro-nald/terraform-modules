# 1. The VPC
resource "aws_vpc" "cms_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = var.application_name }
}

# 2. The Internet Gateway (Allows the store to talk to the internet)
resource "aws_internet_gateway" "igw" {
  count  = local.create_vpc ? 1 : 0
  vpc_id = aws_vpc.cms_vpc.id

  tags   = { Name = var.application_name }
}

# 3. A Public Subnet in ap-east-1a
resource "aws_subnet" "public" {
  count  = local.create_vpc ? 1 : 0
  vpc_id                  = aws_vpc.cms_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = locals.selected_az
  map_public_ip_on_launch = true # Gives your EC2 a public IP automatically
}

# 4. Route Table (The "map" telling traffic to go to the Gateway)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.cms_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "a" {
  count          = local.create_vpc ? 1 : 0
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# 5. Security Group (The Firewall)
resource "aws_security_group" "cms_sg" {
  name        = "cms-security-group"
  description = "Allow web and SSH traffic"
  vpc_id      = aws_vpc.cms_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open to the world for the store
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["YOUR_IP/32"] # Lock SSH to ONLY your home IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}