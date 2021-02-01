# This is terraform template!
# It's need for initial wordpress deployment

# Bastion Host IP address

${bastion_ip} ansible_ssh_user=ec2-user ansible_ssh_private_key_file=${path_to_ssh_pem_key}