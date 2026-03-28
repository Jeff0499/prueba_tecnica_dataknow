variable "environment" {
  description = "Entorno (dev, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Región de Azure"
  type        = string
  default     = "East US 2"
}

variable "resource_group_name" {
  description = "Nombre del grupo de recursos"
  type        = string
  default     = "rg-prueba-tecnica"
}

variable "tags" {
  description = "Etiquetas comunes"
  type        = map(string)
  default = {
    Project     = "PruebaTecnica"
    Environment = "dev"
    Owner       = "Jeferson"
  }
}

# Variables para backend remoto (se usan en el backend "azurerm")
# variable "storage_account_name" {
#   description = "Nombre de la cuenta de almacenamiento para el estado remoto"
#   type        = string
# }

# variable "container_name" {
#   description = "Contenedor para el estado remoto"
#   type        = string
#   default     = "terraform-state"
# }

# variable "key" {
#   description = "Clave (archivo) del estado"
#   type        = string
#   default     = "prueba-tecnica.tfstate"
# }