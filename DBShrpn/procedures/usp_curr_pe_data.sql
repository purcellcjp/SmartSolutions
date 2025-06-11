USE [DBShrpn]
GO
/****** Object:  StoredProcedure [dbo].[usp_curr_pe_data]    Script Date: 4/1/2025 4:33:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[usp_curr_pe_data]
AS
BEGIN

SELECT	e.emp_id					AS [Employee_Number],
		i.first_name				AS [First_Name],
		i.first_middle_name			AS [Middle_Name],
		i.last_name					AS [Last_Name],
		ee.empl_id					AS [Employer], 
		ep.pay_element_id			AS [Pay Element],
		ep.standard_calc_factor_1	AS [Calc_Amt],
		ep.start_date				AS [Begin_Date],
		ep.stop_date				AS [End_Date]

FROM  DBShrpn.dbo.employee e
INNER JOIN [DBShrpn].[dbo].[individual] i ON i.individual_id = e.individual_id
INNER JOIN [DBShrpn].[dbo].[individual_personal] p ON 
p.individual_id = e.individual_id
INNER JOIN [DBShrpn].[dbo].[emp_employment]  ee ON 
ee.emp_id = e.emp_id AND 
ee.eff_date = (
               SELECT MAX(eff_date) 
			   FROM DBShrpn.dbo.emp_employment t 
			   WHERE t.emp_id = ee.emp_id 
			     AND t.eff_date <= GETDATE()
			  )
INNER JOIN [DBShrpn].[dbo].[emp_assignment]  ea ON 
ea.emp_id = e.emp_id AND 
ea.eff_date = (
               SELECT MAX(eff_date) 
			   FROM DBShrpn.dbo.emp_assignment t 
			   WHERE t.emp_id = ea.emp_id 
			     AND t.prime_assignment_ind = 'Y' 
				 AND t.eff_date <= GETDATE()
			  ) AND 
ea.prime_assignment_ind = 'Y'
INNER JOIN [DBShrpn].[dbo].[emp_status]      es ON 
es.emp_id = e.emp_id AND 
es.status_change_date = (
                         SELECT MAX(status_change_date) 
						 FROM DBShrpn.dbo.emp_status t 
						 WHERE t.emp_id = es.emp_id 
						   AND t.status_change_date <= GETDATE()
						)
INNER JOIN [DBShrpn].[dbo].[emp_pay_element] ep ON 
ep.emp_id = e.emp_id AND 
ep.empl_id = ee.empl_id AND 
ep.eff_date = (
               SELECT MAX(eff_date) 
			   FROM DBShrpn.dbo.emp_assignment t 
			   WHERE t.emp_id = ep.emp_id 
			     AND t.eff_date <= GETDATE()
			  )
INNER JOIN [DBShrpn].[dbo].[pay_element] pe ON 
pe.pay_element_id = ep.pay_element_id AND 
pe.eff_date = (
               SELECT MAX(eff_date) 
			   FROM DBShrpn.dbo.pay_element t 
			   WHERE t.pay_element_id = pe.pay_element_id 
			     AND t.pay_element_type_code = 1 
				 AND t.eff_date <= GETDATE()
			  )
ORDER BY e.emp_id
       
       
END  --End of Proc

 
GO
ALTER AUTHORIZATION ON [dbo].[usp_curr_pe_data] TO  SCHEMA OWNER 
GO
