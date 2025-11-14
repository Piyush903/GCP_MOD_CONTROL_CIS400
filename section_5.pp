locals {
  cis_v400_5_common_tags = merge(local.cis_v400_common_tags, {
    cis_section_id = "5"
  })
}

benchmark "cis_v400_5" {
  title         = "5 Storage"
  documentation = file("./cis_v400/docs/cis_v400_5.md")
  children = [
    control.cis_v400_5_1,
    control.cis_v400_5_2
  ]

  tags = merge(local.cis_v400_5_common_tags, {
    type    = "Benchmark"
    service = "GCP/Storage"
  })
}

control "cis_v400_5_1" {
  title         = "5.1 Ensure That Cloud Storage Bucket Is Not Anonymously or Publicly Accessible"
  description   = "It is recommended that IAM policy on Cloud Storage bucket does not allows anonymous or public access."
  query         = query.storage_bucket_not_publicly_accessible

  query_source  = "select   self_link resource,   case     when iam_policy ->> 'bindings' like any (array ['%allAuthenticatedUsers%','%allUsers%']) then 'alarm'     else 'ok'   end as status,   case     when iam_policy ->> 'bindings' like any (array ['%allAuthenticatedUsers%','%allUsers%'])       then title || ' publicly accessible.'     else title || ' not publicly accessible.'   end as reason      , location as location, project as project from   gcp_storage_bucket;"
  documentation = file("./cis_v400/docs/cis_v400_5_1.md")

  tags = merge(local.cis_v400_5_common_tags, {
    cis_item_id = "5.1"
    cis_level   = "1"
    cis_type    = "automated"
    service     = "GCP/Storage"
  })
}

control "cis_v400_5_2" {
  title         = "5.2 Ensure That Cloud Storage Buckets Have Uniform Bucket-Level Access Enabled"
  description   = "It is recommended that uniform bucket-level access is enabled on Cloud Storage buckets."
  query         = query.storage_bucket_uniform_access_enabled

  query_source  = "select   self_link resource,   case     when iam_configuration_uniform_bucket_level_access_enabled then 'ok'     else 'alarm'   end as status,   case     when iam_configuration_uniform_bucket_level_access_enabled       then title || ' uniform bucket-level access enabled.'     else title || ' uniform bucket-level access not enabled.'   end as reason      , location as location, project as project from   gcp_storage_bucket;"
  documentation = file("./cis_v400/docs/cis_v400_5_2.md")

  tags = merge(local.cis_v400_5_common_tags, {
    cis_item_id = "5.2"
    cis_level   = "2"
    cis_type    = "automated"
    service     = "GCP/Storage"
  })
}
