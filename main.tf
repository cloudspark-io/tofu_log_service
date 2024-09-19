terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.8.0"
}

provider "aws" {
  region = var.region
}

resource "aws_cloudwatch_event_rule" "service_log_rule" {  
  name        = "service-log-rule"  
  description = "EventBridge rule to capture logs from any application service and send to CloudWatch Log Group."  
  
  event_pattern = jsonencode({  
    "detail" = {  
      "env"     = [{ "wildcard" : "*" }],  
      "level"   = ["info", "warn", "error"],  
      "message" = [{ "wildcard" : "*" }],  
      "service" = [{ "wildcard" : "*" }]  
    },  
    "detail-type" = ["service.log"],  
    "source"      = [{ "wildcard" : "*" }]  
  })  
}

resource "aws_cloudwatch_log_group" "log_service_cw_log_group" {
  name = "/aws/events/log-service"
}

resource "aws_cloudwatch_event_target" "services_event_target" {
  rule = aws_cloudwatch_event_rule.service_log_rule.name
  arn  = aws_cloudwatch_log_group.log_service_cw_log_group.arn
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "cw_log_group_policy" {  
  statement {  
    actions = [  
      "logs:CreateLogStream",  
      "logs:PutLogEvents",  
    ]  
    resources = [  
      "${aws_cloudwatch_log_group.log_service_cw_log_group.arn}:*"  
    ]  
    principals { # the identity of the principal that is enabled to put logs to this account.  
      identifiers = ["events.amazonaws.com"]  
      type        = "Service"  
    }  
  }  
}

resource "aws_cloudwatch_log_resource_policy" "eventbridge_log_policy" {  
  policy_document = data.aws_iam_policy_document.cw_log_group_policy.json
  policy_name     = "eventbridge-log-policy"  
}

variable "region" {
  description = "The aws region to deploy the infrasctructure to."
  type = string
}