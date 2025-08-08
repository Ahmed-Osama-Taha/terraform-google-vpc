variable "project_id" { 
    type = string 
}
variable "region"     { 
    type = string 
}
variable "vpc_name"   {
     type = string
}
variable "subnets" {
  type = map(object({
    cidr = string
    region = string
    enable_flow_logs = bool
  }))
}
