# Cloudinit
# Generate a new strong password for your instance
resource "random_string" "instance_password" {
  length  = 16
  special = true
}

# Use the cloudinit.ps1 as a template and pass the instance name, user and password as variables to same
data "template_file" "cloudinit_ps1" {
  vars = {
    instance_user     = "opc"
    instance_password = random_string.instance_password.result
    instance_name     = var.instance_name
  }

  template = file("${var.userdata}/${var.cloudinit_ps1}")
}

data "template_cloudinit_config" "cloudinit_config" {
  gzip          = false
  base64_encode = true

  # The cloudinit.ps1 uses the #ps1_sysnative to update the instance password and configure winrm for https traffic
  part {
    filename     = "cloudinit.ps1"
    content_type = "text/x-shellscript"
    content      = data.template_file.cloudinit_ps1.rendered
  }

  # The cloudinit.yml uses the #cloud-config to write files remotely into the instance, this is executed as part of instance setup
  part {
    filename     = "cloudinit.yml"
    content_type = "text/cloud-config"
    content      = file("${var.userdata}/${var.cloudinit_config}")
  }
}

# Compute

resource "oci_core_instance" "tsap_instance" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid
  display_name        = var.instance_name
  shape               = "VM.Standard2.1"

  # Refer cloud-init in https://docs.cloud.oracle.com/iaas/api/#/en/iaas/20160918/datatypes/LaunchInstanceDetails
  metadata = {
    # Base64 encoded YAML based user_data to be passed to cloud-init
    user_data = data.template_cloudinit_config.cloudinit_config.rendered
  }

  create_vnic_details {
    subnet_id      = oci_core_subnet.tsplus_subnet.id
    hostname_label = "TSAP"
  }

  source_details {
    boot_volume_size_in_gbs = var.size_in_gbs
    source_id               = var.instance_image_ocid[var.region]
    source_type             = "image"
  }
}

data "oci_core_instance_credentials" "instance_credentials" {
  instance_id = oci_core_instance.tsap_instance.id
}

resource "oci_core_volume" "tsap_volume" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid
  display_name        = "TSapVolume"
  size_in_gbs         = var.size_in_gbs
}

resource "oci_core_volume_attachment" "tsap_volume_attachment" {
  attachment_type = "iscsi"
  instance_id     = oci_core_instance.tsap_instance.id
  volume_id       = oci_core_volume.tsap_volume.id
}

# Outputs

output "username" {
  value = [data.oci_core_instance_credentials.instance_credentials.username]
}

output "password" {
  value = [random_string.instance_password.result]
}

output "instance_public_ip" {
  value = [oci_core_instance.tsap_instance.public_ip]
}

output "instance_private_ip" {
  value = [oci_core_instance.tsap_instance.private_ip]
}