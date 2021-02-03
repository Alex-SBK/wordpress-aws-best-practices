#!/bin/bash
yum -y update
yum install -y amazon-efs-utils
mkdir "/efs"
mount -t efs -o tls "${efs_id}":/ /efs

