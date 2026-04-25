terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state — uncomment AFTER creating the S3 bucket and DynamoDB table (Step 33).
  # Replace the bucket name with your actual bucket name.
  #
  # backend "s3" {
  #   bucket         = "cicd-lab-tfstate-ka-lm-abc123"
  #   key            = "prod/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "cicd-lab-tflocks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.region
}
