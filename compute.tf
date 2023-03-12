# CloudinitPub
# Generate a new strong password for your instance PUB
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

# Cloudinit TSAP1
# Generate a new strong password for your instance TSAP1
resource "random_string" "instance_ap1_password" {
  length  = 16
  special = true
}

# Use the cloudinit.ps1 as a template and pass the instance name, user and password as variables to same
data "template_file" "cloudinit_ap1_ps1" {
  vars = {
    instance_user     = "opc"
    instance_password = random_string.instance_ap1_password.result
    instance_ap1_name = var.instance_ap1_name
  }

  template = file("${var.userdata_ap1}/${var.cloudinit_ap1_ps1}")
}

data "template_cloudinit_config" "cloudinit_ap1_config" {
  gzip          = false
  base64_encode = true

  # The cloudinit.ps1 uses the #ps1_sysnative to update the instance password and configure winrm for https traffic
  part {
    filename     = "cloudinit_ap1.ps1"
    content_type = "text/x-shellscript"
    content      = data.template_file.cloudinit_ap1_ps1.rendered
  }

  # The cloudinit.yml uses the #cloud-config to write files remotely into the instance, this is executed as part of instance setup
  part {
    filename     = "cloudinit_ap1.yml"
    content_type = "text/cloud-config"
    content      = file("${var.userdata_ap1}/${var.cloudinit_ap1_config}")
  }
}

# Cloudinit TSAP2
# Generate a new strong password for your instance TSAP1
resource "random_string" "instance_ap2_password" {
  length  = 16
  special = true
}

# Use the cloudinit.ps1 as a template and pass the instance name, user and password as variables to same
data "template_file" "cloudinit_ap2_ps1" {
  vars = {
    instance_user     = "opc"
    instance_password = random_string.instance_ap2_password.result
    instance_ap2_name = var.instance_ap2_name
  }

  template = file("${var.userdata_ap2}/${var.cloudinit_ap2_ps1}")
}

data "template_cloudinit_config" "cloudinit_ap2_config" {
  gzip          = false
  base64_encode = true

  # The cloudinit.ps1 uses the #ps1_sysnative to update the instance password and configure winrm for https traffic
  part {
    filename     = "cloudinit_ap2.ps1"
    content_type = "text/x-shellscript"
    content      = data.template_file.cloudinit_ap2_ps1.rendered
  }

  # The cloudinit.yml uses the #cloud-config to write files remotely into the instance, this is executed as part of instance setup
  part {
    filename     = "cloudinit_ap2.yml"
    content_type = "text/cloud-config"
    content      = file("${var.userdata_ap2}/${var.cloudinit_ap2_config}")
  }
}

# Compute PUB INSTANCE

resource "oci_core_instance" "pub_instance" {
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
    subnet_id      = oci_core_subnet.pub_subnet.id
    hostname_label = "PUBINSTANCE"
  }

  source_details {
    boot_volume_size_in_gbs = var.size_in_gbs
    source_id               = var.instance_image_ocid[var.region]
    source_type             = "image"
  }
}

data "oci_core_instance_credentials" "instance_credentials" {
  instance_id = oci_core_instance.pub_instance.id
}

resource "oci_core_volume" "pub_volume" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid
  display_name        = "PubVolume"
  size_in_gbs         = var.size_in_gbs
}

resource "oci_core_volume_attachment" "pub_volume_attachment" {
  attachment_type = "iscsi"
  instance_id     = oci_core_instance.pub_instance.id
  volume_id       = oci_core_volume.pub_volume.id
}

# Outputs

output "username" {
  value = [data.oci_core_instance_credentials.instance_credentials.username]
}

output "password" {
  value = [random_string.instance_password.result]
}

output "instance_public_ip" {
  value = [oci_core_instance.pub_instance.public_ip]
}

output "instance_private_ip" {
  value = [oci_core_instance.pub_instance.private_ip]
}

# Compute TSAP-01

resource "oci_core_instance" "tsap01_instance" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid
  display_name        = var.instance_ap1_name
  shape               = "VM.Standard2.1"

  # Refer cloud-init in https://docs.cloud.oracle.com/iaas/api/#/en/iaas/20160918/datatypes/LaunchInstanceDetails
  metadata = {
    # Base64 encoded YAML based user_data to be passed to cloud-init
    user_data = data.template_cloudinit_config.cloudinit_config.rendered
  }

  create_vnic_details {
    subnet_id      = oci_core_subnet.private1_subnet.id
    assign_public_ip = "false"
    hostname_label = "TSAP01"
  }

  source_details {
    boot_volume_size_in_gbs = var.size_in_gbs
    source_id               = var.instance_image_ocid[var.region]
    source_type             = "image"
  }
}

data "oci_core_instance_credentials" "instance_ap1_credentials" {
  instance_id = oci_core_instance.tsap01_instance.id
}

resource "oci_core_volume" "tsap1_volume" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid
  display_name        = "Tsap1Volume"
  size_in_gbs         = var.size_in_gbs
}

resource "oci_core_volume_attachment" "tsap1_volume_attachment" {
  attachment_type = "iscsi"
  instance_id     = oci_core_instance.tsap01_instance.id
  volume_id       = oci_core_volume.tsap1_volume.id
}

# Outputs

output "username_ap1" {
  value = [data.oci_core_instance_credentials.instance_credentials.username]
}

output "password_ap1" {
  value = [random_string.instance_password.result]
}

/*output "instance_ap1_public_ip" {
  value = [oci_core_instance.tsap01_instance.public_ip]
}*/

output "instance_ap1_private_ip" {
  value = [oci_core_instance.tsap01_instance.private_ip]
}

# Compute TSAP-02

resource "oci_core_instance" "tsap02_instance" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid
  display_name        = var.instance_ap2_name
  shape               = "VM.Standard2.1"

  # Refer cloud-init in https://docs.cloud.oracle.com/iaas/api/#/en/iaas/20160918/datatypes/LaunchInstanceDetails
  metadata = {
    # Base64 encoded YAML based user_data to be passed to cloud-init
    user_data = data.template_cloudinit_config.cloudinit_config.rendered
  }

  create_vnic_details {
    subnet_id      = oci_core_subnet.private2_subnet.id
    assign_public_ip = "false"
    hostname_label = "TSAP02"
  }

  source_details {
    boot_volume_size_in_gbs = var.size_in_gbs
    source_id               = var.instance_image_ocid[var.region]
    source_type             = "image"
  }
}

data "oci_core_instance_credentials" "instance_ap2_credentials" {
  instance_id = oci_core_instance.tsap02_instance.id
}

resource "oci_core_volume" "tsap2_volume" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid
  display_name        = "Tsap2Volume"
  size_in_gbs         = var.size_in_gbs
}

resource "oci_core_volume_attachment" "tsap2_volume_attachment" {
  attachment_type = "iscsi"
  instance_id     = oci_core_instance.tsap02_instance.id
  volume_id       = oci_core_volume.tsap2_volume.id
}

# Outputs

output "username_ap2" {
  value = [data.oci_core_instance_credentials.instance_credentials.username]
}

output "password_ap2" {
  value = [random_string.instance_password.result]
}

/*output "instance_ap2_public_ip" {
  value = [oci_core_instance.tsap01_instance.public_ip]
}*/

output "instance_ap2_private_ip" {
  value = [oci_core_instance.tsap01_instance.private_ip]
}