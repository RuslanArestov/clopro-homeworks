resource "yandex_vpc_network" "network" {
  name = var.name-vps
}

resource "yandex_vpc_subnet" "public" {
  name           = var.name-subnet-public
  zone           = var.default_zone
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = [var.public_subnet_cidr]
}

resource "yandex_vpc_subnet" "private" {
  name           = var.name-subnet-private
  zone           = var.default_zone
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = [var.private_subnet_cidr]
  route_table_id = yandex_vpc_route_table.nat_route.id
}

resource "yandex_vpc_route_table" "nat_route" {
  network_id = yandex_vpc_network.network.id

  static_route {
    destination_prefix = var.destination_prefix
    next_hop_address  = var.nat_instance_public_ip
  }
}

resource "yandex_compute_instance" "nat_instance" {
  name        = var.nat_instance_name
  platform_id = var.platform_id
  zone        = var.default_zone

  resources {
    cores         = var.cpu_cores
    memory        = var.memory
    core_fraction = var.core_fraction
  }

  scheduling_policy {
    preemptible = var.preemptible
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.nat_image.id
      size   = var.disk_size
      type   = var.disk_type
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.public.id
    ip_address = var.nat_instance_public_ip
    nat        = true
  }

  metadata = {
    user-data = data.template_file.userdata.rendered
  }
}

resource "yandex_compute_instance" "vm-public" {
  name        = var.vm_public_name
  platform_id = var.platform_id
  zone        = var.default_zone

  resources {
    cores         = var.cpu_cores
    memory        = var.memory
    core_fraction = var.core_fraction
  }

  scheduling_policy {
    preemptible = var.preemptible
  }

  boot_disk {
    initialize_params {
      image_id = var.vm_image_family
      size     = var.disk_size
      type     = var.disk_type
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public.id
    nat       = true
  }

  metadata = {
    user-data = data.template_file.userdata.rendered
  }
}

resource "yandex_compute_instance" "vm-private" {
  name        = var.vm_private_name
  platform_id = var.platform_id
  zone        = var.default_zone

  resources {
    cores         = var.cpu_cores
    memory        = var.memory
    core_fraction = var.core_fraction
  }

  scheduling_policy {
    preemptible = var.preemptible
  }

  boot_disk {
    initialize_params {
      image_id = var.vm_image_family
      size     = var.disk_size
      type     = var.disk_type
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.private.id
  }

  metadata = {
    user-data = data.template_file.userdata.rendered
  }
}

data "template_file" "userdata" {
  template = file("${path.module}/cloud-init.yml")
  vars = {
    username     = var.username
    ssh_public_key = file(var.ssh_public_key)
  }
}

data "yandex_compute_image" "nat_image" {  
    family = var.nat_instance_family
} 