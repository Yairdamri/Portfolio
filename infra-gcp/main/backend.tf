terraform {
  backend "gcs" {
    bucket = "tf-state-buckett"
    prefix = "state/dev"   # or whatever prefix you prefer
  }
}
