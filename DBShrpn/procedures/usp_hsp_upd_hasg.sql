USE DBShrpn
go
IF OBJECT_ID(N'dbo.usp_hsp_upd_hasg') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_hsp_upd_hasg
    IF OBJECT_ID(N'dbo.usp_hsp_upd_hasg') IS NOT NULL
        PRINT N'<<< FAILED DROPPING PROCEDURE dbo.usp_hsp_upd_hasg >>>'
    ELSE
        PRINT N'<<< DROPPED PROCEDURE dbo.usp_hsp_upd_hasg >>>'
END
go
SET ANSI_NULLS ON
go
/*************************************************************************************

   SP Name:      usp_hsp_upd_hasg

   Description:  Updates SmartStream table DBShrpn..emp_assignment.

                 Cloned from DBShrpn..hsp_upd_hasg in order to use with
                 HCM Interface position title update in procedure DBShrpn..usp_ins_position_title.

   Parameters:


   Tables

   Example:
      exec usp_hsp_upd_hasg ....

   Revision history:
      version  date        developer   SCR      description
      -------  ----------  ---------   -----    ------------------------------------
      1.0.00   10/27/2025  CJP                  - Cloned from SmmartStream version DBShrpn..usp_hsp_upd_hasg
                                                    1) Disabled authentication
                                                    2) Replaced all double quotes with single quote


************************************************************************************/



create procedure [dbo].[usp_hsp_upd_hasg]
          /*------------------------------------------------------------*/
          /*  hsp_ins_hjob : variables                                  */
          /*------------------------------------------------------------*/
          @use_eff_date                     datetime,
          @use_end_date                     datetime,
          /*------------------------------------------------------------*/
          /*    dw_singlerow = hpn0630_employee_assgn_header            */
          /*------------------------------------------------------------*/
          @employee_identifier char(15),
          @emp_asgmt_assigned_to_code       char(01),
          @emp_asgmt_job_or_pos_id          char(10),
          @emp_asgmt_eff_date               datetime,
          @emp_asgmt_next_eff_date          datetime,
          @emp_asgmt_prior_eff_dt           datetime,
          @emp_asgmt_begin_date             datetime,
          @emp_asgmt_end_date               datetime,
          @emp_display_name                 char(45),
          @emp_status_code                  char(01),
          @emp_status_change_date           datetime,
          @w_job_or_pos_title               char(10),
          @tm_pd_id                         char(05),
          @tm_pd_hrs                        float,

          /*------------------------------------------------------------*/
          /*    dw_2 = hpn0630_employee_assgn_basic                     */
          /*------------------------------------------------------------*/
          @emp_asgmt_reason_code            char(05),
          @emp_prime_assignment_ind         char(01),
          @emp_occupancy_code               char(01),
          @emp_asgmt_official_title_code    char(05),
          @emp_asgmt_official_title_date    datetime,
          @emp_autopay_ind                  char(1),
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
          @pd_salary_pd_annlzg_factor   float,
            @pd_salary_pd_hrs            float,
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
          @emp_asgmt_user_date_1            datetime,          @emp_asgmt_user_date_2            datetime,
          @emp_asgmt_user_ind_1             char(01),
          @emp_asgmt_user_ind_2             char(01),
          @emp_user_monetary_amt_1          money,
          @emp_user_monetary_amt_2          money,
          @emp_user_monetary_curr_code      char(03),
          @emp_user_text_1                  char(50),
          @emp_user_text_2                  char(50),
          /*------------------------------------------------------------*/
          /*    dw_7 = hpn0630_employee_assgn_org                        */
          /*------------------------------------------------------------*/
           @emp_asgmt_org_chart_id          char(64),
          @emp_asgmt_org_unit_id            char(240),
          @emp_asgmt_org_change_reason      char(05),
          @emp_asgmt_loc_code               char(10),
          @emp_asgmt_mgr_emp_id             char(15),
          @emp_organization_group_id         float,
          @emp_regulatory_rtg_unit_code    char(10),
          @emp_unemployment_loc_code       char(10),

          /*------------------------------------------------------------*/
          /*    dw_8 = hpn0630_employee_assgn_addl_salary               */
          /*------------------------------------------------------------*/
        @emp_shift_diff_rate_tbl_id char(10),
        @emp_asgmt_work_shift_code char(05),
        @emp_shift_diff_status_code char(02),
        @emp_ref_annual_salary_amt              money,
        @emp_ref_pd_salary_amt                  money,
        @emp_ref_pd_salary_tm_pd_id             char(5),
        @emp_ref_hourly_pay_rate                float,
        @emp_guar_annual_salary_amt     money,
        @emp_guar_pd_salary_amt         money,
        @emp_guar_pd_salary_tm_pd_id    char(5),
        @emp_guar_hourly_pay_rate               float,


          /*------------------------------------------------------------*/
          /*    dw_10 = these fields use to be on dw_6                  */
          /*------------------------------------------------------------*/
           @w_emp_ver_code                   char(01),
          @w_emp_ver_count                  smallint,
          @pos_allowed_fte                  float,
          @pos_allowed_incumbents           int,
          @pos_standard_work_hrs            float,
          @pos_policy_id                    char(08),
          @pol_incumb_val_err_lvl           char(01),
          @pol_fte_val_err_lvl_cd           char(01),
          @tm_pd_annlzg_factor              float,
          @emp_asgmt_next_asgd_to_code      char(01),
          @emp_asgmt_next_job_or_pos_id     char(10),
          @emp_asgmt_prior_asgd_to_code     char(01),
          @emp_asgmt_prior_job_or_pos_id    char(10),
          @w_asg_life_end_date datetime,
          @emp_chgstamp                     smallint

as

/* -------------------------------------------------------------------- */
/* Authenticate the use of this stored procedure                        */
/* -------------------------------------------------------------------- */
      declare @w_ret   int,
                @W_ACTION_DATETIME      char(30)
      --execute @w_ret = sp_dbs_authenticate
      --if @w_ret != 0
      --    return



begin transaction

/* SECTION : 1 ======================================================== */
/* -- If any edit ecounteres an error in this section, an error */
/*       message is sent the the client, and processing stops.          */
/* ==================================================================== */

/* -------------------------------------------------------------------- */
/* Initialize variables used by this procedure and calculate a new      */
/* change stamp                                                         */
/* -------------------------------------------------------------------- */
      declare @w_new_chgstamp       smallint,
              @another_new_chgstamp smallint,
              @retstatus            int,
              @new_eff_date         datetime,
              @cur_eff_date         datetime,
              @nxt_eff_date         datetime,
              @end_of_time          datetime,
              @w_em_20001           char(40),
              @w_em_20002           char(40),
              @w_em_26140           char(100),
              @w_ret_code           int

      select @end_of_time                   = '12/31/2999',
             @w_em_20001  = 'Row updated by another user.',
             @w_em_20002  = 'Row does not exist.',
             @w_em_26140  = '26140 : The assignment next effective date ' +
                            'pointer is corrupted in the database.'

      execute sp_dbs_calc_chgstamp @emp_chgstamp,
                                   @w_new_chgstamp output

/* -------------------------------------------------------------------- */
/*   Perform currency of an assignment.  Currency can only be changed   */
/* if the employee is not associated with a pay group as of the */
/*   effective date or ant point in the future.                         */
/* -------------------------------------------------------------------- */
if not exists(Select * from emp_assignment
              where emp_id = @employee_identifier and
                    assigned_to_code = @emp_asgmt_assigned_to_code and
                    job_or_pos_id    = @emp_asgmt_job_or_pos_id    and
                    curr_code        = @emp_asgmt_salary_curr_cd)
        Begin
            Execute hsp_val_hrpn_curr @employee_identifier,
                                      @emp_asgmt_eff_date,
                                      @w_ret_code
            if @w_ret_code = 100
            Begin
                rollback transaction
--SYBSQL                 raiserror 50458 'Cannot Change the Currency'
          raiserror ('50458 Cannot Change the Currency',16,0)
                return
            End
        End
/* -------------------------------------------------------------------- */
/* Perform salary range validation if a salary range table id is */
/*   present and any of the parms used by the validation process has    */
/*   changed.                                                           */
/* -------------------------------------------------------------------- */
      if (rtrim(@emp_asgmt_salary_structure_id) IS NOT NULL AND rtrim(@emp_asgmt_salary_structure_id)!='')
             if exists (select * from emp_assignment
                          where (emp_id = @employee_identifier and assigned_to_code = @emp_asgmt_assigned_to_code and
                                 job_or_pos_id    = @emp_asgmt_job_or_pos_id    and
                                 eff_date         = @emp_asgmt_eff_date         and                                (salary_structure_id != @emp_asgmt_salary_structure_id or
                                 pay_grade_code           != @emp_asgmt_pay_grade           or
                                 job_evaluation_points_nbr     != @emp_asgmt_job_eval_points     or
                                 salary_step_nbr         != @emp_asgmt_salary_step )))
                begin
                  execute hsp_val_hsrt_employee @emp_asgmt_salary_structure_id,
                                @emp_asgmt_pay_grade,
                                @emp_asgmt_job_eval_points,
                                @emp_asgmt_salary_step
                  if @@error != 0
                      begin
                         rollback transaction
                         return
                      end
                end


/* SECTION : 2 ======================================================== */
/*   --  Apply updates to EMP_ASSIGNMENT according to the following     */
/*       rules :                                                        */
/* A) if usr_eff_date = emp_asgmt_eff_date, and some */
/*              emp_assignment attributes have changed                  */
/*                  then update existing assignment                     */
/* B) if usr_eff_date not = emp_asgmt_eff_date */
/*                  then create a new assignment occurance connecting   */
/*                  the approiate next/prior links to the current       */
/*                  assignment occurance, based on the position of      */
/*                  the new assignment within the chain.                */
/*        NOTE : for rule B, the insertion will always occur after      */
/*               the current assignment.                                       */
/* ==================================================================== */

    select @new_eff_date = @use_eff_date,
             @cur_eff_date = @emp_asgmt_eff_date,
             @nxt_eff_date = @emp_asgmt_next_eff_date

      if @new_eff_date != @cur_eff_date
      /* -------------------------------------------------------------- */
      /* RULE B exists                                                  */
      /* -------------------------------------------------------------- */
         begin  /* RULE B - Added SSA#15851*/
           if @nxt_eff_date = @end_of_time
         /* ----------------------------------------------------------- */         /* insertion to occur at end of EMPLOYEE ASSIGNMENT chain      */
         /* ----------------------------------------------------------- */
            begin
               /* ----------------------------------------------------- */
               /* Insert new row to the EMPLOYEE ASSIGNMENT table       */
               /* ----------------------------------------------------- */
               execute @retstatus = hsp_ins_hasg_ebasic

          /*------------------------------------------------------------*/
          /*    dw_singlerow = hpn0630_employee_assgn_header            */
          /*------------------------------------------------------------*/
          @employee_identifier, @emp_asgmt_assigned_to_code,
          @emp_asgmt_job_or_pos_id,     @new_eff_date,
          @emp_asgmt_next_eff_date,     @cur_eff_date,
          @emp_asgmt_begin_date,        @emp_asgmt_end_date,
          /*------------------------------------------------------------*/
          /*    dw_2 = hpn0630_employee_assgn_basic                     */
          /*------------------------------------------------------------*/
          @emp_asgmt_reason_code,       @emp_prime_assignment_ind,
          @emp_occupancy_code,          @emp_asgmt_official_title_code,
          @emp_asgmt_official_title_date,@emp_autopay_ind,
          /*------------------------------------------------------------*/
          /*    dw_3 = hpn0630_employee_assgn_salary_hours              */
          /*------------------------------------------------------------*/
          @emp_asgmt_annual_salary,     @emp_asgmt_salary_curr_cd,
          @emp_asgmt_pd_salary,         @emp_pay_on_rptd_hrs_ind,
          @emp_asgmt_hourly_pay_rate,   @emp_asgmt_salary_change_type,
          @emp_asgmt_standard_work_hrs, @emp_asgmt_standard_work_pd_id,
          @emp_asgmt_work_tm_code,      @emp_pay_basis_code,
          @emp_asgmt_salary_change_date,   @emp_asgmt_pd_salary_tm_pd,
          @emp_base_rate_tbl_id,        @emp_base_rate_tbl_entry_code,
          @emp_exception_rate_ind,      @emp_overtime_status_code,
          @emp_standard_daily_work_hrs,
          /*------------------------------------------------------------*/
          /*    dw_4 = hpn0630_employee_assgn_compensation              */
          /*------------------------------------------------------------*/
          @emp_asgmt_salary_structure_id, @emp_asgmt_increase_guidel_id,
          @emp_asgmt_pay_grade,           @emp_asgmt_pay_grade_date,
          @emp_asgmt_job_eval_points,     @emp_asgmt_salary_step,
          @emp_asgmt_salary_step_date,
          /*------------------------------------------------------------*/
          /*    dw_5 = hpn0630_employee_assgn_telephones                */
          /*------------------------------------------------------------*/
          @emp_asgmt_phn1_type_code,      @emp_asgmt_phn1_fmt_code,
          @emp_asgmt_phn1_fmt_delimeter,  @emp_asgmt_phn2_type_code,
          @emp_asgmt_phn2_fmt_code,       @emp_asgmt_phn2_fmt_delimeter,
          @emp_asgmt_phn1_intl_code,      @emp_asgmt_phn1_country_code,
          @emp_asgmt_phn1_area_city_code, @emp_asgmt_phn1_nbr,
          @emp_asgmt_phn1_ext_nbr,        @emp_asgmt_phn2_intl_code,
          @emp_asgmt_phn2_country_code,   @emp_asgmt_phn2_area_city_code,
          @emp_asgmt_phn2_nbr,            @emp_asgmt_phn2_ext_nbr,
          /*------------------------------------------------------------*/
          /*    dw_6 = hpn0630_employee_assgn_user_flds                 */
          /*------------------------------------------------------------*/
          @emp_asgmt_user_amt_1,          @emp_asgmt_user_amt_2,
          @emp_asgmt_user_code_1,         @emp_asgmt_user_code_2,
          @emp_asgmt_user_date_1,         @emp_asgmt_user_date_2,
          @emp_asgmt_user_ind_1,          @emp_asgmt_user_ind_2,
          @emp_user_monetary_amt_1,       @emp_user_monetary_amt_2,
          @emp_user_monetary_curr_code,   @emp_user_text_1,
          @emp_user_text_2,
        /*------------------------------------------------------------*/
          /*    dw_7 = hpn0630_employee_assgn_org                        */
          /*------------------------------------------------------------*/
           @emp_asgmt_org_chart_id, @emp_asgmt_org_unit_id,
          @emp_asgmt_org_change_reason,  @emp_asgmt_loc_code,
          @emp_asgmt_mgr_emp_id, @emp_organization_group_id,
          @emp_regulatory_rtg_unit_code, @emp_unemployment_loc_code,

          /*------------------------------------------------------------*/
          /*    dw_8 = hpn0630_employee_assgn_addl_salary               */
          /*------------------------------------------------------------*/
        @emp_shift_diff_rate_tbl_id, @emp_asgmt_work_shift_code,
        @emp_shift_diff_status_code, @emp_ref_annual_salary_amt,
        @emp_ref_pd_salary_amt, @emp_ref_pd_salary_tm_pd_id,
        @emp_ref_hourly_pay_rate, @emp_guar_annual_salary_amt,
        @emp_guar_pd_salary_amt, @emp_guar_pd_salary_tm_pd_id,
        @emp_guar_hourly_pay_rate,

          /*------------------------------------------------------------*/
          /*    dw_10 = these fields use to be on dw_6                  */
          /*------------------------------------------------------------*/
        @emp_asgmt_next_asgd_to_code,   @emp_asgmt_next_job_or_pos_id,
          @emp_asgmt_prior_asgd_to_code,  @emp_asgmt_prior_job_or_pos_id

               if @retstatus != 0
                   begin
                      rollback transaction
--SYBSQL                           raiserror 26140 @w_em_26140
         select @w_em_26140 = '26140 ' + @w_em_26140
          raiserror (@w_em_26140,16,0)
                      return
                   end
               /* ----------------------------------------------------- */
               /* Chain current assignment to prior assignment          */
               /* ----------------------------------------------------- */               update  emp_assignment
                   set next_eff_date      = @new_eff_date,
                       next_assigned_to_code  = ' ',
                       next_job_or_pos_id = ' ',
                       end_date           = @end_of_time,
                       chgstamp                     = @w_new_chgstamp
                   where emp_id = @employee_identifier
                     and assigned_to_code = @emp_asgmt_assigned_to_code
                     and job_or_pos_id    = @emp_asgmt_job_or_pos_id
                     and eff_date         = @cur_eff_date
                     and chgstamp                   = @emp_chgstamp
               if @@rowcount = 0
                   begin
                      rollback transaction
                      if exists (select * from emp_assignment
                                    where emp_id = @employee_identifier
                                      and assigned_to_code = @emp_asgmt_assigned_to_code
                                      and job_or_pos_id    = @emp_asgmt_job_or_pos_id
                                      and eff_date         = @cur_eff_date)
                      begin
--SYBSQL                           raiserror 20001 @w_em_20001
         select @w_em_20001 = '20001 ' + @w_em_20001
          raiserror (@w_em_20001,16,0)
                      end
                      else
                      begin
--SYBSQL                           raiserror 20002 @w_em_20002
         select @w_em_20002 = '20002 ' + @w_em_20002
          raiserror (@w_em_20002,16,0)
                      end
                      return
                   end
            end
         else
        /* ------------------------------------------------------------ */
        /* insertion to occur within the position chain                 */
        /* ------------------------------------------------------------ */
            begin
               /* ----------------------------------------------------- */
               /* Insert new row to the EMPLOYEE ASSIGNMENT table       */
               /* ----------------------------------------------------- */
               execute @retstatus = hsp_ins_hasg_ebasic

          /*------------------------------------------------------------*/
          /*    dw_singlerow = hpn0630_employee_assgn_header            */
          /*------------------------------------------------------------*/
          @employee_identifier, @emp_asgmt_assigned_to_code,
          @emp_asgmt_job_or_pos_id,     @new_eff_date,
          @emp_asgmt_next_eff_date,     @cur_eff_date,
          @emp_asgmt_begin_date,        @emp_asgmt_end_date,
          /*------------------------------------------------------------*/
          /*    dw_2 = hpn0630_employee_assgn_basic                     */
          /*------------------------------------------------------------*/
          @emp_asgmt_reason_code,       @emp_prime_assignment_ind,
          @emp_occupancy_code,          @emp_asgmt_official_title_code,
          @emp_asgmt_official_title_date,@emp_autopay_ind,
          /*------------------------------------------------------------*/
          /*    dw_3 = hpn0630_employee_assgn_salary_hours              */
          /*------------------------------------------------------------*/
          @emp_asgmt_annual_salary,     @emp_asgmt_salary_curr_cd,
          @emp_asgmt_pd_salary,         @emp_pay_on_rptd_hrs_ind,
          @emp_asgmt_hourly_pay_rate,   @emp_asgmt_salary_change_type,
          @emp_asgmt_standard_work_hrs, @emp_asgmt_standard_work_pd_id,
          @emp_asgmt_work_tm_code,      @emp_pay_basis_code,
          @emp_asgmt_salary_change_date,   @emp_asgmt_pd_salary_tm_pd,
          @emp_base_rate_tbl_id,        @emp_base_rate_tbl_entry_code,
          @emp_exception_rate_ind,      @emp_overtime_status_code,
          @emp_standard_daily_work_hrs,
          /*------------------------------------------------------------*/
          /*    dw_4 = hpn0630_employee_assgn_compensation              */
          /*------------------------------------------------------------*/
          @emp_asgmt_salary_structure_id, @emp_asgmt_increase_guidel_id,
          @emp_asgmt_pay_grade,           @emp_asgmt_pay_grade_date,
          @emp_asgmt_job_eval_points,     @emp_asgmt_salary_step,
          @emp_asgmt_salary_step_date,
          /*------------------------------------------------------------*/
          /*    dw_5 = hpn0630_employee_assgn_telephones                */
          /*------------------------------------------------------------*/
          @emp_asgmt_phn1_type_code,      @emp_asgmt_phn1_fmt_code,
          @emp_asgmt_phn1_fmt_delimeter,  @emp_asgmt_phn2_type_code,
          @emp_asgmt_phn2_fmt_code,       @emp_asgmt_phn2_fmt_delimeter,
          @emp_asgmt_phn1_intl_code,      @emp_asgmt_phn1_country_code,          @emp_asgmt_phn1_area_city_code, @emp_asgmt_phn1_nbr,
          @emp_asgmt_phn1_ext_nbr,        @emp_asgmt_phn2_intl_code,          @emp_asgmt_phn2_country_code,   @emp_asgmt_phn2_area_city_code,
          @emp_asgmt_phn2_nbr,            @emp_asgmt_phn2_ext_nbr,
          /*------------------------------------------------------------*/
          /*    dw_6 = hpn0630_employee_assgn_user_flds                 */
          /*------------------------------------------------------------*/           @emp_asgmt_user_amt_1,          @emp_asgmt_user_amt_2,
          @emp_asgmt_user_code_1,         @emp_asgmt_user_code_2,
          @emp_asgmt_user_date_1,         @emp_asgmt_user_date_2,          @emp_asgmt_user_ind_1,          @emp_asgmt_user_ind_2,
          @emp_user_monetary_amt_1,       @emp_user_monetary_amt_2,
          @emp_user_monetary_curr_code,   @emp_user_text_1,
          @emp_user_text_2,
        /*------------------------------------------------------------*/
          /*    dw_7 = hpn0630_employee_assgn_org                        */
          /*------------------------------------------------------------*/
           @emp_asgmt_org_chart_id, @emp_asgmt_org_unit_id,
          @emp_asgmt_org_change_reason,  @emp_asgmt_loc_code,
          @emp_asgmt_mgr_emp_id, @emp_organization_group_id,
          @emp_regulatory_rtg_unit_code, @emp_unemployment_loc_code,

          /*------------------------------------------------------------*/
          /*    dw_8 = hpn0630_employee_assgn_addl_salary               */
          /*------------------------------------------------------------*/
        @emp_shift_diff_rate_tbl_id, @emp_asgmt_work_shift_code,
        @emp_shift_diff_status_code, @emp_ref_annual_salary_amt,
        @emp_ref_pd_salary_amt, @emp_ref_pd_salary_tm_pd_id,
        @emp_ref_hourly_pay_rate, @emp_guar_annual_salary_amt,
        @emp_guar_pd_salary_amt, @emp_guar_pd_salary_tm_pd_id,
        @emp_guar_hourly_pay_rate,
          /*------------------------------------------------------------*/
          /*    dw_10 = these fields use to be on dw_6                  */
          /*------------------------------------------------------------*/
          @emp_asgmt_next_asgd_to_code,   @emp_asgmt_next_job_or_pos_id,
          @emp_asgmt_prior_asgd_to_code,  @emp_asgmt_prior_job_or_pos_id

               if @retstatus != 0
                   begin
                      rollback transaction
--SYBSQL                       raiserror 26140 @w_em_26140
         select @w_em_26140 = '26140 ' + @w_em_26140
          raiserror (@w_em_26140,16,0)
                      return
                   end
               /* ----------------------------------------------------- */
               /* Chain current assignment to prior assignment          */
               /* ----------------------------------------------------- */
               update  emp_assignment
                   set next_eff_date      = @new_eff_date,
                       next_assigned_to_code  = ' ',
                       next_job_or_pos_id = ' ',
                       end_date           = @end_of_time,
                       chgstamp                     = @w_new_chgstamp
                   where emp_id = @employee_identifier
                     and assigned_to_code = @emp_asgmt_assigned_to_code
                     and job_or_pos_id    = @emp_asgmt_job_or_pos_id
                     and eff_date         = @cur_eff_date
                     and chgstamp                   = @emp_chgstamp
               if @@rowcount = 0
                   begin
                      rollback transaction
                      if exists (select * from emp_assignment
                                    where emp_id = @employee_identifier
                                      and assigned_to_code = @emp_asgmt_assigned_to_code
                                      and job_or_pos_id    = @emp_asgmt_job_or_pos_id
                                      and eff_date         = @cur_eff_date)
                       begin
--SYBSQL                           raiserror 20001 @w_em_20001
         select @w_em_20001 = '20001 ' + @w_em_20001
          raiserror (@w_em_20001,16,0)
                      end
                      else
                      begin
--SYBSQL                           raiserror 20002 @w_em_20002
         select @w_em_20002 = '20002 ' + @w_em_20002
          raiserror (@w_em_20002,16,0)
                      end
                      return
                   end
               /* ----------------------------------------------------- */
               /* Chain current assignment to next assignment           */
               /* ----------------------------------------------------- */
               select @another_new_chgstamp = chgstamp
                   from emp_assignment
                   where emp_id = @employee_identifier
                     and assigned_to_code = @emp_asgmt_assigned_to_code
                     and job_or_pos_id    = @emp_asgmt_job_or_pos_id
                     and eff_date         = @nxt_eff_date
               if @@rowcount = 0
                   begin
                      rollback transaction
--SYBSQL                       raiserror 26140 @w_em_26140
         select @w_em_26140 = '26140 ' + @w_em_26140
          raiserror (@w_em_26140,16,0)
                      return
                   end
               execute sp_dbs_calc_chgstamp @another_new_chgstamp,
                                            @w_new_chgstamp output
               update  emp_assignment
                   set prior_eff_date = @new_eff_date,
                       chgstamp               = @w_new_chgstamp
                   where emp_id = @employee_identifier
                     and assigned_to_code = @emp_asgmt_assigned_to_code
                     and job_or_pos_id    = @emp_asgmt_job_or_pos_id
                     and eff_date         = @nxt_eff_date
                     and chgstamp                   = @another_new_chgstamp
               if @@rowcount = 0
                   begin
                      rollback transaction
                      if exists (select * from emp_assignment
                                    where emp_id = @employee_identifier
                                      and assigned_to_code = @emp_asgmt_assigned_to_code
                                      and job_or_pos_id    = @emp_asgmt_job_or_pos_id
                                      and eff_date         = @nxt_eff_date)
                      begin
--SYBSQL                           raiserror 20001 @w_em_20001
         select @w_em_20001 = '20001 ' + @w_em_20001
          raiserror (@w_em_20001,16,0)
                      end
                      else
                      begin
--SYBSQL                           raiserror 20002 @w_em_20002
         select @w_em_20002 = '20002 ' + @w_em_20002
          raiserror (@w_em_20002,16,0)
                      end
                      return
                   end
        end /*SSA#15851 - added this */

/* AUDIT SECTION ==============================================*/
        /* Set up the work employee assignment audit table - FOR RULE B                    */
        /* ============================================================*/

        declare    @W_ACTION_USER      char(30)

        select @W_ACTION_USER = suser_sname()
declare @W_MS             char(3)
   select @W_MS = convert (char(3), datepart(millisecond,getdate()))
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
                           convert(char(8), getdate(), 108) + ':' + @W_MS

        insert into work_emp_assignment_aud
                (user_id, activity_action_code, action_date, emp_id, assigned_to_code,                          job_or_pos_id, eff_date, next_eff_date, prior_eff_date, new_eff_date,                           new_begin_date, new_end_date, new_assigned_to_code, new_job_or_pos_id,                  new_assigned_to_begin_date)
        values
                (@W_ACTION_USER, 'CHGASGNE', @W_ACTION_DATETIME,
                @employee_identifier, @emp_asgmt_assigned_to_code,
                @emp_asgmt_job_or_pos_id, @emp_asgmt_eff_date,
                                '', '', @new_eff_date, '', '', '', '', '')
    end /* end for 'RULE B exists'  added comment SSA#15851 */
 else
      /* -------------------------------------------------------------- */
      /* RULE A exists                                                  */
      /* -------------------------------------------------------------- */
         begin
/* AUDIT SECTION ==============================================*/
        /* Set up the work employee assignment audit table - FOR RULE A   (INSERT)  */
        /* ============================================================*/

        select @W_ACTION_USER = suser_sname()

   select @W_MS = convert (char(3), datepart(millisecond,getdate()))
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
                           convert(char(8), getdate(), 108) + ':' + @W_MS

        insert into work_emp_assignment_aud
                (user_id, activity_action_code, action_date, emp_id, assigned_to_code,                          job_or_pos_id, eff_date, next_eff_date, prior_eff_date, new_eff_date,                           new_begin_date, new_end_date, new_assigned_to_code, new_job_or_pos_id,                  new_assigned_to_begin_date)
        values
                (@W_ACTION_USER, 'CHGASGEQ', @W_ACTION_DATETIME,
                @employee_identifier, @emp_asgmt_assigned_to_code,
                @emp_asgmt_job_or_pos_id, @emp_asgmt_eff_date,
                                                '', '', '', '', '', '', '', '')



         /* ----------------------------------------------------------- */
         /* update the existing EMPLOYEE ASSIGNMENT                     */         /* ----------------------------------------------------------- */
            update  emp_assignment
                set next_assigned_to_code       = @emp_asgmt_next_asgd_to_code,
                    next_job_or_pos_id          = @emp_asgmt_next_job_or_pos_id,
                    prior_assigned_to_code      = @emp_asgmt_prior_asgd_to_code,
                    prior_job_or_pos_id         = @emp_asgmt_prior_job_or_pos_id,
                    begin_date                  = @emp_asgmt_begin_date,
                    end_date                    = @emp_asgmt_end_date,
                    assignment_reason_code      = @emp_asgmt_reason_code,
                    organization_chart_name     = @emp_asgmt_org_chart_id,
/*SSA#22892         organization_unit_name      = @emp_asgmt_org_unit_id,*/
                    organization_group_id       = @emp_organization_group_id,
                    organization_change_reason_cd   = @emp_asgmt_org_change_reason,
                    loc_code                    = @emp_asgmt_loc_code,
/*SSA#22892         mgr_emp_id                  = @emp_asgmt_mgr_emp_id,*/
                    official_title_code         = @emp_asgmt_official_title_code,
                    official_title_date         = @emp_asgmt_official_title_date,
                    salary_change_date          = @emp_asgmt_salary_change_date,
                    annual_salary_amt           = @emp_asgmt_annual_salary,
                    pd_salary_amt               = @emp_asgmt_pd_salary,
                    pd_salary_tm_pd_id          = @emp_asgmt_pd_salary_tm_pd,
                    hourly_pay_rate             = @emp_asgmt_hourly_pay_rate,
                    curr_code                   = @emp_asgmt_salary_curr_cd,
                    pay_on_reported_hrs_ind     = @emp_pay_on_rptd_hrs_ind,
                    salary_change_type_code     = @emp_asgmt_salary_change_type,
                    standard_work_hrs           = @emp_asgmt_standard_work_hrs,
                    standard_work_pd_id         = @emp_asgmt_standard_work_pd_id,
                    work_tm_code                = @emp_asgmt_work_tm_code,
                    work_shift_code = @emp_asgmt_work_shift_code,
                    salary_structure_id         = @emp_asgmt_salary_structure_id,
                    salary_increase_guideline_id  = @emp_asgmt_increase_guidel_id,
                    pay_grade_code              = @emp_asgmt_pay_grade,
                    pay_grade_date              = @emp_asgmt_pay_grade_date,
                    job_evaluation_points_nbr   = @emp_asgmt_job_eval_points,
                    salary_step_nbr             = @emp_asgmt_salary_step,
                    salary_step_date            = @emp_asgmt_salary_step_date,
                    phone_1_type_code           = @emp_asgmt_phn1_type_code,
                    phone_1_fmt_code            = @emp_asgmt_phn1_fmt_code,
                    phone_1_fmt_delimiter       = @emp_asgmt_phn1_fmt_delimeter,
                    phone_1_intl_code           = @emp_asgmt_phn1_intl_code,
                    phone_1_country_code        = @emp_asgmt_phn1_country_code,
                    phone_1_area_city_code      = @emp_asgmt_phn1_area_city_code,
                    phone_1_nbr                 = @emp_asgmt_phn1_nbr,
                    phone_1_extension_nbr       = @emp_asgmt_phn1_ext_nbr,
                    phone_2_type_code           = @emp_asgmt_phn2_type_code,
                    phone_2_fmt_code            = @emp_asgmt_phn2_fmt_code,
                    phone_2_fmt_delimiter       = @emp_asgmt_phn2_fmt_delimeter,
                    phone_2_intl_code           = @emp_asgmt_phn2_intl_code,
                    phone_2_country_code        = @emp_asgmt_phn2_country_code,
                    phone_2_area_city_code      = @emp_asgmt_phn2_area_city_code,
                    phone_2_nbr                 = @emp_asgmt_phn2_nbr,
                    phone_2_extension_nbr       = @emp_asgmt_phn2_ext_nbr,
                    prime_assignment_ind        = @emp_prime_assignment_ind,
                    pay_basis_code              = @emp_pay_basis_code,
                    occupancy_code              = @emp_occupancy_code,
                    regulatory_reporting_unit_code = @emp_regulatory_rtg_unit_code,
                    base_rate_tbl_id            = @emp_base_rate_tbl_id,
                    base_rate_tbl_entry_code    = @emp_base_rate_tbl_entry_code,
                    shift_differential_rate_tbl_id = @emp_shift_diff_rate_tbl_id ,
                    ref_annual_salary_amt       = @emp_ref_annual_salary_amt,
                    ref_pd_salary_amt           = @emp_ref_pd_salary_amt,
                    ref_pd_salary_tm_pd_id      = @emp_ref_pd_salary_tm_pd_id,
                    ref_hourly_pay_rate         = @emp_ref_hourly_pay_rate,
                    guaranteed_annual_salary_amt = @emp_guar_annual_salary_amt,
                    guaranteed_pd_salary_amt    = @emp_guar_pd_salary_amt,
                    guaranteed_pd_salary_tm_pd_id = @emp_guar_pd_salary_tm_pd_id,
                    guaranteed_hourly_pay_rate  = @emp_guar_hourly_pay_rate,
                    exception_rate_ind          = @emp_exception_rate_ind,
                    overtime_status_code        = @emp_overtime_status_code ,
                    shift_differential_status_code = @emp_shift_diff_status_code ,
                    standard_daily_work_hrs     = @emp_standard_daily_work_hrs,
                    user_amt_1          = @emp_asgmt_user_amt_1,                    user_amt_2          = @emp_asgmt_user_amt_2,
                    user_code_1         = @emp_asgmt_user_code_1,
                    user_code_2         = @emp_asgmt_user_code_2,
                    user_date_1         = @emp_asgmt_user_date_1,
                    user_date_2         = @emp_asgmt_user_date_2,
                    user_ind_1          = @emp_asgmt_user_ind_1,
                    user_ind_2          = @emp_asgmt_user_ind_2,
                    user_monetary_amt_1 = @emp_user_monetary_amt_1,
                    user_monetary_amt_2 = @emp_user_monetary_amt_2,
                    user_monetary_curr_code = @emp_user_monetary_curr_code,
                    user_text_1         = @emp_user_text_1,
                    user_text_2         = @emp_user_text_2,
                    unemployment_loc_code = @emp_unemployment_loc_code,
                    include_salary_in_autopay_ind = @emp_autopay_ind,
                    chgstamp            = @w_new_chgstamp
                where emp_id = @employee_identifier
                   and assigned_to_code = @emp_asgmt_assigned_to_code
                   and job_or_pos_id    = @emp_asgmt_job_or_pos_id
                   and eff_date         = @emp_asgmt_eff_date                   and chgstamp                   = @emp_chgstamp
                if @@rowcount = 0
                    begin
                       rollback transaction
                       if exists (select * from emp_assignment
                                     where emp_id = @employee_identifier
                                       and assigned_to_code = @emp_asgmt_assigned_to_code
                                       and job_or_pos_id    = @emp_asgmt_job_or_pos_id
                                       and eff_date         = @emp_asgmt_eff_date)
                       begin
--SYBSQL                            raiserror 20001 @w_em_20001
         select @w_em_20001 = '20001 ' + @w_em_20001
          raiserror (@w_em_20001,16,0)
                       end
                       else
                       begin
--SYBSQL                            raiserror 20002 @w_em_20002
         select @w_em_20002 = '20002 ' + @w_em_20002
          raiserror (@w_em_20002,16,0)
                       end
                       return
                    end

                /*SSA#28892 sybase data corruption bug workaround:moving the update of  */
                /*organization_unit_name and mgr_emp_id to a different update statement */
                /*seems to stop the corruption and update the row correctly.            */
                update  emp_assignment
                set organization_unit_name      = @emp_asgmt_org_unit_id
                where emp_id = @employee_identifier
                   and assigned_to_code = @emp_asgmt_assigned_to_code
                   and job_or_pos_id    = @emp_asgmt_job_or_pos_id
                   and eff_date         = @emp_asgmt_eff_date

                if @@rowcount = 0
                    begin
                       rollback transaction
                       if exists (select * from emp_assignment
                                     where emp_id = @employee_identifier
                                       and assigned_to_code = @emp_asgmt_assigned_to_code
                                       and job_or_pos_id    = @emp_asgmt_job_or_pos_id
                                       and eff_date         = @emp_asgmt_eff_date)
                       begin
--SYBSQL                            raiserror 20001 @w_em_20001
         select @w_em_20001 = '20001 ' + @w_em_20001
          raiserror (@w_em_20001,16,0)
                       end
                       else
                       begin
--SYBSQL                            raiserror 20002 @w_em_20002
         select @w_em_20002 = '20002 ' + @w_em_20002
          raiserror (@w_em_20002,16,0)
                       end
                       return
                    end

                update  emp_assignment
                set mgr_emp_id = @emp_asgmt_mgr_emp_id
                where emp_id = @employee_identifier
                   and assigned_to_code = @emp_asgmt_assigned_to_code
                   and job_or_pos_id    = @emp_asgmt_job_or_pos_id
                   and eff_date         = @emp_asgmt_eff_date

                if @@rowcount = 0
                    begin
                       rollback transaction
                       if exists (select * from emp_assignment
                                     where emp_id = @employee_identifier
                                       and assigned_to_code = @emp_asgmt_assigned_to_code
                                       and job_or_pos_id    = @emp_asgmt_job_or_pos_id
                                       and eff_date         = @emp_asgmt_eff_date)
                       begin
--SYBSQL                            raiserror 20001 @w_em_20001
         select @w_em_20001 = '20001 ' + @w_em_20001
          raiserror (@w_em_20001,16,0)
                       end
                       else
                       begin
--SYBSQL                            raiserror 20002 @w_em_20002
         select @w_em_20002 = '20002 ' + @w_em_20002
          raiserror (@w_em_20002,16,0)
                       end
                       return
                    end
                /*SSA#28892 end */
         end

/* R60M-SSA#28223 begin:code-insert */
/* AUDIT SECTION ==============================================*/
/* UPDATE work employee assignment audit table - FOR RULE A    */
/*  (This is needed in order to activate a trigger.)           */
/* ============================================================*/
Update work_emp_assignment_aud
        set new_eff_date = @new_eff_date
        where user_id = @W_ACTION_USER
        and activity_action_code = 'CHGASGEQ'
        and emp_id = @employee_identifier
        and eff_date = @emp_asgmt_eff_date

/*--------------------------------------------------------------------- */
/*  DELETE THE AUDIT ROW in the work employee assignment audit table.   */
/* -------------------------------------------------------------------- */
if @new_eff_date != @cur_eff_date
        Delete work_emp_assignment_aud
                where user_id = @W_ACTION_USER
                and activity_action_code = 'CHGASGNE'
                and emp_id = @employee_identifier
                and eff_date = @emp_asgmt_eff_date
else
        Delete work_emp_assignment_aud
                where user_id = @W_ACTION_USER
                and activity_action_code = 'CHGASGEQ'
                and emp_id = @employee_identifier
                and eff_date = @emp_asgmt_eff_date
/* R60M-SSA#28223 end:code-insert */

/* -------------------------------------------------------------------- */
/* return the change stamp to allow refresh of the clients window       */
/* -------------------------------------------------------------------- */
      select @w_new_chgstamp


      commit transaction

GO


ALTER AUTHORIZATION ON dbo.usp_hsp_upd_hasg TO  SCHEMA OWNER
GO

IF OBJECT_ID(N'dbo.usp_hsp_upd_hasg', N'P') IS NOT NULL
    PRINT N'<<< CREATED PROCEDURE dbo.usp_hsp_upd_hasg >>>'
ELSE
    PRINT N'<<< FAILED CREATING PROCEDURE dbo.usp_hsp_upd_hasg >>>'
GO