output "ec2_instance_profile_name" {
  description = "Name of the instance profile to attach to EC2 instances (consumed by the ec2 module)."
  value       = aws_iam_instance_profile.ec2.name
}

output "ec2_instance_profile_arn" {
  description = "ARN of the EC2 instance profile."
  value       = aws_iam_instance_profile.ec2.arn
}

output "ec2_role_arn" {
  description = "ARN of the EC2 IAM role."
  value       = aws_iam_role.ec2.arn
}

output "ec2_role_name" {
  description = "Name of the EC2 IAM role."
  value       = aws_iam_role.ec2.name
}

output "ec2_policy_arn" {
  description = "ARN of the least-privilege policy attached to the EC2 role."
  value       = aws_iam_policy.ec2.arn
}
