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

# ------------------------------------------------------------------------------
# Cloudwatch Context
# ------------------------------------------------------------------------------
module "cloudwatch_context" {
  source  = "SevenPico/context/null"
  version = "2.0.0"
  context = module.context.self
}


# ------------------------------------------------------------------------------
# Cloudwatch Log Group
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "default" {
  count             = module.cloudwatch_context.enabled ? 1 : 0
  name              = var.log_group_name_override == null ? module.cloudwatch_context.id : var.log_group_name_override
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_master_key_arn
  tags              = module.cloudwatch_context.tags

}


# ------------------------------------------------------------------------------
# S3 Bucket for CloudWatch Logs
# ------------------------------------------------------------------------------
#locals {
#  bucket_name = var.bucket_name == null || var.bucket_name == "" ? module.context.id : var.bucket_name
#}
#
#module "cloudwatch_logs_bucket" {
#  source     = "SevenPicoForks/s3-bucket/aws"
#  version    = "4.0.6"
#  context    = module.context.self
#  attributes = ["cw", "log", "management"]
#
#  acl                          = var.acl
#  allow_encrypted_uploads_only = var.allow_encrypted_uploads_only
#  allow_ssl_requests_only      = var.allow_ssl_requests_only
#  allowed_bucket_actions = [
#    "s3:PutObject",
#    "s3:PutObjectAcl",
#    "s3:GetObject",
#    "s3:DeleteObject",
#    "s3:ListBucket",
#    "s3:ListBucketMultipartUploads",
#    "s3:GetBucketLocation",
#    "s3:AbortMultipartUpload"
#  ]
#  block_public_acls             = var.block_public_acls
#  block_public_policy           = var.block_public_policy
#  bucket_key_enabled            = var.bucket_key_enabled
#  bucket_name                   = local.bucket_name
#  cors_rule_inputs              = null
#  enable_mfa_delete             = var.enable_mfa_delete
#  force_destroy                 = var.force_destroy
#  grants                        = []
#  ignore_public_acls            = var.ignore_public_acls
#  kms_master_key_arn            = var.kms_master_key_arn
#  lifecycle_configuration_rules = var.lifecycle_configuration_rules
#  logging = var.access_log_bucket_name != null && var.access_log_bucket_name != "" ? {
#    bucket_name = var.access_log_bucket_name
#    prefix      = var.access_log_bucket_prefix_override == null ? "${join("", data.aws_caller_identity.current[*].account_id)}/${module.context.id}/" : (var.access_log_bucket_prefix_override != "" ? "${var.access_log_bucket_prefix_override}/" : "")
#  } : null
#  object_lock_configuration     = null
#  privileged_principal_actions  = []
#  privileged_principal_arns     = []
#  restrict_public_buckets       = var.restrict_public_buckets
#  s3_object_ownership           = "BucketOwnerEnforced"
#  s3_replica_bucket_arn         = ""
#  s3_replication_enabled        = var.s3_replication_enabled
#  s3_replication_rules          = var.s3_replication_rules
#  s3_replication_source_roles   = var.s3_replication_source_roles
#  source_policy_documents       = var.source_policy_documents
#  sse_algorithm                 = var.sse_algorithm
#  transfer_acceleration_enabled = false
#  user_enabled                  = false
#  versioning_enabled            = var.enable_versioning
#  website_inputs                = null
#}


# ------------------------------------------------------------------------------
# CloudWatch Log Group Subscription Filter and Role
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "cloudwatch_logs_policy" {
  count = module.context.enabled && var.enable_s3_archive ? 1 : 0
  statement {
    actions = [
      "logs:CreateExportTask",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    actions = [
      "s3:PutObject",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket"
    ]
    effect = "Allow"
    resources = [
      "${var.s3_archive_bucket_arn}/*",
      var.s3_archive_bucket_arn
    ]
  }
}

module "iam_role" {
  source     = "SevenPicoForks/iam-role/aws"
  version    = "2.0.1"
  context    = module.context.self
  enabled    = module.context.enabled && var.enable_s3_archive
  attributes = ["cw", "logs", "management", "role"]

  role_description         = "Role to archive cloudwatch logs to s3 Bucket the canaries"
  additional_tag_map       = {}
  assume_role_actions      = ["sts:AssumeRole"]
  assume_role_conditions   = []
  in_line_policies         = {}
  instance_profile_enabled = false
  managed_policy_arns      = []
  policy_description       = ""
  policy_document_count    = 1
  policy_documents         = [try(data.aws_iam_policy_document.cloudwatch_logs_policy[0].json, "")]
  principals = {
    Service = ["logs.amazonaws.com"]
  }
  use_fullname = true
}

resource "aws_cloudwatch_log_subscription_filter" "default" {
  count           = module.cloudwatch_context.enabled && var.enable_s3_archive ? 1 : 0
  name            = module.cloudwatch_context.id
  log_group_name  = aws_cloudwatch_log_group.default[0].name
  filter_pattern  = var.s3_archive_filter_pattern
  destination_arn = var.s3_archive_bucket_arn
  role_arn        = module.iam_role.arn
}