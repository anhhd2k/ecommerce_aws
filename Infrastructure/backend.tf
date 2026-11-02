terraform {
  backend "s3" {
    bucket       = "ecommerce112233"
    key          = "dev/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
    region       = "ap-southeast-1"
  }
}