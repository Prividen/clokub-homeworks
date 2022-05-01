
resource "aws_iam_role" "s3-admin" {
  name = "s3-admin"

  assume_role_policy = jsonencode({
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Effect" : "Allow",
        "Sid" : ""
      }
    ]
  })
}

resource "aws_iam_instance_profile" "s3-admin-profile" {
  name = "s3-admin-profile"
  role = aws_iam_role.s3-admin.name
}

resource "aws_iam_role_policy" "s3-full-access" {
  name = "s3-full-access"
  role = aws_iam_role.s3-admin.id

  policy = jsonencode({
    Statement = [
      {
        Action   = ["s3:*"]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}
