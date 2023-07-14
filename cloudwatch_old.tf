# ----------------------------------------------------------------------------
#  Copyright 2023 SevenPico, Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
#  ./cloudwatch.tf
#  This file contains code written by SevenPico, Inc.
# ----------------------------------------------------------------------------

## ------------------------------------------------------------------------------
## Cloudwatch Context
## ------------------------------------------------------------------------------
#module "cloudwatch_context" {
#  source  = "SevenPico/context/null"
#  version = "2.0.0"
#  context = module.context.self
#}
#
#
## ------------------------------------------------------------------------------
## Cloudwatch Log Group
## ------------------------------------------------------------------------------
#resource "aws_cloudwatch_log_group" "default" {
#  count             = module.cloudwatch_context.enabled ? 1 : 0
#  name              = var.log_group_name_override == null ? module.cloudwatch_context.id : var.log_group_name_override
#  retention_in_days = var.log_retention_days
#  kms_key_id        = var.kms_master_key_arn
#  tags              = module.cloudwatch_context.tags
#}
