variable "cidr_block" {
 }

variable "enable_dns_hostnames" {
    default = true
}

variable "enable_dns_support" {
    default = true
}

variable "project_name"{
}

variable "common_tags" {  # optional but good to give tags
    default = {}
}

variable "vpc_tags" {
    default = {}
  }

variable "igw_tags" {
    default = {}
  }

variable "public_subnet_cidr" {
    type = list
  validation {
    condition = length(var.public_subnet_cidr) == 2
    error_message = "please provide only 2 public subnet cidr's only" 
  }
}

variable "private_subnet_cidr" {
    type = list
   validation {
     condition = length(var.private_subnet_cidr) ==2
     error_message = "please provide only 2 private subnet cidr's only"
   }  
}

variable "database_subnet_cidr" {
    type = list
  validation {
    condition = length(var.database_subnet_cidr) ==2
    error_message = "please provide only 2 database subnet cidr's only"
  }
}

variable "natgateway_tags" {
    default = {}
  }

variable "public_route_table_tags" {
    default = {}
}
  
variable "private_route_table_tags" {
  default = {}
 }  

variable "database_route_table_tags" {
  default = {}
 }  

variable "db_subnet_group_tags"{
  default = {}
}