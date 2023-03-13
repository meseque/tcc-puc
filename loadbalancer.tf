resource "oci_load_balancer" "lb" {
  compartment_id = var.compartment_ocid
  display_name   = "Load Balancer"
  subnet_ids = [
    oci_core_subnet.pub_subnet.id
  ]
  shape = "flexible"
  shape_details {
    minimum_bandwidth_in_mbps = 10
    maximum_bandwidth_in_mbps = 100
  }
}

resource "oci_load_balancer_backend_set" "backend" {
  name             = "Backend"
  load_balancer_id = oci_load_balancer.lb.id
  policy           = "ROUND_ROBIN"

  health_checker {
    port                = "80"
    protocol            = "HTTP"
    response_body_regex = ".*"
    url_path            = "/"
  }
}

resource "oci_load_balancer_listener" "listner" {
  load_balancer_id         = oci_load_balancer.lb.id
  name                     = "Listner"
  default_backend_set_name = oci_load_balancer_backend_set.backend.name
  port                     = 80
  protocol                 = "HTTP"

}

resource "oci_load_balancer_backend" "backend1" {
  load_balancer_id = oci_load_balancer.lb.id
  backendset_name  = oci_load_balancer_backend_set.backend.name
  ip_address       = oci_core_instance.tsap01_instance.private_ip
  port             = 80
  backup           = false
  drain            = false
  offline          = false
  weight           = 1
}

resource "oci_load_balancer_backend" "backend2" {
  load_balancer_id = oci_load_balancer.lb.id
  backendset_name  = oci_load_balancer_backend_set.backend.name
  ip_address       = oci_core_instance.tsap02_instance.private_ip
  port             = 80
  backup           = false
  drain            = false
  offline          = false
  weight           = 1
}