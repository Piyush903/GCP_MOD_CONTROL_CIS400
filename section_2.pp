locals {
  cis_v400_2_common_tags = merge(local.cis_v400_common_tags, {
    cis_section_id = "2"
  })
}

benchmark "cis_v400_2" {
  title         = "2 Logging and Monitoring"
  documentation = file("./cis_v400/docs/cis_v400_2.md")
  children = [
    control.cis_v400_2_1,
    control.cis_v400_2_2,
    control.cis_v400_2_3,
    control.cis_v400_2_4,
    control.cis_v400_2_5,
    control.cis_v400_2_6,
    control.cis_v400_2_7,
    control.cis_v400_2_8,
    control.cis_v400_2_9,
    control.cis_v400_2_10,
    control.cis_v400_2_11,
    control.cis_v400_2_12,
    control.cis_v400_2_13,
    control.cis_v400_2_14,
    control.cis_v400_2_15,
    control.cis_v400_2_16
  ]

  tags = merge(local.cis_v400_2_common_tags, {
    type = "Benchmark"
  })
}

control "cis_v400_2_1" {
  title         = "2.1 Ensure That Cloud Audit Logging Is Configured Properly"
  description   = "It is recommended that Cloud Audit Logging is configured to track all admin activities and read, write access to user data."
  query         = query.audit_logging_configured_for_all_service

  query_source  = "with default_audit_configs as (   select     *   from     (       select         service,         string_agg(log ->> 'logType', ', ') log_types,         string_agg(log ->> 'exemptedMembers', ', ') exempted_user,         _ctx,         project       from         gcp_audit_policy,         jsonb_array_elements(audit_log_configs) as log       group by         service, project, _ctx     ) logs   where     log_types like '%DATA_WRITE%'     and log_types like '%DATA_READ%'     and log_types like '%ADMIN_READ%'     and service = 'allServices' ) select   default_audit_configs.service resource,   case     when default_audit_configs.exempted_user is null then 'ok'     else 'alarm'   end as status,   case     when default_audit_configs.exempted_user is null       then 'Audit logging properly configured across all services and no exempted users associated.'     else 'Audit logging not configured as per CIS requirement or default audit setting having exempted user.'   end as reason   , default_audit_configs.project as project from   default_audit_configs;"
  documentation = file("./cis_v400/docs/cis_v400_2_1.md")

  tags = merge(local.cis_v400_2_common_tags, {
    cis_item_id = "2.1"
    cis_level   = "1"
    cis_type    = "automated"
    service     = "GCP/Logging"
  })
}

control "cis_v400_2_2" {
  title         = "2.2 Ensure That Sinks Are Configured for All Log Entries"
  description   = "It is recommended to create a sink that will export copies of all the log entries. This can help aggregate logs from multiple projects and export them to a Security Information and Event Management (SIEM)."
  query         = query.logging_sink_configured_for_all_resource

  query_source  = "with project_sink_count as (   select     project,     count(*) no_of_sink   from     gcp_logging_sink   where     filter = ''     and destination != ''   group by     project ) select   'https://www.googleapis.com/logging/v2/projects/' || s.project resource,   case     when s.no_of_sink > 0 then 'ok'     else 'alarm'   end as status,   case     when s.no_of_sink > 0       then 'Sinks configured for all log entries.'     else 'Sinks not configured for all log entries.'   end as reason      , p.project_id as project from   gcp_project p   left join project_sink_count s on s.project = p.project_id;"
  documentation = file("./cis_v400/docs/cis_v400_2_2.md")

  tags = merge(local.cis_v400_2_common_tags, {
    cis_item_id = "2.2"
    cis_level   = "1"
    cis_type    = "automated"
    service     = "GCP/Logging"
  })
}

control "cis_v400_2_3" {
  title         = "2.3 Ensure That Retention Policies on Cloud Storage Buckets Used for Exporting Logs Are Configured Using Bucket Lock"
  description   = "Enabling retention policies on log buckets will protect logs stored in cloud storage buckets from being overwritten or accidentally deleted. It is recommended to set up retention policies and configure Bucket Lock on all storage buckets that are used as log sinks."
  query         = query.logging_bucket_retention_policy_enabled

  query_source  = "with logging_sinks as (   select     self_link,     title,     _ctx,     project,     destination   from     gcp_logging_sink ) select   s.self_link resource,   case     when b.retention_policy is not null and b.retention_policy ->> 'isLocked' = 'true' then 'ok'     else 'alarm'   end as status,   case     when b.retention_policy is not null and b.retention_policy ->> 'isLocked' = 'true'       then s.title || '''s logging bucket ' || b.name || ' has retention policies configured.'     else s.title || '''s logging bucket ' || b.name || ' has retention policies not configured.'   end as reason   , s.project as project from   gcp_storage_bucket b   join logging_sinks s on (   split_part(s.destination, '/', 1) = 'storage.googleapis.com'   and split_part(s.destination, '/', 2) = b.name );"
  documentation = file("./cis_v400/docs/cis_v400_2_3.md")

  tags = merge(local.cis_v400_2_common_tags, {
    cis_item_id = "2.3"
    cis_level   = "2"
    cis_type    = "automated"
    service     = "GCP/Logging"
  })
}

control "cis_v400_2_4" {
  title         = "2.4 Ensure Log Metric Filter and Alerts Exist for Project Ownership Assignments/Changes"
  description   = "In order to prevent unnecessary project ownership assignments to users/service-accounts and further misuses of projects and resources, all roles/Owner assignments should be monitored. Members (users/Service-Accounts) with a role assignment to primitive role roles/Owner are project owners."
  query         = query.logging_metric_alert_project_ownership_assignment

  query_source  = "with filter_data as (   select     m.project as project,     display_name alert_name,     count(m.name) metric_name   from     gcp_monitoring_alert_policy,     jsonb_array_elements(conditions) as filter_condition     join gcp_logging_metric m on m.filter ~ '\\s*\\(protoPayload.serviceName\\s*=\\s*\"cloudresourcemanager.googleapis.com\"\\s*\\)\\s*AND\\s*\\(\\s*ProjectOwnership\\s*OR\\s*projectOwnerInvitee\\s*\\)\\s*OR\\s*\\(\\s*protoPayload.serviceData.policyDelta.bindingDeltas.action\\s*=\\s*\"REMOVE\"\\s*AND\\s*protoPayload.serviceData.policyDelta.bindingDeltas.role\\s*=\\s*\"roles/owner\"\\s*\\)\\s*OR\\s*\\(\\s*protoPayload.serviceData.policyDelta.bindingDeltas.action\\s*=\\s*\"ADD\"\\s*AND\\s*protoPayload.serviceData.policyDelta.bindingDeltas.role\\s*=\\s*\"roles/owner\"\\s*\\)\\s*'     and filter_condition -> 'conditionThreshold' ->> 'filter' like '%metric.type=\"' || m.metric_descriptor_type || '\"%'   where     enabled   group by     m.project, display_name, m.name ) select   'https://cloudresourcemanager.googleapis.com/v1/projects/' || project_id resource,   case     when d.metric_name > 0  then 'ok'     else 'alarm'   end as status,   case     when d.metric_name > 0       then 'Log metric and alert exist for project ownership assignments/changes.'     else 'Log metric and alert do not exist exist for project ownership assignments/changes.'   end as reason      , project_id as project from   gcp_project as p   left join filter_data as d on d.project = p.name;"
  documentation = file("./cis_v400/docs/cis_v400_2_4.md")

  tags = merge(local.cis_v400_2_common_tags, {
    cis_item_id = "2.4"
    cis_level   = "1"
    cis_type    = "automated"
    service     = "GCP/Logging"
  })
}

control "cis_v400_2_5" {
  title         = "2.5 Ensure That the Log Metric Filter and Alerts Exist for Audit Configuration Changes"
  description   = "Google Cloud Platform (GCP) services write audit log entries to the Admin Activity and Data Access logs to help answer the questions of, \"who did what, where, and when?\" within GCP projects."
  query         = query.logging_metric_alert_audit_configuration_changes

  query_source  = "with filter_data as (   select     m.project as project,     display_name alert_name,     count(m.name) metric_name   from     gcp_monitoring_alert_policy,     jsonb_array_elements(conditions) as filter_condition     join gcp_logging_metric m on m.filter ~ '\\s*protoPayload.methodName\\s*=\\s*\"SetIamPolicy\"\\s*AND\\s*protoPayload.serviceData.policyDelta.auditConfigDeltas:\\*\\s*'     and filter_condition -> 'conditionThreshold' ->> 'filter' like '%metric.type=\"' || m.metric_descriptor_type || '\"%'   where     enabled   group by     m.project, display_name, m.name ) select   'https://cloudresourcemanager.googleapis.com/v1/projects/' || project_id resource,   case     when d.metric_name > 0 then 'ok'     else 'alarm'   end as status,   case     when d.metric_name > 0       then 'Log metric and alert exist for audit configuration changes.'     else 'Log metric and alert do not exist for audit configuration changes.'   end as reason      , project_id as project from   gcp_project as p   left join filter_data as d on d.project = p.name;"
  documentation = file("./cis_v400/docs/cis_v400_2_5.md")

  tags = merge(local.cis_v400_2_common_tags, {
    cis_item_id = "2.5"
    cis_level   = "1"
    cis_type    = "automated"
    service     = "GCP/Logging"
  })
}

control "cis_v400_2_6" {
  title         = "2.6 Ensure That the Log Metric Filter and Alerts Exist for Custom Role Changes"
  description   = "It is recommended that a metric filter and alarm be established for changes to Identity and Access Management (IAM) role creation, deletion and updating activities."
  query         = query.logging_metric_alert_custom_role_changes_with_iam_admin_undelete_role

  query_source  = "with filter_data as (   select     m.project as project,     display_name alert_name,     count(m.name) metric_name   from     gcp_monitoring_alert_policy,     jsonb_array_elements(conditions) as filter_condition     join gcp_logging_metric m on m.filter ~ '\\s*resource\\.type\\s*=\\s*\"iam_role\"\\s*AND\\s*\\(\\s*protoPayload\\.methodName\\s*=\\s*\"google\\.iam\\.admin\\.v1\\.CreateRole\"\\s*OR\\s*protoPayload\\.methodName\\s*=\\s*\"google\\.iam\\.admin\\.v1\\.DeleteRole\"\\s*OR\\s*protoPayload\\.methodName\\s*=\\s*\"google\\.iam\\.admin\\.v1\\.UpdateRole\"\\s*OR\\s*protoPayload\\.methodName\\s*=\\s*\"google\\.iam\\.admin\\.v1\\.UndeleteRole\"\\s*\\)'     and filter_condition -> 'conditionThreshold' ->> 'filter' like '%metric.type=\"' || m.metric_descriptor_type || '\"%'   where     enabled   group by     m.project, display_name, m.name ) select   'https://cloudresourcemanager.googleapis.com/v1/projects/' || project_id resource,   case     when d.metric_name > 0 then 'ok'     else 'alarm'   end as status,   case     when d.metric_name > 0       then 'Log metric and alert exist for custom role changes.'     else 'Log metric and alert do not exist for custom role changes.'   end as reason      , project_id as project from   gcp_project as p   left join filter_data as d on d.project = p.name;"
  documentation = file("./cis_v400/docs/cis_v400_2_6.md")

  tags = merge(local.cis_v400_2_common_tags, {
    cis_item_id = "2.6"
    cis_level   = "1"
    cis_type    = "automated"
    service     = "GCP/Logging"
  })
}

control "cis_v400_2_7" {
  title         = "2.7 Ensure That the Log Metric Filter and Alerts Exist for VPC Network Firewall Rule Changes"
  description   = "It is recommended that a metric filter and alarm be established for Virtual Private Cloud (VPC) Network Firewall rule changes."
  query         = query.logging_metric_alert_firewall_rule_changes

  query_source  = "with filter_data as (   select     m.project as project,     display_name alert_name,     count(m.name) metric_name   from     gcp_monitoring_alert_policy,     jsonb_array_elements(conditions) as filter_condition     join gcp_logging_metric m on m.filter ~ '\\s*resource\\.type\\s*=\\s*\"gce_firewall_rule\"\\s*AND\\s*\\(\\s*protoPayload\\.methodName\\s*:\\s*\"compute\\.firewalls\\.patch\"\\s*OR\\s*protoPayload\\.methodName\\s*:\\s*\"compute\\.firewalls\\.insert\"\\s*OR\\s*protoPayload\\.methodName\\s*:\\s*\"compute\\.firewalls\\.delete\"\\s*\\)'     and filter_condition -> 'conditionThreshold' ->> 'filter' like '%metric.type=\"' || m.metric_descriptor_type || '\"%'   where     enabled   group by     m.project, display_name, m.name ) select   'https://cloudresourcemanager.googleapis.com/v1/projects/' || project_id resource,   case     when d.metric_name > 0 then 'ok'     else 'alarm'   end as status,   case     when d.metric_name > 0       then 'Log metric and alert exist for network firewall rule changes.'     else 'Log metric and alert do not exist network for firewall rule changes.'   end as reason      , project_id as project from   gcp_project as p   left join filter_data as d on d.project = p.name;"
  documentation = file("./cis_v400/docs/cis_v400_2_7.md")

  tags = merge(local.cis_v400_2_common_tags, {
    cis_item_id = "2.7"
    cis_level   = "2"
    cis_type    = "automated"
    service     = "GCP/Logging"
  })
}

control "cis_v400_2_8" {
  title         = "2.8 Ensure That the Log Metric Filter and Alerts Exist for VPC Network Route Changes"
  description   = "It is recommended that a metric filter and alarm be established for Virtual Private Cloud (VPC) network route changes."
  query         = query.logging_metric_alert_network_route_changes

  query_source  = "with filter_data as (   select     m.project as project,     display_name alert_name,     count(m.name) metric_name   from     gcp_monitoring_alert_policy,     jsonb_array_elements(conditions) as filter_condition     join gcp_logging_metric m on m.filter ~ '\\s*resource\\.type\\s*=\\s*\"gce_route\"\\s*AND\\s*\\(\\s*protoPayload\\.methodName\\s*:\\s*\"compute\\.routes\\.delete\"\\s*OR\\s*protoPayload\\.methodName\\s*:\\s*\"compute\\.routes\\.insert\"\\s*\\)'     and filter_condition -> 'conditionThreshold' ->> 'filter' like '%metric.type=\"' || m.metric_descriptor_type || '\"%'   where     enabled   group by     m.project, display_name, m.name ) select   'https://cloudresourcemanager.googleapis.com/v1/projects/' || project_id resource,   case     when d.metric_name > 0 then 'ok'     else 'alarm'   end as status,   case     when d.metric_name > 0       then 'Log metric and alert exist for network route changes.'     else 'Log metric and alert do not exist for network route changes.'   end as reason      , project_id as project from   gcp_project as p   left join filter_data as d on d.project = p.name;"
  documentation = file("./cis_v400/docs/cis_v400_2_8.md")

  tags = merge(local.cis_v400_2_common_tags, {
    cis_item_id = "2.8"
    cis_level   = "2"
    cis_type    = "automated"
    service     = "GCP/Logging"
  })
}

control "cis_v400_2_9" {
  title         = "2.9 Ensure That the Log Metric Filter and Alerts Exist for VPC Network Changes"
  description   = "It is recommended that a metric filter and alarm be established for Virtual Private Cloud (VPC) network changes."
  query         = query.logging_metric_alert_network_changes

  query_source  = "with filter_data as (   select     m.project as project,     display_name alert_name,     count(m.name) metric_name   from     gcp_monitoring_alert_policy,     jsonb_array_elements(conditions) as filter_condition     join gcp_logging_metric m on m.filter ~ '\\s*resource\\.type\\s*=\\s*gce_network\\s*AND\\s*\\(\\s*protoPayload\\.methodName\\s*=\\s*\"beta\\.compute\\.networks\\.insert\"\\s*OR\\s*protoPayload\\.methodName\\s*=\\s*\"beta\\.compute\\.networks\\.patch\"\\s*OR\\s*protoPayload\\.methodName\\s*=\\s*\"v1\\.compute\\.networks\\.delete\"\\s*OR\\s*protoPayload\\.methodName\\s*=\\s*\"v1\\.compute\\.networks\\.removePeering\"\\s*OR\\s*protoPayload\\.methodName\\s*=\\s*\"v1\\.compute\\.networks\\.addPeering\"\\s*\\)'     and filter_condition -> 'conditionThreshold' ->> 'filter' like '%metric.type=\"' || m.metric_descriptor_type || '\"%'   where     enabled   group by     m.project, display_name, m.name ) select   'https://cloudresourcemanager.googleapis.com/v1/projects/' || project_id resource,   case     when d.metric_name > 0 then 'ok'     else 'alarm'   end as status,   case     when d.metric_name > 0       then 'Log metric and alert exist for network changes.'     else 'Log metric and alert do not exist for network changes.'   end as reason      , project_id as project from   gcp_project as p   left join filter_data as d on d.project = p.name;"
  documentation = file("./cis_v400/docs/cis_v400_2_9.md")

  tags = merge(local.cis_v400_2_common_tags, {
    cis_item_id = "2.9"
    cis_level   = "2"
    cis_type    = "automated"
    service     = "GCP/Logging"
  })
}

control "cis_v400_2_10" {
  title         = "2.10 Ensure That the Log Metric Filter and Alerts Exist for Cloud Storage IAM Permission Changes"
  description   = "It is recommended that a metric filter and alarm be established for Cloud Storage Bucket IAM changes."
  query         = query.logging_metric_alert_storage_iam_permission_changes

  query_source  = "with filter_data as (   select     m.project as project,     display_name alert_name,     count(m.name) metric_name   from     gcp_monitoring_alert_policy,     jsonb_array_elements(conditions) as filter_condition     join gcp_logging_metric m on m.filter ~ '\\s*resource\\.type\\s*=\\s*\"gcs_bucket\"\\s*AND\\s*protoPayload\\.methodName\\s*=\\s*\"storage\\.setIamPermissions\"'     and filter_condition -> 'conditionThreshold' ->> 'filter' like '%metric.type=\"' || m.metric_descriptor_type || '\"%'   where     enabled   group by     m.project, display_name, m.name ) select   'https://cloudresourcemanager.googleapis.com/v1/projects/' || project_id resource,   case     when d.metric_name > 0 then 'ok'     else 'alarm'   end as status,   case     when d.metric_name > 0       then 'Log metric and alert exist for Storage IAM permission changes.'     else 'Log metric and alert do not exist for Storage IAM permission changes.'   end as reason      , project_id as project from   gcp_project as p   left join filter_data as d on d.project = p.name;"
  documentation = file("./cis_v400/docs/cis_v400_2_10.md")

  tags = merge(local.cis_v400_2_common_tags, {
    cis_item_id = "2.10"
    cis_level   = "2"
    cis_type    = "automated"
    service     = "GCP/Logging"
  })
}

control "cis_v400_2_11" {
  title         = "2.11 Ensure That the Log Metric Filter and Alerts Exist for SQL Instance Configuration Changes"
  description   = "It is recommended that a metric filter and alarm be established for SQL instance configuration changes."
  query         = query.logging_metric_alert_sql_instance_configuration_changes

  query_source  = "with filter_data as (   select     m.project as project,     display_name alert_name,     count(m.name) metric_name   from     gcp_monitoring_alert_policy,     jsonb_array_elements(conditions) as filter_condition     join gcp_logging_metric m on m.filter ~ '\\s*protoPayload.methodName\\s*=\\s*\"cloudsql.instances.update\"\\s*'     and filter_condition -> 'conditionThreshold' ->> 'filter' like '%metric.type=\"' || m.metric_descriptor_type || '\"%'   where     enabled   group by     m.project, display_name, m.name ) select   'https://cloudresourcemanager.googleapis.com/v1/projects/' || project_id resource,   case     when d.metric_name > 0 then 'ok'     else 'alarm'   end as status,   case     when d.metric_name > 0       then 'Log metric and alert exist for SQL instance configuration changes.'     else 'Log metric and alert do not exist for SQL instance configuration changes.'   end as reason      , project_id as project from   gcp_project as p   left join filter_data as d on d.project = p.name"
  documentation = file("./cis_v400/docs/cis_v400_2_11.md")

  tags = merge(local.cis_v400_2_common_tags, {
    cis_item_id = "2.11"
    cis_level   = "2"
    cis_type    = "automated"
    service     = "GCP/Logging"
  })
}

control "cis_v400_2_12" {
  title         = "2.12 Ensure That Cloud DNS Logging Is Enabled for All VPC Networks"
  description   = "Cloud DNS logging records the queries from the name servers within your VPC to Stackdriver. Logged queries can come from Compute Engine VMs, GKE containers, or other GCP resources provisioned within the VPC."
  query         = query.compute_network_dns_logging_enabled

  query_source  = "with associated_networks as (   select     split_part(network ->> 'networkUrl', 'networks/', 2) network_name,     enable_logging   from     gcp_dns_policy,     jsonb_array_elements(networks) network ) select   net.self_link resource,   case     when p.network_name is null then 'alarm'     when not p.enable_logging then 'alarm'     else 'ok'   end as status,   case     when p.network_name is null then net.title || ' not associated with DNS policy.'     when not p.enable_logging then net.title || ' associated with DNS policy with logging disabled.'     else net.title || ' associated with DNS policy with logging enabled.'   end as reason   , project as project from   gcp_compute_network net left join associated_networks p on net.name = p.network_name;"
  documentation = file("./cis_v400/docs/cis_v400_2_12.md")

  tags = merge(local.cis_v400_2_common_tags, {
    cis_item_id = "2.12"
    cis_level   = "1"
    cis_type    = "automated"
    service     = "GCP/DNS"
  })
}

control "cis_v400_2_13" {
  title         = "2.13 Ensure Cloud Asset Inventory Is Enabled"
  description   = "GCP Cloud Asset Inventory is services that provides a historical view of GCP resources and IAM policies through a time-series database. The information recorded includes metadata on Google Cloud resources, metadata on policies set on Google Cloud projects or resources, and runtime information gathered within a Google Cloud resource."
  query         = query.project_service_cloudasset_api_enabled

  query_source  = "select   name as resource,   case     when state = 'ENABLED' then 'ok'     else 'alarm'   end as status,   case     when state = 'ENABLED'       then name || ' Cloud Asset API is enabled.'     else name || ' Cloud Asset API is disabled.'   end as reason   , location as location, project as project from   gcp_project_service where   name = 'cloudasset.googleapis.com';"
  documentation = file("./cis_v400/docs/cis_v400_2_13.md")

  tags = merge(local.cis_v400_2_common_tags, {
    cis_item_id = "2.13"
    cis_level   = "1"
    cis_type    = "automated"
    service     = "GCP/Project"
  })
}

control "cis_v400_2_14" {
  title         = "2.14 Ensure 'Access Transparency' is 'Enabled'"
  description   = "GCP Access Transparency provides audit logs for all actions that Google personnel take in your Google Cloud resources."
  query         = query.manual_control

  query_source  = "select   'https://cloudresourcemanager.googleapis.com/v1/projects/' || project_id resource,   'info' status,   'Manual verification required.' reason   , project_id as project from   gcp_project;"
  documentation = file("./cis_v400/docs/cis_v400_2_14.md")

  tags = merge(local.cis_v400_2_common_tags, {
    cis_item_id = "2.14"
    cis_level   = "2"
    cis_type    = "manual"
    service     = "GCP/Project"
  })
}

control "cis_v400_2_15" {
  title         = "2.15 Ensure 'Access Approval' is 'Enabled'"
  description   = "GCP Access Approval enables you to require your organizations' explicit approval whenever Google support try to access your projects. You can then select users within your organization who can approve these requests through giving them a security role in IAM. All access requests display which Google Employee requested them in an email or Pub/Sub message that you can choose to Approve. This adds an additional control and logging of who in your organization approved/denied these requests."
  query         = query.project_access_approval_settings_enabled

  query_source  = "select   self_link as resource,   case     when access_approval_settings is not null and access_approval_settings -> 'notificationEmails' is not null then 'ok'     else 'alarm'   end as status,   case     when access_approval_settings is not null and access_approval_settings -> 'notificationEmails' is not null       then name || ' access approval is enabled.'     else name || ' access approval is disabled.'   end as reason   , project_id as project from   gcp_project;"
  documentation = file("./cis_v400/docs/cis_v400_2_15.md")

  tags = merge(local.cis_v400_2_common_tags, {
    cis_item_id = "2.15"
    cis_level   = "2"
    cis_type    = "automated"
    service     = "GCP/Project"
  })
}

control "cis_v400_2_16" {
  title         = "2.16 Ensure Logging is enabled for HTTP(S) Load Balancer"
  description   = "Logging enabled on a HTTPS Load Balancer will show all network traffic and its destination."
  query         = query.compute_https_load_balancer_logging_enabled

  query_source  = "select   m.self_link as resource,   case     when s.self_link is null then 'skip'     when s.log_config_enable then 'ok'     else 'alarm'   end as status,   case     when s.self_link is null then m.name || ' uses backend bucket.'     when s.log_config_enable then m.name || ' logging enabled.'     else m.name || ' logging disabled.'   end as reason   , m.location as location, m.project as project from   gcp_compute_url_map as m   left join gcp_compute_backend_service as s on s.self_link = m.default_service;"
  documentation = file("./cis_v400/docs/cis_v400_2_16.md")

  tags = merge(local.cis_v400_2_common_tags, {
    cis_item_id = "2.16"
    cis_level   = "2"
    cis_type    = "automated"
    service     = "GCP/Logging"
  })
}
