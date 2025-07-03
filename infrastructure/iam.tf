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

resource "aws_ssm_parameter" "airbyte_access_key" {
  name  = "/dev/airbyte/airbyte_user_access_key"
  type  = "String"
  value = aws_iam_access_key.airbyte_credentials.id
}

resource "aws_ssm_parameter" "airbyte_secret_key" {
  name  = "/dev/airbyte/airbyte_user_secret_key"
  type  = "String"
  value = aws_iam_access_key.airbyte_credentials.secret
}
