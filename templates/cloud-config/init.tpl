#cloud-config
#
# Cloud-Config template for the Apache Zookeeper instances.
#
# Copyright 2016-2018, Frederico Martins
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
      echo "=== Setting up Apache Zookeeper Instance ==="
      echo "  instance: ${hostname}.${domain}"
      sudo /usr/local/bin/zookeeper_config ${zookeeper_args} -E -S -W 60
      echo "=== All Done ==="
    path: /tmp/setup_zookeeper.sh
    permissions: '0755'

runcmd:
  - /tmp/setup_zookeeper.sh
  - rm /tmp/setup_zookeeper.sh
