module "networking" {
  source = "./modules/networking"

  name                      = var.project_name
  vpc_cidr                  = var.vpc_cidr
  azs                       = var.azs
  vigilo_public_subnet      = var.public_subnets
  vigilo_app_private_subnet = var.app_subnets
  vigilo_db_private_subnet  = var.db_subnets
}