terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Create an S3 Bucket
resource "aws_s3_bucket" "cloud-resume-challenge-6242023" {
  bucket = data.aws_s3_bucket.aws-cloud-resume-bucket

  tags = {
    Name = "My Bucket"
  }
}

#Create a bucket ACL - Access Control List
resource "aws_s3_bucket_acl" "crc-6242023-acl" {
  bucket = aws_s3_bucket.cloud-resume-challenge-6242023.id
  acl    = "private"
}

locals {
  s3_origin_id = "myS3Origin"
}

resource "aws_cloudfront_origin_access_control" "dcg_cf_origin" {
  name                              = "cfc_dcgplayroom_origin_access"
  description                       = "Origin Access Control Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"

}

resource "aws_cloudfront_distribution" "cloud-resume-challenge-cf" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Static website distribution"
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.cloud-resume-challenge-6242023.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.dcg_cf_origin.id
    origin_id                = local.s3_origin_id
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id
    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
  tags = {
    Name = "Static Website Distribution"
  }
}

resource "aws_acm_certificate" "public_certificate" {
  domain_name       = "*.dcgplayroom.com"
  validation_method = "DNS"

  tags = {
    Name = "Public Certificate for CRC"
  }
}

resource "aws_route53_record" "dcg_rt53_record" {
  allow_overwrite = true
  name            = "resume.dcgplayroom.com"
  records         = aws_cloudfront_distribution.cloud-resume-challenge-cf
  ttl             = 300
  type            = "A"
  zone_id         = data.aws_route53_zone.dcgplayroom_rt53
}

resource "aws_acm_certificate_validation" "public_acm_certificate" {
  certificate_arn         = aws_acm_certificate.public_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.dcg_rt53_record : record.fqdn]
}
