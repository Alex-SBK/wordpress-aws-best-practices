#!/bin/bash
yum -y update
yum -y install httpd

cat <<EOF /var/www/html/index.html
    <html>
      <h2>Build By ALEX-SBK <font color="red">v 1.0 </font></h2>
      <br>
      EFS ID = ${efs_id}
      <br>
    </html>
EOF

sudo service httpd start
chkconfig httpd on