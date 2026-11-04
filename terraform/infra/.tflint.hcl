config {
  # Also lint the local modules under ./modules
  call_module_type = "local"
}

# Terraform language rules: unused variables, missing types, naming and so on
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# AWS rules: invalid instance types, regions, deprecated settings and so on
plugin "aws" {
  enabled = true
  version = "0.49.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}