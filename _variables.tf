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

variable "kms_master_key_arn" {
  type        = string
  default     = ""
  description = "The AWS KMS master key ARN used for the SSE-KMS encryption."
}
