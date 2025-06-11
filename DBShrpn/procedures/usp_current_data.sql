USE [DBShrpn]
GO
/****** Object:  StoredProcedure [dbo].[usp_current_data]    Script Date: 4/1/2025 4:33:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE procedure [dbo].[usp_current_data]
AS
BEGIN

IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_current_temp1]') AND type in (N'U'))
	DROP TABLE [dbo].[ghr_current_temp1]

SELECT	e.emp_id					AS [Employee_Number],
		i.first_name				AS [First_Name],
		i.first_middle_name			AS [Middle_Name], 
		i.last_name					AS [Last_Name],  
		ee.empl_id					AS [Employer], 
		p.national_id_1_type_code	AS [National_Id_Type], 
		p.national_id_1				AS [National_Id_Nbr],
		p.user_text_1				AS [Position Title],
		ea.organization_unit_name	AS [rganization_Unit_name], 
		ea.annual_salary_amt		AS [Annual_Salary],
        ee.time_reporting_meth_code	AS [Time_Reporting_Method],
        ee.pay_element_ctrl_grp_id	AS [Pay_Element_Ctrl_Group], 
        ee.pay_group_id				AS [Pay_Group],
        ee.pay_status_code			AS [Pay_Status],
        ee.pay_through_date			AS [Pay_Through_Date],
        es.hire_date				AS [Hire_Date],
        CASE WHEN pt.title IS NOT NULL	THEN pt.title
             ELSE jt.title		END AS [Original Job_Position_Title],
        es.emp_status_code			AS [Employee Status]
INTO  DBShrpn.dbo.ghr_current_temp1
FROM  DBShrpn.dbo.employee e
INNER JOIN [DBShrpn].[dbo].[individual] i ON i.individual_id = e.individual_id
INNER JOIN [DBShrpn].[dbo].[individual_personal] p ON p.individual_id = e.individual_id
INNER JOIN [DBShrpn].[dbo].[emp_employment] ee ON ee.emp_id = e.emp_id AND ee.eff_date = (SELECT MAX(eff_date) FROM DBShrpn.dbo.emp_employment t WHERE t.emp_id = ee.emp_id AND t.eff_date <= GETDATE())
INNER JOIN [DBShrpn].[dbo].[emp_assignment] ea ON ea.emp_id = e.emp_id AND ea.eff_date = (SELECT MAX(eff_date) FROM DBShrpn.dbo.emp_assignment t WHERE t.emp_id = ea.emp_id AND t.prime_assignment_ind = 'Y' AND t.eff_date <= GETDATE()) AND ea.prime_assignment_ind = 'Y' AND end_date > GETDATE()
INNER JOIN [DBShrpn].[dbo].[emp_status]     es ON es.emp_id = e.emp_id AND es.status_change_date = (SELECT MAX(status_change_date) FROM DBShrpn.dbo.emp_status t WHERE t.emp_id = es.emp_id AND t.status_change_date <= GETDATE())
 LEFT JOIN [DBShrpn].[dbo].[pos_title]		pt ON pt.pos_id = ea.job_or_pos_id AND pt.eff_date = (SELECT MAX(eff_date) FROM DBShrpn.dbo.pos_title t WHERE t.pos_id = pt.pos_id  AND t.eff_date <= GETDATE())
 LEFT JOIN [DBShrpn].[dbo].[job_title]		jt ON jt.job_id = ea.job_or_pos_id AND jt.eff_date = (SELECT MAX(eff_date) FROM DBShrpn.dbo.job_title t WHERE t.job_id = jt.job_id  AND t.eff_date <= GETDATE())
 WHERE ee.empl_id = 'BANK'  --CASD FOR SSI ONLY

IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_current_temp2]') AND type in (N'U'))
	DROP TABLE [dbo].[ghr_current_temp2]
	
SELECT	e.emp_id					AS [Employee_Number],
		i.first_name				AS [First_Name],
		i.first_middle_name			AS [Middle_Name], 
		i.last_name					AS [Last_Name],  
		ee.empl_id					AS [Employer], 
		p.national_id_1_type_code	AS [National_Id_Type], 
		p.national_id_1				AS [National_Id_Nbr],
		p.user_text_1				AS [Position Title],
		ea.organization_unit_name	AS [rganization_Unit_name], 
		ea.annual_salary_amt		AS [Annual_Salary],
        ee.time_reporting_meth_code	AS [Time_Reporting_Method],
        ee.pay_element_ctrl_grp_id	AS [Pay_Element_Ctrl_Group], 
        ee.pay_group_id				AS [Pay_Group],
        ee.pay_status_code			AS [Pay_Status],
        ee.pay_through_date			AS [Pay_Through_Date],
        es.hire_date				AS [Hire_Date],
        CASE WHEN pt.title IS NOT NULL	THEN pt.title
             ELSE jt.title		END AS [Original Job_Position_Title],
        es.emp_status_code			AS [Employee Status]
INTO  DBShrpn.dbo.ghr_current_temp2
FROM  DBShrpn.dbo.employee e
INNER JOIN [DBShrpn].[dbo].[individual] i ON i.individual_id = e.individual_id
INNER JOIN [DBShrpn].[dbo].[individual_personal] p ON p.individual_id = e.individual_id
INNER JOIN [DBShrpn].[dbo].[emp_employment] ee ON ee.emp_id = e.emp_id AND ee.eff_date = (SELECT MAX(eff_date) FROM DBShrpn.dbo.emp_employment t WHERE t.emp_id = ee.emp_id AND t.eff_date <= GETDATE())
INNER JOIN [DBShrpn].[dbo].[emp_assignment] ea ON ea.emp_id = e.emp_id AND ea.eff_date = (SELECT MAX(eff_date) FROM DBShrpn.dbo.emp_assignment t WHERE t.emp_id = ea.emp_id AND t.prime_assignment_ind = 'Y' AND t.eff_date <= GETDATE()) AND ea.prime_assignment_ind = 'Y' AND end_date < GETDATE()
INNER JOIN [DBShrpn].[dbo].[emp_status]     es ON es.emp_id = e.emp_id AND es.status_change_date = (SELECT MAX(status_change_date) FROM DBShrpn.dbo.emp_status t WHERE t.emp_id = es.emp_id AND t.status_change_date <= GETDATE())
 LEFT JOIN [DBShrpn].[dbo].[pos_title]		pt ON pt.pos_id = ea.job_or_pos_id AND pt.eff_date = (SELECT MAX(eff_date) FROM DBShrpn.dbo.pos_title t WHERE t.pos_id = pt.pos_id  AND t.eff_date <= GETDATE())
 LEFT JOIN [DBShrpn].[dbo].[job_title]		jt ON jt.job_id = ea.job_or_pos_id AND jt.eff_date = (SELECT MAX(eff_date) FROM DBShrpn.dbo.job_title t WHERE t.job_id = jt.job_id  AND t.eff_date <= GETDATE())
  WHERE ee.empl_id = 'BANK'  --CASD FOR SSI ONLY

INSERT INTO DBShrpn.dbo.ghr_current_temp1
SELECT * 
  FROM DBShrpn.dbo.ghr_current_temp2 t2
 WHERE t2.[Employee_Number] not in (SELECT [Employee_Number] FROM DBShrpn.dbo.ghr_current_temp1 t1)
  
  
SELECT * FROM  DBShrpn.dbo.ghr_current_temp1 WHERE NOT ([Employee_Number] = '127587' AND [Original Job_Position_Title] = 'Graduate Teacher 1 Westerhall Secondary' )

 
END  --End of Proc
 
GO
ALTER AUTHORIZATION ON [dbo].[usp_current_data] TO  SCHEMA OWNER 
GO
