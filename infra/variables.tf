variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "vpc_id" {
  type        = string
  description = "VPC Id"
}

variable "app_name" {
  type        = string
  description = "Application Name"
}

variable "app_environment" {
  type        = string
  description = "Application Environment"
}

variable "public_subnets" {
  description = "List of public subnets"
}

variable "private_subnets" {
  description = "List of private subnets"
}

variable "ecr_enabled" {
  type        = bool
  default     = false
  description = "Enable ECR"
}

variable "ecs_enabled" {
  type        = bool
  default     = false
  description = "Enable ECS"
}
variable "lb_enabled" {
  type        = bool
  default     = false
  description = "Enable Load Balancer"
}
