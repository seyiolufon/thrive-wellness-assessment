resource "aws_security_group" "ec2_sg" {
  name   = "${var.project_name}-ec2-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*22.04-amd64-server-*"]
  }
}

data "template_cloudinit_config" "user_data" {
  gzip          = false
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content = <<-EOF
      #!/usr/bin/env bash
      set -euxo pipefail

      apt-get update -y
      apt-get install -y docker.io awscli jq wget
      systemctl enable --now docker

      mkdir -p /usr/lib/docker/cli-plugins
      curl -SL https://github.com/docker/compose/releases/download/v2.29.2/docker-compose-linux-x86_64 -o /usr/lib/docker/cli-plugins/docker-compose
      chmod +x /usr/lib/docker/cli-plugins/docker-compose

      REGION="${var.region}"
      ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text || true)"
      REPO_URL="${aws_ecr_repository.app.repository_url}"
      aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $REPO_URL

      IMAGE_TAG="$(aws ssm get-parameter --name "${var.ssm_image_tag_param}" --query 'Parameter.Value' --output text --region $REGION)"
      IMAGE="$REPO_URL:$IMAGE_TAG"

      cat >/opt/app-compose.yml <<YML
      services:
        web:
          image: $IMAGE
          restart: unless-stopped
          ports: ["3000:3000"]
          environment:
            - NODE_ENV=production
          logging:
            driver: awslogs
            options:
              awslogs-region: $REGION
              awslogs-group: /${var.project_name}/app
              awslogs-create-group: "true"
      YML

      docker compose -f /opt/app-compose.yml pull
      docker compose -f /opt/app-compose.yml up -d
    EOF
  }
}

resource "aws_launch_template" "lt" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  iam_instance_profile { name = aws_iam_instance_profile.ec2_profile.name }
  user_data = data.template_cloudinit_config.user_data.rendered
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
}

resource "aws_autoscaling_group" "app_asg" {
  name                      = "${var.project_name}-asg"
  desired_capacity          = var.desired_capacity
  max_size                  = var.max_size
  min_size                  = 1
  vpc_zone_identifier       = aws_subnet.public[*].id
  health_check_type         = "EC2"

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.tg.arn]

  tag {
    key="Name"
    value="${var.project_name}-ec2"
    propagate_at_launch=true
  }
}
