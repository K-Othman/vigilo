
resource "aws_iam_openid_connect_provider" "vigilo_github_actions" {
  url = "https://token.actions.githubusercontent.com"

  # The audience that GitHub Actions tokens include
  client_id_list = ["sts.amazonaws.com"]

  # GitHub's OIDC thumbprint
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Service   = "github-actions"
    ManagedBy = "terraform"
  }
  lifecycle {
    prevent_destroy = true
  }
}
