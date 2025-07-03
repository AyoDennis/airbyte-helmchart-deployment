resource "aws_iam_user" "airbyte_user" {
  name = "airbyte_user"

  tags = {
    service     = "airbyte"
    environment = "dev"
  }
}
