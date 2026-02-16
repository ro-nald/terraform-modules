provider "aws" {
  region = "eu-west-2"
}

# This example assumes you have a default VPC or a specific VPC ID available.
# In a real scenario, the consumer provides their own VPC ID.
variable "vpc_id" {
  type        = string
  description = "The VPC ID to deploy into (e.g., vpc-12345678)"
}

module "webapp_example" {
  # When used internally (testing), we point to the local path.
  # Consumers will point to the Git URL.
  source = "../../modules/aws/webapp_with_postgres"

  vpc_id            = var.vpc_id
  environment_name  = "example-app"
  web_instance_type = "t3.micro"
}

output "website_ip" {
  value = module.webapp_example.web_public_ip
}
