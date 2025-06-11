USE [DBShrpn]
GO
/****** Object:  StoredProcedure [dbo].[usp_bank_cleanup_tbl]    Script Date: 4/1/2025 4:33:00 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE procedure [dbo].[usp_bank_cleanup_tbl]

(@USER_ID      char(30) = NULL)

AS
BEGIN

DELETE [DBShrpn].[dbo].[ghr_bankinfo_events]

END

Grant Execute ON usp_bank_cleanup_tbl TO Public

 
GO
ALTER AUTHORIZATION ON [dbo].[usp_bank_cleanup_tbl] TO  SCHEMA OWNER 
GO
