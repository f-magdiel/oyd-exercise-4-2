output "bucket_name" {
  description = "The S3 bucket name"
  value       = aws_s3_bucket.state_bucket.bucket
}

output "dynamodb_table_name" {
  description = "The DynamoDB table name"
  value       = aws_dynamodb_table.lock_table.name
}
