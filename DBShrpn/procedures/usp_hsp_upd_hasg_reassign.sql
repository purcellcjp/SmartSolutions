USE DBShrpn
go
IF OBJECT_ID(N'dbo.usp_hsp_upd_hasg_reassign') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_hsp_upd_hasg_reassign
    IF OBJECT_ID(N'dbo.usp_hsp_upd_hasg_reassign') IS NOT NULL
        PRINT N'<<< FAILED DROPPING PROCEDURE dbo.usp_hsp_upd_hasg_reassign >>>'
    ELSE
        PRINT N'<<< DROPPED PROCEDURE dbo.usp_hsp_upd_hasg_reassign >>>'
END
go
SET ANSI_NULLS ON
go
/*************************************************************************************

   SP Name:      usp_hsp_upd_hasg_reassign

   Description:  Updates SmartStream table DBShrpn..emp_assignment.

                 Cloned from DBShrpn..usp_hsp_upd_hasg_reassign in order to use with
                 HCM Interface position title update procedure DBShrpn..usp_ins_position_title.

   Parameters:


   Tables

   Example:
      exec usp_hsp_upd_hasg_reassign ....

   Revision history:
      version  date        developer   SCR      description
      -------  ----------  ---------   -----    ------------------------------------
      1.0.00   10/27/2025  CJP                  - Cloned from SmmartStream version DBShrpn..hsp_upd_hasg_reassign
                                                    1) Disabled authentication
                                                    2) Replaced all double quotes with single quote

************************************************************************************/


create procedure [dbo].[usp_hsp_upd_hasg_reassign]
                /*------------------------------------------------------*/
                /*   Following parms are required by the APPLICATION    */
                /*   and ASSIGNMENT windows                             */
                /*------------------------------------------------------*/
                @asg_cur_id                  char(15),
                @asg_cur_assign_to           char(01),
                @asg_cur_assign_id           char(10),
                @asg_cur_eff_date            datetime,
                @asg_cur_chgstamp            smallint,
                @asg_new_assign_to           char(01),
                @asg_new_assign_id           char(10),
                @asg_new_assign_reason       char(05),
                @asg_new_beg_date            datetime,
                @asg_new_end_date            datetime,
                @asg_fte_error_level         char(01),
                @asg_incumbent_error_level   char(01),
                @asf_fs_error_level          char(01),
                @asg_new_work_time_ind       char(01),
                @asg_new_std_hours           float,
                @asg_new_std_work_period     char(05),
                @asg_new_salary_chg_date     datetime,
                @asg_new_pd_salry            money,
                @asg_new_hourly_rate         float,
                @asg_new_annual_salry        money,
                @asg_new_fte                 float,
                /*------------------------------------------------------*/
                /*   Following parms are required by the APPLICATION    */
                /*   window                                             */
                /*------------------------------------------------------*/
                @app_offer_curr_code         char(03),
                @app_offer_pd_salary_time_cd char(05),
                @app_offer_org_chart_id      char(64),
                @app_offer_org_unit_id       char(240),
                @app_offer_pay_hours_rpt_ind char(01),
                @app_offer_work_shift_code   char(05),
                @app_offer_pay_grade         char(06),
                @app_offer_points            smallint,
                @app_offer_salary_step       smallint,
                @app_offer_mgr_emp_id        char(15),
                @from_window                 char(04),
                /*------------------------------------------------------*/
                /* The following parms are new 4.0 release              */
                /*------------------------------------------------------*/
                @w_primary_ind               char(01),
                @w_new_guar_pd_salry         money,
                @w_new_guar_hourly_rate      float,
                @w_new_guar_annual_salry     money,
                @w_new_ref_pd_salry          money,
                @w_new_ref_hourly_rate       float,
                @w_new_ref_salry             money,
                @w_new_org_group             int,
                @app_new_shift_rate_id       char(10)
as

/* -------------------------------------------------------------------- */
/* Authenticate the use of this stored procedure                        */
/* -------------------------------------------------------------------- */
      declare @w_ret              int,
              @W_ACTION_DATETIME  char(30)

      --execute @w_ret = sp_dbs_authenticate

      --if @w_ret != 0
      --    return


/* ==================================================================== */
/* SECTION 1 : Initialize Workareas                                     */
/*   --  Initialize work area's required by the reassign process        */
/*   --  Pick up Employees Current Assignment                           */
/* -------------------------------------------------------------------- */
      declare
          @w_new_chgstamp                    smallint,
          @w_error_number                    int,
          @cur_eff_date                      datetime,
          @cur_end_date                      datetime,
          @w_em_20001                        char(50),
          @w_em_20002                        char(50),
          @w_em_34506                        char(50),
          @w_em_34507                        char(50),
          @w_em_34514                        char(50),
          @w_em_34536                        char(50),
          @w_em_28506                        char(50),
          @w_end_of_time                     datetime,
          @w_jp_eff_date                     datetime,
          @w_jp_beg_date                     datetime,
          @w_jp_end_date                     datetime,
          @w_jp1_eff_date                    datetime,
          @w_jp1_beg_date                    datetime,
          @w_jp1_end_date                    datetime,
          @w_continue                        char(01),
          @w_asgn_cur_enddt                  datetime,
          @w_asgn_cur_effdt                  datetime,
          @w_asgn_new_begdt                  datetime,
/* -------------------------------------------------------------------- */
/* EMP_ASSIGNMENT table definitions                                     */
/* -------------------------------------------------------------------- */
          /*------------------------------------------------------------*/
          /*    dw_singlerow = hpn0630_employee_assgn_header            */
          /*------------------------------------------------------------*/
          @employee_identifier              char(15),
          @emp_asgmt_assigned_to_code       char(01),
          @emp_asgmt_job_or_pos_id          char(10),
          @emp_asgmt_eff_date               datetime,
          @emp_asgmt_next_eff_date          datetime,
          @emp_asgmt_prior_eff_dt           datetime,
          @emp_asgmt_begin_date             datetime,
          @emp_asgmt_end_date               datetime,
          /*------------------------------------------------------------*/
          /*    dw_2 = hpn0630_employee_assgn_basic                     */
          /*------------------------------------------------------------*/
           @emp_asgmt_reason_code            char(05),
           @emp_prime_assignment_ind         char(01),
           @emp_occupancy_code               char(01),
           @emp_asgmt_official_title_code    char(05),
           @emp_asgmt_official_title_date    datetime,
           @emp_asgmt_salary_ind             char(1),
           /*------------------------------------------------------------*/
           /*    dw_3 = hpn0630_employee_assgn_salary_hours              */
           /*------------------------------------------------------------*/
           @emp_asgmt_annual_salary          money,
           @emp_asgmt_salary_curr_cd         char(03),
           @emp_asgmt_pd_salary              money,
           @emp_pay_on_rptd_hrs_ind          char(01),
           @emp_asgmt_hourly_pay_rate        float,
           @emp_asgmt_salary_change_type     char(05),
           @emp_asgmt_standard_work_hrs      float,
           @emp_asgmt_standard_work_pd_id    char(05),
           @emp_asgmt_work_tm_code           char(01),
           @emp_pay_basis_code               char(01),
           @emp_asgmt_salary_change_date     datetime,
           @emp_asgmt_pd_salary_tm_pd        char(05),
           @emp_base_rate_tbl_id             char(10),
           @emp_base_rate_tbl_entry_code     char(08),
           @emp_exception_rate_ind           char(01),
           @emp_overtime_status_code         char(02),
           @emp_standard_daily_work_hrs      float,
           /*------------------------------------------------------------*/
           /*    dw_4 = hpn0630_employee_assgn_compensation              */
           /*------------------------------------------------------------*/
           @emp_asgmt_salary_structure_id    char(10),
           @emp_asgmt_increase_guidel_id     char(10),
           @emp_asgmt_pay_grade              char(06),
           @emp_asgmt_pay_grade_date         datetime,
           @emp_asgmt_job_eval_points        smallint,
           @emp_asgmt_salary_step            smallint,
           @emp_asgmt_salary_step_date       datetime,
           /*------------------------------------------------------------*/
           /*    dw_5 = hpn0630_employee_assgn_telephones                */
           /*------------------------------------------------------------*/
           @emp_asgmt_phn1_type_code         char(05),
           @emp_asgmt_phn1_fmt_code          char(06),
           @emp_asgmt_phn1_fmt_delimeter     char(01),
           @emp_asgmt_phn2_type_code         char(05),
           @emp_asgmt_phn2_fmt_code          char(06),
           @emp_asgmt_phn2_fmt_delimeter     char(01),
           @emp_asgmt_phn1_intl_code         char(04),
           @emp_asgmt_phn1_country_code      char(04),
           @emp_asgmt_phn1_area_city_code    char(05),
           @emp_asgmt_phn1_nbr               char(12),
           @emp_asgmt_phn1_ext_nbr           char(05),
           @emp_asgmt_phn2_intl_code         char(04),
           @emp_asgmt_phn2_country_code      char(04),
           @emp_asgmt_phn2_area_city_code    char(05),
           @emp_asgmt_phn2_nbr               char(12),
           @emp_asgmt_phn2_ext_nbr           char(05),
           /*------------------------------------------------------------*/
           /*    dw_6 = hpn0630_employee_assgn_user_flds                 */
           /*------------------------------------------------------------*/
           @emp_asgmt_user_amt_1             float,
           @emp_asgmt_user_amt_2             float,
           @emp_asgmt_user_code_1            char(05),
           @emp_asgmt_user_code_2            char(05),
           @emp_asgmt_user_date_1            datetime,
           @emp_asgmt_user_date_2            datetime,
           @emp_asgmt_user_ind_1             char(01),
           @emp_asgmt_user_ind_2             char(01),
           @emp_user_monetary_amt_1          money,
           @emp_user_monetary_amt_2          money,
           @emp_user_monetary_curr_code      char(03),
           @emp_user_text_1                  char(50),
           @emp_user_text_2                  char(50),
           /*------------------------------------------------------------*/
           /*    dw_7 = hpn0630_employee_assgn_org                       */
           /*------------------------------------------------------------*/
           @emp_asgmt_org_chart_id           char(64),
           @emp_asgmt_org_unit_id            char(240),
           @emp_asgmt_org_change_reason      char(05),
           @emp_asgmt_loc_code               char(10),
           @emp_asgmt_mgr_emp_id             char(15),
           @emp_organization_group_id	     float,
           @emp_regulatory_rtg_unit_code     char(10),
           @emp_unemployment_loc_code        char(10),
           /*------------------------------------------------------------*/
           /*    dw_8 = hpn0630_employee_assgn_addl_salary               */
           /*------------------------------------------------------------*/
           @emp_shift_diff_rate_tbl_id       char(10),
           @emp_asgmt_work_shift_code        char(05),
           @emp_shift_diff_status_code       char(02),
           @emp_ref_annual_salary_amt        money,
           @emp_ref_pd_salary_amt            money,
           @emp_ref_pd_salary_tm_pd_id       char(5),
           @emp_ref_hourly_pay_rate          float,
           @emp_guar_annual_salary_amt       money,
           @emp_guar_pd_salary_amt           money,
           @emp_guar_pd_salary_tm_pd_id      char(5),
           @emp_guar_hourly_pay_rate         float,
           /*------------------------------------------------------------*/
           /*    dw_9 = hpn0630_employee_assgn_distribution              */
           /*------------------------------------------------------------*/
           @emp_asgmt_next_asgd_to_code      char(01),
           @emp_asgmt_next_job_or_pos_id     char(10),
           @emp_asgmt_prior_asgd_to_code     char(01),
           @emp_asgmt_prior_job_or_pos_id    char(10),
           @emp_chgstamp                     smallint,
/* -------------------------------------------------------------------- */
/*  define job columns to be used as defaults for assignment            */
/* -------------------------------------------------------------------- */
           @w_job_salary_step                 smallint,
           @w_job_pay_grade                   char(06),
           @w_job_points                      smallint,
/* -------------------------------------------------------------------- */
/*  define position columns to be used by validation for filling status */
/* -------------------------------------------------------------------- */
           @w_pos_eff_date                   datetime,
           @w_pos_nxt_date                   datetime,
           @w_pos1_nxt_date                  datetime,
           @w_pos_beg_date                   datetime,
           @w_pos_end_date                   datetime,
           @w_pos_allowed_fte                float,
           @w_pos_allowed_incumbent          float,
           @w_total_incumbents               float,
           @w_total_fte_hrs                  float,
           @w_filled_incumbents              float,
           @w_filled_fte_hrs                 float,
           @w_fill_incumb_01                 int,
           @w_fill_incumb_02                 int,
           @w_future_assignment_ind          char(01),
           @w_pos_policy                     char(08),
           @w_pos_frozen_ind                 char(01),
           @w_pos_plcy_aprvl_cd              char(02),
           @w_pos_plcy_budgt_cd              char(02),
           @w_pos_plcy_fund_cd               char(02),
           @w_pos_pay_grade                  char(06),
           @w_pos_points                     smallint,
           @w_pos_salary_step                smallint,
/* -------------------------------------------------------------------- */
/*  define policy columns to be used by validation for filling status   */
/* -------------------------------------------------------------------- */
           @w_pop_plcy_filerr_cd             char(01),
           @w_pop_plcy_aprvl_cd              char(02),
           @w_pop_plcy_budgt_cd              char(02),
           @w_pop_plcy_fund_cd               char(02),
           @w_pop_incumbent_errcd_cd         char(01),
           @w_pop_fte_errcd_cd               char(01),
           @w_shift_work_rate_cd             char(10)

/* -------------------------------------------------------------------- */
/* initialize variables required by this procedure                      */
/* -------------------------------------------------------------------- */
    select
         @w_end_of_time  = '12/31/2999',
         @w_jp_eff_date  = '12/31/2999',
         @w_jp_beg_date  = '12/31/2999',
         @w_jp_end_date  = '12/31/2999',
         @cur_eff_date   = @asg_cur_eff_date,
         @w_em_20001     = 'Row updated by another user ',
         @w_em_20002     = 'Row does not exist',
         @w_em_34506     = 'Position policy id corrupted in the d/b',
         @w_em_34507     = 'Position fill status fails policy requirements',
         @w_em_34514     = 'Employee not assigned, fill status not meet',
         @w_em_34536     = 'Position is frozen',
         @w_em_28506     = 'D/B error inserting new Employee Assignment',
         @w_error_number = 0,
         @employee_identifier        = @asg_cur_id,
         @emp_asgmt_assigned_to_code = @asg_cur_assign_to,
         @emp_asgmt_job_or_pos_id    = @asg_cur_assign_id,
         @emp_asgmt_eff_date         = @asg_cur_eff_date,
         @emp_chgstamp               = @asg_cur_chgstamp

    /* ---------------------------------------------------------------- */
    /* Pick up current Employee Assignment for use in formating the new */
    /* Employee Assignment                                              */
    /* ---------------------------------------------------------------- */
    select @emp_asgmt_next_eff_date       = next_eff_date,
           @emp_asgmt_prior_eff_dt        = prior_eff_date,
           @emp_asgmt_next_asgd_to_code   = next_assigned_to_code,
           @emp_asgmt_next_job_or_pos_id  = next_job_or_pos_id,
           @emp_asgmt_prior_asgd_to_code  = next_assigned_to_code,
           @emp_asgmt_prior_job_or_pos_id = next_job_or_pos_id,
           @emp_asgmt_begin_date          = begin_date,
           @emp_asgmt_end_date            = end_date,
           @emp_asgmt_reason_code         = assignment_reason_code,
           @emp_asgmt_org_chart_id        = organization_chart_name,
           @emp_asgmt_org_unit_id         = organization_unit_name,
           @emp_organization_group_id     = organization_group_id,
           @emp_asgmt_org_change_reason   = organization_change_reason_cd,
           @emp_asgmt_loc_code            = loc_code,
           @emp_asgmt_mgr_emp_id          = mgr_emp_id,
           @emp_asgmt_official_title_code = official_title_code,
           @emp_asgmt_official_title_date = official_title_date,
           @emp_asgmt_salary_change_date  = salary_change_date,
           @emp_asgmt_salary_change_type  = salary_change_type_code,
           @emp_asgmt_annual_salary       = annual_salary_amt,
           @emp_asgmt_pd_salary           = pd_salary_amt,
           @emp_asgmt_pd_salary_tm_pd     = pd_salary_tm_pd_id,
           @emp_asgmt_hourly_pay_rate     = hourly_pay_rate,
           @emp_asgmt_salary_curr_cd      = curr_code,
           @emp_pay_on_rptd_hrs_ind       = pay_on_reported_hrs_ind,
           @emp_asgmt_standard_work_hrs   = standard_work_hrs,
           @emp_asgmt_standard_work_pd_id = standard_work_pd_id,
           @emp_asgmt_work_tm_code        = work_tm_code,
           @emp_asgmt_work_shift_code     = work_shift_code,
           @emp_asgmt_salary_structure_id = salary_structure_id,
           @emp_asgmt_increase_guidel_id  = salary_increase_guideline_id,
           @emp_asgmt_pay_grade           = pay_grade_code,
           @emp_asgmt_pay_grade_date      = pay_grade_date,
           @emp_asgmt_job_eval_points     = job_evaluation_points_nbr,
           @emp_asgmt_salary_step         = salary_step_nbr,
           @emp_asgmt_salary_step_date    = salary_step_date,
           @emp_asgmt_phn1_type_code      = phone_1_type_code,
           @emp_asgmt_phn1_fmt_code       = phone_1_fmt_code,
           @emp_asgmt_phn1_fmt_delimeter  = phone_1_fmt_delimiter,
           @emp_asgmt_phn1_intl_code      = phone_1_intl_code,
           @emp_asgmt_phn1_country_code   = phone_1_country_code,
           @emp_asgmt_phn1_area_city_code = phone_1_area_city_code,
           @emp_asgmt_phn1_nbr            = phone_1_nbr,
           @emp_asgmt_phn1_ext_nbr        = phone_1_extension_nbr,
           @emp_asgmt_phn2_type_code      = phone_2_type_code,
           @emp_asgmt_phn2_fmt_code       = phone_2_fmt_code,
           @emp_asgmt_phn2_fmt_delimeter  = phone_2_fmt_delimiter,
           @emp_asgmt_phn2_intl_code      = phone_2_intl_code,
           @emp_asgmt_phn2_country_code   = phone_2_country_code,
           @emp_asgmt_phn2_area_city_code = phone_2_area_city_code,
           @emp_asgmt_phn2_nbr            = phone_2_nbr,
           @emp_asgmt_phn2_ext_nbr        = phone_2_extension_nbr,
           @emp_asgmt_user_amt_1          = user_amt_1,
           @emp_asgmt_user_amt_2          = user_amt_2,
           @emp_asgmt_user_code_1         = user_code_1,
           @emp_asgmt_user_code_2         = user_code_2,
           @emp_asgmt_user_date_1         = user_date_1,
           @emp_asgmt_user_date_2         = user_date_2,
           @emp_asgmt_user_ind_1          = user_ind_1,
           @emp_asgmt_user_ind_2          = user_ind_2,
           @emp_prime_assignment_ind      = prime_assignment_ind,
           @emp_pay_basis_code            = pay_basis_code,
           @emp_occupancy_code            = occupancy_code,
           @emp_regulatory_rtg_unit_code  = regulatory_reporting_unit_code,
           @emp_base_rate_tbl_id          = base_rate_tbl_id,
           @emp_base_rate_tbl_entry_code  = base_rate_tbl_entry_code,
           @emp_shift_diff_rate_tbl_id    = shift_differential_rate_tbl_id,
           @emp_ref_annual_salary_amt     = ref_annual_salary_amt,
           @emp_ref_pd_salary_amt         = ref_pd_salary_amt,
           @emp_ref_pd_salary_tm_pd_id    = ref_pd_salary_tm_pd_id,
           @emp_ref_hourly_pay_rate       = ref_hourly_pay_rate,
           @emp_guar_annual_salary_amt    = guaranteed_annual_salary_amt,
           @emp_guar_pd_salary_amt        = guaranteed_pd_salary_amt,
           @emp_guar_pd_salary_tm_pd_id   = guaranteed_pd_salary_tm_pd_id,
           @emp_guar_hourly_pay_rate      = guaranteed_hourly_pay_rate,
           @emp_exception_rate_ind        = exception_rate_ind,
           @emp_overtime_status_code      = overtime_status_code,
           @emp_shift_diff_status_code    = shift_differential_status_code,
           @emp_standard_daily_work_hrs   = standard_daily_work_hrs,
           @emp_user_monetary_amt_1       = user_monetary_amt_1,
           @emp_user_monetary_amt_2       = user_monetary_amt_2,
           @emp_user_monetary_curr_code   = user_monetary_curr_code,
           @emp_user_text_1               = user_text_1,
           @emp_user_text_2               = user_text_2,
           @emp_unemployment_loc_code     = unemployment_loc_code,
           @emp_asgmt_salary_ind          = include_salary_in_autopay_ind
      from  emp_assignment
      where emp_id           = @employee_identifier
       and  assigned_to_code = @emp_asgmt_assigned_to_code
       and  job_or_pos_id    = @emp_asgmt_job_or_pos_id
       and  eff_date         = @emp_asgmt_eff_date
       and  chgstamp         = @emp_chgstamp

    if @@rowcount = 0
    begin
       if exists (select * from emp_assignment
                    where emp_id           = @employee_identifier
                      and assigned_to_code = @emp_asgmt_assigned_to_code
                      and job_or_pos_id    = @emp_asgmt_job_or_pos_id
                      and eff_date         = @emp_asgmt_eff_date)
                 begin
--SYBSQL            raiserror 20001 @w_em_20001
         select @w_em_20001 = '20001 ' + @w_em_20001
          raiserror (@w_em_20001,16,0)
                  end
       else
                 begin
--SYBSQL            raiserror 20002 @w_em_20002
         select @w_em_20002 = '20002 ' + @w_em_20002
          raiserror (@w_em_20002,16,0)
                 end
       return
    end
/* -------------------------------------------------------------------- */
/* SECTION 1 :           Completion                                     */
/* ==================================================================== */

begin transaction
/* ==================================================================== */
/* SECTION 2 : Validate New Employee Assignment                         */
/*   -- Verify Employee not currently assigned to job/position          */
/*   -- Verify Employee not assigned to job/position in the future      */
/*   -- Verify assignment is valid within the range of job/position     */
/*   -- Validate Assignment against Position occupancy rules            */
/* -------------------------------------------------------------------- */

    /*------------------------------------------------------------------*/
    /*   Verify Employee not currently assigned to job/position         */
    /*------------------------------------------------------------------*/
    execute hsp_sel_hasg_dates @asg_cur_id,
                               @asg_new_assign_to,
                               @asg_new_assign_id,
                               @asg_new_beg_date,     '<=',
                               @w_jp1_beg_date output,
                               @w_jp1_eff_date output,
                               @w_jp1_end_date output
    if @w_jp1_beg_date != @w_end_of_time
    begin
       if @w_jp1_end_date = @w_end_of_time
           begin
              /*-------------------------------------------------------*/
              /* employee is already assigned to this job/position     */
              /*-------------------------------------------------------*/
              select @w_error_number = 26177,
                     @w_jp_beg_date  = @w_jp1_beg_date,
                     @w_jp_eff_date  = @w_jp1_eff_date,
                     @w_jp_end_date  = @w_jp1_end_date
              goto exit_chg_rea_date
           end
       else
           if @w_jp1_end_date = @asg_new_beg_date  or
              @w_jp1_end_date > @asg_new_beg_date
               begin
                  select @w_error_number = 26177,
                         @w_jp_beg_date  = @w_jp1_beg_date,
                         @w_jp_eff_date  = @w_jp1_eff_date,
                         @w_jp_end_date  = @w_jp1_end_date
                  goto exit_chg_rea_date
               end
    end

    /*---------------------------------------------------------------*/
    /* Verify Employee not assigned to job/position in the future    */
    /*---------------------------------------------------------------*/
    execute hsp_sel_hasg_dates @asg_cur_id,
                               @asg_new_assign_to,
                               @asg_new_assign_id,
                               @w_end_of_time,     '<=',
                               @w_jp_beg_date output,
                               @w_jp_eff_date output,
                               @w_jp_end_date output
    if @w_jp_beg_date != @w_end_of_time
    begin
       if @w_jp_beg_date != @w_jp1_beg_date
           begin
              /*-----------------------------------------------------*/
              /* employee is already assigned to this job/position   */
              /*-----------------------------------------------------*/
              select @w_error_number = 26178
              goto exit_chg_rea_date
           end
    end

    /*----------------------------------------------------------------*/
    /* Verify assignment is valid within the range of job/position    */
    /*----------------------------------------------------------------*/
    if @asg_new_assign_to = 'J'
        /*------------------------------------------------------------*/
        /* employee is assigned to a JOB                              */
        /*------------------------------------------------------------*/
        begin
           /*---------------------------------------------------------*/
           /* Pick up the key dates for this JOB                      */
           /*---------------------------------------------------------*/
           execute hsp_sel_hjob_dates @asg_new_assign_id,
                                      @asg_new_beg_date,     '<=',
                                      @w_jp_beg_date output,
                                      @w_jp_eff_date output,
                                      @w_jp_end_date output
           /*---------------------------------------------------------*/
           /* Validate existance of the JOB                           */
           /*---------------------------------------------------------*/
           if @w_jp_beg_date = @w_end_of_time
           begin
              execute hsp_sel_hjob_dates @asg_new_assign_id,
                                         @asg_new_beg_date,     '>',
                                         @w_jp_beg_date output,
                                         @w_jp_eff_date output,
                                         @w_jp_end_date output
              if @w_jp_beg_date = @w_end_of_time
                  begin
                     /*-------------------------------------------*/
                     /* JOB does not exist                        */
                     /*-------------------------------------------*/
                     select @w_error_number = 26132
                     goto exit_chg_rea_date
                  end
              else
                  begin
                     /*-------------------------------------------*/
                     /* JOB exists in the future                  */
                     /*-------------------------------------------*/
                     select @w_error_number = 26129
                     goto exit_chg_rea_date
                  end
           end

           /*------------------------------------------------------*/
           /* Validate the assignment begin/end dates against the  */
           /* job's begin/end dates                                */
           /*------------------------------------------------------*/
           if @w_jp_end_date != @w_end_of_time
           begin
              /*---------------------------------------------------*/
              /* Make sure the client begin date is within the     */
              /* boundries of this job's end date.                 */
              /*---------------------------------------------------*/
              if @asg_new_beg_date > @w_jp_end_date
              begin
                 select @w_error_number = 26130
                 goto exit_chg_rea_date
              end
              /*---------------------------------------------------*/
              /* if client provided end date, make sure the        */
              /* clients end date is within this job's end         */
              /* date.                                             */
              /*---------------------------------------------------*/
              if @asg_new_end_date != @w_end_of_time
              begin
                  if @asg_new_end_date > @w_jp_end_date
                  begin
                     select @w_error_number = 26131
                     goto exit_chg_rea_date
                  end
              end
           end

           /*------------------------------------------------------*/
           /* Default the assignment end date if not provided by   */
           /* the client                                           */
           /*------------------------------------------------------*/
           if @asg_new_end_date = @w_end_of_time
           begin
              select @asg_new_end_date = @w_jp_end_date
           end
        end
    else
        /*---------------------------------------------------------*/
        /* Employee is assigned to a POSITION                      */
        /*---------------------------------------------------------*/
        begin
           /*------------------------------------------------------*/
           /* Pick up the key dates for this POSITION              */
           /*------------------------------------------------------*/
           execute hsp_sel_hpos_dates @asg_new_assign_id,
                                      @asg_new_beg_date,     '<=',
                                      @w_jp_beg_date output,
                                      @w_jp_eff_date output,
                                      @w_jp_end_date output
           /*------------------------------------------------------*/
           /* Validate existance of the POSITION                   */
           /*------------------------------------------------------*/
           if @w_jp_beg_date = @w_end_of_time
           begin
              execute hsp_sel_hpos_dates @asg_new_assign_id,
                                         @asg_new_beg_date,     '>',
                                         @w_jp_beg_date output,
                                         @w_jp_eff_date output,
                                         @w_jp_end_date output
              if @w_jp_beg_date = @w_end_of_time
                  begin
                     /*---------------------------------------------*/
                     /* POSITION does not exist                     */
                     /*---------------------------------------------*/
                     select @w_error_number = 26132
                     goto exit_chg_rea_date
                  end
              else
                  begin
                     /*---------------------------------------------*/
                     /* POSITION exists in the future               */
                     /*---------------------------------------------*/
                     select @w_error_number = 26133
                     goto exit_chg_rea_date
                  end
           end

           /*----------------------------------------------------------------*/
           /* Pick up the defaults from the position version just located.   */
           /*----------------------------------------------------------------*/
           select @w_pos_frozen_ind    = frozen_ind,
                  @w_pos_policy        = pos_policy_id,
                  @w_pos_plcy_aprvl_cd = apprvl_status_code,
                  @w_pos_plcy_budgt_cd = bud_status_code,
                  @w_pos_plcy_fund_cd  = funding_status_code
               from position
               where pos_id   = @asg_new_assign_id
                 and eff_date = @w_jp_eff_date

           /*------------------------------------------------------*/
           /* Is the POSITION frozen                               */
           /*------------------------------------------------------*/
           if @w_pos_frozen_ind = 'Y'
           begin
              rollback transaction /* r70m - sol#572150*/
--SYBSQL               raiserror 34536 @w_em_34536
         select @w_em_34536 = '34536 ' + @w_em_34536
          raiserror (@w_em_34536,16,0)
              return
           end

           /*------------------------------------------------------*/
           /* Validate the assignment begin/end dates against the  */
           /* position's begin/end dates                           */
           /*------------------------------------------------------*/
           if @w_jp_end_date != @w_end_of_time
           begin
              /*---------------------------------------------------*/
              /* Make sure the client begin date is within the     */
              /* boundries of this position's end date.            */
              /*---------------------------------------------------*/
              if @asg_new_beg_date > @w_jp_end_date
              begin
                 select @w_error_number = 26138
                 goto exit_chg_rea_date
              end
              /*---------------------------------------------------*/
              /* if client provided end date, make sure the        */
              /* clients end date is within this position's end    */
              /* date.                                             */
              /*---------------------------------------------------*/
              if @asg_new_end_date != @w_end_of_time  and
                 @asg_new_end_date  > @w_jp_end_date
              begin
                 select @w_error_number = 26139
                 goto exit_chg_rea_date
              end
           end

           /*------------------------------------------------------*/
           /* Default the assignment end date if not provided by   */
           /* the client                                           */
           /*------------------------------------------------------*/
           if @asg_new_end_date = @w_end_of_time
           begin
              select @asg_new_end_date = @w_jp_end_date
           end

           /*------------------------------------------------------*/
           /* Pick up the defaults from the policy for this        */
           /* position if they exist.                              */
           /*------------------------------------------------------*/
           if @w_pos_policy != ' '
           begin
              /*---------------------------------------------*/
              /* Validate the existance of this policy       */
              /*---------------------------------------------*/
              if not exists ( select * from pos_policy
                                 where pos_policy_id = @w_pos_policy)
              begin
                 rollback transaction /* r70m - sol#572150*/
--SYBSQL                  raiserror 34506 @w_em_34506
         select @w_em_34506 = '34506 ' + @w_em_34506
          raiserror (@w_em_34506,16,0)
                 return
              end

              /*---------------------------------------------*/
              /* Pick up data for policy validation          */
              /*---------------------------------------------*/
              select @w_pop_plcy_filerr_cd = fill_err_level_code,
                     @w_pop_plcy_aprvl_cd  = apprvl_level_code,
                     @w_pop_plcy_budgt_cd  = bud_level_code,
                     @w_pop_plcy_fund_cd   = funding_level_code
                  from  pos_policy
                  where pos_policy_id = @w_pos_policy

              /*---------------------------------------------*/
              /* Begin policy validation                     */
              /*---------------------------------------------*/
              if @w_pop_plcy_filerr_cd = 'N'
                  begin
                     /*--------------------------------------*/
                     /* No validation is to take place       */
                     /*--------------------------------------*/
                     select @w_continue = 'Y'
                  end
              else
                  begin
                     if @w_pos_plcy_aprvl_cd >= @w_pop_plcy_aprvl_cd  and
                        @w_pos_plcy_budgt_cd >= @w_pop_plcy_budgt_cd  and
                        @w_pos_plcy_fund_cd  >= @w_pop_plcy_fund_cd
                         begin
                            /*------------------------------------*/
                            /* Position filling status meets the  */
                            /* policy filling requirements        */
                            /*------------------------------------*/
                            select @w_continue = 'Y'
                         end
                     else
                         begin
                            if @w_pop_plcy_filerr_cd = 'W'   and
                               @asf_fs_error_level   = 'R'
                            begin
                               /*------------------------------------*/
                               /* WARNING : The positions filling    */
                               /*    status does not meet the policy */
                               /*    filling requirements            */
                               /*------------------------------------*/
                               rollback transaction /* r70m - sol#572150*/
--SYBSQL                                raiserror 34507 @w_em_34507
         select @w_em_34507 = '34507 ' + @w_em_34507
          raiserror (@w_em_34507,16,0)
                               return
                            end
                            if @w_pop_plcy_filerr_cd = 'E'
                            begin
                               /*------------------------------------*/
                               /* ERROR : The positions filling      */
                               /*    status does not meet the policy */
                               /*    filling requirements            */
                               /*------------------------------------*/
                               rollback transaction /* r70m - sol#572150*/
--SYBSQL                                raiserror 34514 @w_em_34514
         select @w_em_34514 = '34514 ' + @w_em_34514
          raiserror (@w_em_34514,16,0)
                               return
                            end
                         end
                  end
           end
        end

    /* ------------------------------------------------------- */
    /* Validate Assignment against Position occupancy rules    */
    /* ------------------------------------------------------- */
    if @asg_new_assign_to = 'P'
    begin
       /*----------------------------------------------------- */
       /*    Locate the position closest to the begin date     */
       /*----------------------------------------------------- */
       execute hsp_sel_hpos_dates @asg_new_assign_id,
                                  @asg_new_beg_date,     '<=',
                                  @w_pos_beg_date output,
                                  @w_pos_eff_date output,
                                  @w_pos_end_date output

       if @w_pos_eff_date = @w_end_of_time
       begin
          /*-------------------------------------------------------*/
          /* Determin if future version exists to decide on which  */
          /* error message to send to the client                   */
          /*-------------------------------------------------------*/
          execute hsp_sel_hpos_dates @asg_new_assign_id,
                                     @asg_new_beg_date,     '>',
                                     @w_pos_beg_date output,
                                     @w_pos_eff_date output,
                                     @w_pos_end_date output
          if @w_pos_eff_date = @w_end_of_time
              begin
                 /*------------------------------------------------*/
                 /* Position Identifier not valid                  */
                 /*------------------------------------------------*/
                 select @w_error_number = 26132
                 goto exit_chg_rea_date
              end
          else
              begin
                 /*--------------------------------------------------*/
                 /*  Assignment begins before position starts        */
                 /*--------------------------------------------------*/
                 select @w_pos_beg_date  = begin_date,
                        @w_pos_end_date  = end_date,
                        @w_error_number  = 26133
                    from position
                    where pos_id   = @asg_new_assign_id
                      and eff_date = @w_pos_eff_date
                 goto exit_chg_rea_date
              end
       end

       /*---------------------------------------------------------------*/
       /* Pick up the defaults from the position version just located.  */
       /*---------------------------------------------------------------*/
       select @w_pos_nxt_date          = next_eff_date,
              @w_pos1_nxt_date         = next_eff_date,
              @w_pos_beg_date          = begin_date,
              @w_pos_policy            = pos_policy_id,
              @w_pos_frozen_ind        = frozen_ind,
              @w_pos_allowed_fte       = allowed_fte_nbr,
              @w_pos_allowed_incumbent = allowed_incumbents_nbr
          from position
          where pos_id   = @asg_new_assign_id
            and eff_date = @w_pos_eff_date

       /*-----------------------------------------------------*/
       /* Determin if Position is frozen                      */
       /*-----------------------------------------------------*/
       if @w_pos_frozen_ind = 'Y'
       begin
          /*--------------------------------------------------*/
          /*  Assignments to this position not allowed        */
          /*--------------------------------------------------*/
          select @w_error_number = 26082
          goto exit_chg_rea_date
       end

       /*-----------------------------------------------------*/
       /* Validate the existance of this policy               */
       /*-----------------------------------------------------*/
       if @w_pos_policy != ' '
           begin
              if not exists ( select * from pos_policy where pos_policy_id = @w_pos_policy )
              begin
                 rollback transaction /* r70m - sol#572150*/
--SYBSQL                  raiserror 34506 @w_em_34506
         select @w_em_34506 = '34506 ' + @w_em_34506
          raiserror (@w_em_34506,16,0)
                 return
              end
           end
       else
           begin
              goto pos_validate_exit
           end

       /*---------------------------------------------------------*/
       /* Pick up the defaults from the policy for this position. */
       /*---------------------------------------------------------*/
       select @w_pop_incumbent_errcd_cd = incumb_val_err_level_code,
              @w_pop_fte_errcd_cd       = fte_val_err_level_code
          from  pos_policy
          where pos_policy_id = @w_pos_policy

       /*---------------------------------------------------------*/
       /*    Policy occupancy validation                          */
       /*---------------------------------------------------------*/
       if @w_pop_incumbent_errcd_cd = 'N'   and
          @w_pop_fte_errcd_cd       = 'N'
       begin
          /*------------------------------------------------------*/
          /* No occupancy validation is to take place             */
          /*------------------------------------------------------*/
          select @w_error_number = 0
          goto pos_validate_exit
       end

       /*----------------------------------------------------------------*/
       /* Pickup position occupancy as of the new begin date   and       */
       /* Determin filled incumbents assigned to this position with no   */
       /* time period assigned                                           */
       /*----------------------------------------------------------------*/
       select @w_fill_incumb_01 = count(asgmt1.assigned_to_code)
          from emp_assignment asgmt1
          where asgmt1.job_or_pos_id    = @asg_new_assign_id
            and asgmt1.assigned_to_code = 'P'
            and asgmt1.eff_date         = ( select max(eff_date)
                         from emp_assignment asgmt2
                         where asgmt2.job_or_pos_id    = asgmt1.job_or_pos_id
                           and asgmt2.assigned_to_code = asgmt1.assigned_to_code
                           and asgmt2.emp_id           = asgmt1.emp_id
                           and asgmt2.eff_date        <= @asg_new_beg_date )
            and asgmt1.end_date            >= @asg_new_beg_date
            and asgmt1.standard_work_pd_id  = ' '

       /*----------------------------------------------------------------*/
       /*   Determin filled incumbents assigned to this position with    */
       /*   time period assigned                                         */
       /*----------------------------------------------------------------*/
       select @w_fill_incumb_02 = count(asgmt1.assigned_to_code),
              @w_filled_fte_hrs = sum(round((asgmt1.standard_work_hrs/policy.tm_pd_hrs),2))
          from emp_assignment asgmt1,
               tm_pd_policy policy
          where asgmt1.job_or_pos_id    = @asg_new_assign_id
            and asgmt1.assigned_to_code = 'P'
            and asgmt1.eff_date         = ( select max(eff_date)
                         from emp_assignment asgmt2
                         where asgmt2.job_or_pos_id    = asgmt1.job_or_pos_id
                           and asgmt2.assigned_to_code = asgmt1.assigned_to_code
                           and asgmt2.emp_id           = asgmt1.emp_id
                           and asgmt2.eff_date        <= @asg_new_beg_date )
            and asgmt1.end_date            >= @asg_new_beg_date
            and asgmt1.standard_work_pd_id  = policy.tm_pd_id

       /*----------------------------------------------------------------*/
       /*   Set incumbents/fte for return to the client                  */
       /*----------------------------------------------------------------*/
       if @w_fill_incumb_02 = 0
       begin
          select @w_filled_fte_hrs = 0
       end
       select @w_filled_incumbents = ( @w_fill_incumb_01 + @w_fill_incumb_02 )

       /*----------------------------------------------------------------*/
       /*   Determin if future assignments exits                         */
       /*----------------------------------------------------------------*/
       if exists (select * from emp_assignment
                     where job_or_pos_id    = @asg_new_assign_id
                       and assigned_to_code = 'P'
                       and begin_date > @asg_new_beg_date )
           select @w_future_assignment_ind = 'Y'
       else
           select @w_future_assignment_ind = 'N'

       if @w_pop_incumbent_errcd_cd  != 'N'  and
          @asg_incumbent_error_level  = 'R'
       begin
          /*----------------------------------------------------*/
          /* Incumbent occupancy validation is to take place    */
          /*----------------------------------------------------*/
          select @w_total_incumbents = @w_filled_incumbents + 1
          if @w_total_incumbents > @w_pos_allowed_incumbent
          begin
             if @w_pop_incumbent_errcd_cd = 'W'
             begin
                /*----------------------------------------------*/
                /* Warning: Position Incumbent's exceeded do you*/
                /*  want continue                               */
                /*----------------------------------------------*/
                select @w_error_number = 26007
                goto exit_chg_rea_date
             end
             if @w_pop_incumbent_errcd_cd = 'E'
             begin
                /*----------------------------------------------*/
                /* Error: Position Incumbents's exceeded you may*/
                /*  not continue                                */
                /*----------------------------------------------*/
                select @w_error_number = 26008
                goto exit_chg_rea_date
             end
          end
       end

       if @w_pop_fte_errcd_cd  != 'N'  and
          @asg_fte_error_level  = 'R'
       begin
          /*------------------------------------------------------------*/
          /* FTE occupancy validation is to take place                  */
          /*------------------------------------------------------------*/
          select @w_total_fte_hrs = @w_filled_fte_hrs + @asg_new_fte
          if @w_total_fte_hrs > @w_pos_allowed_fte
          begin
             if @w_pop_fte_errcd_cd = 'W'
             begin
                /*----------------------------------------------*/
                /* Warning: Position FTE's exceeded do you want */
                /* continue                                     */
                /*----------------------------------------------*/
                select @w_error_number = 26005
                goto exit_chg_rea_date
             end
             if @w_pop_fte_errcd_cd = 'E'
             begin
                /*----------------------------------------------*/
                /* Error: Position FTE's exceeded you may not   */
                /* continue                                     */
                /*----------------------------------------------*/
                select @w_error_number = 26006
                goto exit_chg_rea_date
             end
          end
       end
/* ------------------------------------------------------------------------ */
/* SECTION 2 :           Completion                                         */
/* ======================================================================== */
pos_validate_exit:
    end

/* ===================================================================== */
/* SECTION 3 : Update Current Assignment Create New Assignment           */
/*   --  End the current assignment one day short of the new             */
/*       assignment.                                                     */
/*   --  Point current assignment J/P next chain to new assignment.      */
/*   --  Format the new assignment.                                      */
/*       -- default new assignment from current assignment.              */
/*       -- default job information to new assignment.                   */
/*       -- default position information to new assignment.              */
/*   --  Create the new assignment.                                      */
/*   --  Send Reply Set back to the Client                               */
/* --------------------------------------------------------------------- */

    /* ----------------------------------------------------------------- */
    /* Calculate a new end date for the current Employee Assignment. the */
    /* new end date will be 1 day less than the Begin Date of the new    */
    /* Employee Assignment                                               */
    /* ----------------------------------------------------------------- */
    select @w_asgn_cur_enddt = dateadd( day,
                                       (datediff(day,'01/01/1900',@asg_new_beg_date) -1),
                                        '01/01/1900' )

    /* -------------------------------------------------------------------- */
    /* End the current Employee Assignment and point the Next Job/Position  */
    /* chain to the new Employee Assignment.   The new Assignment will be   */
    /* added later in this procedure                                        */
    /* -------------------------------------------------------------------- */
    execute sp_dbs_calc_chgstamp @emp_chgstamp, @w_new_chgstamp output
    update emp_assignment
       set next_assigned_to_code  = @asg_new_assign_to,
           next_job_or_pos_id     = @asg_new_assign_id,
           end_date               = @w_asgn_cur_enddt,
           chgstamp               = @w_new_chgstamp
       where emp_id           = @employee_identifier
         and assigned_to_code = @emp_asgmt_assigned_to_code
         and job_or_pos_id    = @emp_asgmt_job_or_pos_id
         and eff_date         = @cur_eff_date
         and chgstamp         = @emp_chgstamp
    if @@rowcount = 0
    begin
       rollback transaction
       if exists (select * from emp_assignment
                     where emp_id = @employee_identifier
                       and assigned_to_code = @emp_asgmt_assigned_to_code
                       and job_or_pos_id    = @emp_asgmt_job_or_pos_id
                       and eff_date         = @cur_eff_date)
                   begin
--SYBSQL            raiserror 20001 @w_em_20001
         select @w_em_20001 = '20001 ' + @w_em_20001
          raiserror (@w_em_20001,16,0)
                   end
       else
                   begin
--SYBSQL            raiserror 20002 @w_em_20002
         select @w_em_20002 = '20002 ' + @w_em_20002
          raiserror (@w_em_20002,16,0)
                   end
       return
    end

    /* -------------------------------------------------------------------- */
    /* Update the Next Job/Position chain in each version of the current    */
    /* Employee Assignment                                                  */
    /* -------------------------------------------------------------------- */
    update emp_assignment
       set next_assigned_to_code = @asg_new_assign_to,
           next_job_or_pos_id    = @asg_new_assign_id,
           chgstamp              = chgstamp + 1
       where emp_id           = @employee_identifier
         and assigned_to_code = @emp_asgmt_assigned_to_code
         and job_or_pos_id    = @emp_asgmt_job_or_pos_id
         and begin_date       = @w_jp1_beg_date

    /* ---------------------------------------------------------------- */
    /* Format the new assignment in memory                              */
    /* we have the current assignment in storage, all we need to do is  */
    /* update it with client data, and job/position data then write it  */
    /* out.                                                             */
    /* ---------------------------------------------------------------- */
    select
            /*----------------------------------------------------------*/
            /*  set values from client into the assignment              */
            /*----------------------------------------------------------*/
            @emp_asgmt_work_tm_code        = @asg_new_work_time_ind,
            @emp_asgmt_salary_change_date  = @asg_new_salary_chg_date,
            @emp_asgmt_pd_salary           = @asg_new_pd_salry,
            @emp_asgmt_hourly_pay_rate     = @asg_new_hourly_rate,
            @emp_asgmt_annual_salary       = @asg_new_annual_salry,
            @emp_asgmt_standard_work_hrs   = @asg_new_std_hours,
            @emp_asgmt_standard_work_pd_id = @asg_new_std_work_period,
            @emp_asgmt_reason_code         = @asg_new_assign_reason,
            @emp_asgmt_prior_asgd_to_code  = @emp_asgmt_assigned_to_code,
            @emp_asgmt_prior_job_or_pos_id = @emp_asgmt_job_or_pos_id,
            @emp_asgmt_salary_curr_cd      = @app_offer_curr_code,
            @emp_asgmt_pd_salary_tm_pd     = @app_offer_pd_salary_time_cd,
            @emp_asgmt_org_chart_id        = @app_offer_org_chart_id,
            @emp_asgmt_org_unit_id         = @app_offer_org_unit_id,
            @emp_pay_on_rptd_hrs_ind       = @app_offer_pay_hours_rpt_ind,
            @emp_asgmt_work_shift_code     = @app_offer_work_shift_code,
            @emp_asgmt_pay_grade           = @app_offer_pay_grade,
            @emp_asgmt_job_eval_points     = @app_offer_points,
            @emp_asgmt_salary_step         = @app_offer_salary_step,
            @emp_asgmt_mgr_emp_id          = @app_offer_mgr_emp_id,
            @emp_prime_assignment_ind      = @w_primary_ind,
            @emp_guar_pd_salary_amt        = @w_new_guar_pd_salry,
            @emp_guar_hourly_pay_rate      = @w_new_guar_hourly_rate,
            @emp_guar_annual_salary_amt    = @w_new_guar_annual_salry,
            @emp_ref_pd_salary_amt         = @w_new_ref_pd_salry,
            @emp_ref_hourly_pay_rate       = @w_new_ref_hourly_rate,
            @emp_ref_annual_salary_amt     = @w_new_ref_salry,
            @emp_shift_diff_rate_tbl_id    = @app_new_shift_rate_id,
            /*----------------------------------------------------------*/
            /*  initialize assignment fields                            */
            /*----------------------------------------------------------*/
            @emp_asgmt_salary_change_type  = ' ',
            @emp_asgmt_org_change_reason   = ' '

    /*----------------------------------------------------------------------*/
    /* Update new assignment based upon job or position                     */
    /* Note: Only update from job or position if from Employee Assignment   */
    /* window. If from Application use data from offer.                     */
    /*----------------------------------------------------------------------*/
    if @asg_new_assign_to = 'J' and @from_window = 'HASG'
    begin
       /*----------------------------------------------------------*/
       /* Pick up the defaults from the new job.  Window validated */
       /* existance of the new Job                                 */
       /*----------------------------------------------------------*/
       select @emp_asgmt_salary_structure_id = salary_structure_id,
              @emp_asgmt_increase_guidel_id  = salary_increase_guideline_id,
              @w_job_pay_grade               = pay_grade_code,
              @w_job_points                  = evaluation_points_nbr,
              @w_job_salary_step             = entry_salary_step_nbr,
              @emp_base_rate_tbl_id          = base_rate_tbl_id,
              @emp_base_rate_tbl_entry_code  = base_rate_tbl_entry_code,
              @emp_overtime_status_code      = overtime_status_code,
              @emp_shift_diff_status_code    = shift_differential_status_code,
              @emp_standard_daily_work_hrs   = standard_daily_work_hrs,
              @emp_asgmt_work_shift_code     = ''
           from  job
           where job_id   = @asg_new_assign_id
            and  eff_date = @w_jp_eff_date

       /*---------------------------------------------------------*/
       if (    ltrim(@emp_base_rate_tbl_id)  IS NOT NULL
           and ltrim(@emp_base_rate_tbl_id)  !=''        )
           and @emp_base_rate_tbl_entry_code = ''
       begin
          select @emp_base_rate_tbl_id = ''
       end

       /*---------------------------------------------------------*/
       if @emp_shift_diff_rate_tbl_id <> ''
       begin
          select @emp_asgmt_work_shift_code = @app_offer_work_shift_code
       end

       /*---------------------------------------------------------*/
       if @w_job_pay_grade != @emp_asgmt_pay_grade
       begin
          select @emp_asgmt_pay_grade        = @w_job_pay_grade,
                 @emp_asgmt_pay_grade_date   = @asg_new_beg_date,
                 @emp_asgmt_salary_step      = @w_job_salary_step,
                 @emp_asgmt_salary_step_date = @asg_new_beg_date
          if @w_job_salary_step = 0 select @emp_asgmt_salary_step_date = @w_end_of_time
       end

       /*---------------------------------------------------------*/
       if @w_job_points != @emp_asgmt_job_eval_points
       begin
          select @emp_asgmt_job_eval_points  = @w_job_points,
                 @emp_asgmt_pay_grade_date   = @asg_new_beg_date,
                 @emp_asgmt_salary_step      = @w_job_salary_step,
                 @emp_asgmt_salary_step_date = @asg_new_beg_date
          if @w_job_salary_step = 0 select @emp_asgmt_salary_step_date = @w_end_of_time
       end
    end

    if @asg_new_assign_to = 'P' and @from_window = 'HASG'
    begin
       /*----------------------------------------------------------*/
       /* Pick up the defaults from the new Position.  Window      */
       /* validated existance of the new Position                  */
       /*----------------------------------------------------------*/
       select
              @emp_asgmt_salary_structure_id = salary_structure_id,
              @emp_asgmt_increase_guidel_id  = salary_increase_guideline_id,
              @emp_asgmt_org_chart_id        = organization_chart_name,
              @emp_asgmt_org_unit_id         = organization_unit_name,
              @w_shift_work_rate_cd          = work_shift_code,
              @w_pos_pay_grade               = pay_grade_code,
              @w_pos_points                  = evaluation_points_nbr,
              @w_pos_salary_step             = entry_salary_step_nbr,
              @emp_base_rate_tbl_id          = base_rate_tbl_id,
              @emp_base_rate_tbl_entry_code  = base_rate_tbl_entry_code,
              @emp_overtime_status_code      = overtime_status_code,
              @emp_shift_diff_status_code    = shift_differential_status_code,
              @emp_standard_daily_work_hrs   = standard_daily_work_hrs,
              @emp_regulatory_rtg_unit_code  = regulatory_reporting_unit_code, /* ssa#20590 */
              @emp_organization_group_id     = organization_group_id
          from  position
          where pos_id   = @asg_new_assign_id
           and  eff_date = @w_jp_eff_date

       /*---------------------------------------------------------*/
       if (    ltrim(@emp_base_rate_tbl_id)  IS NOT NULL
           and ltrim(@emp_base_rate_tbl_id)  !=''        )
           and @emp_base_rate_tbl_entry_code = ''
       begin
          select @emp_base_rate_tbl_id = ''
       end

       /*---------------------------------------------------------*/
       if @emp_shift_diff_rate_tbl_id = ''
       begin
          select @emp_asgmt_work_shift_code = @w_shift_work_rate_cd
       end

       /*---------------------------------------------------------*/
       if @w_pos_pay_grade != @emp_asgmt_pay_grade
       begin
          select @emp_asgmt_pay_grade        = @w_pos_pay_grade,
                 @emp_asgmt_pay_grade_date   = @asg_new_beg_date,
                 @emp_asgmt_salary_step      = @w_pos_salary_step,
                 @emp_asgmt_salary_step_date = @asg_new_beg_date
          if @w_job_salary_step = 0 select @emp_asgmt_salary_step_date = @w_end_of_time
       end

       /*---------------------------------------------------------*/
       if @w_pos_points != @emp_asgmt_job_eval_points
       begin
          select @emp_asgmt_job_eval_points  = @w_pos_points,
                 @emp_asgmt_pay_grade_date   = @asg_new_beg_date,
                 @emp_asgmt_salary_step      = @w_pos_salary_step,
                 @emp_asgmt_salary_step_date = @asg_new_beg_date
          if @w_job_salary_step = 0 select @emp_asgmt_salary_step_date = @w_end_of_time
       end

       /*---------------------------------------------------------*/
       /*  Update position succession planning information        */
       /*---------------------------------------------------------*/
       if exists (select * from pos_successor_candidate
                     where emp_id = @employee_identifier
                      and  pos_id = @asg_new_assign_id )
       begin
           Update pos_successor_candidate
             set candidate_status_code = '05',
                 chgstamp              = chgstamp + 1
             where emp_id = @employee_identifier
               and pos_id = @asg_new_assign_id
       end
    end

    if @asg_new_assign_to = 'P'
    begin
       /* ------------------------------------------------- */
       /* Pickup Position Location Code for this assignment */
       /* ------------------------------------------------- */
       select @emp_asgmt_loc_code = loc_code
          from  position
          where pos_id   = @asg_new_assign_id
            and eff_date = @w_jp_eff_date
    end

    /* ---------------------------------------------------- */
    /* Point the previous assignment to this new assignment */
    /* ---------------------------------------------------- */
    if @w_jp1_eff_date != @w_end_of_time
    begin
       update emp_assignment
          set next_eff_date = @asg_new_beg_date,
              chgstamp      = chgstamp + 1
          where emp_id = @employee_identifier
            and assigned_to_code = @asg_new_assign_to
            and job_or_pos_id    = @asg_new_assign_id
            and eff_date         = @w_jp1_eff_date
       if @@rowcount = 0
       begin
          rollback transaction
--SYBSQL           raiserror 28506 @w_em_28506
         select @w_em_28506 = '28506 ' + @w_em_28506
          raiserror (@w_em_28506,16,0)
          return
       end
    end

    /* ----------------------------------------------------------------- */
    /* Insert new Employee Assignment                                    */
    /* ----------------------------------------------------------------- */
    insert into emp_assignment (
          emp_id,                         assigned_to_code,
          job_or_pos_id,                  eff_date,
          next_eff_date,                  prior_eff_date,
          next_assigned_to_code,          next_job_or_pos_id,
          prior_assigned_to_code,         prior_job_or_pos_id,
          begin_date,                     end_date,
          assignment_reason_code,         organization_chart_name,
          organization_unit_name,         organization_group_id,
          organization_change_reason_cd,  loc_code,
          mgr_emp_id,                     official_title_code,
          official_title_date,            salary_change_date ,
          annual_salary_amt,              pd_salary_amt,
          pd_salary_tm_pd_id,             hourly_pay_rate,
          curr_code,                      pay_on_reported_hrs_ind,
          salary_change_type_code,        standard_work_pd_id,
          standard_work_hrs,              work_tm_code,
          work_shift_code,                salary_structure_id,
          salary_increase_guideline_id,   pay_grade_code,
          pay_grade_date,                 job_evaluation_points_nbr,
          salary_step_nbr,                salary_step_date,
          phone_1_type_code,              phone_1_fmt_code,
          phone_1_fmt_delimiter,          phone_1_intl_code,
          phone_1_country_code,           phone_1_area_city_code,
          phone_1_nbr,                    phone_1_extension_nbr,
          phone_2_type_code,              phone_2_fmt_code ,
          phone_2_fmt_delimiter,          phone_2_intl_code ,
          phone_2_country_code,           phone_2_area_city_code,
          phone_2_nbr,                    phone_2_extension_nbr,
          prime_assignment_ind,           pay_basis_code ,
          occupancy_code,                 regulatory_reporting_unit_code,
          base_rate_tbl_id,               base_rate_tbl_entry_code,
          shift_differential_rate_tbl_id, ref_annual_salary_amt ,
          ref_pd_salary_amt,              ref_pd_salary_tm_pd_id ,
          ref_hourly_pay_rate,            guaranteed_annual_salary_amt ,
          guaranteed_pd_salary_amt,       guaranteed_pd_salary_tm_pd_id,
          guaranteed_hourly_pay_rate,     exception_rate_ind,
          overtime_status_code,           shift_differential_status_code ,
          standard_daily_work_hrs,        user_amt_1 ,
          user_amt_2,                     user_code_1 ,
          user_code_2,                    user_date_1 ,
          user_date_2,                    user_ind_1 ,
          user_ind_2,                     user_monetary_amt_1,
          user_monetary_amt_2,            user_monetary_curr_code,
          user_text_1,                    user_text_2,
          unemployment_loc_code,          include_salary_in_autopay_ind,
          chgstamp )
      values (
          @employee_identifier,           @asg_new_assign_to,
          @asg_new_assign_id,             @asg_new_beg_date,
          @w_end_of_time,                 @w_jp1_eff_date,
          @emp_asgmt_next_asgd_to_code,   @emp_asgmt_next_job_or_pos_id,
          @emp_asgmt_prior_asgd_to_code,  @emp_asgmt_prior_job_or_pos_id,
          @asg_new_beg_date,              @asg_new_end_date,
          @emp_asgmt_reason_code,         @emp_asgmt_org_chart_id,
          @emp_asgmt_org_unit_id,         @emp_organization_group_id,
          @emp_asgmt_org_change_reason,   @emp_asgmt_loc_code,
          @emp_asgmt_mgr_emp_id,          @emp_asgmt_official_title_code,
          @emp_asgmt_official_title_date, @emp_asgmt_salary_change_date ,
          @emp_asgmt_annual_salary,       @emp_asgmt_pd_salary,
          @emp_asgmt_pd_salary_tm_pd,     @emp_asgmt_hourly_pay_rate,
          @emp_asgmt_salary_curr_cd,      @emp_pay_on_rptd_hrs_ind,
          @emp_asgmt_salary_change_type,  @emp_asgmt_standard_work_pd_id,
          @emp_asgmt_standard_work_hrs,   @emp_asgmt_work_tm_code,
          @emp_asgmt_work_shift_code,     @emp_asgmt_salary_structure_id,
          @emp_asgmt_increase_guidel_id,  @emp_asgmt_pay_grade,
          @emp_asgmt_pay_grade_date,      @emp_asgmt_job_eval_points,
          @emp_asgmt_salary_step,         @emp_asgmt_salary_step_date,
          @emp_asgmt_phn1_type_code,      @emp_asgmt_phn1_fmt_code,
          @emp_asgmt_phn1_fmt_delimeter,  @emp_asgmt_phn1_intl_code,
          @emp_asgmt_phn1_country_code ,  @emp_asgmt_phn1_area_city_code,
          @emp_asgmt_phn1_nbr,            @emp_asgmt_phn1_ext_nbr,
          @emp_asgmt_phn2_type_code,      @emp_asgmt_phn2_fmt_code ,
          @emp_asgmt_phn2_fmt_delimeter,  @emp_asgmt_phn2_intl_code ,
          @emp_asgmt_phn2_country_code,   @emp_asgmt_phn2_area_city_code,
          @emp_asgmt_phn2_nbr,            @emp_asgmt_phn2_ext_nbr,
          @emp_prime_assignment_ind,      @emp_pay_basis_code ,
          @emp_occupancy_code,            @emp_regulatory_rtg_unit_code,
          @emp_base_rate_tbl_id,          @emp_base_rate_tbl_entry_code,
          @emp_shift_diff_rate_tbl_id,    @emp_ref_annual_salary_amt ,
          @emp_ref_pd_salary_amt,         @emp_ref_pd_salary_tm_pd_id ,
          @emp_ref_hourly_pay_rate,       @emp_guar_annual_salary_amt ,
          @emp_guar_pd_salary_amt,        @emp_guar_pd_salary_tm_pd_id,
          @emp_guar_hourly_pay_rate,      @emp_exception_rate_ind,
          @emp_overtime_status_code,      @emp_shift_diff_status_code ,
          @emp_standard_daily_work_hrs,   @emp_asgmt_user_amt_1,
          @emp_asgmt_user_amt_2,          @emp_asgmt_user_code_1,
          @emp_asgmt_user_code_2,         @emp_asgmt_user_date_1,
          @emp_asgmt_user_date_2,         @emp_asgmt_user_ind_1,
          @emp_asgmt_user_ind_2,          @emp_user_monetary_amt_1,
          @emp_user_monetary_amt_2,       @emp_user_monetary_curr_code,
          @emp_user_text_1,               @emp_user_text_2,
          @emp_unemployment_loc_code,     @emp_asgmt_salary_ind,
          0 )
    if @@error <> 0
    begin
       /* --------------------------------------------------------- */
       /* Error occured Inserting New Assignment                    */
       /* --------------------------------------------------------- */
       rollback transaction
--SYBSQL        raiserror 28506 @w_em_28506
         select @w_em_28506 = '28506 ' + @w_em_28506
          raiserror (@w_em_28506,16,0)
       return
    end

exit_chg_rea_date:

/**********************************************************************
574397 - Begin
         move code below to end of transaction
***********************************************************************/
--    select  @w_error_number,
--            @w_jp_beg_date,
--            @w_jp_eff_date,
--            @w_jp_end_date,
--            @asg_new_assign_id,
--            @asg_new_beg_date,
--            @asg_new_end_date
/**********************************************************************
574397 - end
***********************************************************************/
/* -------------------------------------------------------------------- */
/* SECTION 3 :           Completion                                     */
/* ==================================================================== */

/* ==================================================================== */
/* SECTION 4 : Generate Audit Trail                                     */
/*   --  Set up User and Datetime for use in audit table                */
/*   --  Update the employee assignment audit table                     */
/*   --  Exit Re-assign Process                                         */
/* -------------------------------------------------------------------- */
    declare @W_ACTION_USER   char(30),
            @W_MS            char(3)

	select @W_ACTION_USER = suser_sname(),
	       @cur_end_date  = dateadd(day, -1, @asg_new_beg_date),
           @W_MS          = convert (char(3), datepart(millisecond,getdate()))

    if datalength(rtrim(@W_MS)) = 1
       begin
          select @W_MS = '00'+substring(@W_MS,1,1)
       end
   else
       begin
          if datalength(rtrim(@W_MS)) = 2
          begin
             select @W_MS = '0'+substring(@W_MS,1,2)
          end
       end

   select @W_ACTION_DATETIME = convert(char(10), getdate(), 111) + '-' +
                               convert(char(8),  getdate(), 108) + ':' + @W_MS

    IF @from_window <> 'HAPL'
    begin
       /*---------------------------------------------------------*/
       /* Reassign originated from the Employee Assignment window */
       /*---------------------------------------------------------*/
        insert into work_emp_assignment_aud
            (user_id, activity_action_code, action_date, emp_id, assigned_to_code, 				job_or_pos_id, eff_date, next_eff_date, prior_eff_date, new_eff_date, 				new_begin_date, new_end_date, new_assigned_to_code, new_job_or_pos_id, 			new_assigned_to_begin_date)
        values
            (@W_ACTION_USER,    'REASSIGN',           @W_ACTION_DATETIME,
             @asg_cur_id,        @asg_cur_assign_to,
             @asg_cur_assign_id, @asg_cur_eff_date,   '', '', '','',
             @cur_end_date,      @asg_new_assign_to,  @asg_new_assign_id, @asg_new_beg_date )

        Delete work_emp_assignment_aud
            Where user_id              = @W_ACTION_USER
             and  activity_action_code = 'REASSIGN'
             and  emp_id               = @asg_cur_id
             and  assigned_to_code     = @asg_cur_assign_to
             and  job_or_pos_id        = @asg_cur_assign_id
             and  eff_date             = @asg_cur_eff_date
    end

    IF @from_window = 'HAPL'
    begin
       /*----------------------------------------------------*/
       /* Reassign originated from the Application window    */
       /*----------------------------------------------------*/
        insert into work_emp_assignment_aud
            (user_id, activity_action_code, action_date, emp_id, assigned_to_code, 				job_or_pos_id, eff_date, next_eff_date, prior_eff_date, new_eff_date, 				new_begin_date, new_end_date, new_assigned_to_code, new_job_or_pos_id, 			new_assigned_to_begin_date)
        values
            (@W_ACTION_USER,     'HIREAPPLRE',        @W_ACTION_DATETIME,
             @asg_cur_id,        @asg_cur_assign_to,
             @asg_cur_assign_id, @asg_cur_eff_date,   '', '', '','',
             @cur_end_date,      @asg_new_assign_to,  @asg_new_assign_id,  @asg_new_beg_date)

        Delete work_emp_assignment_aud
            Where user_id              = @W_ACTION_USER
             and  activity_action_code = 'HIREAPPLRE'
             and  emp_id               = @asg_cur_id
             and  assigned_to_code     = @asg_cur_assign_to
             and  job_or_pos_id        = @asg_cur_assign_id
             and  eff_date             = @asg_cur_eff_date
    end
/* -------------------------------------------------------------------- */
/* SECTION 4 :           Completion                                     */
/* ==================================================================== */
/**********************************************************************
574397 - Begin
         moved code below from above audit processing to here
***********************************************************************/
    select  @w_error_number,
            @w_jp_beg_date,
            @w_jp_eff_date,
            @w_jp_end_date,
            @asg_new_assign_id,
            @asg_new_beg_date,
            @asg_new_end_date
/**********************************************************************
574397 - end
***********************************************************************/

commit transaction

GO

ALTER AUTHORIZATION ON dbo.usp_hsp_upd_hasg_reassign TO  SCHEMA OWNER
GO

IF OBJECT_ID(N'dbo.usp_hsp_upd_hasg_reassign', N'P') IS NOT NULL
    PRINT N'<<< CREATED PROCEDURE dbo.usp_hsp_upd_hasg_reassign >>>'
ELSE
    PRINT N'<<< FAILED CREATING PROCEDURE dbo.usp_hsp_upd_hasg_reassign >>>'
GO
