# Root module — wires everything together.
# Person 1 owns the network module. Persons 2-4 add their module blocks here.

module "network" {
  source = "./modules/network"

  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
  enable_nat   = var.enable_nat
}

# ── Person 2
module "compute" {
  source            = "./modules/compute"
  project_name      = var.project_name
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  app_subnet_ids    = module.network.app_subnet_ids
  alb_sg_id         = module.network.alb_sg_id
  app_sg_id         = module.network.app_sg_id
  database_url      = module.data.database_url
  uploads_bucket    = module.data.uploads_bucket
}

# ── Person 3
module "data" {
  source        = "./modules/data"
  project_name  = var.project_name
  db_subnet_ids = module.network.db_subnet_ids
  db_sg_id      = module.network.db_sg_id
}

# ── Person 4
module "monitoring" {
  source                   = "./modules/monitoring"
  project_name             = var.project_name
  asg_name                 = module.compute.asg_name
  target_group_arn         = module.compute.target_group_arn
  load_balancer_arn_suffix = module.compute.load_balancer_arn_suffix
  alert_email     = "sopanha.ryy@gmail.com" 
}
