terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "beyond-diplegia-tfstate"
    key    = "prod/terraform.tfstate"
    region = "eu-west-3"
    encrypt = true
  }
}

provider "aws" {
  region = var.region
}
