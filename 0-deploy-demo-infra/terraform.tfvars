# Application Definition 
app_name        = "rhel-demo" # Do NOT enter any spaces
app_environment = "dev"       # Dev, Test, Staging, Prod, etc

# Network
vpc_cidr           = "10.11.0.0/16"
public_subnet_cidr = "10.11.1.0/24"

# AWS Settings
aws_region = "ap-southeast-2"

# Linux Virtual Machine
linux_instance_type               = "t2.large"
linux_associate_public_ip_address = true
linux_root_volume_size            = 20
linux_root_volume_type            = "gp2"
linux_data_volume_size            = 20
linux_data_volume_type            = "gp2"
