terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      version = ">= 0.95.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
  required_version = ">=1.5"
}

provider "yandex" {
  zone                     = var.default_zone
  service_account_key_file = file("./key.json")
}

data "yandex_client_config" "client" {}

provider "kubernetes" {
  host                   = yandex_kubernetes_cluster.regional_cluster.master[0].external_v4_endpoint
  cluster_ca_certificate = yandex_kubernetes_cluster.regional_cluster.master[0].cluster_ca_certificate
  token                  = data.yandex_client_config.client.iam_token
}
