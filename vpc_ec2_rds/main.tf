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

resource "aws_subnet" "private_subnet_a" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "10.10.2.0/24"
  tags {
     Name = "Private_Subnet_a"
  }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "10.10.3.0/24"
  tags {
     Name = "Private_Subnet_b"
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
  subnet_id     = "${aws_subnet.private_subnet_a.id}"
  subnet_id = "${aws_subnet.private_subnet_b.id}"
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

resource "aws_route_table_association" "private_a" {
  subnet_id	 = "${aws_subnet.private_subnet_a.id}"  
  subnet_id	 = "${aws_subnet.private_subnet_b.id}"
  route_table_id = "${aws_route_table.private_route.id}"
}

#resource "aws_route_table_association" "private_b" {
#  subnet_id	 = "${aws_subnet.private_subnet_b.id}"  
#  route_table_id = "${aws_route_table.private_route.id}"
#}

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
  egress = {
    from_port = 0
    to_port = 0
    protocol = "-1"
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
  user_data = <<HEREDOC
  #!/bin/bash
  yum update -y
  yum install -y httpd24 php56 php56-mysqlnd
  service httpd start
  chkconfig httpd on
  echo "<html>" >> /var/www/html/index.html
  echo "<h1>" >> /var/www/html/index.html
  echo "<center>" >> /var/www/html/index.html
  echo "Hello World" >> /var/www/html/index.html
  echo "</center>" >> /var/www/html/index.html
  echo "</h1>" >> /var/www/html/index.html
  echo "</html>" >> /var/www/html/index.html
HEREDOC
}

##############################################
############# DB Subnet ######################
##############################################

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = ["${aws_subnet.private_subnet_a.id}", "${aws_subnet.private_subnet_b.id}" ] 

  tags {
    Name = "Terraform DB SG"
  }
}

##############################################
############# DB SG ##########################
##############################################

resource "aws_security_group" "db_Web" {
  name = "DB Web Security Group"
  ingress = {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["10.10.0.0/16"]
  }
  vpc_id = "${aws_vpc.main.id}"
  tags = {
    Name = "DB WEB SG"
  }
}


##############################################
############ DB Instance #####################
##############################################

resource "aws_db_instance" "default" {
  allocated_storage    = 10
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  db_subnet_group_name = "${aws_db_subnet_group.default.id}"
  vpc_security_group_ids = ["${aws_security_group.db_Web.id}"]
  name                 = "WEB"
  username             = "terraform"
  password             = "terraform"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot = "True"
  identifier = "web-db"
  tags = {
    Name = "Terraform_DB"
  }
}
