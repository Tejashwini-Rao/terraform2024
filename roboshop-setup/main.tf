resource "aws_instance" "app" {
  count         = length(var.components)
  ami           = ami-0b4f379183e5706b9
  instance_type = "t3.micro"
  iam_instance_profile   = "SecretManager_role_Roboshop"
  vpc_security_group_ids = ["sg-0d863d0a29670b15c"]

  tags = {
    Name = "${var.components["${count.index}"]}-dev"
  }
}


resource "aws_route53_record" "record" {
  count         = length(var.components)
  zone_id = "${var.components["${count.index}"]}-dev"
  name    = "www.example.com"
  type    = "A"
  ttl     = 300
  records = [aws_instance.app.*.private_ip[count.index]]
}

resource "null_resource" "ansible-apply" {
  depends_on = [aws_route53_record.record]
  triggers = {
    abc = timestamp()
  }
  count = length(var.components)
  provisioner "remote-exec" {

    connection {
      host     = aws_instance.app.*.public_ip[count.index]
      user     = "root"
      password = "DevOps321"
    }

    inline = [
      "sudo labauto clean",
      "ansible-pull -i localhost, -U https://github.com/Tejashwini-Rao/roboshop-ansible2024 roboshop.yml -e HOSTS=localhost -e APP_COMPONENT_ROLE=${var.components[count.index]} -e ENV=dev"
    ]

  }