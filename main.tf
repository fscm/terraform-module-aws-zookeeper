#
# Terraform module to create an Apache Zookeeper cluster.
#
# Copyright 2016-2018, Frederico Martins
#   Author: Frederico Martins <http://github.com/fscm>
#
# SPDX-License-Identifier: MIT
#
# This program is free software. You can use it and/or modify it under the
# terms of the MIT License.
#

#
# Apache Zookeeper AMI.
#

data "aws_ami" "zookeeper" {
  most_recent = true
  name_regex  = "^${var.prefix}${var.name}-.*-(\\d{14})$"
  owners      = ["self"]
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "name"
    values = ["${var.ami_prefix}${var.ami_name}-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#
# Apache Zookeeper instance(s).
#

resource "aws_instance" "zookeeper" {
  count                       = "${var.use_asg ? 0 : var.number_of_instances}"
  ami                         = "${data.aws_ami.zookeeper.id}"
  associate_public_ip_address = "${var.associate_public_ip_address}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.keyname}"
  subnet_id                   = "${element(var.subnet_ids, count.index)}"
  user_data                   = "${element(data.template_file.zookeeper.*.rendered, count.index)}"
  vpc_security_group_ids      = ["${aws_security_group.zookeeper.id}","${aws_security_group.zookeeper_intra.id}","${var.extra_security_group_id}"]
  root_block_device {
    volume_size = "${var.root_volume_size}"
    volume_type = "${var.root_volume_type}"
    iops        = "${var.root_volume_iops}"
  }
  tags {
    Name      = "${var.prefix}${var.name}${format("%02d", count.index + 1)}"
    Zookeeper = "true"
    Service   = "Zookeeper"
  }
}

data "template_file" "zookeeper" {
  count    = "${var.use_asg ? 0 : var.number_of_instances}"
  template = "${file("${path.module}/templates/cloud-config/init.tpl")}"
  vars {
    domain         = "${var.domain}"
    hostname       = "${var.prefix}${var.name}${format("%02d", count.index + 1)}"
    zookeeper_args = "-i ${count.index + 1} -n ${join(",", data.template_file.zookeeper_id.*.rendered)} ${var.heap_size == "" ? var.heap_size : "-m var.heap_size"}"
  }
}

data "template_file" "zookeeper_id" {
  count    = "${var.number_of_instances}"
  template = "$${index}:$${hostname}.$${domain}"
  vars {
    domain   = "${var.domain}"
    hostname = "${var.prefix}${var.name}${format("%02d", count.index + 1)}"
    index    = "${count.index + 1}"
  }
}

#
# Apache Zookeeper Auto Scaling Group (ASG).
#

resource "aws_autoscaling_group" "zookeeper" {
  count                     = "${var.use_asg ? 1 : 0}"
  desired_capacity          = "${var.number_of_instances}"
  health_check_grace_period = 300
  health_check_type         = "EC2"
  launch_configuration      = "${aws_launch_configuration.zookeeper.name}"
  max_size                  = "${var.number_of_instances}"
  min_size                  = "${var.number_of_instances}"
  name                      = "${var.prefix}${var.name}"
  vpc_zone_identifier       = "${slice(var.subnet_ids, 0, var.number_of_instances)}"
  lifecycle {
    create_before_destroy = true
  }
  tag {
    key                 = "Name"
    value               = "${var.prefix}${var.name}"
    propagate_at_launch = true
  }
  tag {
    key                 = "Zookeeper"
    value               = "true"
    propagate_at_launch = true
  }
  tag {
    key                 = "Service"
    value               = "Zookeeper"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "zookeeper" {
  associate_public_ip_address = false
  iam_instance_profile        = "${aws_iam_instance_profile.zookeeper_eni.arn}"
  image_id                    = "${data.aws_ami.zookeeper.id}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.keyname}"
  name_prefix                 = "${var.prefix}${var.name}-"
  security_groups             = ["${aws_security_group.zookeeper.id}","${aws_security_group.zookeeper_intra.id}","${var.extra_security_group_id}"]
  user_data = "${data.template_file.zookeeper_asg.rendered}"
  lifecycle {
    create_before_destroy = true
  }
}

data "template_file" "zookeeper_asg" {
  count    = "${var.use_asg ? 1 : 0}"
  template = "${file("${path.module}/templates/cloud-config/init_asg.tpl")}"
  vars {
    domain         = "${var.domain}"
    eni_reference  = "${var.prefix}${var.name}"
    hostname       = "${var.prefix}${var.name}"
    zookeeper_addr = "${join(",", data.template_file.zookeeper_asg_addr.*.rendered)}"
    zookeeper_args = "-n ${join(",", data.template_file.zookeeper_id.*.rendered)} ${var.heap_size == "" ? var.heap_size : "-m var.heap_size"}"
  }
}

data "template_file" "zookeeper_asg_addr" {
  count    = "${var.use_asg ? var.number_of_instances : 0}"
  template = "$${index}:$${address}"
  vars {
    address = "${element(split(",", replace(replace(replace(format("%s", aws_network_interface.zookeeper.*.private_ips), "/[^\\s\\d\\.]/", ""), "/(\\d)\\s+/", "$1,"), "/\\s+/", "")), count.index)}"
    index   = "${count.index + 1}"
  }
}

#
# Apache Zookeeper Policies and Roles (for the ASG).
#

resource "aws_iam_instance_profile" "zookeeper_eni" {
  name  = "${var.prefix}${var.name}-zookeeper-eni"
  roles = ["${aws_iam_role.zookeeper_eni.id}"]
}

resource "aws_iam_role" "zookeeper_eni" {
  name               = "${var.prefix}${var.name}-zookeeper-eni"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "zookeeper_eni" {
  name  = "${var.prefix}${var.name}-zookeeper-eni"
  role = "${aws_iam_role.zookeeper_eni.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:AttachNetworkInterface",
        "ec2:CreateNetworkInterface",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeNetworkInterfaceAttribute",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DetachNetworkInterface",
        "ec2:ModifyInstanceAttribute",
        "ec2:ModifyNetworkInterfaceAttribute"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

#
# Apache Zookeeper Elastic Network Interface(s) (for the ASG).
#

resource "aws_network_interface" "zookeeper" {
  count             = "${var.use_asg ? var.number_of_instances : 0}"
  subnet_id         = "${element(var.subnet_ids, count.index)}"
  security_groups   = ["${aws_security_group.zookeeper.id}","${aws_security_group.zookeeper_intra.id}","${var.extra_security_group_id}"]
  source_dest_check = false
  tags {
    Name      = "${var.prefix}${var.name}${format("%02d", count.index + 1)}"
    Reference = "${var.prefix}${var.name}"
    Zookeeper = "true"
    Service   = "Zookeeper"
  }
}

resource "aws_eip" "zookeeper" {
  count             = "${var.use_asg && var.associate_public_ip_address ? var.number_of_instances : 0}"
  depends_on        = ["aws_network_interface.zookeeper"]
  network_interface = "${element(aws_network_interface.zookeeper.*.id, count.index)}"
  vpc               = true
}

#
# Apache Zookeeper DNS record(s).
#

resource "aws_route53_record" "private" {
  count   = "${var.private_zone_id != "" ? var.number_of_instances : 0}"
  name    = "${var.prefix}${var.name}${format("%02d", count.index + 1)}"
  records = ["${var.use_asg ? element(split(",", replace(replace(replace(format("%s", aws_network_interface.zookeeper.*.private_ips), "/[^\\s\\d\\.]/", ""), "/(\\d)\\s+/", "$1,"), "/\\s+/", "")), count.index) : element(aws_instance.zookeeper.*.private_ip, count.index)}"]
  ttl     = "${var.ttl}"
  type    = "A"
  zone_id = "${var.private_zone_id}"
}

resource "aws_route53_record" "public" {
  count   = "${var.public_zone_id != "" && var.associate_public_ip_address ? var.number_of_instances : 0}"
  name    = "${var.prefix}${var.name}${format("%02d", count.index + 1)}"
  records = ["${var.use_asg ? element(aws_eip.zookeeper.*.public_ip, count.index) : element(aws_instance.zookeeper.*.public_ip, count.index)}"]
  ttl     = "${var.ttl}"
  type    = "A"
  zone_id = "${var.public_zone_id}"
}

#
# Apache Zookeeper security group(s).
#

resource "aws_security_group" "zookeeper" {
  name   = "${var.prefix}${var.name}"
  vpc_id = "${var.vpc_id}"
  ingress {
    from_port = 2181
    to_port   = 2181
    protocol  = "tcp"
    self      = true
  }
  lifecycle {
    create_before_destroy = true
  }
  tags {
    Name      = "${var.prefix}${var.name}"
    Zookeeper = "true"
    Service   = "Zookeeper"
  }
}

resource "aws_security_group" "zookeeper_intra" {
  name   = "${var.prefix}${var.name}-intra"
  vpc_id = "${var.vpc_id}"
  ingress {
    from_port = 2888
    to_port   = 2888
    protocol  = "tcp"
    self      = true
  }
  ingress {
    from_port = 3888
    to_port   = 3888
    protocol  = "tcp"
    self      = true
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle {
    create_before_destroy = true
  }
  tags {
    Name      = "${var.prefix}${var.name}-intra"
    Zookeeper = "true"
    Service   = "Zookeeper"
  }
}

resource "aws_security_group" "zookeeper_monit" {
  name   = "${var.prefix}${var.name}-monit"
  vpc_id = "${var.vpc_id}"
  ingress {
    from_port = 7199
    to_port   = 7199
    protocol  = "tcp"
    self      = true
  }
  lifecycle {
    create_before_destroy = true
  }
  tags {
    Name      = "${var.prefix}${var.name}-monit"
    Zookeeper = "true"
    Service   = "Zookeeper"
  }
}
