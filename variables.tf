variable "name" {
  default     = "MediaWiki"
  type        = string
  description = "Name of the VPC"
}

variable "project" {
  type        = string
  default     = "MediaWiki-project"
  description = "Name of project this VPC is meant to house"
}

variable "environment" {
  type        = string
  default     = "Blue"
  description = "Name of environment this VPC is targeting - Blue/Green"
}

variable "access_key" {
  default     = "youraceskey"
  type        = string
  description = "access key of the account"
}

variable "secret_key" {
  default     = "yoursecretkey"
  type        = string
  description = "secret key of the account"
}

variable "region" {
  default     = "ap-south-1"
  type        = string
  description = "Region of the VPC"
}

variable "keyname" {
  type        = string
  default     = "mediawiki"
  description = "EC2 Key pair name for the bastion"
}

variable "cidr_block" {
  default     = "10.0.0.0/16"
  type        = string
  description = "CIDR block for the VPC"
}

variable "public_subnet_cidr_blocks" {
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
  type        = list
  description = "List of public subnet CIDR blocks"
}

variable "private_subnet_cidr_blocks" {
  default     = ["10.0.2.0/24","10.0.3.0/24"]
  type        = list
  description = "List of private subnet CIDR blocks"
}

variable "availability_zones" {
  default     = ["ap-south-1a", "ap-south-1b"]
  type        = list
  description = "List of availability zones"
}

variable "ami" {
  type        = string
  default     = "ami-026f33d38b6410e30"
  description = "Bastion Amazon Machine Image (AMI) ID"
}

variable "ebs_optimized" {
  default     = false
  type        = bool
  description = "If true, the bastion instance will be EBS-optimized"
}

variable "instance_type" {
  default     = "t2.micro"
  type        = string
  description = "Instance type for bastion instance"
}

variable "tags" {
  default     = {}
  type        = map(string)
  description = "Extra tags to attach to the VPC resources"
}