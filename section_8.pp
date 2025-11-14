locals {
  cis_v400_8_common_tags = merge(local.cis_v400_common_tags, {
    cis_section_id = "8"
  })
}

benchmark "cis_v400_8" {
  title         = "8 Dataproc"
  documentation = file("./cis_v400/docs/cis_v400_8.md")
  children = [
    control.cis_v400_8_1
  ]

  tags = merge(local.cis_v400_8_common_tags, {
    type    = "Benchmark"
    service = "GCP/Dataproc"
  })
}

control "cis_v400_8_1" {
  title         = "8.1 Ensure that Dataproc Cluster is encrypted using Customer-Managed Encryption Key"
  description   = "When you use Dataproc, cluster and job data is stored on Persistent Disks (PDs) associated with the Compute Engine VMs in your cluster and in a Cloud Storage staging bucket. This PD and bucket data is encrypted using a Google-generated data encryption key (DEK) and key encryption key (KEK). The CMEK feature allows you to create, use, and revoke the key encryption key (KEK). Google still controls the data encryption key (DEK)."
  query         = query.dataproc_cluster_encryption_with_cmek

  query_source  = "select   cluster_name resource,   case     when config -> 'encryptionConfig' ->> 'gcePdKmsKeyName' is null then 'alarm'     else 'ok'   end as status,   case     when config -> 'encryptionConfig' ->> 'gcePdKmsKeyName' is null       then title || ' is not encrypted using customer-managed encryption keys (CMEK).'     else title || ' is encrypted using customer-managed encryption keys (CMEK).'   end as reason      , location as location, project as project from   gcp_dataproc_cluster;"
  documentation = file("./cis_v400/docs/cis_v400_8_1.md")

  tags = merge(local.cis_v400_8_common_tags, {
    cis_item_id = "8.1"
    cis_type    = "automated"
    cis_level   = "2"
    service     = "GCP/Dataproc"
  })
}
