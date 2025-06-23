# Создание бакета с основными настройками
resource "yandex_storage_bucket" "bucket" {
  bucket     = "bucket-are" 
  acl        = "public-read"               
  max_size   = 1073741824
  force_destroy = true      # Удаление непустого бакета (только для тестов и учёбы)        

  # Включение версионирования
  versioning {
    enabled = true
  }

}

# Создание сети и подсети
resource "yandex_vpc_network" "network" {
  name = "network"
}

resource "yandex_vpc_subnet" "public-subnet" {
  name           = "public-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

# Security Group
resource "yandex_vpc_security_group" "web-sg" {
  name        = "web-sg"
  network_id  = yandex_vpc_network.network.id

  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # Обязательные диапазоны для health checks ALB
  ingress {
    protocol       = "TCP"
    port           = 30080
    v4_cidr_blocks = ["198.18.235.0/24", "198.18.248.0/24"]
  }

  egress {
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Шаблон user_data для LAMP с заменой содержимого основной страницы
data "template_file" "cloudinit_lamp" {
  template = <<-EOF
    #!/bin/bash
    echo '<!DOCTYPE html>
    <html>
    <head>
        <title>LAMP on Yandex Cloud</title>
    </head>
    <body>
        <h1>Welcome to LAMP Stack</h1>
        <img src="https://storage.yandexcloud.net/bucket-are/cat.png" alt="Image from bucket">
    </body>
    </html>' > /var/www/html/index.html
    systemctl restart apache2
  EOF
}

# Instance Group с привязкой только к ALB
resource "yandex_compute_instance_group" "lamp_group" {
  name                = "lamp-instance-group"
  folder_id           = "b1ge6bvcgcf6f5fdolhp"
  service_account_id  = "ajeplfmmgo62lk4c2ack"
  deletion_protection = false

  instance_template {
    platform_id = "standard-v1"
    name        = "lamp-{instance.index}"
    
    resources {
      memory = 2
      cores  = 2
      core_fraction = 5
    }

    boot_disk {
      initialize_params {
        image_id = "fd827b91d99psvq5fjit"
        size     = 20
      }
    }

    scheduling_policy {
    preemptible = var.preemptible
  }

    network_interface {
      subnet_ids = [yandex_vpc_subnet.public-subnet.id]
      nat       = true
      security_group_ids = [yandex_vpc_security_group.web-sg.id]
    }

    metadata = {
      user-data = data.template_file.cloudinit_lamp.rendered
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    zones = ["ru-central1-a"]
  }

  deploy_policy {
    max_unavailable = 1
    max_expansion   = 0
  }

  # Только Application Load Balancer
  application_load_balancer {
    target_group_name        = "lamp-target-group"
    target_group_description = "Target group for ALB"
  }

  health_check {
    interval = 30
    timeout  = 10
    http_options {
      port = 80
      path = "/"
    }
  }
}

# Backend Group для ALB
resource "yandex_alb_backend_group" "lamp_backend" {
  name = "lamp-backend-group"

  http_backend {
    name             = "lamp-http-backend"
    weight           = 1
    port             = 80
    target_group_ids = [yandex_compute_instance_group.lamp_group.application_load_balancer[0].target_group_id]
    
    healthcheck {
      timeout             = "10s"
      interval            = "2s"
      healthy_threshold   = 5
      unhealthy_threshold = 3
      http_healthcheck {
        path = "/"
      }
    }
  }
}

# HTTP Router
resource "yandex_alb_http_router" "lamp_router" {
  name = "lamp-http-router"
}

# Virtual Host
resource "yandex_alb_virtual_host" "lamp_host" {
  name           = "lamp-virtual-host"
  http_router_id = yandex_alb_http_router.lamp_router.id

  route {
    name = "lamp-route"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.lamp_backend.id
        timeout          = "60s"
      }
    }
  }
}

# Application Load Balancer
resource "yandex_alb_load_balancer" "lamp_alb" {
  name               = "lamp-alb"
  network_id         = yandex_vpc_network.network.id
  security_group_ids = [yandex_vpc_security_group.web-sg.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.public-subnet.id
    }
  }

  listener {
    name = "http-listener"
    endpoint {
      address {
        external_ipv4_address {}
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.lamp_router.id
      }
    }
  }
}

output "alb_ip" {
  value = yandex_alb_load_balancer.lamp_alb.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
}