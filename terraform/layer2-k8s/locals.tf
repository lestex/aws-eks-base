locals {
  region                    = data.terraform_remote_state.layer1-aws.outputs.region
  short_region              = data.terraform_remote_state.layer1-aws.outputs.short_region
  az_count                  = data.terraform_remote_state.layer1-aws.outputs.az_count
  name                      = data.terraform_remote_state.layer1-aws.outputs.name
  env                       = data.terraform_remote_state.layer1-aws.outputs.env
  zone_id                   = data.terraform_remote_state.layer1-aws.outputs.route53_zone_id
  domain_name               = data.terraform_remote_state.layer1-aws.outputs.domain_name
  domain_suffix             = "${local.env}.${local.domain_name}"
  allowed_ips               = data.terraform_remote_state.layer1-aws.outputs.allowed_ips
  ip_whitelist              = join(",", concat(local.allowed_ips, var.additional_allowed_ips))
  vpc_id                    = data.terraform_remote_state.layer1-aws.outputs.vpc_id
  vpc_cidr                  = data.terraform_remote_state.layer1-aws.outputs.vpc_cidr
  eks_cluster_id            = data.terraform_remote_state.layer1-aws.outputs.eks_cluster_id
  eks_oidc_provider_arn     = data.terraform_remote_state.layer1-aws.outputs.eks_oidc_provider_arn
  ssl_certificate_arn       = data.terraform_remote_state.layer1-aws.outputs.ssl_certificate_arn
  elastic_stack_bucket_name = data.terraform_remote_state.layer1-aws.outputs.elastic_stack_bucket_name

  helm_repo_stable      = "https://kubernetes-charts.storage.googleapis.com"
  helm_repo_incubator   = "https://storage.googleapis.com/kubernetes-charts-incubator"
  helm_repo_certmanager = "https://charts.jetstack.io"
  helm_repo_gitlab      = "https://charts.gitlab.io"
  helm_repo_eks         = "https://aws.github.io/eks-charts"
  helm_repo_softonic    = "https://charts.softonic.io"
  helm_repo_elastic     = "https://helm.elastic.co"
}

