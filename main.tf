resource "vsphere_folder" "k8s-dev" {
  path          = "k8s-dev"
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.dc.id
}
variable "k8s-dev-vip" {
  type = string
  default = "172.16.0.250"
}
variable "hapass" {
  type = string
}
##############################
##### Define K8S Cluster #####
##############################
resource "vsphere_virtual_machine" "k8s-lb" {
    count = 2
    depends_on = [
       vsphere_virtual_machine.k8s-master,
       vsphere_virtual_machine.k8s-first-master
    ]
    folder = vsphere_folder.k8s-dev.path
    name             = "dev-lb-${1+count.index}"
    num_cpus         = 4
    memory           = 2048
    datastore_id     = data.vsphere_datastore.hdd-datastore.id
    resource_pool_id = data.vsphere_resource_pool.pool.id
    guest_id         = data.vsphere_virtual_machine.ubuntu-focal.guest_id
    firmware         = data.vsphere_virtual_machine.ubuntu-focal.firmware
    network_interface {
        network_id = data.vsphere_network.lan.id
    }
    disk {
        label = "disk0.vmdk"
        size = "40"
        thin_provisioned = true
    }
    clone {
        template_uuid = data.vsphere_virtual_machine.ubuntu-focal.id
    }
    provisioner "file" {
        source      = "${path.module}/scripts/ubuntu-init.sh"
        destination = "/tmp/init.sh"
    }
    provisioner "file" {
        source      = "${path.module}/scripts/lb.sh"
        destination = "/tmp/lb.sh"
    }
    provisioner "remote-exec" {
        inline = [
            "export hostname=${self.name}",
            "export vip=${var.k8s-dev-vip}",
            "export hapass=${var.hapass}",
            "echo ${vsphere_virtual_machine.k8s-first-master.default_ip_address} > /tmp/masterips",
            "echo '${join("\n",formatlist("%v", vsphere_virtual_machine.k8s-master.*.default_ip_address))}' >> /tmp/masterips",
            "chmod +x /tmp/init.sh",
            "chmod +x /tmp/lb.sh",
            "/tmp/init.sh",
            "/tmp/lb.sh",
            "sudo rm -rf /tmp/*"
        ]
    }
    connection {
        type     = "ssh"
        user     = "admin"
        private_key = file("${path.module}/credentials/ssh_key")
        host     = self.default_ip_address
    }
    lifecycle {
        ignore_changes = [
        clone[0].template_uuid,
        annotation,
        ]
    }
    extra_config = {
        "guestinfo.metadata"          = base64encode(file("${path.module}/cloud-init/metadata.yaml"))
        "guestinfo.metadata.encoding" = "base64"
        "guestinfo.userdata"          = base64encode(file("${path.module}/cloud-init/userdata.yaml"))
        "guestinfo.userdata.encoding" = "base64"
    }
}
resource "vsphere_virtual_machine" "k8s-first-master" {
    folder = vsphere_folder.k8s-dev.path
    name             = "dev-master-1"
    num_cpus         = 6
    memory           = 4096
    datastore_id     = data.vsphere_datastore.hdd-datastore.id
    resource_pool_id = data.vsphere_resource_pool.pool.id
    guest_id         = data.vsphere_virtual_machine.ubuntu-focal.guest_id
    firmware         = data.vsphere_virtual_machine.ubuntu-focal.firmware
    network_interface {
        network_id = data.vsphere_network.lan.id
    }
    disk {
        label = "disk0.vmdk"
        size = "100"
        thin_provisioned = true
    }
    clone {
        template_uuid = data.vsphere_virtual_machine.ubuntu-focal.id
    }
   provisioner "file" {
        source      = "${path.module}/scripts/ubuntu-init.sh"
        destination = "/tmp/init.sh"
    }
    provisioner "file" {
        source      = "${path.module}/scripts/k8s-init.sh"
        destination = "/tmp/k8s-init.sh"
    }
    provisioner "remote-exec" {
        inline = [
            "export hostname=${self.name}",
            "chmod +x /tmp/init.sh",
            "chmod +x /tmp/k8s-init.sh",
            "/tmp/k8s-init.sh",
            "/tmp/init.sh",
            "sudo rm -rf /tmp/*"
        ]
    }
    connection {
        type     = "ssh"
        user     = "admin"
        private_key = file("${path.module}/credentials/ssh_key")
        host     = self.default_ip_address
    }
    lifecycle {
        ignore_changes = [
        clone[0].template_uuid,
        annotation,
        ]
    }
    extra_config = {
        "guestinfo.metadata"          = base64encode(file("${path.module}/cloud-init/metadata.yaml"))
        "guestinfo.metadata.encoding" = "base64"
        "guestinfo.userdata"          = base64encode(file("${path.module}/cloud-init/userdata.yaml"))
        "guestinfo.userdata.encoding" = "base64"
    }
}
resource "vsphere_virtual_machine" "k8s-master" {
    count = 2
    folder = vsphere_folder.k8s-dev.path
    name             = "dev-master-${2+count.index}"
    num_cpus         = 6
    memory           = 4096
    datastore_id     = data.vsphere_datastore.hdd-datastore.id
    resource_pool_id = data.vsphere_resource_pool.pool.id
    guest_id         = data.vsphere_virtual_machine.ubuntu-focal.guest_id
    firmware         = data.vsphere_virtual_machine.ubuntu-focal.firmware
    network_interface {
        network_id = data.vsphere_network.lan.id
    }
    disk {
        label = "disk0.vmdk"
        size = "100"
        thin_provisioned = true
    }
    clone {
        template_uuid = data.vsphere_virtual_machine.ubuntu-focal.id
    }
    provisioner "file" {
        source      = "${path.module}/scripts/ubuntu-init.sh"
        destination = "/tmp/init.sh"
    }
    provisioner "file" {
        source      = "${path.module}/scripts/k8s-init.sh"
        destination = "/tmp/k8s-init.sh"
    }
    provisioner "remote-exec" {
        inline = [
            "export hostname=${self.name}",
            "chmod +x /tmp/init.sh /tmp/k8s-init.sh",
            "/tmp/k8s-init.sh",
            "/tmp/init.sh",
            "sudo rm -rf /tmp/*"
        ]
    }
    connection {
        type     = "ssh"
        user     = "admin"
        private_key = file("${path.module}/credentials/ssh_key")
        host     = self.default_ip_address
    }
    lifecycle {
        ignore_changes = [
        clone[0].template_uuid,
        annotation,
        ]
    }
    extra_config = {
        "guestinfo.metadata"          = base64encode(file("${path.module}/cloud-init/metadata.yaml"))
        "guestinfo.metadata.encoding" = "base64"
        "guestinfo.userdata"          = base64encode(file("${path.module}/cloud-init/userdata.yaml"))
        "guestinfo.userdata.encoding" = "base64"
    }
}
resource "vsphere_virtual_machine" "k8s-worker" {
    count = 5
    folder = vsphere_folder.k8s-dev.path
    name             = "dev-worker-${1+count.index}"
    num_cpus         = 4
    memory           = 2048
    datastore_id     = data.vsphere_datastore.hdd-datastore.id
    resource_pool_id = data.vsphere_resource_pool.pool.id
    guest_id         = data.vsphere_virtual_machine.ubuntu-focal.guest_id
    firmware         = data.vsphere_virtual_machine.ubuntu-focal.firmware
    network_interface {
        network_id = data.vsphere_network.lan.id
    }
    disk {
        label = "disk0.vmdk"
        size = "100"
        thin_provisioned = true
    }
    clone {
        template_uuid = data.vsphere_virtual_machine.ubuntu-focal.id
    }
    provisioner "file" {
        source      = "${path.module}/scripts/ubuntu-init.sh"
        destination = "/tmp/init.sh"
    }
    provisioner "file" {
        source      = "${path.module}/scripts/k8s-init.sh"
        destination = "/tmp/k8s-init.sh"
    }
    provisioner "remote-exec" {
        inline = [
            "export hostname=${self.name}",
            "chmod +x /tmp/init.sh /tmp/k8s-init.sh",
            "/tmp/k8s-init.sh",
            "/tmp/init.sh",
            "sudo rm -rf /tmp/*"
        ]
    }
    connection {
        type     = "ssh"
        user     = "admin"
        private_key = file("${path.module}/credentials/ssh_key")
        host     = self.default_ip_address
    }
    lifecycle {
        ignore_changes = [
        clone[0].template_uuid,
        annotation,
        ]
    }
    extra_config = {
        "guestinfo.metadata"          = base64encode(file("${path.module}/cloud-init/metadata.yaml"))
        "guestinfo.metadata.encoding" = "base64"
        "guestinfo.userdata"          = base64encode(file("${path.module}/cloud-init/userdata.yaml"))
        "guestinfo.userdata.encoding" = "base64"
    }
}
##############################
##### Create K8S Cluster #####
##############################
resource "null_resource" "init-master" {
    depends_on = [
        vsphere_virtual_machine.k8s-first-master,
        vsphere_virtual_machine.k8s-lb
        ]
    provisioner "local-exec" {
        command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u admin --private-key ${path.module}/credentials/ssh_key -e working_host='${vsphere_virtual_machine.k8s-first-master.default_ip_address}' ansible/playbook/master_init.yaml"
    }
}
resource "null_resource" "master-join" {
    count = 2
    depends_on = [
        vsphere_virtual_machine.k8s-first-master,
        vsphere_virtual_machine.k8s-master,
        vsphere_virtual_machine.k8s-lb,
        null_resource.init-master
        ]
    #for_each = toset(vsphere_virtual_machine.k8s-master.*.default_ip_address)
    provisioner "local-exec" {
        command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u admin --private-key ${path.module}/credentials/ssh_key -e working_host='${vsphere_virtual_machine.k8s-master[count.index].default_ip_address}' ansible/playbook/master_join.yaml"
    }
}
resource "null_resource" "worker-join" {
    count = 5
    depends_on = [
        vsphere_virtual_machine.k8s-first-master,
        vsphere_virtual_machine.k8s-master,
        vsphere_virtual_machine.k8s-worker,
        vsphere_virtual_machine.k8s-lb,
        null_resource.init-master,
        null_resource.master-join
        ]
    #for_each = toset(vsphere_virtual_machine.k8s-worker.*.default_ip_address)
    provisioner "local-exec" {
        command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u admin --private-key ${path.module}/credentials/ssh_key -e working_host='${vsphere_virtual_machine.k8s-worker[count.index].default_ip_address}' ansible/playbook/worker_join.yaml"
    }
}
##############################
##### Output Cluster IPs #####
##############################
output "master-ip" {
  value = vsphere_virtual_machine.k8s-master.*.default_ip_address
}
output "fmaster-ip" {
  value = vsphere_virtual_machine.k8s-first-master.default_ip_address
}
output "worker-ip" {
  value = vsphere_virtual_machine.k8s-worker.*.default_ip_address
}
output "loadbalancer-ip" {
  value = vsphere_virtual_machine.k8s-lb.*.default_ip_address
}
