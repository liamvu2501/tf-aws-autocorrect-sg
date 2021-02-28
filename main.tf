module "cloudwatch" {
  source        = "./modules/cloudwatch"
  eventbus_name = var.eventbus_name
  cwrule_name   = var.cwrule_name
  lambda_arn    = module.lambda.lambda_arn
}

module "lambda" {
  source             = "./modules/lambda"
  lambda_role_name   = var.lambda_role_name
  lambda_policy_name = var.lambda_policy_name
  region             = var.region
  account_id         = var.account_id
  topic_name         = var.topic_name
  function_name      = var.function_name
  topic_arn          = module.sns.topic_arn
  cwrule_arn         = module.cloudwatch.cwrule_arn
}

module "sns" {
  source     = "./modules/sns"
  topic_name = var.topic_name
  email      = var.email
}