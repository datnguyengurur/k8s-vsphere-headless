provider "vsphere" {
  vsphere_server       = var.vsphere_server
  user                 = var.vsphere_username
  password             = var.vsphere_password
  allow_unverified_ssl = var.vsphere_insecure
}
data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter
}
data "vsphere_distributed_virtual_switch" "switch" {
  name = var.vsphere_switch
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_virtual_machine" "ubuntu-focal" {
  name          = "Templates/linux-ubuntu-20.04lts-v22.03"
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_virtual_machine" "ws2019" {
  name          = "Templates/windows-server-2019-deskstop"
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_datastore" "nvme-datastore" {
  name          = "nvme-datastore"
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_datastore" "hdd-datastore" {
  name          = "hdd-datastore"
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_resource_pool" "pool" {
  name          = "${var.vsphere_cluster}/Resources"
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_network" "lan" {
    name = "LAN"
    datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_network" "vlan-100" {
    name = "vlan-100"
    datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_network" "vlan-40" {
    name = "vlan-40"
    datacenter_id = data.vsphere_datacenter.dc.id
}