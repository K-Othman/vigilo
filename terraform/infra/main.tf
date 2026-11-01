module "networking" {
  source = "./modules/networking"

  name                      = var.name
  vpc_cidr                  = var.vpc_cidr
  azs                       = var.azs
  vigilo_public_subnet      = var.public_subnets
  vigilo_app_private_subnet = var.app_subnets
  vigilo_db_private_subnet  = var.db_subnets
}

module "security-groups" {
  source = "./modules/security-groups"

  name     = var.name
  vpc_id   = module.networking.vpc_id
  vpc_cidr = var.vpc_cidr
}

module "acm" {
  source = "./modules/acm"

  domain_name = var.domain_name
  zone_name   = var.zone_name
}

module "alb" {
  source = "./modules/alb"

  name              = var.name
  vpc_id            = module.networking.vpc_id
  alb_sg_id         = module.security-groups.alb_sg_id
  public_subnet_ids = module.networking.public_subnet_ids
  certificate_arn   = module.acm.certificate_arn
}

module "rds" {
  source = "./modules/rds"

  name          = var.name
  db_subnet_ids = module.networking.private_db_subnet_ids
  db_sg_id      = module.security-groups.alb_sg_id
}

module "ecs" {
  source = "./modules/ecs"

  name             = var.name
  aws_region       = var.aws_region
  image            = var.app_image
  app_subnet_ids   = module.networking.private_app_subnet_ids
  web_sg_id        = module.security-groups.web_sg_id
  worker_sg_id     = module.security-groups.worker_sg_id
  target_group_arn = module.alb.target_group_arn
  db_endpoint      = module.rds.db_endpoint
  db_port          = module.rds.db_port
  db_name          = module.rds.db_name
  db_username      = module.rds.db_username
  db_secret_arn    = module.rds.db_secret_arn

  depends_on = [module.alb]
}