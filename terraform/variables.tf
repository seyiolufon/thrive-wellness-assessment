variable "project_name" {
  type    = string
  default = "thrive"
}
variable "region" {
  type = string
  default = "us-east-1"
}

variable "az_count" {
  type = number
  default = 2
}

variable "desired_capacity"    {
  type = number
  default = 2
}

variable "max_size"   {
  type = number
  default = 3
}

variable "instance_type"       {
  type = string
  default = "t3.micro"
}

variable "allowed_cidrs"       {
  type = list(string)
  default = ["0.0.0.0/0"]
}

variable "ssm_image_tag_param" {
  type = string
  default = "/hello-app/image_tag"
}

variable "acm_certificate_arn" {
  type = string
  default = ""
}
