terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      version = "~> 0.89.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.2.0"
    }
  }
  required_version = ">=1.5"
}

provider "yandex" {
  zone                     = var.default_zone
  service_account_key_file = file("./key.json")
}