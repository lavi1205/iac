variable "name" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "tags" {
  type = map(string)
  default = {
  }
}

variable "cidr_block" {
  type = string
}

variable "public_subnet" {
  type = list(string)
}

variable "private_subnet" {
  type =list(string)
}

variable "eks_ng_instance" {
  type = string
}

variable "availability_zone" {
  type = list(string)
}

variable "taint_key" {
  type = string
}

variable "taint_value" {
  type = string
}