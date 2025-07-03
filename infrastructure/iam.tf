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

resource "aws_iam_policy" "airbyte_policy" {
  name        = "airbyte-policy"
  description = "Dedicated policy for rds instance and s3 "

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:*Object*",
        #   "rds:DescribeDBInstances",
        #   "rds:DescribeDBClusters",
        #   "rds:ListTagsForResource",
          "rds-db:connect"
        ]
        Resource = [
          "arn:aws:s3:::airbyte-destination-demo*",
        ]
      },
    ]
  })
}

resource "aws_iam_user_policy_attachment" "policy_attachment" {
  user       = aws_iam_user.airbyte_user.name
  policy_arn = aws_iam_policy.airbyte_policy.arn
}
