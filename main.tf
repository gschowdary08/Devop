provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "main-vpc" }
}

# Subnets
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"
  tags = { Name = "public-subnet" }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"
  tags = { Name = "private-a" }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.aws_region}c"
  tags = { Name = "private-b" }
}

# Internet Gateway & Route Table for Public Subnet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group
resource "aws_security_group" "all_traffic" {
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Launch Template
resource "aws_launch_template" "lt" {
  name_prefix   = "lt-"
  image_id      = var.ami_id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.all_traffic.id]
}

# Auto Scaling Group
resource "aws_autoscaling_group" "asg" {
  desired_capacity     = 1
  max_size             = 2
  min_size             = 1
  vpc_zone_identifier  = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "asg-instance"
    propagate_at_launch = true
  }
}

# ✅ FSx (Windows) — fixed argument `subnet_ids` as a list
resource "aws_fsx_windows_file_system" "fsx" {
  subnet_ids                  = [aws_subnet.private_a.id]
  storage_capacity            = 32
  throughput_capacity         = 16
  preferred_subnet_id         = aws_subnet.private_a.id
  deployment_type             = "SINGLE_AZ_1"
  automatic_backup_retention_days = 7
}

# RDS MySQL
resource "aws_db_subnet_group" "db_subnet" {
  name       = "main-db-subnet"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

resource "aws_db_instance" "rds" {
  identifier              = "mydb"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  username                = sanju
  password                = Sanju936@
  allocated_storage       = 20
  db_subnet_group_name    = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids  = [aws_security_group.all_traffic.id]
  skip_final_snapshot     = true
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/terraform/asg"
  retention_in_days = 14
}

# CloudTrail
resource "aws_s3_bucket" "cloudtrail" {
  bucket = "${var.project}-trail-bucket"
}

resource "aws_cloudtrail" "trail" {
  name                          = "main-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true
  is_multi_region_trail         = true
}
