terraform {
  backend "s3" {
    bucket         = "oyd-tf-orders-tfstate"
    key            = "orders/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "oyd-tf-orders-locks"
    encrypt        = true
  }
}
