module "tags_labs" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git"
  namespace   = var.name
  environment = "dev"
  name        = "labs-chaosengineers"
  delimiter   = "_"

  tags = {
    owner = var.name
    type  = "labs"
  }
}

resource "aws_vpc" "k8s_lab" {
  cidr_block           = "10.0.0.0/16"
  tags                 = module.tags_labs.tags
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "lab_gateway" {
  vpc_id = aws_vpc.k8s_lab.id
  tags   = module.tags_labs.tags
}

resource "aws_route" "lab_internet_access" {
  route_table_id         = aws_vpc.k8s_lab.main_route_table_id
  gateway_id             = aws_internet_gateway.lab_gateway.id
  destination_cidr_block = "0.0.0.0/0"
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "sandbox" {
  vpc_id                  = aws_vpc.k8s_lab.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags                    = module.tags_labs.tags
}

variable "ing" {
  type = list(any)
  default = [
    { from = 80, to = 80 },
    { from = 8080, to = 8080 },
    { from = 443, to = 443 },
    { from = 22, to = 22 },
    { from = 9000, to = 9050 },
    { from = 9450, to = 9450 },
    { from = 30000, to = 32767 }
  ]
}

resource "aws_security_group" "sandbox" {
  vpc_id = aws_vpc.k8s_lab.id
  tags   = module.tags_labs.tags
  dynamic "ingress" {
    for_each = var.ing
    content {
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      from_port   = ingress.value.from
      to_port     = ingress.value.to
    }
  }
}

resource "aws_security_group" "sandbox" {
  vpc_id = aws_vpc.k8s_lab.id
  tags   = module.tags_labs.tags

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9450
    to_port     = 9450
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9010
    to_port     = 9010
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9020
    to_port     = 9020
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9030
    to_port     = 9030
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9040
    to_port     = 9040
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "lab_keypair" {
  key_name   = format("%s%s", var.name, "_keypair_2")
  public_key = file(var.public_key_path)
}

data "aws_ami" "latest_sandbox" {
  most_recent = true
  owners      = ["self"]
  name_regex  = "^${var.name}-sandbox-\\d*$"

  filter {
    name   = "name"
    values = ["${var.name}-sandbox-*"]
  }
}

resource "aws_instance" "sandbox" {
  ami                    = data.aws_ami.latest_sandbox.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.sandbox.id
  vpc_security_group_ids = [aws_security_group.sandbox.id]
  key_name               = aws_key_pair.lab_keypair.id

  root_block_device {
    volume_size = 100
    volume_type = "gp2"
  }

  tags = module.tags_labs.tags
}
