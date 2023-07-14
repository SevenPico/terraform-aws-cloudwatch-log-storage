## ----------------------------------------------------------------------------
##  Copyright 2023 SevenPico, Inc.
##
##  Licensed under the Apache License, Version 2.0 (the "License");
##  you may not use this file except in compliance with the License.
##  You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
##  Unless required by applicable law or agreed to in writing, software
##  distributed under the License is distributed on an "AS IS" BASIS,
##  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
##  See the License for the specific language governing permissions and
##  limitations under the License.
## ----------------------------------------------------------------------------

## ----------------------------------------------------------------------------
##  ./_variables.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

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

variable "s3_bucket_name" {
  type        = string
  default     = ""
  description = "The S3 Bucket name where the logs will be transferred."
}

variable "s3_bucket_access_role_arn" {
  type        = string
  default     = ""
  description = "The S3 Bucket access role arn value."
}