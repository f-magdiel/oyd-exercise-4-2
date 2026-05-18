resource "aws_s3_bucket" "order_attachments" {
  bucket = "${var.app_name}-order-attachments-${var.environment}"
  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "time_sleep" "lock_demo" {
  create_duration = "20s"
}
