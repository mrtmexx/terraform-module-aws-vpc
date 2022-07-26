variable "region" {
  type = string
}

variable "environment" {
  type = object({
    short = string
    full  = string
  })
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnets" {
  type = map(string)
}

variable "private_subnets" {
  type = map(string)
  default = {}
}

variable "local_subnets" {
  type = map(string)
}

variable "single_nat_gateway" {
  type    = bool
  default = true
}

variable "public_subnet_tags" {
  type    = map(string)
  default = {}
}

variable "private_subnet_tags" {
  type    = map(string)
  default = {}
}
