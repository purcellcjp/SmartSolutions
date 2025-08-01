USE DBShrpn
GO

-- Header table
DELETE FROM dbo.code_policy
WHERE (code_tbl_id = '50001')
GO

-- Detail
DELETE FROM dbo.code_entry_policy
WHERE (code_tbl_id = '50001')
GO


INSERT INTO dbo.code_policy
(
  code_tbl_id
, short_descp
, code_tbl_type_code
, chgstamp
)
VALUES
(
  '50001'
, 'HCM Employee Type Mapping'
, 'EMP'
, 0
)
GO


INSERT INTO dbo.code_entry_policy
(
  code_tbl_id
, code_value
, language_code
, short_descp
, chgstamp
)
VALUES
  ('50001','APPR','EN','APPRENTICE',0)
, ('50001','ASSOC','EN','ASSOCIATE',0)
, ('50001','CONTR','EN','CONTRACT',0)
, ('50001','EMP','EN','EMPLOYEE',0)
, ('50001','ESTPB','EN','EST/PUBLIC',0)
, ('50001','INT','EN','INTERN',0)
, ('50001','LEGIS','EN','LEGISLATIVE',0)
, ('50001','NESTM','EN','NON-ESTAB(WAGES)',0)
, ('50001','NESTW','EN','NON-ESTAB(FORT)',0)
, ('50001','OTHER','EN','OTHER',0)
, ('50001','PEN','EN','PENSIONER',0)
, ('50001','PERMN','EN','PERMNON-PEN',0)
, ('50001','PERMP','EN','PERMPENSIONABLE',0)
, ('50001','PJCTC','EN','PROJECT',0)
, ('50001','PROB','EN','PROBATION',0)
, ('50001','RECRU','EN','RECRUIT',0)
, ('50001','SEAS','EN','SEASONAL',0)
, ('50001','TEMP','EN','TEMPORARY',0)
, ('50001','VOLUN','EN','VOLUNTEER',0)
GO


SELECT *
FROM dbo.code_entry_policy
WHERE (code_tbl_id = '50001')
GO
