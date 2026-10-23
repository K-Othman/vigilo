module "networking" {
  source = "./modules/networking"

  project_name               = var.project_name
  vpc_cidr                   = var.vpc_cidr
  azs                        = var.azs
  vigilo_public_subnet       = var.public_subnets
  vigilo_app_private_subnets = var.app_subnets
  vigilo_db_private_subnets  = var.db_subnets
}