# Remote state backend (S3 + DynamoDB locking).
#
# This is intentionally commented out so the example initializes with local state
# out of the box. For real use, create the bucket and lock table once (out of band
# or via a small bootstrap configuration), then uncomment and fill in the values
# below and run `terraform init -migrate-state`.
#
# terraform {
#   backend "s3" {
#     bucket         = "acme-app-terraform-state"      # pre-existing, globally unique
#     key            = "environments/example/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "acme-app-terraform-locks"      # pre-existing lock table
#     encrypt        = true
#   }
# }
