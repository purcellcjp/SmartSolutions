USE [DBShrpn]
GO
/****** Object:  StoredProcedure [dbo].[usp_bank_verification_rpt]    Script Date: 4/1/2025 4:33:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[usp_bank_verification_rpt]
AS
 --   EXEC [DBShrpn].[dbo].[usp_bank_verification_rpt]
BEGIN
DECLARE	@cnt					int
DECLARE @max					int
DECLARE @event_id_01			char(02)
DECLARE @activity_status		char(02)
DECLARE	@emp_id					char(15)
DECLARE @eff_date				char(10)
DECLARE @rundate				datetime

SELECT @rundate = MAX(activity_date) FROM [DBShrpn].[dbo].[ghr_bankinfo_events_aud] 
--2024-04-23 15:29:33.000
--2024-04-24 00:00:00.000
--SELECT @rundate
--IF convert(char,@rundate,112) <> convert(char,DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE())),112)
--   SELECT @rundate = convert(char,DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE())),112)
--SELECT @rundate
--SELECT @rundate = DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))

-- '2023-04-21 03:02:10.000'
--	Report on Employees Successfully Loaded for pay element interface
--  SELECT * FROM [DBShrpn].[dbo].[ghr_bankinfo_events_aud] WHERE activity_date = '2024-04-23 15:29:33.000' 


SELECT 'HCM - SS Interface Bank Transaction Report' + char(10) + char(13)
SELECT CAST('<style>p {font: 12px Courier New;} table {font: 12px Courier New;}pre {margin-left: 20px;margin-right: 35px; padding:10px 10px 10px 15px;font: 12px Courier New;background-color:rgb(248,248,248);border:thin solid black;}</style><p style="font: bold 18px Courier New;color:blue;font-weight:bold;">GHR Bank Interface Information</p><br><table style="font: 13px Courier New;"><tr><td><b>Name</b></td><td>:</td><td>GHR</td></tr><tr><td><b>Qualifier</b></td><td>:</td><td>BANK INTERFACES</td></tr> <tr><td><b>User ID</b></td><td>:</td><td>DBS</td></tr><tr><td><b>Database</b></td><td>:</td><td>DBShrpn</td></tr><tr><td><b>Server</b></td><td>:</td><td>SQLSRV2</td></tr></table><p style="font: bold 13px Courier New;">The information in the following shaded area is the output from Interface Report.</p><br><pre>< REPORT INFORMATION >' AS CHAR(812)) + CHAR(10) + CHAR(13)
--SELECT CAST('<font face="Courier New" size="11px" color="#FF7A59">Your text here.</font>' AS CHAR(90)) 

		SELECT	SPACE(35) + 'HCM - SS Interface Bank Transaction Report'
		SELECT  SPACE(50) + 'All Entities'
		SELECT	'Run Date: ' + CONVERT(char,GETDATE(),120)	+ SPACE(10)
		SELECT	SPACE(50)
		
 
SET		@event_id_01	=	'07'
SET		@activity_status =  '00'


IF	EXISTS ( SELECT * 
            FROM [DBShrpn].[dbo].[ghr_bankinfo_events_aud] 
            WHERE event_id_01 = @event_id_01 
              AND activity_status = @activity_status 
              AND activity_date = @rundate
          )
	BEGIN		
		SELECT  SPACE(30)
		SELECT	'Bank Account Section:'
		SELECT	SPACE(30)

		SELECT	--CAST('<font face=''Courier New''>' AS CHAR(27)) +
--				CAST('Activity Description' AS CHAR(20))	+ CAST('' AS CHAR(6)) + 
				CAST('Employee' AS CHAR(12))				+ CAST('' AS CHAR(1)) +	
				CAST('Eff. Date' AS CHAR(10))				+ CAST('' AS CHAR(3)) +
				CAST('First Name' AS CHAR(15))				+ CAST('' AS CHAR(5)) +
				CAST('Last Name' AS CHAR(15))				+ CAST('' AS CHAR(5)) +
				CAST('Employer' AS CHAR(10))				+ CAST('' AS CHAR(1)) +
--				CAST('Bank Id ' AS CHAR(15)),	
--				CAST('Bank Account Number' AS CHAR(15)),
--				CAST('Bank Account Type' AS CHAR(15)),	
--				CAST('Organization Name' AS CHAR(15)),	
--				CAST('Organization Unit' AS CHAR(15)),	
				CAST('Bank Id ' AS CHAR(8))				     + CAST('' AS CHAR(3)) +	
				CAST('Bank Account Number' AS CHAR(20))		 + CAST('' AS CHAR(2)) +	
				CAST('Bank Account Type' AS CHAR(17))		 + CAST('' AS CHAR(3)) 
				--CAST('</font>' AS CHAR(07)) 

--		SELECT 'Successful Bank Account:'
	

		SELECT   
				---CAST('<font face=''Courier New''>' AS CHAR(27)) +
--				CAST(''										AS CHAR(17))	+ CAST('' AS CHAR(9)) + 
				CAST(RTRIM(emp_id_01)						AS CHAR(12))	+ CAST('' AS CHAR(1)) + 
				CAST(RTRIM(eff_date_01)						AS CHAR(10))	+ CAST('' AS CHAR(3)) + 
				CAST(RTRIM(first_name_01)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 
				CAST(RTRIM(last_name_01)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 
				CAST(RTRIM(empl_id_01)						AS CHAR(10))	+ CAST('' AS CHAR(1)) +  	
				CAST(RTRIM(bank_id_07)					    AS CHAR(07))	+ CAST('' AS CHAR(4)) + 	
				CAST(RTRIM(direct_deposit_bank_acct_nbr_07)	AS CHAR(15))	+ CAST('' AS CHAR(7)) + 
--				CAST(RTRIM(bank_acct_type_code_07)		    AS CHAR(17))	+ CAST('' AS CHAR(3)) + 
				CASE WHEN bank_acct_type_code_07 = '1'  THEN 'Checking ' 
				     WHEN bank_acct_type_code_07 = '2'  THEN 'Saving   '
				     ELSE CAST(RTRIM(bank_acct_type_code_07) AS CHAR(17)) 
				END	+ CAST('' AS CHAR(11)) 
				--CAST('</font>' AS CHAR(07)) 	
 --SELECT *
		  FROM DBShrpn.dbo.ghr_bankinfo_events_aud ev 
		 WHERE event_id_01 = @event_id_01 AND activity_status = @activity_status AND activity_date	=	@rundate
END -- End of IF Statement	


SET		@event_id_01	=	'07'
SET		@activity_status =  '02'

--
--	This section of code will proc
--
IF	EXISTS ( SELECT * FROM DBShrpn.dbo.ghr_bankinfo_events_aud ev WHERE event_id_01 = @event_id_01 AND activity_status in (@activity_status,'01') AND activity_date = @rundate)
	BEGIN
	IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_email_report2]') AND type in (N'U'))
		DROP TABLE [DBShrpn].[dbo].[ghr_email_report2]
	

	CREATE TABLE [DBShrpn].[dbo].[ghr_email_report2](
		[ID]									[int]	IDENTITY(1,1) NOT NULL,
		[event_id_01]							[char](02) NULL,
		[emp_id_01]								[char](15) NULL,
		[eff_date_01]							[char](10) NULL,
		[pay_element_desc_06]					[char](20) NULL,
		first_name_01							[char](25) NULL,
		last_name_01							[char](30) NULL,
		empl_id_01								[char](10) NULL,
        bank_id_07  				            [char](11) NULL,	
        direct_deposit_bank_acct_nbr_07         [char](17) NULL,
        bank_acct_type_code_07                  [char](01) NULL,
		emp_status_code_5                       [char](02) NULL,		
		emp_calculation_06						[char](15) NULL)
		
	INSERT INTO [DBShrpn].[dbo].[ghr_email_report2]	
	SELECT  ev.event_id_01,  ev.emp_id_01,ev.eff_date_01, ev.pay_element_desc_06,
			ev.first_name_01,ev.last_name_01, 
			ev.empl_id_01, bank_id_07, direct_deposit_bank_acct_nbr_07, bank_acct_type_code_07,
			ev.emp_status_code_5,ev.emp_calculation_06
--  SELECT *
	  FROM DBShrpn.dbo.ghr_bankinfo_events_aud ev 
	  	  INNER JOIN [DBShrpn].[dbo].[ghr_historical_message] m 
			  ON m.event_id		=	ev.event_id_01
			 AND m.emp_id		=	ev.emp_id_01
			 AND m.eff_date		=	ev.eff_date_01
	 WHERE ev.event_id_01 = @event_id_01 AND ev.activity_status IN (@activity_status,'01') AND	ev.activity_date =	@rundate 
	 GROUP BY ev.event_id_01,  ev.emp_id_01,ev.eff_date_01, ev.pay_element_desc_06,
			ev.first_name_01,ev.last_name_01,ev.empl_id_01,bank_id_07, direct_deposit_bank_acct_nbr_07, bank_acct_type_code_07, ev.emp_status_code_5,ev.emp_calculation_06
	 ORDER BY ev.empl_id_01

	IF	EXISTS ( SELECT * FROM [DBShrpn].[dbo].[ghr_bankinfo_events_aud] WHERE event_id_01 = @event_id_01 AND activity_status IN (@activity_status,'01') AND activity_date = @rundate)
		BEGIN
			SELECT  SPACE(30)
			SELECT	'Bank Account in Errors Section:'
			SELECT	SPACE(30)
		
			SELECT	--CAST('Activity Description' AS CHAR(20))	+ CAST('' AS CHAR(6)) + 
					CAST('Employee' AS CHAR(12))				+ CAST('' AS CHAR(1)) +	
					CAST('Eff. Date' AS CHAR(10))				+ CAST('' AS CHAR(3)) +
--					CAST('Pay Element' AS CHAR(11))				+ CAST('' AS CHAR(1)) +				
					CAST('First Name' AS CHAR(15))				+ CAST('' AS CHAR(5)) +
					CAST('Last Name' AS CHAR(15))				+ CAST('' AS CHAR(5)) +
					CAST('Employer' AS CHAR(10))				+ CAST('' AS CHAR(1)) + 
					CAST('Bank Id' AS CHAR(10))				    + CAST('' AS CHAR(1)) +
					CAST('Bank Account Number' AS CHAR(20))		+ CAST('' AS CHAR(2)) +
					CAST('Bank Account Type' AS CHAR(20))		+ CAST('' AS CHAR(1))
--					CAST('National Type Code' AS CHAR(15)),	
--					CAST('National Identity' AS CHAR(15)),
--					CAST('Organization Group' AS CHAR(15)),	
--					CAST('Organization Name' AS CHAR(15)),	
--					CAST('Organization Unit' AS CHAR(15)),	
--					CAST('Pay Group' AS CHAR(15))				+ CAST('' AS CHAR(5)) +	
--					CAST('Control Group' AS CHAR(15))			+ CAST('' AS CHAR(5)) +	
--					CAST('Position Title' AS CHAR(15))
--					CAST('Pay Amount' AS CHAR(10))				+ CAST('' AS CHAR(1)) +
--					CAST('New Hire Messages:' AS CHAR(21))	  				
				

		SELECT @max	=	COUNT(*) FROM [DBShrpn].[dbo].[ghr_email_report2];
		SELECT @cnt =	1;
		
		WHILE (@cnt <= @max)
		 BEGIN
						
			SELECT  --DISTINCT 
--					CAST(''										AS CHAR(17))	+ CAST('' AS CHAR(9)) + 
					CAST(RTRIM(emp_id_01)						AS CHAR(12))	+ CAST('' AS CHAR(1)) + 
					CAST(RTRIM(eff_date_01)						AS CHAR(10))	+ CAST('' AS CHAR(3)) + 
--					CAST(RTRIM(ev.pay_element_desc_06)			AS CHAR(15))	+ CAST('' AS CHAR(5)) + 				
					CAST(RTRIM(first_name_01)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 
					CAST(RTRIM(last_name_01)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 
					CAST(RTRIM(empl_id_01)						AS CHAR(10))	+ CAST('' AS CHAR(1)) +
					CAST(RTRIM(bank_id_07)						AS CHAR(10))	+ CAST('' AS CHAR(1)) +
					CAST(RTRIM(direct_deposit_bank_acct_nbr_07)	AS CHAR(10))	+ CAST('' AS CHAR(12)) +
--					CAST(RTRIM(bank_acct_type_code_07)			AS CHAR(10))	+ CAST('' AS CHAR(1)) 
					CASE WHEN bank_acct_type_code_07 = '1'  THEN 'Checking ' 
				         WHEN bank_acct_type_code_07 = '2'  THEN 'Saving   '
				         ELSE CAST(RTRIM(bank_acct_type_code_07) AS CHAR(10)) 
				END	+ CAST('' AS CHAR(5)) 	
--					CAST(RTRIM(pay_group_id_03)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 	
--					CAST(RTRIM(pay_element_ctrl_grp_id_03)		AS CHAR(15))	+ CAST('' AS CHAR(5)) + 					
--					CAST(RTRIM(emp_calculation_06)				AS CHAR(05))	+ CAST('' AS CHAR(5)) + 
--					msg_desc
--					CHAR(13) + '   ' + msg_desc
			  FROM [DBShrpn].[dbo].[ghr_email_report2] 
		     WHERE [ID]	=	@cnt
		 
			SELECT @emp_id = emp_id_01, @eff_date = eff_date_01 FROM [DBShrpn].[dbo].[ghr_email_report2] WHERE [ID]	=	@cnt
		
			SELECT 'Error Messages:'
		
			SELECT  CAST(''			AS CHAR(02)) + msg_desc
			  FROM [DBShrpn].[dbo].[ghr_historical_message]
			 WHERE event_id			=	@event_id_01
		       AND emp_id			=	@emp_id
		       AND eff_date			=	@eff_date
		       AND activity_date	=	@rundate
		    GROUP BY msg_desc
		    
			SELECT '              '
				
			SELECT	@cnt	=	@cnt + 1
		 
		 END	--End of While Loop
		END  --End of IF Statement 2
	END  -- End of Event 01 AND Activity Status 02		 


SELECT SPACE(1)
SELECT SPACE(0)
SELECT 'End of mail message.'
SELECT '    '
SELECT 'IPM.MICROSOFT'
SELECT 'GHR'
SELECT 'TO:jgross@smartsi.com + SMTP:jgross@smartsi.com'

END  -- End of SP
 
GO
ALTER AUTHORIZATION ON [dbo].[usp_bank_verification_rpt] TO  SCHEMA OWNER 
GO
