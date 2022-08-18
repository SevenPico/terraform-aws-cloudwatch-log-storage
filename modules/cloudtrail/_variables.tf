variable "create_kms_key" {
  type = bool
  default = false
}

variable "log_group_name_override" {
  type        = string
  default     = null
  description = ""
}

variable "log_retention_days" {
  type        = number
  default     = null
  description = 30
}

#variable "kms_key_policy_source_json" {
#  type    = string
#  default = ""
#}
