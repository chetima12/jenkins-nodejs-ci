variable "aws_region" {
  description = "AWS Region for infrastructure deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "prod"
}

variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
  default     = "prod-eks-cluster"
}

variable "app_repository_name" {
  description = "ECR Repository Name"
  type        = string
  default     = "jenkins-nodejs-app"
}
