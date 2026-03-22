variable "region" {
  type    = string
  default = "eu-west-3"
}

variable "env" {
  type    = string
  default = "prod"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "public_key" {
  type        = string
  description = "Clé publique SSH pour accéder à l'EC2 (injectée via GitHub Actions secret)"
  sensitive   = true
}
