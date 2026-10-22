module "vigilo-vpc" {
  source = "./modules/networking"

  project_name = "vigilo"
  repository_name = "K-Othman/vigilo"
  vpc_cidr = "10.0.0.0/16"
  azs = ["eu-west-2a", "eu-west-2b"]
  vigilo_public_subnet = ["10.0.1.0/24", "10.0.2.0/24"]
  vigilo_app_private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]
  vigilo_db_private_subnets = ["10.0.21.0/24", "10.0.22.0/24"]

}