# ------------------------------------------------------------------------------
# VPC Flow Logs KMS Key Policy Meta
# ------------------------------------------------------------------------------
module "kms_key_meta" {
  source  = "registry.terraform.io/cloudposse/label/null"
  version = "0.25.0"
  context = module.vpc_flow_logs_cloudwatch_meta.context
  enabled = var.create_kms_key && module.vpc_flow_logs_cloudwatch_meta.enabled
}


# ------------------------------------------------------------------------------
# VPC Flow Logs KMS Key Policy
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "kms_key" {
  count = module.kms_key_meta.enabled ? 1 : 0
  statement {
    sid     = "Enable IAM User Permissions"
    effect  = "Allow"
    actions = ["kms:*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    resources = ["*"]
  }
  statement {
    sid     = "Allow VPC Flow Logs to encrypt logs"
    effect  = "Allow"
    actions = ["kms:GenerateDataKey*"]
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
    resources = ["*"]
#    condition {
#      test     = "StringLike"
#      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
#      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*"]
#    }
  }
  statement {
    sid     = "Allow VPC Flow Logs to describe key"
    effect  = "Allow"
    actions = ["kms:DescribeKey"]
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
    resources = ["*"]
  }
  statement {
    sid    = "Allow principals in the account to decrypt log files"
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:ReEncryptFrom",
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
#    condition {
#      test     = "StringLike"
#      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
#      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*"]
#    }
  }
  statement {
    sid     = "Allow alias creation during setup"
    effect  = "Allow"
    actions = ["kms:CreateAlias"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ec2.${data.aws_region.current.name}.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    resources = ["*"]
  }
#  statement {
#    sid    = "Enable cross account log decryption"
#    effect = "Allow"
#    actions = [
#      "kms:Decrypt",
#      "kms:ReEncryptFrom",
#    ]
#    principals {
#      type        = "AWS"
#      identifiers = ["*"]
#    }
#    condition {
#      test     = "StringEquals"
#      variable = "kms:CallerAccount"
#      values   = [data.aws_caller_identity.current.account_id]
#    }
#    condition {
#      test     = "StringLike"
#      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
#      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*"]
#    }
#    resources = ["*"]
#  }
  statement {
    sid    = "Allow logs KMS access"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]
  }
}


# ------------------------------------------------------------------------------
# VPC Flow Logs KMS Key
# ------------------------------------------------------------------------------
module "kms_key" {
  source  = "registry.terraform.io/cloudposse/kms-key/aws"
  version = "0.12.1"
  context = module.kms_key_meta.context

  description             = "KMS key for VPC Flow Logs in Cloudwatch."
  deletion_window_in_days = 10
  enable_key_rotation     = true
  policy                  = join("", data.aws_iam_policy_document.kms_key.*.json)
}