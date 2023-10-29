--SQL Server Audit
select top 10 * from sys.dm_audit_actions (nolock)
select top 10 * from sys.dm_audit_class_type_map (nolock)

--broker
select top 10 * from sys.dm_broker_activated_tasks (nolock)
select top 10 * from sys.dm_broker_connections (nolock)
select top 10 * from sys.dm_broker_forwarded_messages (nolock)
select top 10 * from sys.dm_broker_queue_monitors (nolock)

--change data capture
select top 10 * from sys.dm_cdc_errors (nolock)
select top 10 * from sys.dm_cdc_log_scan_sessions (nolock)

--clr
select top 10 * from sys.dm_clr_appdomains (nolock)
select top 10 * from sys.dm_clr_loaded_assemblies (nolock)
select top 10 * from sys.dm_clr_properties (nolock)
select top 10 * from sys.dm_clr_tasks (nolock)

--cryptographic
select top 10 * from sys.dm_cryptographic_provider_properties (nolock)
--dm_cryptographic_provider_algorithms
--dm_cryptographic_provider_keys
--dm_cryptographic_provider_sessions

--database
select top 10 * from sys.dm_database_encryption_keys (nolock)
select top 10 * from sys.dm_db_file_space_usage (nolock)
select top 10 * from sys.dm_db_fts_index_physical_stats (nolock)
select top 10 * from sys.dm_db_index_usage_stats (nolock)
select top 10 * from sys.dm_db_log_space_usage (nolock)
select top 10 * from sys.dm_db_mirroring_auto_page_repair (nolock)
select top 10 * from sys.dm_db_mirroring_connections (nolock)
select top 10 * from sys.dm_db_mirroring_past_actions (nolock)
select top 10 * from sys.dm_db_missing_index_details (nolock)
select top 10 * from sys.dm_db_missing_index_group_stats (nolock)
select top 10 * from sys.dm_db_missing_index_groups (nolock)
select top 10 * from sys.dm_db_partition_stats (nolock)
select top 10 * from sys.dm_db_persisted_sku_features (nolock)
select top 10 * from sys.dm_db_script_level (nolock)
select top 10 * from sys.dm_db_session_space_usage (nolock)
select top 10 * from sys.dm_db_task_space_usage (nolock)
select top 10 * from sys.dm_db_uncontained_entities (nolock)
--dm_db_database_page_allocations
--dm_db_index_operational_stats
--dm_db_index_physical_stats
--dm_db_missing_index_columns
--dm_db_objects_disabled_on_compatibility_level_change

--transactions
select top 10 * from sys.dm_exec_background_job_queue (nolock)
select top 10 * from sys.dm_exec_background_job_queue_stats (nolock)
select top 10 * from sys.dm_exec_cached_plans (nolock)
select top 10 * from sys.dm_exec_connections (nolock)
select top 10 * from sys.dm_exec_procedure_stats (nolock)
select top 10 * from sys.dm_exec_query_memory_grants (nolock)
select top 10 * from sys.dm_exec_query_optimizer_info (nolock)
select top 10 * from sys.dm_exec_query_resource_semaphores (nolock)
select top 10 * from sys.dm_exec_query_stats (nolock)
select top 10 * from sys.dm_exec_query_transformation_stats (nolock)
select top 10 * from sys.dm_exec_requests (nolock)
select top 10 * from sys.dm_exec_sessions (nolock)
select top 10 * from sys.dm_exec_trigger_stats (nolock)
--dm_exec_cached_plan_dependent_objects
--dm_exec_cursors
--dm_exec_describe_first_result_set
--dm_exec_describe_first_result_set_for_object
--dm_exec_plan_attributes
--dm_exec_query_plan
--dm_exec_sql_text
--dm_exec_text_query_plan
--dm_exec_xml_handles

--
select top 10 * from sys.dm_filestream_file_io_handles (nolock)
select top 10 * from sys.dm_filestream_file_io_requests (nolock)
select top 10 * from sys.dm_filestream_non_transacted_handles (nolock)

--full text search
select top 10 * from sys.dm_fts_active_catalogs (nolock)
select top 10 * from sys.dm_fts_fdhosts (nolock)
select top 10 * from sys.dm_fts_index_population (nolock)
select top 10 * from sys.dm_fts_memory_buffers (nolock)
select top 10 * from sys.dm_fts_memory_pools (nolock)
select top 10 * from sys.dm_fts_outstanding_batches (nolock)
select top 10 * from sys.dm_fts_population_ranges (nolock)
select top 10 * from sys.dm_fts_semantic_similarity_population (nolock)
--dm_fts_index_keywords
--dm_fts_index_keywords_by_document
--dm_fts_index_keywords_by_property
--dm_fts_parser

--hadr
select top 10 * from sys.dm_hadr_auto_page_repair (nolock)
select top 10 * from sys.dm_hadr_availability_group_states (nolock)
select top 10 * from sys.dm_hadr_availability_replica_cluster_nodes (nolock)
select top 10 * from sys.dm_hadr_availability_replica_cluster_states (nolock)
select top 10 * from sys.dm_hadr_availability_replica_states (nolock)
select top 10 * from sys.dm_hadr_cluster (nolock)
select top 10 * from sys.dm_hadr_cluster_members (nolock)
select top 10 * from sys.dm_hadr_cluster_networks (nolock)
select top 10 * from sys.dm_hadr_database_replica_cluster_states (nolock)
select top 10 * from sys.dm_hadr_database_replica_states (nolock)
select top 10 * from sys.dm_hadr_instance_node_map (nolock)
select top 10 * from sys.dm_hadr_name_id_map (nolock)

--io
select top 10 * from sys.dm_io_backup_tapes (nolock)
select top 10 * from sys.dm_io_cluster_shared_drives (nolock)
select top 10 * from sys.dm_io_pending_io_requests (nolock)
--dm_io_virtual_file_stats

--
--dm_logconsumer_cachebufferrefs
--dm_logconsumer_privatecachebuffers

--
select top 10 * from sys.dm_logpool_hashentries (nolock)
select top 10 * from sys.dm_logpool_stats (nolock)
--dm_logpool_consumers
--dm_logpool_sharedcachebuffers
--dm_logpoolmgr_freepools
--dm_logpoolmgr_respoolsize
--dm_logpoolmgr_stats

--os
select top 10 * from sys.dm_os_buffer_descriptors (nolock)
select top 10 * from sys.dm_os_child_instances (nolock)
select top 10 * from sys.dm_os_cluster_nodes (nolock)
select top 10 * from sys.dm_os_cluster_properties (nolock)
select top 10 * from sys.dm_os_dispatcher_pools (nolock)
select top 10 * from sys.dm_os_dispatchers (nolock)
select top 10 * from sys.dm_os_hosts (nolock)
select top 10 * from sys.dm_os_latch_stats (nolock)
select top 10 * from sys.dm_os_loaded_modules (nolock)
select top 10 * from sys.dm_os_memory_allocations (nolock)
select top 10 * from sys.dm_os_memory_broker_clerks (nolock)
select top 10 * from sys.dm_os_memory_brokers (nolock)
select top 10 * from sys.dm_os_memory_cache_clock_hands (nolock)
select top 10 * from sys.dm_os_memory_cache_counters (nolock)
select top 10 * from sys.dm_os_memory_cache_entries (nolock)
select top 10 * from sys.dm_os_memory_cache_hash_tables (nolock)
select top 10 * from sys.dm_os_memory_clerks (nolock)
select top 10 * from sys.dm_os_memory_node_access_stats (nolock)
select top 10 * from sys.dm_os_memory_nodes (nolock)
select top 10 * from sys.dm_os_memory_objects (nolock)
select top 10 * from sys.dm_os_memory_pools (nolock)
select top 10 * from sys.dm_os_nodes (nolock)
select top 10 * from sys.dm_os_performance_counters (nolock)
select top 10 * from sys.dm_os_process_memory (nolock)
select top 10 * from sys.dm_os_ring_buffers (nolock)
select top 10 * from sys.dm_os_schedulers (nolock)
select top 10 * from sys.dm_os_server_diagnostics_log_configurations (nolock)
select top 10 * from sys.dm_os_spinlock_stats (nolock)
select top 10 * from sys.dm_os_stacks (nolock)
select top 10 * from sys.dm_os_sublatches (nolock)
select top 10 * from sys.dm_os_sys_info (nolock)
select top 10 * from sys.dm_os_sys_memory (nolock)
select top 10 * from sys.dm_os_tasks (nolock)
select top 10 * from sys.dm_os_threads (nolock)
select top 10 * from sys.dm_os_virtual_address_dump (nolock)
select top 10 * from sys.dm_os_wait_stats (nolock)
select top 10 * from sys.dm_os_waiting_tasks (nolock)
select top 10 * from sys.dm_os_windows_info (nolock)
select top 10 * from sys.dm_os_worker_local_storage (nolock)
select top 10 * from sys.dm_os_workers (nolock)
--dm_os_volume_stats

--replication
select top 10 * from sys.dm_qn_subscriptions (nolock)
select top 10 * from sys.dm_repl_articles (nolock)
select top 10 * from sys.dm_repl_schemas (nolock)
select top 10 * from sys.dm_repl_tranhash (nolock)
select top 10 * from sys.dm_repl_traninfo (nolock)

--resource governor
select top 10 * from sys.dm_resource_governor_configuration (nolock)
select top 10 * from sys.dm_resource_governor_resource_pool_affinity (nolock)
select top 10 * from sys.dm_resource_governor_resource_pools (nolock)
select top 10 * from sys.dm_resource_governor_workload_groups (nolock)

--server
select top 10 * from sys.dm_server_audit_status (nolock)
select top 10 * from sys.dm_server_memory_dumps (nolock)
select top 10 * from sys.dm_server_registry (nolock)
select top 10 * from sys.dm_server_services (nolock)

--
--dm_sql_referenced_entities
--dm_sql_referencing_entities

--
select top 10 * from sys.dm_tcp_listener_states (nolock)

--transactions
select top 10 * from sys.dm_tran_active_snapshot_database_transactions (nolock)
select top 10 * from sys.dm_tran_active_transactions (nolock)
select top 10 * from sys.dm_tran_commit_table (nolock)
select top 10 * from sys.dm_tran_current_snapshot (nolock)
select top 10 * from sys.dm_tran_current_transaction (nolock)
select top 10 * from sys.dm_tran_database_transactions (nolock)
select top 10 * from sys.dm_tran_locks (nolock)
select top 10 * from sys.dm_tran_session_transactions (nolock)
select top 10 * from sys.dm_tran_top_version_generators (nolock)
select top 10 * from sys.dm_tran_transactions_snapshot (nolock)
select top 10 * from sys.dm_tran_version_store (nolock)

--extended events
select top 10 * from sys.dm_xe_map_values (nolock)
select top 10 * from sys.dm_xe_object_columns (nolock)
select top 10 * from sys.dm_xe_objects (nolock)
select top 10 * from sys.dm_xe_packages (nolock)
select top 10 * from sys.dm_xe_session_event_actions (nolock)
select top 10 * from sys.dm_xe_session_events (nolock)
select top 10 * from sys.dm_xe_session_object_columns (nolock)
select top 10 * from sys.dm_xe_session_targets (nolock)
select top 10 * from sys.dm_xe_sessions (nolock)
