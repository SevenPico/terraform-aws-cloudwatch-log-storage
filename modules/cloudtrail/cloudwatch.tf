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
##  ./modules/cloudtrail/cloudwatch.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Cloudtrail Cloudwatch Context
# ------------------------------------------------------------------------------
module "cloudtrail_cloudwatch_context" {
  source  = "SevenPico/context/null"
  version = "2.0.0"
  context    = module.context.self
  attributes = ["cloudtrail"]
}

module "cloudtrail_cloudwatch_role_context" {
  source  = "SevenPico/context/null"
  version = "2.0.0"
  context    = module.cloudtrail_cloudwatch_context.self
  attributes = ["role"]
}


# ------------------------------------------------------------------------------
# Cloudtrail Cloudwatch Log Group
# ------------------------------------------------------------------------------
module "cloudtrail_cloudwatch_log_storage" {
  source  = "../../"
  context = module.cloudtrail_cloudwatch_context.self

  kms_master_key_arn      = module.kms_key.key_arn
  log_group_name_override = var.log_group_name_override
  log_retention_days      = var.log_retention_days
}


# ------------------------------------------------------------------------------
# Cloudtrail Cloudwatch IAM
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "assume_role" {
  count = module.cloudtrail_cloudwatch_context.enabled ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cloudtrail_cloudwatch_logs" {
  count              = module.cloudtrail_cloudwatch_context.enabled ? 1 : 0
  name               = module.cloudtrail_cloudwatch_role_context.id
  assume_role_policy = data.aws_iam_policy_document.assume_role[0].json
  tags               = module.cloudtrail_cloudwatch_context.tags
}


data "aws_iam_policy_document" "cloudtrail_cloudwatch_logs" {
  count = module.cloudtrail_cloudwatch_context.enabled ? 1 : 0
  statement {
    sid    = "WriteCloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${module.cloudtrail_cloudwatch_log_storage.log_group_name}:*"
    ]
  }
}

resource "aws_iam_policy" "cloudtrail_cloudwatch_logs" {
  count  = module.cloudtrail_cloudwatch_context.enabled ? 1 : 0
  name   = "${module.cloudtrail_cloudwatch_role_context.id}-policy"
  policy = data.aws_iam_policy_document.cloudtrail_cloudwatch_logs[0].json
}

resource "aws_iam_policy_attachment" "cloudtrail_cloudwatch_logs" {
  count      = module.cloudtrail_cloudwatch_context.enabled ? 1 : 0
  name       = "${aws_iam_policy.cloudtrail_cloudwatch_logs[0].name}-attachment"
  policy_arn = aws_iam_policy.cloudtrail_cloudwatch_logs[0].arn
  roles      = [aws_iam_role.cloudtrail_cloudwatch_logs[0].name]
}

