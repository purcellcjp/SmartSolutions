USE [DBShrpn]
GO
/****** Object:  StoredProcedure [dbo].[usp_pay_check_earnings]    Script Date: 4/1/2025 4:33:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE procedure [dbo].[usp_pay_check_earnings]
AS
BEGIN
  SET NOCOUNT ON
  DECLARE @max			INT
  DECLARE @cnt			INT
  DECLARE @ncnt			INT 
  DECLARE @skey			INT 
  DECLARE @oldchk		[char](10)
  DECLARE @newchk		[char](10)
--
-- Pay Check Earning
--
--
--	EXEC [dbo].[usp_pay_check_earnings]
--
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_earnings_temp]') AND type in (N'U'))
DROP TABLE [dbo].[ghr_earnings_temp]

CREATE TABLE [dbo].[ghr_earnings_temp](
	[ID]								[int] IDENTITY(1,1) NOT NULL,
	[HROrganization]					[varchar](3)		NOT NULL,
	[Employee]							[varchar](15)		NOT NULL,
	[CheckDate]							[char](30)				NULL,
	[CheckID]							[char](9)			NOT NULL,
	[CheckEarning]						[varchar](1)		NOT NULL,
	[earningsdescp]						[varchar](35)		NOT NULL,
	[Hours]								[varchar](1)		NOT NULL,
	[EarningsAmount]					[char](10)				NULL,
	[PayPeriodDateRangeBegin]			[char](30)				NULL,
	[PayPeriodDateRangeEnd]				[char](30)				NULL,
	[YearToDateEarningsAmount]			[char](10)				NULL,
	[YearToDateHours]					[varchar](1)		NOT NULL,
	[EffectiveDate]						[char](30)				NULL
) ON [PRIMARY]	

CREATE UNIQUE CLUSTERED INDEX [skey] ON [dbo].[ghr_earnings_temp] 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]

--
--	Create the Header Record
--
SELECT  
		'HDR'							AS	HROrganization,
		'HDR0'							AS	Employee,
		'HDR1'							AS	CheckDate,
		'HDR2'							AS	CheckID,
		'HDR3'							AS	CheckEarning,
		'HDR4'							AS	earningsdescp,
		'HDR5'							AS	[Hours],
		'HDR6'							AS	EarningsAmount,
		'HDR7'							AS	PayPeriodDateRangeBegin,
		'HDR8'							AS	PayPeriodDateRangeEnd,
		'HDR9'							AS	YearToDateEarningsAmount,
		'HDR10'							AS	YearToDateHours,
		'HDR11'							AS	EffectiveDate
		
--
--	EXEC [dbo].[usp_pay_check_earnings]
--

INSERT INTO DBShrpn.dbo.ghr_earnings_temp 
SELECT 
		'GOG'		AS	HROrganization,
		d.emp_id						AS	Employee,
		CONVERT(CHAR,e.check_date,112)	AS	CheckDate,
		e.check_nbr						AS	CheckID,
		''								AS	CheckEarning,
		d.pay_element_descp				AS	earningsdescp,
		''								AS	[Hours],
		CAST(d.calc_monetary_amt		AS CHAR(10))			AS	EarningsAmount,
		CONVERT(CHAR,e.pay_pd_begin_date,112)					AS PayPeriodDateRangeBegin,
		CONVERT(CHAR,e.pay_pd_end_date,112)						AS PayPeriodDateRangeEnd,
		CAST(d.ytd_monetary_amt			AS CHAR(10))			AS	YearToDateEarningsAmount,
		''								AS	YearToDateHours,
		CONVERT(CHAR,DATEADD(dd, -1, DATEADD(mm, DATEDIFF(mm, 0, e.check_date) + 1, 0)),112) AS	EffectiveDate
	 
  FROM DBShrpy.dbo.ghr_emp_pmt_pay_element_detail_sum d
 INNER JOIN	(
             SELECT [emp_id],[payroll_run_type_id],[pay_pd_id],[pmt_seq_nbr],[check_date],[pay_pd_begin_date],[pay_pd_end_date],[check_nbr]	
             FROM DBShrpn.dbo.ghr_emp_pmt_sumn_temp
			) e
						ON	e.[emp_id]					=	d.[emp_id]
						AND e.[payroll_run_type_id]		=	d.[payroll_run_type_id]
						AND e.[pay_pd_id]				=	d.[pay_pd_id]
						AND e.[pmt_seq_nbr]				=	d.[pmt_seq_nbr]
  WHERE	d.pay_element_type_code = '1' 
  ORDER BY e.check_nbr
  
  SELECT @max		=  COUNT(*) FROM DBShrpn.dbo.ghr_earnings_temp 
  
  SELECT @oldchk	=   CheckID FROM DBShrpn.dbo.ghr_earnings_temp  WHERE	[ID] = 1
  SELECT @newchk	=	@oldchk	
  SELECT @cnt =1
  SELECT @ncnt = 1
  
  WHILE (@cnt < @max)
  BEGIN
	
	SELECT @skey = ID, @oldchk = CheckID FROM DBShrpn.dbo.ghr_earnings_temp  WHERE	[ID] = @cnt

 	IF @oldchk <> @newchk 
 	BEGIN
 	
 		SELECT @ncnt = 1,	@newchk = @oldchk	
 		UPDATE DBShrpn.dbo.ghr_earnings_temp  SET CheckEarning = CONVERT(CHAR(1),@ncnt)   WHERE [ID] = @skey
 		SELECT @ncnt = @ncnt + 1	
	
     END  
     ELSE
     BEGIN
     	UPDATE DBShrpn.dbo.ghr_earnings_temp  SET CheckEarning = CONVERT(CHAR(1),@ncnt)   WHERE [ID] = @skey
		SELECT @ncnt = @ncnt + 1
		
		
	 END
				
 	SELECT @cnt = @cnt + 1	
	
	
  END	-- End of While
  
  SELECT * FROM DBShrpn.dbo.ghr_earnings_temp
  
  END	-- End of Proc	  



 
GO
ALTER AUTHORIZATION ON [dbo].[usp_pay_check_earnings] TO  SCHEMA OWNER 
GO
