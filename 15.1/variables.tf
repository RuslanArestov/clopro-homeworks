variable "username" {
  type    = string
  default = "user_admin"
}

variable "ssh_public_key" {
  type    = string
  default = "~/.ssh/terraform_study.pub"
}

variable "name-vps" {
  type    = string
  default = "network-vpc"
}

variable "name-subnet-public" {
  type    = string
  default = "public"
}

variable "name-subnet-private" {
  type    = string
  default = "private"
}

variable "default_zone" {
  type        = string
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
  default     = "ru-central1-a"
}

variable "destination_prefix" {
  type    = string
  default = "0.0.0.0/0"
}

variable "public_subnet_cidr" {
  type    = string
  default = "192.168.10.0/24"
}

variable "private_subnet_cidr" {
  type    = string
  default = "192.168.20.0/24"
}

variable "nat_instance_name" {
  type    = string
  default = "nat-instance"
}

variable "vm_public_name" {
  type    = string
  default = "public-vm"
}

variable "vm_private_name" {
  type    = string
  default = "private-vm"
}

variable "platform_id" {
  type    = string
  default = "standard-v1"
}

variable "nat_instance_family" {
  type    = string
  default = "nat-instance-ubuntu-2204"
}

variable "vm_image_family" {
  type    = string
  default = "fd81hgrcv6lsnkremf32"
}

variable "nat_instance_public_ip" {
  type    = string
  default = "192.168.10.254"
}

variable "nat_instance_private_ip" {
  type    = string
  default = "192.168.20.254"
}

variable "disk_size" {
  type    = number
  default = 10
}

variable "disk_type" {
  type    = string
  default = "network-hdd"
}

variable "cpu_cores" {
  type    = number
  default = 2
}

variable "memory" {
  type    = number
  default = 2
}

variable "core_fraction" {
  type    = number
  default = 5
}

variable "preemptible" {
  type    = bool
  default = true
}
