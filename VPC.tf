provider "aws" {
  region   = "ap-south-1"
  profile  = "sahiba"
}

resource "aws_vpc" "myvpc" {
  cidr_block = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"

  tags = {
	Name = "myvpc"
}
}

resource "aws_subnet" "publicsub" {
  vpc_id     = "${aws_vpc.myvpc.id}"
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"
  depends_on = [
    aws_vpc.myvpc,
  ]

  tags = {
    Name = "publicsub"
  }
}

resource "aws_subnet" "privatesub" {
  vpc_id     = "${aws_vpc.myvpc.id}"
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = "false"
  depends_on = [
    aws_vpc.myvpc,
  ]

  tags = {
    Name = "privatesub"
  }
}

resource "aws_internet_gateway" "nicrogg" {
  vpc_id = "${aws_vpc.myvpc.id}"
  depends_on = [
    aws_vpc.myvpc,
  ]

  tags = {
    Name = "nicrogg"
  }
}

resource "aws_route_table" "nicro" {
  vpc_id = "${aws_vpc.myvpc.id}"
 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.nicrogg.id}"
  }
  depends_on = [
    aws_vpc.myvpc,
  ]

  tags = {
    Name = "nicro"
  }
}

resource "aws_route_table_association" "associate" {
  subnet_id      = "${aws_subnet.publicsub.id}"
  route_table_id = "${aws_route_table.nicro.id}"
  depends_on = [
    aws_subnet.publicsub,
  ]
}

resource "aws_security_group" "mywpsg" {
  name        = "mywpsg"
  description = "Allow TLS inbound traffic"
  vpc_id      = "${aws_vpc.myvpc.id}"

 ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 ingress {
    description = "ssh"
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

  depends_on = [
    aws_vpc.myvpc,
  ]

  tags = {
    Name = "mywpsg"
  }
}
resource "aws_instance" "wordpressOS" {
  ami           = "ami-004a955bfb611bf13"
  instance_type = "t2.micro"
  key_name      = "keycloud"
  subnet_id =  aws_subnet.publicsub.id
  vpc_security_group_ids = [ "${aws_security_group.mywpsg.id}" ]
  tags = {
    Name = "wordpressOS"
  }

}

resource "aws_security_group" "mysqlsg" {
  name        = "basic"
  description = "Allow TLS inbound traffic"
  vpc_id      = "${aws_vpc.myvpc.id}"

  ingress {
    description = "mysql"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  depends_on = [
    aws_vpc.myvpc,
  ]

  tags = {
    Name = "mysqlsg"
  }
}

resource "aws_instance" "mysqlOS" {
  ami           = "ami-08706cb5f68222d09"
  instance_type = "t2.micro"
  key_name      = "keycloud"
  subnet_id =  aws_subnet.privatesub.id
  vpc_security_group_ids = [ "${aws_security_group.mysqlsg.id}" ]
  tags = {
    Name = "mysqlOS"
  }
}

output "IP_of_wp" {
  value = aws_instance.wordpressOS.public_ip
}
