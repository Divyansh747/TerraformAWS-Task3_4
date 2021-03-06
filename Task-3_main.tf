provider "aws" { 
  region = "ap-south-1" 
  profile = "TEST_USER" 
} 

resource "aws_vpc" "testvpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"  

  tags = {
    Name = "testvpc"
  }
}

resource "aws_subnet" "pubsubnet" {
  vpc_id     = "${aws_vpc.testvpc.id}"
  cidr_block = "192.168.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "pubsubnet"
  }
}

resource "aws_subnet" "privsubnet" {
  vpc_id     = "${aws_vpc.testvpc.id}"
  cidr_block = "192.168.2.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "privsubnet"
  }
}

resource "aws_internet_gateway" "testgw" {
  vpc_id = "${aws_vpc.testvpc.id}"

  tags = {
    Name = "testgw"
  }
}

resource "aws_route_table" "testroute" {
  vpc_id = "${aws_vpc.testvpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.testgw.id}"
  }

  tags = {
    Name = "testroute"
  }
}

resource "aws_route_table_association" "testa" {
  subnet_id      = aws_subnet.pubsubnet.id
  route_table_id = aws_route_table.testroute.id
}

resource "aws_security_group" "testsg" {
  name        = "allow_http_ssh"
  description = "Allow HTTP SSH traffic"
  vpc_id      = "${aws_vpc.testvpc.id}"

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "testsg"
  }
}

resource "aws_security_group" "mysqlsg" {
  name        = "allow_mysql"
  description = "Allow ssh and mysql inbound traffic"
  vpc_id      = "${aws_vpc.testvpc.id}"

  ingress {
    description = "MYSQL from VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.testsg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_mysql"
  }
}

resource "aws_instance" "ec2_wordpress" {
  ami           = "ami-000cbce3e1b899ebd"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.pubsubnet.id
  vpc_security_group_ids = [ aws_security_group.testsg.id ]
  associate_public_ip_address = true
  key_name      = "web-key"

  tags = {
    Name = "ec2_wordpress"
  }
}

resource "aws_instance" "ec2_mysql" {
  ami           = "ami-0019ac6129392a0f2"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.privsubnet.id
  vpc_security_group_ids = [ aws_security_group.mysqlsg.id ]
  key_name      = "web-key"

  tags = {
    Name = "ec2_mysql"
  }
}
