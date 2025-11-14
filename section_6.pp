locals {
  cis_v400_6_common_tags = merge(local.cis_v400_common_tags, {
    cis_section_id = "6"
  })
}

locals {
  cis_v400_6_1_common_tags = merge(local.cis_v400_6_common_tags, {
    cis_section_id = "6.1"
  })
}

locals {
  cis_v400_6_2_common_tags = merge(local.cis_v400_6_common_tags, {
    cis_section_id = "6.2"
  })
}

locals {
  cis_v400_6_3_common_tags = merge(local.cis_v400_6_common_tags, {
    cis_section_id = "6.3"
  })
}

benchmark "cis_v400_6" {
  title         = "6 Cloud SQL Database Services"
  documentation = file("./cis_v400/docs/cis_v400_6.md")
  children = [
    benchmark.cis_v400_6_1,
    benchmark.cis_v400_6_2,
    benchmark.cis_v400_6_3,
    control.cis_v400_6_4,
    control.cis_v400_6_5,
    control.cis_v400_6_6,
    control.cis_v400_6_7
  ]

  tags = merge(local.cis_v400_6_common_tags, {
    type    = "Benchmark"
    service = "GCP/SQL"
  })
}

benchmark "cis_v400_6_1" {
  title         = "6.1 MySQL Database"
  documentation = file("./cis_v400/docs/cis_v400_6_1.md")
  children = [
    control.cis_v400_6_1_1,
    control.cis_v400_6_1_2,
    control.cis_v400_6_1_3
  ]

  tags = merge(local.cis_v400_6_1_common_tags, {
    type    = "Benchmark"
    service = "GCP/SQL"
  })
}

control "cis_v400_6_1_1" {
  title         = "6.1.1 Ensure That a MySQL Database Instance Does Not Allow Anyone To Connect With Administrative Privileges"
  description   = "It is recommended to set a password for the administrative user (root by default) to prevent unauthorized access to the SQL database instances. This recommendation is applicable only for MySQL Instances. PostgreSQL does not offer any setting for No Password from the cloud console."
  documentation = file("./cis_v400/docs/cis_v400_6_1_1.md")
  query         = query.manual_control

  query_source  = "select   'https://cloudresourcemanager.googleapis.com/v1/projects/' || project_id resource,   'info' status,   'Manual verification required.' reason   , project_id as project from   gcp_project;"

  tags = merge(local.cis_v400_6_1_common_tags, {
    cis_item_id = "6.1.1"
    cis_level   = "1"
    cis_type    = "manual"
    service     = "GCP/SQL"
  })
}

control "cis_v400_6_1_2" {
  title         = "6.1.2 Ensure 'Skip_show_database' Database Flag for Cloud SQL MySQL Instance Is Set to 'On'"
  description   = "It is recommended to set `skip_show_database` database flag for Cloud SQL Mysql instance to `on`."
  documentation = file("./cis_v400/docs/cis_v400_6_1_2.md")
  query         = query.sql_instance_mysql_skip_show_database_flag_on

  query_source  = "select   self_link resource,   case     when database_version not like 'MYSQL%' then 'skip'     when database_flags @> '[{\"name\":\"skip_show_database\",\"value\":\"on\"}]' then 'ok'     else 'alarm'   end as status,   case     when database_version not like 'MYSQL%'       then title || ' not a MySQL database.'     when database_flags is null or not (database_flags @> '[{\"name\":\"skip_show_database\"}]')       then title || ' ''skip_show_database'' database flag not set.'     when database_flags @> '[{\"name\":\"skip_show_database\",\"value\":\"on\"}]'       then title || ' ''skip_show_database'' database flag set to ''on''.'     else title || ' ''skip_show_database'' database flag set to ''off''.'   end as reason          , location as location, project as project from   gcp_sql_database_instance;"

  tags = merge(local.cis_v400_6_1_common_tags, {
    cis_item_id = "6.1.2"
    cis_level   = "1"
    cis_type    = "automated"
    service     = "GCP/SQL"
  })
}

control "cis_v400_6_1_3" {
  title         = "6.1.3 Ensure That the 'Local_infile' Database Flag for a Cloud SQL MySQL Instance Is Set to 'Off'"
  description   = "It is recommended to set the `local_infile` database flag for a Cloud SQL MySQL instance to `off`."
  documentation = file("./cis_v400/docs/cis_v400_6_1_3.md")
  query         = query.sql_instance_mysql_local_infile_database_flag_off

  query_source  = "select   self_link resource,   case     when database_version not like 'MYSQL%' then 'skip'     when database_flags @> '[{\"name\":\"local_infile\",\"value\":\"off\"}]' then 'ok'     else 'alarm'   end as status,   case     when database_version not like 'MYSQL%'       then title || ' not a MySQL database.'     when database_flags is null or not (database_flags @> '[{\"name\":\"local_infile\"}]')       then title || ' ''local_infile'' database flag not set.'     when database_flags @> '[{\"name\":\"local_infile\",\"value\":\"off\"}]'       then title || ' ''local_infile'' database flag set to ''off''.'     else title || ' ''local_infile'' database flag set to ''on''.'   end as reason          , location as location, project as project from   gcp_sql_database_instance;"

  tags = merge(local.cis_v400_6_1_common_tags, {
    cis_item_id = "6.1.3"
    cis_level   = "1"
    cis_type    = "automated"
    service     = "GCP/SQL"
  })
}

benchmark "cis_v400_6_2" {
  title         = "6.2 PostgreSQL Database"
  documentation = file("./cis_v400/docs/cis_v400_6_2.md")
  children = [
    control.cis_v400_6_2_1,
    control.cis_v400_6_2_2,
    control.cis_v400_6_2_3,
    control.cis_v400_6_2_4,
    control.cis_v400_6_2_5,
    control.cis_v400_6_2_6,
    control.cis_v400_6_2_7,
    control.cis_v400_6_2_8
  ]

  tags = merge(local.cis_v400_6_2_common_tags, {
    type    = "Benchmark"
    service = "GCP/SQL"
  })
}

control "cis_v400_6_2_1" {
  title         = "6.2.1 Ensure 'Log_error_verbosity' Database Flag for Cloud SQL PostgreSQL Instance Is Set to 'DEFAULT' or Stricter"
  description   = "The `log_error_verbosity` flag controls the verbosity/details of messages logged. Valid values are: 'TERSE', 'DEFAULT', and 'VERBOSE'."
  documentation = file("./cis_v400/docs/cis_v400_6_2_1.md")
  query         = query.sql_instance_postgresql_log_error_verbosity_database_flag_default_or_stricter

  query_source  = "select   self_link as resource,   case     when database_version not like 'POSTGRES%' then 'skip'     when database_flags @> '[{\"name\": \"log_error_verbosity\",\"value\":\"default\"}]' or database_flags @> '[{\"name\": \"log_error_verbosity\",\"value\":\"verbose\"}]' then 'ok'     else 'alarm'   end as status,   case     when database_version not like 'POSTGRES%' then title || ' not a PostgreSQL database.'     when database_flags @> '[{\"name\": \"log_error_verbosity\",\"value\":\"default\"}]' then title || ' log_error_verbosity database flag set to DEFAULT.'     when database_flags @> '[{\"name\": \"log_error_verbosity\",\"value\":\"verbose\"}]' then title || ' log_error_verbosity database flag set to VERBOSE.'     when database_flags @> '[{\"name\": \"log_error_verbosity\",\"value\":\"terse\"}]' then title || ' log_error_verbosity database flag set to TERSE.'     else title || ' log_error_verbosity database flag not set.'   end as reason      , location as location, project as project from   gcp_sql_database_instance;"

  tags = merge(local.cis_v400_6_2_common_tags, {
    cis_item_id = "6.2.1"
    cis_level   = "2"
    cis_type    = "automated"
    service     = "GCP/SQL"
  })
}

control "cis_v400_6_2_2" {
  title         = "6.2.2 Ensure That the 'Log_connections' Database Flag for Cloud SQL PostgreSQL Instance Is Set to 'On'"
  description   = "Enabling the `log_connections` setting causes each attempted connection to the server to be logged, along with successful completion of client authentication. This parameter cannot be changed after the session starts."
  documentation = file("./cis_v400/docs/cis_v400_6_2_2.md")
  query         = query.sql_instance_postgresql_log_connections_database_flag_on

  query_source  = "select   self_link resource,   case     when database_version not like 'POSTGRES%' then 'skip'     when database_flags @> '[{\"name\":\"log_connections\",\"value\":\"on\"}]' then 'ok'     else 'alarm'   end as status,   case     when database_version not like 'POSTGRES%'       then title || ' not a PostgreSQL database.'     when database_flags is null or not (database_flags @> '[{\"name\":\"log_connections\"}]')       then title || ' ''log_connections'' database flag not set.'     when database_flags @> '[{\"name\":\"log_connections\",\"value\":\"on\"}]'       then title || ' ''log_connections'' database flag set to ''on''.'     else title || ' ''log_connections'' database flag set to ''off''.'   end as reason          , location as location, project as project from   gcp_sql_database_instance;"

  tags = merge(local.cis_v400_6_2_common_tags, {
    cis_item_id = "6.2.2"
    cis_level   = "1"
    cis_type    = "automated"
    service     = "GCP/SQL"
  })
}

control "cis_v400_6_2_3" {
  title         = "6.2.3 Ensure That the 'Log_disconnections' Database Flag for Cloud SQL PostgreSQL Instance Is Set to 'On'"
  description   = "Enabling the `log_disconnections` setting logs the end of each session, including the session duration."
  documentation = file("./cis_v400/docs/cis_v400_6_2_3.md")
  query         = query.sql_instance_postgresql_log_disconnections_database_flag_on

  query_source  = "select   self_link resource,   case     when database_version not like 'POSTGRES%' then 'skip'     when database_flags @> '[{\"name\":\"log_disconnections\",\"value\":\"on\"}]' then 'ok'     else 'alarm'   end as status,   case     when database_version not like 'POSTGRES%'       then title || ' not a PostgreSQL database.'     when database_flags is null or not (database_flags @> '[{\"name\":\"log_disconnections\"}]')       then title || ' ''log_disconnections'' database flag not set.'     when database_flags @> '[{\"name\":\"log_disconnections\",\"value\":\"on\"}]'       then title || ' ''log_disconnections'' database flag set to ''on''.'     else title || ' ''log_disconnections'' database flag set to ''off''.'   end as reason      , location as location, project as project from   gcp_sql_database_instance;"

  tags = merge(local.cis_v400_6_2_common_tags, {
    cis_item_id = "6.2.3"
    cis_level   = "1"
    cis_type    = "automated"
    service     = "GCP/SQL"
  })
}

control "cis_v400_6_2_4" {
  title         = "6.2.4 Ensure 'Log_statement' Database Flag for Cloud SQL PostgreSQL Instance Is Set Appropriately"
  description   = "The value of `log_statement` flag determined the SQL statements that are logged. Valid values are: 'none', 'ddl', 'mod', and 'all'."
  documentation = file("./cis_v400/docs/cis_v400_6_2_4.md")
  query         = query.sql_instance_postgresql_log_statement_database_flag_ddl

  query_source  = "select   self_link as resource,   case     when database_version not like 'POSTGRES%' then 'skip'     when database_flags is null or not (database_flags @> '[{\"name\":\"log_statement\"}]') then 'alarm'     when database_flags @> '[{\"name\": \"log_statement\",\"value\":\"ddl\"}]' then 'ok'     else 'alarm'   end as status,   case     when database_version not like 'POSTGRES%' then title || ' not a PostgreSQL database.'     when database_flags is null or not (database_flags @> '[{\"name\":\"log_statement\"}]') then title || ' log_statement database flag not set.'     when database_flags @> '[{\"name\": \"log_statement\",\"value\":\"ddl\"}]' then title || ' log_statement database flag set to ddl.'     when database_flags @> '[{\"name\": \"log_statement\",\"value\":\"mod\"}]' then title || ' log_statement database flag set to mod.'     when database_flags @> '[{\"name\": \"log_statement\",\"value\":\"all\"}]' then title || ' log_statement database flag set to all.'     when database_flags @> '[{\"name\": \"log_statement\",\"value\":\"none\"}]' then title || ' log_statement database flag set to none.'   end as reason      , location as location, project as project from   gcp_sql_database_instance;"
  tags = merge(local.cis_v400_6_2_common_tags, {
    cis_item_id = "6.2.4"
    cis_level   = "2"
    cis_type    = "automated"
    service     = "GCP/SQL"
  })
}

control "cis_v400_6_2_5" {
  title         = "6.2.5 Ensure that the 'Log_min_messages' Flag for a Cloud SQL PostgreSQL Instance is set at minimum to 'Warning'"
  description   = "The `log_min_messages` flag defines the minimum message severity level that is considered as an error statement. Messages for error statements are logged with the SQL statement. Valid values include DEBUG5, DEBUG4, DEBUG3, DEBUG2, DEBUG1, INFO, NOTICE, WARNING, ERROR, LOG, FATAL, and PANIC. Each severity level includes the subsequent levels mentioned above. ERROR is considered the best practice setting. Changes should only be made in accordance with the organization's logging policy."
  documentation = file("./cis_v400/docs/cis_v400_6_2_5.md")
  query         = query.sql_instance_postgresql_log_min_messages_database_flag_error

  query_source  = "select   self_link as resource,   case     when database_version not like 'POSTGRES%' then 'skip'     when database_flags is null or not (database_flags @> '[{\"name\":\"log_min_messages\"}]') then 'alarm'     when database_flags @> '[{\"name\":\"log_min_messages\",\"value\":\"error\"}]' or database_flags @> '[{\"name\":\"log_min_messages\",\"value\":\"warning\"}]' then 'ok'     else 'alarm'   end as status,   case     when database_version not like 'POSTGRES%' then title || ' not a PostgreSQL database.'     when database_flags is null or not (database_flags @> '[{\"name\":\"log_min_messages\"}]') then title || ' log_min_messages database flag not set.'     when database_flags @> '[{\"name\":\"log_min_messages\",\"value\":\"error\"}]' then title || ' log_min_messages database flag set to ERROR.'     when database_flags @> '[{\"name\":\"log_min_messages\",\"value\":\"warning\"}]' then title || ' log_min_messages database flag set to WARNING.'     else title || ' log_min_messages database flag not set at minimum to WARNING.'   end as reason      , location as location, project as project from   gcp_sql_database_instance;"
  tags = merge(local.cis_v400_6_2_common_tags, {
    cis_item_id = "6.2.5"
    cis_level   = "1"
    cis_type    = "automated"
  })
}

control "cis_v400_6_2_6" {
  title         = "6.2.6 Ensure 'Log_min_error_statement' Database Flag for Cloud SQL PostgreSQL Instance Is Set to 'Error' or Stricter"
  description   = "The `log_min_error_statement` flag defines the minimum message severity level that are considered as an error statement."
  documentation = file("./cis_v400/docs/cis_v400_6_2_6.md")
  query         = query.sql_instance_postgresql_log_min_error_statement_database_flag_configured

  query_source  = "select   self_link resource,   case     when database_version not like 'POSTGRES%' then 'skip'     when database_flags @> '[{\"name\":\"log_min_error_statement\"}]' then 'ok'     else 'alarm'   end as status,   case     when database_version not like 'POSTGRES%'       then title || ' not a PostgreSQL database.'     when database_flags @> '[{\"name\":\"log_min_error_statement\"}]'       then title || ' ''log_min_error_statement'' database flag set.'     else title || ' ''log_min_error_statement'' database flag not set.'   end as reason      , location as location, project as project from   gcp_sql_database_instance;"

  tags = merge(local.cis_v400_6_2_common_tags, {
    cis_item_id = "6.2.6"
    cis_level   = "1"
    cis_type    = "automated"
  })
}

control "cis_v400_6_2_7" {
  title         = "6.2.7 Ensure That the 'Log_min_duration_statement' Database Flag for Cloud SQL PostgreSQL Instance Is Set to '-1' (Disabled)"
  description   = "The `log_min_duration_statement` flag defines the minimum amount of execution time of a statement in milliseconds where the total duration of the statement is logged. Ensure that log_min_duration_statement is disabled, i.e., a value of -1 is set."
  documentation = file("./cis_v400/docs/cis_v400_6_2_7.md")
  query         = query.sql_instance_postgresql_log_min_duration_statement_database_flag_disabled

  query_source  = "select   self_link resource,   case     when database_version not like 'POSTGRES%' then 'skip'     when database_flags @> '[{\"name\":\"log_min_duration_statement\",\"value\":\"-1\"}]' then 'ok'     else 'alarm'   end as status,   case     when database_version not like 'POSTGRES%'       then title || ' not a PostgreSQL database.'     when database_flags is null or not (database_flags @> '[{\"name\":\"log_min_duration_statement\"}]')       then title || ' ''log_min_duration_statement'' database flag not set.'     when database_flags @> '[{\"name\":\"log_min_duration_statement\",\"value\":\"-1\"}]'       then title || ' ''log_min_duration_statement'' database flag disabled.'     else title || ' ''log_min_duration_statement'' database flag enabled.'   end as reason      , location as location, project as project from   gcp_sql_database_instance;"

  tags = merge(local.cis_v400_6_2_common_tags, {
    cis_item_id = "6.2.7"
    cis_level   = "1"
    cis_type    = "automated"
  })
}

control "cis_v400_6_2_8" {
  title         = "6.2.8 Ensure That 'cloudsql.enable_pgaudit' Database Flag for each Cloud Sql Postgresql Instance Is Set to 'on' For Centralized Logging"
  description   = "Ensure cloudsql.enable_pgaudit database flag for Cloud SQL PostgreSQL instance is set to on to allow for centralized logging."
  documentation = file("./cis_v400/docs/cis_v400_6_2_8.md")
  query         = query.sql_instance_postgresql_cloudsql_pgaudit_database_flag_enabled

  query_source  = "select   self_link resource,   case     when database_version not like 'POSTGRES%' then 'skip'     when database_flags @> '[{\"name\":\"cloudsql.enable_pgaudit\",\"value\":\"on\"}]' then 'ok'     else 'alarm'   end as status,   case     when database_version not like 'POSTGRES%'       then title || ' not a PostgreSQL database.'     when database_flags is null or not (database_flags @> '[{\"name\":\"cloudsql.enable_pgaudit\"}]')       then title || ' ''cloudsql.enable_pgaudit'' database flag not set.'     when database_flags @> '[{\"name\":\"cloudsql.enable_pgaudit\",\"value\":\"on\"}]'       then title || ' ''cloudsql.enable_pgaudit'' database flag enabled.'     else title || ' ''cloudsql.enable_pgaudit'' database flag disabled.'   end as reason          , location as location, project as project from   gcp_sql_database_instance;"

  tags = merge(local.cis_v400_6_2_common_tags, {
    cis_item_id = "6.2.8"
    cis_level   = "1"
    cis_type    = "automated"
  })
}

benchmark "cis_v400_6_3" {
  title         = "6.3 SQL Server"
  documentation = file("./cis_v400/docs/cis_v400_6_3.md")
  children = [
    control.cis_v400_6_3_1,
    control.cis_v400_6_3_2,
    control.cis_v400_6_3_3,
    control.cis_v400_6_3_4,
    control.cis_v400_6_3_5,
    control.cis_v400_6_3_6,
    control.cis_v400_6_3_7
  ]

  tags = merge(local.cis_v400_6_3_common_tags, {
    type    = "Benchmark"
    service = "GCP/SQL"
  })
}

control "cis_v400_6_3_1" {
  title         = "6.3.1 Ensure 'external scripts enabled' Database Flag for Cloud SQL SQL Server Instance Is Set to 'off'"
  description   = "It is recommended to set `external scripts enabled` database flag for Cloud SQL SQL Server instance to `off`."
  documentation = file("./cis_v400/docs/cis_v400_6_3_1.md")
  query         = query.sql_instance_sql_external_scripts_enabled_database_flag_off

  query_source  = "select   self_link resource,   case     when database_version not like 'SQLSERVER%' then 'skip'     when database_flags @> '[{\"name\":\"external scripts enabled\",\"value\":\"off\"}]' then 'ok'     else 'alarm'   end as status,   case     when database_version not like 'SQLSERVER%'       then title || ' not a SQL Server database.'     when database_flags is null or not (database_flags @> '[{\"name\":\"external scripts enabled\"}]')       then title || ' ''external scripts enabled'' not set.'     when database_flags @> '[{\"name\":\"external scripts enabled\",\"value\":\"off\"}]'       then title || ' ''external scripts enabled'' database flag set to ''off''.'     else title || ' ''external scripts enabled'' database flag set to ''on''.'   end as reason      , location as location, project as project from   gcp_sql_database_instance;"

  tags = merge(local.cis_v400_6_3_common_tags, {
    cis_item_id = "6.3.1"
    cis_level   = "1"
    cis_type    = "automated"
  })
}

control "cis_v400_6_3_2" {
  title         = "6.3.2 Ensure 'cross db ownership chaining' Database Flag for Cloud SQL SQL Server Instance Is Set to 'off'"
  description   = "It is recommended to set `cross db ownership chaining` database flag for Cloud SQL SQL Server instance to `off`."
  documentation = file("./cis_v400/docs/cis_v400_6_3_2.md")
  query         = query.sql_instance_sql_cross_db_ownership_chaining_database_flag_off

  query_source  = "select   self_link resource,   case     when database_version not like 'SQLSERVER%' then 'skip'     when database_flags @> '[{\"name\":\"cross db ownership chaining\",\"value\":\"off\"}]' then 'ok'     else 'alarm'   end as status,   case     when database_version not like 'SQLSERVER%'       then title || ' not a SQL Server database.'     when database_flags is null or not (database_flags @> '[{\"name\":\"cross db ownership chaining\"}]')       then title || ' ''cross db ownership chaining'' not set.'     when database_flags @> '[{\"name\":\"cross db ownership chaining\",\"value\":\"off\"}]'       then title || ' ''cross db ownership chaining'' database flag set to ''off''.'     else title || ' ''cross db ownership chaining'' database flag set to ''on''.'   end as reason      , location as location, project as project from   gcp_sql_database_instance;"

  tags = merge(local.cis_v400_6_3_common_tags, {
    cis_item_id = "6.3.2"
    cis_level   = "1"
    cis_type    = "automated"
  })
}

control "cis_v400_6_3_3" {
  title         = "6.3.3 Ensure 'user Connections' Database Flag for Cloud SQL SQL Server Instance Is Set to a Non-limiting Value"
  description   = "It is recommended to check the `user connections` for a Cloud SQL SQL Server instance to ensure that it is not artificially limiting connections."
  documentation = file("./cis_v400/docs/cis_v400_6_3_3.md")
  query         = query.sql_instance_sql_user_connections_database_flag_configured

  query_source  = "select   self_link resource,   case     when database_version not like 'SQLSERVER%' then 'skip'     when database_flags @> '[{\"name\":\"user connections\"}]' then 'ok'     else 'alarm'   end as status,   case     when database_version not like 'SQLSERVER%'       then title || ' not a SQL Server database.'     when database_flags @> '[{\"name\":\"user connections\"}]'       then title || ' ''user connections'' database flag set.'     else title || ' ''user connections'' database flag not set.'   end as reason      , location as location, project as project from   gcp_sql_database_instance;"

  tags = merge(local.cis_v400_6_3_common_tags, {
    cis_item_id = "6.3.3"
    cis_level   = "1"
    cis_type    = "automated"
  })
}

control "cis_v400_6_3_4" {
  title         = "6.3.4 Ensure 'user options' Database Flag for Cloud SQL SQL Server Instance Is Not Configured"
  description   = "The `user options` option specifies global defaults for all users. A list of default query processing options is established for the duration of a user's work session. The user options option allows you to change the default values of the SET options (if the server's default settings are not appropriate)."
  documentation = file("./cis_v400/docs/cis_v400_6_3_4.md")
  query         = query.sql_instance_sql_user_options_database_flag_not_configured

  query_source  = "select   self_link resource,   case     when database_version not like 'SQLSERVER%' then 'skip'     when database_flags @> '[{\"name\":\"user options\"}]' then 'alarm'     else 'ok'   end as status,   case     when database_version not like 'SQLSERVER%'       then title || ' not a SQL Server database.'     when database_flags @> '[{\"name\":\"user options\"}]'       then title || ' ''user options'' database flag set.'     else title || ' ''user options'' database flag not set.'   end as reason      , location as location, project as project from   gcp_sql_database_instance;"

  tags = merge(local.cis_v400_6_3_common_tags, {
    cis_item_id = "6.3.4"
    cis_level   = "1"
    cis_type    = "automated"
  })
}

control "cis_v400_6_3_5" {
  title         = "6.3.5 Ensure 'remote access' Database Flag for Cloud SQL SQL Server Instance Is Set to 'off'"
  description   = "It is recommended to set `remote access` database flag for Cloud SQL SQL Server instance to `off`."
  documentation = file("./cis_v400/docs/cis_v400_6_3_5.md")
  query         = query.sql_instance_sql_remote_access_database_flag_off

  query_source  = "select   self_link resource,   case     when database_version not like 'SQLSERVER%' then 'skip'     when database_flags @> '[{\"name\":\"remote access\",\"value\":\"off\"}]' then 'ok'     else 'alarm'   end as status,   case     when database_version not like 'SQLSERVER%'       then title || ' not a SQL Server database.'     when database_flags is null or not (database_flags @> '[{\"name\":\"remote access\"}]')       then title || ' ''remote access'' not set.'     when database_flags @> '[{\"name\":\"remote access\",\"value\":\"off\"}]'       then title || ' ''remote access'' database flag set to ''off''.'     else title || ' ''remote access'' database flag set to ''on''.'   end as reason      , location as location, project as project from   gcp_sql_database_instance;"

  tags = merge(local.cis_v400_6_3_common_tags, {
    cis_item_id = "6.3.5"
    cis_level   = "1"
    cis_type    = "automated"
  })
}

control "cis_v400_6_3_6" {
  title         = "6.3.6 Ensure '3625 (trace flag)' Database Flag for all Cloud SQL SQL Server Instances Is Set to 'on'"
  description   = "It is recommended to set `3625 (trace flag)` database flag for Cloud SQL SQL Server instance to `on`."
  documentation = file("./cis_v400/docs/cis_v400_6_3_6.md")
  query         = query.sql_instance_sql_3625_trace_database_flag_on

  query_source  = "select   self_link as resource,   case     when database_version not like 'SQLSERVER%' then 'skip'     when database_flags @> '[{\"name\":\"3625\",\"value\":\"on\"}]' then 'ok'     else 'alarm'   end as status,   case     when database_version not like 'SQLSERVER%' then title || ' not a SQL Server database.'     when database_flags is null or not (database_flags @> '[{\"name\":\"3625\"}]') then title || ' ''3625 (trace flag)'' not set.'     when database_flags @> '[{\"name\":\"3625\",\"value\":\"on\"}]' then title || ' ''3625 (trace flag)'' database flag set to ''on''.'     else title || ' ''3625 (trace flag)'' database flag set to ''off''.'   end as reason      , location as location, project as project from   gcp_sql_database_instance;"

  tags = merge(local.cis_v400_6_3_common_tags, {
    cis_item_id = "6.3.6"
    cis_level   = "1"
    cis_type    = "automated"
  })
}

control "cis_v400_6_3_7" {
  title         = "6.3.7 Ensure 'contained database authentication' Database Flag for Cloud SQL SQL Server Instance Is Set to 'off'"
  description   = "A contained database includes all database settings and metadata required to define the database and has no configuration dependencies on the instance of the Database Engine where the database is installed. Users can connect to the database without authenticating a login at the Database Engine level. Isolating the database from the Database Engine makes it possible to easily move the database to another instance of SQL Server. Contained databases have some unique threats that should be understood and mitigated by SQL Server Database Engine administrators. Most of the threats are related to the USER WITH PASSWORD authentication process, which moves the authentication boundary from the Database Engine level to the database level, hence this is recommended not to enable this flag. This recommendation is applicable to SQL Server database instances."
  documentation = file("./cis_v400/docs/cis_v400_6_3_7.md")
  query         = query.sql_instance_sql_contained_database_authentication_database_flag_off

  query_source  = "select   self_link resource,   case     when database_version not like 'SQLSERVER%' then 'skip'     when database_flags @> '[{\"name\":\"contained database authentication\",\"value\":\"off\"}]' then 'ok'     else 'alarm'   end as status,   case     when database_version not like 'SQLSERVER%'       then title || ' not a SQL Server database.'     when database_flags is null or not (database_flags @> '[{\"name\":\"contained database authentication\"}]')       then title || ' ''contained database authentication'' not set.'     when database_flags @> '[{\"name\":\"contained database authentication\",\"value\":\"off\"}]'       then title || ' ''contained database authentication'' database flag set to ''off''.'     else title || ' ''contained database authentication'' database flag set to ''on''.'   end as reason      , location as location, project as project from   gcp_sql_database_instance;"

  tags = merge(local.cis_v400_6_3_common_tags, {
    cis_item_id = "6.3.7"
    cis_level   = "1"
    cis_type    = "automated"
  })
}

control "cis_v400_6_4" {
  title         = "6.4 Ensure That the Cloud SQL Database Instance Requires All Incoming Connections To Use SSL"
  description   = "It is recommended to enforce all incoming connections to SQL database instance to use SSL."
  documentation = file("./cis_v400/docs/cis_v400_6_4.md")
  query         = query.sql_instance_require_ssl_enabled

  query_source  = "select    self_link resource,   case     when ip_configuration ->> 'sslMode' = 'ENCRYPTED_ONLY' then 'ok'     else 'alarm'   end as status,   case     when ip_configuration ->> 'sslMode' = 'ENCRYPTED_ONLY'       then title || ' enforces SSL connections.'     else title || ' does not enforce SSL connections.'   end as reason      , location as location, project as project from   gcp_sql_database_instance;"

  tags = merge(local.cis_v400_6_common_tags, {
    cis_item_id = "6.4"
    cis_level   = "1"
    cis_type    = "automated"
  })
}

control "cis_v400_6_5" {
  title         = "6.5 Ensure That Cloud SQL Database Instances Do Not Implicitly Whitelist All Public IP Addresses"
  description   = "Database Server should accept connections only from trusted Network(s)/IP(s) and restrict access from public IP addresses."
  documentation = file("./cis_v400/docs/cis_v400_6_5.md")
  query         = query.sql_instance_not_open_to_internet

  query_source  = "select   self_link as resource,   case     when exists (       select 1       from jsonb_array_elements(ip_configuration -> 'authorizedNetworks') as authNet       where authNet ->> 'value' = '0.0.0.0/0' or authNet ->> 'value' = '::/0'     ) then 'alarm'     else 'ok'   end as status,   case     when exists (       select 1       from jsonb_array_elements(ip_configuration -> 'authorizedNetworks') as authNet       where authNet ->> 'value' = '0.0.0.0/0' or  authNet ->> 'value' = '::/0'     ) then title || ' is open to the internet.'     else title || ' is not open to the internet.'   end as reason      , location as location, project as project from   gcp_sql_database_instance;"

  tags = merge(local.cis_v400_6_common_tags, {
    cis_item_id = "6.5"
    cis_level   = "1"
    cis_type    = "automated"
  })
}

control "cis_v400_6_6" {
  title         = "6.6 Ensure That Cloud SQL Database Instances Do Not Have Public IPs"
  description   = "It is recommended to configure Second Generation Sql instance to use private IPs instead of public IPs."
  documentation = file("./cis_v400/docs/cis_v400_6_6.md")
  query         = query.sql_instance_with_no_public_ips

  query_source  = "select   self_link resource,   case     when ip_addresses @> '[{\"type\": \"PRIMARY\"}]' and backend_type = 'SECOND_GEN' then 'alarm'     else 'ok'   end as status,   case     when ip_addresses @> '[{\"type\": \"PRIMARY\"}]' and backend_type = 'SECOND_GEN'       then title || ' associated with public IPs.'     else title || ' not associated with public IPs.'   end as reason      , location as location, project as project from   gcp_sql_database_instance;"

  tags = merge(local.cis_v400_6_common_tags, {
    cis_item_id = "6.6"
    cis_level   = "2"
    cis_type    = "automated"
  })
}

control "cis_v400_6_7" {
  title         = "6.7 Ensure That Cloud SQL Database Instances Are Configured With Automated Backups"
  description   = "It is recommended to have all SQL database instances set to enable automated backups."
  documentation = file("./cis_v400/docs/cis_v400_6_7.md")
  query         = query.sql_instance_automated_backups_enabled

  query_source  = "select   self_link resource,   case     when backup_enabled then 'ok'     else 'alarm'   end as status,   case     when backup_enabled       then title || ' automatic backups configured.'     else title || ' automatic backups not configured.'   end as reason      , location as location, project as project from   gcp_sql_database_instance;"

  tags = merge(local.cis_v400_6_common_tags, {
    cis_item_id = "6.7"
    cis_level   = "1"
    cis_type    = "automated"
  })
}
