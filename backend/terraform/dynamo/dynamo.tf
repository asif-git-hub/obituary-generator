provider "aws" {
  region = "ap-south-1"
  access_key = "TOP_SECRET"
  secret_key = "TOP_SECRET"
}

resource "aws_dynamodb_table" "dynamodb" {
  name           = "prod-obituary-data-3043657"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "id"
  range_key      = "created_at"

  attribute {
    name = "id"
    type = "S"
  }
  attribute {
    name = "created_at"
    type = "S"
  }
  tags = {
    Environment = "prod"
  }
}