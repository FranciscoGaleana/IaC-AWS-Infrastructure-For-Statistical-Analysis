# main.tf
# main boot file
###############################################################################
# 
# Programmer: Francisco E. Galeana G.
# 
# Creation date: 22-nov-2024
# Modification date: 22-nov-2024 
# 
###############################################################################

provider "aws" {
    access_key = var.AWS_Key
    secret_key = var.AWS_Secret
    region = var.Region_AWS
}

#Creating VPC
resource "aws_vpc" "StatAnalysis-dev-UsEast1" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "StatAnalysis-dev-UsEast1"
  }
}

#Creating public subnet 1 in zone 1
resource "aws_subnet" "PublicSubnet1" {
  vpc_id = aws_vpc.StatAnalysis-dev-UsEast1.id
  cidr_block = "10.0.0.0/20"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"

  tags = {
    Name = "PublicSubnet1"
  }
}

#Creating public subnet 2 in zone 2
resource "aws_subnet" "PublicSubnet2" {
  vpc_id = aws_vpc.StatAnalysis-dev-UsEast1.id
  cidr_block = "10.0.16.0/20"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1b"

  tags = {
    Name = "PublicSubnet2"
  }
}

#Creating private subnet 1 in zone 1
resource "aws_subnet" "PrivateSubnet1" {
  vpc_id = aws_vpc.StatAnalysis-dev-UsEast1.id
  cidr_block = "10.0.128.0/20"
  availability_zone = "us-east-1a"

  tags = {
    Name = "PrivateSubnet1"
  }
}

#Creating private subnet 2 in zone 2
resource "aws_subnet" "PrivateSubnet2" {
  vpc_id = aws_vpc.StatAnalysis-dev-UsEast1.id
  cidr_block = "10.0.144.0/20"
  availability_zone = "us-east-1b"

  tags = {
    Name = "PrivateSubnet2"
  }
}

#Creating route table for public subnets---------------------------
resource "aws_route_table" "PublicRouteTable" {
  vpc_id = aws_vpc.StatAnalysis-dev-UsEast1.id
  
  tags = {
    Name = "Public-Route-Table"
  }
}

#Associate routing from public subnet 1 to public routing table
resource "aws_route_table_association" "PublicSubnet1_Association" {
  subnet_id = aws_subnet.PublicSubnet1.id
  route_table_id = aws_route_table.PublicRouteTable.id
}

#Associate routing from public subnet 2 to public routing table
resource "aws_route_table_association" "PublicSubnet2_Association" {
  subnet_id = aws_subnet.PublicSubnet2.id
  route_table_id = aws_route_table.PublicRouteTable.id
}

#Creating Internet Gateway for public subnets
resource "aws_internet_gateway" "InternetGateway" {
  vpc_id = aws_vpc.StatAnalysis-dev-UsEast1.id

  tags = {
    Name = "MainInternetGateway"
  }
}

#Adding route to Internet
resource "aws_route" "PublicInternet" {
  route_table_id = aws_route_table.PublicRouteTable.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.InternetGateway.id
}


#Creating route table for private subnets------------------------
resource "aws_route_table" "PrivateRouteTable" {
  vpc_id = aws_vpc.StatAnalysis-dev-UsEast1.id

  tags = {
    Name = "Private-Route-Table"
  }
}

#Associate routing from private subnet 1 to private routing table
resource "aws_route_table_association" "PrivateSubnet1_Association" {
  subnet_id = aws_subnet.PrivateSubnet1.id
  route_table_id = aws_route_table.PrivateRouteTable.id
}

#Associate routing from private subnet 2 to private routing table
resource "aws_route_table_association" "PrivateSubnet2_Association" {
  subnet_id = aws_subnet.PrivateSubnet2.id
  route_table_id = aws_route_table.PrivateRouteTable.id
}

#Creating NAT gateway (outbound traffic) for private subnets
resource "aws_eip" "NAT" {
  tags = {
    Name = "nat-eip"
  }
}

#Creating NAT gateway on public subnet 1 (intermediary)
resource "aws_nat_gateway" "mainNATgateway" {
  allocation_id = aws_eip.NAT.id
  subnet_id = aws_subnet.PublicSubnet1.id

  tags = {
    Name = "main-nat-gateway"
  }
}

#Creating routing table for NAT gateway
resource "aws_route" "PrivateNAT" {
  route_table_id = aws_route_table.PrivateRouteTable.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.mainNATgateway.id
}

#Creating security groups for public subnets
resource "aws_security_group" "PublicSG" {
  vpc_id = aws_vpc.StatAnalysis-dev-UsEast1.id

  #HTTP Traffic
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #HTTPs Traffic
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  
  #SSH traffic for node configuration with Ansible
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #ICMP to ping test connection
  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1" #Cualquier protocolo
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "PublicSG"
  }
}

#Creating security groups for private subnets
resource "aws_security_group" "PrivateSG" {
  vpc_id = aws_vpc.StatAnalysis-dev-UsEast1.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [aws_security_group.PublicSG.id]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    security_groups = [aws_security_group.PublicSG.id]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
  }

  tags = {
    Name = "PrivateSG"
  }
}

#Creating security group for database
resource "aws_security_group" "dbSG" {
  vpc_id = aws_vpc.StatAnalysis-dev-UsEast1.id

  #Allow incoming traffic from EC2 instance security groups
  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_groups = [aws_security_group.PublicSG.id]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dbSG"
  }
}

#Creating S3 bucket that will store CSV files
resource "aws_s3_bucket" "csvBucket" {
  bucket = "stat-analysis-csv-bucket-231124"
  
  tags = {
    Name = "csvBucket"
    Environment = "Dev"
  }
}

#Creating policy to allow communication between EC2 and S3
resource "aws_iam_role" "S3AccessRole" {
  name = "ec2-s3-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
        {
            Action = "sts:AssumeRole",
            Effect = "Allow",
            Principal = {
                Service = "ec2.amazonaws.com"
            }
        }
    ]
  })
}

resource "aws_iam_policy" "S3AccessPolicy" {
  name = "ec2-s3-access-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Action = [
                "s3:PutObject",
                "s3:GetObject",
                "s3:ListBucket"
            ],

            Effect = "Allow",
            Resource = [
                aws_s3_bucket.csvBucket.arn,
                "${aws_s3_bucket.csvBucket.arn}/*"
            ]
        }
    ]
  })
}

#Associating policy with the role
resource "aws_iam_role_policy_attachment" "AttachS3Policy" {
  role = aws_iam_role.S3AccessRole.name
  policy_arn = aws_iam_policy.S3AccessPolicy.arn
}

#Get key pair to associate with EC2 instance
resource "aws_key_pair" "AWSLlaves" {
  key_name = "Ubuntu"
  public_key = file("C:/Users/UserName/.ssh/id_rsa.pub") 
}

#EC2 Instance creation (Website Hosting)
resource "aws_instance" "UbuntuServer" {
  ami = "ami-0866a3c8686eaeeba"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.PublicSubnet1.id
  vpc_security_group_ids = [aws_security_group.PublicSG.id]
  key_name = aws_key_pair.AWSLlaves.key_name
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.S3AccessProfile.name

  tags = {
    Name = "UbuntuServer"
  }
}

#Role association with EC2 instance
resource "aws_iam_instance_profile" "S3AccessProfile" {
  name = "S3AccessProfile"
  role = aws_iam_role.S3AccessRole.name
}

#Create RDS instance (database)
resource "aws_db_instance" "StatDB" {
  allocated_storage = 20
  engine = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  db_name = "StatDb"
  username = var.db_username
  password = var.db_password
  vpc_security_group_ids = [aws_security_group.dbSG.id]
  db_subnet_group_name = aws_db_subnet_group.DBSubnet.name
  skip_final_snapshot = true #Set as false in real world environments 
                             #(it prevents accidental db deletion)
}

#Subnet group for RDS
resource "aws_db_subnet_group" "DBSubnet" {
  name = "stat-db-subnet"
  subnet_ids = [aws_subnet.PrivateSubnet1.id, aws_subnet.PrivateSubnet2.id]

  tags = {
    Name = "StatAnalysisDBSubnetGroup"
  }
}
