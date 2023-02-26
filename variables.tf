#descricao id da tenancy
variable "tenancy_ocid" {
  default = "ocid1.tenancy.oc1..aaaaaaaad5inhrxpzcozuvgsbzgxbxa7ri7tordweztvqg2jtfkulmqr6hvq"
}
#descricao id do usuario
variable "user_ocid" {
  default = "ocid1.user.oc1..aaaaaaaaskyo6fffpnombhm4bw4sgjafy7nipcab6xax22tqehq5ajevmjka"
}
#descricao do api key do usuario
variable "fingerprint" {
  default = "3c:e9:8e:f5:70:4f:60:47:55:0e:a0:91:0d:1e:4b:f8"
}
#descricao do caminho da chave privada
variable "private_key_path" {
  default = "D:/TCC/TCC/key/oci_api_key.pem"
}
#descricao do compartimento usado
variable "compartment_ocid" {
  default = "ocid1.compartment.oc1..aaaaaaaa244kk7evpcemiee53eiecrufx5mwb66dossufabg44dt6cel5wqq"
}
#descricao da regiao
variable "region" {
  default = "sa-saopaulo-1"
}
variable "userdata" {
  default = "userdata"
}

variable "cloudinit_ps1" {
  default = "cloudinit.ps1"
}

variable "cloudinit_config" {
  default = "cloudinit.yml"
}

variable "setup_ps1" {
  default = "setup.ps1"
}

variable "size_in_gbs" {
  default = "256"
}

variable "instance_name" {
  default = "TSPLUS"
}

variable "instance_image_ocid" {
  type = map(string)

  default = {
    # Images released in and after July 2018 have cloudbase-init and winrm enabled by default, refer to the release notes - https://docs.cloud.oracle.com/iaas/images/
    # Image OCIDs for Windows-Server-2012-R2-Standard-Edition-VM-Gen2-2018.10.12-0 - https://docs.cloud.oracle.com/iaas/images/image/80b70ffd-5efc-479e-872c-d1bf6bcbefbd/

    sa-saopaulo-1 = "ocid1.image.oc1.sa-saopaulo-1.aaaaaaaarq2tvirjdd7koud7ynleyx2nkjyjoweb7lh5hfpxdkeri3qmfaxa"
  }
}