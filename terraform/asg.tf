# ==============================================================================
# Auto Scaling Group (ASG), Políticas de Escalamiento y Monitoreo CloudWatch
# ==============================================================================

# Auto Scaling Group Multi-AZ (Min: 1 | Deseada: 1 | Max: 3)
resource "aws_autoscaling_group" "main" {
  name                = "asg-${var.project_name}"
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_desired_capacity
  health_check_type   = "ELB"
  health_check_grace_period = 300

  vpc_zone_identifier = [
    aws_subnet.public_1a.id,
    aws_subnet.public_1b.id,
    aws_subnet.public_1c.id
  ]

  target_group_arns = [aws_lb_target_group.main.arn]

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "ec2-${var.project_name}-asg"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Política de Escalamiento Target Tracking (CPU = 50%)
# Ajusta automáticamente el número de instancias entre 1 y 3 para mantener el CPU al 50%
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "asp-${var.project_name}-cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.main.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = var.cpu_target_utilization
  }
}

# Alarma de CloudWatch para Observabilidad (CPUUtilization > 50%)
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "alarm-${var.project_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = var.cpu_target_utilization
  alarm_description   = "Disparada cuando el uso promedio de CPU en el ASG supera el 50%"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }
}
