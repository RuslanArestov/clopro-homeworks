variable "default_zone" {
  type        = string
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
  default     = "ru-central1-a"
}

variable "zone-b" {
  type        = string
  default     = "ru-central1-b"
}

variable "zone-d" {
  type        = string
  default     = "ru-central1-d"
}

variable "service_account_id" {
  type        = string
  sensitive   = true
  default = "ajeplfmmgo62lk4c2ack"
}

variable "network_name" {
  type        = string
  default     = "network"
}

variable "subnet_cidr-a" {
  type        = string
  default     = "192.168.10.0/24"
}

variable "subnet_cidr-b" {
  type        = string
  default     = "192.168.20.0/24"
}

variable "subnet_cidr-d" {
  type        = string
  default     = "192.168.30.0/24"
}

variable "public-subnet_cidr-a" {
  type        = string
  default     = "192.168.40.0/24"
}

variable "public-subnet_cidr-b" {
  type        = string
  default     = "192.168.50.0/24"
}

variable "public-subnet_cidr-d" {
  type        = string
  default     = "192.168.60.0/24"
}

variable "folder_id" {
  type        = string
  sensitive   = true
  default = "b1ge6bvcgcf6f5fdolhp"
}

variable "preemptible" {
  type    = bool
  default = true
}