output "vm1_public_ip" {
    value = aws_instance.demo1.public_ip
}
output "vm2_public_ip" {
    value = aws_instance.demo2.public_ip
}
output "lb-dns" {
    value = aws_lb.nginx-lb.dns_name
}