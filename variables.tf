variable "region" {
  type = string
}

variable "account_id" {
  type = string
}

#Cloudwatch's variables
variable "eventbus_name" {
  type = string
}

variable "cwrule_name" {
  type = string
}

#Lambda's variables
variable "lambda_role_name" {
  type = string
}

variable "lambda_policy_name" {
  type = string
}

variable "function_name" {
  type = string
}

#SNS's variables
variable "topic_name" {
  type = string
}

variable "email" {
  type = string
}
