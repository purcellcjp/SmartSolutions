USE [DBShrpn]
GO
/****** Object:  StoredProcedure [dbo].[usp_verification_rpt]    Script Date: 4/1/2025 4:33:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE procedure [dbo].[usp_verification_rpt]
AS
 --   EXEC [DBShrpn].[dbo].[usp_verification_rpt]
BEGIN
DECLARE	@cnt					int
DECLARE @max					int
DECLARE @event_id_01			char(02)
DECLARE @activity_status		char(02)
DECLARE	@emp_id					char(15)
DECLARE @eff_date				char(10)
DECLARE @rundate				datetime

SELECT @rundate = MAX(activity_date) FROM [DBShrpn].[dbo].[ghr_employee_events_aud] 

IF convert(char,@rundate,112) <> convert(char,DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE())),112)
   SELECT @rundate = convert(char,DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE())),112)

--SELECT @rundate = DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))
--SELECT @rundate = '2023-04-21 03:02:10.000'
--
--	Report on Employees Successfully Loaded for pay element interface
--


--SELECT CAST('<font face="Courier New" size="11px" color="#FF7A59">Your text here.</font>' AS CHAR(90)) 

		SELECT	SPACE(35) + 'HCM - SS Interface Transaction Report'
		SELECT  SPACE(50) + 'All Entities'
		SELECT	'Run Date: ' + CONVERT(char,GETDATE(),120)	+ SPACE(10)
		SELECT	SPACE(50)
		
 
SET		@event_id_01	=	'01'
SET		@activity_status =  '00'


IF	EXISTS ( SELECT * FROM [DBShrpn].[dbo].[ghr_employee_events_aud] WHERE event_id_01 = @event_id_01 AND activity_status = @activity_status AND activity_date = @rundate)
	BEGIN		
		SELECT  SPACE(30)
		SELECT	'New Hire Section:'
		SELECT	SPACE(30)

		SELECT	--CAST('<font face=''Courier New''>' AS CHAR(27)) +
--				CAST('Activity Description' AS CHAR(20))	+ CAST('' AS CHAR(6)) + 
				CAST('Employee' AS CHAR(12))				+ CAST('' AS CHAR(1)) +	
				CAST('Eff. Date' AS CHAR(10))				+ CAST('' AS CHAR(3)) +
				CAST('First Name' AS CHAR(15))				+ CAST('' AS CHAR(5)) +
				CAST('Last Name' AS CHAR(15))				+ CAST('' AS CHAR(5)) +
				CAST('Employer' AS CHAR(10))				+ CAST('' AS CHAR(1)) +
--				CAST('National Type Code' AS CHAR(15)),	
--				CAST('National Identity' AS CHAR(15)),
--				CAST('Organization Group' AS CHAR(15)),	
--				CAST('Organization Name' AS CHAR(15)),	
--				CAST('Organization Unit' AS CHAR(15)),	
				CAST('Pay Group' AS CHAR(15))				+ CAST('' AS CHAR(5)) +	
				CAST('Control Group' AS CHAR(15))			+ CAST('' AS CHAR(5)) +	
--				CAST('Position Title' AS CHAR(15))
				CAST('Annual Salary' AS CHAR(15))			+ CAST('' AS CHAR(5))   
				--CAST('</font>' AS CHAR(07)) 

--		SELECT 'Successful New Hire:'
	

		SELECT   
				---CAST('<font face=''Courier New''>' AS CHAR(27)) +
--				CAST(''										AS CHAR(17))	+ CAST('' AS CHAR(9)) + 
				CAST(RTRIM(emp_id_01)						AS CHAR(12))	+ CAST('' AS CHAR(1)) + 
				CAST(RTRIM(eff_date_01)						AS CHAR(10))	+ CAST('' AS CHAR(3)) + 
				CAST(RTRIM(first_name_01)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 
				CAST(RTRIM(last_name_01)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 
				CAST(RTRIM(empl_id_01)						AS CHAR(10))	+ CAST('' AS CHAR(1)) +  	
				CAST(RTRIM(pay_group_id_03)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 	
				CAST(RTRIM(pay_element_ctrl_grp_id_03)		AS CHAR(15))	+ CAST('' AS CHAR(5)) + 					
				CAST(RTRIM(annual_salary_amt_01)			AS CHAR(15))	+ CAST('' AS CHAR(5)) 
				--CAST('</font>' AS CHAR(07)) 	
 
		  FROM [DBShrpn].[dbo].[ghr_employee_events_aud] ev 
		 WHERE event_id_01 = @event_id_01 AND activity_status = @activity_status AND activity_date	=	@rundate
END -- End of IF Statement		


SET		@event_id_01	=	'01'
SET		@activity_status =  '02'

--
--	This section of code will proc
--
IF	EXISTS ( SELECT * FROM [DBShrpn].[dbo].[ghr_employee_events_aud] WHERE event_id_01 = @event_id_01 AND activity_status in (@activity_status,'01') AND activity_date = @rundate)
	BEGIN
	IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_email_report]') AND type in (N'U'))
		DROP TABLE [dbo].[ghr_email_report]
	

	CREATE TABLE [dbo].[ghr_email_report](
		[ID]									[int]	IDENTITY(1,1) NOT NULL,
		[event_id_01]							[char](02) NULL,
		[emp_id_01]								[char](15) NULL,
		[eff_date_01]							[char](10) NULL,
		[pay_element_desc_06]					[char](20) NULL,
		first_name_01							[char](25) NULL,
		last_name_01							[char](30) NULL,
		empl_id_01								[char](10) NULL,
		emp_status_code_5                       [char](02) NULL,		
		emp_calculation_06						[char](15) NULL)

	INSERT INTO [DBShrpn].[dbo].[ghr_email_report]	
	SELECT  ev.event_id_01,  ev.emp_id_01,ev.eff_date_01, ev.pay_element_desc_06,
			ev.first_name_01,ev.last_name_01,ev.empl_id_01,ev.emp_status_code_5,ev.emp_calculation_06
	  FROM [DBShrpn].[dbo].[ghr_employee_events_aud] ev 
	  	  INNER JOIN [DBShrpn].[dbo].[ghr_historical_message] m 
			  ON m.event_id		=	ev.event_id_01
			 AND m.emp_id		=	ev.emp_id_01
			 AND m.eff_date		=	ev.eff_date_01
	 WHERE ev.event_id_01 = @event_id_01 AND ev.activity_status IN (@activity_status,'01') AND	ev.activity_date =	@rundate 
	 GROUP BY ev.event_id_01,  ev.emp_id_01,ev.eff_date_01, ev.pay_element_desc_06,
			ev.first_name_01,ev.last_name_01,ev.empl_id_01,ev.emp_status_code_5,ev.emp_calculation_06
	 ORDER BY ev.empl_id_01

	IF	EXISTS ( SELECT * FROM [DBShrpn].[dbo].[ghr_employee_events_aud] WHERE event_id_01 = @event_id_01 AND activity_status IN (@activity_status,'01') AND activity_date = @rundate)
		BEGIN
			SELECT  SPACE(30)
			SELECT	'New Hire in Errors Section:'
			SELECT	SPACE(30)
		
			SELECT	--CAST('Activity Description' AS CHAR(20))	+ CAST('' AS CHAR(6)) + 
					CAST('Employee' AS CHAR(12))				+ CAST('' AS CHAR(1)) +	
					CAST('Eff. Date' AS CHAR(10))				+ CAST('' AS CHAR(3)) +
--					CAST('Pay Element' AS CHAR(11))				+ CAST('' AS CHAR(1)) +				
					CAST('First Name' AS CHAR(15))				+ CAST('' AS CHAR(5)) +
					CAST('Last Name' AS CHAR(15))				+ CAST('' AS CHAR(5)) +
					CAST('Employer' AS CHAR(10))				+ CAST('' AS CHAR(1)) 
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
				

		SELECT @max	=	COUNT(*) FROM [DBShrpn].[dbo].[ghr_email_report];
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
					CAST(RTRIM(empl_id_01)						AS CHAR(10))	+ CAST('' AS CHAR(1))  	
--					CAST(RTRIM(pay_group_id_03)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 	
--					CAST(RTRIM(pay_element_ctrl_grp_id_03)		AS CHAR(15))	+ CAST('' AS CHAR(5)) + 					
--					CAST(RTRIM(emp_calculation_06)				AS CHAR(05))	+ CAST('' AS CHAR(5)) + 
--					msg_desc
--					CHAR(13) + '   ' + msg_desc
			  FROM [DBShrpn].[dbo].[ghr_email_report] 
		     WHERE [ID]	=	@cnt
		 
			SELECT @emp_id = emp_id_01, @eff_date = eff_date_01 FROM [DBShrpn].[dbo].[ghr_email_report] WHERE [ID]	=	@cnt
		
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



SET		@event_id_01	=	'02'
SET		@activity_status =  '00'


IF	EXISTS ( SELECT * FROM [DBShrpn].[dbo].[ghr_employee_events_aud] WHERE event_id_01 = @event_id_01 AND activity_status = @activity_status AND activity_date = @rundate)
	BEGIN		
		SELECT  SPACE(30)
		SELECT	'Salary Change Section:'
		SELECT	SPACE(30)

			SELECT	--CAST('Activity Description' AS CHAR(20))	+ CAST('' AS CHAR(6)) + 
					CAST('Employee' AS CHAR(12))				+ CAST('' AS CHAR(1)) +	
					CAST('Eff. Date' AS CHAR(10))				+ CAST('' AS CHAR(3)) +
--					CAST('Pay Element' AS CHAR(11))				+ CAST('' AS CHAR(1)) +				
					CAST('First Name' AS CHAR(15))				+ CAST('' AS CHAR(5)) +
					CAST('Last Name' AS CHAR(15))				+ CAST('' AS CHAR(6)) +
					CAST('Employer' AS CHAR(10))				+ CAST('' AS CHAR(1)) +
--					CAST('National Type Code' AS CHAR(15)),	
--					CAST('National Identity' AS CHAR(15)),
--					CAST('Organization Group' AS CHAR(15)),	
--					CAST('Organization Name' AS CHAR(15)),	
--					CAST('Organization Unit' AS CHAR(15)),	
--					CAST('Pay Group' AS CHAR(15))				+ CAST('' AS CHAR(5)) +	
--					CAST('Control Group' AS CHAR(15))			+ CAST('' AS CHAR(5)) +	
--					CAST('Position Title' AS CHAR(15))
					CAST('Pay Amount' AS CHAR(10))				+ CAST('' AS CHAR(1)) 
--					CAST('New Hire Messages:' AS CHAR(21))
				--CAST('</font>' AS CHAR(07)) 

--		SELECT 'Successful New Hire:'
	

		SELECT   
				---CAST('<font face=''Courier New''>' AS CHAR(27)) +
--				CAST(''										AS CHAR(17))	+ CAST('' AS CHAR(9)) + 
				CAST(RTRIM(emp_id_01)						AS CHAR(12))	+ CAST('' AS CHAR(1)) + 
				CAST(RTRIM(eff_date_01)						AS CHAR(10))	+ CAST('' AS CHAR(3)) + 
				CAST(RTRIM(first_name_01)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 
				CAST(RTRIM(last_name_01)					AS CHAR(15))	+ CAST('' AS CHAR(6)) + 
				CAST(RTRIM(empl_id_01)						AS CHAR(10))	+ CAST('' AS CHAR(1)) +  	
--				CAST(RTRIM(pay_group_id_03)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 	
--				CAST(RTRIM(pay_element_ctrl_grp_id_03)		AS CHAR(15))	+ CAST('' AS CHAR(5)) + 					
				CAST(RTRIM(annual_salary_amt_01)			AS CHAR(15))	+ CAST('' AS CHAR(5)) 
				--CAST('</font>' AS CHAR(07)) 				 
		  FROM [DBShrpn].[dbo].[ghr_employee_events_aud] ev 
		 WHERE event_id_01 = @event_id_01 AND activity_status = @activity_status  AND	activity_date =	@rundate
END -- End of IF Statement	


SET		@event_id_01	=	'02'
SET		@activity_status =  '02'

--
--	This section of code will proc
--
IF	EXISTS ( SELECT * FROM [DBShrpn].[dbo].[ghr_employee_events_aud] WHERE event_id_01 = @event_id_01 AND activity_status = @activity_status AND activity_date = @rundate)
	BEGIN
	IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_email_report]') AND type in (N'U'))
		DROP TABLE [dbo].[ghr_email_report]
	

	CREATE TABLE [dbo].[ghr_email_report](
		[ID]									[int]	IDENTITY(1,1) NOT NULL,
		[event_id_01]							[char](02) NULL,
		[emp_id_01]								[char](15) NULL,
		[eff_date_01]							[char](10) NULL,
		[pay_element_desc_06]					[char](20) NULL,
		first_name_01							[char](25) NULL,
		last_name_01							[char](30) NULL,
		empl_id_01								[char](10) NULL,
		emp_status_code_5                       [char](02) NULL,
		emp_calculation_06						[char](15) NULL)


	INSERT INTO [DBShrpn].[dbo].[ghr_email_report]	
	SELECT  ev.event_id_01,  ev.emp_id_01,ev.eff_date_01, ev.pay_element_desc_06,
			ev.first_name_01,ev.last_name_01,ev.empl_id_01,ev.emp_status_code_5,ev.annual_salary_amt_01
	  FROM [DBShrpn].[dbo].[ghr_employee_events_aud] ev 
	  INNER JOIN [DBShrpn].[dbo].[ghr_historical_message] m 
			  ON m.event_id		=	ev.event_id_01
			 AND m.emp_id		=	ev.emp_id_01
			 AND m.eff_date		=	ev.eff_date_01
			 
	 WHERE ev.event_id_01 = @event_id_01 AND ev.activity_status IN (@activity_status,'01')  AND	ev.activity_date =	@rundate
	 GROUP BY ev.event_id_01,  ev.emp_id_01,ev.eff_date_01, ev.pay_element_desc_06,
			  ev.first_name_01,ev.last_name_01,ev.empl_id_01,ev.emp_status_code_5,ev.annual_salary_amt_01
	 ORDER BY ev.empl_id_01

	IF	EXISTS ( SELECT * FROM [DBShrpn].[dbo].[ghr_employee_events_aud] WHERE event_id_01 = @event_id_01 AND activity_status = @activity_status AND activity_date = @rundate)
		BEGIN
			SELECT  SPACE(30)
			SELECT	'Salary Change Error Section:'
			SELECT	SPACE(30)
		
			SELECT	--CAST('Activity Description' AS CHAR(20))	+ CAST('' AS CHAR(6)) + 
					CAST('Employee' AS CHAR(12))				+ CAST('' AS CHAR(1)) +	
					CAST('Eff. Date' AS CHAR(10))				+ CAST('' AS CHAR(3)) +
--					CAST('Pay Element' AS CHAR(11))				+ CAST('' AS CHAR(1)) +				
					CAST('First Name' AS CHAR(15))				+ CAST('' AS CHAR(5)) +
					CAST('Last Name' AS CHAR(15))				+ CAST('' AS CHAR(6)) +
					CAST('Employer' AS CHAR(10))				+ CAST('' AS CHAR(1)) +
--					CAST('National Type Code' AS CHAR(15)),	
--					CAST('National Identity' AS CHAR(15)),
--					CAST('Organization Group' AS CHAR(15)),	
--					CAST('Organization Name' AS CHAR(15)),	
--					CAST('Organization Unit' AS CHAR(15)),	
--					CAST('Pay Group' AS CHAR(15))				+ CAST('' AS CHAR(5)) +	
--					CAST('Control Group' AS CHAR(15))			+ CAST('' AS CHAR(5)) +	
--					CAST('Position Title' AS CHAR(15))
					CAST('Pay Amount' AS CHAR(10))				+ CAST('' AS CHAR(1)) 
--					CAST('New Hire Messages:' AS CHAR(21))	  				
				

		SELECT @max	=	COUNT(*) FROM [DBShrpn].[dbo].[ghr_email_report];
		SELECT @cnt =	1;
		
		WHILE (@cnt <= @max)
		 BEGIN
						
			SELECT  --DISTINCT 
--					CAST(''										AS CHAR(20))	+ CAST('' AS CHAR(9)) + 
					CAST(RTRIM(emp_id_01)						AS CHAR(12))	+ CAST('' AS CHAR(1)) + 
					CAST(RTRIM(eff_date_01)						AS CHAR(10))	+ CAST('' AS CHAR(3)) + 
--					CAST(RTRIM(ev.pay_element_desc_06)			AS CHAR(15))	+ CAST('' AS CHAR(5)) + 				
					CAST(RTRIM(first_name_01)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 
					CAST(RTRIM(last_name_01)					AS CHAR(15))	+ CAST('' AS CHAR(6)) + 
					CAST(RTRIM(empl_id_01)						AS CHAR(10))	+ CAST('' AS CHAR(1)) +	
--					CAST(RTRIM(pay_group_id_03)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 	
--					CAST(RTRIM(pay_element_ctrl_grp_id_03)		AS CHAR(15))	+ CAST('' AS CHAR(5)) + 					
					CAST(RTRIM(emp_calculation_06)				AS CHAR(15))	+ CAST('' AS CHAR(1))  
--					msg_desc
--					CHAR(13) + '   ' + msg_desc
			  FROM [DBShrpn].[dbo].[ghr_email_report] 
		     WHERE [ID]	=	@cnt
		 
			SELECT @emp_id = emp_id_01, @eff_date = eff_date_01 FROM [DBShrpn].[dbo].[ghr_email_report] WHERE [ID]	=	@cnt
		
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
	END  -- End of Event 02 AND Activity Status 02	
	
SET		@event_id_01	=	'03'
SET		@activity_status =  '00'


IF	EXISTS ( SELECT * FROM [DBShrpn].[dbo].[ghr_employee_events_aud] WHERE event_id_01 = @event_id_01 AND activity_status = @activity_status AND activity_date = @rundate)
	BEGIN		
		SELECT  SPACE(30)
		SELECT	'Transfer Section:'
		SELECT	SPACE(30)

			SELECT	--CAST('Activity Description' AS CHAR(20))	+ CAST('' AS CHAR(6)) + 
					CAST('Employee' AS CHAR(12))				+ CAST('' AS CHAR(1)) +	
					CAST('Eff. Date' AS CHAR(10))				+ CAST('' AS CHAR(3)) +
--					CAST('Pay Element' AS CHAR(11))				+ CAST('' AS CHAR(1)) +				
					CAST('First Name' AS CHAR(15))				+ CAST('' AS CHAR(5)) +
					CAST('Last Name' AS CHAR(15))				+ CAST('' AS CHAR(5)) +
					CAST('Employer' AS CHAR(10))				+ CAST('' AS CHAR(1)) +
--					CAST('National Type Code' AS CHAR(15)),	
--					CAST('National Identity' AS CHAR(15)),
--					CAST('Organization Group' AS CHAR(15)),	
--					CAST('Organization Name' AS CHAR(15)),	
--					CAST('Organization Unit' AS CHAR(15)),	
--					CAST('Pay Group' AS CHAR(15))				+ CAST('' AS CHAR(5)) +	
--					CAST('Control Group' AS CHAR(15))			+ CAST('' AS CHAR(5)) +	
--					CAST('Position Title' AS CHAR(15))
					CAST('Pay Amount' AS CHAR(10))				+ CAST('' AS CHAR(1)) 
--					CAST('New Hire Messages:' AS CHAR(21))
				--CAST('</font>' AS CHAR(07)) 

--		SELECT 'Successful New Hire:'
	

		SELECT   
				---CAST('<font face=''Courier New''>' AS CHAR(27)) +
--				CAST(''										AS CHAR(17))	+ CAST('' AS CHAR(9)) + 
				CAST(RTRIM(emp_id_01)						AS CHAR(12))	+ CAST('' AS CHAR(1)) + 
				CAST(RTRIM(eff_date_01)						AS CHAR(10))	+ CAST('' AS CHAR(3)) + 
				CAST(RTRIM(first_name_01)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 
				CAST(RTRIM(last_name_01)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 
				CAST(RTRIM(empl_id_01)						AS CHAR(10))	+ CAST('' AS CHAR(5)) +  	
--				CAST(RTRIM(pay_group_id_03)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 	
--				CAST(RTRIM(pay_element_ctrl_grp_id_03)		AS CHAR(15))	+ CAST('' AS CHAR(5)) + 					
				CAST(RTRIM(annual_salary_amt_01)			AS CHAR(15))	+ CAST('' AS CHAR(5)) 
				--CAST('</font>' AS CHAR(07)) 				 
		  FROM [DBShrpn].[dbo].[ghr_employee_events_aud] ev 
		 WHERE event_id_01 = @event_id_01 AND activity_status = @activity_status  AND	activity_date =	@rundate
END -- End of IF Statement	

SET		@event_id_01	=	'03'
SET		@activity_status =  '02'

--
--	This section of code will proc
--
IF	EXISTS ( SELECT * FROM [DBShrpn].[dbo].[ghr_employee_events_aud] WHERE event_id_01 = @event_id_01 AND activity_status = @activity_status AND activity_date = @rundate)
	BEGIN
	IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_email_report]') AND type in (N'U'))
		DROP TABLE [dbo].[ghr_email_report]
	

	CREATE TABLE [dbo].[ghr_email_report](
		[ID]									[int]	IDENTITY(1,1) NOT NULL,
		[event_id_01]							[char](02) NULL,
		[emp_id_01]								[char](15) NULL,
		[eff_date_01]							[char](10) NULL,
		[pay_element_desc_06]					[char](20) NULL,
		first_name_01							[char](25) NULL,
		last_name_01							[char](30) NULL,
		empl_id_01								[char](10) NULL,
		emp_status_code_5                       [char](02) NULL,
		emp_calculation_06						[char](15) NULL)


	INSERT INTO [DBShrpn].[dbo].[ghr_email_report]	
	SELECT  ev.event_id_01,  ev.emp_id_01,ev.eff_date_01, ev.pay_element_desc_06,
			ev.first_name_01,ev.last_name_01,ev.empl_id_01,ev.emp_status_code_5,ev.annual_salary_amt_01
	  FROM [DBShrpn].[dbo].[ghr_employee_events_aud] ev 
	  INNER JOIN [DBShrpn].[dbo].[ghr_historical_message] m 
			  ON m.event_id		=	ev.event_id_01
			 AND m.emp_id		=	ev.emp_id_01
			 AND m.eff_date		=	ev.eff_date_01
			 
	 WHERE ev.event_id_01 = @event_id_01 AND ev.activity_status IN (@activity_status,'01')  AND	ev.activity_date =	@rundate
	 GROUP BY ev.event_id_01,  ev.emp_id_01,ev.eff_date_01, ev.pay_element_desc_06,
			  ev.first_name_01,ev.last_name_01,ev.empl_id_01,ev.emp_status_code_5,ev.annual_salary_amt_01
	 ORDER BY ev.empl_id_01

	IF	EXISTS ( SELECT * FROM [DBShrpn].[dbo].[ghr_employee_events_aud] WHERE event_id_01 = @event_id_01 AND activity_status = @activity_status AND activity_date = @rundate)
		BEGIN
			SELECT  SPACE(30)
			SELECT	'Transfer Error Section:'
			SELECT	SPACE(30)
		
			SELECT	--CAST('Activity Description' AS CHAR(20))	+ CAST('' AS CHAR(6)) + 
					CAST('Employee' AS CHAR(12))				+ CAST('' AS CHAR(1)) +	
					CAST('Eff. Date' AS CHAR(10))				+ CAST('' AS CHAR(2)) +
--					CAST('Pay Element' AS CHAR(11))				+ CAST('' AS CHAR(1)) +				
					CAST('First Name' AS CHAR(15))				+ CAST('' AS CHAR(5)) +
					CAST('Last Name' AS CHAR(15))				+ CAST('' AS CHAR(5)) +
					CAST('Employer' AS CHAR(10))				+ CAST('' AS CHAR(4)) +
--					CAST('National Type Code' AS CHAR(15)),	
--					CAST('National Identity' AS CHAR(15)),
--					CAST('Organization Group' AS CHAR(15)),	
--					CAST('Organization Name' AS CHAR(15)),	
--					CAST('Organization Unit' AS CHAR(15)),	
--					CAST('Pay Group' AS CHAR(15))				+ CAST('' AS CHAR(5)) +	
--					CAST('Control Group' AS CHAR(15))			+ CAST('' AS CHAR(5)) +	
--					CAST('Position Title' AS CHAR(15))
					CAST('Pay Amount' AS CHAR(10))				+ CAST('' AS CHAR(1)) 
--					CAST('New Hire Messages:' AS CHAR(21))	  				
				

		SELECT @max	=	COUNT(*) FROM [DBShrpn].[dbo].[ghr_email_report];
		SELECT @cnt =	1;
		
		WHILE (@cnt <= @max)
		 BEGIN
						
			SELECT  --DISTINCT 
--					CAST(''										AS CHAR(17))	+ CAST('' AS CHAR(9)) + 
					CAST(RTRIM(emp_id_01)						AS CHAR(12))	+ CAST('' AS CHAR(1)) + 
					CAST(RTRIM(eff_date_01)						AS CHAR(10))	+ CAST('' AS CHAR(2)) + 
--					CAST(RTRIM(ev.pay_element_desc_06)			AS CHAR(15))	+ CAST('' AS CHAR(5)) + 				
					CAST(RTRIM(first_name_01)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 
					CAST(RTRIM(last_name_01)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 
					CAST(RTRIM(empl_id_01)						AS CHAR(10))	+ CAST('' AS CHAR(4)) +	
--					CAST(RTRIM(pay_group_id_03)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 	
--					CAST(RTRIM(pay_element_ctrl_grp_id_03)		AS CHAR(15))	+ CAST('' AS CHAR(5)) + 					
					CAST(RTRIM(emp_calculation_06)				AS CHAR(15))	+ CAST('' AS CHAR(1))  
--					msg_desc
--					CHAR(13) + '   ' + msg_desc
			  FROM [DBShrpn].[dbo].[ghr_email_report] 
		     WHERE [ID]	=	@cnt
		 
			SELECT @emp_id = emp_id_01, @eff_date = eff_date_01 FROM [DBShrpn].[dbo].[ghr_email_report] WHERE [ID]	=	@cnt
		
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
	END  -- End of Event 02 AND Activity Status 02			
	
SET		@event_id_01	=	'04'
SET		@activity_status =  '00'

IF	EXISTS ( SELECT * FROM [DBShrpn].[dbo].[ghr_employee_events_aud] WHERE event_id_01 = @event_id_01 AND activity_status = @activity_status AND activity_date = @rundate)
	BEGIN		
		SELECT  SPACE(30)
		SELECT	'Name Change Section:'
		SELECT	SPACE(30)

			SELECT	--CAST('Activity Description' AS CHAR(20))	+ CAST('' AS CHAR(6)) + 
					CAST('Employee' AS CHAR(12))				+ CAST('' AS CHAR(1)) +	
					CAST('Eff. Date' AS CHAR(10))				+ CAST('' AS CHAR(3)) +
--					CAST('Pay Element' AS CHAR(11))				+ CAST('' AS CHAR(1)) +				
					CAST('First Name' AS CHAR(15))				+ CAST('' AS CHAR(5)) +
					CAST('Last Name' AS CHAR(15))				+ CAST('' AS CHAR(5)) +
					CAST('Employer' AS CHAR(10))				+ CAST('' AS CHAR(1)) +
--					CAST('National Type Code' AS CHAR(15)),	
--					CAST('National Identity' AS CHAR(15)),
--					CAST('Organization Group' AS CHAR(15)),	
--					CAST('Organization Name' AS CHAR(15)),	
--					CAST('Organization Unit' AS CHAR(15)),	
--					CAST('Pay Group' AS CHAR(15))				+ CAST('' AS CHAR(5)) +	
--					CAST('Control Group' AS CHAR(15))			+ CAST('' AS CHAR(5)) +	
--					CAST('Position Title' AS CHAR(15))
					CAST('Pay Amount' AS CHAR(10))				+ CAST('' AS CHAR(1)) 
--					CAST('New Hire Messages:' AS CHAR(21))
				--CAST('</font>' AS CHAR(07)) 

--		SELECT 'Successful New Hire:'
	

		SELECT   
				---CAST('<font face=''Courier New''>' AS CHAR(27)) +
--				CAST(''										AS CHAR(17))	+ CAST('' AS CHAR(9)) + 
				CAST(RTRIM(emp_id_01)						AS CHAR(12))	+ CAST('' AS CHAR(1)) + 
				CAST(RTRIM(eff_date_01)						AS CHAR(10))	+ CAST('' AS CHAR(3)) + 
				CAST(RTRIM(first_name_01)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 
				CAST(RTRIM(last_name_01)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 
				CAST(RTRIM(empl_id_01)						AS CHAR(10))	+ CAST('' AS CHAR(5)) +  	
--				CAST(RTRIM(pay_group_id_03)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 	
--				CAST(RTRIM(pay_element_ctrl_grp_id_03)		AS CHAR(15))	+ CAST('' AS CHAR(5)) + 					
				CAST(RTRIM(annual_salary_amt_01)			AS CHAR(15))	+ CAST('' AS CHAR(5)) 
				--CAST('</font>' AS CHAR(07)) 				 
		  FROM [DBShrpn].[dbo].[ghr_employee_events_aud] ev 
		 WHERE event_id_01 = @event_id_01 AND activity_status = @activity_status  AND	activity_date =	@rundate
END -- End of IF Statement	

SET		@event_id_01	=	'04'
SET		@activity_status =  '02'

--
--	This section of code will proc
--
IF	EXISTS ( SELECT * FROM [DBShrpn].[dbo].[ghr_employee_events_aud] WHERE event_id_01 = @event_id_01 AND activity_status = @activity_status AND activity_date = @rundate)
	BEGIN
	IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_email_report]') AND type in (N'U'))
		DROP TABLE [dbo].[ghr_email_report]
	

	CREATE TABLE [dbo].[ghr_email_report](
		[ID]									[int]	IDENTITY(1,1) NOT NULL,
		[event_id_01]							[char](02) NULL,
		[emp_id_01]								[char](15) NULL,
		[eff_date_01]							[char](10) NULL,
		[pay_element_desc_06]					[char](20) NULL,
		first_name_01							[char](25) NULL,
		last_name_01							[char](30) NULL,
		empl_id_01								[char](10) NULL,
		emp_status_code_5                       [char](02) NULL,		
		emp_calculation_06						[char](15) NULL)


	INSERT INTO [DBShrpn].[dbo].[ghr_email_report]	
	SELECT  ev.event_id_01,  ev.emp_id_01,ev.eff_date_01, ev.pay_element_desc_06,
			ev.first_name_01,ev.last_name_01,ev.empl_id_01,ev.emp_status_code_5,ev.annual_salary_amt_01
	  FROM [DBShrpn].[dbo].[ghr_employee_events_aud] ev 
	  INNER JOIN [DBShrpn].[dbo].[ghr_historical_message] m 
			  ON m.event_id		=	ev.event_id_01
			 AND m.emp_id		=	ev.emp_id_01
			 AND m.eff_date		=	ev.eff_date_01
			 
	 WHERE ev.event_id_01 = @event_id_01 AND ev.activity_status IN (@activity_status,'01')  AND	ev.activity_date =	@rundate
	 GROUP BY ev.event_id_01,  ev.emp_id_01,ev.eff_date_01, ev.pay_element_desc_06,
			  ev.first_name_01,ev.last_name_01,ev.empl_id_01,ev.emp_status_code_5,ev.annual_salary_amt_01
	 ORDER BY ev.empl_id_01

	IF	EXISTS ( SELECT * FROM [DBShrpn].[dbo].[ghr_employee_events_aud] WHERE event_id_01 = @event_id_01 AND activity_status = @activity_status)
		BEGIN
			SELECT  SPACE(30)
			SELECT	'Name Change Error Section:'
			SELECT	SPACE(30)
		
			SELECT	--CAST('Activity Description' AS CHAR(20))	+ CAST('' AS CHAR(6)) + 
					CAST('Employee' AS CHAR(12))				+ CAST('' AS CHAR(1)) +	
					CAST('Eff. Date' AS CHAR(10))				+ CAST('' AS CHAR(2)) +
--					CAST('Pay Element' AS CHAR(11))				+ CAST('' AS CHAR(1)) +				
					CAST('First Name' AS CHAR(15))				+ CAST('' AS CHAR(5)) +
					CAST('Last Name' AS CHAR(15))				+ CAST('' AS CHAR(5)) +
					CAST('Employer' AS CHAR(10))				+ CAST('' AS CHAR(4)) +
--					CAST('National Type Code' AS CHAR(15)),	
--					CAST('National Identity' AS CHAR(15)),
--					CAST('Organization Group' AS CHAR(15)),	
--					CAST('Organization Name' AS CHAR(15)),	
--					CAST('Organization Unit' AS CHAR(15)),	
--					CAST('Pay Group' AS CHAR(15))				+ CAST('' AS CHAR(5)) +	
--					CAST('Control Group' AS CHAR(15))			+ CAST('' AS CHAR(5)) +	
--					CAST('Position Title' AS CHAR(15))
					CAST('Pay Amount' AS CHAR(10))				+ CAST('' AS CHAR(1)) 
--					CAST('New Hire Messages:' AS CHAR(21))	  				
				

		SELECT @max	=	COUNT(*) FROM [DBShrpn].[dbo].[ghr_email_report];
		SELECT @cnt =	1;
		
		WHILE (@cnt <= @max)
		 BEGIN
						
			SELECT  --DISTINCT 
--					CAST(''										AS CHAR(17))	+ CAST('' AS CHAR(9)) + 
					CAST(RTRIM(emp_id_01)						AS CHAR(12))	+ CAST('' AS CHAR(1)) + 
					CAST(RTRIM(eff_date_01)						AS CHAR(10))	+ CAST('' AS CHAR(2)) + 
--					CAST(RTRIM(ev.pay_element_desc_06)			AS CHAR(15))	+ CAST('' AS CHAR(5)) + 				
					CAST(RTRIM(first_name_01)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 
					CAST(RTRIM(last_name_01)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 
					CAST(RTRIM(empl_id_01)						AS CHAR(10))	+ CAST('' AS CHAR(2)) +	
--					CAST(RTRIM(pay_group_id_03)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 	
--					CAST(RTRIM(pay_element_ctrl_grp_id_03)		AS CHAR(15))	+ CAST('' AS CHAR(5)) + 					
					CAST(RTRIM(emp_calculation_06)				AS CHAR(15))	+ CAST('' AS CHAR(1))  
--					msg_desc
--					CHAR(13) + '   ' + msg_desc
			  FROM [DBShrpn].[dbo].[ghr_email_report] 
		     WHERE [ID]	=	@cnt
		 
			SELECT @emp_id = emp_id_01, @eff_date = eff_date_01 FROM [DBShrpn].[dbo].[ghr_email_report] WHERE [ID]	=	@cnt
		
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
	END  -- End of Event 02 AND Activity Status 02			
--JAG
SET		@event_id_01	=	'05'
SET		@activity_status =  '00'

IF	EXISTS ( SELECT * FROM [DBShrpn].[dbo].[ghr_employee_events_aud] WHERE event_id_01 = @event_id_01 AND activity_status = @activity_status AND activity_date = @rundate)
	BEGIN		
		SELECT  SPACE(30)
		SELECT	'Status Change Section:'
		SELECT	SPACE(30)

			SELECT	--CAST('Activity Description' AS CHAR(20))	+ CAST('' AS CHAR(6)) + 
					CAST('Employee' AS CHAR(12))				+ CAST('' AS CHAR(1)) +	
					CAST('Eff. Date' AS CHAR(10))				+ CAST('' AS CHAR(3)) +
--					CAST('Pay Element' AS CHAR(11))				+ CAST('' AS CHAR(1)) +				
					CAST('First Name' AS CHAR(15))				+ CAST('' AS CHAR(5)) +
					CAST('Last Name' AS CHAR(15))				+ CAST('' AS CHAR(5)) +
					CAST('Employer' AS CHAR(10))				+ CAST('' AS CHAR(1)) +
					CAST('New Status' AS CHAR(11))		+ CAST('' AS CHAR(3)) +					
--					CAST('National Type Code' AS CHAR(15)),	
--					CAST('National Identity' AS CHAR(15)),
--					CAST('Organization Group' AS CHAR(15)),	
--					CAST('Organization Name' AS CHAR(15)),	
--					CAST('Organization Unit' AS CHAR(15)),	
--					CAST('Pay Group' AS CHAR(15))				+ CAST('' AS CHAR(5)) +	
--					CAST('Control Group' AS CHAR(15))			+ CAST('' AS CHAR(5)) +	
--					CAST('Position Title' AS CHAR(15))
					CAST('Pay Amount' AS CHAR(10))				+ CAST('' AS CHAR(1)) 
--					CAST('New Hire Messages:' AS CHAR(21))
				--CAST('</font>' AS CHAR(07))

--		SELECT 'Successful New Hire:'
	

		SELECT   
				---CAST('<font face=''Courier New''>' AS CHAR(27)) +
--				CAST(''										AS CHAR(17))	+ CAST('' AS CHAR(9)) + 
				CAST(RTRIM(emp_id_01)						AS CHAR(12))	+ CAST('' AS CHAR(1)) + 
				CAST(RTRIM(eff_date_01)						AS CHAR(10))	+ CAST('' AS CHAR(3)) + 
				CAST(RTRIM(first_name_01)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 
				CAST(RTRIM(last_name_01)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 
				CAST(RTRIM(empl_id_01)						AS CHAR(10))	+ CAST('' AS CHAR(1)) +  	
				CASE WHEN emp_status_code_5 = 'I'  THEN 'Inactive ' 
				     WHEN emp_status_code_5 = 'RA' THEN 'Reactive '
				     WHEN emp_status_code_5 = 'RH' THEN 'Rehire   '
				     WHEN emp_status_code_5 = 'T'  THEN 'Terminate' 
				     ELSE CAST(RTRIM(emp_status_code_5) AS CHAR(10)) 
				END	+ CAST('' AS CHAR(5)) +					
--				CAST(RTRIM(pay_group_id_03)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 	
--				CAST(RTRIM(pay_element_ctrl_grp_id_03)		AS CHAR(15))	+ CAST('' AS CHAR(5)) + 					
				CAST(RTRIM(annual_salary_amt_01)			AS CHAR(15))	+ CAST('' AS CHAR(5)) 
				--CAST('</font>' AS CHAR(07)) 				 
		  FROM [DBShrpn].[dbo].[ghr_employee_events_aud] ev 
		 WHERE event_id_01 = @event_id_01 AND activity_status = @activity_status  AND	activity_date =	@rundate
END -- End of IF Statement	



SET		@event_id_01	=	'05'
SET		@activity_status =  '02'

--
--	This section of code will proc
--
IF	EXISTS ( SELECT * FROM [DBShrpn].[dbo].[ghr_employee_events_aud] WHERE event_id_01 = @event_id_01 AND activity_status = @activity_status AND activity_date = @rundate)
	BEGIN
	IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_email_report]') AND type in (N'U'))
		DROP TABLE [dbo].[ghr_email_report]
	

	CREATE TABLE [dbo].[ghr_email_report](
		[ID]									[int]	IDENTITY(1,1) NOT NULL,
		[event_id_01]							[char](02) NULL,
		[emp_id_01]								[char](15) NULL,
		[eff_date_01]							[char](10) NULL,
		[pay_element_desc_06]					[char](20) NULL,
		first_name_01							[char](25) NULL,
		last_name_01							[char](30) NULL,
		empl_id_01								[char](10) NULL,
		emp_status_code_5                       [char](02) NULL,
		emp_calculation_06						[char](15) NULL)


	INSERT INTO [DBShrpn].[dbo].[ghr_email_report]	
	SELECT  ev.event_id_01,  ev.emp_id_01,ev.eff_date_01, ev.pay_element_desc_06,
			ev.first_name_01,ev.last_name_01,ev.empl_id_01,ev.emp_status_code_5, ev.annual_salary_amt_01
	  FROM [DBShrpn].[dbo].[ghr_employee_events_aud] ev 
	  INNER JOIN [DBShrpn].[dbo].[ghr_historical_message] m 
			  ON m.event_id		=	ev.event_id_01
			 AND m.emp_id		=	ev.emp_id_01
			 AND m.eff_date		=	ev.eff_date_01
			 
	 WHERE ev.event_id_01 = @event_id_01 AND ev.activity_status IN (@activity_status,'01')  AND	ev.activity_date =	@rundate
	 GROUP BY ev.event_id_01,  ev.emp_id_01,ev.eff_date_01, ev.pay_element_desc_06,
			  ev.first_name_01,ev.last_name_01,ev.empl_id_01,ev.emp_status_code_5,ev.annual_salary_amt_01
	 ORDER BY ev.empl_id_01

	IF	EXISTS ( SELECT * FROM [DBShrpn].[dbo].[ghr_employee_events_aud] WHERE event_id_01 = @event_id_01 AND activity_status = @activity_status AND activity_date = @rundate)
		BEGIN
			SELECT  SPACE(30)
			SELECT	'Status Change Error Section:'
			SELECT	SPACE(30)
		
			SELECT	--CAST('Activity Description' AS CHAR(20))	+ CAST('' AS CHAR(6)) + 
					CAST('Employee' AS CHAR(12))				+ CAST('' AS CHAR(1)) +	
					CAST('Eff. Date' AS CHAR(10))				+ CAST('' AS CHAR(2)) +
--					CAST('Pay Element' AS CHAR(11))				+ CAST('' AS CHAR(1)) +				
					CAST('First Name' AS CHAR(15))				+ CAST('' AS CHAR(5)) +
					CAST('Last Name' AS CHAR(15))				+ CAST('' AS CHAR(5)) +
					CAST('Employer' AS CHAR(10))				+ CAST('' AS CHAR(2)) +
					CAST('New Status' AS CHAR(11))				+ CAST('' AS CHAR(3)) +						
--					CAST('National Type Code' AS CHAR(15)),	
--					CAST('National Identity' AS CHAR(15)),
--					CAST('Organization Group' AS CHAR(15)),	
--					CAST('Organization Name' AS CHAR(15)),	
--					CAST('Organization Unit' AS CHAR(15)),	
--					CAST('Pay Group' AS CHAR(15))				+ CAST('' AS CHAR(5)) +	
--					CAST('Control Group' AS CHAR(15))			+ CAST('' AS CHAR(5)) +	
--					CAST('Position Title' AS CHAR(15))
					CAST('Pay Amount' AS CHAR(10))				+ CAST('' AS CHAR(1)) 
--					CAST('New Hire Messages:' AS CHAR(21))	  				
				

		SELECT @max	=	COUNT(*) FROM [DBShrpn].[dbo].[ghr_email_report];
		SELECT @cnt =	1;
		
		WHILE (@cnt <= @max)
		 BEGIN
						
			SELECT  --DISTINCT 
--					CAST(''										AS CHAR(17))	+ CAST('' AS CHAR(9)) + 
					CAST(RTRIM(emp_id_01)						AS CHAR(12))	+ CAST('' AS CHAR(1)) + 
					CAST(RTRIM(eff_date_01)						AS CHAR(10))	+ CAST('' AS CHAR(2)) + 
--					CAST(RTRIM(ev.pay_element_desc_06)			AS CHAR(15))	+ CAST('' AS CHAR(5)) + 				
					CAST(RTRIM(first_name_01)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 
					CAST(RTRIM(last_name_01)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 
					CAST(RTRIM(empl_id_01)						AS CHAR(10))	+ CAST('' AS CHAR(2)) +	
					CASE WHEN emp_status_code_5 = 'I'  THEN 'Inactive ' 
				         WHEN emp_status_code_5 = 'RA' THEN 'Reactive '
				         WHEN emp_status_code_5 = 'RH' THEN 'Rehire   '
				         WHEN emp_status_code_5 = 'T'  THEN 'Terminate' 
				         ELSE CAST(RTRIM(emp_status_code_5) AS CHAR(10)) 
				END	+ CAST('' AS CHAR(5)) +
--					CAST(RTRIM(pay_group_id_03)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 	
--					CAST(RTRIM(pay_element_ctrl_grp_id_03)		AS CHAR(15))	+ CAST('' AS CHAR(5)) + 					
					CAST(RTRIM(emp_calculation_06)				AS CHAR(15))	+ CAST('' AS CHAR(1))  
--					msg_desc
--					CHAR(13) + '   ' + msg_desc
--					SELECT *
			  FROM [DBShrpn].[dbo].[ghr_email_report] 
		     WHERE [ID]	=	@cnt
	 
			SELECT @emp_id = emp_id_01, @eff_date = eff_date_01 FROM [DBShrpn].[dbo].[ghr_email_report] WHERE [ID]	=	@cnt
		
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
	END  -- End of Event 05 AND Activity Status 02	

--JAG
SET		@event_id_01	=	'06'
SET		@activity_status =  '00'

IF	EXISTS ( SELECT * FROM [DBShrpn].[dbo].[ghr_employee_events_aud] WHERE event_id_01 = @event_id_01 AND activity_status = @activity_status AND activity_date = @rundate)
	BEGIN		
		SELECT  SPACE(30)
		SELECT	'Pay Element Section:'
		SELECT	SPACE(30)

		SELECT	--CAST('<font face=''Courier New''>' AS CHAR(27)) +
--				CAST('Activity Description' AS CHAR(20))	+ CAST('' AS CHAR(6)) + 
				CAST('Employee' AS CHAR(12))				+ CAST('' AS CHAR(1)) +	
				CAST('Eff. Date' AS CHAR(10))				+ CAST('' AS CHAR(1)) +
				CAST('First Name' AS CHAR(15))				+ CAST('' AS CHAR(5)) +
				CAST('Last Name' AS CHAR(15))				+ CAST('' AS CHAR(5)) +
				CAST('Employer' AS CHAR(10))				+ CAST('' AS CHAR(1)) + 
				CAST('Pay Element Id' AS CHAR(15))			+ CAST('' AS CHAR(1)) + 				
--				CAST('National Type Code' AS CHAR(15)),	
--				CAST('National Identity' AS CHAR(15)),
--				CAST('Organization Group' AS CHAR(15)),	
--				CAST('Organization Name' AS CHAR(15)),	
--				CAST('Organization Unit' AS CHAR(15)),	
--				CAST('Pay Group' AS CHAR(15))				+ CAST('' AS CHAR(5)) +	
--				CAST('Control Group' AS CHAR(15))			+ CAST('' AS CHAR(5)) +	
--				CAST('Position Title' AS CHAR(15))
				CAST('Pay Amount' AS CHAR(15))				+ CAST('' AS CHAR(5))   
				--CAST('</font>' AS CHAR(07)) 

--		SELECT 'Successful Employees:'
	

		SELECT  
				---CAST('<font face=''Courier New''>' AS CHAR(27)) +
--				CAST(''										AS CHAR(17))	+ CAST('' AS CHAR(9)) + 
				CAST(RTRIM(emp_id_01)						AS CHAR(12))	+ CAST('' AS CHAR(1)) + 
				CAST(RTRIM(eff_date_01)						AS CHAR(10))	+ CAST('' AS CHAR(1)) + 
				CAST(RTRIM(first_name_01)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 
				CAST(RTRIM(last_name_01)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 
				CAST(RTRIM(empl_id_01)						AS CHAR(10))	+ CAST('' AS CHAR(1)) +
				CAST(ev.pay_element_desc_06					AS CHAR(11))	+ CAST('' AS CHAR(5)) + 					
--				CAST(RTRIM(pay_group_id_03)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 	
--				CAST(RTRIM(pay_element_ctrl_grp_id_03)		AS CHAR(15))	+ CAST('' AS CHAR(5)) + 					
				CAST(RTRIM(emp_calculation_06)				AS CHAR(15))	+ CAST('' AS CHAR(5)) 
				--CAST('</font>' AS CHAR(07)) 				 
		  FROM [DBShrpn].[dbo].[ghr_employee_events_aud] ev 
		 WHERE event_id_01 = '06' AND activity_status = '00'  AND	activity_date =	@rundate
	END -- End of IF Statement 1st		


SET		@event_id_01	=	'06'
SET		@activity_status =  '02'

--
--	This section of code will proc
--

IF	EXISTS ( SELECT * FROM [DBShrpn].[dbo].[ghr_employee_events_aud] WHERE event_id_01 = @event_id_01 AND activity_status = @activity_status AND activity_date = @rundate)	
	BEGIN
	IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_email_report]') AND type in (N'U'))
		DROP TABLE [dbo].[ghr_email_report]
	

	CREATE TABLE [dbo].[ghr_email_report](
		[ID]									[int]	IDENTITY(1,1) NOT NULL,
		[event_id_01]							[char](02) NULL,
		[emp_id_01]								[char](15) NULL,
		[eff_date_01]							[char](10) NULL,
		[pay_element_desc_06]					[char](20) NULL,
		first_name_01							[char](25) NULL,
		last_name_01							[char](30) NULL,
		empl_id_01								[char](10) NULL,
		emp_status_code_5                       [char](02) NULL,		
		emp_calculation_06						[char](15) NULL)


	INSERT INTO [DBShrpn].[dbo].[ghr_email_report]	
	SELECT  ev.event_id_01,  ev.emp_id_01,ev.eff_date_01, ev.pay_element_desc_06,
			ev.first_name_01,ev.last_name_01,ev.empl_id_01,ev.emp_status_code_5,ev.emp_calculation_06
	  FROM [DBShrpn].[dbo].[ghr_employee_events_aud] ev
	  	  INNER JOIN [DBShrpn].[dbo].[ghr_historical_message] m 
			  ON m.event_id		=	ev.event_id_01
			 AND m.emp_id		=	ev.emp_id_01
			 AND m.eff_date		=	ev.eff_date_01 
	 WHERE ev.event_id_01 = @event_id_01 AND ev.activity_status IN (@activity_status,'01')  AND	ev.activity_date =	@rundate 
	 GROUP BY ev.event_id_01,  ev.emp_id_01,ev.eff_date_01, ev.pay_element_desc_06,
			  ev.first_name_01,ev.last_name_01,ev.empl_id_01,ev.emp_status_code_5,ev.emp_calculation_06
	 ORDER BY ev.empl_id_01

	IF	EXISTS ( SELECT * FROM [DBShrpn].[dbo].[ghr_employee_events_aud] WHERE event_id_01 = @event_id_01 AND activity_status = @activity_status)
		BEGIN
			SELECT  SPACE(30)
			SELECT	'Pay Element in Errors Section:'
			SELECT	SPACE(30)
		
		SELECT	--CAST('Activity Description' AS CHAR(20))	+ CAST('' AS CHAR(6)) + 
				CAST('Employee' AS CHAR(12))				+ CAST('' AS CHAR(1)) +	
				CAST('Eff. Date' AS CHAR(10))				+ CAST('' AS CHAR(1)) +
				CAST('Pay Element' AS CHAR(11))				+ CAST('' AS CHAR(2)) +				
--				CAST('First_Name' AS CHAR(15))				+ CAST('' AS CHAR(5)) +
--				CAST('Last_Name' AS CHAR(15))				+ CAST('' AS CHAR(5)) +
--				CAST('Employer' AS CHAR(15))				+ CAST('' AS CHAR(5)) +
--				CAST('National Type Code' AS CHAR(15)),	
--				CAST('National Identity' AS CHAR(15)),
--				CAST('Organization Group' AS CHAR(15)),	
--				CAST('Organization Name' AS CHAR(15)),	
--				CAST('Organization Unit' AS CHAR(15)),	
--				CAST('Pay Group' AS CHAR(15))				+ CAST('' AS CHAR(5)) +	
--				CAST('Control Group' AS CHAR(15))			+ CAST('' AS CHAR(5)) +	
--				CAST('Position Title' AS CHAR(15))
				CAST('Pay Amount' AS CHAR(10))				+ CAST('' AS CHAR(1)) 
--				CAST('Pay Element Messages:' AS CHAR(21))
				

		SELECT @max	=	COUNT(*) FROM [DBShrpn].[dbo].[ghr_email_report];
		SELECT @cnt =	1;
		
		WHILE (@cnt <= @max)
		 BEGIN
						
		SELECT  DISTINCT 
--				CAST(''										AS CHAR(17))	+ CAST('' AS CHAR(9)) + 
				CAST(RTRIM(emp_id_01)						AS CHAR(12))	+ CAST('' AS CHAR(1)) + 
				CAST(RTRIM(eff_date_01)						AS CHAR(10))	+ CAST('' AS CHAR(1)) + 
				CAST(RTRIM(pay_element_desc_06)				AS CHAR(12))	+ CAST('' AS CHAR(1)) + 				
--				CAST(RTRIM(first_name_01)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 
--				CAST(RTRIM(last_name_01)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 
--				CAST(RTRIM(empl_id_01)						AS CHAR(15))	+ CAST('' AS CHAR(5)) + 	
--				CAST(RTRIM(pay_group_id_03)					AS CHAR(15))	+ CAST('' AS CHAR(5)) + 	
--				CAST(RTRIM(pay_element_ctrl_grp_id_03)		AS CHAR(15))	+ CAST('' AS CHAR(5)) + 					
				CAST(RTRIM(emp_calculation_06)				AS CHAR(05))	+ CAST('' AS CHAR(6))  
--				CHAR(13) + '   ' + msg_desc
			  FROM [DBShrpn].[dbo].[ghr_email_report] 
		     WHERE [ID]	=	@cnt
		 
			SELECT @emp_id = emp_id_01, @eff_date = eff_date_01 FROM [DBShrpn].[dbo].[ghr_email_report] WHERE [ID]	=	@cnt
		
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
	END  -- End of Event 06 AND Activity Status 02		

SELECT SPACE(1)
SELECT SPACE(0)
SELECT 'End of mail message.'
SELECT '    '
SELECT 'IPM.MICROSOFT'
SELECT 'GHR'
SELECT 'TO:jgross@smartsi.com + SMTP:jgross@smartsi.com; TO:shirlyn.Decoteau@gov.gd + SMTP:shirlyn.Decoteau@gov.gd; TO:denee.toussaint@dpa.gov.gd + SMTP:denee.toussaint@dpa.gov.gd; TO:sao-psc@gov.gd + SMTP:sao-psc@gov.gd; TO:rachel.brizan@mof.gov.gd + SMTP:rachel.brizan@mof.gov.gd; TO:dorran.strachan@gov.gd + SMTP:dorran.strachan@gov.gd'
END  -- End of SP
 
GO
ALTER AUTHORIZATION ON [dbo].[usp_verification_rpt] TO  SCHEMA OWNER 
GO
