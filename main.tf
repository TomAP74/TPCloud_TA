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

resource "openstack_blockstorage_volume_v2" "TP_volume" {
  name = "TP-volume"
  size = 1
}

# Define VM resource
resource "openstack_compute_instance_v2" "webserver_vm" {
  name            = "server-web"
  flavor_name     = "ds1G"      # Adjust to desired flavor
  image_name      = "ubuntu"        # Adjust to desired image
#  key_pair        = "my-keypair"   # Adjust to your SSH key pair name
  network {
    name          = "TP-network"       # Adjust to your network name
  }
}

# Define VM resource
resource "openstack_compute_instance_v2" "database_vm" {
  name            = "database"
  flavor_name     = "ds1G"     # Adjust to desired flavor
  image_name      = "ubuntu" # Adjust to desired image
#  key_pair        = "my-keypair"   # Adjust to your SSH key pair name
  network {
    name          = "TP-network"      # Adjust to your network name
  }
}

resource "openstack_compute_volume_attach_v3" "TP-va" {
  instance_id = openstack_compute_instance_v2.database_vm.id
  volume_id   = openstack_blockstorage_volume_v2.TP_volume.id
}

Envoyer un message à @ThomasP
 
