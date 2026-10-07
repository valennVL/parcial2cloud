[haproxy]
vm-haproxy ansible_host=${haproxy_public_ip}

[microservices]
vm-microservices ansible_host=${microservices_public_ip}

[all:vars]
ansible_user=azureuser
ansible_ssh_private_key_file=${ssh_private_key_path}
ansible_python_interpreter=/usr/bin/python3
dockerhub_user=${dockerhub_user}
image_tag=${image_tag}
