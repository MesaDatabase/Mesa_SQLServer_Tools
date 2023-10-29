select * from sys.dm_xe_map_values
select * from sys.dm_xe_object_columns
where name = 'connectivity_ring_buffer_recorded'

select * from sys.dm_xe_objects 
where object_type = 'event' 
  and name = 'connectivity_ring_buffer_recorded'
order by name

select * from sys.dm_xe_packages
select * from sys.dm_xe_session_event_actions
select * from sys.dm_xe_session_events
select * from sys.dm_xe_session_object_columns
select * from sys.dm_xe_session_targets
select * from sys.dm_xe_sessions
