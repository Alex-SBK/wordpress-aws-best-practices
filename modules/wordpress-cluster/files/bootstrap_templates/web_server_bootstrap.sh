#!/bin/bash
yum -y update
yum -y install httpd

amazon-linux-extras install -y php7.2
yum install -y amazon-efs-utils
mount -t efs -o tls "${efs_id}":/ /var/www/html/
service httpd start
chkconfig httpd on
