terraform {
  required_version = {
    aws = {
        source = "hashicorp/aws"
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
    acl = "private"

    index_document {
        suffix = "index.html"
    }

    error_document {
        key = "error.html"
    }

    locals {
        s3_origin_id = "mys3origin"
    }

    tags = {
      Name = "Static Website Bucket"
    }

}
resource "aws_cloudfront_distribution" "cloud-resume-challenge-cf" {
  enabled = true
  is_ipv6_enabled = true
  comment = "Static website distribution"
  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket.cloud-resume-challenge-6242023.website_endpoint
    origin_id = "s3Origin"
  }

  aliases = "resume.dcgplayroom.com"

  default_cache_behavior {
    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods = ["GET", "HEAD"]
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
  domain_name = "*.dcgplayroom.com"
  validation_method = "DNS"

  tags = {
    Name = "Public Certificate for CRC"
  }
}
resource "aws_route53_record" "dcg_rt53_record" {       
  for_each = {
    for dvo in aws_acmaws_acm_certificate.public_certificate.domain_validation_options : dvo.domain_name => {
        name = dvo.resource_record_name
        record = dvo.resource_record_name
        type = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.dcgplayroom_rt53
}

resource "aws_acm_certificate_validation" "public_acm_certificate" {
  certificate_arn = aws_acm_certificate.public_certificate.arn
  validation_record_fqdns = [for record in awsaws_route53_record.dcg_rt53_record : record.fqdn]
}
