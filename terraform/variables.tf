variable "project_name" {
    type = string
    default = "ecom-data-mesh"
}

variable "aws_region"{
    type = string
    default = "eu-central-1"
}

variable "aws_access_key" {
    type = string
    default = ""
    sensitive = true
}

variable "aws_secret_key"{
    type = string
    default = ""
    sensitive = true
}