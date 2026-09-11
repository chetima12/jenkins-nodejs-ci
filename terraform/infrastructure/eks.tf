module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.31"

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Enables OIDC Provider for IRSA
  enable_irsa = true

  eks_managed_node_groups = {
    general_nodes = {
      name           = "prod-node-group"
      instance_types = ["t3.small"]
      min_size       = 2
      max_size       = 6
      desired_size   = 3

      capacity_type = "ON_DEMAND"
      
      ebs_optimized = true
      disk_size     = 50

      labels = {
        role = "general"
      }
    }
  }

  # Cluster admin access configuration
  enable_cluster_creator_admin_permissions = true
}
