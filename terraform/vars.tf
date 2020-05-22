variable "aws_region" {
    default = "us-west-2"
}

variable "aws_access_key" {
    description = "The AWS access key"
}

variable "aws_secret_key" {
    description = "The AWS secret key"
}

variable "site_name" {
    description = "The DNS domain of the site we are creating"
}

provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
}