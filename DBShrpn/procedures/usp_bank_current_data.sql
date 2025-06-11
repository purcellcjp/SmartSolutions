USE [DBShrpn]
GO
/****** Object:  StoredProcedure [dbo].[usp_bank_current_data]    Script Date: 4/1/2025 4:33:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE procedure [dbo].[usp_bank_current_data]
AS
BEGIN
-- EXEC [DBShrpn].[dbo].[usp_bank_current_data]

SELECT pe.emp_id, pe.pay_element_id, pe.bank_id, pe.direct_deposit_bank_acct_nbr, pe.bank_acct_type_code
  FROM [DBShrpn].[dbo].[emp_pay_element] pe
INNER JOIN [DBShrpn].[dbo].[emp_status]  es
        ON es.emp_id = pe.emp_id AND es.status_change_date = (SELECT MAX(status_change_date) FROM emp_status t WHERE t.emp_id = es.emp_id AND status_change_date <= GETDATE())
WHERE [eff_date]        =   (SELECT MAX(eff_date) FROM [DBShrpn].[dbo].[emp_pay_element] t 
                              WHERE t.emp_id = pe.emp_id AND t.pay_element_id = pe.pay_element_id)
  AND pe.bank_id <> ''
  AND es.emp_status_code = 'A'
 GROUP BY pe.emp_id, pe.pay_element_id, pe.bank_id, pe.direct_deposit_bank_acct_nbr, pe.bank_acct_type_code
 ORDER BY pe.emp_id, pe.pay_element_id
 
END  --End of Proc

GRANT EXECUTE on [dbo].[usp_bank_current_data] TO public

 
 
GO
ALTER AUTHORIZATION ON [dbo].[usp_bank_current_data] TO  SCHEMA OWNER 
GO
GRANT EXECUTE ON [dbo].[usp_bank_current_data] TO [public] AS [dbo]
GO
