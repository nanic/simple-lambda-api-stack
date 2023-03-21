
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    # Replace this with your bucket name!
    bucket = "tf-state-lock-bucket-nani"
    key    = "terraform.tfstate"
    region = "ap-southeast-2"

    # Replace this with your DynamoDB table name!
    dynamodb_table = "tf-state-lock"
    encrypt        = true
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-southeast-2"
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "../app/src/lambda.js"
  output_path = "lambda_function_payload.zip"
}

resource "aws_lambda_function" "sample_lambda" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "lambda_function_payload.zip"
  function_name = "lambda_function_name"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda.helloWorld"

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "nodejs16.x"

  environment {
    variables = {
    }
  }

  tags = {
    Name        = "Learning bucket"
    Environment = "Dev"
  }
}

data "aws_iam_policy_document" "assume_role_lambda" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}


resource "aws_iam_role_policy" "iam_for_lambda_policy" {
  name = "iam_for_lambda_policy"
  role = aws_iam_role.iam_for_lambda.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ],
        "Resource" : ["arn:aws:s3:::nanitf-test-bucket/*"]
      }
    ]
  })
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json
}

resource "aws_s3_bucket" "b" {
  bucket = "nanitf-test-bucket"

  tags = {
    Name        = "Learning bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_acl" "b_acl" {
  bucket = aws_s3_bucket.b.id
  acl    = "private"
}
