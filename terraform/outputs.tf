output "alb_dns"        { value = aws_lb.app_lb.dns_name }
output "ecr_repository" { value = aws_ecr_repository.app.repository_url }
output "asg_name"       { value = aws_autoscaling_group.app_asg.name }
output "iam_role_oidc"  { value = aws_iam_role.github_oidc.arn }
