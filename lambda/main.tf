provider "aws" {
	region = "us-east-1"
}

resource "aws_s3_bucket" "inbound" {
	bucket = "devopsdc-inbound"
	acl = "private"
	tags = {
		Name = "DevOpsDC Test Bucket"
		X-Project = "aleff devopsdc"
	}
}

resource "aws_dynamodb_table" "filedata" {
	name = "DevOpsDCFileData"
	read_capacity = 20
	write_capacity = 20
	hash_key = "UUID"
	attribute {
		name = "UUID"
		type = "S"
	}
}

resource "aws_lambda_function" "s3_to_dynamo" {
	function_name = "devopsdc-s3-to-dynamo"
	filename = "./function/lambda.zip"
	role = "${aws_iam_role.lambda_exec.arn}"
	runtime = "python2.7"
	handler = "process.do_stuff"
}

### boring IAM stuff below

resource "aws_iam_role" "lambda_exec" {
	name = "devopsdc-lambda-exec"
	assume_role_policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
		{
		  "Action": "sts:AssumeRole",
		  "Principal": {
		    "Service": "lambda.amazonaws.com"
		  },
		  "Effect": "Allow"
		}
	]
}
EOF
}

resource "aws_iam_role_policy" "lambda_to_cloudwatch" {
	name = "devopsdc-lambda-to-cloudwatch"
	role = "${aws_iam_role.lambda_exec.id}"
	policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Action": [
				"logs:CreateLogGroup",
				"logs:CreateLogStream",
				"logs:PutLogEvents"
			],
			"Effect": "Allow",
			"Resource": "arn:aws:logs:*:*:*"
		}
	]
}
EOF
}

resource "aws_iam_role_policy" "lambda_to_dynamodb" {
	name = "devopsdc-lambda-to-dynamodb"
	role = "${aws_iam_role.lambda_exec.id}"
	policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Action": [
				"dynamodb:PutItem"
			],
			"Effect": "Allow",
			"Resource": "${aws_dynamodb_table.filedata.arn}"
		}
	]
}
EOF
}

resource "aws_iam_role" "s3_invoke" {
	name = "devopsdc-s3-invoke"
	assume_role_policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Action": "sts:AssumeRole",
			"Principal": {
				"Service": "s3.amazonaws.com"
			},
			"Effect": "Allow",
			"Sid": ""
		}
	]
}
EOF
}
