locals {
  cis_v400_1_common_tags = merge(local.cis_v400_common_tags, {
    cis_section_id = "1"
  })
}

benchmark "cis_v400_1" {
  title         = "1 Identity and Access Management"
  documentation = file("./cis_v400/docs/cis_v400_1.md")
  children = [
    control.cis_v400_1_1,
    control.cis_v400_1_2,
    control.cis_v400_1_3,
    control.cis_v400_1_4,
    control.cis_v400_1_5,
    control.cis_v400_1_6,
    control.cis_v400_1_7,
    control.cis_v400_1_8,
    control.cis_v400_1_9,
    control.cis_v400_1_10,
    control.cis_v400_1_11,
    control.cis_v400_1_12,
    control.cis_v400_1_13,
    control.cis_v400_1_14,
    control.cis_v400_1_15,
    control.cis_v400_1_16,
    control.cis_v400_1_17
  ]

  tags = merge(local.cis_v400_1_common_tags, {
    type = "Benchmark"
  })
}

control "cis_v400_1_1" {
  title         = "1.1 Ensure that Corporate Login Credentials are Used"
  description   = "Use corporate login credentials instead of consumer accounts, such as Gmail accounts."
  query         = query.iam_user_uses_corporate_login_credentials

  query_source  = "-- Please note: The table gcp_organization requires the resourcemanager.organizations.get permission to retrieve organization details. with user_with_access as (   select     distinct split_part(m, ':', 2) as member,     project,     _ctx,     location   from     gcp_iam_policy,     jsonb_array_elements(bindings) as b,     jsonb_array_elements_text(b -> 'members') as m   where     m like 'user:%' ) select   case when (select count(*) from gcp_organization) = 0 then a.project else a.member end as resource,   case     when (select count(*) from gcp_organization) = 0 then 'info'     when org.display_name is null then 'alarm'     else 'ok'   end as status,   case     when (select count(*) from gcp_organization) = 0 then 'Plugin authentication mechanism does not have organization viewer permission.'     when org.display_name is null then a.member || ' uses non-corporate login credentials.'     else a.member || ' uses corporate login credentials.'   end as reason   , a.project as project from   user_with_access as a   left join gcp_organization as org on split_part(a.member, '@', 2) = org.display_name   limit case when (select count(*) from gcp_organization) = 0 then 1 end;"
  documentation = file("./cis_v400/docs/cis_v400_1_1.md")

  tags = merge(local.cis_v400_1_common_tags, {
    cis_item_id = "1.1"
    cis_level   = "1"
    cis_type    = "manual"
    service     = "GCP/IAM"
  })
}

control "cis_v400_1_2" {
  title         = "1.2 Ensure that Multi-Factor Authentication is 'Enabled' for All Non-Service Accounts"
  description   = "Setup multi-factor authentication for Google Cloud Platform accounts."
  query         = query.manual_control

  query_source  = "select   'https://cloudresourcemanager.googleapis.com/v1/projects/' || project_id resource,   'info' status,   'Manual verification required.' reason   , project_id as project from   gcp_project;"
  documentation = file("./cis_v400/docs/cis_v400_1_2.md")

  tags = merge(local.cis_v400_1_common_tags, {
    cis_item_id = "1.2"
    cis_level   = "1"
    cis_type    = "manual"
    service     = "GCP/IAM"
  })
}

control "cis_v400_1_3" {
  title         = "1.3 Ensure that Security Key Enforcement is Enabled for All Admin Accounts"
  description   = "Setup Security Key Enforcement for Google Cloud Platform admin accounts."
  query         = query.manual_control

  query_source  = "select   'https://cloudresourcemanager.googleapis.com/v1/projects/' || project_id resource,   'info' status,   'Manual verification required.' reason   , project_id as project from   gcp_project;"
  documentation = file("./cis_v400/docs/cis_v400_1_3.md")

  tags = merge(local.cis_v400_1_common_tags, {
    cis_item_id = "1.3"
    cis_level   = "2"
    cis_type    = "manual"
    service     = "GCP/IAM"
  })
}

control "cis_v400_1_4" {
  title         = "1.4 Ensure That There Are Only GCP-Managed Service Account Keys for Each Service Account"
  description   = "User-managed service accounts should not have user-managed keys."
  query         = query.iam_service_account_gcp_managed_key

  query_source  = "with service_account_key as (   select     distinct service_account_name   from     gcp_service_account_key   where     key_type = 'USER_MANAGED' ) select   'https://iam.googleapis.com/v1/projects/' || project || '/serviceAccounts/' || name as resource,   case     when name like '%iam.gserviceaccount.com' and name in (select service_account_name from service_account_key) then 'alarm'     else 'ok'   end as status,   case     when name like '%iam.gserviceaccount.com' and name in (select service_account_name from service_account_key)       then title || ' has user-managed keys.'     else title || ' does not have user-managed keys.'   end as reason   , project as project from   gcp_service_account;"
  documentation = file("./cis_v400/docs/cis_v400_1_4.md")

  tags = merge(local.cis_v400_1_common_tags, {
    cis_item_id = "1.4"
    cis_level   = "1"
    cis_type    = "automated"
    service     = "GCP/IAM"
  })
}

control "cis_v400_1_5" {
  title         = "1.5 Ensure That Service Account Has No Admin Privileges"
  description   = "A service account is a special Google account that belongs to an application or a VM, instead of to an individual end-user. The application uses the service account to call the service's Google API so that users aren't directly involved. It's recommended not to use admin access for ServiceAccount."
  query         = query.iam_service_account_without_admin_privilege

  query_source  = "with user_roles as ( select   distinct split_part(entity, ':', 2) as user_name from   gcp_iam_policy,   jsonb_array_elements(bindings) as p,   jsonb_array_elements_text(p -> 'members') as entity where   p ->> 'role' like any (array ['%admin','%Admin','%Editor','%Owner','%editor','%owner'])   and split_part(entity, ':', 2) like '%@' || project || '.iam.gserviceaccount.com' ) select   'https://iam.googleapis.com/v1/projects/' || project || '/serviceAccounts/' || name as resource,   case     when name not like '%@' || project || '.iam.gserviceaccount.com' then 'skip'     when name in (select user_name from user_roles) then 'alarm'     else 'ok'   end as status,   case     when name not like '%@' || project || '.iam.gserviceaccount.com' then 'Google-created service account ' || title || ' excluded.'     when name in (select user_name from user_roles) then title || ' has admin privileges.'     else title || ' has no admin privileges.'   end as reason   , project as project from   gcp_service_account;"
  documentation = file("./cis_v400/docs/cis_v400_1_5.md")

  tags = merge(local.cis_v400_1_common_tags, {
    cis_item_id = "1.5"
    cis_level   = "1"
    cis_type    = "automated"
    service     = "GCP/IAM"
  })
}

control "cis_v400_1_6" {
  title         = "1.6 Ensure That IAM Users Are Not Assigned the Service Account User or Service Account Token Creator Roles at Project Level"
  description   = "It is recommended to assign the Service Account User (iam.serviceAccountUser) and Service Account Token Creator (iam.serviceAccountTokenCreator) roles to a user for a specific service account rather than assigning the role to a user at project level."
  query         = query.iam_user_not_assigned_service_account_user_role_project_level

  query_source  = "with unapproved_bindings as (   select     project,     p,     entity   from     gcp_iam_policy,     jsonb_array_elements(bindings) as p,     jsonb_array_elements_text(p -> 'members') as entity   where     p ->> 'role' in ('roles/iam.serviceAccountTokenCreator','roles/iam.serviceAccountUser')     and entity not like '%iam.gserviceaccount.com' ) select   p.project as resource,   case     when entity is not null then 'alarm'     else 'ok'   end as status,   case     when entity is not null       then 'IAM users associated with iam.serviceAccountTokenCreator or iam.serviceAccountUser role.'     else 'No IAM users associated with iam.serviceAccountTokenCreator or iam.serviceAccountUser role.'   end as reason   , p.project as project from   gcp_iam_policy as p   left join unapproved_bindings as b on p.project = b.project;"
  documentation = file("./cis_v400/docs/cis_v400_1_6.md")

  tags = merge(local.cis_v400_1_common_tags, {
    cis_item_id = "1.6"
    cis_level   = "1"
    cis_type    = "automated"
    service     = "GCP/IAM"
  })
}

control "cis_v400_1_7" {
  title         = "1.7 Ensure User-Managed/External Keys for Service Accounts Are Rotated Every 90 Days or Fewer"
  description   = "Service Account keys consist of a key ID (Private_key_Id) and Private key, which are used to sign programmatic requests users make to Google cloud services accessible to that particular service account. It is recommended that all Service Account keys are regularly rotated."
  query         = query.iam_service_account_key_age_90

  query_source  = "select   'https://iam.googleapis.com/v1/projects/' || project || '/serviceAccounts/' || service_account_name || '/keys/' || name as resource,   case     when valid_after_time <= (current_date - interval '90' day) then 'alarm'     else 'ok'   end as status,   service_account_name || ' ' || name || ' created ' || to_char(valid_after_time , 'DD-Mon-YYYY') ||     ' (' || extract(day from current_timestamp - valid_after_time) || ' days).'   as reason   , project as project from   gcp_service_account_key where   key_type = 'USER_MANAGED';"
  documentation = file("./cis_v400/docs/cis_v400_1_7.md")

  tags = merge(local.cis_v400_1_common_tags, {
    cis_item_id = "1.7"
    cis_level   = "1"
    cis_type    = "automated"
    service     = "GCP/IAM"
  })
}

control "cis_v400_1_8" {
  title         = "1.8 Ensure That Separation of Duties Is Enforced While Assigning Service Account Related Roles to Users"
  description   = "It is recommended that the principle of 'Separation of Duties' is enforced while assigning service-account related roles to users."
  query         = query.iam_user_separation_of_duty_enforced

  query_source  = "with users_with_roles as (   select     distinct split_part(member_entity, ':', 2) as user_name,     project,     _ctx,     p ->> 'role' as assigned_role   from     gcp_iam_policy,     jsonb_array_elements(bindings) as p,     jsonb_array_elements_text(p -> 'members') as member_entity   where     split_part(member_entity, ':', 1) = 'user' ), account_admin_users as(   select     user_name,     project   from     users_with_roles   where assigned_role = 'roles/iam.serviceAccountAdmin' ), account_users as(   select     user_name,     project   from     users_with_roles   where assigned_role = 'roles/iam.serviceAccountUser' ) select   distinct user_name as resource,   case     when user_name in (select user_name from account_users) and user_name in (select user_name from account_admin_users) then 'alarm'     else 'ok'   end as status,   case     when user_name in (select user_name from account_users) and user_name in (select user_name from account_admin_users)       then  user_name || ' assigned with both Service Account Admin and Service Account User roles.'     else user_name || ' not assigned with both Service Account Admin and Service Account User roles.'   end as reason   , project as project from   users_with_roles;"
  documentation = file("./cis_v400/docs/cis_v400_1_8.md")

  tags = merge(local.cis_v400_1_common_tags, {
    cis_item_id = "1.8"
    cis_level   = "2"
    cis_type    = "automated"
    service     = "GCP/IAM"
  })
}

control "cis_v400_1_9" {
  title         = "1.9 Ensure That Cloud KMS Cryptokeys Are Not Anonymously or Publicly Accessible"
  description   = "It is recommended that the IAM policy on Cloud KMS `cryptokeys` should restrict anonymous and/or public access."
  query         = query.kms_key_not_publicly_accessible

  query_source  = "with public_keys as (   select     distinct self_link   from     gcp_kms_key,     jsonb_array_elements(iam_policy -> 'bindings') as b   where     b -> 'members' ?| array['allAuthenticatedUsers', 'allUsers'] ) select   k.self_link as resource,   case     when p.self_link is null then 'ok'     else 'alarm'   end as status,   case     when p.self_link is null then title || ' in ' || k.key_ring_name || ' key ring not publicly accessible.'     else title || ' in ' || k.key_ring_name || ' key ring publicly accessible.'   end as reason      , location as location, project as project from   gcp_kms_key k left join public_keys p on k.self_link = p.self_link;"
  documentation = file("./cis_v400/docs/cis_v400_1_9.md")

  tags = merge(local.cis_v400_1_common_tags, {
    cis_item_id = "1.9"
    cis_level   = "1"
    cis_type    = "automated"
    service     = "GCP/KMS"
  })
}

control "cis_v400_1_10" {
  title         = "1.10 Ensure KMS Encryption Keys Are Rotated Within a Period of 90 Days"
  description   = "Google Cloud Key Management Service stores cryptographic keys in a hierarchical structure designed for useful and elegant access control management. The format for the rotation schedule depends on the client library that is used. For the gcloud command-line tool, the next rotation time must be in ISO or RFC3339 format, and the rotation period must be in the form INTEGER[UNIT], where units can be one of seconds (s), minutes (m), hours (h) or days (d)."
  query         = query.kms_key_rotated_within_90_day

  query_source  = "select   self_link as resource,   case     when \"primary\" ->> 'state' = 'DESTROYED' then 'skip'     when \"primary\" ->> 'state' = 'DESTROY_SCHEDULED' then 'skip'     when \"primary\" ->> 'state' = 'DISABLED' then 'skip'     when split_part(rotation_period, 's', 1) :: int <= 7776000 then 'ok'     else 'alarm'   end as status,   case     when \"primary\" ->> 'state' = 'DESTROYED' then title || ' is destroyed.'     when \"primary\" ->> 'state' = 'DESTROY_SCHEDULED' then title || ' is scheduled for deletion.'     when \"primary\" ->> 'state' = 'DISABLED' then title || ' is disabled.'     when rotation_period is null then title || ' in ' || key_ring_name || ' requires manual rotation.'     else key_ring_name || ' ' || title || ' rotation period set for ' || (split_part(rotation_period, 's', 1) :: int)/86400 || ' day(s).'   end as reason      , location as location, project as project from   gcp_kms_key;"
  documentation = file("./cis_v400/docs/cis_v400_1_10.md")

  tags = merge(local.cis_v400_1_common_tags, {
    cis_item_id = "1.10"
    cis_level   = "1"
    cis_type    = "automated"
    service     = "GCP/KMS"
  })
}

control "cis_v400_1_11" {
  title         = "1.11 Ensure That Separation of Duties Is Enforced While Assigning KMS Related Roles to Users"
  description   = "It is recommended that the principle of 'Separation of Duties' is enforced while assigning KMS related roles to users."
  query         = query.kms_key_separation_of_duties_enforced

  query_source  = "with users_with_roles as (   select     distinct split_part(member_entity, ':', 2) as user_name,     project,     _ctx,     array_agg(distinct p ->> 'role') as assigned_roles   from     gcp_iam_policy,     jsonb_array_elements(bindings) as p,     jsonb_array_elements_text(p -> 'members') as member_entity   where     split_part(member_entity, ':', 1) = 'user'   group by     user_name,     project,     _ctx ), kms_roles_users as (   select     user_name,     project,     assigned_roles   from     users_with_roles   where     'roles/cloudkms.admin' = any(assigned_roles)     and assigned_roles && array['roles/cloudkms.cryptoKeyEncrypterDecrypter', 'roles/cloudkms.cryptoKeyEncrypter', 'roles/cloudkms.cryptoKeyDecrypter'] ) select   distinct r.user_name as resource,   case     when 'roles/cloudkms.admin' = any(r.assigned_roles) and k.user_name is null then 'ok'     when k.user_name is not null then 'alarm'     else 'ok'   end as status,   case     when 'roles/cloudkms.admin' = any(r.assigned_roles) and k.user_name is null then r.user_name || ' assigned only with KMS admin role.'     when k.user_name is not null then r.user_name || ' assigned with roles/cloudkms.admin, ' ||       concat_ws(', ',         case when 'roles/cloudkms.cryptoKeyEncrypterDecrypter' = any(r.assigned_roles) then 'roles/cloudkms.cryptoKeyEncrypterDecrypter' end,         case when 'roles/cloudkms.cryptoKeyEncrypter' = any(r.assigned_roles) then 'roles/cloudkms.cryptoKeyEncrypter' end,         case when 'roles/cloudkms.cryptoKeyDecrypter' = any(r.assigned_roles) then 'roles/cloudkms.cryptoKeyDecrypter' end         ) || ' KMS role(s).'     else r.user_name || ' not assigned with KMS admin and additional encrypter/decrypter roles.'   end as reason   , r.project as project from   users_with_roles as r   left join kms_roles_users as k on k.user_name = r.user_name and k.project = r.project"
  documentation = file("./cis_v400/docs/cis_v400_1_11.md")

  tags = merge(local.cis_v400_1_common_tags, {
    cis_item_id = "1.11"
    cis_level   = "2"
    cis_type    = "automated"
    service     = "GCP/KMS"
  })
}

control "cis_v400_1_12" {
  title         = "1.12 Ensure API Keys Only Exist for Active Services"
  description   = "API Keys should only be used for services in cases where other authentication methods are unavailable. Unused keys with their permissions in tact may still exist within a project. Keys are insecure because they can be viewed publicly, such as from within a browser, or they can be accessed on a device where the key resides. It is recommended to use standard authentication flow instead."
  query         = query.project_no_api_key

  query_source  = "with project_api_key as (   select     project,     count(*) as api_key_count   from     gcp_apikeys_key   group by     project ), gcp_projects as (   select     self_link,     name,     project_id   from     gcp_project ) select   p.self_link as resource,   case     when k.api_key_count > 0  then 'alarm'     else 'ok'   end as status,   case     when k.api_key_count > 0 then p.name || ' has ' ||  k.api_key_count || ' api key(s).'     else p.name || ' has no api key(s).'   end as reason   , project_id as project from   gcp_projects as p   left join project_api_key as k on k.project = p.project_id;"
  documentation = file("./cis_v400/docs/cis_v400_1_12.md")

  tags = merge(local.cis_v400_1_common_tags, {
    cis_item_id = "1.12"
    cis_level   = "2"
    cis_type    = "automated"
    service     = "GCP/IAM"
  })
}

control "cis_v400_1_13" {
  title         = "1.13 Ensure API Keys Are Restricted To Use by Only Specified Hosts and Apps"
  description   = "API Keys should only be used for services in cases where other authentication methods are unavailable. In this case, unrestricted keys are insecure because they can be viewed publicly, such as from within a browser, or they can be accessed on a device where the key resides. It is recommended to restrict API key usage to trusted hosts, HTTP referrers and apps. It is recommended to use the more secure standard authentication flow instead."
  query         = query.iam_api_key_restricts_websites_hosts_apps

  query_source  = "select   'https://iam.googleapis.com/v1/projects/' || project || '/apikeys/' || name as resource,   case     when restrictions -> 'serverKeyRestrictions' is null       and restrictions -> 'browserKeyRestrictions' is null       and restrictions -> 'androidKeyRestrictions' is null       and restrictions -> 'iosKeyRestrictions' is null then 'alarm'     when restrictions -> 'serverKeyRestrictions' @> any( array[     '{\"allowedIps\": [\"0.0.0.0\"]}', '{\"allowedIps\": [\"0.0.0.0/0\"]}', '{\"allowedIps\": [\"::0\"]}']::jsonb[]) then 'alarm'     when restrictions -> 'browserKeyRestrictions' @> any( array[     '{\"allowedReferrers\": [\"*\"]}','{\"allowedReferrers\": [\"*.[TLD]/*\"]}','{\"allowedReferrers\": [\"*.[TLD]\"]}' ]::jsonb[] ) then 'alarm'     else 'ok'   end as status,   case     when restrictions -> 'serverKeyRestrictions' is null       and restrictions -> 'browserKeyRestrictions' is null       and restrictions -> 'androidKeyRestrictions' is null       and restrictions -> 'iosKeyRestrictions' is null       then title || ' API key not restricted to use any specified Websites, Hosts and Apps.'     when restrictions -> 'serverKeyRestrictions' @> any( array[     '{\"allowedIps\": [\"0.0.0.0\"]}', '{\"allowedIps\": [\"0.0.0.0/0\"]}', '{\"allowedIps\": [\"::0\"]}']::jsonb[]) then title || ' API key open to any hosts.'     when restrictions -> 'browserKeyRestrictions' @> any( array[     '{\"allowedReferrers\": [\"*\"]}','{\"allowedReferrers\": [\"*.[TLD]/*\"]}','{\"allowedReferrers\": [\"*.[TLD]\"]}' ]::jsonb[] ) then  title || ' API key open to any or wide range of HTTP referrer(s).'     else title || ' API key is restricted with specific Website(s), Host(s) and App(s).'   end as reason   , location as location, project as project from   gcp_apikeys_key;"
  documentation = file("./cis_v400/docs/cis_v400_1_13.md")

  tags = merge(local.cis_v400_1_common_tags, {
    cis_item_id = "1.13"
    cis_level   = "2"
    cis_type    = "manual"
    service     = "GCP/IAM"
  })
}

control "cis_v400_1_14" {
  title         = "1.14 Ensure API Keys Are Restricted to Only APIs That Application Needs Access"
  description   = "API Keys should only be used for services in cases where other authentication methods are unavailable. API keys are always at risk because they can be viewed publicly, such as from within a browser, or they can be accessed on a device where the key resides. It is recommended to restrict API keys to use (call) only APIs required by an application."
  query         = query.iam_api_key_restricts_apis

  query_source  = "select    'https://iam.googleapis.com/v1/projects/' || project || '/apikeys/' || name as resource,   case     when restrictions -> 'apiTargets' is null then 'alarm'     else 'ok'   end as status,   case     when restrictions -> 'apiTargets' is null then title || ' API key is not restricted to required APIs.'     else title || ' API key is restricted to only required APIs.'   end as reason   , location as location, project as project from   gcp_apikeys_key;"
  documentation = file("./cis_v400/docs/cis_v400_1_14.md")

  tags = merge(local.cis_v400_1_common_tags, {
    cis_item_id = "1.14"
    cis_level   = "2"
    cis_type    = "automated"
    service     = "GCP/IAM"
  })
}

control "cis_v400_1_15" {
  title         = "1.15 Ensure API Keys Are Rotated Every 90 Days"
  description   = "API Keys should only be used for services in cases where other authentication methods are unavailable. If they are in use it is recommended to rotate API keys every 90 days."
  query         = query.iam_api_key_age_90

  query_source  = "select   'https://iam.googleapis.com/v1/projects/' || project || '/apikeys/' || name as resource,   case     when create_time <= (current_date - interval '90' day) then 'alarm'     else 'ok'   end as status,   display_name || ' ' || uid || ' created ' || to_char(create_time , 'DD-Mon-YYYY') ||     ' (' || extract(day from current_timestamp - create_time) || ' days).'   as reason   , project as project from   gcp_apikeys_key;"
  documentation = file("./cis_v400/docs/cis_v400_1_15.md")

  tags = merge(local.cis_v400_1_common_tags, {
    cis_item_id = "1.15"
    cis_level   = "2"
    cis_type    = "automated"
    service     = "GCP/IAM"
  })
}

control "cis_v400_1_16" {
  title         = "1.16 Ensure Essential Contacts is Configured for Organization"
  description   = "It is recommended that Essential Contacts is configured to designate email addresses for Google Cloud services to notify of important technical or security information."
  query         = query.organization_essential_contacts_configured

  query_source  = "-- \"Essential Contacts API\" should be Enabled and requires \"Essential Contacts Viewer\" at Organization level. with categories as (   select     name,     title,     _ctx,     organization_id,     notificationtype   from     gcp_organization,     jsonb_array_elements(essential_contacts) as ec,     jsonb_array_elements_text(ec -> 'notificationCategorySubscriptions') as notificationtype ) select   name resource,   case     when jsonb_array_length('[\"LEGAL\", \"SECURITY\", \"SUSPENSION\", \"TECHNICAL\", \"TECHNICAL_INCIDENTS\"]'::jsonb - array_agg(notificationtype)) = 0 then 'ok'     when to_jsonb(array_agg(notificationtype)) @> '[\"ALL\"]'::jsonb then 'ok'     else 'alarm'   end as status,   case     when jsonb_array_length('[\"LEGAL\", \"SECURITY\", \"SUSPENSION\", \"TECHNICAL\", \"TECHNICAL_INCIDENTS\"]'::jsonb - array_agg(notificationtype)) = 0       then title || ' essential contacts are configured.'     when to_jsonb(array_agg(notificationtype)) @> '[\"ALL\"]'::jsonb       then title || ' essential contacts are configured.'     else title || ' essential contacts are not configured.'   end as reason,   organization_id from   categories group by   name,   title,   _ctx,   organization_id;"
  documentation = file("./cis_v400/docs/cis_v400_1_16.md")

  tags = merge(local.cis_v400_1_common_tags, {
    cis_item_id = "1.16"
    cis_level   = "1"
    cis_type    = "automated"
    service     = "GCP/Organization"
  })
}

control "cis_v400_1_17" {
  title         = "1.17 Ensure Secrets are Not Stored in Cloud Functions Environment Variables by Using Secret Manager"
  description   = "Google Cloud Functions allow you to host serverless code that is executed when an event is triggered, without the requiring the management a host operating system. These functions can also store environment variables to be used by the code that may contain authentication or other information that needs to remain confidential."
  query         = query.manual_control

  query_source  = "select   'https://cloudresourcemanager.googleapis.com/v1/projects/' || project_id resource,   'info' status,   'Manual verification required.' reason   , project_id as project from   gcp_project;"
  documentation = file("./cis_v400/docs/cis_v400_1_17.md")

  tags = merge(local.cis_v400_1_common_tags, {
    cis_item_id = "1.17"
    cis_level   = "1"
    cis_type    = "manual"
    service     = "GCP/Dataproc"
  })
}
