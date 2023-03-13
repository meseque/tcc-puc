# Rede Publica

data "oci_identity_availability_domain" "ad" {
  compartment_id = var.tenancy_ocid
  ad_number      = 1
}

resource "oci_core_vcn" "rede_vcn" {
  cidr_block     = "10.1.0.0/16"
  compartment_id = var.compartment_ocid
  display_name   = "Rede"
  dns_label      = "Rede"
}

resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = var.compartment_ocid
  display_name   = "InternetGateway"
  vcn_id         = oci_core_vcn.rede_vcn.id
}

resource "oci_core_route_table" "pub_route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.rede_vcn.id
  display_name   = "PubRouteTable"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.internet_gateway.id
  }
}

resource "oci_core_public_ip" "lb_reserved_ip" {
  compartment_id = var.compartment_ocid
  lifetime       = "RESERVED"

  lifecycle {
    ignore_changes = [private_ip_id]
  }
}

# https://docs.cloud.oracle.com/iaas/Content/Compute/Tasks/accessinginstance.htm#one
resource "oci_core_security_list" "pub_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.rede_vcn.id
  display_name   = "PubSecurityList"

  # allow inbound remote desktop traffic
  ingress_security_rules {
    protocol  = "6" # tcp
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    protocol  = "6" # tcp
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      # These values correspond to the destination port range.
      min = 3389
      max = 3389
    }
  }

  ingress_security_rules {
    protocol  = "6" # tcp
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      # These values correspond to the destination port range.
      min = 443
      max = 443
    }
  }

  ingress_security_rules {
    protocol  = "6" # tcp
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      # These values correspond to the destination port range.
      min = 5985
      max = 5986
    }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    stateless   = false
  }
}

resource "oci_core_subnet" "pub_subnet" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  cidr_block          = "10.1.10.0/24"
  display_name        = "PubSubnet"
  dns_label           = "pubsubnet"
  security_list_ids   = [oci_core_security_list.pub_security_list.id]
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_vcn.rede_vcn.id
  route_table_id      = oci_core_route_table.pub_route_table.id
  dhcp_options_id     = oci_core_vcn.rede_vcn.default_dhcp_options_id

  provisioner "local-exec" {
    command = "sleep 5"
  }
}

resource "oci_core_nat_gateway" "nat_gateway" {
  compartment_id = var.compartment_ocid
  display_name   = "NatGateway"
  vcn_id         = oci_core_vcn.rede_vcn.id
}

resource "oci_core_route_table" "private_route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.rede_vcn.id
  display_name   = "PrivateRouteTable"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.nat_gateway.id
  }
}

# https://docs.cloud.oracle.com/iaas/Content/Compute/Tasks/accessinginstance.htm#one
resource "oci_core_security_list" "private_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.rede_vcn.id
  display_name   = "PrivateSecurityList"

  # allow inbound remote desktop traffic
  ingress_security_rules {
    protocol  = "6" # tcp
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      # These values correspond to the destination port range.
      min = 3389
      max = 3389
    }
  }

  # allow inbound winrm traffic
  ingress_security_rules {
    protocol  = "6" # tcp
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      # These values correspond to the destination port range.
      min = 5985
      max = 5986
    }
  }

  # allow all outbound traffic
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    stateless   = false
  }
}

resource "oci_core_subnet" "private1_subnet" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  cidr_block          = "10.1.20.0/24"
  display_name        = "Private1Subnet"
  dns_label           = "private1subnet"
  security_list_ids   = [oci_core_security_list.private_security_list.id]
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_vcn.rede_vcn.id
  route_table_id      = oci_core_route_table.private_route_table.id
  dhcp_options_id     = oci_core_vcn.rede_vcn.default_dhcp_options_id

  provisioner "local-exec" {
    command = "sleep 5"
  }
}

resource "oci_core_subnet" "private2_subnet" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  cidr_block          = "10.1.30.0/24"
  display_name        = "Private2Subnet"
  dns_label           = "private2subnet"
  security_list_ids   = [oci_core_security_list.private_security_list.id]
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_vcn.rede_vcn.id
  route_table_id      = oci_core_route_table.private_route_table.id
  dhcp_options_id     = oci_core_vcn.rede_vcn.default_dhcp_options_id

  provisioner "local-exec" {
    command = "sleep 5"
  }
}
