# variables.tf
# Archivo de declaracion de variables
###############################################################################
# 
# Programador: Francisco E. Galeana G.
# 
# Fecha Creación: 22-nov-2024
# Fecha Modificación: 22-nov-2024 
# 
###############################################################################

# Access key
variable "AWS_Key" {
  description = "AWS access key"
  type = string
}

# Secret key
variable "AWS_Secret" {
  description = "Secret key"
  type = string
}

# AWS region
variable "Region_AWS" {
  description = "Region where project will be developed"
  default = "us-east-1"
}


# Database username
variable "db_username" {
  description = "Database username"
  type = string
}

# Database password
variable "db_password" {
  description = "User password for database"
  type = string
}