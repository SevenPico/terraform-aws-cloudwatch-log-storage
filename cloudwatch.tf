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
resource "aws_s3_bucket" "cloudwatch_logs_bucket" {
  bucket = var.s3_bucket_name

  lifecycle_rule {
      id      = "CloudWatchLogsTransitionToGlacier"
      enabled = true
      transition  {
        days          = var.log_retention_days - 1
        storage_class = "GLACIER"
      }
  }

  tags = {
    Name = "CloudWatchLogsBucket"
  }
}

# ------------------------------------------------------------------------------
# CloudWatch Log Stream
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_log_stream" "default" {
  count             = module.cloudwatch_context.enabled ? 1 : 0
  name              = module.cloudwatch_context.id
  log_group_name    = aws_cloudwatch_log_group.default[count.index].name
}

# ------------------------------------------------------------------------------
# CloudWatch Log Stream Export to S3
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_log_stream" "export_to_s3" {
  count                = module.cloudwatch_context.enabled ? 1 : 0
  name                 = module.cloudwatch_context.id
  log_group_name       = aws_cloudwatch_log_group.default[count.index].name
  depends_on           = [aws_cloudwatch_log_group.default, aws_s3_bucket.cloudwatch_logs_bucket]
}

# ------------------------------------------------------------------------------
# CloudWatch Log Group Subscription Filter
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_log_subscription_filter" "default" {
  count                = module.cloudwatch_context.enabled ? 1 : 0
  name                 = module.cloudwatch_context.id
  log_group_name       = aws_cloudwatch_log_group.default[count.index].name
  filter_pattern       = ""
  destination_arn      = aws_s3_bucket.cloudwatch_logs_bucket.arn
  role_arn             = var.s3_bucket_access_role_arn
  depends_on           = [aws_cloudwatch_log_group.default, aws_s3_bucket.cloudwatch_logs_bucket]
}
