terraform {
    required_providers {
      azurerm = {
        source = "hashicorp/azurerm"
        version = "~> 4.3"
      }
    }
}
provider "azurerm" {
    features {}
  subscription_id = "a063b7d0-0fe4-4b03-a406-6f44f33382a4"
  client_id = "7d346b51-a042-47bc-ab04-7a8dea75630e"
  tenant_id = "201cd9cb-f6df-4821-ba98-c311216ca694"
  client_secret = "CWv8Q~OSAft4AosHTkhG.SNzEgsr-8p638taZcpm"
}
resource "azurerm_resource_group" "serve-rg7" {
  name     = "${lower(replace(var.web_server,"",""))}-${var.environment}-rg7"
  location = var.location
  tags = {
     web_server = var.web_server
     environmnet = var.environment 
  }
}
resource "azurerm_virtual_network" "serve-vnet7"{
    name = "${lower(replace(var.web_server,"",""))}-${var.environment}-vnet7"
    location = azurerm_resource_group.serve-rg7.location
    resource_group_name = azurerm_resource_group.serve-rg7.name
    address_space = [var.serve-vnet7-cidr]
    tags = {
      web_server = var.web_server
      environment = var.environment
    }
}
resource "azurerm_subnet" "serve-sub7"{
    name = "${lower(replace(var.web_server,"",""))}-${var.environment}-sub7"
    resource_group_name = azurerm_resource_group.serve-rg7.name
    virtual_network_name = azurerm_virtual_network.serve-vnet7.name
    address_prefixes = [var.serve-sub7-cidr]
}
resource "random_password" "serve-password" {
    length = 16
    special = true
    override_special = "_%@"
    min_lower = 2
    min_numeric = 2
    min_upper = 2
}
resource "random_string" "serve-name" {
    length = 8
    upper = false
    special = false
    lower = true
}
resource "azurerm_network_security_group" "serve-nsg7" {
     depends_on = [ azurerm_resource_group.serve-rg7 ]
     name = "web-${var.environment}-${random_string.serve-name.result}-nsg7"
    location = azurerm_resource_group.serve-rg7.location
    resource_group_name = azurerm_resource_group.serve-rg7.name
    security_rule {
        name = "allowweb"
        description = "allow web"
        priority = "100"
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "80"
        source_address_prefix = "Internet"
        destination_address_prefix = "*"
      }
      security_rule {
        name = "Allowssh"
        description = "allow ssh"
        priority = "150"
        protocol = "Tcp"
        direction = "Inbound"
        access = "Allow"
        source_port_range = "*"
        destination_port_range = "22"
        source_address_prefix = "Internet"
        destination_address_prefix = "*"
      }
      tags = {
        web_server = var.web_server
        environment = var.environment
    
      }
}
resource "azurerm_subnet_network_security_group_association" "serve-nsga7" {
    depends_on = [ azurerm_resource_group.serve-rg7 ]

    subnet_id = azurerm_subnet.serve-sub7.id
    network_security_group_id = azurerm_network_security_group.serve-nsg7.id
}
resource "azurerm_public_ip" "serve-ip7" {
    depends_on = [ azurerm_resource_group.serve-rg7 ]
    name = "web-${var.environment}-${random_string.serve-name.result}-ip7"
    location = azurerm_resource_group.serve-rg7.location
    resource_group_name = azurerm_resource_group.serve-rg7.name
    allocation_method = "Static"
    tags = {
      web_server = var.web_server
      environment = var.environment
    }
}
resource "azurerm_network_interface" "serve-nif7" {
    depends_on = [ azurerm_resource_group.serve-rg7 ]
    name = "web-${var.environment}-${random_string.serve-name.result}-nif7"
    location = azurerm_resource_group.serve-rg7.location
    resource_group_name = azurerm_resource_group.serve-rg7.name
    ip_configuration {
        name = "web-${var.environment}-${random_string.serve-name.result}-nif7-ip"
        subnet_id = azurerm_subnet.serve-sub7.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id = azurerm_public_ip.serve-ip7.id
    }
    tags = {
      web_server = var.web_server
      environment = var.environment
    }
} 
resource "tls_private_key" "key_file" {
    algorithm = "RSA"
    rsa_bits = 4096
}
resource "local_file" "key-file" {
    filename = "key-file.pem"
    content = tls_private_key.key_file.private_key_openssh  
}
resource "azurerm_virtual_machine" "serve-vm7" {
  depends_on = [ azurerm_network_interface.serve-nif7 ]

   network_interface_ids = [azurerm_network_interface.serve-nif7.id]
   name = "web-${var.environment}-${random_string.serve-name.result}-vm7"
   location = azurerm_resource_group.serve-rg7.location
   resource_group_name = azurerm_resource_group.serve-rg7.name
   vm_size = var.serve-vm_size

   delete_os_disk_on_termination = var.serve-delete_os_disk_on_termination
   delete_data_disks_on_termination = var.serve-delete_data_disks_on_termination
   storage_image_reference {
       publisher = lookup(var.serve-vm-stoarge, "publisher", null)
       offer = lookup(var.serve-vm-stoarge, "offer", null)
       sku = lookup(var.serve-vm-stoarge, "sku", null)
       version = lookup(var.serve-vm-stoarge, "version", null)
   }
   storage_os_disk {
       name = "web-${var.environment}-${random_string.serve-name.result}-vm7-osdisk"
       caching = "ReadWrite"
       create_option = "FromImage"
       managed_disk_type = "Standard_LRS"
       disk_size_gb = lookup(var.serve-vm-stoarge, "disk_size_gb", null)
   }
   os_profile {
       computer_name = "web-${var.environment}-${random_string.serve-name.result}-vm7"
       admin_username = var.serve-admin_username
       admin_password = random_password.serve-password.result
   }
   os_profile_linux_config {
       disable_password_authentication = true
       ssh_keys {
           path = "/home/${var.serve-admin_username}/.ssh/authorized_keys"
           key_data = tls_private_key.key_file.public_key_openssh
       }
   }
   provisioner "remote-exec" {
     connection {
       type = "ssh"
       user = var.serve-admin_username
       host = azurerm_public_ip.serve-ip7.ip_address
       private_key = tls_private_key.key_file.private_key_pem
       timeout = "1m"
       port = "22"
     }
     inline = [
       "sudo apt-get update",
       "sudo apt-get install -y apache2",
       "sudo systemctl start apache2",
       "sudo systemctl enable apache2",
       "echo 'Hello, World!' > /var/www/html/index.html",
       "sudo apt-get install -y git"
     ]
   }
provisioner "local-exec" {
    command = "echo ${azurerm_public_ip.serve-ip7.ip_address} > ip-address.txt"
  }
  provisioner "local-exec" {
    command = "echo ${random_password.serve-password.result} > password.txt"
  }
}


