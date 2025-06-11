USE [DBShrpn]
GO
/****** Object:  StoredProcedure [dbo].[usp_pay_check_deduction]    Script Date: 4/1/2025 4:33:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE procedure [dbo].[usp_pay_check_deduction]
AS
BEGIN
  SET NOCOUNT ON
  DECLARE @max				INT
  DECLARE @cnt				INT
  DECLARE @ncnt				INT 
  DECLARE @skey				INT 
  DECLARE @oldchk			[char](10)
  DECLARE @newchk			[char](10)
  DECLARE @end_of_period	datetime 
--
-- Pay Check Deduction
--
--
--	EXEC [dbo].[usp_pay_check_deduction]
--  

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_deduction_temp]') AND type in (N'U'))
DROP TABLE [dbo].[ghr_deduction_temp]

CREATE TABLE [dbo].[ghr_deduction_temp](
	[ID]						[int] IDENTITY(1,1) NOT NULL,
	[EffectiveDate]				[char](30)			NULL,
	[HROrganization]			[varchar](3)	NOT NULL,
	[Employee]					[varchar](15)	NOT NULL,
	[CheckDate]					[char](30)			NULL,
	[CheckID]					[char](10)		NOT NULL,
	[Deduction]					[varchar](1)	NOT NULL,
--	[DeductionType]				[varchar](1)	NOT NULL,
	[DeductionCode]				[varchar](15)	NOT NULL,
	[DeductionCodeDescription]	[varchar](35)	NOT NULL,
	[DeductionAmount]			[char](10)			NULL,
	[YearToDateDeductionAmount] [char](10)			NULL
) ON [PRIMARY]

CREATE UNIQUE CLUSTERED INDEX [skey] ON [dbo].[ghr_deduction_temp] 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]

--
--	Create the Header Record
--

SELECT  'HDR'						AS	EffectiveDate,
		'HDR0'						AS	HROrganization,
		'HDR1'						AS	Employee,
		'HDR2'						AS	CheckDate,
		'HDR3'						AS	CheckID,
		'HDR4'						AS	Deduction,
--		'HDR5'						AS	DeductionType, 
		'HDR6'						AS	DeductionCode,
		'HDR7'						AS	DeductionCodeDescription,
		'HDR8'						AS	DeductionAmount,
		'HDR9'						AS	YearToDateDeductionAmount

--
--
--
--
SELECT  @end_of_period = ep.pay_pd_end_date
--  SELECT *
 FROM	[DBShrpn].[dbo].[ghr_emp_pmt_sumn_temp] ep
 WHERE ID = 1

   
INSERT   INTO DBShrpn.dbo.ghr_deduction_temp
SELECT  --TOP 100
		--CONVERT(CHAR,DATEADD(dd, -1, DATEADD(mm, DATEDIFF(mm, 0, e.check_date) + 1, 0)),112) AS	EffectiveDate,
		CONVERT(CHAR,@end_of_period,112) AS	EffectiveDate,
		'GOG'	AS	HROrganization,
		d.emp_id					AS	Employee,
		CONVERT(CHAR,e.check_date,112)				AS	CheckDate,
		e.check_nbr					AS	CheckID,
		''							AS	Deduction,
--		d.pay_element_type_code		AS	DeductionType, 
		d.pay_element_id			AS	DeductionCode,
		d.pay_element_descp			AS	DeductionCodeDescription,
		CAST(d.calc_monetary_amt    AS CHAR(10))			AS	DeductionAmount,
		CAST(d.ytd_monetary_amt     AS CHAR(10))			AS	YearToDateDeductionAmount
--   SELECT *		 
  FROM DBShrpy.dbo.ghr_emp_pmt_pay_element_detail_sum d
 INNER JOIN	(SELECT [emp_id],[payroll_run_type_id],[pay_pd_id],[pmt_seq_nbr],[check_date],[check_nbr]	FROM DBShrpn.dbo.ghr_emp_pmt_sumn_temp) e
						ON	e.[emp_id]					=	d.[emp_id]
						AND e.[payroll_run_type_id]		=	d.[payroll_run_type_id]
						AND e.[pay_pd_id]				=	d.[pay_pd_id]
						AND e.[pmt_seq_nbr]				=	d.[pmt_seq_nbr]
  WHERE	d.pay_element_type_code = '2' AND d.pay_element_descp <> 'Net Pay'
  ORDER BY e.check_nbr
  
  SELECT @max		=  COUNT(*) FROM DBShrpn.dbo.ghr_deduction_temp 
  
  SELECT @oldchk	=   CheckID FROM DBShrpn.dbo.ghr_deduction_temp WHERE	[ID] = 1
  SELECT @newchk	=	@oldchk	
  SELECT @cnt =1
  SELECT @ncnt = 1
  
  WHILE (@cnt < @max)
  BEGIN
	
	SELECT @skey = ID, @oldchk = CheckID FROM DBShrpn.dbo.ghr_deduction_temp WHERE	[ID] = @cnt

 	IF @oldchk <> @newchk 
 	BEGIN
 	
 		SELECT @ncnt = 1,	@newchk = @oldchk	
 		UPDATE DBShrpn.dbo.ghr_deduction_temp SET Deduction = CONVERT(CHAR(1),@ncnt)   WHERE [ID] = @skey
 		SELECT @ncnt = @ncnt + 1	
	
     END  
     ELSE
     BEGIN
     	UPDATE DBShrpn.dbo.ghr_deduction_temp SET Deduction = CONVERT(CHAR(1),@ncnt)   WHERE [ID] = @skey
		SELECT @ncnt = @ncnt + 1
		
		
	 END
				
 	SELECT @cnt = @cnt + 1	
	
	
  END -- End of While
  
  SELECT * FROM DBShrpn.dbo.ghr_deduction_temp
  
  END	-- End of Proc	  



--     
 
GO
ALTER AUTHORIZATION ON [dbo].[usp_pay_check_deduction] TO  SCHEMA OWNER 
GO
