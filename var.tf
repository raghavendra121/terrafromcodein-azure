variable "company" {
    type = string
    description = "The name of the company"
}
variable "web_server" {
    type = string
    description = "The name of the web server"
}
variable "environment" {
    type = string
    description = "The name of the environment"
}
variable "location" {
  default = "centralindia"
}
variable "serve-vnet7-cidr" {
    type = string
    description = "The name of the vnet cidr"
    default = "10.0.0.0/16"
}
variable "serve-sub7-cidr" {
    type = string
    default = "10.0.1.0/24"
}
variable "serve-vm_size" {
    type = string
    description = "the value "
    default = "Standard_DS2_v2"
}
variable "serve-delete_os_disk_on_termination" {
    type = string
    default = true
}
variable "serve-delete_data_disks_on_termination" {
    type = string
    default = true
}
variable "serve-vm-stoarge" {
    type = map(string)
    default = {
       disk_size_gb = "30"
       publisher = "Canonical"
       offer = "UbuntuServer"
       sku = "18.04-LTS"
       version = "latest"
    }
}
variable "serve-admin_username" {
    type = string
    default = "server-test"
}  
variable "serve-admin_password" {
    type = string
    default = "Password@123"
}