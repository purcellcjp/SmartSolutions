USE DBShrpn
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'dbo.usp_perform_transfer', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_perform_transfer
    IF OBJECT_ID(N'dbo.usp_perform_transfer') IS NOT NULL
        PRINT N'<<< FAILED DROPPING PROCEDURE dbo.usp_perform_transfer >>>'
    ELSE
        PRINT N'<<< DROPPED PROCEDURE dbo.usp_perform_transfer >>>'
END
GO

/*************************************************************************************
    SP Name:       usp_perform_transfer

    Description:


    Parameters:
        @p_user_id       =  User ID (i.e. 'DBS')
        @p_batchname     = Job Scheduler Batch Name (i.e. 'GHR')
        @p_qualifier     = Job Scheduler Qualifier (i.e. 'INTERFACES')
        @p_activity_date = Current System Date


    Example:
        EXEC DBShrpn.dbo.usp_perform_transfer
              @p_user_id          = @w_userid
            , @p_batchname       = @v_PSC_BATCHNAME
            , @p_qualifier       = @w_PSC_QUALIFIER
            , @p_activity_date   = @w_activity_date


   Revision history:
   version  date        developer   SCR         description
   -------  ----------  ---------   -----       ------------------------------------
   1.0.00   08/27/2025  CJP                     - Cloned from GOG version

************************************************************************************/

CREATE PROCEDURE dbo.usp_perform_transfer
    (
      @p_user_id              varchar(30)
    , @p_batchname            varchar(08)
    , @p_qualifier            varchar(30)
    , @p_activity_date        datetime
    )
AS

BEGIN

    SET NOCOUNT ON

    DECLARE @v_step_position                            varchar(255)        = 'Begin Procedure'
    DECLARE @msg_id                                     char(10)

    DECLARE @v_EVENT_ID_SALARY_CHANGE                   char(2)             = '02'
    DECLARE @v_EVENT_ID_TRANSFER                        char(2)             = '03'
    DECLARE @v_EVENT_ID_STATUS_CHANGE                   char(2)             = '05'
    DECLARE @v_END_OF_TIME_DATE                         datetime            = '29991231'

    DECLARE @v_ACTIVITY_STATUS_GOOD                     char(2)             = '00'
    DECLARE @v_ACTIVITY_STATUS_WARNING                  char(2)             = '01'
    DECLARE @v_ACTIVITY_STATUS_BAD                      char(2)             = '02'

    DECLARE @ErrorNumber                                varchar(10)
    DECLARE @ErrorMessage                               nvarchar(4000)
    DECLARE @ErrorSeverity                              int
    DECLARE @ErrorState                                 int

    DECLARE @v_ret_val                                  int = 0

    DECLARE @w_msg_text                                 varchar(255)
    DECLARE @w_msg_text_2                               varchar(255)
    DECLARE @w_msg_text_3                               varchar(255)
    DECLARE @w_severity_cd                              tinyint
    DECLARE @w_fatal_error                              bit                 = 0

    DECLARE @rehire_override                            bit
    DECLARE @maxx                                       char(06)

    DECLARE @new_annual_salary_amt    money
    DECLARE @new_emp_asgn_assigned_to_code              char(01)
    DECLARE @new_emp_asgn_job_or_pos_id                 char(10)
    DECLARE @new_emp_asgn_eff_date                      datetime
    DECLARE @new_emp_asgn_standard_work_pd_id           char(5)
    DECLARE @new_emp_asgn_salary_change_type_code       char(5)
    DECLARE @new_emp_asgn_standard_work_hrs             float
    DECLARE @new_emp_asgn_yearly_std_work_hrs           float
    DECLARE @new_emp_asgn_hourly_rate_amt               money
    DECLARE @new_emp_asgn_period_amt                    money
    DECLARE @new_emp_asgn_work_tm_code                  char(01)
    DECLARE @new_emp_asgn_base_rate_tbl_id              char(10)
    DECLARE @new_emp_asgn_base_rate_tbl_entry_code      char(08)
    DECLARE @new_emp_asgn_pd_salary_tm_pd_id            char(05)

    -- This section declares the interface values from Global HR
    DECLARE @aud_id                                     int             = 0
    DECLARE @emp_id                                     char(15)        = ''
    DECLARE @eff_date                                   char(10)        = '29991231'
    DECLARE @first_name                                 char(25)
    DECLARE @first_middle_name                          char(25)
    DECLARE @last_name                                  char(30)
    DECLARE @empl_id                                    char(10)
    DECLARE @national_id_type_code                      char(05)
    DECLARE @national_id                                char(20)
    DECLARE @organization_group_id                      char(05)
    DECLARE @organization_chart_name                    char(64)
    DECLARE @organization_unit_name                     char(240)
    DECLARE @emp_status_classn_code                     char(02)
    DECLARE @position_title                             char(50)        -- DBShrpn..emp_assignment.user_text
    DECLARE @employment_type_code                       varchar(70)     -- increased size to 70 from 5
    DECLARE @annual_salary_amt                          char(15)
    DECLARE @begin_date                                 char(10)
    DECLARE @end_date                                   char(10)
    DECLARE @pay_status_code                            char(01)
    DECLARE @pay_group_id                               char(10)
    DECLARE @pay_element_ctrl_grp_id                    char(10)
    DECLARE @time_reporting_meth_code                   char(01)
    DECLARE @employment_info_chg_reason_cd              char(05)
    DECLARE @emp_location_code                          char(10)
    DECLARE @emp_status_code                            char(02)
    DECLARE @reason_code                                char(02)
    DECLARE @emp_expected_return_date                   char(10)
    DECLARE @pay_through_date                           char(10)
    DECLARE @emp_death_date                             char(10)
    DECLARE @consider_for_rehire_ind                    char(01)
    DECLARE @pay_element_id                             char(10)
    DECLARE @emp_calculation                            char(15)
    DECLARE @tax_flag                                   char(1)         -- individual_personal.ind_2
    DECLARE @nic_flag                                   char(1)         -- individual_personal.ind_1
    DECLARE @tax_ceiling_amt                            char(15)        -- employee.user_monetary_amt_1
    DECLARE @labor_grp_code                             char(5)         -- DBShrpn..emp_employment.labor_grp_code
    DECLARE @file_source                                char(50)        -- 'SS VENUS' or 'SS GANYMEDE'

    DECLARE @w_eff_date                                 datetime
    DECLARE @v_cal_year                                 smallint

    -- Transfer Varaibles
    DECLARE @cur_empl_id                                char(10)
    DECLARE @cur_eempl_eff_date                         datetime
    DECLARE @cur_tax_entity_id                          char(10)
    DECLARE @new_tax_entity                             char(10)
    DECLARE @cur_emp_asgn_end_date                      datetime
    DECLARE @cur_emp_asgn_job_position_end_date         datetime
    DECLARE @cur_emp_asgn_assigned_to_code              char(01)
    DECLARE @cur_emp_asgn_job_or_pos_id                 char(10)
    DECLARE @cur_emp_status_code                        char(02)
    DECLARE @new_taxing_country_code                    char(02)
    DECLARE @new_curr_code                              char(03)


    -- Temp tables for the SmartStream helper procedures
    CREATE TABLE #temp1  (emp_id                      char(15)       not null, empl_id                        char(10)       not null, pay_element_id                 char(10)       not null, eff_date                       datetime       not null,   prior_eff_date                 datetime       not null,   next_eff_date                  datetime       not null,   inactivated_by_pay_element_ind char(1)       not null,   start_date                     datetime       not null,   stop_date                      datetime       not null,   change_reason_code             char(5)       not null,   pay_element_pay_pd_sched_code  char(2)       not null,   calc_meth_code                 char(2)       not null,   standard_calc_factor_1         money          not null,   standard_calc_factor_2         money          not null,   special_calc_factor_1          money          not null,   special_calc_factor_2          money          not null,   special_calc_factor_3          money          not null,   special_calc_factor_4          money          not null,   rate_tbl_id                    char(10)       not null,   rate_code                      char(8)       not null,   payee_name                     char(35)      not null,   payee_pmt_sched_code           char(5)       not null,   payee_bank_transit_nbr         char(17)       not null,   payee_bank_acct_nbr            char(17)       not null,   pmt_ref_nbr                    char(20)       not null,   pmt_ref_name                   char(35)       not null,   vendor_id                      char(10)       not null,   limit_amt                      money          not null,   guaranteed_net_pay_amt         money          not null,   start_after_pay_element_id     char(10)       not null,   indiv_addr_type_to_print_code  char(5)       not null,   bank_id                        char(11)       not null,   direct_deposit_bank_acct_nbr   char(17)       not null,   bank_acct_type_code            char(1)       not null,   pay_pd_arrears_rec_fixed_amt   money          not null,   pay_pd_arrears_rec_fixed_pct   money          not null,   min_pay_pd_recovery_amt        money          not null,   user_amt_1                     float          not null,   user_amt_2                     float          not null,   user_monetary_amt_1            money          not null,   user_monetary_amt_2            money          not null,   user_monetary_curr_code        char(3)       not null,   user_code_1                    char(5)       not null,   user_code_2                    char(5)       not null,   user_date_1                    datetime       not null,   user_date_2                    datetime       not null,   user_ind_1                     char(1)       not null,   user_ind_2                     char(1)       not null,   user_text_1                    char(50)       not null,   user_text_2                    char(50)       not null,   pension_tot_distn_ind          char(1)       not null,   pension_distn_code_1           char(1)       not null,   pension_distn_code_2           char(1)       not null, pre_1990_rpp_ctrb_type_cd      char(1)       not null,   chgstamp                       smallint       not null,   first_roth_ctrb                datetime       not null,   ira_sep_simple_ind             char(1)       not null, taxable_amt_not_determined_ind char(1)       not null)
    CREATE TABLE #temp4  (emp_id                      char(15)       not null, empl_id                        char(10)       not null, pay_element_id                 char(10)       not null, arrears_bal_amt                money          not null,   recover_over_nbr_of_pay_pds    tinyint       not null,   wh_status_code                 char(1)       not null,   calc_last_pay_pd_ind           char(1)       not null,   prenotification_check_date     datetime       not null,   prenotification_code           char(1)       not null,   chgstamp                       smallint       not null)
    CREATE TABLE #temp5  (emp_id                      char(15)       not null, empl_id                        char(10)       not null, pay_element_id                 char(10)       not null, start_date                     datetime       not null,   towards_the_limit_amt          money          not null,   chgstamp                       smallint       not null)
    CREATE TABLE #temp6  (emp_id                      char(15)       not null, empl_id                        char(10)       not null, pay_element_id                 char(10)       not null, start_date                     datetime       not null,   comnt_type_code                char(1)       not null,   seq_nbr                        smallint       not null,   comnt_text                     varchar(255)    not null,   chgstamp                       smallint       not null)
    CREATE TABLE #temp7  (participant_id              char(15)       not null, ben_plan_id                    char(15)       not null, ben_plan_opt_id                char(08)       not null, eff_date                       datetime       not null, next_eff_date                  datetime       not null, prior_eff_date                 datetime       not null, start_date                     datetime       not null, stop_date                      datetime       not null, chained_with_option_id         char(8)       not null, chained_to_option_id           char(8)       not null, stopped_due_to_plan_ending_ind char(1)       not null, stopped_due_to_opt_ending_ind  char(1)       not null, stopped_due_to_terminated_ind  char(1)       not null, cobra_cost_amt                 money          not null, cobra_cost_tm_pd_id            char(5)       not null, cobra_empl_cost_amt            money          not null, cobra_empl_cost_tm_pd_id       char(5)       not null, user_amt_1                     float          not null, user_amt_2                     float          not null, user_monetary_curr_code        char(3)       not null, user_monetary_amt_1            money          not null, user_monetary_amt_2            money          not null, user_code_1                    char(5)       not null, user_code_2                    char(5)       not null, user_date_1                    datetime       not null, user_date_2                    datetime       not null, user_ind_1                     char(1)       not null, user_ind_2                     char(1)       not null, user_text_1                    char(50)       not null, user_text_2                    char(50)       not null, chgstamp                       smallint       not null)
    CREATE TABLE #temp8  (participant_id              char(15)       not null, ben_plan_id                    char(15)       not null, ben_plan_opt_id                char(08)       not null, eff_date                       datetime       not null, ben_plan_alloc_opt_id          char(10)       not null, allocated_amt                  money          not null, allocated_pct                  float          not null, user_amt_1                     float          not null, user_amt_2                     float          not null, user_monetary_curr_code        char(3)       not null, user_monetary_amt_1            money          not null, user_monetary_amt_2            money          not null, user_code_1                    char(5)       not null, user_code_2                    char(5)       not null, user_date_1                    datetime       not null, user_date_2                    datetime       not null, user_ind_1                     char(1)       not null, user_ind_2                     char(1)       not null, user_text_1                    char(50)       not null, user_text_2                    char(50)       not null, chgstamp                       smallint       not null)
    CREATE TABLE #temp9  (participant_id             char(15)       not null, ben_plan_id                  char(15)       not null, ben_plan_opt_id              char(08)       not null, start_date                   datetime       not null, comnt_type_code                char(1)          not null, seq_nbr                        smallint       not null, comnt_text                     varchar(255)    not null, chgstamp                       smallint       not null)
    CREATE TABLE #temp11 (emp_id                      char(15)       not null, assigned_to_code               char(1)       not null, job_or_pos_id                  char(10)       not null, eff_date                       datetime       not null,   next_eff_date                  datetime       not null,   prior_eff_date                 datetime       not null,   next_assigned_to_code          char(1)       not null,   next_job_or_pos_id             char(10)       not null,   prior_assigned_to_code         char(1)       not null,   prior_job_or_pos_id            char(10)       not null,   begin_date                     datetime       not null,   end_date                       datetime       not null,   assignment_reason_code         char(5)       not null,   organization_chart_name        varchar(64)    not null, organization_unit_name         varchar(240)    not null,   organization_group_id          int             not null,   organization_change_reason_cd  char(5)       not null,   loc_code                       char(10)       not null,   mgr_emp_id                     char(15)       not null,   official_title_code            char(5)       not null,   official_title_date            datetime       not null,   salary_change_date             datetime       not null,   annual_salary_amt              money          not null,   pd_salary_amt                  money          not null,   pd_salary_tm_pd_id             char(5)       not null,   hourly_pay_rate                float          not null,   curr_code                      char(3)       not null,   pay_on_reported_hrs_ind        char(1)       not null,   salary_change_type_code        char(5)       not null,   standard_work_pd_id            char(5)       not null,   standard_work_hrs              float          not null,   work_tm_code                   char(1)    not null,   work_shift_code                char(5)       not null,   salary_structure_id            char(10)       not null,   salary_increase_guideline_id   char(10)       not null,   pay_grade_code                 char(6)       not null,   pay_grade_date                 datetime       not null,   job_evaluation_points_nbr      smallint       not null,   salary_step_nbr                smallint       not null,   salary_step_date               datetime       not null,   phone_1_type_code              char(5)       not null,   phone_1_fmt_code               char(6)       not null,   phone_1_fmt_delimiter          char(1)       not null,   phone_1_intl_code              char(4)       not null,   phone_1_country_code           char(4)       not null,   phone_1_area_city_code         char(5)       not null,   phone_1_nbr                    char(12)       not null,   phone_1_extension_nbr          char(5)       not null,   phone_2_type_code              char(5)       not null,   phone_2_fmt_code               char(6)       not null,   phone_2_fmt_delimiter          char(1)       not null,   phone_2_intl_code              char(4)       not null,   phone_2_country_code           char(4)       not null,   phone_2_area_city_code         char(5)       not null,   phone_2_nbr                    char(12)       not null,   phone_2_extension_nbr          char(5)       not null,   prime_assignment_ind           char(1)       not null,   pay_basis_code                 char(1)       not null,   occupancy_code                 char(1)       not null,   regulatory_reporting_unit_code char(10)       not null,   base_rate_tbl_id               char(10)       not null,   base_rate_tbl_entry_code       char(8)       not null,   shift_differential_rate_tbl_id char(10)       not null,   ref_annual_salary_amt          money          not null,   ref_pd_salary_amt              money          not null,   ref_pd_salary_tm_pd_id         char(5)       not null,   ref_hourly_pay_rate            float          not null,   guaranteed_annual_salary_amt   money          not null,   guaranteed_pd_salary_amt       money          not null,   guaranteed_pd_salary_tm_pd_id  char(5)       not null,   guaranteed_hourly_pay_rate     float          not null,   exception_rate_ind             char(1)       not null,   overtime_status_code           char(2)       not null,   shift_differential_status_code char(2)       not null,   standard_daily_work_hrs        money          not null,   user_amt_1                     float          not null,   user_amt_2                     float          not null,   user_code_1                    char(5)       not null,   user_code_2                    char(5)       not null,   user_date_1                    datetime       not null,   user_date_2                    datetime       not null,   user_ind_1                     char(1)       not null,   user_ind_2                     char(1)       not null,   user_monetary_amt_1            money          not null,   user_monetary_amt_2            money          not null,   user_monetary_curr_code        char(3)       not null,   user_text_1                    char(50)       not null,   user_text_2                    char(50)       not null,   unemployment_loc_code          char(10)       not null, include_salary_in_autopay_ind  char(1)       not null,   chgstamp                       smallint       not null)
    CREATE TABLE #temp12 (emp_id                      char(15)       not null, tax_entity_id                  char(10)       not null, tax_authority_id               char(10)       not null, emp_us_tax_authority_status_cd char(1)       not null,   tax_marital_status_code        char(1)       not null,   tm_worked_pct                  money          not null,   work_resident_status_code      char(1)       not null,   reciprocal_tax_authority_id    char(10)       not null,   income_tax_calc_meth_cd        char(2)       not null,   earned_income_cr_calc_meth_cd  char(1)       not null,   income_tax_adj_code            char(1)       not null,   income_tax_adj_amt             money          not null,   income_tax_adj_pct             money          not null,   income_tax_nbr_of_exemps       smallint       not null,   income_tax_nbr_of_pers_exemps  smallint       not null,   income_tax_nbr_of_depn_exemps  smallint       not null,   income_tax_nbr_exemps_over_65  smallint       not null,   income_tax_nbr_of_allowances   smallint       not null,   use_inc_tax_low_inc_tbls_ind   char(1)       not null,   income_tax_blind_crs           smallint       not null,   income_tax_personal_exemp_amt  money          not null,   income_tax_senior_citizen_cr   smallint       not null,   oasdi_status_code              char(1)       not null,   medicare_status_code           char(1)       not null,   fui_status_code                char(1)       not null,   sui_st_ind                     char(1)       not null,   resident_county_code           char(5)       not null,   work_county_code               char(5)       not null,   sui_status_code                char(1)       not null,   sdi_status_code                char(1)       not null,   other_st_tax_1_status_code     char(1)       not null,   other_st_tax_2_status_code     char(1)       not null,   other_st_tax_3_status_code     char(1)       not null,   other_st_tax_4_status_code     char(1)       not null,   other_st_tax_5_status_code     char(1)       not null,   wage_plan_code                 char(1)       not null,   emp_health_insurance_cvrg_cd   char(1)       not null,   user_amt_1                     float          not null,   user_amt_2                     float          not null,   user_monetary_amt_1            money          not null,   user_monetary_amt_2            money          not null,   user_monetary_curr_code        char(3)       not null,   user_code_1                    char(5)       not null,   user_code_2                    char(5)       not null,   user_date_1                    datetime       not null,   user_date_2                    datetime       not null,   user_ind_1                     char(1)       not null,   user_ind_2                     char(1)       not null,   user_text_1                    char(50)       not null,   user_text_2                    char(50)       not null, emp_workers_comp_cvrg_cd       char(1)       not null, puerto_rico_resident_status_cd char(1)       not null, allowances_based_on_ded_amt    money          not null, az_income_tax_ovrd_opt_cd       char(1)       not null,   chgstamp                       smallint       not null, us_resident_status_cd          char(1)       null, other_st_tax_1a_status_code    char(1)       null, eic_nbr_of_children             smallint      null, hire_act_status_code             char(1)       null, emp_workers_comp_class        char(1)       null, resident_psd                           char(10)      null, add_vet_pers_exemps                  float         null, income_tax_nbr_joint_dep_exemp  smallint      null, allowance_based_on_special_ded   float         null, allowance_based_on_deds          smallint      null, rec_chg_ind                      char(1)       null, visa_type                       char(1)       null)
    CREATE TABLE #temp14 (emp_id                      char(15)       not null, eff_date                       datetime       not null, next_eff_date                  datetime       not null, prior_eff_date                 datetime       not null,   employment_type_code           char(5)       not null,   work_tm_code                   char(1)       null,   official_title_code            char(5)       not null,   official_title_date            datetime       not null,   mgr_ind                        char(1)       not null,   recruiter_ind                  char(1)       not null,   pensioner_indicator            char(1)       not null,   payroll_company_code           char(5)       not null,   pmt_ctrl_code                  char(5)       not null,   us_federal_tax_meth_code       char(1)       not null,   us_federal_tax_amt             money          not null,   us_federal_tax_pct             money          not null,   us_federal_marital_status_code char(1)       not null,   us_federal_exemp_nbr           tinyint       not null,   us_work_st_code                char(2)       not null,   canadian_work_province_code    char(2)       not null,   ipp_payroll_id                 char(5)       not null,   ipp_max_pay_level_amt          money          not null,   pay_through_date               datetime       not null,   empl_id                        char(10)       not null,   tax_entity_id                  char(10)       not null,   pay_status_code                char(1)       not null,   clock_nbr                      char(10)       not null,   provided_i_9_ind               char(1)       not null,   time_reporting_meth_code       char(1)       not null,   regular_hrs_tracked_code       char(1)       not null,   pay_element_ctrl_grp_id        char(10)       not null,   pay_group_id                   char(10)       not null,   us_pension_ind                 char(1)       not null,   professional_cat_code          char(5)       not null,   corporate_officer_ind          char(1)       not null,   prim_disbursal_loc_code        char(10)       not null,   alternate_disbursal_loc_code   char(10)       not null,   labor_grp_code                 char(5)       not null,   employment_info_chg_reason_cd  char(5)       not null,   highly_compensated_emp_ind     char(1)       not null,   nbr_of_dependent_children      tinyint       not null,   canadian_federal_tax_meth_cd   char(1)       not null,   canadian_federal_tax_amt       money          not null,   canadian_federal_tax_pct       money          not null,   canadian_federal_claim_amt     money          not null,   canadian_province_claim_amt    money          not null,   tax_unit_code                  char(5)       not null,   requires_tm_card_ind           char(1)       not null,   xfer_type_code                 char(1)       not null,   tax_clear_code                 char(1)       not null,   pay_type_code                  char(1)       not null,   labor_distn_code               char(14)       not null,   labor_distn_ext_code           char(30)       not null,   us_fui_status_code             char(1)       not null,   us_fica_status_code            char(1)       not null,   payable_through_bank_id        char(11)       not null,   disbursal_seq_nbr_1            char(30)       not null,   disbursal_seq_nbr_2            char(30)       not null,   non_employee_indicator         char(1)       not null,   excluded_from_payroll_ind      char(1)       not null,   emp_info_source_code           char(1)       not null,   user_amt_1                     float          not null,   user_amt_2                     float          not null,   user_monetary_amt_1            money          not null,   user_monetary_amt_2            money          not null,   user_monetary_curr_code        char(3)       not null,   user_code_1                    char(5)       not null,   user_code_2                    char(5)       not null,   user_date_1                    datetime       not null,   user_date_2                    datetime       not null,   user_ind_1                     char(1)       not null,   user_ind_2                     char(1)       not null,   user_text_1                    char(50)       not null,   user_text_2                    char(50)       not null,   t4_employ_code                 char(2)       not null,   chgstamp                       smallint       not null)
    CREATE TABLE #temp15 (emp_id                      char(15)      NOT NULL, empl_id                        char(10)       NOT NULL, tax_authority_id               char(10)       NOT NULL, emp_can_tax_auth_status_cd     char(1)       NOT NULL, inc_tax_status_code            char(1)       NOT NULL, inc_tax_adj_code               char(1)       NOT NULL, inc_tax_adj_amt                money         NOT NULL, inc_tax_adj_pct                money         NOT NULL, tot_estd_remuneration_amt      money         NOT NULL, tot_estimated_expense_amt      money         NOT NULL, inc_tax_basic_amt              money         NOT NULL, inc_tax_spousal_disabled_amt   money         NOT NULL, inc_tax_depn_relative_amt      money         NOT NULL, inc_tax_eligible_pens_inc_amt  money         NOT NULL, inc_tax_age_amt                money         NOT NULL, inc_tax_tuition_fees_educ_amt  money         NOT NULL, inc_tax_disability_amt         money         NOT NULL, inc_tax_transferred_amt        money         NOT NULL, inc_tax_tot_claim_amt          money         NOT NULL, inc_tax_ded_dsgnd_liv_area_amt money         NOT NULL, inc_tax_auth_annual_ded_amt    money         NOT NULL, inc_tax_other_tax_cr_amt       money         NOT NULL, canadian_status_indian_ind     char(1)       NOT NULL, ei_status_code                 char(1)       NOT NULL, pit_basic_amt                  money         NOT NULL, pit_spouse_support_amt         money         NOT NULL, pit_dependent_children_amt     money         NOT NULL, pit_other_dependent_amt        money         NOT NULL, pit_domestic_estab_amt         money         NOT NULL, pit_age_amt                    money         NOT NULL, unused_amt_1                   money         NOT NULL, unused_amt_2                   money         NOT NULL, pit_retmt_income_amt           money         NOT NULL, pit_family_amt                 money         NOT NULL, unused_amt_3                   money         NOT NULL, pit_tot_claim_amt              money         NOT NULL, pit_other_deds_amt             money         NOT NULL, pit_other_tax_cr_amt           money         NOT NULL, primary_province_ind           char(1)       NOT NULL, sales_tax_status_code          char(1)       NOT NULL, lbr_sponsored_fund_tax_cr_amt  money         NOT NULL, pp_status_code                 char(1)       NOT NULL, other_provincial_tax_1_stat_cd char(1)       NOT NULL, other_provincial_tax_2_stat_cd char(1)       NOT NULL, other_provincial_tax_3_stat_cd char(1)       NOT NULL, nbr_of_days_wrkd_os_canada     float         NOT NULL, user_amt_1                     float         NOT NULL, user_amt_2                     float         NOT NULL, user_monetary_amt_1            money         NOT NULL, user_monetary_amt_2            money         NOT NULL, user_monetary_curr_code        char(3)       NOT NULL, user_code_1                    char(5)       NOT NULL, user_code_2                    char(5)       NOT NULL, user_date_1                    datetime      NOT NULL, user_date_2                    datetime      NOT NULL, user_ind_1                     char(1)       NOT NULL, user_ind_2                     char(1)       NOT NULL, user_text_1                    varchar(50)   NOT NULL, user_text_2                    varchar(50)   NOT NULL, inc_tax_caregiver_amt          money         NOT NULL, pit_disability_amt              money         NOT NULL, pit_transferred_amt              money         NOT NULL, chgstamp                       smallint      NOT NULL, ppip_status_code               char(1)       NOT NULL, inc_tax_infirm_depn_amt        money         NULL, inc_tax_child_amt              money         NULL, inc_tax_transferred_depn_amt   money         NULL, cpp_election_code              char(1)       NULL, cpp_election_date              datetime      NULL, prev_cpp_election_code         char(1)       NULL, prev_cpp_election_date         datetime      NULL, rcv_pp_pension_ind             char(1)       NULL, hlth_ctrb_status_code          char(1)       NULL)



    CREATE TABLE #tbl_ghr_msg
        (
          msg_id                                    char(15)            NOT NULL
        , msg_desc                                  varchar(255)        NOT NULL
        )


    CREATE TABLE #tbl_msg_master
        (
          msg_id            char(15)    NOT NULL
        , severity_cd       tinyint     NOT NULL
        , msg_text          varchar(255)    NOT NULL
        , msg_text_2        varchar(255)    NOT NULL
        , msg_text_3        varchar(255)    NOT NULL
        , loop_flag         char(1)     NOT NULL
        )


    BEGIN TRY

        SET @v_step_position = '#tbl_msg_master'

        ---------------------------------------------------------------------------
        -- Retrieve all error message templates
        ---------------------------------------------------------------------------
        INSERT INTO #tbl_msg_master
        SELECT msg_id
            , severity_cd
            , msg_text
            , msg_text_2
            , msg_text_3
            , 'N' AS loop_flag
        FROM DBSCOMMON.dbo.message_master
        WHERE (msg_id IN ('U00017'
                         ,'U00009'
                         ,'U00011'
                         ,'U00018'
                         ,'U00012'
                         ,'U00027'
                         ,'U00036'  -- do we need?
                         ,'U00034'
                         ,'U00038'
                         ,'U00039'
                         ,'U00044'
                         ,'U00045'
                         ,'U00010'
                        ))

        -- ID Message templates that need to loop through errors to add to log table
        UPDATE #tbl_msg_master
        SET loop_flag = 'Y'
        WHERE (msg_id IN ('U00012'
                         ,'U00027'
                         ,'U00036'  -- do we need
                         ,'U00034'
                         ,'U00038'
                         ,'U00039'
                         ,'U00044'
                         ,'U00045'
                        ))


        SET @v_step_position = 'Declaring cursor crsrHR'

        -- Loop through ghr_employee_events_temp to populate error message log entry
        DECLARE crsrHR CURSOR FAST_FORWARD FOR
        SELECT t.aud_id
             , t.emp_id
             , t.eff_date
             , t.first_name
             , t.first_middle_name
             , t.last_name
             , t.empl_id
             , t.national_id_type_code
             , t.national_id
             , t.organization_group_id
             , ''       -- t.organization_chart_name
             , ''       -- t.organization_unit_name
             , t.emp_status_classn_code
             , t.position_title
             , t.employment_type_code
             , t.annual_salary_amt
             , t.begin_date
             , t.end_date
             , t.pay_status_code
             , t.pay_group_id
             , t.pay_element_ctrl_grp_id
             , t.time_reporting_meth_code
             , t.employment_info_chg_reason_cd
             , t.emp_location_code
             , t.emp_status_code
             , t.reason_code
             , t.emp_expected_return_date
             , t.pay_through_date
             , t.emp_death_date
             , t.consider_for_rehire_ind
             , t.pay_element_id
             , t.emp_calculation
             , t.tax_flag
             , t.nic_flag
             , t.tax_ceiling_amt
             , t.labor_grp_code
             , t.file_source
        FROM #ghr_employee_events_temp t
        WHERE (event_id = @v_EVENT_ID_TRANSFER)

        SET @v_step_position = 'Opening cursor crsrHR'
        OPEN crsrHR

        SET @v_step_position = 'Fetching cursor crsrHR'
        FETCH crsrHR
        INTO  @aud_id
            , @emp_id
            , @eff_date
            , @first_name
            , @first_middle_name
            , @last_name
            , @empl_id
            , @national_id_type_code
            , @national_id
            , @organization_group_id
            , @organization_chart_name
            , @organization_unit_name
            , @emp_status_classn_code
            , @position_title
            , @employment_type_code
            , @annual_salary_amt
            , @begin_date
            , @end_date
            , @pay_status_code
            , @pay_group_id
            , @pay_element_ctrl_grp_id
            , @time_reporting_meth_code
            , @employment_info_chg_reason_cd
            , @emp_location_code
            , @emp_status_code
            , @reason_code
            , @emp_expected_return_date
            , @pay_through_date
            , @emp_death_date
            , @consider_for_rehire_ind
            , @pay_element_id
            , @emp_calculation
            , @tax_flag
            , @nic_flag
            , @tax_ceiling_amt
            , @labor_grp_code
            , @file_source


        WHILE (@@FETCH_STATUS = 0)
        BEGIN

            BEGIN TRY

                SET @v_step_position = 'Begin crsrHR While Loop'

                SET @w_fatal_error = 0

                BEGIN TRAN

                --   Clear the fields:
                SELECT @cur_empl_id                             = ''
                    , @cur_tax_entity_id                       = ''
                    , @cur_eempl_eff_date                      = ''
                    , @cur_emp_asgn_end_date                   = @v_END_OF_TIME_DATE
                    , @cur_emp_asgn_job_position_end_date      = @v_END_OF_TIME_DATE
                    , @cur_emp_asgn_assigned_to_code           = ''
                    , @cur_emp_asgn_job_or_pos_id              = ''
                    , @cur_emp_status_code                     = ''
                    , @new_tax_entity                          = ''
                    , @new_taxing_country_code                 = ''
                    , @new_curr_code                           = ''
                    , @w_fatal_error                           = 0


                ---------------------------------------------------------------------------
                ---------------------------------------------------------------------------
                -- Validate Basic Data
                ---------------------------------------------------------------------------
                ---------------------------------------------------------------------------


                ---------------------------------------------------------------------------
                -- Validate Effective Date
                ---------------------------------------------------------------------------
                -- Invalid date value from HCM, ''@1'', for employee, @2, and event id, @3.

                -- Effective Date
                IF (TRY_CONVERT(datetime, @eff_date) IS NULL)
                    BEGIN

                        SET @msg_id = 'U00102'  -- New code
                        SET @v_step_position = 'Validation Effective Date - ' + RTRIM(@msg_id)

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id      AS msg_id
                            , REPLACE(REPLACE(REPLACE(t.msg_text, '@1', @eff_date), '@2', @emp_id), '@3', @v_EVENT_ID_TRANSFER) AS msg_desc
                        FROM #tbl_msg_master t
                        WHERE (msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_TRANSFER
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = ''
                            , @p_msg_p1             = ''
                            , @p_msg_p2             = ''
                            , @p_msg_desc           = 'Invalid Effective Date'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id

                        SET @w_fatal_error = 1

                    END
                ELSE
                    -- Convert amount to money data type
                    SELECT @w_eff_date = CONVERT(datetime, @eff_date)


                -- Validate Employee ID - U00012

                ---------------------------------------------------------------------------
                -- Lookup current SS associate details
                ---------------------------------------------------------------------------
                SELECT @cur_empl_id                             = eempl.empl_id
                    , @cur_tax_entity_id                       = eempl.tax_entity_id
                    , @cur_eempl_eff_date                      = eempl.eff_date
                    , @cur_emp_asgn_end_date                   = ea.end_date
                    , @cur_emp_asgn_job_position_end_date      = ea.end_date
                    , @cur_emp_asgn_assigned_to_code           = ea.assigned_to_code
                    , @cur_emp_asgn_job_or_pos_id              = ea.job_or_pos_id
                    , @cur_emp_status_code                     = stat.emp_status_code
                FROM DBShrpn.dbo.employee emp
                JOIN DBShrpn.dbo.uvu_emp_employment_most_rec eempl ON
                    (emp.emp_id = eempl.emp_id)
                JOIN DBShrpn.dbo.uvu_emp_assignment_most_rec ea ON
                    (emp.emp_id = ea.emp_id)
                JOIN DBShrpn.dbo.uvu_emp_status_most_rec stat ON
                    (emp.emp_id = stat.emp_id)
                WHERE (emp.emp_id = @emp_id)

                -- If no records are returned then employee doesn't exist in SS
                IF (@@ROWCOUNT = 0)
                BEGIN

                    SET @msg_id = 'U00012'
                    SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)


                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id AS msg_id
                        , REPLACE(t.msg_text, '@1', RTRIM(@emp_id)) AS msg_desc
                    FROM #tbl_msg_master t
                    WHERE (msg_id = @msg_id)

                    -- Historical Message for reporting purpose
                    EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                        @p_msg_id             = @msg_id
                        , @p_event_id           = @v_EVENT_ID_TRANSFER
                        , @p_emp_id             = @emp_id
                        , @p_eff_date           = @eff_date
                        , @p_pay_element_id     = ''
                        , @p_msg_p1             = ''
                        , @p_msg_p2             = ''
                        , @p_msg_desc           = 'Invalid employee id.'
                        , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                        , @p_activity_date      = @p_activity_date
                        , @p_audit_id           = @aud_id

                    SET @w_fatal_error = 1

                END


                ---------------------------------------------------------------------------
                -- Override the message if this cycle contains an employee rehire record
                ---------------------------------------------------------------------------
                IF  EXISTS (
                            SELECT 1
                            FROM #ghr_employee_events_temp
                            WHERE event_id = @v_EVENT_ID_STATUS_CHANGE
                            AND emp_id = @emp_id
                            AND emp_status_code = 'RH'
                        )
                    SET @rehire_override = 1
                ELSE
                    SET @rehire_override = 0


                ---------------------------------------------------------------------------
                -- Check to see if the employee current status is terminated and look ahead for Rehire record.
                ---------------------------------------------------------------------------
                SET @v_step_position = 'Validation - Emp Status Check'
                -- DO I NEED TO ADD LOG ERROR MESSAGE ????

                IF (@cur_emp_status_code = 'T')
                BEGIN
                    IF (@rehire_override = 1)
                    BEGIN

                    -- Historical Message for reporting purpose
                    EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                        @p_msg_id             = @msg_id
                        , @p_event_id           = @v_EVENT_ID_TRANSFER
                        , @p_emp_id             = @emp_id
                        , @p_eff_date           = @eff_date
                        , @p_pay_element_id     = ''
                        , @p_msg_p1             = ''
                        , @p_msg_p2             = ''
                        , @p_msg_desc           = 'Associate is currently terminated and has rehire record in current extract - bypassing transfer.'
                        , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                        , @p_activity_date      = @p_activity_date
                        , @p_audit_id           = @aud_id


                        SET @w_fatal_error = 1

                    END
                END


                ---------------------------------------------------------------------------
                --   Obtain the current record for this employee employment
                ---------------------------------------------------------------------------
                set @v_step_position = 'Emp Employment Lookup'

                /*
                SELECT @new_emp_asgn_emp_employment_exists = 'N'

                SELECT @new_emp_asgn_emp_id                = emp_id,
                    @new_emp_asgn_empl_id               = empl_id,
                    @new_emp_asgn_eff_date              = eff_date,
                    @new_emp_asgn_emp_employment_exists = 'Y'
                FROM DBShrpn.dbo.uvu_emp_employment_most_rec
                WHERE (emp_id = @emp_id)
                */


                SET @v_step_position = 'Validation'


                IF --(@new_emp_asgn_emp_employment_exists = 'Y') AND
                (@cur_eempl_eff_date > @w_eff_date)
                    BEGIN

                        SET @msg_id = 'U00027'
                        SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

                        -- Convert date to string for log table
                        SET @w_msg_text_2 = CONVERT(char(8), @cur_eempl_eff_date, 112)


                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id As msg_id
                            , REPLACE(REPLACE(t.msg_text, '@1', @eff_date), '@2', @emp_id) AS msg_desc
                        FROM #tbl_msg_master t
                        WHERE (msg_id = @msg_id)


                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_TRANSFER
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = ''
                            , @p_msg_p1             = @w_msg_text_2
                            , @p_msg_p2             = ''
                            , @p_msg_desc           = 'The new effective date for employee must be greater than the current employee employment effective date'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id

                        SET @w_fatal_error = 1

                    END


                ---------------------------------------------------------------------------
                -- Check to see that current payments have been updated to accumulators
                ---------------------------------------------------------------------------
                -- Can't perform transfer if the accumulators have not been updated
                IF EXISTS (
                        SELECT 1
                        FROM DBShrpy.dbo.emp_pmt
                        WHERE (emp_id                 = @emp_id)
                            AND (posted_accumulator_ind = 'N')
                            AND (seq_ctrl_yr            > 0)
                        )
                    BEGIN
                        SET @msg_id = 'U00038'
                        SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)


                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id As msg_id
                            , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                        FROM #tbl_msg_master t
                        WHERE (msg_id = @msg_id)


                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_TRANSFER
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = ''
                            , @p_msg_p1             = ''
                            , @p_msg_p2             = ''
                            , @p_msg_desc           = 'Existing payments have not been updated into the accumulator for this employee.'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id

                        SET @w_fatal_error = 1

                    END


                ---------------------------------------------------------------------------
                -- Check to see if the new employer exists
                ---------------------------------------------------------------------------
                IF NOT EXISTS (
                            SELECT 1
                            FROM DBShrpn.dbo.employer
                            WHERE empl_id = @empl_id
                            )
                BEGIN
                    IF EXISTS (
                            SELECT 1
                            FROM DBShrpn.dbo.employer
                            WHERE empl_id = '0' + @empl_id
                            )
                        -- Add leading zero to employer id - lost on bulkcopy??? -- Do we need this for GOSL????
                        SELECT @empl_id   = '0' + @empl_id
                    ELSE
                        BEGIN

                            SET @msg_id = 'U00039'
                            SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)


                            INSERT INTO #tbl_ghr_msg
                            SELECT @msg_id      As msg_id
                                , REPLACE(t.msg_text, '@1', @empl_id) AS msg_desc
                            FROM #tbl_msg_master t
                            WHERE (msg_id = @msg_id)


                            -- Historical Message for reporting purpose
                            EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                                @p_msg_id             = @msg_id
                                , @p_event_id           = @v_EVENT_ID_TRANSFER
                                , @p_emp_id             = @emp_id
                                , @p_eff_date           = @eff_date
                                , @p_pay_element_id     = ''
                                , @p_msg_p1             = @empl_id
                                , @p_msg_p2             = ''
                                , @p_msg_desc           = 'Employer does not exist - bypassing record'
                                , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                                , @p_activity_date      = @p_activity_date
                                , @p_audit_id           = @aud_id

                            SET @w_fatal_error = 1

                        END
                END

                ---------------------------------------------------------------------------
                -- Check to see if the new employer is not the same as the current employer
                ---------------------------------------------------------------------------
                IF (@cur_empl_id = @empl_id)
                    BEGIN

                        -- If salary Change Record Exists in this run, bypass transfer record
                        -- NEED TO UPDATE THIS LOGIC SINCE GOSL WILL NOT INTERFACE IN SALARY
                        -- IF EXISTS (
                        --            SELECT 1
                        --            FROM #ghr_employee_events_temp
                        --            WHERE emp_id   = @emp_id
                        --              AND event_id = @v_EVENT_ID_SALARY_CHANGE
                        --           )
                        --     BEGIN
                        --         UPDATE DBShrpn.dbo.ghr_employee_events_aud
                        --         SET activity_status = @v_ACTIVITY_STATUS_WARNING
                        --         WHERE emp_id = @emp_id
                        --           AND activity_date = @p_activity_date
                        --           AND event_id = @v_EVENT_ID_TRANSFER

                        --         --CJP 8/6/2025 set skip flag instead of jumping to GOTO BYPASS_EMPLOYEE
                        --         SET @w_fatal_error = 1
                        --     END
                        -- ELSE
                            --BEGIN
                                SET @msg_id = 'U00034'
                                SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

                                INSERT INTO #tbl_ghr_msg
                                SELECT @msg_id As msg_id
                                    , REPLACE(REPLACE(t.msg_text, '@1', @empl_id), '@2', @emp_id) AS msg_desc
                                FROM #tbl_msg_master t
                                WHERE (msg_id = @msg_id)

                                -- Historical Message for reporting purpose
                                EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                                    @p_msg_id             = @msg_id
                                    , @p_event_id           = @v_EVENT_ID_TRANSFER
                                    , @p_emp_id             = @emp_id
                                    , @p_eff_date           = @eff_date
                                    , @p_pay_element_id     = ''
                                    , @p_msg_p1             = @empl_id
                                    , @p_msg_p2             = @cur_empl_id
                                    , @p_msg_desc           = 'Cannot transfer an employee to the same employer.'
                                    , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                                    , @p_activity_date      = @p_activity_date
                                    , @p_audit_id           = @aud_id

                                SET @w_fatal_error = 1
                            --END

                    END

/*
                ---------------------------------------------------------------------------
                -- Check to see if the employee is getting transfer to pensioner employer
                ---------------------------------------------------------------------------
                IF EXISTS(
                        SELECT 1
                        FROM DBShrpn.dbo.employer
                        WHERE empl_id = @empl_id
                            AND (name LIKE 'Pen%')
                        )
                    BEGIN
                        SET @msg_id = 'U00044'
                        SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

                        IF (@rehire_override = 0)
                            BEGIN

                                INSERT INTO #tbl_ghr_msg
                                SELECT @msg_id As msg_id
                                    , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                                FROM #tbl_msg_master t
                                WHERE (msg_id = @msg_id)

                                -- Historical Message for reporting purpose
                                EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                                    @p_msg_id             = @msg_id
                                    , @p_event_id           = @v_EVENT_ID_TRANSFER
                                    , @p_emp_id             = @emp_id
                                    , @p_eff_date           = @eff_date
                                    , @p_pay_element_id     = ''
                                    , @p_msg_p1             = @empl_id
                                    , @p_msg_p2             = ''
                                    , @p_msg_desc           = 'Cannot transfer an employee to a pensioner employer'
                                    , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                                    , @p_activity_date      = @p_activity_date
                                    , @p_audit_id           = @aud_id

                                SET @w_fatal_error = 1
                            END
                        ELSE
                            BEGIN
                                UPDATE DBShrpn.dbo.ghr_employee_events_aud
                                SET activity_status = @v_ACTIVITY_STATUS_WARNING
                                WHERE activity_date = @p_activity_date
                                    AND emp_id = @emp_id
                                    AND event_id = @v_EVENT_ID_TRANSFER
                            END

                END
*/


                ---------------------------------------------------------------------------
                -- Check to see if the employee current status is terminated.
                ---------------------------------------------------------------------------
                SET @msg_id = 'U00045'
                SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

                IF   (@cur_emp_status_code = 'T')
                    BEGIN
                        IF (@rehire_override = 0)   -- not a rehire in current run
                            BEGIN

                                INSERT INTO #tbl_ghr_msg
                                SELECT @msg_id                   As msg_id
                                    , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                                FROM #tbl_msg_master t
                                WHERE (msg_id = @msg_id)

                                -- Historical Message for reporting purpose
                                EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                                    @p_msg_id             = @msg_id
                                    , @p_event_id           = @v_EVENT_ID_TRANSFER
                                    , @p_emp_id             = @emp_id
                                    , @p_eff_date           = @eff_date
                                    , @p_pay_element_id     = ''
                                    , @p_msg_p1             = @cur_emp_status_code
                                    , @p_msg_p2             = ''
                                    , @p_msg_desc           = 'Terminated employee cannot be transferred.'
                                    , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                                    , @p_activity_date      = @p_activity_date
                                    , @p_audit_id           = @aud_id

                                SET @w_fatal_error = 1
                            END
                        ELSE
                            BEGIN
                                -- Associate is a rehire - negate transfer

                                -- Historical Message for reporting purpose
                                EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                                    @p_msg_id             = @msg_id
                                    , @p_event_id           = @v_EVENT_ID_TRANSFER
                                    , @p_emp_id             = @emp_id
                                    , @p_eff_date           = @eff_date
                                    , @p_pay_element_id     = ''
                                    , @p_msg_p1             = @cur_emp_status_code
                                    , @p_msg_p2             = ''
                                    , @p_msg_desc           = 'Terminated employee is a rehire in current extract - bypassing transfer.'
                                    , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                                    , @p_activity_date      = @p_activity_date
                                    , @p_audit_id           = @aud_id

                                SET @w_fatal_error = 1

                            END

                    END


                IF (@w_fatal_error = 1)
                    GOTO BYPASS_EMPLOYEE


                SET @v_cal_year = YEAR(@w_eff_date)



                ---------------------------------------------------------------------------
                -- Lookup new employer/tax entity details
                ---------------------------------------------------------------------------
                SET @v_step_position = 'Lookup New Employer/Tax Entity'

                SELECT @new_taxing_country_code = empl.taxing_country_code
                    , @new_curr_code           = empl.curr_code
                    , @new_tax_entity          = tax_entity_id
                FROM DBShrpn.dbo.employer empl
                JOIN DBShrpn.dbo.empl_tax_entity ete ON
                    (empl.empl_id = ete.empl_id)
                WHERE (empl.empl_id = @empl_id)


                ---------------------------------------------------------------------------
                -- Execute Transfer
                ---------------------------------------------------------------------------
                SET @v_step_position = 'Execute DBShrpn.dbo.usp_upd_hrpn_02_trn'

                EXECUTE DBShrpn.dbo.usp_upd_hrpn_02_trn
                    @p_emp_id                         = @emp_id
                    , @p_empl_id                        = @cur_empl_id
                    , @p_new_empl_id                    = @empl_id
                    , @p_transfer_date                  = @w_eff_date      --CAST(@eff_date AS datetime)
                    , @p_assign_to                      = @cur_emp_asgn_assigned_to_code
                    , @p_job_or_pos_id                  = @cur_emp_asgn_job_or_pos_id       --'99999' -- Default Position
                    , @p_org_grp_id                     = @organization_group_id		--CAST(@organization_group_id AS int)
                    , @p_org_chart_name                 = @organization_chart_name
                    , @p_org_unit_name                  = @organization_unit_name
                    , @p_location                       = @emp_location_code
                    , @p_new_tax_entity_id              = @new_tax_entity
                    , @p_old_tax_entity_id              = @cur_tax_entity_id
                    , @p_eff_date                       = @cur_eempl_eff_date                        --   effective date of current emp_employment record
                    , @p_pay_group                      = @pay_group_id
                    , @p_emp_info_change_reason         = @employment_info_chg_reason_cd
                    , @p_job_position_end_date          = @cur_emp_asgn_job_position_end_date
                    , @p_assignment_end_date            = @cur_emp_asgn_end_date
                    , @p_xfer_different_taxing_cntry    = 'N'                        --   different_taxing_country,
                    , @p_new_empl_taxing_country_cd     = @new_taxing_country_code
                    , @p_new_empl_curr_code             = @new_curr_code
                    , @p_use_policy_xfer_options        = 'Y'                            --   'Y' As policy_xfer_options


                -- Executes transfer updates in DBShrpy (emp_pmt* tables)
                SET @v_step_position = 'Execute DBShrpn.dbo.usp_ins_hpep_02_trn'

                EXECUTE DBShrpy.dbo.usp_ins_hpep_02_trn
                    @p_emp_id                     = @emp_id
                    , @p_old_empl_id                = @cur_empl_id
                    , @p_new_empl_id                = @empl_id
                    , @p_transfer_date              = @w_eff_date      --CAST(@eff_date AS datetime)
                    , @p_calendar_year              = @v_cal_year      --LEFT(convert(varchar(10),@p_transfer_date,112),4)
                    , @p_curr_code                  = @new_curr_code
                    , @p_return_to_prior_empl       = 'N'
                    , @p_empl_adj_paymnt_run_type   = '#ADJUSTMNT'
                    , @p_system_user_id             = 'DBS'
                    , @p_pay_group_id               = @pay_group_id


                ---------------------------------------------------------------------------
                --   Update the Salary in the Assignment Record
                ---------------------------------------------------------------------------
                SET @v_step_position = 'Lookup New Employee Assignment'

                SELECT @new_emp_asgn_assigned_to_code = ea.assigned_to_code
                    , @new_emp_asgn_job_or_pos_id    = ea.job_or_pos_id
                    , @new_emp_asgn_eff_date         = ea.eff_date
                FROM DBShrpn.dbo.uvu_emp_assignment_most_rec ea
                WHERE (emp_id = @emp_id)


                -- GOSL: HCM Salary data will not be interfaced to SS
                -- Blank them out
                SELECT @new_annual_salary_amt                   = 0.00
                    , @new_emp_asgn_hourly_rate_amt            = 0.00
                    , @new_emp_asgn_period_amt                 = 0.00
                    , @new_emp_asgn_salary_change_type_code    = ''
                    , @new_emp_asgn_work_tm_code               = ''
                    , @new_emp_asgn_base_rate_tbl_id           = ''
                    , @new_emp_asgn_base_rate_tbl_entry_code   = ''
                    , @new_emp_asgn_standard_work_pd_id        = ''
                    , @new_emp_asgn_standard_work_hrs          = 0.00
                    , @new_emp_asgn_pd_salary_tm_pd_id         = ''


                UPDATE DBShrpn.dbo.emp_assignment
                SET annual_salary_amt           = @new_annual_salary_amt
                , hourly_pay_rate             = @new_emp_asgn_hourly_rate_amt
                , pd_salary_amt               = @new_emp_asgn_period_amt
                , salary_change_type_code     = @new_emp_asgn_salary_change_type_code
                , work_tm_code                = @new_emp_asgn_work_tm_code
                , base_rate_tbl_id            = @new_emp_asgn_base_rate_tbl_id
                , base_rate_tbl_entry_code    = @new_emp_asgn_base_rate_tbl_entry_code
                , organization_group_id       = @organization_group_id
                , organization_chart_name     = @organization_chart_name
                , organization_unit_name      = @organization_unit_name
                WHERE (emp_id           = @emp_id)
                AND (assigned_to_code = @new_emp_asgn_assigned_to_code)
                AND (job_or_pos_id    = @new_emp_asgn_job_or_pos_id)
                AND (eff_date         = @new_emp_asgn_eff_date)


                ---------------------------------------------------------------------------
                -- Update Labor Group Code
                ---------------------------------------------------------------------------
                -- update latest emp employment record with labor group code
                UPDATE DBShrpn.dbo.emp_employment
                SET labor_grp_code = @labor_grp_code
                WHERE (next_eff_date = @v_END_OF_TIME_DATE)


                ---------------------------------------------------------------------------
                -- GOSL update NIC and Tax Code
                ---------------------------------------------------------------------------
                -- CJP 7/7/2025
                SET @v_step_position = 'Update NIC/Tax Code'

                UPDATE DBShrpn.dbo.individual_personal
                SET user_ind_1 = @nic_flag
                , user_ind_2 = @tax_flag
                FROM DBShrpn.dbo.employee emp
                JOIN DBShrpn.dbo.individual_personal ind ON
                    (emp.individual_id = ind.individual_id)
                WHERE (emp.emp_id = @emp_id)


                ---------------------------------------------------------------------------
                -- Update Processed Flag after successful update
                ---------------------------------------------------------------------------
                UPDATE DBShrpn.dbo.ghr_employee_events_aud
                SET proc_flag = 'Y'
                WHERE (activity_date = @p_activity_date)
                  AND (aud_id        = @aud_id)


            END TRY
            BEGIN CATCH

                SELECT @ErrorNumber   = CAST(ERROR_NUMBER() AS varchar(10))
                    , @ErrorMessage  = @v_step_position + ' - ' + ERROR_MESSAGE()
                    , @ErrorSeverity = ERROR_SEVERITY()
                    , @ErrorState    = ERROR_STATE()

                IF (@@TRANCOUNT > 0)
                    ROLLBACK TRAN

                BEGIN TRAN

                -- Log error
                EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                      @p_msg_id             = @ErrorNumber
                    , @p_event_id           = @v_EVENT_ID_TRANSFER
                    , @p_emp_id             = @emp_id
                    , @p_eff_date           = @eff_date
                    , @p_pay_element_id     = ''
                    , @p_msg_p1             = ''
                    , @p_msg_p2             = ''
                    , @p_msg_desc           = @ErrorMessage
                    , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                    , @p_activity_date      = @p_activity_date
                    , @p_audit_id           = @aud_id


            END CATCH

BYPASS_EMPLOYEE:
            -- committ records before next record in order to maintain log entries
            IF (@@TRANCOUNT > 0)
                COMMIT TRAN

            FETCH crsrHR
            INTO  @aud_id
                , @emp_id
                , @eff_date
                , @first_name
                , @first_middle_name
                , @last_name
                , @empl_id
                , @national_id_type_code
                , @national_id
                , @organization_group_id
                , @organization_chart_name
                , @organization_unit_name
                , @emp_status_classn_code
                , @position_title
                , @employment_type_code
                , @annual_salary_amt
                , @begin_date
                , @end_date
                , @pay_status_code
                , @pay_group_id
                , @pay_element_ctrl_grp_id
                , @time_reporting_meth_code
                , @employment_info_chg_reason_cd
                , @emp_location_code
                , @emp_status_code
                , @reason_code
                , @emp_expected_return_date
                , @pay_through_date
                , @emp_death_date
                , @consider_for_rehire_ind
                , @pay_element_id
                , @emp_calculation
                , @tax_flag
                , @nic_flag
                , @tax_ceiling_amt
                , @labor_grp_code
                , @file_source

        END  -- While Loop

        -- Cleanup Cursor
        CLOSE crsrHR
        DEALLOCATE crsrHR

        -- commit after every record
        IF (@@TRANCOUNT > 0)
            COMMIT TRAN


        ---------------------------------------------------------------------------
        -- Log warning message U00000 -- < EMPLOYEE TRANSFER SECTION (3) >
        ---------------------------------------------------------------------------

        SET @msg_id = 'U00017'
        SET @v_step_position = 'Log ' + @msg_id

        SELECT @w_msg_text    = msg_text
            , @w_msg_text_2  = msg_text_2
            , @w_msg_text_3  = msg_text_3
            , @w_severity_cd = severity_cd
        FROM #tbl_msg_master
        WHERE (msg_id = @msg_id)

        EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2
            @userid   = @p_user_id
            , @batch    = @p_batchname
            , @qual     = @p_qualifier
            , @msgno    = @msg_id
            , @severity = @w_severity_cd
            , @text     = @w_msg_text
            , @text_2   = @w_msg_text_2
            , @text_3   = @w_msg_text_3


        ---------------------------------------------------------------------------
        -- Send notification of warning message U00009  -- < BEGINING OF WARNING MESSAGES: >
        ---------------------------------------------------------------------------
        SET @msg_id = 'U00009'
        SET @v_step_position = 'Log ' + @msg_id

        SELECT @w_msg_text    = msg_text
            , @w_msg_text_2  = msg_text_2
            , @w_msg_text_3  = msg_text_3
            , @w_severity_cd = severity_cd
        FROM #tbl_msg_master
        WHERE (msg_id = @msg_id)

        EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2
            @userid   = @p_user_id
            , @batch    = @p_batchname
            , @qual     = @p_qualifier
            , @msgno    = @msg_id
            , @severity = @w_severity_cd
            , @text     = @w_msg_text
            , @text_2   = @w_msg_text_2
            , @text_3   = @w_msg_text_3


        ---------------------------------------------------------------------------
        -- Send notification of warning message U00011 -- Blank Line
        ---------------------------------------------------------------------------
        SET @msg_id = 'U00011'
        SET @v_step_position = 'Log ' + @msg_id

        SELECT @w_msg_text    = msg_text
            , @w_msg_text_2  = msg_text_2
            , @w_msg_text_3  = msg_text_3
            , @w_severity_cd = severity_cd
        FROM #tbl_msg_master
        WHERE (msg_id = @msg_id)

        EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2
            @userid   = @p_user_id
            , @batch    = @p_batchname
            , @qual     = @p_qualifier
            , @msgno    = @msg_id
            , @severity = @w_severity_cd
            , @text     = @w_msg_text
            , @text_2   = @w_msg_text_2
            , @text_3   = @w_msg_text_3


        ---------------------------------------------------------------------------
        -- Send notification of warning message U00003 - Total nbr of employees that already exist: @1
        ---------------------------------------------------------------------------
        SET @msg_id = 'U00018'
        SET @v_step_position = 'Log ' + @msg_id

        SELECT @msg_id        = msg_id
            , @w_msg_text    = msg_text
            , @w_msg_text_2  = msg_text_2
            , @w_msg_text_3  = msg_text_3
            , @w_severity_cd = severity_cd
        FROM #tbl_msg_master
        WHERE (msg_id = @msg_id)

        -- Get total new hire records from HCM
        SELECT @maxx = CAST(COUNT(*) AS varchar(6))
        FROM #tbl_ghr_msg
        WHERE (msg_id = @msg_id)

        SET @w_msg_text = REPLACE(@w_msg_text, '@1', @maxx)

        EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2
            @userid   = @p_user_id
            , @batch    = @p_batchname
            , @qual     = @p_qualifier
            , @msgno    = @msg_id
            , @severity = @w_severity_cd
            , @text     = @w_msg_text
            , @text_2   = @w_msg_text_2
            , @text_3   = @w_msg_text_3


        ---------------------------------------------------------------------------
        -- Add log entries that contain employee details
        ---------------------------------------------------------------------------
        SET @v_step_position = 'Log Cursor'

        -- Loop through tbl_ghr_msg to populate error message log entry
        DECLARE crsrLog CURSOR FAST_FORWARD FOR
        SELECT msg.msg_id
            , msg.severity_cd
            , ghr.msg_desc
            , msg.msg_text_2
            , msg.msg_text_3
        FROM #tbl_ghr_msg ghr
        JOIN #tbl_msg_master msg ON
            (ghr.msg_id = msg.msg_id)
        WHERE (msg.loop_flag = 'Y')

        OPEN crsrLog

        FETCH crsrLog
        INTO @msg_id
        , @w_severity_cd
        , @w_msg_text
        , @w_msg_text_2
        , @w_msg_text_3



        WHILE (@@FETCH_STATUS = 0)
        BEGIN
            -- Add entries to DBSpscb..ssw_psc_messages_work
            EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2
                @userid   = @p_user_id
                , @batch    = @p_batchname
                , @qual     = @p_qualifier
                , @msgno    = @msg_id
                , @severity = @w_severity_cd
                , @text     = @w_msg_text
                , @text_2   = @w_msg_text_2
                , @text_3   = @w_msg_text_3

        FETCH crsrLog
        INTO @msg_id
        , @w_severity_cd
        , @w_msg_text
        , @w_msg_text_2
        , @w_msg_text_3

        END

        CLOSE crsrLog
        DEALLOCATE crsrLog


        ---------------------------------------------------------------------------
        -- Send notification of warning message U00011 -- Blank Line
        ---------------------------------------------------------------------------
        SET @msg_id = 'U00011'
        SET @v_step_position = 'Log ' + @msg_id

        SELECT @w_msg_text    = msg_text
            , @w_msg_text_2  = msg_text_2
            , @w_msg_text_3  = msg_text_3
            , @w_severity_cd = severity_cd
        FROM #tbl_msg_master
        WHERE (msg_id = @msg_id)

        EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2
            @userid   = @p_user_id
            , @batch    = @p_batchname
            , @qual     = @p_qualifier
            , @msgno    = @msg_id
            , @severity = @w_severity_cd
            , @text     = @w_msg_text
            , @text_2   = @w_msg_text_2
            , @text_3   = @w_msg_text_3


        ---------------------------------------------------------------------------
        -- Send notification of warning message U00010 -- <ENDING OF WARNING MESSAGES: >
        ---------------------------------------------------------------------------
        SET @msg_id = 'U00010'
        SET @v_step_position = 'Log ' + @msg_id

        SELECT @w_msg_text    = msg_text
            , @w_msg_text_2  = msg_text_2
            , @w_msg_text_3  = msg_text_3
            , @w_severity_cd = severity_cd
        FROM #tbl_msg_master
        WHERE (msg_id = @msg_id)

        EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2
            @userid   = @p_user_id
            , @batch    = @p_batchname
            , @qual     = @p_qualifier
            , @msgno    = @msg_id
            , @severity = @w_severity_cd
            , @text     = @w_msg_text
            , @text_2   = @w_msg_text_2
            , @text_3   = @w_msg_text_3


        ---------------------------------------------------------------------------
        -- Send notification of warning message U00011 -- Blank Line
        ---------------------------------------------------------------------------
        SET @msg_id = 'U00011'
        SET @v_step_position = 'Log ' + @msg_id

        SELECT @w_msg_text    = msg_text
            , @w_msg_text_2  = msg_text_2
            , @w_msg_text_3  = msg_text_3
            , @w_severity_cd = severity_cd
        FROM #tbl_msg_master
        WHERE (msg_id = @msg_id)

        EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2
            @userid   = @p_user_id
            , @batch    = @p_batchname
            , @qual     = @p_qualifier
            , @msgno    = @msg_id
            , @severity = @w_severity_cd
            , @text     = @w_msg_text
            , @text_2   = @w_msg_text_2
            , @text_3   = @w_msg_text_3

        SET @v_step_position = 'End Logging'

    END TRY
    BEGIN CATCH

        SELECT @ErrorNumber   = CAST(ERROR_NUMBER() AS varchar(10))
             , @ErrorMessage  = @v_step_position + ' - ' + ERROR_MESSAGE()
             , @ErrorSeverity = ERROR_SEVERITY()
             , @ErrorState    = ERROR_STATE()
             , @v_ret_val      = -1

        -- Handle cursors
        IF (CURSOR_STATUS('local', 'crsrHR') > 0)
        BEGIN
            CLOSE crsrHR
            DEALLOCATE crsrHR
        END

        IF (CURSOR_STATUS('local', 'crsrLog') > 0)
        BEGIN
            CLOSE crsrLog
            DEALLOCATE crsrLog
        END

        -- Historical Message for reporting purpose
        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
              @p_msg_id             = @ErrorNumber
            , @p_event_id           = @v_EVENT_ID_TRANSFER
            , @p_emp_id             = @emp_id
            , @p_eff_date           = @eff_date
            , @p_pay_element_id     = ''
            , @p_msg_p1             = ''
            , @p_msg_p2             = ''
            , @p_msg_desc           = @ErrorMessage
            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
            , @p_activity_date      = @p_activity_date
            , @p_audit_id           = @aud_id

        RAISERROR(@ErrorMessage
                , @ErrorSeverity
                , @ErrorState
                  );

    END CATCH


    -- Cleanup temp tables
    DROP TABLE #temp1
    DROP TABLE #temp4
    DROP TABLE #temp5
    DROP TABLE #temp6
    DROP TABLE #temp7
    DROP TABLE #temp8
    DROP TABLE #temp9
    DROP TABLE #temp11
    DROP TABLE #temp12
    DROP TABLE #temp14
    DROP TABLE #temp15
    DROP TABLE #tbl_ghr_msg
    DROP TABLE #tbl_msg_master

    RETURN @v_ret_val

END
GO

ALTER AUTHORIZATION ON dbo.usp_perform_transfer TO  SCHEMA OWNER
GO

IF OBJECT_ID(N'dbo.usp_perform_transfer', N'P') IS NOT NULL
    PRINT N'<<< CREATED PROCEDURE dbo.usp_perform_transfer >>>'
ELSE
    PRINT N'<<< FAILED CREATING PROCEDURE dbo.usp_perform_transfer >>>'
GO
