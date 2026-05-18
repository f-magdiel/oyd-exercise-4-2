resource "aws_s3_bucket" "order_attachments" {
  bucket = "${var.app_name}-order-attachments-${var.environment}"
  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
