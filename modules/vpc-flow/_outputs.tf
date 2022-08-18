output "log_group_id" {
  value = module.vpc_flow_logs_cloudwatch_log_storage.log_group_id
}

output "log_group_name" {
  value = module.vpc_flow_logs_cloudwatch_log_storage.log_group_name
}

output "log_group_arn" {
  value = module.vpc_flow_logs_cloudwatch_log_storage.log_group_arn
}

output "log_group_role_arn" {
  value = join("", aws_iam_role.vpc_flow_logs_cloudwatch_logs[*].arn)
}

output "kms_key_arn" {
  value       = module.kms_key.key_arn
  description = "Key ARN"
}

output "kms_key_id" {
  value       = module.kms_key.key_id
  description = "Key ID"
}

output "kms_key_alias_arn" {
  value       = module.kms_key.alias_arn
  description = "Alias ARN"
}

output "kms_key_alias_name" {
  value       = module.kms_key.alias_name
  description = "Alias name"
}



