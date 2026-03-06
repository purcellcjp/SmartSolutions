SELECT @@SERVERNAME as servername
GO

SELECT DISTINCT activity_date
FROM DBShrpn.dbo.ghr_historical_message
ORDER BY activity_date DESC
GO


EXEC DBShrpn.dbo.usp_verification_rpt_csv
			--  @p_activity_date = '2026-02-27 18:47:44.817'
			--, @p_emp_id        = '82000'
GO
