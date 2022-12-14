resource aws_cloudfront_monitoring_subscription "this" {
  
    count = var.create_monitoring_subscription ? 1 : 0
    
    distribution_id = aws_cloudfront_distribution.this.id

    monitoring_subscription {
        realtime_metrics_subscription_config {
            realtime_metrics_subscription_status = var.enable_additional_moniroting ? "Enabled" : "Disabled"
        }
    }
}

resource aws_cloudfront_realtime_log_config "this" {
    for_each = { for log in var.realtime_log_configs: log.name => log }

    name = each.key
    sampling_rate = each.value.sampling_rate
    fields        = each.value.fields

    endpoint {
        stream_type = "Kinesis"

        kinesis_stream_config {
            role_arn   = local.create_realtime_logging_role ? aws_iam_role.this[0].arn : each.value.role_arn
            stream_arn = each.value.kinesis_stream_arn
        }
    }
}

resource aws_iam_role "this" {

    count = local.create_realtime_logging_role ? 1 : 0

    name = var.realtime_logging_role_name

    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource aws_iam_role_policy "this" {
    count = local.create_realtime_logging_role ? 1 : 0

    name = var.realtime_logging_role_name
    role = aws_iam_role.this[0].id

    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": [
          "kinesis:DescribeStreamSummary",
          "kinesis:DescribeStream",
          "kinesis:PutRecord",
          "kinesis:PutRecords"
        ],
        "Resource": [ ${local.kinesis_resources} ]
    }
  ]
}
EOF
}