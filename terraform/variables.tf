variable "aws_region" {
  description = "Región de AWS donde se desplegarán los recursos"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Nombre utilizado para identificar el proyecto"
  type        = string
  default     = "ecb-daily-exchange-rates"
}