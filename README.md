Lab Project: Terraform + Ansible Roles - Nginx Frontend with HA Backend HTTPD Servers
Project Overview
This project demonstrates a multi-tier AWS infrastructure deployment using Terraform for infrastructure provisioning and Ansible roles for configuration management. The architecture consists of an Nginx frontend acting as a reverse proxy/load balancer for three Apache HTTPD backend servers, with high availability configuration.

Architecture
Infrastructure Components

1 Frontend Server: Nginx reverse proxy/load balancer
3 Backend Servers: Apache HTTPD servers (2 active + 1 backup)
VPC Setup: Custom VPC with public subnet, Internet Gateway, and Route Tables
Security Groups: Configured for SSH (from my IP) and HTTP (public access)

High Availability Design

Load Balancing Strategy: Round-robin between 2 primary backends
Backup Configuration: 1 backup backend activates when primaries fail
Automatic Failover: Nginx automatically routes to backup on primary failure


Project Structure
LabProject_FrontendBackend/
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output definitions
├── locals.tf                  # Local values and IP detection
├── terraform.tfvars           # Variable values (not committed)
├── modules/
│   ├── subnet/                # VPC and subnet module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── webserver/             # EC2 instance module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── ansible/
│   ├── ansible.cfg            # Ansible configuration
│   ├── inventory/
│   │   └── hosts              # Static inventory file
│   ├── playbooks/
│   │   └── site.yaml          # Main playbook using roles
│   └── roles/
│       ├── common/            # Base configuration role (optional)
│       │   └── tasks/main.yml
│       ├── frontend/          # Nginx frontend role
│       │   ├── tasks/main.yml
│       │   ├── handlers/main.yml
│       │   └── templates/nginx_frontend.conf.j2
│       └── backend/           # HTTPD backend role
│           ├── tasks/main.yml
│           ├── handlers/main.yml
│           └── templates/backend_index.html.j2
├── screenshots/               # Testing screenshots
├── .gitignore
└── README.md

Key Features Implemented
Terraform Infrastructure 

 VPC with custom CIDR block
 Public subnet with Internet Gateway
 Route table with default route to IGW
 Security groups with proper SSH and HTTP rules
 Dynamic IP detection for SSH access
 1 frontend + 3 backend EC2 instances
 Meaningful tags and variable usage
 Modular design with reusable components

Ansible Roles & Structure

 Proper role-based architecture (not single playbook)
 Separate frontend role for Nginx configuration
 Separate backend role for HTTPD configuration
 Optional common role for shared tasks
 Jinja2 templates for dynamic configuration
 Handlers for service management
 Sensible defaults and variables

Nginx & HTTPD Behavior

 All 3 backends running HTTPD with distinct content
 Each backend serves unique identification page
 Nginx upstream with 2 primary + 1 backup servers
 Round-robin load balancing between primaries
 Automatic failover to backup on primary failure
 Verified HA behavior with service stop tests

Terraform-Ansible Automation

 Ansible automatically triggered via null_resource
 Single terraform apply -auto-approve deploys everything
 No manual Ansible commands required
 Idempotent re-runs (no errors on re-apply)
 Proper dependency management with depends_on

 Code Quality & Documentation 

 Clear directory structure
 Comprehensive comments and documentation
 Meaningful variable naming
 Clean Git history (no secrets/state files)
 Proper .gitignore configuration

Prerequisites

GitHub Codespace or Linux environment
Terraform (v1.0+)
Ansible (v2.9+)
AWS CLI configured with credentials
AWS Account with EC2 permissions
SSH Key Pair (Ed25519 or RSA)

Configuration
1. AWS Credentials
Ensure AWS credentials are configured:
bashaws configure
2. Terraform Variables
Create terraform.tfvars with your values:
hclvpc_cidr_block    = "10.0.0.0/16"
subnet_cidr_block = "10.0.1.0/24"
availability_zone = "us-east-1a"
env_prefix        = "dev"
instance_type     = "t2.micro"
public_key        = "~/.ssh/id_ed25519.pub"
private_key       = "~/.ssh/id_ed25519"
3. Ansible Configuration
The ansible/ansible.cfg is pre-configured:
ini[defaults]
host_key_checking = False
interpreter_python = /usr/bin/python3

Deployment
One-Command Deployment
bashterraform init
terraform apply -auto-approve
This single command:

Creates VPC, subnet, and networking components
Provisions security groups
Launches 1 frontend + 3 backend EC2 instances
Automatically runs Ansible playbooks
Configures Nginx and HTTPD services
Sets up HA load balancing

Manual Steps (if needed)
bash# Initialize Terraform
terraform init

# Plan infrastructure
terraform plan

# Apply configuration
terraform apply -auto-approve

# View outputs
terraform output

# (Optional) Manually run Ansible
cd ansible
ansible-playbook -i inventory/hosts playbooks/site.yaml

Testing & Verification
1. Check Backend Servers
Each backend serves unique content:
bashcurl http://<backend-1-ip>/
curl http://<backend-2-ip>/
curl http://<backend-3-ip>/
Expected output shows distinct backend identification.
2. Test Load Balancing
Access frontend multiple times:
bashfor i in {1..10}; do curl http://<frontend-ip>/; done
Expected: Alternating responses between Backend 1 and Backend 2.
3. Test High Availability (Backup)
Stop primary backends:
bashssh ec2-user@<backend-1-ip> "sudo systemctl stop httpd"
ssh ec2-user@<backend-2-ip> "sudo systemctl stop httpd"
Access frontend:
bashcurl http://<frontend-ip>/
Expected: Backup backend (Backend 3) responds automatically.
4. Test Idempotence
bashterraform apply -auto-approve
Expected: No changes, all resources already in desired state.

Outputs
After deployment, Terraform provides:
hclfrontend_public_ip  = "54.XXX.XXX.XXX"
backend_public_ips  = ["3.XXX.XXX.XXX", "34.XXX.XXX.XXX", "52.XXX.XXX.XXX"]
backend_private_ips = ["10.0.1.10", "10.0.1.11", "10.0.1.12"]

Ansible Roles Details
Backend Role (roles/backend/)

Installs Apache HTTPD
Deploys unique index.html per server
Uses Jinja2 template with inventory hostname
Ensures service is enabled and running

Frontend Role (roles/frontend/)

Installs Nginx
Configures upstream with backend private IPs
Sets 2 primary + 1 backup server
Uses handler for service restart on config change

Common Role (roles/common/) - Optional

Base system updates
Common package installation
Firewall configuration


Security

SSH access restricted to my public IP only
HTTP access allowed from internet (0.0.0.0/0)
Private keys not committed to repository
Security groups follow least privilege principle
Backend communication uses private IPs

Cleanup
Destroy all resources:
bashterraform destroy -auto-approve
