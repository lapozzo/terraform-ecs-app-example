ECR_REPO_URL = 137493621064.dkr.ecr.us-east-2.amazonaws.com/ecs-example-app-ecr

build:
	mvn clean package
	docker build . -t $(ECR_REPO_URL):latest

push:
	aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 137493621064.dkr.ecr.us-east-2.amazonaws.com
	docker push $(ECR_REPO_URL):latest

