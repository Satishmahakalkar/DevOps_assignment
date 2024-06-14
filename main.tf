# main.tf

provider "aws" {
  region = "us-west-2"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "MyVPC"
  }
}

# Subnets
resource "aws_subnet" "web_app_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
  tags = {
    Name = "WebAppSubnet"
  }
}

resource "aws_subnet" "db_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"
  tags = {
    Name = "DBSubnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "MyInternetGateway"
  }
}

# Route Table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "MainRouteTable"
  }
}

resource "aws_route_table_association" "web_app_subnet_association" {
  subnet_id      = aws_subnet.web_app_subnet.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "db_subnet_association" {
  subnet_id      = aws_subnet.db_subnet.id
  route_table_id = aws_route_table.main.id
}

# Security Groups
resource "aws_security_group" "web_app_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
    Name = "WebAppSecurityGroup"
  }
}

resource "aws_security_group" "db_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "DBSecurityGroup"
  }
}

# EC2 Instances
resource "aws_instance" "web_app" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.web_app_subnet.id
  security_groups = [aws_security_group.web_app_sg.name]
  key_name      = "your-key-pair"  # Replace with your key pair name

  tags = {
    Name = "WebAppInstance"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "curl -sL https://rpm.nodesource.com/setup_14.x | sudo bash -",
      "sudo yum install -y nodejs",
      "mkdir /home/ec2-user/myapp",
      "echo 'const http = require(\"http\");const server = http.createServer((req, res) => {res.statusCode = 200;res.setHeader(\"Content-Type\", \"text/plain\");res.end(\"Hello, World!\");});const port = 3000;server.listen(port, () => {console.log(`Server running at http://localhost:${port}/`);});' > /home/ec2-user/myapp/app.js",
      "node /home/ec2-user/myapp/app.js"
    ]
  }
}

resource "aws_instance" "db" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.db_subnet.id
  security_groups = [aws_security_group.db_sg.name]
  key_name      = "your-key-pair"  # Replace with your key pair name

  tags = {
    Name = "DBInstance"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y postgresql-server postgresql-contrib",
      "sudo postgresql-setup initdb",
      "sudo systemctl start postgresql",
      "sudo systemctl enable postgresql",
      "sudo -u postgres psql -c \"CREATE USER myuser WITH PASSWORD 'mypassword';\"",
      "sudo -u postgres psql -c \"CREATE DATABASE mydb;\"",
      "sudo -u postgres psql -c \"GRANT ALL PRIVILEGES ON DATABASE mydb TO myuser;\""
    ]
  }
}

# Bastion Host
resource "aws_instance" "bastion" {
  ami                    = "ami-0c55b159cbfafe1f0"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.web_app_subnet.id
  associate_public_ip_address = true
  security_groups = [aws_security_group.web_app_sg.name]
  key_name               = "your-key-pair"  # Replace with your key pair name

  tags = {
    Name = "BastionHost"
  }
}
