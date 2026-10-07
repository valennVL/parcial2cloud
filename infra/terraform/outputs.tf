output "vm_haproxy_public_ip" {
  value       = azurerm_public_ip.haproxy.ip_address
  description = "Public IP of vm-haproxy"
}

output "vm_microservices_public_ip" {
  value       = azurerm_public_ip.microservices.ip_address
  description = "Public IP of vm-microservices"
}

output "ansible_inventory_file" {
  value       = local_file.ansible_inventory.filename
  description = "Generated Ansible inventory file"
}
