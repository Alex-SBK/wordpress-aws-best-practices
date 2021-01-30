#!/bin/bash
sudo yum -y update

sudo yum -y install httpd

sudo cat << EOF > /var/www/html/index.html
    <html>
      <h2>Build By ALEX-SBK <font color="red">v 1.0 </font></h2>
      <br>
      EFS ID = ${efs_id}
      <br>
    </html>
EOF

sudo service httpd start
sudo chkconfig httpd on

sudo yum install -y amazon-efs-utils
sudo mkdir "/efs"
sudo mount -t efs -o tls ${efs_id}:/ /efs

