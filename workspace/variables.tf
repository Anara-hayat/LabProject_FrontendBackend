variable "aws_region" {}
variable "env_prefix" {}
variable "vpc_cidr_block" {}
variable "subnet_cidr_block" {}
variable "availability_zone" {}
variable "instance_type" {}
variable "ami_id" {}
variable "key_name" {
  description = "AWS EC2 key pair name"
  type        = string
}
variable "public_key_path" {
  description = "Path to public SSH key"
  type        = string
}
variable "private_key_path" {
  description = "Path to private SSH key"
  type        = string
}