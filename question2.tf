# Define the provider (AWS in this case)
provider "aws" {
  region = "us-east-1" # Change this to your desired region
}

# Create an S3 bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-unique-bucket-name"
  acl    = "private"
}

# Create an IAM role
resource "aws_iam_role" "my_iam_role" {
  name = "my-iam-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "glue.amazonaws.com"
      }
    }]
  })
}

# Attach a sample IAM policy to the role
resource "aws_iam_policy_attachment" "my_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.my_iam_role.name
}

# Create a security group
resource "aws_security_group" "my_security_group" {
  name        = "my-security-group"
  description = "Allow incoming traffic on port 3306"
  vpc_id      = "vpc-12345678" # Replace with your VPC ID

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an RDS instance with MySQL
resource "aws_db_instance" "my_db_instance" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "mydbuser"
  password             = "mypassword"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.my_security_group.id]
}

# Create an AWS Glue job
resource "aws_glue_job" "my_glue_job" {
  name           = "my-glue-job"
  role_arn       = aws_iam_role.my_iam_role.arn
  command {
    name          = "glueetl"
    script_location = "s3://my-unique-bucket-name/glue-scripts/script.py" # Replace with your script location
  }
}

# Create a KMS key
resource "aws_kms_key" "my_kms_key" {
  description             = "My KMS Key"
  deletion_window_in_days = 30
}

# Create an Application Load Balancer
resource "aws_lb" "my_alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = ["subnet-12345678", "subnet-87654321"] # Replace with your subnet IDs

  enable_deletion_protection = false
}

# Create an Auto Scaling Group
resource "aws_autoscaling_group" "my_asg" {
  name                 = "my-asg"
  launch_configuration = aws_launch_configuration.my_lc.name
  min_size             = 1
  max_size             = 3
  desired_capacity     = 2
  availability_zones   = ["us-east-1a", "us-east-1b"] # Replace with your availability zones

  tag {
    key                 = "Name"
    value               = "my-asg-instance"
    propagate_at_launch = true
  }
}

# Create a launch configuration
resource "aws_launch_configuration" "my_lc" {
  name_prefix          = "my-lc-"
  image_id             = "ami-12345678" # Replace with your desired AMI ID
  instance_type        = "t2.micro"
  security_groups      = [aws_security_group.my_security_group.id]
  key_name             = "my-key-pair" # Replace with your key pair name
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}

# Output the DNS name of the ALB
output "alb_dns_name" {
  value = aws_lb.my_alb.dns_name
}
