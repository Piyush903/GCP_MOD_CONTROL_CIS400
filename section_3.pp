locals {
  cis_v400_3_common_tags = merge(local.cis_v400_common_tags, {
    cis_section_id = "3"
  })
}

benchmark "cis_v400_3" {
  title         = "3 Networking"
  documentation = file("./cis_v400/docs/cis_v400_3.md")
  children = [
    control.cis_v400_3_1,
    control.cis_v400_3_2,
    control.cis_v400_3_3,
    control.cis_v400_3_4,
    control.cis_v400_3_5,
    control.cis_v400_3_6,
    control.cis_v400_3_7,
    control.cis_v400_3_8,
    control.cis_v400_3_9,
    control.cis_v400_3_10
  ]

  tags = merge(local.cis_v400_3_common_tags, {
    type = "Benchmark"
  })
}

control "cis_v400_3_1" {
  title         = "3.1 Ensure That the Default Network Does Not Exist in a Project"
  description   = "To prevent use of `default` network, a project should not have a `default` network."
  query         = query.compute_network_contains_no_default_network

  query_source  = "select   self_link resource,   case     when name = 'default' then 'alarm'     else 'ok'   end as status,   case     when name = 'default'       then title || ' is a default network.'     else title || ' not a default network.'   end as reason   , project as project from   gcp_compute_network;"
  documentation = file("./cis_v400/docs/cis_v400_3_1.md")

  tags = merge(local.cis_v400_3_common_tags, {
    cis_item_id = "3.1"
    cis_level   = "2"
    cis_type    = "automated"
    service     = "GCP/Compute"
  })
}

control "cis_v400_3_2" {
  title         = "3.2 Ensure Legacy Networks Do Not Exist for Older Projects"
  description   = "In order to prevent use of legacy networks, a project should not have a legacy network configured. As of now, Legacy Networks are gradually being phased out, and you can no longer create projects with them. This recommendation is to check older projects to ensure that they are not using Legacy Networks."
  query         = query.compute_network_contains_no_legacy_network

  query_source  = "select   self_link resource,   case     when ipv4_range is not null then 'alarm'     else 'ok'   end as status,   case     when ipv4_range is not null       then title || ' is a legacy network.'     else title || ' not a legacy network.'   end as reason   , project as project from   gcp_compute_network;"
  documentation = file("./cis_v400/docs/cis_v400_3_2.md")

  tags = merge(local.cis_v400_3_common_tags, {
    cis_item_id = "3.2"
    cis_level   = "1"
    cis_type    = "automated"
    service     = "GCP/Compute"
  })
}

control "cis_v400_3_3" {
  title         = "3.3 Ensure That DNSSEC Is Enabled for Cloud DNS"
  description   = "Cloud Domain Name System (DNS) is a fast, reliable and cost-effective domain name system that powers millions of domains on the internet. Domain Name System Security Extensions (DNSSEC) in Cloud DNS enables domain owners to take easy steps to protect their domains against DNS hijacking and man-in-the-middle and other attacks."
  query         = query.dns_managed_zone_dnssec_enabled

  query_source  = "select   self_link resource,   case     when visibility = 'private' then 'skip'     when visibility = 'public' and (dnssec_config_state is null or dnssec_config_state = 'off') then 'alarm'     else 'ok'   end as status,   case     when visibility = 'private'       then title || ' is private.'     when visibility = 'public' and (dnssec_config_state is null or dnssec_config_state = 'off')       then title || ' DNSSEC not enabled.'     else title || ' DNSSEC enabled.'   end as reason      , project as project from   gcp_dns_managed_zone;"
  documentation = file("./cis_v400/docs/cis_v400_3_3.md")

  tags = merge(local.cis_v400_3_common_tags, {
    cis_item_id = "3.3"
    cis_level   = "1"
    cis_type    = "automated"
    service     = "GCP/DNS"
  })
}

control "cis_v400_3_4" {
  title         = "3.4 Ensure That RSASHA1 Is Not Used for the Key-Signing Key in Cloud DNS DNSSEC"
  description   = "DNSSEC algorithm numbers in this registry may be used in CERT RRs. Zone signing (DNSSEC) and transaction security mechanisms (SIG(0) and TSIG) make use of particular subsets of these algorithms. The algorithm used for key signing should be a recommended one and it should be strong."
  query         = query.dns_managed_zone_key_signing_not_using_rsasha1

  query_source  = "select   self_link resource,   case     when visibility = 'private' then 'skip'     when dnssec_config_state is null then 'alarm'     when dnssec_config_default_key_specs @> '[{\"keyType\": \"keySigning\", \"algorithm\": \"rsasha1\"}]' then 'alarm'     else 'ok'   end as status,   case     when visibility = 'private'       then title || ' is private.'     when dnssec_config_state is null       then title || ' DNSSEC not enabled.'     when dnssec_config_default_key_specs @> '[{\"keyType\": \"keySigning\", \"algorithm\": \"rsasha1\"}]'       then title || ' using RSASHA1 algorithm for key-signing.'     else title || ' not using RSASHA1 algorithm for key-signing.'   end as reason      , project as project from   gcp_dns_managed_zone;"
  documentation = file("./cis_v400/docs/cis_v400_3_4.md")

  tags = merge(local.cis_v400_3_common_tags, {
    cis_item_id = "3.4"
    cis_level   = "1"
    cis_type    = "automated"
    service     = "GCP/DNS"
  })
}

control "cis_v400_3_5" {
  title         = "3.5 Ensure That RSASHA1 Is Not Used for the Zone-Signing Key in Cloud DNS DNSSEC"
  description   = "DNSSEC algorithm numbers in this registry may be used in CERT RRs. Zone signing (DNSSEC) and transaction security mechanisms (SIG(0) and TSIG) make use of particular subsets of these algorithms. The algorithm used for key signing should be a recommended one and it should be strong."
  query         = query.dns_managed_zone_zone_signing_not_using_rsasha1

  query_source  = "select   self_link resource,   case     when visibility = 'private' then 'skip'     when dnssec_config_state is null then 'alarm'     when dnssec_config_default_key_specs @> '[{\"keyType\": \"zoneSigning\", \"algorithm\": \"rsasha1\"}]' then 'alarm'     else 'ok'   end as status,   case     when visibility = 'private'       then title || ' is private.'     when dnssec_config_state is null       then title || ' DNSSEC not enabled.'     when dnssec_config_default_key_specs @> '[{\"keyType\": \"zoneSigning\", \"algorithm\": \"rsasha1\"}]'       then title || ' using RSASHA1 algorithm for zone-signing.'     else title || ' not using RSASHA1 algorithm for zone-signing.'   end as reason      , project as project from   gcp_dns_managed_zone;"
  documentation = file("./cis_v400/docs/cis_v400_3_5.md")

  tags = merge(local.cis_v400_3_common_tags, {
    cis_item_id = "3.5"
    cis_level   = "1"
    cis_type    = "automated"
    service     = "GCP/DNS"
  })
}

control "cis_v400_3_6" {
  title         = "3.6 Ensure That SSH Access Is Restricted From the Internet"
  description   = "GCP `Firewall Rules` are specific to a `VPC Network`. Each rule either allows or denies traffic when its conditions are met. Its conditions allow the user to specify the type of traffic, such as ports and protocols, and the source or destination of the traffic, including IP addresses, subnets, and instances."
  query         = query.compute_firewall_rule_ssh_access_restricted

  query_source  = "with ip_protocol_all as ( select   name from   gcp_compute_firewall where   direction = 'INGRESS'   and action = 'Allow'   and source_ranges ?& array['0.0.0.0/0']   and (allowed @> '[{\"IPProtocol\":\"all\"}]' or allowed::text like '%!{\"IPProtocol\": \"tcp\"}%') ), ip_protocol_tcp as (   select     name   from     gcp_compute_firewall,     jsonb_array_elements(allowed) as p,     jsonb_array_elements_text(p -> 'ports') as port   where     direction = 'INGRESS'     and action = 'Allow'     and source_ranges ?& array['0.0.0.0/0']     and p ->> 'IPProtocol' = 'tcp'     and (       port = '22'       or (         port like '%-%'         and split_part(port, '-', 1) :: integer <= 22         and split_part(port, '-', 2) :: integer >= 22       )     ) ) select   self_link resource,   case     when name in (select name from ip_protocol_tcp) then 'alarm'     when name in (select name from ip_protocol_all) then 'alarm'     else 'ok'   end as status,   case     when name in (select name from ip_protocol_tcp) or name in (select name from ip_protocol_all)       then title || ' allows SSH access from internet.'     else title || ' restricts SSH access from internet.'   end as reason   , location as location, project as project from   gcp_compute_firewall;"
  documentation = file("./cis_v400/docs/cis_v400_3_6.md")

  tags = merge(local.cis_v400_3_common_tags, {
    cis_item_id = "3.6"
    cis_level   = "2"
    cis_type    = "automated"
    service     = "GCP/Compute"
  })
}

control "cis_v400_3_7" {
  title         = "3.7 Ensure That RDP Access Is Restricted From the Internet"
  description   = "GCP `Firewall Rules` are specific to a `VPC Network`. Each rule either allows or denies traffic when its conditions are met. Its conditions allow users to specify the type of traffic, such as ports and protocols, and the source or destination of the traffic, including IP addresses, subnets, and instances."
  query         = query.compute_firewall_rule_rdp_access_restricted

  query_source  = "with ip_protocol_all as (   select     name   from     gcp_compute_firewall   where     direction = 'INGRESS'     and action = 'Allow'     and source_ranges ?& array['0.0.0.0/0']     and (allowed @> '[{\"IPProtocol\":\"all\"}]' or allowed::text like '%!{\"IPProtocol\": \"tcp\"}%') ), ip_protocol_tcp as (   select     name   from     gcp_compute_firewall,     jsonb_array_elements(allowed) as p,     jsonb_array_elements_text(p -> 'ports') as port   where     direction = 'INGRESS'     and action = 'Allow'     and source_ranges ?& array['0.0.0.0/0']     and p ->> 'IPProtocol' = 'tcp'     and (       port = '3389'       or (         port like '%-%'         and split_part(port, '-', 1) :: integer <= 3389         and split_part(port, '-', 2) :: integer >= 3389       )     ) ) select   self_link resource,   case     when name in (select name from ip_protocol_tcp) then 'alarm'     when name in (select name from ip_protocol_all) then 'alarm'     else 'ok'   end as status,   case     when name in (select name from ip_protocol_tcp) or name in (select name from ip_protocol_all)       then title || ' allows RDP access from internet.'     else title || ' restricts RDP access from internet.'   end as reason   , location as location, project as project from   gcp_compute_firewall;"
  documentation = file("./cis_v400/docs/cis_v400_3_7.md")

  tags = merge(local.cis_v400_3_common_tags, {
    cis_item_id = "3.7"
    cis_level   = "2"
    cis_type    = "automated"
    service     = "GCP/Compute"
  })
}

control "cis_v400_3_8" {
  title         = "3.8 Ensure that VPC Flow Logs is Enabled for Every Subnet in a VPC Network"
  description   = "Flow Logs is a feature that enables users to capture information about the IP traffic going to and from network interfaces in the organization's VPC Subnets. Once a flow log is created, the user can view and retrieve its data in Stackdriver Logging. It is recommended that Flow Logs be enabled for every business-critical VPC subnet."
  query         = query.compute_subnetwork_flow_log_enabled

  query_source  = "select   self_link resource,   case     when enable_flow_logs then 'ok'     else 'alarm'   end as status,   case     when enable_flow_logs       then title || ' flow logging enabled.'     else title || ' flow logging disabled.'   end as reason   , location as location, project as project from   gcp_compute_subnetwork;"
  documentation = file("./cis_v400/docs/cis_v400_3_8.md")

  tags = merge(local.cis_v400_3_common_tags, {
    cis_item_id = "3.8"
    cis_level   = "2"
    cis_type    = "automated"
    service     = "GCP/Compute"
  })
}

control "cis_v400_3_9" {
  title         = "3.9 Ensure No HTTPS or SSL Proxy Load Balancers Permit SSL Policies With Weak Cipher Suites"
  description   = "Secure Sockets Layer (SSL) policies determine what port Transport Layer Security (TLS) features clients are permitted to use when connecting to load balancers."
  query         = query.compute_ssl_policy_with_no_weak_cipher

  query_source  = "with all_proxies as (   select     name,     _ctx,     self_link,     split_part(kind, '#', 2) proxy_type,     ssl_policy,     title,     location,     project   from     gcp_compute_target_ssl_proxy   union   select     name,     _ctx,     self_link,     split_part(kind, '#', 2) proxy_type,     ssl_policy,     title,     location,     project   from     gcp_compute_target_https_proxy ), ssl_policy_without_weak_cipher as (   select     self_link   from     gcp_compute_ssl_policy   where     (profile = 'MODERN' and min_tls_version = 'TLS_1_2')     or profile = 'RESTRICTED'     or (profile = 'CUSTOM' and not (enabled_features ?| array['TLS_RSA_WITH_AES_128_GCM_SHA256', 'TLS_RSA_WITH_AES_256_GCM_SHA384', 'TLS_RSA_WITH_AES_128_CBC_SHA', 'TLS_RSA_WITH_AES_256_CBC_SHA', 'TLS_RSA_WITH_3DES_EDE_CBC_SHA'])) ) select   self_link resource,   case     when ssl_policy is null or ssl_policy in (select self_link from ssl_policy_without_weak_cipher) then 'ok'     else 'alarm'   end as status,   case     when ssl_policy is null       then proxy_type || ' ' || title || ' has no SSL policy.'     when ssl_policy is null or ssl_policy in (select self_link from ssl_policy_without_weak_cipher)       then proxy_type || ' ' || title || ' SSL policy contains CIS compliant cipher.'     else proxy_type || ' ' || title || ' SSL policy contains weak cipher.'   end as reason   , project as project from all_proxies;"
  documentation = file("./cis_v400/docs/cis_v400_3_9.md")

  tags = merge(local.cis_v400_3_common_tags, {
    cis_item_id = "3.9"
    cis_level   = "1"
    cis_type    = "manual"
    service     = "GCP/Compute"
  })
}

control "cis_v400_3_10" {
  title         = "3.10 Use Identity Aware Proxy (IAP) to Ensure Only Traffic From Google IP Addresses are 'Allowed'"
  description   = "IAP authenticates the user requests to your apps via a Google single sign in. You can then manage these users with permissions to control access. It is recommended to use both IAP permissions and firewalls to restrict this access to your apps with sensitive information."
  query         = query.compute_firewall_allow_tcp_connections_proxied_by_iap

  query_source  = "select   self_link resource,   case     when       ( allowed @> '[{\"IPProtocol\":\"tcp\",\"ports\":[\"80\",\"443\",\"22\",\"3389\"]}]'         or allowed @> '[{\"IPProtocol\":\"tcp\",\"ports\":[\"80\",\"443\",\"22\"]}]'         or allowed @> '[{\"IPProtocol\":\"tcp\",\"ports\":[\"80\",\"443\",\"3389\"]}]'         or allowed @> '[{\"IPProtocol\":\"tcp\",\"ports\":[\"80\",\"22\",\"3389\"]}]'         or allowed @> '[{\"IPProtocol\":\"tcp\",\"ports\":[\"3389\",\"443\",\"22\"]}]'         or allowed @> '[{\"IPProtocol\":\"tcp\",\"ports\":[\"80\",\"443\"]}]'         or allowed @> '[{\"IPProtocol\":\"tcp\",\"ports\":[\"80\",\"22\"]}]'         or allowed @> '[{\"IPProtocol\":\"tcp\",\"ports\":[\"80\",\"3389\"]}]'         or allowed @> '[{\"IPProtocol\":\"tcp\",\"ports\":[\"22\",\"443\"]}]'         or allowed @> '[{\"IPProtocol\":\"tcp\",\"ports\":[\"3389\",\"443\"]}]'         or allowed @> '[{\"IPProtocol\":\"tcp\",\"ports\":[\"22\",\"3389\"]}]'         or allowed @> '[{\"IPProtocol\":\"tcp\",\"ports\":[\"443\"]}]'         or allowed @> '[{\"IPProtocol\":\"tcp\",\"ports\":[\"22\"]}]'         or allowed @> '[{\"IPProtocol\":\"tcp\",\"ports\":[\"80\"]}]'         or allowed @> '[{\"IPProtocol\":\"tcp\",\"ports\":[\"3389\"]}]'       )       and (source_ranges ?& array['130.211.0.0/22']         or source_ranges ?& array['35.235.240.0/20']         or source_ranges ?& array['35.191.0.0/16']         or source_ranges ?& array['35.191.0.0/16', '130.211.0.0/22']         or source_ranges ?& array['35.191.0.0/16', '35.235.240.0/20']         or source_ranges ?& array['130.211.0.0/22', '35.235.240.0/20']         or source_ranges ?& array['130.211.0.0/22', '35.235.240.0/20', '35.191.0.0/16'])       then 'ok'     else 'alarm'   end as status,   case     when       ( allowed @> '[{\"IPProtocol\":\"tcp\",\"ports\":[\"80\",\"443\",\"22\",\"3389\"]}]'         or allowed @> '[{\"IPProtocol\":\"tcp\",\"ports\":[\"80\",\"443\",\"22\"]}]'         or allowed @> '[{\"IPProtocol\":\"tcp\",\"ports\":[\"80\",\"443\",\"3389\"]}]'         or allowed @> '[{\"IPProtocol\":\"tcp\",\"ports\":[\"80\",\"22\",\"3389\"]}]'         or allowed @> '[{\"IPProtocol\":\"tcp\",\"ports\":[\"3389\",\"443\",\"22\"]}]'         or allowed @> '[{\"IPProtocol\":\"tcp\",\"ports\":[\"80\",\"443\"]}]'         or allowed @> '[{\"IPProtocol\":\"tcp\",\"ports\":[\"80\",\"22\"]}]'         or allowed @> '[{\"IPProtocol\":\"tcp\",\"ports\":[\"80\",\"3389\"]}]'         or allowed @> '[{\"IPProtocol\":\"tcp\",\"ports\":[\"22\",\"443\"]}]'         or allowed @> '[{\"IPProtocol\":\"tcp\",\"ports\":[\"3389\",\"443\"]}]'         or allowed @> '[{\"IPProtocol\":\"tcp\",\"ports\":[\"22\",\"3389\"]}]'         or allowed @> '[{\"IPProtocol\":\"tcp\",\"ports\":[\"443\"]}]'         or allowed @> '[{\"IPProtocol\":\"tcp\",\"ports\":[\"22\"]}]'         or allowed @> '[{\"IPProtocol\":\"tcp\",\"ports\":[\"80\"]}]'         or allowed @> '[{\"IPProtocol\":\"tcp\",\"ports\":[\"3389\"]}]'       )       and (source_ranges ?& array['130.211.0.0/22']         or source_ranges ?& array['35.235.240.0/20']         or source_ranges ?& array['35.191.0.0/16']         or source_ranges ?& array['35.191.0.0/16', '130.211.0.0/22']         or source_ranges ?& array['35.191.0.0/16', '35.235.240.0/20']         or source_ranges ?& array['130.211.0.0/22', '35.235.240.0/20']         or source_ranges ?& array['130.211.0.0/22', '35.235.240.0/20', '35.191.0.0/16'])       then title || ' IAP configured to allow traffic from Google IP addresses.'     else title || ' IAP not configured to allow traffic from Google IP addresses.'   end as reason   , location as location, project as project from   gcp_compute_firewall;"
  documentation = file("./cis_v400/docs/cis_v400_3_10.md")

  tags = merge(local.cis_v400_3_common_tags, {
    cis_item_id = "3.10"
    cis_level   = "2"
    cis_type    = "manual"
    service     = "GCP/Compute"
  })
}
