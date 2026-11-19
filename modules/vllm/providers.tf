# A fresh cluster token per call (module.cluster.exec: aws eks get-token, or
# kubelogin on Azure): a token fetched once per run expires after 15 minutes,
# and Helm waits can be longer (vLLM: 30). The runner needs the aws CLI or
# kubelogin. The cloud's own provider comes from modules/_cloud/<cloud>.
provider "helm" {
  kubernetes = {
    host                   = module.cluster.cluster_endpoint
    cluster_ca_certificate = base64decode(module.cluster.cluster_ca_data)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = module.cluster.exec.command
      args        = module.cluster.exec.args
    }
  }
}

provider "kubernetes" {
  host                   = module.cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(module.cluster.cluster_ca_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = module.cluster.exec.command
    args        = module.cluster.exec.args
  }
}
