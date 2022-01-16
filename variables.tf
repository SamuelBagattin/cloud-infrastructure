variable "my_ip" {
  type = string
}

variable "aws_session_token" {
  type      = string
  sensitive = true
}

variable "oci_tenancy_ocid" {
  type = string
}

variable "oci_user_ocid" {
  type = string
}

variable "oci_fingerprint" {
  type = string
}

variable "oci_private_key_path" {
  type = string
}