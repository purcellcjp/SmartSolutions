USE DBShrpn
GO


IF OBJECT_ID('dbo.uvu_emp_assignment_most_rec') IS NOT NULL
BEGIN
    DROP VIEW dbo.uvu_emp_assignment_most_rec
    IF OBJECT_ID('dbo.uvu_emp_assignment_most_rec') IS NOT NULL
        PRINT '<<< FAILED DROPPING VIEW dbo.uvu_emp_assignment_most_rec >>>'
    ELSE
        PRINT '<<< DROPPED VIEW dbo.uvu_emp_assignment_most_rec >>>'
END
GO

/****************************************************************************************

   View Name:     uvu_emp_assignment_most_rec

   Description:   Used to obtain the most recent employee assignment information.

   Table_Name(s):   INPUT:    DBShrpn..emp_assignemnt

   Revision history:
      version  date        developer   description
      -------  ----------  ---------   --------------------------------------------------
      1.0.00   08/06/2025  cjp         - Created view

****************************************************************************************/

CREATE VIEW dbo.uvu_emp_assignment_most_rec

AS

SELECT ea.emp_id
     , ea.assigned_to_code
     , ea.job_or_pos_id
     , ea.eff_date
     , ea.next_eff_date
     , ea.prior_eff_date
     , ea.next_assigned_to_code
     , ea.next_job_or_pos_id
     , ea.prior_assigned_to_code
     , ea.prior_job_or_pos_id
     , ea.begin_date
     , ea.end_date
     , ea.assignment_reason_code
     , ea.organization_chart_name
     , ea.organization_unit_name
     , ea.organization_group_id
     , ea.organization_change_reason_cd
     , ea.loc_code
     , ea.mgr_emp_id
     , ea.official_title_code
     , ea.official_title_date
     , ea.salary_change_date
     , ea.annual_salary_amt
     , ea.pd_salary_amt
     , ea.pd_salary_tm_pd_id
     , ea.hourly_pay_rate
     , ea.curr_code
     , ea.pay_on_reported_hrs_ind
     , ea.salary_change_type_code
     , ea.standard_work_pd_id
     , ea.standard_work_hrs
     , ea.work_tm_code
     , ea.work_shift_code
     , ea.salary_structure_id
     , ea.salary_increase_guideline_id
     , ea.pay_grade_code
     , ea.pay_grade_date
     , ea.job_evaluation_points_nbr
     , ea.salary_step_nbr
     , ea.salary_step_date
     , ea.phone_1_type_code
     , ea.phone_1_fmt_code
     , ea.phone_1_fmt_delimiter
     , ea.phone_1_intl_code
     , ea.phone_1_country_code
     , ea.phone_1_area_city_code
     , ea.phone_1_nbr
     , ea.phone_1_extension_nbr
     , ea.phone_2_type_code
     , ea.phone_2_fmt_code
     , ea.phone_2_fmt_delimiter
     , ea.phone_2_intl_code
     , ea.phone_2_country_code
     , ea.phone_2_area_city_code
     , ea.phone_2_nbr
     , ea.phone_2_extension_nbr
     , ea.prime_assignment_ind
     , ea.pay_basis_code
     , ea.occupancy_code
     , ea.regulatory_reporting_unit_code
     , ea.base_rate_tbl_id
     , ea.base_rate_tbl_entry_code
     , ea.shift_differential_rate_tbl_id
     , ea.ref_annual_salary_amt
     , ea.ref_pd_salary_amt
     , ea.ref_pd_salary_tm_pd_id
     , ea.ref_hourly_pay_rate
     , ea.guaranteed_annual_salary_amt
     , ea.guaranteed_pd_salary_amt
     , ea.guaranteed_pd_salary_tm_pd_id
     , ea.guaranteed_hourly_pay_rate
     , ea.exception_rate_ind
     , ea.overtime_status_code
     , ea.shift_differential_status_code
     , ea.standard_daily_work_hrs
     , ea.user_amt_1
     , ea.user_amt_2
     , ea.user_code_1
     , ea.user_code_2
     , ea.user_date_1
     , ea.user_date_2
     , ea.user_ind_1
     , ea.user_ind_2
     , ea.user_monetary_amt_1
     , ea.user_monetary_amt_2
     , ea.user_monetary_curr_code
     , ea.user_text_1
     , ea.user_text_2
     , ea.unemployment_loc_code
     , ea.include_salary_in_autopay_ind
     , ea.chgstamp
FROM DBShrpn.dbo.emp_assignment ea
WHERE (ea.next_eff_date = '12/31/2999')
  AND (ea.prime_assignment_ind = 'Y')
  AND (ea.end_date = (
                      SELECT MAX(ea2.end_date)
                      FROM DBShrpn..emp_assignment ea2
                      WHERE (ea2.emp_id               = ea.emp_id)
                        AND (ea2.prime_assignment_ind = ea.prime_assignment_ind)
                        AND (ea2.next_eff_date        = ea.next_eff_date)
                     ))
GO

ALTER AUTHORIZATION ON dbo.uvu_emp_assignment_most_rec TO  SCHEMA OWNER
GO


IF OBJECT_ID('dbo.uvu_emp_assignment_most_rec') IS NOT NULL
    PRINT '<<< CREATED VIEW dbo.uvu_emp_assignment_most_rec >>>'
ELSE
    PRINT '<<< FAILED CREATING VIEW dbo.uvu_emp_assignment_most_rec >>>'
GO
