# ------------------------------------------------------------------------------
# Cloudwatch Meta
# ------------------------------------------------------------------------------
module "cloudwatch_meta" {
  source  = "registry.terraform.io/cloudposse/label/null"
  version = "0.25.0"
  context = module.this.context
}


# ------------------------------------------------------------------------------
# Cloudwatch Log Group
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "default" {
  count             = module.cloudwatch_meta.enabled ? 1 : 0
  name              = var.log_group_name_override == null ? module.cloudwatch_meta.id : var.log_group_name_override
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_master_key_arn
  tags              = module.cloudwatch_meta.tags
}
