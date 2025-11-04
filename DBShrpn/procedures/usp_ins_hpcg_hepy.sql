USE DBShrpn
go
IF OBJECT_ID(N'dbo.usp_ins_hpcg_hepy') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_ins_hpcg_hepy
    IF OBJECT_ID(N'dbo.usp_ins_hpcg_hepy') IS NOT NULL
        PRINT N'<<< FAILED DROPPING PROCEDURE dbo.usp_ins_hpcg_hepy >>>'
    ELSE
        PRINT N'<<< DROPPED PROCEDURE dbo.usp_ins_hpcg_hepy >>>'
END
go
SET ANSI_NULLS ON
go
/*************************************************************************************

   SP Name:      usp_ins_hpcg_hepy

   Description:  Builds pay elements for an associate in the status update process
                 executed in procedure DBShrpn..usp_ins_status_change.

                 Cloned from SmartStream procedure DBShrpn..hsp_ins_hpcg_hepy
                 in order to use with HCM Interface.

   Parameters:


   Tables

   Example:
      exec usp_ins_hpcg_hepy ....

   Revision history:
      version  date        developer   SCR      description
      -------  ----------  ---------   -----    ------------------------------------
      1.0.00                                    - Cloned from SmmartStream version DBShrpn..hsp_ins_hpcg_hepy
                                                    1) Disabled authentication
                                                    2) Replaced all double quotes with single quote

************************************************************************************/


CREATE procedure [dbo].[usp_ins_hpcg_hepy]
	(@p_emp_id			char(15),
	 @p_empl_id 			char(10),
         @p_new_pay_group_id		char(10),
	 @p_new_pecg_id			char(10),
         @p_as_of_date			datetime)
as

declare
        @w_eot				datetime,
	@w_employer_taxing_ctry_code	char(2),
	@w_pensioner_indicator		char(1),
	@w_pay_element_id		char(10),
        @w_ded_type_code               	char(1),
        @w_calc_method_code            	char(2),
      	@w_schedule_code               	char(2),
        @w_std_calc_factor_1           	float,
        @w_std_calc_factor_2           	float,
	@w_start_date			datetime,
	@w_stop_date			datetime,
        @w_next_eff_date                datetime,
        @w_limit_amt            	float,
        @w_rt_tbl_id                   	char(10),
        @w_direct_deposit_ind          	char(1),
	@w_regular_earn_pay_element_id  char(10),
        @w_inact_by_pay_element_ind    	char(1),
	@w_prenote_code                	char(1),
	@w_error_return_code           	varchar(255),
        @w_epe_prior_eff_date           datetime,
        @w_epe_stop_date                datetime,
        @w_pe_count                     int,
        @w_limit_cycle_type_code        char(1)

/* ==================================================================== */
/* Authenticate the request for this process                            */
/* ==================================================================== */
declare @ret int
--execute @ret = sp_dbs_authenticate
--if @ret != 0
    --return

declare @w_error char(1)
select  @w_error = 'N'

/* ==================================================================== */
/* Begin Audit setup                                                    */
/* ==================================================================== */
declare @W_ACTION_USER      		char(30),
        @W_ACTION_DATETIME  		char(30),
        @W_MS             		char(3)

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
/* ==================================================================== */
/* End Audit setup                                                      */
/* ==================================================================== */

/* ==================================================================== */
/* Initialize variables                                                 */
/* ==================================================================== */
select @w_eot = '12/31/2999'
select @w_error_return_code = ''
select @w_pe_count = 0


select @w_employer_taxing_ctry_code = taxing_country_code
  from employer
 where empl_id = @p_empl_id

select @w_pensioner_indicator = 'N'
select @w_pensioner_indicator = pensioner_indicator
  FROM emp_employment
 WHERE emp_id        = @p_emp_id
   AND next_eff_date = @w_eot
   AND empl_id       = @p_empl_id

begin transaction

if @w_employer_taxing_ctry_code = 'US' and @w_pensioner_indicator = 'N'
  BEGIN
    declare est_pecg_pe_cursor cursor
      for Select a.pay_element_id,
                 b.deduction_type_code,
                 b.calc_meth_code,
                 b.pay_pd_sched_code,
                 b.standard_calc_factor_1,
                 b.standard_calc_factor_2,
                 b.start_date,
                 b.stop_date,
                 b.next_eff_date,
                 b.limit_amt,
                 b.rate_tbl_id,
                 b.limit_cycle_type_code
            From pay_element_ctrl_grp_entry a, pay_element b
           Where a.pay_element_ctrl_grp_id = @p_new_pecg_id
             and a.pay_element_id          = b.pay_element_id
             and a.establish_on_hire_ind   = 'Y'
             and b.eff_date               <= @p_as_of_date
             and b.next_eff_date           > @p_as_of_date
             and b.start_date             <= @p_as_of_date
             and b.stop_date               > @p_as_of_date
             and b.earn_type_code         <> '6' /* pension earnings */
  END
else
  BEGIN /* Declare cursor to select pay element info for CANADA */
    declare est_pecg_pe_cursor cursor
      for Select a.pay_element_id,
                 b.deduction_type_code,
                 b.calc_meth_code,
                 b.pay_pd_sched_code,
                 b.standard_calc_factor_1,
                 b.standard_calc_factor_2,
                 b.start_date,
                 b.stop_date,
                 b.next_eff_date,
                 b.limit_amt,
                 b.rate_tbl_id,
                 b.limit_cycle_type_code
            From pay_element_ctrl_grp_entry a, pay_element b
           Where a.pay_element_ctrl_grp_id = @p_new_pecg_id
             and a.pay_element_id          = b.pay_element_id
             and a.establish_on_hire_ind   = 'Y'
             and b.eff_date               <= @p_as_of_date
             and b.next_eff_date           > @p_as_of_date
             and b.start_date             <= @p_as_of_date
             and b.stop_date               > @p_as_of_date
  END

open est_pecg_pe_cursor

Fetch est_pecg_pe_cursor
 Into @w_pay_element_id,
      @w_ded_type_code,
      @w_calc_method_code,
      @w_schedule_code,
      @w_std_calc_factor_1,
      @w_std_calc_factor_2,
      @w_start_date,
      @w_stop_date,
      @w_next_eff_date,
      @w_limit_amt,
      @w_rt_tbl_id,
      @w_limit_cycle_type_code

select @w_direct_deposit_ind = 'N'

While @@fetch_status = 0
  Begin         /* A */
        /* If the Pay Group is entered, the autopay pay element will already be started before */
        /* reaching this stored procedure, so no need to check if the autopay pay element is   */
        /* in the Pay Element Control Group.  If the Pay Group isn't entered and the autopay   */
        /* pay element is also in the Pay Element Control Group marked establish on hire, then */
        /* the autopay pay element will be started by this stored procedure under the same     */
        /* conditions as any of the other pay elements in the Pay Element Control Group that   */
        /* are marked establish on hire.                                                       */

        /**************************************************************************
         Check if employee already has the PE.
        **************************************************************************/
        if exists(select *
                    from emp_pay_element
                   where emp_id          = @p_emp_id
                     and empl_id         = @p_empl_id
                     and pay_element_id  = @w_pay_element_id)
          begin /* C */
            /**********************************************************************
             If employee has the PE and eff date >= hire date, get next PE.
            ***********************************************************************/
            if exists (select *
                         from emp_pay_element
                        where emp_id         = @p_emp_id
                          and eff_date      >= @p_as_of_date
                          and next_eff_date  = @w_eot
                          and pay_element_id = @w_pay_element_id
                          and empl_id        = @p_empl_id)
              begin
                Goto next_pecg_pe_cursor
              end

            /**********************************************************************
             If employee has the PE and eff date < hire date,
             update next_eff_date on prior row, set prior_eff_date for new row.
             Only want to reestablish PEs which are stopped before @p_as_of_date.
             [R6.5.03M-ALS#563565: corrected comment-removed '(stop_date <> @w_eot)'
              and replaced with 'before @p_as_of_date']
            ***********************************************************************/
            if exists (select * from emp_pay_element
                       where emp_id         = @p_emp_id
                         and eff_date       < @p_as_of_date
                         and next_eff_date  = @w_eot
                         and pay_element_id = @w_pay_element_id
                         and empl_id        = @p_empl_id)
              begin /* D */
                select @w_epe_stop_date = stop_date,
                       @w_limit_amt     = limit_amt
                  from emp_pay_element
                 where emp_id         = @p_emp_id
                   and eff_date       < @p_as_of_date
                   and next_eff_date  = @w_eot
                   and pay_element_id = @w_pay_element_id
                   and empl_id        = @p_empl_id

                if @w_epe_stop_date < @p_as_of_date /* R6.5.03M-ALS#563565: chgd <> @w_eot to < @p_as_of_date */
                  begin
                    select @w_epe_prior_eff_date = eff_date
                      from emp_pay_element
                     where emp_id         = @p_emp_id
                       and eff_date       < @p_as_of_date
                       and next_eff_date  = @w_eot
                       and pay_element_id = @w_pay_element_id
                       and empl_id        = @p_empl_id

                    update emp_pay_element
                       set next_eff_date  = @p_as_of_date,
                           chgstamp       = chgstamp + 1
                     where emp_id         = @p_emp_id
                       and eff_date       < @p_as_of_date
                       and next_eff_date  = @w_eot
                       and pay_element_id = @w_pay_element_id
                       and empl_id        = @p_empl_id
                  end
                else /* PE is active - don't need to do anything */
                  goto next_pecg_pe_cursor
              end   /* D */
          END  /* C */
        else   /* employee does not already have the PE */
          BEGIN
            select @w_epe_prior_eff_date = @w_eot
            select @w_limit_amt          = 0
          END

        /*********************************************************/
        /* Get info for new emp_pay_element row.                 */
        /*********************************************************/
        if @w_start_date <= @p_as_of_date
          select @w_start_date = @p_as_of_date

        if @w_stop_date = @w_eot
          BEGIN
            select @w_inact_by_pay_element_ind = 'N'
            if @w_next_eff_date = @w_eot
              select @w_stop_date = stop_date
                from pay_element
               where pay_element_id = @w_pay_element_id
                 and next_eff_date  = @w_eot
          END
        else
          select @w_inact_by_pay_element_ind = 'Y'

        if @w_calc_method_code in ('01','02','04','06','13','14','17','18','19','21','22','25')
          BEGIN
            if @w_std_calc_factor_1 = 0
              select @w_schedule_code = '00'
            else
              select @w_schedule_code = ''
          END
        else if @w_calc_method_code in ('03','05','23','24')
          BEGIN
            if @w_std_calc_factor_1 = 0 or @w_std_calc_factor_2 = 0
              select @w_schedule_code = '00'
            else
              select @w_schedule_code = ''
          END
        else if @w_calc_method_code in ('07','08','09','10','11','12','15','16','20')
           select @w_schedule_code = '00'
        else
           select @w_schedule_code = ''

        /*********************************************************/
        /* Insert new emp_pay_element row.                       */
        /*********************************************************/
        insert into emp_pay_element
                  (emp_id,
                   empl_id,
                   pay_element_id,
                   eff_date,
                   start_date,
                   stop_date,
                   prior_eff_date,
                   next_eff_date,
                   inactivated_by_pay_element_ind,
                   change_reason_code,
                   pay_element_pay_pd_sched_code,
                   calc_meth_code,
                   standard_calc_factor_1,
                   standard_calc_factor_2,
                   special_calc_factor_1,
                   special_calc_factor_2,
                   special_calc_factor_3,
                   special_calc_factor_4,
                   rate_tbl_id,
                   rate_code,
                   payee_name,
                   payee_pmt_sched_code,
                   payee_bank_transit_nbr,
                   payee_bank_acct_nbr,
                   pmt_ref_nbr,
                   pmt_ref_name,
                   vendor_id,
                   limit_amt,
                   guaranteed_net_pay_amt,
                   start_after_pay_element_id,
                   indiv_addr_type_to_print_code,
                   bank_id,
                   direct_deposit_bank_acct_nbr,
                   bank_acct_type_code,
                   pay_pd_arrears_rec_fixed_amt,
                   pay_pd_arrears_rec_fixed_pct,
                   min_pay_pd_recovery_amt,
                   user_amt_1,
                   user_amt_2,
                   user_monetary_amt_1,
                   user_monetary_amt_2,
                   user_monetary_curr_code,
                   user_code_1,
                   user_code_2,
                   user_date_1,
                   user_date_2,
                   user_ind_1,
                   user_ind_2,
                   user_text_1,
                   user_text_2,
                   pension_tot_distn_ind,
                   pension_distn_code_1,
                   pension_distn_code_2,
                   pre_1990_rpp_ctrb_type_cd,
                   chgstamp,
                   first_roth_ctrb,                 /* r71m - 578919 in 2006 reg pack 576240 */
                   ira_sep_simple_ind,              /* r71m - 581591 in 582025 */
                   taxable_amt_not_determined_ind)  /* r71m - 581591 in 582025 */
        values
                  (@p_emp_id,
                   @p_empl_id,
                   @w_pay_element_id,
                   @p_as_of_date,
                   @w_start_date,
                   @w_stop_date,
                   @w_epe_prior_eff_date,
                   @w_eot,
                   @w_inact_by_pay_element_ind,
                   '',
                   @w_schedule_code,
                   '',
                   0,
                   0,
                   0,
                   0,
                   0,
                   0,
                   @w_rt_tbl_id,
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   '',
                   @w_limit_amt,
                   0,
                   '',
                   '',
                   '',
                   '',
                   '',
                   0,
                   0,
                   0,
                   0,
                   0,
                   0,
                   0,
                   '',
                   '',
                   '',
                   @w_eot,
                   @w_eot,
                   'N',
                   'N',
                   '',
                   '',
                   'N',
                   '',
                   '',
                   '0',
                   0,
                   @w_eot,      /* r71m - 578919 in 2006 reg pack 576240 */
                   'N',         /* r71m - 581591 in 582025 */
                   'N')         /* r71m - 581591 in 582025 */

        if @@error <> 0
          begin
            select @w_error = 'Y'
            goto end_proc
        end

        select @w_pe_count = @w_pe_count + 1

        /* AUDIT SECTION ==========================================*/
        /* Set up the work employee pay element audit table        */
        /* ========================================================*/
        insert into work_emp_pay_element_aud
                    (user_id, activity_action_code, action_date, emp_id, empl_id,
                     pay_element_id, eff_date, prior_eff_date, next_eff_date,
                     new_eff_date, new_start_date, new_stop_date)
        values
                    (@W_ACTION_USER, 'PECGEPE', @W_ACTION_DATETIME,
                     @p_emp_id, @p_empl_id, @w_pay_element_id,
                     @p_as_of_date, '', '', '', '', '')

        Delete work_emp_pay_element_aud
         Where user_id = @W_ACTION_USER
           and action_date = @W_ACTION_DATETIME
           and activity_action_code = 'PECGEPE'
           and emp_id               = @p_emp_id
           and empl_id              = @p_empl_id
           and pay_element_id       = @w_pay_element_id
           and eff_date             = @p_as_of_date

        /* END AUDIT SECTION ==========================================*/
        /* Set up the work employee pay element audit table            */
        /* ============================================================*/

        if @w_ded_type_code = '3'  /* direct deposit */
          select @w_prenote_code       = '4',
                 @w_direct_deposit_ind = 'Y'
        else
          select @w_prenote_code = ''

        /**********************************************************************
         If not already exists, insert emp_pay_element_non_dtd
        ***********************************************************************/
        if not exists (select * from emp_pay_element_non_dtd
                        where emp_id         = @p_emp_id
                          and pay_element_id = @w_pay_element_id
                          and empl_id        = @p_empl_id)
          begin
            insert into emp_pay_element_non_dtd
                  (emp_id,
                   empl_id,
                   pay_element_id,
                   arrears_bal_amt,
                   recover_over_nbr_of_pay_pds,
                   wh_status_code,
                   calc_last_pay_pd_ind,
                   prenotification_check_date,
                   prenotification_code,
                   chgstamp)
            values
                  (@p_emp_id,
                   @p_empl_id,
                   @w_pay_element_id,
                   0,
                   0,
                   '9',
                   'N',
                   @w_eot,
                   @w_prenote_code,
                   0)
          end

        /* Compute inserts a row if the type code = 1 (See Employee Status Reactivate action) */
        if @w_limit_cycle_type_code = '2'   /* for type 1 - row is inserted after compute */
          BEGIN
            insert into emp_pay_element_limit
                   (emp_id,
                    empl_id,
                    pay_element_id,
                    start_date,
                    towards_the_limit_amt,
                    chgstamp)
             values
                   (@p_emp_id,
                    @p_empl_id,
                    @w_pay_element_id,
                    @w_start_date,
                    0,
                    0)
          END

next_pecg_pe_cursor:
    Fetch est_pecg_pe_cursor
     Into @w_pay_element_id,
          @w_ded_type_code,
          @w_calc_method_code,
          @w_schedule_code,
          @w_std_calc_factor_1,
          @w_std_calc_factor_2,
          @w_start_date,
          @w_stop_date,
          @w_next_eff_date,
          @w_limit_amt,
          @w_rt_tbl_id,
          @w_limit_cycle_type_code
  End           /* A *//* end while loop */
  /**********************************************************************
   End   est_pecg_pe_cursor
  ***********************************************************************/

close est_pecg_pe_cursor
deallocate est_pecg_pe_cursor

/****************************************/
/* Informational Error Message Handling */
/****************************************/
/* Any direct deposit pay elements that were established are incomplete     */
/* because they are missing Bank and Bank Account information.  If a direct */
/* deposit pay element was established on hire, notify the user.            */
if @w_direct_deposit_ind  = 'Y'
  begin
    if @w_error_return_code = ''
        select @w_error_return_code = '50436' + '/' + @p_new_pecg_id /* warning */
    else
        select @w_error_return_code = @w_error_return_code + '/' + '50436' + '/' + @p_new_pecg_id /* warning */
  end

/* If there are future active pay elements that the user has indicated to   */
/* establish on hire, set the return to inform the user that these were not */
/* set up.                                                                  */
if exists (select a.pay_element_id
             from pay_element_ctrl_grp_entry a, pay_element b
            where a.pay_element_ctrl_grp_id = @p_new_pecg_id
              and a.pay_element_id          = b.pay_element_id
              and a.establish_on_hire_ind   = 'Y'
              and b.start_date              > @p_as_of_date)
  begin
    if @w_error_return_code = ''
	select @w_error_return_code = '50433' + '/' + @p_new_pecg_id /* warning */
    else
	select @w_error_return_code = @w_error_return_code + '/' + '50433' + '/' + @p_new_pecg_id /* warning */
  end

/* If there are stopped pay elements that the user has indicated to */
/* establish on hire, set the return to inform the user that these  */
/* were not set up.                                                 */
if exists (select a.pay_element_id
             from pay_element_ctrl_grp_entry a, pay_element b
            where a.pay_element_ctrl_grp_id = @p_new_pecg_id
              and a.pay_element_id          = b.pay_element_id
              and a.establish_on_hire_ind   = 'Y'
              and b.eff_date               <= @p_as_of_date
              and b.next_eff_date           > @p_as_of_date
              and b.stop_date               < @p_as_of_date)
  begin
    if @w_error_return_code = ''
	select @w_error_return_code = '520106' + '/' + @p_new_pecg_id /* warning */
    else
	select @w_error_return_code = @w_error_return_code + '/' + '520106' + '/' + @p_new_pecg_id /* warning */
  end

/* If the employee being hired is designated as a pensioner in the U.S., */
/* and there are non-pension earnings in the pay element control group,  */
/* raise an error such that the user is warned that non-pension earnings */
/* were not established for this employee.                               */
if @w_employer_taxing_ctry_code = 'US'
  begin
    if @w_pensioner_indicator = 'N'
      if exists (select @w_pay_element_id
                   from pay_element_ctrl_grp_entry a, pay_element b
                  where a.pay_element_ctrl_grp_id = @p_new_pecg_id
                    and a.pay_element_id          = b.pay_element_id
                    and a.establish_on_hire_ind   = 'Y'
                    and b.pay_element_type_code   = '1'
                    and b.earn_type_code          = '6')
        begin
          if @w_error_return_code = ''
	    select @w_error_return_code = '50435' + '/' + @p_new_pecg_id /* warning */
          else
            select @w_error_return_code = @w_error_return_code + '/' + '50435' + '/' + @p_new_pecg_id /* warning */
        end
  end

/* ==================================================================== */
/*   --  Return to the client                                           */
/* ==================================================================== */
end_proc:
--select @w_error_return_code,
--       @w_pe_count

if @w_error = 'Y'
  begin
--SYBSQL    raiserror 520100  'Auto Setup Failed'
          raiserror ('520100  Auto Setup Failed',16,0)
   rollback transaction
  end
else
   commit transaction

GO

ALTER AUTHORIZATION ON dbo.usp_ins_hpcg_hepy TO  SCHEMA OWNER
GO

IF OBJECT_ID(N'dbo.usp_ins_hpcg_hepy', N'P') IS NOT NULL
    PRINT N'<<< CREATED PROCEDURE dbo.usp_ins_hpcg_hepy >>>'
ELSE
    PRINT N'<<< FAILED CREATING PROCEDURE dbo.usp_ins_hpcg_hepy >>>'
GO
