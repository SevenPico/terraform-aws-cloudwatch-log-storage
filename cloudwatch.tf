# ------------------------------------------------------------------------------
# Cloudwatch Context
# ------------------------------------------------------------------------------
module "cloudwatch_context" {
  source  = "app.terraform.io/SevenPico/context/null"
  version = "1.0.2"
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
