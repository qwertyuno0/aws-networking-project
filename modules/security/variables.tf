variable "vpc_id" {
  description = "vpc id"
  type        = string
}

variable "public_subnet_ids" {
  description = "ids public subnet"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "ids private subnet "
  type        = list(string)
}

variable "my_ip" {
  description = "public ip in cidr"
  type        = string
}

variable "vpc_cidr" {
  description = "cidr block of vpc"
  type        = string
}

