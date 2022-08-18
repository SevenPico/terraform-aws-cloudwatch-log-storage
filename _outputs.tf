output "log_group_name" {
  value = join("", aws_cloudwatch_log_group.default[*].name)
}

output "log_group_id" {
  value = join("", aws_cloudwatch_log_group.default[*].id)
}

output "log_group_arn" {
  value = join("", aws_cloudwatch_log_group.default[*].arn)
}
