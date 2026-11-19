# AWS slice (staged in by scripts/stage-module): history in the group's S3
# bucket, written through Pod Identity (core-platform binds monitoring/<writer>).
locals {
  s3_endpoint = "s3.${local.region}.amazonaws.com"

  slice = {
    cloud        = "aws"
    secret_store = "aws-secretsmanager"
    # Each signal's object-store block, rendered as is into its chart values.
    object_storage = {
      mimir = {
        backend = "s3"
        s3      = { bucket_name = local.bucket, endpoint = local.s3_endpoint, region = local.region }
      }
      loki_schema_store = "s3"
      loki = {
        type                = "s3"
        bucketNames         = { chunks = local.bucket, ruler = local.bucket, admin = local.bucket }
        s3                  = { region = local.region }
        use_thanos_objstore = true
        object_store = {
          type           = "s3"
          storage_prefix = local.loki_prefix
          s3             = { endpoint = local.s3_endpoint, region = local.region }
        }
      }
      tempo = {
        backend = "s3"
        s3 = {
          bucket   = local.bucket
          prefix   = local.tempo_prefix
          endpoint = local.s3_endpoint
          region   = local.region
        }
      }
    }
    # Credentials from Pod Identity (monitoring/grafana -> CloudWatch read role).
    cloud_datasources = [{
      name     = "CloudWatch"
      type     = "cloudwatch"
      uid      = "cloudwatch"
      jsonData = { authType = "default", defaultRegion = local.region }
    }]
  }
}
