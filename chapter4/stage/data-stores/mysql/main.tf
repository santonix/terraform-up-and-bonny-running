provider "aws" {
  region = "us-east-2"
}
resource "aws_db_instance" "example" {
  identifier_prefix = "terraform-up-and-running"
  engine            = "mysql"
  allocated_storage = 10
  instance_class    = "db.t2.micro"


  username = "admin"
  # How should we set the password?
  password = var.db_password
}


terraform {
  backend "s3" {

    # Replace this with your bucket name!
    bucket = "terraform-up-and-bonny-running-state"
    key    = "stage/data-stores/mysql/terraform.tfstate"
    region = "us-east-2"

    # Replace this with your DynamoDB table name!
    dynamodb_table = "terraform-up-and-bonny-running-locks"
    encrypt        = true
  }
}  