data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  repo       = "${var.github_owner}/${var.github_repo}"

  # Roles the infra stack creates for ECS must use this prefix
  ecs_role_prefix = "${var.project_name}-ecs-"
  sub_prefix      = "repo:${var.github_owner}@${var.github_owner_id}/${var.github_repo}@${var.github_repo_id}"
}

# ===========================================================================
# Trust policies: WHO may assume each role
# ===========================================================================

# Apply role: only workflows running on main
data "aws_iam_policy_document" "apply_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.vigilo_github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["${local.sub_prefix}:ref:refs/heads/main"]
    }
  }
}

# Plan role: only pull request workflows
data "aws_iam_policy_document" "plan_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.vigilo_github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["${local.sub_prefix}:pull_request"]
    }
  }
}

resource "aws_iam_role" "github_apply" {
  name               = "${var.project_name}-github-apply"
  assume_role_policy = data.aws_iam_policy_document.apply_trust.json
}

resource "aws_iam_role" "github_plan" {
  name               = "${var.project_name}-github-plan"
  assume_role_policy = data.aws_iam_policy_document.plan_trust.json
}

# ===========================================================================
# Apply policy 1 of 2: state, networking, load balancer, certificate, DNS
# ===========================================================================

data "aws_iam_policy_document" "github_apply" {
  # --- Terraform state ---
  statement {
    sid       = "StateBucketList"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.bootstrap_s3_bucket.arn]
  }

  statement {
    sid = "StateObjectsReadWrite"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${aws_s3_bucket.bootstrap_s3_bucket.arn}/vigilo/*"]
  }

  # --- Networking (VPC lives under EC2) ---
  statement {
    sid = "Networking"
    actions = [
      "ec2:Describe*",
      "ec2:CreateTags",
      "ec2:DeleteTags",

      "ec2:CreateVpc",
      "ec2:DeleteVpc",
      "ec2:ModifyVpcAttribute",

      "ec2:CreateSubnet",
      "ec2:DeleteSubnet",
      "ec2:ModifySubnetAttribute",

      "ec2:CreateInternetGateway",
      "ec2:DeleteInternetGateway",
      "ec2:AttachInternetGateway",
      "ec2:DetachInternetGateway",

      "ec2:AllocateAddress",
      "ec2:ReleaseAddress",
      "ec2:DisassociateAddress",
      "ec2:CreateNatGateway",
      "ec2:DeleteNatGateway",

      "ec2:CreateRouteTable",
      "ec2:DeleteRouteTable",
      "ec2:CreateRoute",
      "ec2:DeleteRoute",
      "ec2:ReplaceRoute",
      "ec2:AssociateRouteTable",
      "ec2:DisassociateRouteTable",

      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:ModifySecurityGroupRules",
      "ec2:UpdateSecurityGroupRuleDescriptionsIngress",
      "ec2:UpdateSecurityGroupRuleDescriptionsEgress",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  # --- Load balancer ---
  statement {
    sid = "LoadBalancer"
    actions = [
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags",

      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",

      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",

      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:ModifyListener",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  # --- Certificate ---
  statement {
    sid = "Certificate"
    actions = [
      "acm:RequestCertificate",
      "acm:DeleteCertificate",
      "acm:DescribeCertificate",
      "acm:ListCertificates",
      "acm:ListTagsForCertificate",
      "acm:AddTagsToCertificate",
      "acm:RemoveTagsFromCertificate",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  # --- DNS (global service, so no region condition) ---
  statement {
    sid = "DnsRead"
    actions = [
      "route53:ListHostedZones",
      "route53:GetChange",
    ]
    resources = ["*"]
  }

  statement {
    sid = "DnsRecordsInMyZoneOnly"
    actions = [
      "route53:GetHostedZone",
      "route53:ListResourceRecordSets",
      "route53:ChangeResourceRecordSets",
      "route53:ListTagsForResource",
    ]
    resources = ["arn:aws:route53:::hostedzone/${var.hosted_zone_id}"]
  }
}

resource "aws_iam_policy" "github_apply" {
  name   = "${var.project_name}-github-apply"
  policy = data.aws_iam_policy_document.github_apply.json
}

resource "aws_iam_role_policy_attachment" "github_apply" {
  role       = aws_iam_role.github_apply.name
  policy_arn = aws_iam_policy.github_apply.arn
}

# ===========================================================================
# Apply policy 2 of 2: database, containers, registry, logs, IAM, safety net
# ===========================================================================

data "aws_iam_policy_document" "github_apply_platform" {
  # --- Database ---
  statement {
    sid = "Database"
    actions = [
      "rds:Describe*",
      "rds:ListTagsForResource",
      "rds:AddTagsToResource",
      "rds:RemoveTagsFromResource",

      "rds:CreateDBSubnetGroup",
      "rds:DeleteDBSubnetGroup",
      "rds:ModifyDBSubnetGroup",

      "rds:CreateDBInstance",
      "rds:DeleteDBInstance",
      "rds:ModifyDBInstance",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  # RDS creates the DB password secret itself (manage_master_user_password).
  # Those secrets always start with rds!
  statement {
    sid = "RdsManagedSecret"
    actions = [
      "secretsmanager:CreateSecret",
      "secretsmanager:DeleteSecret",
      "secretsmanager:DescribeSecret",
      "secretsmanager:TagResource",
      "secretsmanager:UntagResource",
      "secretsmanager:RotateSecret",
    ]
    resources = ["arn:aws:secretsmanager:${var.aws_region}:${local.account_id}:secret:rds!*"]
  }

  statement {
    sid       = "KmsDescribeForRdsSecret"
    actions   = ["kms:DescribeKey"]
    resources = ["*"]
  }

  # --- Containers ---
  statement {
    sid = "Ecs"
    actions = [
      "ecs:CreateCluster",
      "ecs:DeleteCluster",
      "ecs:DescribeClusters",
      "ecs:UpdateCluster",
      "ecs:PutClusterCapacityProviders",

      "ecs:RegisterTaskDefinition",
      "ecs:DeregisterTaskDefinition",
      "ecs:DescribeTaskDefinition",
      "ecs:ListTaskDefinitions",

      "ecs:CreateService",
      "ecs:UpdateService",
      "ecs:DeleteService",
      "ecs:DescribeServices",

      "ecs:TagResource",
      "ecs:UntagResource",
      "ecs:ListTagsForResource",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  # --- Image registry: manage the repo and push images ---
  statement {
    sid       = "EcrLogin"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "EcrVigiloRepo"
    actions = [
      "ecr:CreateRepository",
      "ecr:DeleteRepository",
      "ecr:DescribeRepositories",
      "ecr:PutLifecyclePolicy",
      "ecr:GetLifecyclePolicy",
      "ecr:DeleteLifecyclePolicy",
      "ecr:PutImageTagMutability",
      "ecr:PutImageScanningConfiguration",
      "ecr:ListTagsForResource",
      "ecr:TagResource",
      "ecr:UntagResource",

      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
    ]
    resources = ["arn:aws:ecr:${var.aws_region}:${local.account_id}:repository/${var.project_name}*"]
  }

  # --- Logs ---
  statement {
    sid       = "LogsDescribe"
    actions   = ["logs:DescribeLogGroups"]
    resources = ["*"]
  }

  statement {
    sid = "LogsVigiloGroups"
    actions = [
      "logs:CreateLogGroup",
      "logs:DeleteLogGroup",
      "logs:PutRetentionPolicy",
      "logs:DeleteRetentionPolicy",
      "logs:TagResource",
      "logs:UntagResource",
      "logs:ListTagsForResource",
    ]
    resources = ["arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:/ecs/${var.project_name}*"]
  }

  # --- IAM roles for ECS (only roles named vigilo-ecs-*) ---
  statement {
    sid = "EcsRolesManage"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:UpdateRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePolicy",
      "iam:GetRolePolicy",
      "iam:DeleteRolePolicy",
    ]
    resources = ["arn:aws:iam::${local.account_id}:role/${local.ecs_role_prefix}*"]
  }

  # Hand those roles to ECS tasks, and nothing else
  statement {
    sid       = "PassEcsRolesToEcsOnly"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::${local.account_id}:role/${local.ecs_role_prefix}*"]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }

  # First use of ECS/ELB/RDS in an account creates AWS's own service-linked roles
  statement {
    sid       = "ServiceLinkedRoles"
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values = [
        "ecs.amazonaws.com",
        "elasticloadbalancing.amazonaws.com",
        "rds.amazonaws.com",
      ]
    }
  }

  # --- Safety net: never touch bootstrap itself ---
  statement {
    sid     = "DenyTouchingBootstrap"
    effect  = "Deny"
    actions = ["iam:*"]
    resources = [
      aws_iam_role.github_apply.arn,
      aws_iam_role.github_plan.arn,
      aws_iam_openid_connect_provider.vigilo_github_actions.arn,
    ]
  }

  statement {
    sid    = "DenyBreakingStateBucket"
    effect = "Deny"
    actions = [
      "s3:DeleteBucket",
      "s3:PutBucketPolicy",
      "s3:PutBucketVersioning",
    ]
    resources = [aws_s3_bucket.bootstrap_s3_bucket.arn]
  }
}

resource "aws_iam_policy" "github_apply_platform" {
  name   = "${var.project_name}-github-apply-platform"
  policy = data.aws_iam_policy_document.github_apply_platform.json
}

resource "aws_iam_role_policy_attachment" "github_apply_platform" {
  role       = aws_iam_role.github_apply.name
  policy_arn = aws_iam_policy.github_apply_platform.arn
}

# ===========================================================================
# Plan role permissions: read everything, write only the lock file
# ===========================================================================

resource "aws_iam_role_policy_attachment" "github_plan_readonly" {
  role       = aws_iam_role.github_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy_document" "github_plan_state" {
  statement {
    sid       = "StateBucketList"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.bootstrap_s3_bucket.arn]
  }

  statement {
    sid       = "StateRead"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.bootstrap_s3_bucket.arn}/vigilo/*"]
  }

  # plan takes the lock too, so it must create and remove the .tflock file
  statement {
    sid = "LockFileOnly"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${aws_s3_bucket.bootstrap_s3_bucket.arn}/vigilo/*.tflock"]
  }
}

resource "aws_iam_role_policy" "github_plan_state" {
  name   = "${var.project_name}-github-plan-state"
  role   = aws_iam_role.github_plan.id
  policy = data.aws_iam_policy_document.github_plan_state.json
}