# Define required providers
terraform {
required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.51.1"
    }
  }
}

# Configure the OpenStack Provider
provider "openstack" {
  user_name   = "admin"
  tenant_name = "admin"
  password    = "secret"
  auth_url    = "http://172.20.10.3/identity"
  region      = "RegionOne"
}

resource "openstack_networking_floatingip_v2" "webserver_floating_ip" {
  pool = "public"
}

resource "openstack_networking_floatingip_v2" "database_floating_ip" {
  pool = "public"
}

resource "openstack_networking_network_v2" "TP_network" {
  name         = "TP-network"
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "TP-subnet" {
  name            = "TP-subnet"
  network_id      = openstack_networking_network_v2.TP_network.id
  cidr            = "10.10.10.0/24"
  gateway_ip      = "10.10.10.254"
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
  allocation_pool {
    start = "10.10.10.1"
    end   = "10.10.10.253"
  }
}

resource "openstack_blockstorage_volume_v3" "database_volume" {
  name = "database-volume"
  size = 1
}

resource "openstack_blockstorage_volume_v3" "webserver_volume" {
  name = "webserver-volume"
  size = 1
}

resource "openstack_images_image_v2" "ubuntu" {
  name             = "ubuntu"
  image_source_url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  container_format = "bare"
  disk_format      = "qcow2"

  properties = {
    key = "value"
  }
}

# Define VM resource
resource "openstack_compute_instance_v2" "webserver_vm" {
  name            = "server-web"
  flavor_name     = "m1.small"      # Adjust to desired flavor
  image_name      = "ubuntu"        # Adjust to desired image
  key_pair        = "TP-keypair"   # Adjust to your SSH key pair name
  network {
    name          = "TP-network"       # Adjust to your network name
  }
}

# Define VM resource
resource "openstack_compute_instance_v2" "database_vm" {
  name            = "database"
  flavor_name     = "ds1G"     # Adjust to desired flavor
  image_name      = "ubuntu" # Adjust to desired image
  key_pair        = "TP-keypair"   # Adjust to your SSH key pair name
  network {
    name          = "TP-network"      # Adjust to your network name
  }
}

resource "openstack_compute_volume_attach_v2" "database-va" {
  instance_id = openstack_compute_instance_v2.database_vm.id
  volume_id   = openstack_blockstorage_volume_v3.database_volume.id
}

resource "openstack_compute_volume_attach_v2" "webserver-va" {
  instance_id = openstack_compute_instance_v2.webserver_vm.id
  volume_id   = openstack_blockstorage_volume_v3.webserver_volume.id
}

resource "openstack_compute_floatingip_associate_v2" "webserver_associate_floating_ip" {
  floating_ip = openstack_networking_floatingip_v2.webserver_floating_ip.address
  instance_id = openstack_compute_instance_v2.webserver_vm.id
}

resource "openstack_compute_floatingip_associate_v2" "database_associate_floating_ip" {
  floating_ip = openstack_networking_floatingip_v2.database_floating_ip.address
  instance_id = openstack_compute_instance_v2.database_vm.id
}

resource "null_resource" "webserver_provisioner" {
  connection {
    type        = "ssh"
    host        = openstack_networking_floatingip_v2.webserver_floating_ip.address
    user        = "ubuntu"
    private_key = file("/home/thomasp/TP/TP-keypair.pem")
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y apache2",
      "sudo systemctl start apache2"
    ]
  }
}

resource "null_resource" "database_provisioner" {
  connection {
    type        = "ssh"
    host        = openstack_networking_floatingip_v2.database_floating_ip.address
    user        = "ubuntu"
    private_key = file("/home/thomasp/TP/TP-keypair.pem")
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y mariadb-server",
      "sudo systemctl start mariadb.service"
    ]
  }
}
