resource "aws_ecs_cluster" "ecs_cluster" {
  count = var.ecs_enabled ? 1 : 0
  name = "${var.app_name}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = {
    Application = var.app_name
    Environment = var.app_environment
  }  
}

resource "aws_cloudwatch_log_group" "log_group" {
  count = var.ecs_enabled ? 1 : 0
  name  = "${var.app_name}-${var.app_environment}-logs"

  tags = {
    Application = var.app_name
    Environment = var.app_environment
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  count              = var.ecs_enabled ? 1 : 0
  name               = "${var.app_name}-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags = {
    Name        = "${var.app_name}-iam-role"
    Environment = var.app_environment
  }
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  count      = var.ecs_enabled ? 1 : 0
  role       = aws_iam_role.ecs_task_execution_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_s3" {
  count      = var.ecs_enabled ? 1 : 0
  role       = aws_iam_role.ecs_task_execution_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}


resource "aws_ecs_task_definition" "aws_ecs_task" {
  count  = var.ecs_enabled ? 1 : 0
  family = "${var.app_name}-task"

  container_definitions = <<DEFINITION
  [
    {
      "name": "${var.app_name}-${var.app_environment}-container",
      "image": "${aws_ecr_repository.ecr[0] .repository_url}:latest",
      "entryPoint": [],
      "essential": true,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.log_group[0].id}",
          "awslogs-region": "${var.aws_region}",
          "awslogs-stream-prefix": "${var.app_name}-${var.app_environment}"
        }
      },
      "portMappings": [
        {
          "containerPort": 8080,
          "hostPort": 8080
        }
      ],
      "cpu": 256,
      "memory": 512,
      "networkMode": "awsvpc"
    }
  ]
  DEFINITION

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = "512"
  cpu                      = "256"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role[0].arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role[0].arn

  tags = {
    Name        = "${var.app_name}-ecs-td"
    Environment = var.app_environment
  }
}

resource "aws_ecs_service" "aws_ecs_service" {
  count                = var.ecs_enabled ? 1 : 0
  name                 = "${var.app_name}-${var.app_environment}-ecs-service"
  cluster              = aws_ecs_cluster.ecs_cluster[0].id
  task_definition      = "${aws_ecs_task_definition.aws_ecs_task[0].family}:${aws_ecs_task_definition.aws_ecs_task[0].revision}"
  launch_type          = "FARGATE"
  scheduling_strategy  = "REPLICA"
  desired_count        = 1
  force_new_deployment = true

  network_configuration {
    subnets          = "${var.private_subnets}"
    assign_public_ip = false
    security_groups = [
      aws_security_group.service_security_group[0].id,
      aws_security_group.load_balancer_security_group[0].id
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group[0].arn
    container_name   = "${var.app_name}-${var.app_environment}-container"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.listener]
}

resource "aws_security_group" "service_security_group" {
  count  = var.ecs_enabled ? 1 : 0
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.load_balancer_security_group[0].id]
  }

  egress {
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "${var.app_name}-service-sg"
    Environment = var.app_environment
  }
}

resource "aws_appautoscaling_target" "ecs_target" {
  count              = var.ecs_enabled ? 1 : 0
  max_capacity       = 2
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster[0].name}/${aws_ecs_service.aws_ecs_service[0].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  count              = var.ecs_enabled ? 1 : 0
  name               = "${var.app_name}-${var.app_environment}-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value = 80
  }
}

resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  count              = var.ecs_enabled ? 1 : 0
  name               = "${var.app_name}-${var.app_environment}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 80
  }
}

resource "aws_vpc_endpoint" "ecr" {
  vpc_id              = "${var.vpc_id}"
  service_name        = "com.amazonaws.us-east-2.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = "${var.private_subnets}"
  security_group_ids = [
      aws_security_group.service_security_group[0].id,
      aws_security_group.load_balancer_security_group[0].id
  ]

  tags = {
    Name        = "${var.app_name}-service-sg"
    Environment = var.app_environment
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = "${var.vpc_id}"
  service_name        = "com.amazonaws.us-east-2.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = "${var.private_subnets}"
  security_group_ids = [
      aws_security_group.service_security_group[0].id,
      aws_security_group.load_balancer_security_group[0].id
  ]

  tags = {
    Name        = "${var.app_name}-service-sg"
    Environment = var.app_environment
  }
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = "${var.vpc_id}"
  service_name        = "com.amazonaws.us-east-2.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = "${var.private_subnets}"
  security_group_ids = [
      aws_security_group.service_security_group[0].id,
      aws_security_group.load_balancer_security_group[0].id
  ]

  tags = {
    Name        = "${var.app_name}-service-sg"
    Environment = var.app_environment
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id              = "${var.vpc_id}"
  service_name        = "com.amazonaws.us-east-2.s3"
  vpc_endpoint_type   = "Gateway"

  tags = {
    Name        = "${var.app_name}-service-sg"
    Environment = var.app_environment
  }
}