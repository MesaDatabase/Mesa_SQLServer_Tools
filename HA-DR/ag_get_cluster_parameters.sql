select 
  ag.name,
  agl.dns_name,
  ag.name + '_' + agl.dns_name,
  'Get-ClusterResource ' + ag.name + '_' + agl.dns_name + ' | Get-ClusterParameter RegisterAllProvidersIP'
from sys.availability_groups as ag
  join sys.availability_group_listeners as agl on ag.group_id = agl.group_id