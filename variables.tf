variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "resource_group_name" {
  type    = string
}

variable "location" {
  type    = string
}

variable "acr_name" {
  type    = string 
}

variable "prefix" {
  type    = string
}

variable "python_image_name" {
  type    = string
}

variable "spring_image_name" {
  type    = string
}

variable "python_app_name" {
  type    = string
}

variable "spring_app_name" {
  type    = string
}

variable "python_port" {
  type    = string
}

variable "spring_port" {
  type    = string
}

variable "acr_username" {
  type = string
}

variable "acr_password" {
  description = "ACR Password"
  type        = string
}