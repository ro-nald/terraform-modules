# --- 2. THE EC2 INSTANCE ---
resource "aws_instance" "cms_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.cms_sg.id]
  
  # Ensure we tag it so DLM can find it
  tags = {
    Name   = "${var.application_name}-${var.environment}"
    Backup = "Daily"
  }

  root_block_device {
    volume_size = 10
    volume_type = var.block_volume_type
  }
}

# --- 3. THE DLM POLICY (Backups) ---
resource "aws_dlm_lifecycle_policy" "daily_snapshots" {
  description        = "Daily snapshots for Cookie Store CMS"
  execution_role_arn = aws_iam_role.dlm_lifecycle.arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]
    
    # DLM targets volumes based on tags
    target_tags = {
      Backup = "Daily"
    }

    schedule {
      name = "DailySnapshots"
      
      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["12:00"] # 12 PM UTC (8 PM HK Time)
      }

      retain_rule {
        count = 7 # Keep 1 week of backups
      }

      copy_tags = true
    }
  }
}

# --- 4. AUTO-RECOVERY ALARM (Fault Tolerance) ---
resource "aws_cloudwatch_metric_alarm" "recovery" {
  alarm_name          = "recover-${aws_instance.cms_server.id}"
  metric_name         = "StatusCheckFailed_System"
  namespace           = "AWS/EC2"
  statistic           = "Minimum"
  period              = "60"
  evaluation_periods  = "2"
  threshold           = "0"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    InstanceId = aws_instance.cms_server.id
  }

  alarm_actions = ["arn:aws:automate:ap-east-1:ec2:recover"]
}