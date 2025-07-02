resource "yandex_vpc_network" "network" {
  name = var.network_name
}

################################ Cluster MySQL ##############################
resource "yandex_vpc_subnet" "private-subnet-a" {
  name           = "private-subnet-a"
  zone           = var.default_zone
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = [var.subnet_cidr-a]
}

resource "yandex_vpc_subnet" "private-subnet-b" {
  name           = "private-subnet-b"
  zone           = var.zone-b
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = [var.subnet_cidr-b]
}

resource "yandex_vpc_subnet" "private-subnet-d" {
  name           = "private-subnet-d"
  zone           = var.zone-d
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = [var.subnet_cidr-d]
}

resource "yandex_vpc_security_group" "mysql-sg" {
  name       = "mysql-sg"
  network_id = yandex_vpc_network.network.id

  ingress {
    description    = "MySQL®"
    port           = 3306
    protocol       = "TCP"
    v4_cidr_blocks = [ "0.0.0.0/0" ]
  }
}

resource "yandex_mdb_mysql_cluster" "claster-mysql" {
  name                = "claster-mysql"
  environment         = "PRESTABLE"
  network_id          = yandex_vpc_network.network.id
  version             = "8.0"
  security_group_ids  = [ yandex_vpc_security_group.mysql-sg.id ]
  deletion_protection = true

  resources {
    resource_preset_id = "s1.micro"
    disk_type_id       = "network-hdd"
    disk_size          = 20
  }

  host {
    zone             = "ru-central1-a"
    subnet_id        = yandex_vpc_subnet.private-subnet-a.id
    assign_public_ip = false
    backup_priority  = 10 # master node
  }
 
  host {
    zone             = "ru-central1-b"
    subnet_id        = yandex_vpc_subnet.private-subnet-b.id
    assign_public_ip = false
  }

  host {
    zone             = "ru-central1-d"
    subnet_id        = yandex_vpc_subnet.private-subnet-d.id
    assign_public_ip = false
  }

  maintenance_window {
    type = "WEEKLY"
    day  = "SAT"
    hour = "23"
  }

  backup_window_start {
    hours   = "23"
    minutes = "59"
  }
}

resource "yandex_mdb_mysql_database" "netology_db" {
  cluster_id = yandex_mdb_mysql_cluster.claster-mysql.id
  name       = "netology_db"
}

resource "yandex_mdb_mysql_user" "netology" {
  cluster_id = yandex_mdb_mysql_cluster.claster-mysql.id
  name       = "netology"
  password   = "12345678"
  permission {
    database_name = yandex_mdb_mysql_database.netology_db.name
    roles         = ["ALL"]
  }
}


################################ Cluster Kubernetes ##############################
resource "yandex_vpc_subnet" "public-subnet-a" {
  name           = "public-subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = [var.public-subnet_cidr-a]
}

resource "yandex_vpc_subnet" "public-subnet-b" {
  name           = "public-subnet-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = [var.public-subnet_cidr-b]
}

resource "yandex_vpc_subnet" "public-subnet-d" {
  name           = "public-subnet-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = [var.public-subnet_cidr-d]
}

# Сервисные аккаунты
resource "yandex_iam_service_account" "k8s-admin" {
  name        = "k8s-admin"
  description = "Service account for managing K8S cluster"
}

resource "yandex_iam_service_account" "k8s-nodes" {
  name        = "k8s-nodes"
  description = "Service account for K8S worker nodes"
}

# Назначение ролей
resource "yandex_resourcemanager_folder_iam_binding" "k8s-admin-roles" {
  folder_id = var.folder_id
  role      = "editor"
  members   = ["serviceAccount:${yandex_iam_service_account.k8s-admin.id}"]
}

resource "yandex_resourcemanager_folder_iam_binding" "k8s-cluster-agent" {
  folder_id = var.folder_id
  role      = "k8s.clusters.agent"
  members   = ["serviceAccount:${yandex_iam_service_account.k8s-admin.id}"]
}

resource "yandex_resourcemanager_folder_iam_binding" "k8s-nodes-roles" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  members   = ["serviceAccount:${yandex_iam_service_account.k8s-nodes.id}"]
}


# KMS ключ для шифрования
resource "yandex_kms_symmetric_key" "k8s-key" {
  name              = "k8s-encryption-key"
  default_algorithm = "AES_128"
  rotation_period   = "8760h"
}

resource "yandex_kms_symmetric_key_iam_binding" "viewer" {
  symmetric_key_id = yandex_kms_symmetric_key.k8s-key.id
  role             = "viewer"
  members          = ["serviceAccount:${yandex_iam_service_account.k8s-admin.id}"]
}

# Группы безопасности
resource "yandex_vpc_security_group" "k8s-master-sg" {
  name       = "k8s-master-sg"
  network_id = yandex_vpc_network.network.id

  ingress {
    protocol       = "TCP"
    port           = 6443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol          = "TCP"
    port              = 443
    predefined_target = "loadbalancer_healthchecks"
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "k8s-nodes-sg" {
  name       = "k8s-nodes-sg"
  network_id = yandex_vpc_network.network.id

  ingress {
    protocol       = "ANY"
    from_port      = 30000
    to_port        = 32767
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Региональный кластер Kubernetes
resource "yandex_kubernetes_cluster" "regional_cluster" {
  name        = "regional-k8s-cluster"
  network_id  = yandex_vpc_network.network.id

  master {
    regional {
      region = "ru-central1"

      location {
        zone      = var.default_zone
        subnet_id = yandex_vpc_subnet.public-subnet-a.id
      }

      location {
        zone      = var.zone-b
        subnet_id = yandex_vpc_subnet.public-subnet-b.id
      }

      location {
        zone      = var.zone-d
        subnet_id = yandex_vpc_subnet.public-subnet-d.id
      }
    }

    version   = "1.30"
    public_ip = true

    # security_group_ids = [yandex_vpc_security_group.k8s-master-sg.id]

    maintenance_policy {
      auto_upgrade = true
      maintenance_window {
        day        = "saturday"
        start_time = "23:00"
        duration   = "3h"
      }
    }
  }

  kms_provider {
      key_id = yandex_kms_symmetric_key.k8s-key.id
    }

  service_account_id      = yandex_iam_service_account.k8s-admin.id
  node_service_account_id = yandex_iam_service_account.k8s-nodes.id

  release_channel         = "STABLE"
  network_policy_provider = "CALICO"

  depends_on = [
    yandex_iam_service_account.k8s-admin,
    yandex_iam_service_account.k8s-nodes,
    yandex_resourcemanager_folder_iam_binding.k8s-cluster-agent,
    yandex_resourcemanager_folder_iam_binding.k8s-admin-roles,
    yandex_resourcemanager_folder_iam_binding.k8s-nodes-roles
  ]

}

# Группа узлов с автоскейлингом
resource "yandex_kubernetes_node_group" "k8s-nodes" {
  cluster_id  = yandex_kubernetes_cluster.regional_cluster.id
  name        = "k8s-nodes"
  description = "K8S worker nodes with autoscaling"

  instance_template {
    platform_id = "standard-v1"

    resources {
      memory        = 2
      cores         = 2
      core_fraction = 5
    }

    boot_disk {
      type = "network-hdd"
      size = 64
    }

    scheduling_policy {
      preemptible = var.preemptible
    }

    network_interface {
      subnet_ids = [
        yandex_vpc_subnet.public-subnet-a.id]
      nat                 = true
      # security_group_ids  = [yandex_vpc_security_group.k8s-nodes-sg.id]
    }

    metadata = {
      ssh-keys = "ubuntu:${file("~/.ssh/terraform_study.pub")}"
    }
  }

  scale_policy {
    auto_scale {
      min     = 3
      max     = 6
      initial = 3
    }
  }

  allocation_policy {
    location {
      zone = "ru-central1-a"
    }
  }

  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true
  }
}

resource "local_file" "kubeconfig" {
  filename = "${path.module}/kubeconfig.yaml"
  content = templatefile("${path.module}/kubeconfig.tpl", {
    cluster_endpoint = yandex_kubernetes_cluster.regional_cluster.master[0].external_v4_endpoint
    cluster_ca      = base64encode(yandex_kubernetes_cluster.regional_cluster.master[0].cluster_ca_certificate)
    token           = data.yandex_client_config.client.iam_token
  })
}