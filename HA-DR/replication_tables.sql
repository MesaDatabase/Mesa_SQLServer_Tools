
--Replication Tables in the master Database
MSreplication_options
 

--Replication Tables in the msdb Database
MSagentparameterlist 
MSdbms_map 
MSdbms 
MSreplmonthresholdmetrics 
MSdbms_datatype 
sysreplicationalerts 
MSdbms_datatype_mapping 

select * from sys.servers
where is_publisher = 1

select * from sys.remote_logins

--Replication Tables in the Distribution Database
select * from MSagent_parameters 
select * from MSpublicationthresholds 
select * from MSagent_profiles 
select * from MSpublisher_databases 
select * from MSarticles 
select * from MSreplication_objects 
select * from MScached_peer_lsns 
select * from MSreplication_subscriptions 
select * from MSrepl_commands 
select * from MSdistribution_agents 
select * from MSrepl_errors 
select * from MSdistribution_history 
select * from MSrepl_originators 
select * from MSdistributiondbs 
select * from MSrepl_transactions 
select * from MSrepl_version 
select * from MSlogreader_agents 
select * from MSsnapshot_agents 
select * from MSlogreader_history 
select * from MSsnapshot_history 
select * from MSmerge_agents 
select * from MSsubscriber_info 
select * from MSmerge_history 
select * from MSsubscriber_schedule 
select * from MSmerge_sessions 
select * from MSsubscriptions 
select * from MSmerge_subscriptions 
select * from MSsubscription_properties 
select * from MSpublication_access 
select * from MStracer_history 
select * from MSpublications 
select * from MStracer_tokens 
dbo.MSdistribution_status
dbo.sysarticlecolumns
dbo.sysarticles
dbo.sysextendedarticlesview
dbo.syspublications
dbo.syssubscriptions
sys.dm_repl_articles
sys.dm_repl_schemas
sys.dm_repl_tranhash
sys.dm_repl_traninfo
sys.dm_tran_active_snapshot_database_transactions
sys.dm_tran_active_transactions
sys.dm_tran_active_transactions
sys.dm_tran_current_snapshot
sys.dm_tran_current_transaction
sys.dm_tran_database_transactions
sys.dm_tran_locks
sys.dm_tran_session_transactions
sys.dm_tran_top_version_generators
sys.dm_tran_transactions_snapshot
sys.dm_tran_version_store




  
 
--Replication Tables in the Publication Database
conflict_<schema>_<table> 
MSpeer_originatorid_history 
MSdynamicsnapshotjobs 
MSpeer_topologyrequest 
MSdynamicsnapshotviews 
MSpeer_topologyresponse 
MSmerge_altsyncpartners 
MSpeer_request 
MSmerge_conflicts_info 
MSpeer_response 
MSmerge_contents 
MSpub_identity_range 
MSmerge_current_partition_mappings 
sysarticlecolumns 
MSmerge_dynamic_snapshots 
sysarticles 
MSmerge_errorlineage 
sysarticleupdates 
MSmerge_generation_partition_mappings 
sysmergearticlecolumns 
MSmerge_genhistory 
sysmergearticles 
MSmerge_identity_range 
sysmergepartitioninfo 
MSmerge_metadataaction_request 
sysmergepublications 
MSmerge_partition_groups 
sysmergeschemaarticles 
MSmerge_past_partition_mappings 
sysmergeschemachange 
MSmerge_replinfo 
sysmergesubscriptions 
MSmerge_settingshistory 
sysmergesubsetfilters 
MSmerge_tombstone 
syspublications 
MSpeer_conflictdetectionconfigrequest 
sysschemaarticles 
MSpeer_conflictdetectionconfigresponse 
syssubscriptions 
MSpeer_lsns 
systranschemas 


--Replication Tables in the Subscription Database
MSdynamicsnapshotjobs 
MSmerge_settingshistory 
MSdynamicsnapshotviews 
MSmerge_tombstone 
MSmerge_altsyncpartners 
MSpeer_lsns
MSmerge_conflicts_info 
MSrepl_queuedtraninfo 
MSmerge_contents 
MSsnapshotdeliveryprogress 
MSmerge_current_partition_mappings 
MSsubscription_properties 
MSmerge_dynamic_snapshots 
sysmergearticlecolumns 
MSmerge_errorlineage 
sysmergearticles 
MSmerge_generation_partition_mappings 
sysmergepartitioninfo 
MSmerge_genhistory 
sysmergepublications 
MSmerge_identity_range 
sysmergeschemaarticles 
MSmerge_metadataaction_request 
sysmergeschemachange 
MSmerge_partition_groups 
sysmergesubscriptions 
MSmerge_past_partition_mappings 
sysmergesubsetfilters 
MSmerge_replinfo 
systranschemas 


