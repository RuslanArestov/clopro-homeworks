terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      version = ">= 0.95.0"
    }
  }
  required_version = ">=1.5"
}

provider "yandex" {
  zone                     = var.default_zone
  service_account_key_file = file("./key.json")
}


