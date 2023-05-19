provider "aws" {
    access_key = var.access_key
    secret_key = var.secret_key
    region = var.region
}

#EC2 Set up
resource "aws_instance" "demo1" {
    ami = var.ami
    instance_type = var.instance_type
    key_name = aws_key_pair.test-key.key_name
    vpc_security_group_ids = [aws_security_group.ec2_sg.id]
    subnet_id = var.subnet_a
}

resource "aws_instance" "demo2" {
    ami = var.ami
    instance_type = var.instance_type
    key_name = aws_key_pair.test-key.key_name
    vpc_security_group_ids = [aws_security_group.ec2_sg.id]
    subnet_id = var.subnet_b
}

#Target group set-up

resource "aws_lb_target_group" "tg" {
  name     = "lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id = var.vpc_id
}

#add hosts to target group

resource "aws_lb_target_group_attachment" "tg-attach1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.demo1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "tg-attach2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.demo2.id
  port             = 80
}


# attach target group to load balancer

resource "aws_lb_listener" "connection" {
    load_balancer_arn = aws_lb.nginx-lb.arn
    port              = 80
    protocol          = "HTTP"

    default_action {
        type          = "forward"
        target_group_arn = aws_lb_target_group.tg.arn
    }
}


# load balancer set-up

resource "aws_lb" "nginx-lb" {
  name               = "nginx-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [var.subnet_a, var.subnet_b]
  security_groups = [aws_security_group.lb_sg.id]
}



#Secuirty group set up
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Allow SSH, nginx inbound traffic"
 
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "lb_sg" {
  name        = "lb-sg"
  description = "Allow nginx inbound traffic"
 
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}



#ssh key set up
resource "aws_key_pair" "test-key" {
  key_name   = "test-key"
  public_key = tls_private_key.test.public_key_openssh
}
 
resource "tls_private_key" "test" {
    algorithm = "RSA"
    rsa_bits = 4096
}
 
resource "local_file" "tf_key" {
    content = tls_private_key.test.private_key_pem
    filename = "tf_key.pem"
}