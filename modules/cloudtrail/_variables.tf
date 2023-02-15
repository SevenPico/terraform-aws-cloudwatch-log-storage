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
##  ./modules/cloudtrail/_variables.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

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


variable "kms_key_deletion_window_in_days" {
  type    = number
  default = 30
}

variable "kms_key_enable_key_rotation" {
  type    = bool
  default = true
}
