USE DBShrpn
go
IF OBJECT_ID(N'dbo.usp_upd_hmpl_terminate') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_upd_hmpl_terminate
    IF OBJECT_ID(N'dbo.usp_upd_hmpl_terminate') IS NOT NULL
        PRINT N'<<< FAILED DROPPING PROCEDURE dbo.usp_upd_hmpl_terminate >>>'
    ELSE
        PRINT N'<<< DROPPED PROCEDURE dbo.usp_upd_hmpl_terminate >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER OFF
GO


/*************************************************************************************

   SP Name:      usp_upd_hmpl_terminate

   Description:  Executes SmartStream rehire process

                 Cloned from DBShrpn..hsp_upd_hmpl_terminate in order to use with
                 HCM Interface position title update procedure DBShrpn..usp_ins_position_title.

   Parameters:


   Tables

   Example:
      exec usp_upd_hmpl_terminate ....

   Revision history:
      version  date        developer   SCR      description
      -------  ----------  ---------   -----    ------------------------------------
      1.0.00                                    - Cloned from SmmartStream version DBShrpn..hsp_upd_hmpl_rehire
                                                    1) Disabled authentication

************************************************************************************/

CREATE procedure [dbo].[usp_upd_hmpl_terminate]

(     @p_emp_id                        char(15),
      @p_status_change_date            datetime,
      @p_termination_date              datetime,
      @p_new_classn_cd                 char(2),
      @p_date_of_death                 datetime,
      @p_new_reason_code               char(5),
      @p_new_pay_through_date          datetime,
      @p_new_rehire_conson             char(1),
      @p_pay_status_code               char(1),
      @p_last_day_paid                 datetime,
      @p_old_chgstamp                  smallint
)

as

declare @ret int,
   @W_ACTION_DATETIME char(30)

--exec @ret = sp_dbs_authenticate if @ret != 0  return

declare  @w_end_of_time          	datetime,
         @w_status_code          	char(1),
         @w_spaces               	char(1),
         @w_last_action_cd         	char(2),
         @w_new_chgstamp         	smallint,
         @c_emp_id               	char(15),
         @c_assigned_to_code      	char(1),
         @c_job_or_pos_id         	char(10),
         @c_eff_date            	datetime,
         @c_next_eff_date         	datetime,
         @c_prior_eff_date         	datetime,
         @c_end_date            	datetime,
         @c_ben_plan_id         	char(15),
         @c_end_ptcpn_termn_ind   	char(1),
         @c_end_ptcpn_as_of_code 	char(1),
         @c_participant_id         	char(15),
         @w_as_of_date            	datetime,
         @w_month_part            	int,
         @w_year_part            	int,
         @w_first_date            	char(2),
         @w_second_date         	char(4),
         @w_third_date            	char(10),
         @c_pay_element_id         	char(10),
         @c_pay_elem_del_id      	char(10),
         @c_pay_elem_two         	char(10),
         @c_empl_id         		char(15),
         @w_termination_date_plus_one	datetime,
         @w_pay_status_code      	char(1),
         @w_pay_through_date_plus_one   datetime,
/* R6.1M-ssa# 29829 Begin */
	 @w_source_code			char(1),
/* R6.1M-ssa# 29829 End */
         @w_next_eff_date               datetime,
         @w_emp_id			char(15),		/* SSA 30832 */
	 @w_assigned_to_code		char(1),		/* SSA 30832 */
         @w_job_or_pos_id		char(10),		/* SSA 30832 */
         @w_effect_date			datetime,		/* SSA 30832 */
         @w_next_effect_date		datetime,		/* SSA 30832 */
         @w_prior_effect_date       	datetime,		/* SSA 30832 */
/* R6.1M-ssa #30724 Begin */
	 @ret_val			int,
/* R6.1M-ssa #30724 End */
/* SSA 30724 Begin */
	@w_total_rows			int,
	@w_row 				int
/* SSA 30724 End */

execute sp_dbs_calc_chgstamp @p_old_chgstamp, @w_new_chgstamp output

select   @w_end_of_time     = "12/31/2999",
         @w_status_code     = "T",
         @w_last_action_cd  = "TM",
         @w_spaces          = " ",
/* R6.1M-ssa# 29829 Begin */
	 @w_source_code     = "9",
/* R6.1M-ssa# 29829 End */
         @w_pay_status_code = ""

/**********************************************************************
564993 - create indicator to tell of auditing is turned on for
         emp_assignment
***********************************************************************/
declare @w_audit_emp_assign_tbl char(1)
if not exists (select audit_ind
              from  hr_audit_ctrl
              where sybase_table_name = 'emp_assignment'
              and sybase_audit_tbl_name = 'emp_assignment_aud'
              and bypass_audit_ind = 'N'
              and audit_ind  = 'Y')
    select  @w_audit_emp_assign_tbl = "N"
else
    select  @w_audit_emp_assign_tbl = "Y"
/**********************************************************************
564993 - End
***********************************************************************/


select   @w_termination_date_plus_one   = dateadd(day,1,@p_termination_date)
select   @w_pay_through_date_plus_one   = dateadd(day,1,@p_new_pay_through_date)

/****************************************************************/
/* This logic ends the employee's employment information as of  */
/* their pay through date.  The pay through date acts as the    */
/* 'end' date of the employee's employment information.         */
/****************************************************************/

INSERT INTO #temp1	/* SSA 30724 */
select emp_pay_element.pay_element_id
      from emp_pay_element, pay_element
      where emp_pay_element.emp_id = @p_emp_id
        and emp_pay_element.eff_date > @p_new_pay_through_date
        and emp_pay_element.pay_element_id = pay_element.pay_element_id
        and pay_element.eff_date <= @p_new_pay_through_date     /* 564993 */
        and pay_element.next_eff_date > @p_new_pay_through_date /* 564993 */
       and (pay_element.ben_plan_id = " " or pay_element.ben_plan_id = "")
       and pay_element.pay_element_type_code = '1'

/* begin transaction  ssa 30724 */

if @p_last_day_paid <> "" and @p_last_day_paid <> @w_end_of_time
    Begin
        Update employee set last_date_for_which_paid = @p_last_day_paid
        where emp_id = @p_emp_id
    End

/* AUDIT SECTION ==============================================*/
/* Set up the work employee employment audit table             */
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

/* ******************************************************************* */
/* Modified for Release 5.0                                            */

insert into work_emp_employment_aud
        (user_id, activity_action_code, action_date, emp_id, eff_date,
         next_eff_date, prior_eff_date, new_eff_date, new_empl_id,
         new_tax_entity_id, xfer_date, pay_through_date)
    values
        (@W_ACTION_USER, 'TERM', @W_ACTION_DATETIME,
        @p_emp_id, @p_new_pay_through_date,'','','','','','','')

/* END AUDIT SECTION ==========================================*/
/* Set up the work employee employment audit table             */
/* ============================================================*/

/* *********************************************************** */
/* Modified for Release 5.0                                    */
update emp_employment
   set pay_through_date  =    @p_new_pay_through_date,
       chgstamp          =    chgstamp + 1
 where emp_id = @p_emp_id
   and eff_date <= @p_termination_date /* 1665080/20160121 @p_new_pay_through_date */
   and next_eff_date > @p_termination_date /* 1665080/20160121 @p_new_pay_through_date */

if @@error != 0
      begin
--SYBSQL           raiserror 20002 "Row does not exist."
          raiserror ('20002 Row does not exist.',16,0)
          /*  rollback transaction ssa 30724 */
            return
      end

/* *********************************************************** */
/* Begin Additions for Release 5.0                             */
/* If the pay status is entered on the terminate employee      */
/* response window and is different from the pay status as of  */
/* the pay through date, a new version is inserted effective 1 */
/* day after the pay through date.  If that version already    */
/* existed, the row is updated.                                */
/* *********************************************************** */

if @p_pay_status_code <> ""
begin
    select  @w_pay_status_code = pay_status_code
        from    emp_employment
        where   emp_id = @p_emp_id
          and   eff_date <= @p_termination_date /* 1665080/20160121 @p_new_pay_through_date */
          and   next_eff_date > @p_termination_date /* 1665080/20160121 @p_new_pay_through_date */

    if @p_pay_status_code <> @w_pay_status_code
    /* ************************************************************ */
    /* Update or insert employment version with the new pay status  */
    /* ************************************************************ */
    begin
        if exists (select * from emp_employment
                            where emp_id = @p_emp_id
                              and eff_date = @w_pay_through_date_plus_one)
        begin

            /* AUDIT SECTION======================================*/
            /* UPDATE work employee employment audit table -      */
            /* ===================================================*/

	        /* R6.5.01M-ALS#286282: begin-add */
	        update work_emp_employment_aud
                         set eff_date = @w_pay_through_date_plus_one
                       where emp_id = @p_emp_id
                         and user_id = @W_ACTION_USER
                         and eff_date = @w_pay_through_date_plus_one
                         and activity_action_code = 'TERM'
            /* R6.5.01M-ALS#286282: end-add */

            /* END AUDIT SECTION==================================*/
            /* UPDATE work employee employment audit table -      */
            /* ===================================================*/

            update  emp_employment
                set     pay_through_date = @p_new_pay_through_date,
                                pay_status_code  = @p_pay_status_code
                        where   emp_id = @p_emp_id
                          and   eff_date = @w_pay_through_date_plus_one

            if @@rowcount = 0
            begin
                if exists (select * from emp_employment
                                     where emp_id = @p_emp_id
                                       and eff_date = @w_pay_through_date_plus_one)
--SYBSQL            raiserror 20001 "Row updated by another user."
              raiserror ('20001 Row updated by another user.',16,0)
                else
--SYBSQL            raiserror 20002 "Row does not exist."
              raiserror ('20002 Row does not exist.',16,0)
                /* rollback transaction ssa 30724 */
                return
            end /* if @@rowcount = 0 */

        end /* if exists (select * from emp_employment where emp_id = @p_emp_id and eff_date = @w_pay_through_date_plus_one) */
        else /* need new row */
        begin
            insert into emp_employment
                     select    emp_id,
                               @w_pay_through_date_plus_one,
                               next_eff_date,
                               eff_date,
                               employment_type_code,
                               work_tm_code,
                               official_title_code,
                               official_title_date,
                               mgr_ind,
                               recruiter_ind,
                               pensioner_indicator,
                               payroll_company_code,
                               pmt_ctrl_code,
                               us_federal_tax_meth_code,
                               us_federal_tax_amt,
                               us_federal_tax_pct,
                               us_federal_marital_status_code,
                               us_federal_exemp_nbr,
                               us_work_st_code,
                               canadian_work_province_code,
                               ipp_payroll_id,
                               ipp_max_pay_level_amt,
                               @p_new_pay_through_date,
                               empl_id,
                               tax_entity_id,
                               @p_pay_status_code,
                               clock_nbr,
                               provided_i_9_ind,
                               time_reporting_meth_code,
                               regular_hrs_tracked_code,
                               pay_element_ctrl_grp_id,
                               pay_group_id,
                               us_pension_ind,
                               professional_cat_code,
                               corporate_officer_ind,
                               prim_disbursal_loc_code,
                               alternate_disbursal_loc_code,
                               labor_grp_code,
                               employment_info_chg_reason_cd,
                               highly_compensated_emp_ind,
                               nbr_of_dependent_children,
                               canadian_federal_tax_meth_cd,
                               canadian_federal_tax_amt,
                               canadian_federal_tax_pct,
                               canadian_federal_claim_amt,
                               canadian_province_claim_amt,
                               tax_unit_code,
                               requires_tm_card_ind,
                               xfer_type_code,
                               tax_clear_code,
                               pay_type_code,
                               labor_distn_code,
                               labor_distn_ext_code,
                               us_fui_status_code,
                               us_fica_status_code,
                               payable_through_bank_id,
                               disbursal_seq_nbr_1,
                               disbursal_seq_nbr_2,
                               non_employee_indicator,
                               excluded_from_payroll_ind,
                        /* R6.1M-ssa# 29829 Begin */
                        /*     emp_info_source_code,  */
                               @w_source_code,
                        /* R6.1M-ssa# 29829 End */
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
                               t4_employ_code,         /* R6.0M - SSA# 23771 */
                               0
                        from  emp_employment
                        where emp_id = @p_emp_id
                          and eff_date <= @p_new_pay_through_date
                         and next_eff_date > @p_new_pay_through_date

            if @@error != 0
            begin
                /* rollback transaction ssa 30724 */
--SYBSQL        raiserror 20003 "Error inserting into emp_employment"
          raiserror ('20003 Error inserting into emp_employment',16,0)
                return
            end /* if @@error != 0 */

            select @w_next_eff_date = next_eff_date
                         from emp_employment
                        where emp_id = @p_emp_id
                          and eff_date <= @p_new_pay_through_date
                          and next_eff_date > @p_new_pay_through_date

            if @w_next_eff_date <> "29991231"
            begin
                update  emp_employment
                    set  prior_eff_date = @w_pay_through_date_plus_one
                                 where  emp_id = @p_emp_id
                                   and  eff_date = @w_next_eff_date

                if @@rowcount = 0
                begin
                    if exists (select * from emp_employment
                                                 where emp_id = @p_emp_id
                                                   and eff_date = @w_pay_through_date_plus_one)
--SYBSQL                raiserror 20001 "Row updated by another user."
                  raiserror ('20001 Row updated by another user.',16,0)
                    else
--SYBSQL                raiserror 20002 "Row does not exist."
                  raiserror ('20002 Row does not exist.',16,0)
                    /* rollback transaction  ssa 30724 */
                    return
                end /* if @@error != 0 */
            end /* if @w_next_eff_date <> "29991231" */

            update  emp_employment
                set  next_eff_date = @w_pay_through_date_plus_one
                         where  emp_id = @p_emp_id
                           and  eff_date <= @p_new_pay_through_date
                           and  next_eff_date > @p_new_pay_through_date

            if @@rowcount = 0
            begin
                if exists (select * from emp_employment
                                         where emp_id = @p_emp_id
                                           and eff_date = @w_pay_through_date_plus_one)
--SYBSQL            raiserror 20001 "Row updated by another user."
              raiserror ('20001 Row updated by another user.',16,0)
                else
--SYBSQL            raiserror 20002 "Row does not exist."
              raiserror ('20002 Row does not exist.',16,0)
                /* rollback transaction ssa 30724 */
                return
            end /* if @@error != 0 */
        end /* need new row */
    end /* if @p_pay_status_code <> @w_pay_status_code */
end /* if @p_pay_status_code <> "" */

/* ************************************************************ */
/* Update employment versions effective dated after the         */
/* termination date.    1665080/20160121                        */
/* ************************************************************ */
if @p_pay_status_code <> @w_pay_status_code
begin
    /* AUDIT SECTION======================================*/
    /* UPDATE work employee employment audit table -      */
    /* ===================================================*/
    /* R6.5.01M-ALS#286282: begin-add */
    update work_emp_employment_aud
               set eff_date = @w_pay_through_date_plus_one
             where emp_id = @p_emp_id
               and eff_date = @p_new_pay_through_date
               and activity_action_code = 'TERM'
               and user_id = @W_ACTION_USER
            /* R6.5.01M-ALS#286282: end-add */

    /* END AUDIT SECTION==================================*/
    /* UPDATE work employee employment audit table -      */
    /* ===================================================*/

    update  emp_employment
        set     pay_through_date = @p_new_pay_through_date,
                    pay_status_code  = @p_pay_status_code
            where   emp_id = @p_emp_id
              and   eff_date > @p_termination_date /* 1665080/20160121 @p_new_pay_through_date */
end  /* if @p_pay_status_code <> @w_pay_status_code */
else /* if @p_pay_status_code = @w_pay_status_code */
begin
    /* AUDIT SECTION======================================*/
    /* UPDATE work employee employment audit table -      */
    /* ===================================================*/

    /* R6.5.01M-ALS#286282: begin-add */
    update work_emp_employment_aud
            set eff_date = @w_pay_through_date_plus_one
             where emp_id = @p_emp_id
               and eff_date = @p_new_pay_through_date
               and activity_action_code = 'TERM'
               and user_id = @W_ACTION_USER
    /* R6.5.01M-ALS#286282: end-add */

    /* END AUDIT SECTION==================================*/
    /* UPDATE work employee employment audit table -      */
    /* ===================================================*/

    update  emp_employment
            set     pay_through_date = @p_new_pay_through_date
            where   emp_id = @p_emp_id
              and   eff_date > @p_termination_date /* 1665080/20160121 @p_new_pay_through_date */
end /* if @p_pay_status_code = @w_pay_status_code */
/* ************************************************************ */
/* End of Additions for Release 5.0                             */
/* ************************************************************ */

/* R6.5.01M-ALS#286282: begin-add */
Delete work_emp_employment_aud
 Where user_id = @W_ACTION_USER
   and activity_action_code = 'TERM'
   and action_date = @W_ACTION_DATETIME
   and emp_id = @p_emp_id
/* R6.5.01M-ALS#286282: end-add */

/* AUDIT SECTION ==============================================*/
/* Set up the work employee employment audit table             */
/* ============================================================*/

/****************************************************************/
/* Update each selected Employee Assignment with the End Date   */
/* equal to the Termination Date.                               */
/****************************************************************/

/*********************************************************************
Bypass emp_assignment audit logic if emp_assignment auditing is not turned on
**********************************************************************/
if @w_audit_emp_assign_tbl = "N" /* 564993 */
   goto nextprocess1             /* 564993 */

/* AUDIT SECTION ==============================================*/
/* Set up the work employee assignment audit table             */
/* ============================================================*/

   DECLARE EMPASSIGNCURSOR cursor FOR
   SELECT  emp_id, assigned_to_code, job_or_pos_id, eff_date, next_eff_date, prior_eff_date
   FROM    emp_assignment
   WHERE   emp_id = @p_emp_id AND
           eff_date <= @p_termination_date AND
           (
             (next_eff_date > @p_termination_date AND next_eff_date != @w_end_of_time) OR
             (next_eff_date = @w_end_of_time  AND end_date > @p_termination_date)
           )


   OPEN EMPASSIGNCURSOR

   FETCH EMPASSIGNCURSOR INTO
         @w_emp_id, @w_assigned_to_code, @w_job_or_pos_id, @w_effect_date,
         @w_next_effect_date,@w_prior_effect_date

   WHILE (@@fetch_status=0)
   BEGIN

        SELECT @W_MS = CONVERT (char(3), datepart(millisecond,getdate()))
        IF datalength(rtrim(@W_MS)) = 1
        BEGIN
		    SELECT @W_MS = '00'+substring(@W_MS,1,1)
        END
        ELSE
        BEGIN
            IF datalength(rtrim(@W_MS)) = 2
            BEGIN
                SELECT @W_MS = '0'+substring(@W_MS,1,2)
            END
        END

        SELECT @W_ACTION_DATETIME = CONVERT(char(10), getdate(), 111) + '-' +
                                    CONVERT(char(8), getdate(), 108) + ':' + @W_MS


        INSERT INTO work_emp_assignment_aud
        VALUES (@W_ACTION_USER, 'TERMENDASG', @W_ACTION_DATETIME,
                @w_emp_id, @w_assigned_to_code, @w_job_or_pos_id, @w_effect_date, @w_next_effect_date,
                @w_prior_effect_date, '', '', @p_termination_date, '', '', '')


        DELETE work_emp_assignment_aud
        WHERE  user_id = @W_ACTION_USER AND
               activity_action_code = 'TERMENDASG' AND
               emp_id = @w_emp_id /* 564993 */

        /* SSA# 524688 - delay 150 ms. This will ensure that duplicate key */
        /* insert error in audit processing will not happen  */
        waitfor delay "00:00:00:150"

        FETCH EMPASSIGNCURSOR INTO
              @w_emp_id, @w_assigned_to_code, @w_job_or_pos_id, @w_effect_date,
              @w_next_effect_date,@w_prior_effect_date

   END

   CLOSE EMPASSIGNCURSOR
   deallocate EMPASSIGNCURSOR

   /* SSA 30832 END */

/* END AUDIT SECTION ==========================================*/
/* Set up the work employee assignment audit table             */
/* ============================================================*/

nextprocess1:             /* 564993 */

update emp_assignment
   set end_date = @p_termination_date,
      next_eff_date = @w_end_of_time,
      next_assigned_to_code = " ",
      next_job_or_pos_id = space(10),
      chgstamp = chgstamp + 1
   from    emp_assignment
   where    emp_id = @p_emp_id
    and    eff_date <= @p_termination_date
    and  ((next_eff_date > @p_termination_date
            and next_eff_date != @w_end_of_time)
            or (next_eff_date = @w_end_of_time
               and end_date > @p_termination_date))

/*************************************************************************/
/* Reset Next Effective Date in Inactivate Employee Assignment Versions. */
/*************************************************************************/
update emp_assignment
   set    next_eff_date = @w_end_of_time,
         chgstamp = chgstamp + 1
   from   emp_assignment
   where   emp_id = @p_emp_id
    and   ((eff_date <= @p_termination_date
           and   next_eff_date > @p_termination_date)
         and  end_date < @p_termination_date)
   and      next_eff_date != @w_end_of_time

/*****************************************************************/
/* Delete All job/position assignment information that is future */
/* dated relative to the termination date for the employee.      */
/*****************************************************************/

/*********************************************************************
Bypass emp_assignment audit logic if emp_assignment auditing is not turned on
**********************************************************************/
if @w_audit_emp_assign_tbl = "N" /* 564993 */
   goto nextprocess2             /* 564993 */

/* AUDIT SECTION ==============================================*/
/* Set up the work employee assignment audit table             */
/* ============================================================*/

   DECLARE EMPASSIGNCURSOR cursor FOR
   SELECT emp_id, assigned_to_code, job_or_pos_id, eff_date, next_eff_date, prior_eff_date
   FROM emp_assignment
   WHERE emp_id = @p_emp_id AND eff_date > @p_termination_date

   OPEN EMPASSIGNCURSOR

   FETCH EMPASSIGNCURSOR INTO
         @w_emp_id, @w_assigned_to_code, @w_job_or_pos_id, @w_effect_date,
         @w_next_effect_date,@w_prior_effect_date

   WHILE (@@fetch_status=0)
   BEGIN

        SELECT @W_MS = CONVERT (char(3), datepart(millisecond,getdate()))
        IF datalength(rtrim(@W_MS)) = 1
        BEGIN
		    SELECT @W_MS = '00'+substring(@W_MS,1,1)
        END
        ELSE
        BEGIN
            IF datalength(rtrim(@W_MS)) = 2
            BEGIN
                SELECT @W_MS = '0'+substring(@W_MS,1,2)
            END
        END

        SELECT @W_ACTION_DATETIME = CONVERT(char(10), getdate(), 111) + '-' +
                                    CONVERT(char(8), getdate(), 108) + ':' + @W_MS

        INSERT INTO work_emp_assignment_aud
        VALUES (@W_ACTION_USER, 'TERMASGDV', @W_ACTION_DATETIME,
                @w_emp_id, @w_assigned_to_code, @w_job_or_pos_id, @w_effect_date, @w_next_effect_date,
                @w_prior_effect_date, '', '', @p_termination_date, '', '', '' )

        DELETE work_emp_assignment_aud
        WHERE user_id = @W_ACTION_USER AND
              activity_action_code = 'TERMASGDV' AND
              emp_id = @w_emp_id /* 564993 */

        /* SSA# 524688 - delay 150 ms. This will ensure that duplicate key */
        /* insert error in audit processing will not happen  */
        waitfor delay "00:00:00:150"

        FETCH EMPASSIGNCURSOR INTO
              @w_emp_id, @w_assigned_to_code, @w_job_or_pos_id, @w_effect_date,
              @w_next_effect_date,@w_prior_effect_date

   END

   CLOSE EMPASSIGNCURSOR
   deallocate EMPASSIGNCURSOR

   /* SSA 30832 END */

/* END AUDIT SECTION =======================================*/
/* Set up the work employee assignment audit table          */
/* =========================================================*/
nextprocess2:             /* 564993 */


delete from emp_assignment
    where   emp_id = @p_emp_id
    and     eff_date > @p_termination_date

/****************************************************************/
/* Delete All assignment comments that are future dated relative*/
/* to the termination date for the employee.                    */
/****************************************************************/
delete from emp_assignment_comnt
                where   emp_id = @p_emp_id
                and     begin_date > @p_termination_date

/* R6.5.02MCEXP-ALS#524447: Begin */
/****************************************************************/
/* Delete All assignment distributions that are future dated    */
/* relative to the termination date for the employee.           */
/****************************************************************/
delete from emp_assignment_distribution
                where   emp_id   = @p_emp_id
                and     eff_date > @p_termination_date
/* R6.5.02MCEXP-ALS#524447: End */

/*************************************************************************/
/* Stop Active Employee EARNING Pay Elements As of the Pay Through Date. */
/*************************************************************************/

/* AUDIT SECTION ==============================================*/
/* Set up the work employee pay element audit table            */
/* ============================================================*/
   insert into work_emp_pay_element_aud
   select
      @W_ACTION_USER, 'TERMSTOPPE', @W_ACTION_DATETIME, emp_id,
      empl_id, emp_pay_element.pay_element_id, emp_pay_element.eff_date,
        '', '', '', '', @p_new_pay_through_date

      from emp_pay_element, pay_element
      where  emp_id = @p_emp_id
      and  emp_pay_element.eff_date <= @p_new_pay_through_date
      and    ((emp_pay_element.next_eff_date > @p_new_pay_through_date
           and emp_pay_element.next_eff_date != @w_end_of_time)
         or (emp_pay_element.next_eff_date = @w_end_of_time
            and emp_pay_element.stop_date > @p_new_pay_through_date))
      and    pay_element.pay_element_id = emp_pay_element.pay_element_id
      and pay_element.eff_date <= @p_new_pay_through_date     /* 564993 */
      and pay_element.next_eff_date > @p_new_pay_through_date /* 564993 */
      and    (pay_element.ben_plan_id = " " or pay_element.ben_plan_id = "")
      and pay_element.pay_element_type_code = '1'

   Delete work_emp_pay_element_aud
      Where user_id = @W_ACTION_USER
      and activity_action_code = 'TERMSTOPPE'
      and action_date = @W_ACTION_DATETIME
      and emp_id = @p_emp_id
/* END AUDIT SECTION ==========================================*/
/* Set up the work employee pay element audit table            */
/* ============================================================*/

declare emp_pay_element_cursor cursor for
   select emp_pay_element.emp_id, emp_pay_element.empl_id,
      emp_pay_element.pay_element_id, emp_pay_element.eff_date
      from emp_pay_element, pay_element
    where  emp_id = @p_emp_id
      and  emp_pay_element.eff_date <= @p_new_pay_through_date
      and    ((emp_pay_element.next_eff_date > @p_new_pay_through_date
              and emp_pay_element.next_eff_date != @w_end_of_time)
         or (emp_pay_element.next_eff_date = @w_end_of_time
            and emp_pay_element.stop_date > @p_new_pay_through_date))
      and    pay_element.pay_element_id = emp_pay_element.pay_element_id
      and pay_element.eff_date <= @p_new_pay_through_date     /* 564993 */
      and pay_element.next_eff_date > @p_new_pay_through_date /* 564993 */
      and    (pay_element.ben_plan_id = " " or pay_element.ben_plan_id = "")
      and pay_element.pay_element_type_code = '1'

      open emp_pay_element_cursor

      fetch emp_pay_element_cursor
            into    @c_emp_id, @c_empl_id,
               @c_pay_element_id, @c_eff_date

      while (@@fetch_status = 0)
         begin
            update emp_pay_element
              set stop_date = @p_new_pay_through_date,
                  next_eff_date = @w_end_of_time,
                  inactivated_by_pay_element_ind = 'N',
                  chgstamp = chgstamp + 1
            where emp_id = @c_emp_id
            and empl_id = @c_empl_id
            and pay_element_id = @c_pay_element_id
            and eff_date = @c_eff_date

            delete from emp_pay_element_limit
            where emp_id = @c_emp_id
            and empl_id = @c_empl_id
            and pay_element_id = @c_pay_element_id
            and start_date > @p_new_pay_through_date

            delete from emp_pay_element_comnt
            where emp_id = @c_emp_id
            and empl_id = @c_empl_id
            and pay_element_id = @c_pay_element_id
            and start_date > @p_new_pay_through_date

         fetch emp_pay_element_cursor
            into    @c_emp_id, @c_empl_id,
               @c_pay_element_id, @c_eff_date
         end

      close emp_pay_element_cursor
      deallocate emp_pay_element_cursor

/*************************************************************/
/* Delete Future Dated Employee EARNING Pay Elements Not     */
/* Associated with Benefit Plans.                            */
/*************************************************************/

/* AUDIT SECTION ==============================================*/
/* Set up the work employee pay element audit table            */
/* ============================================================*/
   insert into work_emp_pay_element_aud
   select
      @W_ACTION_USER, 'TERMDELPE', @W_ACTION_DATETIME, emp_id,
         empl_id, emp_pay_element.pay_element_id, emp_pay_element.eff_date,
             '', '', '', '', ''

      from emp_pay_element, pay_element
      where emp_pay_element.emp_id = @p_emp_id
        and emp_pay_element.eff_date > @p_new_pay_through_date
        and emp_pay_element.pay_element_id = pay_element.pay_element_id
        and pay_element.eff_date <= @p_new_pay_through_date     /* 564993 */
        and pay_element.next_eff_date > @p_new_pay_through_date /* 564993 */
       and (pay_element.ben_plan_id = " " or pay_element.ben_plan_id = "")
       and pay_element.pay_element_type_code = '1'

   Delete work_emp_pay_element_aud
      Where user_id = @W_ACTION_USER
      and activity_action_code = 'TERMDELPE'
      and action_date = @W_ACTION_DATETIME
      and emp_id = @p_emp_id
/* END AUDIT SECTION ==========================================*/
/* Set up the work employee pay element audit table            */
/* ============================================================*/

   delete from emp_pay_element
      where emp_pay_element.emp_id = @p_emp_id
        and emp_pay_element.eff_date > @p_new_pay_through_date
        and emp_pay_element.pay_element_id in
            (select pay_element_id from #temp1) /* SSA 30724 */

   delete from emp_pay_element_limit
      where emp_pay_element_limit.emp_id = @p_emp_id
        and emp_pay_element_limit.start_date > @p_new_pay_through_date
        and emp_pay_element_limit.pay_element_id in
            (select pay_element_id from #temp1) /* SSA 30724 */

   delete from emp_pay_element_comnt
      where emp_pay_element_comnt.emp_id = @p_emp_id
        and emp_pay_element_comnt.start_date > @p_new_pay_through_date
        and emp_pay_element_comnt.pay_element_id in
            (select pay_element_id from #temp1) /* SSA 30724 */


/* R6.5.02MCEXP-ALS#523706: Begin - rewrite */
/********************************************************************/
/* Process Benefit Plan Participation.  This logic determines       */
/* the plans the employee is participating in, as of their          */
/* termination date, and whether they are to be terminated or left  */
/* unchanged (i.e. remain enrolled in).                             */
/********************************************************************/
/* Determine the Benefit Plan Termination Policy for any Benefit    */
/* Plans that the employee may have or will participate in.         */
/********************************************************************/
declare ben_plan_ptcp_cursor cursor for
   select DISTINCT ben_plan_ptcp_status.ben_plan_id,
          end_participation_as_of_code,
          ben_plan_ptcp_status.participant_id
     from ben_plan, ben_plan_ptcp_status, participant
    where ben_plan_ptcp_status.participant_id = participant.participant_id
      and ben_plan_ptcp_status.ben_plan_id    = ben_plan.ben_plan_id
      and participant.emp_id                  = @p_emp_id
      and end_ptcpn_on_emplmnt_termn_ind      = "Y"
      and (ben_plan.eff_date      <= @p_termination_date and
           ben_plan.next_eff_date >  @p_termination_date)

     open ben_plan_ptcp_cursor

    fetch ben_plan_ptcp_cursor
     into @c_ben_plan_id,
          @c_end_ptcpn_as_of_code,
          @c_participant_id

    while (@@fetch_status = 0)
         begin
            if @c_end_ptcpn_as_of_code = "1"
                  select @w_as_of_date = @p_termination_date

            if @c_end_ptcpn_as_of_code = "3"
               begin
                  select @w_month_part = datepart(month,@p_termination_date)
                  select @w_year_part  = datepart(year,@p_termination_date)

                  if @w_month_part = 12
                     begin
                           select @w_month_part = 1
                           select @w_year_part  = @w_year_part + 1
                     end
                  else
                           select @w_month_part = @w_month_part + 1

                  select @w_first_date  = convert(char, @w_month_part)
                  select @w_second_date = convert(char, @w_year_part)
                  select @w_third_date  = IsNull (LTrim (@w_first_date), '') + "/" + "01" + "/"  + @w_second_date
                  select @w_as_of_date  = @w_third_date
                  select @w_as_of_date  = dateadd(day, -1, @w_as_of_date)
               end

            if @c_end_ptcpn_as_of_code = "2"
                  select @w_as_of_date = @p_new_pay_through_date

            if @c_end_ptcpn_as_of_code = "4"
               begin
                  select @w_month_part = datepart(month,@p_new_pay_through_date)
                  select @w_year_part  = datepart(year,@p_new_pay_through_date)

                  if @w_month_part = 12
                     begin
                           select @w_month_part = 1
                           select @w_year_part  = @w_year_part + 1
                     end
                  else
                           select @w_month_part = @w_month_part + 1

                  select @w_first_date  = convert(char, @w_month_part)
                  select @w_second_date = convert(char, @w_year_part)
                  select @w_third_date  = IsNull (LTrim (@w_first_date), '') + "/" + "01" + "/" + @w_second_date
                  select @w_as_of_date  = @w_third_date
                  select @w_as_of_date  = dateadd(day, -1, @w_as_of_date)
               end

              /* Process Active Benefit Plans */
              /* Determine the plans the employee is participating in based on the  */
              /* As-of-Date variable that was retrieved above from the Benefit Plan */
              /* Termination Participation Date Code (@c_end_ptcpn_as_of_code).     */
              /* (If next_status_change_date = @w_as_of_date, then that row will    */
              /* not be selected.  The stop dates do not need to be updated.)       */
              if exists (select *
                         from ben_plan, ben_plan_ptcp_status, participant
                        where ben_plan_ptcp_status.participant_id = @c_participant_id
                          and participant.participant_id          = @c_participant_id
                          and ben_plan_ptcp_status.ben_plan_id    = @c_ben_plan_id
                          and ben_plan.ben_plan_id                = @c_ben_plan_id
                          and participant.emp_id                  = @p_emp_id
                          and (status_change_date      <= @w_as_of_date and
                               next_status_change_date >  @w_as_of_date)
                          and end_ptcpn_on_emplmnt_termn_ind      = "Y"
                          and (ptcp_status_code = "1" or
                               ptcp_status_code = "2" or
                               ptcp_status_code = "5")
                          and (ben_plan.eff_date       <= @p_termination_date and
                               ben_plan.next_eff_date  >  @p_termination_date))
                begin
                  execute hsp_upd_hbpo_terminate
                          @c_participant_id,
                          @c_ben_plan_id,
                          @w_as_of_date,
                          @p_emp_id
                end

              /* ************************************************************** */
              /* Delete the employee's participation in benefit plans that were */
              /* scheduled to start later than their termination date based on  */
              /* the Benefit Plan Termination Policy.  If the employee had been */
              /* in the plan previously, then only delete their participation   */
              /* that was scheduled to start after their termination date.      */
              /* ************************************************************** */
              if exists(select *
                        from ben_plan, ben_plan_ptcp_status, participant
                        where ben_plan_ptcp_status.participant_id = @c_participant_id
                          and participant.participant_id          = @c_participant_id
                          and ben_plan_ptcp_status.ben_plan_id    = @c_ben_plan_id
                          and ben_plan.ben_plan_id                = @c_ben_plan_id
                          and participant.emp_id                  = @p_emp_id
                          and (status_change_date       >  @p_termination_date and
                               prior_status_change_date >  @p_termination_date)
                          and end_ptcpn_on_emplmnt_termn_ind      = "Y"
                          and (ben_plan.eff_date        <= @p_termination_date and
                               ben_plan.next_eff_date   >  @p_termination_date))
                begin
                  execute hsp_del_hpcp_driver
                          @c_participant_id,
                          @c_ben_plan_id,
                          3,
                          @p_emp_id,
                          '',
                          @w_as_of_date
                end

            fetch ben_plan_ptcp_cursor
             into @c_ben_plan_id,
                  @c_end_ptcpn_as_of_code,
                  @c_participant_id
         end

    close ben_plan_ptcp_cursor
    deallocate ben_plan_ptcp_cursor
/* R6.5.02MCEXP-ALS#523706: End - rewrite */

/****************************************************************/
/* Update the Employee Status Next Change Date with the         */
/* Termination Date.                                            */
/****************************************************************/
update emp_status
   set next_change_date   = @p_termination_date,
       chgstamp           = @w_new_chgstamp
 where emp_id             = @p_emp_id
  and  status_change_date = @p_status_change_date
  and  chgstamp           = @p_old_chgstamp

if @@rowcount = 0
    begin
       if exists (select * from emp_status
            where emp_id = @p_emp_id
              and status_change_date = @p_status_change_date)
--SYBSQL             raiserror 20001 "Row updated by another user."
          raiserror ('20001 Row updated by another user.',16,0)
       else
--SYBSQL             raiserror 20002 "Row does not exist."
          raiserror ('20002 Row does not exist.',16,0)
           /*  rollback transaction ssa 30724 */
            return
    end

/***************************************************************/
/* Insert the new Employee Status row with the status change   */
/* date equal to the termination date.                         */
/***************************************************************/
insert into emp_status
          select  @p_emp_id,                @p_termination_date,
                  @p_status_change_date,    @w_end_of_time,
                  @w_status_code,           @p_new_classn_cd,
                  @w_spaces,                hire_date,
                  @w_end_of_time,           @p_new_rehire_conson,
                  @w_spaces,                @p_new_reason_code,
                  @w_last_action_cd,        0
            from  emp_status
           where  emp_id = @p_emp_id
             and  status_change_date = @p_status_change_date

if @@error != 0
                begin
                        /* rollback transaction  ssa 30724 */
--SYBSQL 			raiserror 20004 "Error inserting into emp_status"
          raiserror ('20004 Error inserting into emp_status',16,0)
                        return
                end
/**************************************************************/
/* If the date of death has been entered, update individual   */
/* personal with Death Date.                                  */
/**************************************************************/
if @p_date_of_death != @w_end_of_time
   update individual_personal
      set death_date = @p_date_of_death,
          chgstamp = chgstamp + 1
    where individual_id = (select individual.individual_id
                             from individual, employee
                            where individual.individual_id = employee.individual_id /*SSA# 18025 R4.1M */
                              and employee.emp_id          = @p_emp_id)


/* AUDIT SECTION ==============================================*/
/* Set up the work employee status audit table                 */
/* ============================================================*/
   insert into work_emp_status_aud
      (user_id, activity_action_code, action_date, emp_id,
       status_change_date, prior_change_date, prior_emp_id)
   values
      (@W_ACTION_USER, 'TERMINATE', @W_ACTION_DATETIME,
       @p_emp_id, @p_termination_date, @p_status_change_date, '')

   Delete work_emp_status_aud
   Where user_id = @W_ACTION_USER
   and activity_action_code = 'TERMINATE'
   and emp_id = @p_emp_id
   and status_change_date = @p_termination_date

/* END AUDIT SECTION ==========================================*/
/* Set up the work employee status audit table                 */
/* ============================================================*/

/********************************************************************/
/* Select the employee assignment version (with the terminated      */
/* manager) less than the managers termination date.                */
/* Note: 1. Do not select if the assignment has ended prior to      */
/*          termination.                                            */
/*       2. this is the max effective dated version less than the   */
/*          termination date                                        */
/********************************************************************/

/* SSA 30724 Begin */
/* All Code in this section was removed and replaced by the following code from SSA 30724 */
/* SSA 30724 End */

/* SSA 30724 Begin New */
/*********************************************************************
564993 - Cursor removed for emp_mgr__emp_id processing and replaced
         with a select statement.
**********************************************************************/
SELECT @w_row = 0

INSERT INTO #temp2
SELECT  @w_row,
        emp_id,
        assigned_to_code,
        job_or_pos_id,
        eff_date,
        next_eff_date,
        prior_eff_date,
        end_date
FROM    emp_assignment
WHERE   mgr_emp_id    = @p_emp_id AND
        emp_id        > "" AND
        eff_date     <= @p_termination_date AND
        next_eff_date > @p_termination_date
--        (end_date = @w_end_of_time or end_date > @p_termination_date) /* 564993 */

SELECT  @w_total_rows = count(*)
FROM	#temp2

SELECT @w_row = 0

set rowcount 1
while  @w_row < @w_total_rows
begin
    SELECT @w_row = @w_row + 1
    update #temp2 set row_id = @w_row
        where row_id=0
    continue
end
set rowcount 0

/*********************************************************************
564993 - Moved this audit section for emp_assignment from its own
         cursor to here in order to use table #temp2
**********************************************************************/
/*********************************************************************
564993 - Bypass emp_assignment audit logic if emp_assignment auditing is not turned on
**********************************************************************/
if @w_audit_emp_assign_tbl = "N" /* 564993 */
   goto nextprocess3             /* 564993 */

SELECT  @w_row = 1

While (@w_row <= @w_total_rows)
BEGIN
	SELECT @c_emp_id = emp_id,
	       @c_assigned_to_code = assigned_to_code,
	       @c_job_or_pos_id = job_or_pos_id,
	       @c_eff_date = eff_date,
	       @c_next_eff_date = next_eff_date,
	       @c_prior_eff_date = prior_eff_date,
	       @c_end_date = end_date
	FROM   #temp2
	WHERE  row_id = @w_row

	SELECT @w_row = @w_row + 1

   if @c_end_date <= @p_termination_date /* 564993 */
   begin                                 /* 564993 */
      continue                           /* 564993 */
   end                                   /* 564993 */


        SELECT @W_MS = CONVERT (char(3), datepart(millisecond,getdate()))
        IF datalength(rtrim(@W_MS)) = 1
          BEGIN
		    SELECT @W_MS = '00'+substring(@W_MS,1,1)
          END
        ELSE
          BEGIN
            IF datalength(rtrim(@W_MS)) = 2
              BEGIN
                SELECT @W_MS = '0'+substring(@W_MS,1,2)
              END
          END

        SELECT @W_ACTION_DATETIME = CONVERT(char(10), getdate(), 111) + '-' +
                                    CONVERT(char(8), getdate(), 108) + ':' + @W_MS

        INSERT INTO work_emp_assignment_aud
        VALUES (@W_ACTION_USER, 'TERMDELMGR', @W_ACTION_DATETIME,
                @c_emp_id, @c_assigned_to_code, @c_job_or_pos_id, @c_eff_date,
                @p_termination_date, '', '', '', '', '', '', '' )

        DELETE work_emp_assignment_aud
        WHERE user_id = @W_ACTION_USER AND
              activity_action_code = 'TERMDELMGR' AND
              emp_id = @c_emp_id

        /* SSA# 524688 - delay 150 ms. This will ensure that duplicate key */
        /* insert error in audit processing will not happen  */
        waitfor delay "00:00:00:150"
END
/*********************************************************************
564993 - End - Moved this audit section for emp_assignment from its own
         cursor to here in order to use table #temp2
**********************************************************************/

nextprocess3:             /* 564993 */

SELECT  @w_row = 1

While (@w_row <= @w_total_rows)
  Begin
	SELECT @c_emp_id = emp_id,
	       @c_assigned_to_code = assigned_to_code,
	       @c_job_or_pos_id = job_or_pos_id,
	       @c_eff_date = eff_date,
	       @c_next_eff_date = next_eff_date,
	       @c_prior_eff_date = prior_eff_date,
	       @c_end_date = end_date
	FROM   #temp2
	WHERE  row_id = @w_row

	SELECT @w_row = @w_row + 1

   if @c_end_date <= @p_termination_date /* 564993 */
   begin                                 /* 564993 */
      continue                           /* 564993 */
   end                                   /* 564993 */

	   UPDATE emp_assignment
	   SET	  next_eff_date = @w_termination_date_plus_one,
        	  end_date =    @w_end_of_time,
	          chgstamp = chgstamp + 1
	   WHERE  emp_id = @c_emp_id AND
        	  assigned_to_code = @c_assigned_to_code AND
	          job_or_pos_id = @c_job_or_pos_id AND
        	  eff_date = @c_eff_date

      /***************************************************************
      521449 - Adding a check to make sure a row does not already
                  exist with this effective date.  This is possible if
                  the deleted employee's last status was deleted and
                  then re-terminated.
      ****************************************************************/
      if not exists (select * from emp_assignment
                      WHERE  emp_id = @c_emp_id AND
                             assigned_to_code = @c_assigned_to_code AND
                             job_or_pos_id = @c_job_or_pos_id AND
                             eff_date = @w_termination_date_plus_one)
      begin /* 521449 */
	   INSERT INTO emp_assignment
	   SELECT emp_id,
		  assigned_to_code,			job_or_pos_id,
		  @w_termination_date_plus_one,		@c_next_eff_date,
		  @c_eff_date,				next_assigned_to_code,
		  next_job_or_pos_id,			prior_assigned_to_code,
		  prior_job_or_pos_id,			begin_date,
		  @c_end_date,				assignment_reason_code,			  		  		  		  organization_chart_name,		organization_unit_name,
		  organization_group_id,		organization_change_reason_cd,
 		  loc_code,               		@w_spaces,
	          official_title_code,      		official_title_date,
	          salary_change_date,      		annual_salary_amt,
        	  pd_salary_amt,         		pd_salary_tm_pd_id,
	          hourly_pay_rate,         		curr_code,
        	  pay_on_reported_hrs_ind, 		salary_change_type_code,
	          standard_work_pd_id,      		standard_work_hrs,
        	  work_tm_code,            		work_shift_code,
		  salary_structure_id,      		salary_increase_guideline_id,
  	          pay_grade_code,         		pay_grade_date,
  	          job_evaluation_points_nbr,   		salary_step_nbr,
  	          salary_step_date,         		phone_1_type_code,
   	          phone_1_fmt_code,         		phone_1_fmt_delimiter,
        	  phone_1_intl_code,      		phone_1_country_code,
          	  phone_1_area_city_code,  		phone_1_nbr,
          	  phone_1_extension_nbr,   		phone_2_type_code,
	          phone_2_fmt_code,         		phone_2_fmt_delimiter,
        	  phone_2_intl_code,      		phone_2_country_code,
	          phone_2_area_city_code,   		phone_2_nbr,
        	  phone_2_extension_nbr,   		prime_assignment_ind,
	          pay_basis_code,         		occupancy_code,
        	  regulatory_reporting_unit_code,   	base_rate_tbl_id,
	          base_rate_tbl_entry_code,   		shift_differential_rate_tbl_id,
        	  ref_annual_salary_amt,   		ref_pd_salary_amt,
	          ref_pd_salary_tm_pd_id,   		ref_hourly_pay_rate,
        	  guaranteed_annual_salary_amt,   	guaranteed_pd_salary_amt,
	          guaranteed_pd_salary_tm_pd_id,   	guaranteed_hourly_pay_rate,
 	          exception_rate_ind,      		overtime_status_code,
	          shift_differential_status_code,   	standard_daily_work_hrs,
	          user_amt_1,            		user_amt_2,
	          user_code_1,            		user_code_2,
	          user_date_1,            		user_date_2,
	          user_ind_1,            		user_ind_2,
	          user_monetary_amt_1,      		user_monetary_amt_2,
	          user_monetary_curr_code,   		user_text_1,
	          user_text_2, 				unemployment_loc_code,
	          include_salary_in_autopay_ind,	0
	   FROM   emp_assignment
	   WHERE  emp_id = @c_emp_id AND
		  assigned_to_code = @c_assigned_to_code AND
	          job_or_pos_id = @c_job_or_pos_id AND
        	  eff_date = @c_eff_date AND                        /* 521449 */
           next_eff_date = @w_termination_date_plus_one AND  /* 521449 */
        	 (end_date = @w_end_of_time or end_date > @p_termination_date)
      end   /* 521449 */

	   UPDATE emp_assignment
	   SET    prior_eff_date = @w_termination_date_plus_one, chgstamp = chgstamp + 1
	   WHERE  emp_id = @c_emp_id AND
        	  assigned_to_code = @c_assigned_to_code AND
	          job_or_pos_id = @c_job_or_pos_id AND
        	  eff_date = @c_next_eff_date

  End
/* SSA 30724 End New */

/****************************************************************/
/* REMOVE TERMINATED EMPLOYEE AS MANAGER OF ANY OTHER EMPLOYEES */
/****************************************************************/

update emp_assignment
   set mgr_emp_id = @w_spaces,
       chgstamp   = chgstamp + 1
 where mgr_emp_id = @p_emp_id
   and eff_date   > @p_termination_date

/* commit transaction  ssa 30724 */

return




GO
ALTER AUTHORIZATION ON [dbo].[usp_upd_hmpl_terminate] TO  SCHEMA OWNER
GO

IF OBJECT_ID(N'dbo.usp_upd_hmpl_terminate', N'P') IS NOT NULL
    PRINT N'<<< CREATED PROCEDURE dbo.usp_upd_hmpl_terminate >>>'
ELSE
    PRINT N'<<< FAILED CREATING PROCEDURE dbo.usp_upd_hmpl_terminate >>>'
GO
