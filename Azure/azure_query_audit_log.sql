
--specific file
SELECT top 100 * 
FROM sys.fn_get_audit_file ('https://devdblogstgblob.core.windows.net/sqldbauditlogs/npduseamdapsqlsrv/npduseamdapsqldbDW/SqlDbAuditing_Audit/2020-05-20/10_01_05_201_24.xel',default,default)
WHERE 1=1
  AND session_server_principal_name = 'AzureDFReadOnly'
  AND data_sensitivity_information <> ''

  --all files in folder
SELECT top 100 * 
FROM sys.fn_get_audit_file ('https://devdblogstgblob.blob.core.windows.net/sqldbauditlogs/npduseamdapsqlsrv/npduseamdapsqldbDW/SqlDbAuditing_Audit/2020-05-20',default,default)
WHERE 1=1
  AND session_server_principal_name = 'AzureDFReadOnly'
  AND data_sensitivity_information <> ''