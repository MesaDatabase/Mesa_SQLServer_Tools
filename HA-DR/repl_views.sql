--subscribers
select
  @@SERVERNAME as Distributor,
  t2.data_source as PubServer,
  t1.publisher_db, 
  t3.data_source as SubServer,
  t1.subscriber_db,
  case when t1.status = 0 then 'Inactive'
	   when t1.status = 1 then 'Subscribed'
	   when t1.status = 2 then 'Active' end as Status
--select *
from distribution..MSsubscriptions as t1
  join sys.servers as t2 on t1.publisher_id = t2.server_id
  join sys.servers as t3 on t1.subscriber_id = t3.server_id
where t1.subscription_type = 0 
--  and t1.status = 2
  and subscriber_id > 0
group by
  t2.data_source,
  t1.publisher_db, 
  t3.data_source,
  t1.subscriber_db,
  case when t1.status = 0 then 'Inactive'
	   when t1.status = 1 then 'Subscribed'
	   when t1.status = 2 then 'Active' end
order by 1,2,3,4

--publications
select
  @@SERVERNAME as Distributor,
  t2.data_source as PubServer,
  t1.publisher_db, 
  t1.publication
from distribution.dbo.MSpublications as t1
  join sys.servers as t2 on t1.publisher_id = t2.server_id

--subscriptions
select distinct
  @@SERVERNAME as Distributor,
  t2.data_source as PubServer,
  t1.publisher_db, 
  t5.publication,
  t3.data_source as SubServer,
  t1.subscriber_db,
  case when t1.status = 0 then 'Inactive'
	   when t1.status = 1 then 'Subscribed'
	   when t1.status = 2 then 'Active' end as Status
--select *
from distribution..MSsubscriptions as t1
  join sys.servers as t2 on t1.publisher_id = t2.server_id
  join sys.servers as t3 on t1.subscriber_id = t3.server_id
  join distribution..MSpublications as t5 on t1.publication_id = t5.publication_id
  join distribution..MSarticles as t4 on t1.publisher_id = t4.publisher_id and t1.publication_id = t4.publication_id and t1.article_id = t4.article_id
where t1.subscription_type = 0
  and subscriber_id > 0
order by 1,2,3,4,5

--articles
select distinct
  @@SERVERNAME as Distributor,
  t2.data_source as PubServer,
  t1.publisher_db, 
  t5.publication,
  t3.data_source as SubServer,
  t1.subscriber_db,
  t4.article,
  case when t1.status = 0 then 'Inactive'
	   when t1.status = 1 then 'Subscribed'
	   when t1.status = 2 then 'Active' end as Status
--select *
from distribution..MSsubscriptions as t1
  join sys.servers as t2 on t1.publisher_id = t2.server_id
  join sys.servers as t3 on t1.subscriber_id = t3.server_id
  join distribution..MSpublications as t5 on t1.publication_id = t5.publication_id
  join distribution..MSarticles as t4 on t1.publisher_id = t4.publisher_id and t1.publication_id = t4.publication_id and t1.article_id = t4.article_id
where t1.subscription_type = 0 
--  and t1.status = 2
  and subscriber_id > 0
order by 1,2,3,4,5

--snapshot agents  
select 
  @@SERVERNAME as Distributor,
  name as JobName
from distribution.dbo.MSsnapshot_agents

--distribution agents
select 
  @@SERVERNAME as Distributor,
  name as JobName,
  subscriber_db
from distribution.dbo.MSdistribution_agents 
where local_job = 1

--log reader agents
select 
  @@SERVERNAME as Distributor,
  name as JobName   
from distribution.dbo.MSlogreader_agents

--queue reader agents
select 
  @@SERVERNAME as Distributor,
  name as JobName
from distribution.dbo.MSqreader_agents

--permissions
select 
  @@SERVERNAME as Distributor,
  t3.data_source as PubServer,
  t2.publication,
  t1.login
from distribution.dbo.MSpublication_access as t1
  join distribution.dbo.MSpublications as t2 on t1.publication_id = t2.publication_id
  join sys.servers as t3 on t2.publisher_id = t3.server_id

--view job history for snapshot agents
select 
  @@SERVERNAME as Distributor,
  t2.name as JobName,
  t1.start_time,
  t1.runstatus,
  t1.comments,
  t1.delivered_transactions
from distribution.dbo.MSsnapshot_history as t1
  join distribution.dbo.MSsnapshot_agents as t2 on t1.agent_id = t2.id
order by 1,2,3
  
--view job history for distribution agents
select 
  @@SERVERNAME as Distributor,
  t2.name as JobName,
  t1.start_time,
  t1.runstatus,
  t1.comments,
  t1.delivered_transactions
from distribution.dbo.MSdistribution_history as t1
  join distribution.dbo.MSdistribution_agents as t2 on t1.agent_id = t2.id

--view job history for log reader agents
select 
  @@SERVERNAME as Distributor,
  t2.name as JobName,
  t1.start_time,
  t1.runstatus,
  t1.comments,
  t1.delivered_transactions
from distribution.dbo.MSlogreader_history as t1
  join distribution.dbo.MSlogreader_agents as t2 on t1.agent_id = t2.id

--view job history for queue reader agents
select 
  @@SERVERNAME as Distributor,
  t2.name as JobName,
  t1.start_time,
  t1.runstatus,
  t1.comments
from distribution.dbo.MSqreader_history as t1
  join distribution.dbo.MSqreader_agents as t2 on t1.agent_id = t2.id
