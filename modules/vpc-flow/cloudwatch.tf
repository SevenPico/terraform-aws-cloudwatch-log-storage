# ------------------------------------------------------------------------------
# VPC Flow Log Cloudwatch Meta
# ------------------------------------------------------------------------------
module "vpc_flow_logs_cloudwatch_meta" {
  source     = "registry.terraform.io/cloudposse/label/null"
  version    = "0.25.0"
  context    = module.this.context
  attributes = ["vpc-flow-logs"]
}

module "vpc_flow_logs_cloudwatch_role_meta" {
  source     = "registry.terraform.io/cloudposse/label/null"
  version    = "0.25.0"
  context    = module.vpc_flow_logs_cloudwatch_meta.context
  attributes = ["role"]
}


# ------------------------------------------------------------------------------
# VPC Flow Log Cloudwatch Log Group
# ------------------------------------------------------------------------------
module "vpc_flow_logs_cloudwatch_log_storage" {
  source  = "../../"
  context = module.vpc_flow_logs_cloudwatch_meta

  kms_master_key_arn      = module.kms_key.key_arn
  log_group_name_override = var.log_group_name_override
  log_retention_days      = var.log_retention_days
}


# ------------------------------------------------------------------------------
# VPC Flow Log Cloudwatch IAM
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "assume_role" {
  count = module.vpc_flow_logs_cloudwatch_meta.enabled ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "vpc_flow_logs_cloudwatch_logs" {
  count              = module.vpc_flow_logs_cloudwatch_meta.enabled ? 1 : 0
  name               = module.vpc_flow_logs_cloudwatch_role_meta.id
  assume_role_policy = data.aws_iam_policy_document.assume_role[0].json
  tags               = module.vpc_flow_logs_cloudwatch_meta.tags
}


data "aws_iam_policy_document" "vpc_flow_logs_cloudwatch_logs" {
  count = module.vpc_flow_logs_cloudwatch_meta.enabled ? 1 : 0
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
      "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${module.vpc_flow_logs_cloudwatch_log_storage.log_group_name}:*"
    ]
  }
}

resource "aws_iam_policy" "vpc_flow_logs_cloudwatch_logs" {
  count  = module.vpc_flow_logs_cloudwatch_meta.enabled ? 1 : 0
  name   = "${module.vpc_flow_logs_cloudwatch_role_meta.id}-policy"
  policy = data.aws_iam_policy_document.vpc_flow_logs_cloudwatch_logs[0].json
}

resource "aws_iam_policy_attachment" "vpc_flow_logs_cloudwatch_logs" {
  count      = module.vpc_flow_logs_cloudwatch_meta.enabled ? 1 : 0
  name       = "${aws_iam_policy.vpc_flow_logs_cloudwatch_logs[0].name}-attachment"
  policy_arn = aws_iam_policy.vpc_flow_logs_cloudwatch_logs[0].arn
  roles      = [aws_iam_role.vpc_flow_logs_cloudwatch_logs[0].name]
}

