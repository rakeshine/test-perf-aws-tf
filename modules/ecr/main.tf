resource "aws_ecr_repository" "jmeter" {
  name                 = "jmeter"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name  = "jmeter"
    Owner = "PerformanceTesting"
  }
}

output "repository_url" {
  value = aws_ecr_repository.jmeter.repository_url
}
