resource "aws_s3_bucket" "b" {
  count  = var.create_bucket ? 1 : 0
  bucket = "my-tf-test-bucket-asha"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_intelligent_tiering_configuration" "example-entire-bucket" {
  count  = var.create_tier ? 1 : 0
  bucket = aws_s3_bucket.b[count.index].bucket
  name   = "EntireBucket"

  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }
  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 125
  }
}