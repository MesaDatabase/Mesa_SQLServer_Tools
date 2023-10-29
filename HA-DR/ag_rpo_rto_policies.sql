Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'IsPrimaryReplica', @description=N'', @facet=N'AvailabilityGroup', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>EQ</OpType>
  <Count>2</Count>
  <Attribute>
    <TypeClass>Numeric</TypeClass>
    <Name>LocalReplicaRole</Name>
  </Attribute>
  <Function>
    <TypeClass>Numeric</TypeClass>
    <FunctionType>Enum</FunctionType>
    <ReturnType>Numeric</ReturnType>
    <Count>2</Count>
    <Constant>
      <TypeClass>String</TypeClass>
      <ObjType>System.String</ObjType>
      <Value>Microsoft.SqlServer.Management.Smo.AvailabilityReplicaRole</Value>
    </Constant>
    <Constant>
      <TypeClass>String</TypeClass>
      <ObjType>System.String</ObjType>
      <Value>Primary</Value>
    </Constant>
  </Function>
</Operator>', @is_name_condition=0, @obj_name=N'', @condition_id=@condition_id OUTPUT
Select @condition_id

GO


Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'RPO', @description=N'', @facet=N'DatabaseReplicaState', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>LE</OpType>
  <Count>2</Count>
  <Attribute>
    <TypeClass>Numeric</TypeClass>
    <Name>EstimatedDataLoss</Name>
  </Attribute>
  <Constant>
    <TypeClass>Numeric</TypeClass>
    <ObjType>System.Double</ObjType>
    <Value>3600</Value>
  </Constant>
</Operator>', @is_name_condition=0, @obj_name=N'', @condition_id=@condition_id OUTPUT
Select @condition_id

GO

Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'RTO', @description=N'', @facet=N'DatabaseReplicaState', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>LE</OpType>
  <Count>2</Count>
  <Function>
    <TypeClass>Numeric</TypeClass>
    <FunctionType>Add</FunctionType>
    <ReturnType>Numeric</ReturnType>
    <Count>2</Count>
    <Attribute>
      <TypeClass>Numeric</TypeClass>
      <Name>EstimatedRecoveryTime</Name>
    </Attribute>
    <Constant>
      <TypeClass>Numeric</TypeClass>
      <ObjType>System.Double</ObjType>
      <Value>60</Value>
    </Constant>
  </Function>
  <Constant>
    <TypeClass>Numeric</TypeClass>
    <ObjType>System.Double</ObjType>
    <Value>600</Value>
  </Constant>
</Operator>', @is_name_condition=0, @obj_name=N'', @condition_id=@condition_id OUTPUT
Select @condition_id

GO








Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'CustomAvailabilityDatabaseRPO_ObjectSet', @facet=N'DatabaseReplicaState', @object_set_id=@object_set_id OUTPUT
Select @object_set_id

Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'CustomAvailabilityDatabaseRPO_ObjectSet', @type_skeleton=N'Server/AvailabilityGroup/DatabaseReplicaState', @type=N'DATABASEREPLICASTATE', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id

EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/AvailabilityGroup/DatabaseReplicaState', @level_name=N'DatabaseReplicaState', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/AvailabilityGroup', @level_name=N'AvailabilityGroup', @condition_name=N'IsPrimaryReplica', @target_set_level_id=0


GO

Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'CustomAvailabilityDatabaseRPO', @condition_name=N'RPO', @policy_category=N'Availability database warnings', @description=N'The availability database has exceeded your RPO of 5 minutes. You should investigate performance issues on the availability replicas immediately.', @help_text=N'RPO Exceeded!', @help_link=N'', @schedule_uid=N'44149a24-c866-4aa9-987e-697232287444', @execution_mode=4, @is_enabled=True, @policy_id=@policy_id OUTPUT, @root_condition_name=N'', @object_set=N'CustomAvailabilityDatabaseRPO_ObjectSet'
Select @policy_id


GO


Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'CustomSecondaryDatabaseRTO_ObjectSet', @facet=N'DatabaseReplicaState', @object_set_id=@object_set_id OUTPUT
Select @object_set_id

Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'CustomSecondaryDatabaseRTO_ObjectSet', @type_skeleton=N'Server/AvailabilityGroup/DatabaseReplicaState', @type=N'DATABASEREPLICASTATE', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id

EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/AvailabilityGroup/DatabaseReplicaState', @level_name=N'DatabaseReplicaState', @condition_name=N'', @target_set_level_id=0
EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/AvailabilityGroup', @level_name=N'AvailabilityGroup', @condition_name=N'IsPrimaryReplica', @target_set_level_id=0


GO

Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'CustomSecondaryDatabaseRTO', @condition_name=N'RTO', @policy_category=N'Availability database warnings', @description=N'The current replica has an RTO that exceeds 10 minutes, assuming an overhead of 1 minute for discovery and failover. You should investigate performance issues on the respective server instance immediately.', @help_text=N'RTO Exceeded!', @help_link=N'', @schedule_uid=N'60b28a1c-a49e-43b3-b2e6-f42b30a04c44', @execution_mode=4, @is_enabled=True, @policy_id=@policy_id OUTPUT, @root_condition_name=N'', @object_set=N'CustomSecondaryDatabaseRTO_ObjectSet'
Select @policy_id


GO


