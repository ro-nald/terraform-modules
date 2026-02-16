output "db_public_ip" {
  description = "Public IP of the Postgres DB instance"
  value       = aws_instance.postgres_db.public_ip
}

output "db_private_ip" {
  description = "Private IP of the Postgres DB instance (use this in Web App config)"
  value       = aws_instance.postgres_db.private_ip
}

# Helper to find the instance created by the ASG for display purposes
data "aws_instances" "web_asg_instances" {
  instance_tags = {
    Name = "${var.environment_name}-web-spot"
  }
  instance_state_names = ["running", "pending"]
  depends_on           = [aws_autoscaling_group.web_asg]
}

output "web_public_ip" {
  description = "Public IP of the Web App instance (Note: This may change if Spot is reclaimed)"
  value       = try(data.aws_instances.web_asg_instances.public_ips[0], "Waiting for ASG...")
}
