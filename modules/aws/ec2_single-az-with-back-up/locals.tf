locals {
  selected_az = data.aws_availability_zones.available.names[0]
}