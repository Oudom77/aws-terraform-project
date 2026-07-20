# Root module — wires everything together.
# Person 1 owns the network module. Persons 2-4 add their module blocks here.

module "network" {
  source = "./modules/network"

  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
  enable_nat   = var.enable_nat
}

module "compute" {
  source            = "./modules/compute"
  project_name      = var.project_name
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids # ALB goes here
  app_subnet_ids    = module.network.app_subnet_ids    # EC2/ASG goes here
  alb_sg_id         = module.network.alb_sg_id
  app_sg_id         = module.network.app_sg_id
}

# ── Person 3 adds (example): ─────────────────────────────────────────────────
# module "data" {
#   source        = "./modules/data"
#   project_name  = var.project_name
#   db_subnet_ids = module.network.db_subnet_ids
#   db_sg_id      = module.network.db_sg_id
# }

# ── Person 4
module "monitoring" {
  source       = "./modules/monitoring"
  project_name = var.project_name
}
