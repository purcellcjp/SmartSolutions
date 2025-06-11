USE [DBShrpn]
GO
/****** Object:  StoredProcedure [dbo].[usp_pay_check_earndeduct]    Script Date: 4/1/2025 4:33:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE procedure [dbo].[usp_pay_check_earndeduct]
AS
BEGIN
--
-- Pay Check Earning and deductions
--

--
--	Create the Header Record
--
SELECT  'HDR'						AS	HROrganization,
		'HDR0'						AS	Employee,
		'HDR1'						AS	CheckDate,
		'HDR2'						AS	CheckID,
		'HDR3'						AS	FlagEarningDeduction,
		'HDR4'						AS	[Description],
--		'HDR5'						AS	[Hours], 
		'HDR6'						AS	Earning,
		'HDR7'						AS	Deduction
		
--
--	EXEC [dbo].[usp_pay_check_earndeduct]
--

SELECT  
		'GOG'							AS	HROrganization,
		d.emp_id						AS	Employee,
		CONVERT(CHAR,e.check_date,112)	AS	CheckDate,
		e.check_nbr						AS	CheckID,
		CASE WHEN d.pay_element_type_code = 1 THEN 'E' 								
			 WHEN d.pay_element_type_code = 2 THEN 'D'	END AS	FlagEarningDeduction,
		d.pay_element_descp				AS	[Description],
--		''								AS	[Hours],		
		CASE WHEN d.pay_element_type_code = 1 THEN LTRIM(CAST(d.calc_monetary_amt AS CHAR(10)))
			 ELSE CAST('0.00'			AS CHAR(10))					    END	AS	Earning,
		CASE WHEN d.pay_element_type_code = 2 THEN LTRIM(CAST(d.calc_monetary_amt AS CHAR(10))) 								
			 ELSE CAST('0.00'			AS CHAR(10))					    END	AS	Deduction 	  
  FROM DBShrpy.dbo.ghr_emp_pmt_pay_element_detail_sum d
 INNER JOIN	(
             SELECT [emp_id],[payroll_run_type_id],[pay_pd_id],[pmt_seq_nbr],[check_date],[pay_pd_begin_date],[pay_pd_end_date],[check_nbr]	
             FROM DBShrpn.dbo.ghr_emp_pmt_sumn_temp
			) e
						ON	e.[emp_id]					=	d.[emp_id]
						AND e.[payroll_run_type_id]		=	d.[payroll_run_type_id]
						AND e.[pay_pd_id]				=	d.[pay_pd_id]
						AND e.[pmt_seq_nbr]				=	d.[pmt_seq_nbr]
  WHERE	d.pay_element_type_code in ('1','2') AND d.pay_element_descp <> 'Net Pay'
  ORDER BY e.check_nbr, d.pay_element_type_code
  
  END	  



 
GO
ALTER AUTHORIZATION ON [dbo].[usp_pay_check_earndeduct] TO  SCHEMA OWNER 
GO
