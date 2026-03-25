output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "environment" {
  description = "Current environment"
  value       = var.environment
}

output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "ec2_instance_id" {
  description = "Instance ID of the EC2"
  value       = aws_instance.web.id
}

output "ec2_key_name" {
  description = "Key pair name used by the EC2 instance"
  value       = aws_instance.web.key_name
}

output "ec2_private_key_pem" {
  description = "Private key PEM (only set when auto-generated; save this to SSH into the instance)"
  value       = var.key_name == "" ? tls_private_key.web[0].private_key_pem : null
  sensitive   = true
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket (if created)"
  value       = var.create_s3_bucket ? aws_s3_bucket.this[0].bucket : null
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket (if created)"
  value       = var.create_s3_bucket ? aws_s3_bucket.this[0].arn : null
}
