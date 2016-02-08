provider "aws" {
	access_key = "${var.aws_access_key}"
	secret_key = "${var.aws_secret_key}"
	region     = "us-east-1"
}

resource "aws_instance" "devopsdc-instance" {
	ami           = "ami-2051294a"
	instance_type = "t2.micro"
	key_name      = "adamleff"
	count         = 1

	provisioner "chef" {
		environment            = "_default"
		run_list               = ["devopsdc_demo::default"]
		node_name              = "${self.public_dns}"
		server_url             = "https://api.opscode.com/organizations/leff"
		validation_client_name = "leff-validator"
		validation_key         = "${file("/Users/aleff/projects/devopsdc-terraform/.chef/validation.pem")}"

		connection {
			type = "ssh"
			user = "ec2-user"
		}
	}

	tags {
		X-Project = "aleff devopsdc"
	}
}

resource "aws_elb" "devopsdc-elb" {
	name = "devopsdc-demo-elb"
	subnets = ["subnet-ce8daee6"]

	listener {
		instance_port     = 8000
		instance_protocol = "http"
		lb_port           = 80
		lb_protocol       = "http"
	}

	health_check {
		healthy_threshold   = 2
		unhealthy_threshold = 2
		timeout             = 3
		target              = "HTTP:8000/"
		interval            = 30
	}

	instances = ["${aws_instance.devopsdc-instance.*.id}"]

	tags {
		X-Project = "aleff devopsdc"
	}
}

resource "aws_route53_record" "devopsdc-elb-dns" {
	zone_id = "Z20GXCA1KGHB6A"
	name = "devopsdc"
	type = "A"

	alias {
		name = "${aws_elb.devopsdc-elb.dns_name}"
		zone_id = "${aws_elb.devopsdc-elb.zone_id}"
		evaluate_target_health = false
	}
}

output "elb_dns" {
	value = "${aws_elb.devopsdc-elb.dns_name}"
}

output "instances" {
	value = "${join(", ", aws_instance.devopsdc-instance.*.public_dns)}"
}
