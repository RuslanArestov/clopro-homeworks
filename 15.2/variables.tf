variable "default_zone" {
  type        = string
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
  default     = "ru-central1-a"
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

variable "service_account_key_file" {
  type        = string
  default     = "./key.json"
}

variable "bucket_name" {
  type        = string
  default     = "bucket-are"
}

variable "bucket_image_path" {
  type        = string
  default     = "cat.png"
}

variable "network_name" {
  type        = string
  default     = "network"
}

variable "subnet_cidr" {
  type        = string
  default     = "192.168.10.0/24"
}

variable "instance_image_id" {
  type        = string
  default     = "fd827b91d99psvq5fjit"
}

variable "instance_count" {
  type        = number
  default     = 3
}

variable "service_account_id" {
  type        = string
  sensitive   = true
}