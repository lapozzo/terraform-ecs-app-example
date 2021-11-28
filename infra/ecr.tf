resource "aws_ecr_repository" "ecr" {
  count = var.ecr_enabled ? 1 : 0
  name  = "${var.app_name}-ecr"
  tags  = {
    Name        = "${var.app_name}-ecr"
    Environment = var.app_environment
  }
}