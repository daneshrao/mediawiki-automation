########## This terraform script is to create an one time provisioning of the AWS infra ##########
########## Which hold the three tier architecture of the media wiki application ##########
########## resources created - VPC, IGW, NAT, PUBLIC SUBNET, PRIVATE SUBNET, SEC-GROUPS, APPSERVER, DB-SERVER ##########
########################################################################################################################
########## check the variables and the userdata.tpl scripts in the templates folder before provisioning ##########
########## USAGE: terraform init ##########
########## terraform apply ##########

# VPC resources
resource "aws_vpc" "mediawiki_vpc" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    {
      Name        = var.name,
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_internet_gateway" "mediawiki_igw" {
  vpc_id = aws_vpc.mediawiki_vpc.id

  tags = merge(
    {
      Name        = "mediawiki_igw",
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_route_table" "private" {
  count = length(var.private_subnet_cidr_blocks)

  vpc_id = aws_vpc.mediawiki_vpc.id

  tags = merge(
    {
      Name        = "PrivateRouteTable",
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_route" "private" {
  count = length(var.private_subnet_cidr_blocks)

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.mediawiki_nat[count.index].id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.mediawiki_vpc.id

  tags = merge(
    {
      Name        = "PublicRouteTable",
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.mediawiki_igw.id
}

resource "aws_subnet" "mediawiki_private" {
  count = length(var.private_subnet_cidr_blocks)
  vpc_id            = aws_vpc.mediawiki_vpc.id
  cidr_block        = var.private_subnet_cidr_blocks[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    {
      Name        = "PrivateSubnet",
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_subnet" "mediawiki_public" {
  count = length(var.public_subnet_cidr_blocks)
  vpc_id                  = aws_vpc.mediawiki_vpc.id
  cidr_block              = var.public_subnet_cidr_blocks[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name        = "PublicSubnet",
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_route_table_association" "mediawiki_private" {
  count = length(var.private_subnet_cidr_blocks)

  subnet_id      = aws_subnet.mediawiki_private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidr_blocks)

  subnet_id      = aws_subnet.mediawiki_public[count.index].id
  route_table_id = aws_route_table.public.id
}


#
# NAT resources
#
resource "aws_eip" "nat" {
  count = length(var.public_subnet_cidr_blocks)
  vpc   = true
}

resource "aws_nat_gateway" "mediawiki_nat" {
  depends_on = [aws_internet_gateway.mediawiki_igw]

  count = length(var.public_subnet_cidr_blocks)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.mediawiki_public[count.index].id

  tags = merge(
    {
      Name        = "gwNAT",
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )
}

#
# Webserver resources
#
resource "aws_security_group" "sg_mediawiki_appserver" {
  vpc_id = aws_vpc.mediawiki_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = merge(
    {
      Name        = "sg_mediawiki_appserver",
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )
}


resource "aws_security_group" "sg_mediawiki_dbserver" {
  vpc_id = aws_vpc.mediawiki_vpc.id

  ingress {
    description = "SSH only from internal VPC clients"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port   = 0
    to_port     = 3306
    protocol    = "TCP"
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "TCP"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = merge(
    {
      Name        = "sg_mediawiki_dbserver",
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )
}



resource "aws_network_interface_sg_attachment" "sg_attachment_mediawiki_appserver" {
  security_group_id    = aws_security_group.sg_mediawiki_dbserver.id
  network_interface_id = aws_instance.mediawiki_appserver.primary_network_interface_id
}

resource "tls_private_key" "mw_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "generated_key" {
  key_name   = "${var.keyname}"
  public_key = "${tls_private_key.mw_key.public_key_openssh}"

  provisioner "local-exec" {
    command = "echo '${tls_private_key.mw_key.private_key_pem}' > ./'${var.keyname}'.pem"
  }
}

resource "aws_instance" "mediawiki_appserver" {
  ami                         = var.ami
  availability_zone           = var.availability_zones[0]
  ebs_optimized               = var.ebs_optimized
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.sg_mediawiki_appserver.id]
  key_name                    = aws_key_pair.generated_key.key_name
  subnet_id                   = aws_subnet.mediawiki_public[0].id
  associate_public_ip_address = true

  tags = merge(
    {
      Name        = "mediawiki_appserver",
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )
  
  user_data = "${data.template_file.user_data.rendered}"
}

data "template_file" "user_data" {
  template = "${file("templates/user_data.tpl")}"

}


## output details to Ansible inventory file for ansible to deploy in the config management tool
resource "local_file" "AnsibleInventory" {
 content = templatefile("inventory.tmpl",
 {
  webserver-ip = aws_instance.mediawiki_appserver.public_ip
 }
 )
 filename = "inventory"
}


resource "aws_instance" "mediawiki_dbserver" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = [aws_security_group.sg_mediawiki_dbserver.id]
  subnet_id              = aws_subnet.mediawiki_private[0].id
  tags = merge(
    {
      Name        = "mediawiki_dbserver",
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )
}