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

variable "bucket_name" {
  type        = string
  default     = "bucket-are"
}

variable "service_account_id" {
  type        = string
  sensitive   = true
  default = "ajeplfmmgo62lk4c2ack"
}