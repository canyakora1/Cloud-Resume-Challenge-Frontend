data "aws_s3_bucket" "aws-cloud-resume-bucket" {
  bucket = "cloud-resume-challenge-6242023"

}

data "aws_route53_zone" "dcgplayroom_rt53" {
  name         = "resume.dcgplayroom.com"
  private_zone = false
}