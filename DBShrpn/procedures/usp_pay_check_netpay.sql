USE [DBShrpn]
GO
/****** Object:  StoredProcedure [dbo].[usp_pay_check_netpay]    Script Date: 4/1/2025 4:33:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE procedure [dbo].[usp_pay_check_netpay]
AS
BEGIN
--
-- Pay Check Net Pay
--
--
--	EXEC [dbo].[usp_pay_check_netpay]
--
DECLARE @next_avail_check_nbr	INT
DECLARE	@tot_check_nbr			INT
DECLARE @max_check_nbr			INT

IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_emp_pmt_sumn_temp]') AND type in (N'U'))
	DROP TABLE [dbo].[ghr_emp_pmt_sumn_temp]
	
CREATE TABLE [DBShrpn].[dbo].[ghr_emp_pmt_sumn_temp] (
	[ID]									[int]	IDENTITY(1,1) NOT NULL,
	[emp_id] [varchar](15) NOT NULL,
	[last_name] [varchar](25) NOT NULL,
	[first_name] [varchar](25) NOT NULL,
	[emp_name_ext] [varchar](100) NOT NULL,
	[emp_name] [varchar](45) NOT NULL,
	[payroll_run_type_id] [varchar](10) NOT NULL,
	[pay_pd_id] [varchar](10) NOT NULL,
	[pmt_seq_nbr] [int] NOT NULL,
	[deposit_check_code] [char](1) NOT NULL,
	[title] [varchar](80) NOT NULL,
	[empl_id] [varchar](10) NOT NULL,
	[empl_name] [varchar](45) NOT NULL,
	[empl_bank_id] [char](11) NOT NULL,
	[bank_name] [varchar](30) NOT NULL,
	[branch_name] [varchar](70) NOT NULL,
	[bank_nbr] [varchar](17) NOT NULL,
	[organization_unit_name] [varchar](20) NOT NULL,
	[org_unit_desc] [varchar](50) NOT NULL,
	[empl_bank_account] [char](10) NOT NULL,
	[check_nbr] [char](9) NOT NULL,
	[check_date] [datetime] NOT NULL,
	[pay_area] [varchar](4) NOT NULL,
	[pay_group_id] [varchar](10) NOT NULL,
	[pay_pd_begin_date] [datetime] NOT NULL,
	[pay_pd_end_date] [datetime] NOT NULL,
	[pmt_next_eff_date] [datetime] NOT NULL,
	[pmt_pay_grade_code] [varchar](6) NOT NULL,
	[pmt_check_amt] [money] NOT NULL,
	[pmt_annual_salary] [money] NOT NULL,
	[pmt_tot_salary_and_taxable] [money] NOT NULL,
	[pmt_tot_non_taxable] [money] NOT NULL,
	[pmt_tot_deductions_wh_amt] [money] NOT NULL,
	[pmt_net_pay_amt] [money] NOT NULL,
	[pmt_direct_deposits] [money] NOT NULL,
	[pmt_ytd_tot_gross_pay_amt] [money] NOT NULL,
	[pmt_ytd_tot_deductions_wh_amt] [money] NOT NULL,
	[pmt_ytd_net_pay_amt] [money] NOT NULL,
	[pmt_1st_tot_gross_pay_amt] [money] NOT NULL,
	[pmt_1st_taxable_pay_to_date] [money] NOT NULL,
	[pmt_1st_tax_deducted_to_date] [money] NOT NULL
)
SELECT * FROM [DBShrpn].[dbo].[ghr_emp_pmt_sumn_temp]
INSERT INTO [DBShrpn].[dbo].[ghr_emp_pmt_sumn_temp]
SELECT * 
  FROM DBShrpy.dbo.ghr_emp_pmt_sum

SELECT @next_avail_check_nbr	=	[begin_ref_nbr]
--	SELECT *
  FROM [DBSbank].[dbo].[pmt_ref_ctrl] WHERE bank_id = 'PAYSLIP' AND [bank_acct_nbr] = '9999999' AND type_of_pmt = 'CHK' AND pmt_meth_id = 'PAYSL'

UPDATE [DBShrpn].[dbo].[ghr_emp_pmt_sumn_temp]
   SET [check_nbr] = CONVERT(CHAR(09),(@next_avail_check_nbr + ID))
   
SELECT @max_check_nbr	=	MAX(CONVERT(INT,check_nbr)) FROM [DBShrpn].[dbo].[ghr_emp_pmt_sumn_temp] 


UPDATE [DBSbank].[dbo].[pmt_ref_ctrl] 
   SET [begin_ref_nbr] = @max_check_nbr
 WHERE bank_id = 'PAYSLIP' AND [bank_acct_nbr] = '9999999' AND type_of_pmt = 'CHK' AND pmt_meth_id = 'PAYSL' 
 

--
--	Create the Header Record
--
SELECT  'HDR'									AS	EffectiveDate,
		'HDR0'									AS	HROrganization,
		'HDR1'									AS	Employee,
		'HDR2'									AS	CheckDate,
		'HDR3'									AS	CheckId,
		'HDR4'									AS  CheckNumber,
		'HDR5'									AS  PayPeriodDateRangeBegin,	
		'HDR6'									AS  PayPeriodDateRangeEnd,	
		'HDR7'									AS	NetPayAmount,	
		'HDR8'									AS	YearToDateNetPay,	
		'HDR9'									AS	CheckNetAmount,	
		'HDR10'									AS	YearToDateCheckNet,	
		'HDR11'									AS	GrossPayAmount,	
		'HDR12'									AS	YearToDateGrossPay,	
		'HDR13'									AS	TotalCompanyDeductions,	
		'HDR14'									AS	TotalOtherDeductions,	
		'HDR15'									AS	NonEarnings,
		'HDR16'									AS	TotalCheckDeductions,	
		'HDR17'									AS	TotalTaxDeductions,	
		'HDR18'									AS	TotalYearToDateDeductions,
		'HDR19'									AS	ViewEmployeePayCheckCheckID,
		'HDR20'									AS	CheckType
		
--
--	Create the Data Reords
--		 
SELECT  CONVERT(CHAR,pay_pd_end_date,112)													AS	EffectiveDate,
		'GOG'																				AS	HROrganization,
		ep.emp_id																			AS	Employee,
		CONVERT(CHAR,check_date,112)														AS	CheckDate,
		check_nbr																			AS	CheckId,
		''																					AS  CheckNumber,
		CONVERT(CHAR,pay_pd_begin_date,112)													AS  PayPeriodDateRangeBegin,	
		CONVERT(CHAR,pay_pd_end_date,112)													AS  PayPeriodDateRangeEnd,	
		CAST(pmt_net_pay_amt				AS CHAR(10))									AS	NetPayAmount,	
		CAST(pmt_ytd_net_pay_amt			AS CHAR(10))									AS	YearToDateNetPay,	
		CAST(pmt_check_amt					AS CHAR(10))									AS	CheckNetAmount,	
		CAST(pmt_ytd_net_pay_amt			AS CHAR(10))									AS	YearToDateCheckNet,	
		CAST(pmt_1st_tot_gross_pay_amt		AS CHAR(10))									AS	GrossPayAmount,	
		CAST(pmt_ytd_tot_gross_pay_amt		AS CHAR(10))									AS	YearToDateGrossPay,	
		''																					AS	TotalCompanyDeductions,	
		CAST(pmt_tot_deductions_wh_amt		AS CHAR(10))									AS	TotalOtherDeductions,	
		''																					AS	NonEarnings,
		CAST(pmt_tot_deductions_wh_amt		AS CHAR(10))									AS	TotalCheckDeductions,	
		CAST(pmt_tot_deductions_wh_amt		AS CHAR(10))									AS	TotalTaxDeductions,	
		CAST(pmt_ytd_tot_deductions_wh_amt	AS CHAR(10))									AS	TotalYearToDateDeductions,
		''																					AS	ViewEmployeePayCheckCheckID,
		''																					AS	CheckType
		--  SELECT ep.*
 FROM	[DBShrpn].[dbo].[ghr_emp_pmt_sumn_temp] ep
 INNER JOIN [DBShrpy].[dbo].[emp_pmt_disbursal_detail]  dd
    ON dd.emp_id				=	ep.emp_id
   AND dd.payroll_run_type_id	=	ep.payroll_run_type_id
   AND dd.pay_pd_id				=	ep.pay_pd_id 
   AND dd.pmt_seq_nbr			=	ep.pmt_seq_nbr 
   AND dd.doc_disbursal_status_code = '05'

  END  --End of Proc	  



 
GO
ALTER AUTHORIZATION ON [dbo].[usp_pay_check_netpay] TO  SCHEMA OWNER 
GO
