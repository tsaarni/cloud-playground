
provider "aws" {
  region = "eu-west-1"
}


data "aws_ami" "image" {
  most_recent = true
  owners = ["099720109477"]   # canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_iam_role" "aws_iam_fleet_role" {
  role_name = "aws-ec2-spot-fleet-role"
}



#resource "aws_vpc" "my_vpc" {
#  cidr_block = "172.16.0.0/16"
#  tags {
#    Name = "tf-example"
#  }
#}

resource "aws_spot_fleet_request" "workers" {
  iam_fleet_role      = "${data.aws_iam_role.aws_iam_fleet_role.arn}"
  spot_price          = "0.02"
  target_capacity     = "3"
  terminate_instances_with_expiration = true

  # valid_until =  default 24 hours

  launch_specification {
    instance_type = "m3.medium"
    ami           = "${data.aws_ami.image.image_id}"
    spot_price    = "0.02"
    key_name      = "tsaarni"
  }

}
