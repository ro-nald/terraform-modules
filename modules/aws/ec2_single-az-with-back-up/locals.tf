locals {
  selected_az = data.aws_availability_zones.available.names[0]

  # If a VPC ID is provided, use it. Otherwise, use the ID of the new VPC.
  create_vpc = var.vpc_id == null || var.vpc_id == ""
  vpc_id     = local.create_vpc ? aws_vpc.new_network[0].id : var.vpc_id

  # If a VPC ID is provided, fetch its subnets. Otherwise, use the new subnets.
  subnet_ids = local.create_vpc ? [for s in aws_subnet.new_network : s.id] : data.aws_subnets.provided[0].ids
}