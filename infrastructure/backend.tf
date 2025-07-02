terraform {
  backend "s3" {
    bucket  = "airbyte-project-test"
    key     = "key/terraform.tfstate"
    use_lockfile = true
    region  = "eu-central-1"
    profile = "default"
  }
}
