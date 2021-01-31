#!/bin/bash
yum -y update
yum install -y amazon-efs-utils
mkdir "/efs"
mount -t efs -o tls "${efs_id}":/ /efs

#cd /home/ec2-user
#wget https://wordpress.org/latest.tar.gz
#tar -xzf latest.tar.gz
#cp -r wordpress/* /efs
#cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
#rm -rf wordpress
#rm -rf latest.tar.gz





sudo mkdir /secrets
sudo cat << EOF > /home/ec2-user/key.pem
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAo4R88uWT0hoHqLVWxs0v1dQ6cRTLOg0sMS+qRme6IDAC62wL
7F0+d2+NA2N/6kbvUk6wkegt9q5K9m3kkGG7W6792zxVOZ0VREZGb7y8X4vSsKqL
PHwFjETirqQePEJ1JnNwfn5w6x6tn4EQsHaqsl83d9Pc77BJ8Gw0tomKOSEijVvz
8aWV+COs1VJraJimmFLXGzcLx1gArfdgrH475AE8a7cA3MD211wIXnOizPbmtkCg
inHIWxsvnhXZuuM6G3KTuH/GZgEYLahKz7X8hC5usru+/dapJehWlw7OIyqzWvNs
O9kJwjN4tiH2j6PDDWtdfJqNYP6uMYPUhAOinQIDAQABAoIBAGwx6gs+ZQUMPC0h
b/2zHwe5mcHhJGeQ98DD7UMQt1M88XGc2HbZa8/Te9bWK3l03j3z21lv65nh0bAl
Hqt6P2J283nw/eNVUREP/uNIWsxN1GcZMXAgD/u0SNmNtoPg5Ws/zxujxkuMzQ1R
dR2OJ3xHDIi5IuNmHkZ7EpYFg/QwJw9gxxFeH/IIqAwCAQBo89iT2x9B+4UXEbxb
ahyu0KGbb3R7RxT5dleHhm7md8K8pAWOZvOjRv9CufR6ELmFzdc8Gpj639V4f1S3
hjs593nFnm7PlLddNViesBBFPLtkvWnhZ7Jucq8vGrPawirh7yRhSMCMjlE87ju3
2pnOaXECgYEA/6e5BgU1zoamASUqGzy0RSiaotmQ98TZrrPtc4OsWzaG5oJD4840
vI6IqehBpBpt1M/Noif+d4zB9nee8NukvotF7VvRdfAiU06mNxQCRZLLbUhnp2bk
OHiHhyzWP2hF8jWQryc9AjwRaRRLAkDRuhfVJrhX46jZmseIrKoJwgMCgYEAo7zz
TBVyfKgbTkpkc8RnXcRmvMZISlPaKYd67b/NekjbpJIh4juTmWtuzwoJn25iBQR+
3loT8k+sLBise5y7YZTiwCpx87PO0yaEq0Wha+AYRA064AgwTgZO+kHJNhpPLaMd
KYp0X/LvokgY/axIxzRBhvkHtJI5n4k1zJ7dNt8CgYEAplPqrp4JKbq0mh4hzOKr
risCoFzIUkrCDUWGgRbztcw97A5oOPfZm6toApLW0ftX5ZLlCFDY39K2BrJAuBdO
kaFu90Q7fG2lB2ot/buI1tbwfsMSnPj2Fj9kfW+QXGRszW5IGYx/xspp0WGgg3DE
gjwrMyvQEo+yM18J7rwZ6R0CgYBVScHNWsqUxhfbEwL6Dk7tV7VQFVRoav8TbL+K
gcLtNHA8a+X8ap36ZyyD6a2TfzLNfEb9WRxUtk1vdra5eK1eKehmwnUyxPExqTmn
4RAxGbxqDh4hvgIzUjPnRUciyFd/5Rv2nGj75ZYPCNEDqa8LHFwZizQJSbV8NUNx
vzppLwKBgC2z9rm9qNJ2Ms4wqHs7E/LmlvK8w0IWZAAzR8LWQnCqFatBAItCgMYk
gYqIEHE8BQKoUvKsNSazumcvVcTg/zQjSd8kuIQ90eYpAQ1BfP98S9Etb6v2/sZN
spnf1ELb6T621dr8i+JtqRnkLTIsrio58fRXvjA4z5FoVz2lTl0b
-----END RSA PRIVATE KEY-----
EOF

sudo chmod 400 /home/ec2-user/key.pem

