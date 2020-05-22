
# S3 Bucket with Website Settings
resource "aws_s3_bucket" "site_bucket"{
    bucket = "${var.site_name}"    
    acl = "public-read"
    website {
        index_document = "index.html"
        error_document = "error.html"
    }
}

# Route53 Domain Name and Resource Records
resource "aws_route53_zone" "site_zone" {
    name = "${var.site_name}"
}

resource "aws_route53_record" "site_cname" {
    zone_id = "${aws_route53_zone.site_zone.zone_id}"
    name = "${var.site_name}"
    type = "NS"
    ttl = "30"
    records = [
        "${aws_route53_zone.site_zone.name_servers.0}",
        "${aws_route53_zone.site_zone.name_servers.1}",
        "${aws_route53_zone.site_zone.name_servers.2}",
        "${aws_route53_zone.site_zone.name_servers.3}"
    ]
}


# Amazon Certificate Manager
module "acm" {
    source = "git@github.com:terraform-module/terraform-aws-acm.git"
    
    domain_name = "${var.site_name}"
    zone_id = "${aws_route53_zone.site_zone.zone_id}"
    
    validation_method = "DNS"

    subject_alternative_names = [
        "*.${var.site_name}"
    ]

    tags = {}
}


# CloudFront  Distribution
resource "aws_cloudfront_distribution" "site_distribution" {
    origin {
        domain_name = "${aws_s3_bucket.site_bucket.bucket_domain_name}"
        origin_id = "${var.site_name}-origin"
    }

    enabled = true
    aliases = ["${var.site_name}"]
    price_class = "PriceClass_100"
    default_root_object = "index.html"

    default_cache_behavior {
        allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH",
                      "POST", "PUT"]
        cached_methods   = ["GET", "HEAD"]
        target_origin_id = "${var.site_name}-origin"

        forwarded_values {
          query_string = true
            cookies {
                forward = "all"
            }
        }
        viewer_protocol_policy = "https-only"
        min_ttl                = 0
        default_ttl            = 1000
        max_ttl                = 86400
    }
    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }
    viewer_certificate {
        acm_certificate_arn = "${module.acm.arn}"
        minimum_protocol_version = "TLSv1"
        ssl_support_method = "sni-only"
    }


}