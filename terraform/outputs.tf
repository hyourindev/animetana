output "ip" {
  value = aws_eip.main.public_ip
}

output "ssh" {
  value = "ssh ubuntu@${aws_eip.main.public_ip}"
}

output "s3_bucket" {
  value = aws_s3_bucket.media.id
}
