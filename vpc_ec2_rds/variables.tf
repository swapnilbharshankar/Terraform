variable "access_key" {}
variable "secret_key" {}
variable "region" {
  default = "us-east-1"
}

variable "ami" {
  default = "ami-06b5810be11add0e2"
}

variable "key_path" {
  default = "/home/ubuntu/test.pub"
}
