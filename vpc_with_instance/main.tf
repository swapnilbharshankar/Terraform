provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

#################################################
################## VPC creation #################
#################################################

resource "aws_vpc" "main" {
  cidr_block = "10.10.0.0/16"
  tags {
    Name = "Terraform VPC"
  }
}

##################################################
############# Public Subnet Creation #############
##################################################

resource "aws_subnet" "public_subnet" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "10.10.1.0/24"
  map_public_ip_on_launch = true
  tags {
     Name = "Public_Subnet"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }

  tags {
    Name = "Public_Route_Table"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id	 = "${aws_subnet.public_subnet.id}" 
  route_table_id = "${aws_route_table.public.id}"
}

##################################################
############# Private Subnet Creation #############
##################################################

resource "aws_subnet" "private_subnet" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "10.10.2.0/24"
  tags {
     Name = "Private_Subnet"
  }
}

resource "aws_eip" "nat" {
  vpc = "True"
  tags {
    Name = "gw_NAT"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.private_subnet.id}"
}

resource "aws_route_table" "private_route" {
  vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.nat.id}"
  }
  tags {
    Name = "Private_Route_Table"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id	 = "${aws_subnet.private_subnet.id}"  
  route_table_id = "${aws_route_table.private_route.id}"
}

###############################################
############# create SG #######################
###############################################

resource "aws_security_group" "Web" {
  name = "Web Security Group"
  ingress = {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress = {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  vpc_id = "${aws_vpc.main.id}"
  tags = {
    Name = "WEB SG"
  }
}


###############################################
############ Key Pair #########################
###############################################

resource "aws_key_pair" "key" {
  key_name = "Terrafrom_key"
  public_key = "${file("${var.key_path}")}"
}

##############################################
############## Instance ######################
##############################################

resource "aws_instance" "Web" {
  ami = "${var.ami}"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.key.id}"
  subnet_id = "${aws_subnet.public_subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.Web.id}"]
  tags = {
    Name = "WEB"
  }
}
