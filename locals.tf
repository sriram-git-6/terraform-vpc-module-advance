locals {
  azs = slice(data.aws_availability_zones.available.names,0,2) # 0 means first element, 2 means ending index It indicates that the slicing should include elements up to, but not including, the element at index 2
}      # if you assign the value in locals, users cannot override.

output "azs" {
    value = local.azs
  
}