#cloud-config
#
# Cloud-Config template for the Apache Zookeeper instances (in Autoscaling
# Group mode).
#
# Copyright 2016-2021, Frederico Martins
#   Author: Frederico Martins <http://github.com/fscm>
#
# SPDX-License-Identifier: MIT
#

fqdn: ${hostname}.${domain}
hostname: ${hostname}
manage_etc_hosts: true

write_files:
  - content: |
      #!/bin/bash
      echo "=== Setting Variables ==="
      __AWS_METADATA_ADDR__="169.254.169.254"
      __MAC_ADDRESS__="$$(curl -s http://$${__AWS_METADATA_ADDR__}/latest/meta-data/network/interfaces/macs/ | awk '{print $$1}')"
      __INSTANCE_ID__=$$(curl -s http://$${__AWS_METADATA_ADDR__}/latest/meta-data/instance-id)
      __SUBNET_ID__="$$(curl -s http://$${__AWS_METADATA_ADDR__}/latest/meta-data/network/interfaces/macs/$${__MAC_ADDRESS__}subnet-id)"
      __ATTACHMENT_ID__=$$(aws ec2 describe-network-interfaces --filters "Name=tag:Reference,Values=${eni_reference}" "Name=subnet-id,Values=$${__SUBNET_ID__}" --query "NetworkInterfaces[0].[Attachment][0].[AttachmentId]" | grep -o 'eni-attach-[a-z0-9]*' || echo '')
      __ENI_ID__=$$(aws ec2 describe-network-interfaces --filters "Name=status,Values=available" "Name=tag:Reference,Values=${eni_reference}" "Name=subnet-id,Values=$${__SUBNET_ID__}" --output json --query "NetworkInterfaces[0].NetworkInterfaceId" | grep -o 'eni-[a-z0-9]*')
      __ENI_IP__=$$(aws ec2 describe-network-interfaces --filters "Name=status,Values=available" "Name=tag:Reference,Values=${eni_reference}" "Name=subnet-id,Values=$${__SUBNET_ID__}" --output json --query "NetworkInterfaces[0].PrivateIpAddress" | grep -o "[0-9\.]*")
      echo "=== Disabling source-dest-check ==="
      aws ec2 modify-instance-attribute --instance-id $${__INSTANCE_ID__} --no-source-dest-check &>/dev/null || echo "skipped"
      echo "=== Detach ENI ==="
      if [[ "x$${__ATTACHMENT_ID__}" != "x" ]]; then aws ec2 detach-network-interface --attachment-id $${__ATTACHMENT_ID__}; sleep 60; fi
      echo "=== Attach ENI ==="
      aws ec2 attach-network-interface --network-interface-id $${__ENI_ID__} --instance-id $${__INSTANCE_ID__} --device-index 1
      echo "=== Setting up Apache Zookeeper Instance ==="
      echo "  instance: ${hostname}.${domain}"
      sudo /usr/local/bin/zookeeper_config -i $$(echo '${zookeeper_addr}' | sed -r -n -e "s/.*(([0-9]+):$${__ENI_IP__}).*/\2/p" ) ${zookeeper_args} -E -S -W 60
      echo "=== All Done ==="
    path: /tmp/setup_zookeeper.sh
    permissions: '0755'

runcmd:
  - /tmp/setup_zookeeper.sh
  - rm /tmp/setup_zookeeper.sh
