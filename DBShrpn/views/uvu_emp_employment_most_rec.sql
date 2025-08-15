USE DBShrpn
GO


IF OBJECT_ID('dbo.uvu_emp_employment_most_rec') IS NOT NULL
BEGIN
    DROP VIEW dbo.uvu_emp_employment_most_rec
    IF OBJECT_ID('dbo.uvu_emp_employment_most_rec') IS NOT NULL
        PRINT '<<< FAILED DROPPING VIEW dbo.uvu_emp_employment_most_rec >>>'
    ELSE
        PRINT '<<< DROPPED VIEW dbo.uvu_emp_employment_most_rec >>>'
END
GO

/****************************************************************************************

   View Name:     uvu_emp_employment_most_rec

   Description:   Used to obtain the most recent employee assignment information.

   Table_Name(s):   INPUT:    DBShrpn..emp_employment

   Revision history:
      version  date        developer   description
      -------  ----------  ---------   --------------------------------------------------
      1.0.00   08/06/2025  cjp         - Created view

****************************************************************************************/

CREATE VIEW dbo.uvu_emp_employment_most_rec

AS

SELECT emp_id
     , eff_date
     , next_eff_date
     , prior_eff_date
     , employment_type_code
     , work_tm_code
     , official_title_code
     , official_title_date
     , mgr_ind
     , recruiter_ind
     , pensioner_indicator
     , payroll_company_code
     , pmt_ctrl_code
     , us_federal_tax_meth_code
     , us_federal_tax_amt
     , us_federal_tax_pct
     , us_federal_marital_status_code
     , us_federal_exemp_nbr
     , us_work_st_code
     , canadian_work_province_code
     , ipp_payroll_id
     , ipp_max_pay_level_amt
     , pay_through_date
     , empl_id
     , tax_entity_id
     , pay_status_code
     , clock_nbr
     , provided_i_9_ind
     , time_reporting_meth_code
     , regular_hrs_tracked_code
     , pay_element_ctrl_grp_id
     , pay_group_id
     , us_pension_ind
     , professional_cat_code
     , corporate_officer_ind
     , prim_disbursal_loc_code
     , alternate_disbursal_loc_code
     , labor_grp_code
     , employment_info_chg_reason_cd
     , highly_compensated_emp_ind
     , nbr_of_dependent_children
     , canadian_federal_tax_meth_cd
     , canadian_federal_tax_amt
     , canadian_federal_tax_pct
     , canadian_federal_claim_amt
     , canadian_province_claim_amt
     , tax_unit_code
     , requires_tm_card_ind
     , xfer_type_code
     , tax_clear_code
     , pay_type_code
     , labor_distn_code
     , labor_distn_ext_code
     , us_fui_status_code
     , us_fica_status_code
     , payable_through_bank_id
     , disbursal_seq_nbr_1
     , disbursal_seq_nbr_2
     , non_employee_indicator
     , excluded_from_payroll_ind
     , emp_info_source_code
     , user_amt_1
     , user_amt_2
     , user_monetary_amt_1
     , user_monetary_amt_2
     , user_monetary_curr_code
     , user_code_1
     , user_code_2
     , user_date_1
     , user_date_2
     , user_ind_1
     , user_ind_2
     , user_text_1
     , user_text_2
     , t4_employ_code
     , chgstamp
FROM   DBShrpn.dbo.emp_employment
WHERE  (next_eff_date = '12/31/2999')

GO

ALTER AUTHORIZATION ON dbo.uvu_emp_employment_most_rec TO  SCHEMA OWNER
GO


IF OBJECT_ID('dbo.uvu_emp_employment_most_rec') IS NOT NULL
    PRINT '<<< CREATED VIEW dbo.uvu_emp_employment_most_rec >>>'
ELSE
    PRINT '<<< FAILED CREATING VIEW dbo.uvu_emp_employment_most_rec >>>'
GO
