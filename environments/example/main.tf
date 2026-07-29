# Example environment: instantiates the six reusable modules and wires them
# together into one deployable stack. See README.md for deploy instructions and
# cost warnings.

module "vpc" {
  source = "../../modules/vpc"

  project     = var.project
  environment = var.environment

  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  single_nat_gateway   = var.single_nat_gateway
}

module "s3" {
  source = "../../modules/s3"

  project     = var.project
  environment = var.environment

  bucket_suffix = var.bucket_suffix
}

module "iam" {
  source = "../../modules/iam"

  project     = var.project
  environment = var.environment

  # s3 -> iam: the role is scoped to exactly this bucket.
  s3_bucket_arn = module.s3.bucket_arn
}

module "ec2" {
  source = "../../modules/ec2"

  project     = var.project
  environment = var.environment

  # vpc -> ec2 (private subnets) and iam -> ec2 (instance profile).
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.private_subnet_ids
  iam_instance_profile = module.iam.ec2_instance_profile_name

  instance_type = var.instance_type
  app_port      = var.app_port

  # No ALB in this scope: allow the app port only from inside the VPC.
  ingress_cidr_blocks = [var.vpc_cidr]

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity
}

module "rds" {
  source = "../../modules/rds"

  project     = var.project
  environment = var.environment

  # vpc -> rds (private subnets) and ec2 -> rds (only the app SG may connect).
  vpc_id                    = module.vpc.vpc_id
  subnet_ids                = module.vpc.private_subnet_ids
  allowed_security_group_id = module.ec2.security_group_id

  engine_version          = var.db_engine_version
  instance_class          = var.db_instance_class
  allocated_storage       = var.db_allocated_storage
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  multi_az                = var.db_multi_az
  backup_retention_period = var.db_backup_retention_period
}

module "route53" {
  source = "../../modules/route53"
  count  = var.create_dns ? 1 : 0

  project     = var.project
  environment = var.environment

  domain_name = var.domain_name
  create_zone = true

  # An ALB is out of scope here, so there is no single entry point to alias to.
  # When a load balancer is added, pass its target_dns_name / target_zone_id and
  # set create_alias_record = true.
  create_alias_record = false
}
