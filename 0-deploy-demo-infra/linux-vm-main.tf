###################################
## Virtual Machine Module - Main ##
###################################

# Create Elastic IP for the EC2 instance
resource "aws_eip" "linux-eip" {
  count = 4
  vpc   = true
  tags = {
    Name        = "${lower(var.app_name)}-${var.app_environment}-linux-eip"
    Environment = var.app_environment
  }
}

# Define the security group for the Linux server
resource "aws_security_group" "aws-linux-sg" {
  name        = "${lower(var.app_name)}-${var.app_environment}-linux-sg"
  description = "Allow incoming HTTP connections"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming HTTP connections"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming HTTPS connections"
  }

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming HTTPS connections"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming SSH connections"
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    self        = "true"
    description = "Allow internal postgres connections"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${lower(var.app_name)}-${var.app_environment}-linux-sg"
    Environment = var.app_environment
  }
}

# Create EC2 Instance
resource "aws_instance" "linux-server" {
  count                       = 4
  ami                         = data.aws_ami.rhel_8_7.id
  instance_type               = var.linux_instance_type
  subnet_id                   = aws_subnet.public-subnet.id
  vpc_security_group_ids      = [aws_security_group.aws-linux-sg.id]
  associate_public_ip_address = var.linux_associate_public_ip_address
  source_dest_check           = false
  key_name                    = aws_key_pair.key_pair.key_name
  user_data                   = file("aws-user-data.sh")

  # root disk
  root_block_device {
    volume_size           = var.linux_root_volume_size
    volume_type           = var.linux_root_volume_type
    delete_on_termination = true
    encrypted             = true
  }

  # extra disk
  ebs_block_device {
    device_name           = "/dev/xvda"
    volume_size           = var.linux_data_volume_size
    volume_type           = var.linux_data_volume_type
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name        = "${lower(var.app_name)}-${var.app_environment}-linux-server"
    Environment = var.app_environment
  }

  # Ensure the machine has started with a remote exec
  provisioner "remote-exec" {
    inline = ["echo hello world"]

    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(format("%s.%s", self.key_name, "pem"))
    }
  }
}

# Associate Elastic IP to Linux Server
resource "aws_eip_association" "linux-eip-association" {
  count         = 4
  instance_id   = aws_instance.linux-server[count.index].id
  allocation_id = aws_eip.linux-eip[count.index].id
}

# Ensure cloudflare dns for controller is set to the new public addresses
resource "cloudflare_record" "cloudflare-controlller" {
  zone_id = var.cloudflare_zone_id
  name    = "controller.rhdemo.win"
  type    = "A"
  value   = aws_instance.linux-server[0].public_ip
}

# Ensure cloudflare dns for sso is set to the new public address
resource "cloudflare_record" "cloudflare-sso" {
  zone_id = var.cloudflare_zone_id
  name    = "sso.rhdemo.win"
  type    = "A"
  value   = aws_instance.linux-server[1].public_ip
}

# Ensure cloudflare dns for hub is set to the new public addresses
resource "cloudflare_record" "cloudflare-hub" {
  zone_id = var.cloudflare_zone_id
  name    = "hub.rhdemo.win"
  type    = "A"
  value   = aws_instance.linux-server[2].public_ip
}

# Ensure cloudflare dns for catalog is set to the new public addresses
resource "cloudflare_record" "cloudflare-catalog" {
  zone_id = var.cloudflare_zone_id
  name    = "catalog.rhdemo.win"
  type    = "A"
  value   = aws_instance.linux-server[3].public_ip
}

resource "cloudflare_record" "cloudflare-database" {
  zone_id = var.cloudflare_zone_id
  name    = "database.rhdemo.win"
  type    = "A"
  value   = aws_instance.linux-server[0].private_ip
}

resource "null_resource" "configure-ec2" {
  count = 4

  # Run ansible playbook post create
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '${aws_instance.linux-server[count.index].public_ip},' --private-key '${aws_instance.linux-server[count.index].key_name}.pem' demo-infra-configure.yaml"
  }
}
