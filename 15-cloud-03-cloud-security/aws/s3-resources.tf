
resource "aws_kms_key" "bucket-key" {
  description             = "S3 bucket encryption key"
}


# Create S3 bucket and upload a picture

resource "aws_s3_bucket" "netology-15-encrypted" {
  bucket = "netology-15-encrypted"

  tags = {
    Name = "netology-15-encrypted"
  }
}

resource "aws_s3_bucket_acl" "netology-15-encrypted" {
  bucket = aws_s3_bucket.netology-15-encrypted.id
  acl    = "public-read"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket-encryption" {
  bucket = aws_s3_bucket.netology-15-encrypted.bucket
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.bucket-key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket" "netology-15-site" {
  bucket = "netology-15-site"

  tags = {
    Name = "netology-15-site"
  }
}

resource "aws_s3_bucket_acl" "netology-15-site" {
  bucket = aws_s3_bucket.netology-15-site.id
  acl    = "public-read"
}

resource "aws_s3_bucket_website_configuration" "s3-site" {
  bucket = aws_s3_bucket.netology-15-site.bucket

  index_document {
    suffix = "index.html"
  }

}

resource "aws_s3_object" "elk-picture" {
  for_each = toset([
    aws_s3_bucket.netology-15-site.bucket,
    aws_s3_bucket.netology-15-encrypted.bucket
  ])
  bucket       = each.key
  key          = local.pict_name
  content_type = "image/jpeg"
  source       = "../${local.pict_name}"
  acl          = "public-read"
}

resource "aws_s3_object" "index-page" {
  bucket       = aws_s3_bucket.netology-15-site.bucket
  key          = "index.html"
  content_type = "text/html"
  acl          = "public-read"
  # this is fake index page. Real one will be copied from S3 service VM
  content = ""
}

