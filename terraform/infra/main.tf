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