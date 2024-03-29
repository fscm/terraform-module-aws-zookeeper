#
# Variables for the Apache Zookeeper terraform module.
#
# Copyright 2016-2022, Frederico Martins
#   Author: Frederico Martins <http://github.com/fscm>
#
# SPDX-License-Identifier: MIT
#
# This program is free software. You can use it and/or modify it under the
# terms of the MIT License.
#

variable "ami_name" {
  description = "The name of the AMI to use for the instance(s)."
  default     = "zookeeper"
  type        = "string"
}

variable "ami_prefix" {
  description = "The prefix of the AMI to use for the instance(s)."
  default     = ""
  type        = "string"
}

variable "associate_public_ip_address" {
  description = "Associate a public IP address to the Apache Zookeeper instance(s)."
  default     = false
  type        = "string"
}

variable "domain" {
  description = "The domain name to use for the Apache Zookeeper instance(s)."
  type        = "string"
}

variable "extra_security_group_id" {
  description = "Extra security group to assign to the Apache Zookeeper instance(s) (e.g.: 'sg-3f983f98')."
  default     = ""
  type        = "string"
}

variable "heap_size" {
  description = "The heap size for the Apache Zookeeper instance(s) (e.g.: '1G')."
  default     = ""
  type        = "string"
}

variable "instance_type" {
  description = "The type of instance to use for the Apache Zookeeper instance(s)."
  default     = "t2.small"
  type        = "string"
}

variable "keyname" {
  description = "The SSH key name to use for the Apache Zookeeper instance(s)."
  type        = "string"
}

variable "name" {
  description = "The main name that will be used for the Apache Zookeeper instance(s)."
  default     = "zookeeper"
  type        = "string"
}

variable "number_of_instances" {
  description = "Number of Apache Zookeeper instances."
  default     = "1"
  type        = "string"
}

variable "prefix" {
  description = "A prefix to prepend to the Apache Zookeeper instance(s) name."
  default     = ""
  type        = "string"
}

variable "private_zone_id" {
  description = "The ID of the hosted zone for the private DNS record(s)."
  default     = ""
  type        = "string"
}

variable "public_zone_id" {
  description = "The ID of the hosted zone for the public DNS record(s)."
  default     = ""
  type        = "string"
}

variable "root_volume_iops" {
  description = "The amount of provisioned IOPS (for 'io1' type only)."
  default     = 0
  type        = "string"
}

variable "root_volume_size" {
  description = "The volume size in gigabytes."
  default     = "8"
  type        = "string"
}

variable "root_volume_type" {
  description = "The volume type. Must be one of 'standard' (magnetic), 'gp2' (general purpose SSD), or 'io1' (provisioned IOPS SSD)."
  default     = "gp2"
  type        = "string"
}

variable "subnet_ids" {
	description = "List of Subnet IDs to launch the instance(s) in (e.g.: ['subnet-0zfg04s2','subnet-6jm2z54q'])."
  type        = "list"
}

variable "ttl" {
  description = "The TTL (in seconds) for the DNS record(s)."
  default     = "600"
  type        = "string"
}

variable "use_asg" {
  description = "Set to true to use an Auto Scaling Group for the cluster."
  default     = false
  type        = "string"
}

variable "vpc_id" {
  description = "The VPC ID for the security group(s)."
  type        = "string"
}
