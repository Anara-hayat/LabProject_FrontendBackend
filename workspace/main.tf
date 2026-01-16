terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region                   = var.aws_region
  shared_config_files      = ["~/.aws/config"]
  shared_credentials_files = ["~/.aws/credentials"]
}

data "http" "my_ip" {
  url = "https://icanhazip.com"
}

resource "aws_key_pair" "lab_key" {
  key_name   = "${var.env_prefix}-key"
  public_key = file(var.public_key_path)
}

module "network" {
  source            = "./modules/subnet"
  env_prefix        = var.env_prefix
  vpc_cidr_block    = var.vpc_cidr_block
  subnet_cidr_block = var.subnet_cidr_block
  availability_zone = var.availability_zone
  my_ip             = local.my_ip
}

module "frontend" {
  source         = "./modules/webserver"
  env_prefix     = var.env_prefix
  name_suffix    = "frontend"
  instance_count = 1
  ami_id         = var.ami_id
  instance_type  = var.instance_type
  subnet_id      = module.network.subnet_id
  security_group = module.network.web_sg_id
  key_name = aws_key_pair.lab_key.key_name
}

module "backend" {
  source         = "./modules/webserver"
  env_prefix     = var.env_prefix
  name_suffix    = "backend"
  instance_count = 3
  ami_id         = var.ami_id
  instance_type  = var.instance_type
  subnet_id      = module.network.subnet_id
  security_group = module.network.web_sg_id
  key_name = aws_key_pair.lab_key.key_name
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/ansible/inventory/generated_hosts.ini"

  content = templatefile(
    "${path.module}/ansible/inventory/hosts.tpl",
    {
      frontend_ip = module.frontend.public_ips[0]
      backend_ips = module.backend.public_ips
    }
  )
}

resource "null_resource" "ansible_provision" {
  triggers = {
    frontend_ip = module.frontend.public_ips[0]
    backend_ips = join(",", module.backend.public_ips)
  }

  depends_on = [
    local_file.ansible_inventory,
    module.frontend,
    module.backend
  ]

  provisioner "local-exec" {
    command = <<-EOT
      cd ansible
      ANSIBLE_HOST_KEY_CHECKING=False \
      ANSIBLE_ROLES_PATH=roles \
      ansible-playbook \
        -i inventory/generated_hosts.ini \
        playbooks/site.yaml
    EOT
  }
}