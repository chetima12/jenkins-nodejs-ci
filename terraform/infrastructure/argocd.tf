# Dedicated namespace for ArgoCD
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# Helm Release for ArgoCD
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = "6.7.0" # ArgoCD v2.10+

  values = [
    yamlencode({
      server = {
        # Enable HTTPS on Load Balancer termination or TLS passthrough
        extraArgs = ["--insecure"] # Offloads SSL termination to AWS ALB
        
        ingress = {
          enabled          = true
          ingressClassName = "alb"
          annotations = {
            "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
            "alb.ingress.kubernetes.io/target-type"      = "ip"
            "alb.ingress.kubernetes.io/listen-ports"     = "[{\"HTTPS\":443}]"
            "alb.ingress.kubernetes.io/ssl-redirect"     = "443"
            # Replace with your ACM certificate ARN
            # "alb.ingress.kubernetes.io/certificate-arn" = "arn:aws:acm:us-east-1:123456789012:certificate/xxx"
          }
          hosts = [
            {
              host = "argocd.yourdomain.com"
              paths = [
                {
                  path     = "/"
                  pathType = "Prefix"
                }
              ]
            }
          ]
        }
      }
      # Enable HA for Production deployments
      redis-ha = {
        enabled = true
      }
      controller = {
        metrics = {
          enabled = true
        }
      }
    })
  ]

  depends_on = [
    module.eks,
    helm_release.aws_load_balancer_controller
  ]
}
