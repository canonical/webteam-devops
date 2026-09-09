terraform {
  backend "s3" {
    key    = "state"
    bucket = "k8s-prod-marketplace-default-tfstate"
    region = "prodstack7"
    endpoints = {
      s3 = "https://radosgw.ps7.canonical.com"
    }
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
    use_lockfile                = true
  }
}
