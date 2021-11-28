output "ecr_repository" {
  description = "The ECR Repository"
  value       = "${aws_ecr_repository.ecr[0].repository_url}"
}

output "ecs_cluster" {
  description = "The ECS Cluster Id"
  value       = "${aws_ecs_cluster.ecs_cluster[0].id}"
}

output "load_balancer" {
  description = "The Load Balancer DNS"
  value       = "${aws_alb.application_load_balancer[0].dns_name}"
}

