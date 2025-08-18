resource "aws_ssm_parameter" "image_tag" {
  name  = var.ssm_image_tag_param
  type  = "String"
  value = "latest"
}
