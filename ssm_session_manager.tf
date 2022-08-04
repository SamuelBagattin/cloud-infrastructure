data "aws_iam_role" "systems_manager" {
  name = "AWSServiceRoleForAmazonSSM"
}

data "aws_iam_policy_document" "systems_manager_instance_profile_assume_role" {
    statement {
        actions = ["sts:AssumeRole"]
        principals {
        type        = "Service"
        identifiers = ["ssm.amazonaws.com"]
        }
      condition {
        test     = "StringEquals"
        values   = [local.current_account_id]
        variable = "aws:SourceAccount"
      }
      condition {
        test     = "ArnEquals"
        values   = ["arn:aws:ssm:${local.current_region}:${local.current_account_id}:*"]
        variable = "aws:SourceArn"
      }
    }
}

resource "aws_iam_role" "systems_manager_instance_profile" {
  assume_role_policy = data.aws_iam_policy_document.systems_manager_instance_profile_assume_role.json
}

data "aws_iam_policy" "ssm_managed_instance_core" {
  name = "AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "systems_manager_instance_profile_managed_instance_core" {
  policy_arn = data.aws_iam_policy.ssm_managed_instance_core.arn
  role       = aws_iam_role.systems_manager_instance_profile.name
}

resource "aws_ssm_activation" "oci" {
  iam_role = aws_iam_role.systems_manager_instance_profile.name
  registration_limit = 5
  expiration_date = "2022-08-05T00:00:00Z"
  name = "oci-ssmactivation"
}