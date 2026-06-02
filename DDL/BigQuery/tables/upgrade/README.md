If you are upgrading from a previous instance of StriimWatcher data, the following table alterations add the new columns to our BQ Target database.

The following are may be new tables, please confirm they are missing before creating them:
- https://github.com/daniel-striim/StriimWatcher/blob/main/DDL/BigQuery/tables/striim_mon_checkpoint_history.sql
- https://github.com/daniel-striim/StriimWatcher/blob/main/DDL/BigQuery/tables/striim_mon_file_lineage.sql
- https://github.com/daniel-striim/StriimWatcher/blob/main/DDL/BigQuery/tables/striim_mon_ojet_metrics.sql
- https://github.com/daniel-striim/StriimWatcher/blob/main/DDL/BigQuery/tables/striim_mon_oracle_open_trx.sql
- https://github.com/daniel-striim/StriimWatcher/blob/main/DDL/BigQuery/tables/striim_mon_source_information.sql
- https://github.com/daniel-striim/StriimWatcher/blob/main/DDL/BigQuery/tables/striim_mon_system_configuration.sql
- https://github.com/daniel-striim/StriimWatcher/blob/main/DDL/BigQuery/tables/striim_mon_target_information.sql
- https://github.com/daniel-striim/StriimWatcher/blob/main/DDL/BigQuery/tables/striim_mon_tql_history.sql
