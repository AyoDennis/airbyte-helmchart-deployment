resource "aws_iam_user" "airbyte_user" {
  name = "airbyte_user"

  tags = {
    service     = "airbyte"
    environment = "dev"
  }
}

resource "aws_iam_access_key" "airbyte_credentials" {
  user = aws_iam_user.airbyte_user.name
}
