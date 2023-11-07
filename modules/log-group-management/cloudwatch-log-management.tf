# ------------------------------------------------------------------------------
# Lambda Function to Clean up Stale Logstreams
# ------------------------------------------------------------------------------
data "archive_file" "log_management_lambda" {
  count       = module.context.enabled ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/cw-log-management/"
  output_path = "./temp/log-management.zip"
}

module "log_management_lambda" {
  source     = "SevenPicoForks/lambda-function/aws"
  version    = "2.0.0"
  context    = module.context.self
  attributes = ["lambda"]

  architectures                       = null
  cloudwatch_event_rules              = {}
  cloudwatch_lambda_insights_enabled  = false
  cloudwatch_logs_kms_key_arn         = ""
  cloudwatch_logs_retention_in_days   = var.log_retention_days
  cloudwatch_log_subscription_filters = {}
  description                         = "Deletes log streams that are empty and older then the log events retention period."
  event_source_mappings               = {}
  filename                            = "log-management.zip"
  source_code_hash                    = filebase64sha256(data.archive_file.log_management_lambda[0].output_path)
  function_name                       = "${module.context.id}-cloudwatch-log-management"
  handler                             = "lambda"
  ignore_external_function_updates    = false
  image_config                        = {}
  image_uri                           = null
  kms_key_arn                         = ""
  lambda_at_edge                      = false
  lambda_environment = {
    variables = {
      purge_non_empty = "False",
      dry_run         = "True"
    }
  }
  layers                         = []
  memory_size                    = 512
  package_type                   = "Zip"
  publish                        = false
  reserved_concurrent_executions = 10
  role_name                      = module.iam_role.name
  runtime                        = "python3.9"
  s3_bucket                      = null
  s3_key                         = null
  s3_object_version              = null
  sns_subscriptions              = {}
  ssm_parameter_names            = null
  timeout                        = 60
  tracing_config_mode            = "Active"
  vpc_config                     = null
}


resource "aws_lambda_alias" "log_management_alias" {
  count            = module.context.enabled ? 1 : 0
  name             = "${module.context.id}-cloudwatch-log-management-alias"
  description      = "Deletes log streams that are empty and older then the log events retention period."
  function_name    = module.log_management_lambda.function_name
  function_version = "$LATEST"
}


# ------------------------------------------------------------------------------
# Lambda Role
# ------------------------------------------------------------------------------
module "iam_role" {
  source     = "SevenPicoForks/iam-role/aws"
  version    = "2.0.1"
  context    = module.context.self
  enabled    = module.context.enabled
  attributes = ["cw", "logs", "management", "role"]

  role_description         = "Lambda Role "
  additional_tag_map       = {}
  assume_role_actions      = ["sts:AssumeRole"]
  assume_role_conditions   = []
  in_line_policies         = {}
  instance_profile_enabled = false
  managed_policy_arns      = []
  policy_description       = ""
  policy_document_count    = 1
  policy_documents         = [try(data.aws_iam_policy_document.lambda_log_management_policy_doc[0].json, "")]
  principals = {
    Service = ["events.amazonaws.com", "lambda.amazonaws.com"]
  }
  use_fullname = true
}

data "aws_iam_policy_document" "lambda_log_management_policy_doc" {
  count = module.context.enabled ? 1 : 0

  version = "2012-10-17"
  statement {
    actions = [
      "lambda:InvokeFunction",
      "lambda:InvokeAsync"
    ]
    effect = "Allow"
    resources = [
      module.log_management_lambda.arn,
      "${module.log_management_lambda.arn}:${aws_lambda_alias.log_management_alias[0].name}",
    ]
  }
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutRetentionPolicy",
      "logs:DeleteLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    effect    = "Allow"
    resources = ["arn:aws:logs:*:*:*"]
    sid       = "LambdaLogstreamCleanup"
  }
  statement {
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets",
      "xray:GetSamplingStatisticSummaries"
    ]
    effect    = "Allow"
    resources = ["*"]
    sid       = "ActiveTracing"
  }
}


# ------------------------------------------------------------------------------
# Use Cloudwatch Event to Run Nightly
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "log_management_event_rule" {
  count               = module.context.enabled ? 1 : 0
  name                = "${module.context.id}-cloudwatch-log-management-rule"
  description         = "Clean up Cloudwatch Logs Nightly"
  schedule_expression = "cron(0 0 * * ? *)"
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "log_management_scheduled_task" {
  count     = module.context.enabled ? 1 : 0
  target_id = "${module.context.id}-run-cloudwatch-log-management-nightly"
  arn       = aws_lambda_alias.log_management_alias[0].arn
  rule      = aws_cloudwatch_event_rule.log_management_event_rule[0].name
  input     = <<DOC
{
  "dry_run": false,
  "purge_non_empty": true,
  "days": ${var.log_retention_days}
}
DOC
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_log_cleanup" {
  count         = module.context.enabled ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.log_management_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.log_management_event_rule[0].arn
  qualifier     = aws_lambda_alias.log_management_alias[0].name
}
