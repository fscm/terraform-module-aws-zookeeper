# Apache Zookeeper Terraform Module

A terraform module to create and manage an Apache Zookeeper cluster on AWS.

## Prerequisites

Terraform and AWS Command Line Interface tools need to be installed on your
local computer.

A previously build AMI base image with Apache Zookeeper is required.

### Terraform

Terraform version 0.8 or higher is required.

Terraform installation instructions can be found
[here](https://www.terraform.io/intro/getting-started/install.html).

### AWS Command Line Interface

AWS Command Line Interface installation instructions can be found [here](http://docs.aws.amazon.com/cli/latest/userguide/installing.html).

### Apache Zookeeper AMI

This module requires that an AMI base image with Apache Zookeeper built using
the recipe from [this](https://github.com/fscm/packer-aws-zookeeper) project
to already exist in your AWS account.

The `ami_name` and `ami_prefix` values should match the `aws_ami_name` and
`aws_ami_name_prefix` used on the Packer recipe (respectively).

### AWS Route53 Service (optional)

If you wish to register the instances FQDN, the AWS Route53 service is also
required to be enabled and properly configured.

To register the instances FQDN on AWS Route53 service you need to set the
`private_zone_id` and/or `public_zone_id` variable(s).

## Module Input Variables

- `ami_name` - The name of the AMI to use for the instance(s). See the [Apache Zookeeper AMI](#apache-zookeeper-ami) section for more information. *[default value: 'zookeeper']*
- `ami_prefix` - The prefix of the AMI to use for the instance(s). See the [Apache Zookeeper AMI](#apache-zookeeper-ami) section for more information. *[default value: '']*
- `associate_public_ip_address` - Associate a public IP address to the Apache Zookeeper instance(s). *[default value: false]*
- `domain` - **[required]** The domain name to use for the Apache Zookeeper instance(s).
- `extra_security_group_id` - Extra security group to assign to the Apache Zookeeper instance(s) (e.g.: 'sg-3f983f98'). *[default value: '']*
- `heap_size` - The heap size for the Apache Zookeeper instance(s) (e.g.: '1G'). *[default value: '']*
- `instance_type` - The type of instance to use for the Apache Zookeeper instance(s). *[default value: 't2.small']*
- `keyname` - **[required]** The SSH key name to use for the Apache Zookeeper instance(s).
- `name` - The main name that will be used for the Apache Zookeeper instance(s). *[default value: 'zookeeper']*
- `number_of_instances` - Number of Apache Zookeeper instances in the cluster. *[default value: '1']*
- `prefix` - A prefix to prepend to the Apache Zookeeper instance(s) name. *[default value: '']*
- `private_zone_id` - The ID of the hosted zone for the private DNS record(s). *[default value: '']*
- `public_zone_id` - The ID of the hosted zone for the public DNS record(s). Requires `associate_public_ip_address` to be set to 'true'. *[default value: '']*
- `root_volume_iops` - The amount of provisioned IOPS (for 'io1' type only). *[default value: 0]*
- `root_volume_size` - The volume size in gigabytes. *[default value: '8']*
- `root_volume_type` - The volume type. Must be one of 'standard' (magnetic), 'gp2' (general purpose SSD), or 'io1' (provisioned IOPS SSD). *[default value: 'gp2']*
- `subnet_ids` - **[required]** List of Subnet IDs to launch the instance(s) in (e.g.: ['subnet-0zfg04s2','subnet-6jm2z54q']).
- `ttl` - The TTL (in seconds) for the DNS record(s). *[default value: '600']*
- `use_asg` - Set to true to use an Auto Scaling Group for the cluster. See the [Auto Scaling Group Option](#auto-scaling-group-option) section for more information. *[default value: false]*
- `vpc_id` - **[required]** The VPC ID for the security group(s).

## Usage

```hcl
module "my_zookeeper_cluster" {
  source                     = "github.com/fscm/terraform-module-aws-zookeeper"
  ami_id                     = "ami-gxrd5hz0"
  domain                     = "mydomain.tld"
  keyname                    = "my_ssh_key"
  name                       = "zookeeper"
  number_of_instances        = "3"
  prefix                     = "mycompany-"
  private_zone_id            = "Z3K95H7K1S3F"
  subnet_ids                 = ["subnet-0zfg04s2", "subnet-6jm2z54q"]
  vpc_id                     = "vpc-3f0tb39m"
}
```

## Outputs

- `fqdn` - **[type: list]** List of FQDNs of the Apache Zookeeper instance(s).
- `hostname` - **[type: list]** List of hostnames of the Apache Zookeeper instance(s).
- `id` - **[type: list]** List of IDs of the Apache Zookeeper instance(s).
- `ip` - **[type: list]** List of private IP address of the Apache Zookeeper instance(s).
- `security_group` - **[type: string]** ID of the security group to be added to every instance that requires access to the Apache Zookeeper Cluster.
- `security_group_monit` - **[type: string]** ID of the security group to be added to every instance that requires access to the JMX port of the Apache Zookeeper Cluster nodes.
- `ssh_key` - **[type: string]** The name of the SSH key used.

## Auto Scaling Group Option

**- beta feature -**

The auto scaling group feature will allow for unresponsive instances of the
cluster to be replaced with newer ones automatically.

In some cases this could lead to **data corruption/loss**.

This feature is more suitable to volatile environments and thus not recommended
for production clusters (where the information stored on the Zookeeper nodes
can not be lost and/or restored).

### Auto Scaling Group Limitation

Due to the way Elastic Network Interfaces have to be assigned to the Zookeeper
instances, on this method of creating the cluster, there can only be **one
instance per subnet**.

## Cluster Access

This modules provides a security group that will allow access to the Apache
Zookeeper cluster instances.

That group will allow access to the following ports to all the AWS EC2
instances that belong to the group:

| Service                 | Port   | Protocol |
|:------------------------|:------:|:--------:|
| Zookeeper Server        | 2181   |    TCP   |

If access to other ports (like the SSH port) is required, you can create your
own security group and add it to the Apache Zookeeper cluster instances using
the `extra_security_group_id` variable.

## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request

## Versioning

This project uses [SemVer](http://semver.org/) for versioning. For the versions
available, see the [tags on this repository](https://github.com/fscm/terraform-module-aws-zookeeper/tags).

## Authors

* **Frederico Martins** - [fscm](https://github.com/fscm)

See also the list of [contributors](https://github.com/fscm/terraform-module-aws-zookeeper/contributors)
who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE)
file for details
