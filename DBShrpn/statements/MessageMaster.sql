USE DBSCOMMON
GO

-- Create U00100 Message Master template for New 
INSERT INTO dbo.message_master
VALUES
(
  'U00100'		-- msg_id
, 1				-- severity_cd
, 0				-- user_def
, 'WARNING: Invalid Employment Type code, @1, for employee @2'			-- msg_text
, ''			-- msg_text_2
, ''			-- msg_text_3
, 0				-- help_context
, ''			-- help_file_id
, 0				-- pscm_flag
, 0				-- CHGSTAMP
)
GO

-- Return all message templates
SELECT *
FROM dbo.message_master
WHERE (msg_id LIKE 'U%')
GO
