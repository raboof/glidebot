variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {
  default = "eu-west-1"
}
variable "aws_zone" {
  default = "eu-west-1a"
}
# http://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_container_instance.html
variable "aws_ecs_ami" {
  default = "ami-95f8d2f3"
}

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"
}

resource "aws_iam_role" "glidebot_instance" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "glidebot" {
  role = "${aws_iam_role.glidebot_instance.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:CreateCluster",
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:RegisterContainerInstance",
        "ecs:StartTelemetrySession",
        "ecs:Submit*",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecs:StartTask"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "glidebot" {
  roles = ["${aws_iam_role.glidebot_instance.name}"]
}

resource "aws_ecs_cluster" "glidebot" {
  name = "glidebot"
}

resource "aws_security_group" "secgroup_glidebot_ecs_instance" {
  ingress {
    from_port = 22
    to_port = 22
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "glidebot_ecs_launch_conf" {
  image_id = "${var.aws_ecs_ami}"
  instance_type = "t2.micro"
  security_groups = [ "${aws_security_group.secgroup_glidebot_ecs_instance.name}" ]
  iam_instance_profile = "${aws_iam_instance_profile.glidebot.name}"
  # TODO create with terraform, too?
  key_name = "myaws"
  user_data = "#!/bin/bash\necho ECS_CLUSTER=${aws_ecs_cluster.glidebot.name} >> /etc/ecs/ecs.config"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "glidebot_ecs_autoscaler" {
  availability_zones = ["${var.aws_zone}"]
  launch_configuration = "${aws_launch_configuration.glidebot_ecs_launch_conf.name}"
  min_size = 0
  max_size = 0

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecs_task_definition" "glidebot_task" {
  family = "glidebot_task"
  container_definitions = <<EOF
  [{
    "name": "glidebot_task",
    "image": "raboof/glidebot:latest",
    "cpu": 10,
    "memory": 300,
    "environment": [
      {
        "name": "USER",
        "value": "root"
      }
    ],
    "mountPoints": [
      {
        "containerPath": "/root/.ssh",
        "sourceVolume": "dotssh",
        "readOnly": true
      },
      {
        "containerPath": "/root/.config",
        "sourceVolume": "dotconfig",
        "readOnly": true
      }
    ]
  }]
EOF
  volume {
    "name" = "dotssh"
    "host_path" = "/home/ec2-user/dotssh"
  }

  volume {
    "name" = "dotconfig"
    "host_path" = "/home/ec2-user/dotconfig"
  }
}
