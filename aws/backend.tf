terraform {
  backend "s3" {
    bucket = "jmeter-terraform-state-new"  # New bucket name
    key    = "env/terraform.tfstate"
    region = "us-east-1"
  }
}