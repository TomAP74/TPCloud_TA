provider "openstack" {
  user_name   = "admin"
  tenant_name = "admin"
  password    = "secret"
  auth_url    = "http://172.20.10.3/identity"
  region      = "RegionOne"
}
