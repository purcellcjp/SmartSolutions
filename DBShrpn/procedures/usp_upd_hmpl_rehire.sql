USE DBShrpn
go
IF OBJECT_ID(N'dbo.usp_upd_hmpl_rehire') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_upd_hmpl_rehire
    IF OBJECT_ID(N'dbo.usp_upd_hmpl_rehire') IS NOT NULL
        PRINT N'<<< FAILED DROPPING PROCEDURE dbo.usp_upd_hmpl_rehire >>>'
    ELSE
        PRINT N'<<< DROPPED PROCEDURE dbo.usp_upd_hmpl_rehire >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER OFF
GO


/*************************************************************************************

   SP Name:      usp_upd_hmpl_rehire

   Description:  Executes SmartStream rehire process

                 Cloned from DBShrpn..hsp_upd_hmpl_rehire in order to use with
                 HCM Interface position title update procedure DBShrpn..usp_ins_position_title.

   Parameters:


   Tables

   Example:
      exec usp_upd_hmpl_rehire ....

   Revision history:
      version  date        developer   SCR      description
      -------  ----------  ---------   -----    ------------------------------------
      1.0.00                                    - Cloned from SmartStream version DBShrpn..hsp_upd_hmpl_rehire
                                                    1) Disabled authentication

************************************************************************************/

CREATE procedure [dbo].[usp_upd_hmpl_rehire]
       (@p_emp_id					char(15),
	@p_previous_emp_id				char(15),
	@p_status_change_date				datetime,
	@p_new_empl_id					char(10),
	@p_new_tax_entity_id				char(10),
	@p_new_hire_date				datetime,
	@p_new_classn_cd				char(2),
	@p_new_reason_cd				char(5),
	@p_new_assigned_to_code				char(1),
	@p_new_job_or_pos_id				char(10),
	@p_new_pay_group_id				char(10),
	@p_new_time_reporting_meth			char(1),
	@p_job_end_date					datetime,
	@p_position_end_date				datetime,
        @p_taxing_country              			char(2),
        @p_new_pay_elem_ctrl_grp_id			char(10), /* R6.5.03M-ALS#28859 */
        @p_allow_pay_updates_ind			char(1),  /* R6.5.03M-ALS#28859 */
	@p_old_chgstamp					smallint
)

as

/* ==================================================================== */
/* DOS.Name    :  hpnpeu14.sp                                           */
/* ==================================================================== */
/***************************************************************/
/* R6.5.03M-ALS#28859: Begin - moved from below                */
/* AUDIT SECTION ==============================================*/
/* Set up the audit tables                                     */
/* ============================================================*/
declare @W_ACTION_USER		char(30),
        @W_MS             	char(3),
        @W_ACTION_DATETIME	char(30)

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
/***************************************************************/
/* R6.5.03M-ALS#28859: End - moved from below                  */
/***************************************************************/

declare @ret int
     /* @W_ACTION_DATETIME  char(30) *//* R6.5.03M-ALS#28859: moved to above */

--exec @ret = sp_dbs_authenticate
--if @ret != 0 return

declare	@w_end_of_time				datetime,
	@w_status_code				char(1),
	@w_rehire_conson  			char(1),
	@w_last_action_cd 			char(2),
	@w_no_value				char(1),
	@w_pay_element_ctrl_grp_id		char(10),
	@w_error_26249				char(200),
	@w_employment_prior_eff_date 		datetime,
	@w_pay_status_code			char(1),
	@w_source_code				char(1),
	@w_new_chgstamp				smallint,
	@w_error_26267				char(5),
	@w_test_eff_date			datetime,
	@w_empl_curr_code			char(3),
	@w_error                    		int,
	@w_pay_element_prior_eff_date		datetime,  /*R6.1M-SSA#28928*/
	@w_pay_element_id			char(10),  /*R6.1M-SSA#28928*/
	@w_pensioner_indicator			char(1),   /*R6.1M-SSA#29680*/
	@w_same_prev_job_or_pos_id		char(10),  /*@w_previous_job_or_pos_id R6.53M Sol#527321 */
	@w_max_eff_date				datetime,  /*R6.5M Sol#198163 */
	@w_test2_eff_date			datetime,  /* R6.5.03M-ALS#558312 */
	@w_test3_eff_date			datetime   /* R6.5.03M-ALS#558312 */

execute sp_dbs_calc_chgstamp @p_old_chgstamp, @w_new_chgstamp output

select	@w_end_of_time		= "12/31/2999",
	@w_status_code		= "A",
	@w_rehire_conson	= "N",
	@w_last_action_cd 	= "RH",
	@w_no_value		= " ",
	@w_pay_status_code	= "1",
	@w_source_code		= "1",
	@w_error_26267		= "11111",
        @w_error            	= 0

declare @w_st_tax_entity_id        char(10),
        @w_wk_resident_status_code char(1),
        @w_sui_state_ind           char(1),
        @w_time_worked_pct         money,
        @w_sdi_status_code         char(1),
        @w_prior_st_tax_entity_id  char(10),
        @w_st_complete             char(1),
        @w_exit                    char(1),
        @w_total_tm_worked_pct     money,
        @w_nbr_sui_states          int,
        @w_nbr_resident_states     int,
        @w_nbr_sdi_states          int,
        @w_validate_state          char(1),
        @w_validate_terr           char(1),
        @w_rowcount                int

select @w_st_complete         = 'Y',
       @w_time_worked_pct     = 0,
       @w_total_tm_worked_pct = 0,
       @w_nbr_sui_states      = 0,
       @w_nbr_resident_states = 0,
       @w_nbr_sdi_states      = 0,
       @w_validate_state      = 'N',
       @w_validate_terr       = 'N'


/*R6.5M Sol.198163 Begin */
/* Get maximum effective date to determine last job or position */
if exists (select *                                            	/*R653M-sol#527321-added if exists else*/
             from emp_assignment                            	/*R653M-sol#527321-added if exists else*/
            where emp_id = @p_emp_id                       	/*R653M-sol#527321-added if exists else*/
              and job_or_pos_id  = @p_new_job_or_pos_id       	/*R653M-sol#527321-added if exists else*/
	      and next_eff_date  = @w_end_of_time             	/*R653M-sol#527321-added if exists else*/
              and end_date      <> @w_end_of_time)             	/*R653M-sol#527321-added if exists else*/
   begin                                                       	/*R653M-sol#527321-added if exists else*/
           select @w_max_eff_date = max(eff_date)             	/*R653M-sol#527321-added if exists else*/
	     from emp_assignment                            	/*R653M-sol#527321-added if exists else*/
            where emp_id = @p_emp_id                       	/*R653M-sol#527321-added if exists else*/
              and job_or_pos_id  = @p_new_job_or_pos_id       	/*R653M-sol#527321-added if exists else*/
	      and next_eff_date  = @w_end_of_time             	/*R653M-sol#527321-added if exists else*/
              and end_date      <> @w_end_of_time              	/*R653M-sol#527321-added if exists else*/
   end                                                         	/*R653M-sol#527321-added if exists else*/
else                                                           	/*R653M-sol#527321-added if exists else*/
   begin                                                       	/*R653M-sol#527321-added if exists else*/
     select @w_max_eff_date = @w_end_of_time                    /*R653M-sol#527321-added if exists else*/
   end                                                          /*R653M-sol#527321-added if exists else*/

/* Get last job or position id that is the same as the new job or position id */
if exists (select *                                           	/*R653M-sol#527321-added if exists else*/
	     from emp_assignment                              	/*R653M-sol#527321-added if exists else*/
	    where emp_id        = @p_emp_id                    	/*R653M-sol#527321-added if exists else*/
              and job_or_pos_id = @p_new_job_or_pos_id        	/*R653M-sol#527321-added if exists else*/
	      and eff_date      = @w_max_eff_date)             	/*R653M-sol#527321-added if exists else*/
   begin                                                      	/*R653M-sol#527321-added if exists else*/
     select @w_same_prev_job_or_pos_id = job_or_pos_id         	/*R653M-sol#527321-added if exists else*/
       from emp_assignment                              	/*R653M-sol#527321-added if exists else*/
      where emp_id        = @p_emp_id                          	/*R653M-sol#527321-added if exists else*/
        and job_or_pos_id = @p_new_job_or_pos_id        	/*R653M-sol#527321-added if exists else*/
	and eff_date      = @w_max_eff_date                  	/*R653M-sol#527321-added if exists else*/
   end                                                        	/*R653M-sol#527321-added if exists else*/
else                                                          	/*R653M-sol#527321-added if exists else*/
   begin                                                      	/*R653M-sol#527321-added if exists else*/
     select @w_same_prev_job_or_pos_id = NULL                  	/*R653M-sol#527321-added if exists else*/
   end                                                        	/*R653M-sol#527321-added if exists else*/

/*R6.5M Sol.198163 End */
/****************************************************************/
/* If the emp id passed is equal to the previous emp id then    */
/* previous employee identifier will be used.  Otherwise, a new */
/* employee identifier has been assigned.		        */
/****************************************************************/
begin transaction

if @p_emp_id = @p_previous_emp_id
  begin /* A */
    /*R4.1 SSA#15753 begin */
    /**********************************************************
     Check state tax authority for completeness
    **********************************************************/
    /* Sol#525582 beging commented out
    update employee
       set us_tax_auths_compl_ind   = @w_st_complete,
           last_date_for_which_paid = @w_end_of_time,
           chgstamp                 = chgstamp + 1
     where emp_id = @p_emp_id
    Sol#525582 end commented out  */

    update emp_status
       set next_change_date = @p_new_hire_date,
	   chgstamp         = @w_new_chgstamp
     where emp_id             = @p_emp_id
       and status_change_date = @p_status_change_date
       and chgstamp           = @p_old_chgstamp

    if @@rowcount = 0
      begin
        if exists (select *
                     from emp_status
		    where emp_id = @p_emp_id
		      and status_change_date = @p_status_change_date)
          begin
--SYBSQL             raiserror 20001 "Row updated by another user."
          raiserror ('20001 Row updated by another user.',16,0)
            rollback transaction
            return
          end
        else
          begin
--SYBSQL             raiserror 20002 "Row does not exist."
          raiserror ('20002 Row does not exist.',16,0)
            rollback transaction
            return
          end
      end

    /***************************************************************/
    /* Insert the new Employee Status row with the status change   */
    /* date equal to the rehire date.			           */
    /***************************************************************/
    insert into emp_status
      select @p_emp_id,			@p_new_hire_date,
             status_change_date,	@w_end_of_time,
             @w_status_code,		@p_new_classn_cd,
             @w_no_value,		@p_new_hire_date,
             @w_end_of_time,		@w_no_value,
             @p_new_reason_cd,		@w_no_value,
             @w_last_action_cd,		0
        from emp_status
       where emp_id = @p_emp_id
         and status_change_date = @p_status_change_date

    if @@error != 0
      begin
        rollback transaction
        return
      end
  end /* A */

/***************************************************************/
/* A new Employee Identifier has been assigned to the employee.*/
/***************************************************************/
else
  begin /* B */
    insert into employee
      select @p_emp_id,				maintain_own_skills_ind,
             maintain_own_trng_rqst_ind,	maintain_own_payroll_info_ind,
             requires_system_access_ind,	system_user_id,
             electronic_mail_id,		emp_display_name,
             individual_id,			original_hire_date,
             adjusted_service_date,		entp_hire_date,
             @p_previous_emp_id,		'N',
             2999,                    		first_date_worked,
             last_date_for_which_paid,       	canadian_tax_auth_compl_ind,
             user_amt_1,			user_amt_2,
             user_monetary_amt_1,		user_monetary_amt_2,
             user_monetary_curr_code,		user_code_1,
             user_code_2,			user_date_1,
             user_date_2,			user_ind_1,
             user_ind_2,			user_text_1,
             user_text_2,			0
        from employee
       where emp_id = @p_previous_emp_id

    if @@rowcount = 0
      begin
        if exists (select * from employee
                    where emp_id = @p_emp_id)
          begin
--SYBSQL             raiserror 20001 "Row updated by another user."
          raiserror ('20001 Row updated by another user.',16,0)
            rollback transaction
            return
          end
        else
          begin
--SYBSQL             raiserror 20002 "Row does not exist."
          raiserror ('20002 Row does not exist.',16,0)
            rollback transaction
            return
          end
      end

    insert into emp_status
      select @p_emp_id,			@p_new_hire_date,
             @w_end_of_time,		@w_end_of_time,
             @w_status_code,		@p_new_classn_cd,
             @w_no_value,		@p_new_hire_date,
             @w_end_of_time,		@w_rehire_conson,
             @p_new_reason_cd,		@w_no_value,
             @w_last_action_cd,		0

    if @@error != 0
      begin
        rollback transaction
        return
      end
  end /* B */

/****************************************************************/
/* Select Job or Position to Default Information into Employee  */
/* tables.						        */
/****************************************************************/
/* R6.5.03M-ALS#28859-If @p_allow_pay_updates_ind = "Y" then    */
/* use the PECG passed to this procedure otherwise get the PECG */
/* associated with the Job or Position.                         */
/****************************************************************/
if @p_allow_pay_updates_ind = "N"	/* R6.5.03M-ALS#28859 */
  begin					/* R6.5.03M-ALS#28859 */
    if @p_new_assigned_to_code = "J"
      begin
        select @w_pay_element_ctrl_grp_id = pay_element_ctrl_grp_id
          from job
         where job_id         = @p_new_job_or_pos_id
           and eff_date      <= @p_new_hire_date
           and next_eff_date  > @p_new_hire_date
      end
    else
      begin
        select @w_pay_element_ctrl_grp_id = pay_element_ctrl_grp_id
          from position
         where pos_id         = @p_new_job_or_pos_id
           and eff_date      <= @p_new_hire_date
           and next_eff_date  > @p_new_hire_date
      end
  end  								  /* R6.5.03M-ALS#28859 */
else   								  /* R6.5.03M-ALS#28859 */
  select @w_pay_element_ctrl_grp_id = @p_new_pay_elem_ctrl_grp_id /* R6.5.03M-ALS#28859 */

/*********************************************/
/* Select Prior Employee Employment Version  */
/*********************************************/
/*R6.1M-SSA#29680*/
select @w_test_eff_date       = eff_date,
       @w_pensioner_indicator = pensioner_indicator
  from emp_employment
 where emp_id        = @p_previous_emp_id
   and next_eff_date = @w_end_of_time

if @w_test_eff_date >= @p_new_hire_date
  begin
--SYBSQL     raiserror 26249 "Employment information corrupted."
          raiserror ('26249 Employment information corrupted.',16,0)
    rollback transaction
    return
  end
else
  begin
    select @w_employment_prior_eff_date = @w_test_eff_date
  end

/***************************************************************/
/* If the previous employee id was used, update the prior emp  */
/* employment version effective date chain and insert a new    */
/* employee employment row using the previous employee id.     */
/***************************************************************/
if @p_emp_id = @p_previous_emp_id
  begin
    update emp_employment
       set next_eff_date = @p_new_hire_date,
           chgstamp = chgstamp + 1
     where emp_id        = @p_emp_id
       and next_eff_date = @w_end_of_time

    insert into emp_employment
      values(@p_emp_id,				@p_new_hire_date,
             @w_end_of_time,			@w_employment_prior_eff_date,
             @w_no_value,			"F",
             @w_no_value,			@w_end_of_time,
             "N",				"N",
             @w_pensioner_indicator,		@w_no_value,
             @w_no_value,			@w_no_value,
             0,					0,
             @w_no_value,			0,
             @w_no_value,			@w_no_value,
             @w_no_value,			0,
             @w_end_of_time,			@p_new_empl_id,
             @p_new_tax_entity_id,		@w_pay_status_code,
             @w_no_value,			"N",
             @p_new_time_reporting_meth,	"1",
             @w_pay_element_ctrl_grp_id,	@p_new_pay_group_id,
             "N",				@w_no_value,
             "N",				@w_no_value,
             @w_no_value,			@w_no_value,
             @w_no_value,			"N",
             0,					@w_no_value,
             0,					0,
             0,					0,
             @w_no_value,			"Y",
             @w_no_value,			@w_no_value,
             "1",				@w_no_value,
             @w_no_value,			@w_no_value,
             @w_no_value,			@w_no_value,
             @w_no_value,			@w_no_value,
             "N",				"N",
             "1",				0,
             0,					0,
             0,					@w_no_value,
             @w_no_value,			@w_no_value,
             @w_end_of_time,			@w_end_of_time,
             "N",				"N",
             @w_no_value,			@w_no_value,
             @w_no_value,    /* R6.0M - SSA# 23771 */
             0)
  end
/***********************************************************/
/* Insert a New Employee Employment row using the new      */
/* employee identifier.			  		   */
/***********************************************************/
else
  begin
    insert into emp_employment
      values(@p_emp_id,				@p_new_hire_date,
             @w_end_of_time,			@w_end_of_time,
             @w_no_value,			"F",
             @w_no_value,			@w_end_of_time,
             "N",				"N",
             "N",				@w_no_value,
             @w_no_value,			@w_no_value,
             0,					0,
             @w_no_value,			0,
             @w_no_value,			@w_no_value,
             @w_no_value,			0,
             @w_end_of_time,			@p_new_empl_id,
             @p_new_tax_entity_id,		@w_pay_status_code,
             @w_no_value,			"N",
             @p_new_time_reporting_meth,	"1",
             @w_pay_element_ctrl_grp_id,	@p_new_pay_group_id,
             "N",				@w_no_value,
             "N",				@w_no_value,
             @w_no_value,			@w_no_value,
             @w_no_value,			"N",
             0,					@w_no_value,
             0,					0,
             0,					0,
             @w_no_value,			"Y",
             @w_no_value,			@w_no_value,
             "1",				@w_no_value,
             @w_no_value,			@w_no_value,
             @w_no_value,			@w_no_value,
             @w_no_value,			@w_no_value,
             "N",				"N",
             "1",				0,
             0,					0,
             0,					@w_no_value,
             @w_no_value,			@w_no_value,
             @w_end_of_time,			@w_end_of_time,
             "N",				"N",
             @w_no_value,			@w_no_value,
             @w_no_value, /* R6.0M - SSA# 23771 */
             0)
  end

/*******************************/
/* Process Autopay Pay Element */
/*******************************/
if @p_new_pay_group_id <> ""
  begin /* C */
    if @p_new_time_reporting_meth != "3"
      begin /* D */
        if not exists (select *
                         from pay_element pe, pay_group pg
                        where pe.pay_element_id  = pg.regular_earn_pay_element_id
                          and pg.pay_group_id    = @p_new_pay_group_id
                          and pe.eff_date       <= @p_new_hire_date
                          and pe.next_eff_date   > @p_new_hire_date)
            begin
              if not exists (select *
                              from pay_element pe, pay_group pg
                             where pe.pay_element_id = pg.regular_earn_pay_element_id
                               and pg.pay_group_id   = @p_new_pay_group_id
                               and pe.prior_eff_date = @w_end_of_time)
                  begin
--SYBSQL                     raiserror 26266 "Information in the database is corrupt."
          raiserror ('26266 Information in the database is corrupt.',16,0)
                    rollback transaction
                    return
                 end
              else
                begin
                  select @w_error_26267 = regular_earn_pay_element_id
                    from pay_group
                    where pay_group_id = @p_new_pay_group_id
                  goto continue_on
                end
            end
        else
          begin /* E */
            /* R6.1M-SSA#28928 Begin -                                                 */
            /* Need to chain dates of previous regular pay element version to rehired  */
            /* version that uses same regular pay element.                             */

            /* Used to find pay element of pay group used. */
            select @w_pay_element_id = (select regular_earn_pay_element_id
                                          from pay_group
                                          where pay_group_id = @p_new_pay_group_id)

            select @w_pay_element_prior_eff_date = @w_end_of_time

            if @p_emp_id = @p_previous_emp_id
              begin
                select @w_test2_eff_date = eff_date      /* R6.5.03M-ALS#558312: chgd test to test2 */
                  from emp_pay_element
                  where emp_id       = @p_previous_emp_id
                  and next_eff_date  = @w_end_of_time
                  and pay_element_id = @w_pay_element_id

                if @w_test2_eff_date >= @p_new_hire_date /* R6.5.03M-ALS#558312: chgd test to test2 */
                  begin
--SYBSQL                     raiserror 26266 "Information in the database is corrupt."
          raiserror ('26266 Information in the database is corrupt.',16,0)
                    rollback transaction
                    return
                  end
                else
                  begin
                    if @w_test2_eff_date is not null     /* R6.5.03M-ALS#558312: chgd test to test2 */
                      begin
                        select @w_pay_element_prior_eff_date = @w_test2_eff_date /* R6.5.03M-ALS#558312: chgd test to test2 */
                      end
                  end

                update emp_pay_element
                  set next_eff_date      = @p_new_hire_date
                      where emp_id       = @p_emp_id
                      and next_eff_date  = @w_end_of_time
                      and pay_element_id = @w_pay_element_id
              end
              /* R6.1M-SSA#28928 End */

            insert into emp_pay_element
              select DISTINCT  @p_emp_id,                      @p_new_empl_id,
                               pe.pay_element_id,              @p_new_hire_date,
                               @w_pay_element_prior_eff_date,  @w_end_of_time,
                               "N",                            @p_new_hire_date,
                               pe.stop_date,                   @w_no_value,
                               "00",                           pe.calc_meth_code,
                               pe.standard_calc_factor_1,      pe.standard_calc_factor_2,
                               pe.special_calc_factor_1,       pe.special_calc_factor_2,
                               pe.special_calc_factor_3,       pe.special_calc_factor_4,
                               @w_no_value,                    @w_no_value,
                               @w_no_value,                    @w_no_value,
                               @w_no_value,                    @w_no_value,
                               @w_no_value,                    @w_no_value,
                               @w_no_value,                    0,
                               0,                              @w_no_value,
                               @w_no_value,                    @w_no_value,
                               @w_no_value,                    @w_no_value,
                               0,                              0,
                               0,                              0,
                               0,                              0,
                               0,                              @w_no_value,
                               @w_no_value,                    @w_no_value,
                               @w_end_of_time,                 @w_end_of_time,
                               "N",                            "N",
                               @w_no_value,                    @w_no_value,
                               "N",                            @w_no_value,
                               @w_no_value,                    @w_no_value,
                               0,                              @w_end_of_time,  /* r71m-578919 in 576240 */
                               "N",                            "N"              /* r71m-581591 in 582025 */
                from pay_element pe, pay_group pg
               where pe.pay_element_id  = pg.regular_earn_pay_element_id
                 and pg.pay_group_id    = @p_new_pay_group_id
                 and pe.eff_date       <= @p_new_hire_date
                 and pe.next_eff_date   > @p_new_hire_date

            /* R6.5.03M-ALS#28859: Begin */
            /* AUDIT SECTION ==========================================*/
            /* Set up the work employee pay element audit table        */
            /* ========================================================*/
            insert into work_emp_pay_element_aud
                    (user_id, activity_action_code, action_date, emp_id, empl_id,
                     pay_element_id, eff_date, prior_eff_date, next_eff_date,
                     new_eff_date, new_start_date, new_stop_date)
            values
                    (@W_ACTION_USER, 'REHIRE', @W_ACTION_DATETIME,
                     @p_emp_id, @p_new_empl_id, @w_pay_element_id,
                     @p_new_hire_date, '', '', '', '', '')

            Delete work_emp_pay_element_aud
             Where user_id = @W_ACTION_USER
               and action_date = @W_ACTION_DATETIME
               and activity_action_code = 'REHIRE'
               and emp_id               = @p_emp_id
               and empl_id              = @p_new_empl_id
               and pay_element_id       = @w_pay_element_id
               and eff_date             = @p_new_hire_date

            /* END AUDIT SECTION ==========================================*/
            /* Set up the work employee pay element audit table            */
            /* ============================================================*/
            /* R6.5.03M-ALS#28859: End */
          end /* E */
      end /* D */
  end /* C */

/**********************************************************/
/* Insert a new Employee Assignment row, based on Job or  */
/* position assigned to.				  */
/**********************************************************/
continue_on:
SELECT @w_empl_curr_code = employer.curr_code
  FROM employer
 WHERE employer.empl_id = @p_new_empl_id

/**** SSA#28384 START ****/
/***********************************************************************************/
/* If the previous employee id was used, select Prior Employee Assignment Version  */
/***********************************************************************************/
select @w_employment_prior_eff_date = @w_end_of_time

if @p_emp_id = @p_previous_emp_id
  begin /* F */
    select @w_test3_eff_date = eff_date            /* R6.5.03M-ALS#558312: chgd test to test3 */
      from emp_assignment
     where emp_id           = @p_previous_emp_id
       and next_eff_date    = @w_end_of_time
       and assigned_to_code = @p_new_assigned_to_code
       and job_or_pos_id    = @p_new_job_or_pos_id

    if @w_test3_eff_date >= @p_new_hire_date	   /* R6.5.03M-ALS#558312: chgd test to test3 */
      begin
--SYBSQL         raiserror 26249 "Employee assignment date information corrupted."
          raiserror ('26249 Employee assignment date information corrupted.',16,0)
        rollback transaction
        return
      end
    else
      begin
        if @w_test3_eff_date is not null           /* R6.5.03M-ALS#558312: chgd test to test3 */
          begin
            select @w_employment_prior_eff_date = @w_test3_eff_date  /* R6.5.03M-ALS#558312: chgd test to test3 */
          end
      end

    /***************************************************************/
    /* If the previous employee id was used, update the prior emp  */
    /* assignment version effective date chain and insert a new    */
    /* employee assignment row using the previous employee id.     */
    /***************************************************************/
    update emp_assignment
       set next_eff_date = @p_new_hire_date,
           chgstamp      = chgstamp + 1
     where emp_id           = @p_emp_id
       and next_eff_date    = @w_end_of_time
       and assigned_to_code = @p_new_assigned_to_code
       and job_or_pos_id    = @p_new_job_or_pos_id
  end /* F */
/**** SSA#28384 END ****/

/*R6.5M Sol.198163 Begin*/
/* If the id is the same, but the job or position is different 	*/
/* then the prior eff date should be EOT			*/
if @p_emp_id = @p_previous_emp_id
  if @w_same_prev_job_or_pos_id <> @p_new_job_or_pos_id	/*@w_previous_job_or_pos_id R6.53M Sol#527321*/
    Select @w_employment_prior_eff_date = @w_end_of_time
/*R6.5M Sol.198163 End*/

if @p_new_assigned_to_code = "J"
  begin /* G */
    insert into emp_assignment
      select @p_emp_id,					@p_new_assigned_to_code,
             @p_new_job_or_pos_id,			@p_new_hire_date,
             @w_end_of_time,				@w_employment_prior_eff_date, /* @w_end_of_time -changed SSA#28384 */
             @w_no_value,				@w_no_value,
             @w_no_value,				@w_no_value,
             @p_new_hire_date,				@p_job_end_date,
             @w_no_value,				" ",
             " ",					0,
             @w_no_value,
             @w_no_value,				@w_no_value,
             @w_no_value,				@w_end_of_time,
             @w_end_of_time,				0,
             0,						@w_no_value,
             0,						@w_empl_curr_code,
             "N",					@w_no_value,
             @w_no_value,				0,
             job.pos_full_tm_ind,			@w_no_value,
             job.salary_structure_id,   		job.salary_increase_guideline_id,
             job.pay_grade_code,			@w_end_of_time,
             job.evaluation_points_nbr, 		0,
             @w_end_of_time,				@w_no_value,
             @w_no_value,	        		@w_no_value,
             @w_no_value,				@w_no_value,
             @w_no_value,				@w_no_value,
             @w_no_value,				@w_no_value,
             @w_no_value,				@w_no_value,
             @w_no_value,				@w_no_value,
             @w_no_value,				@w_no_value,
             @w_no_value,				"Y",
             "9",					"3",
             @w_no_value,				@w_no_value,
             @w_no_value,				@w_no_value,
             0,						0,
             @w_no_value,				0,
             0,						0,
             @w_no_value,				0,
             "N",					job.overtime_status_code,
             job.shift_differential_status_code, 	job.standard_daily_work_hrs,
             0,						0,
             @w_no_value,				@w_no_value,
             @w_end_of_time,				@w_end_of_time,
             "N",					"N",
             0,						0,
             @w_empl_curr_code,				@w_no_value,
             @w_no_value,  				@w_no_value,
             'N',					0
        from job
       where @p_new_job_or_pos_id  = job.job_id
         and job.eff_date         <= @p_new_hire_date
         and job.next_eff_date     > @p_new_hire_date
  end /* G */
else
  begin /* H */
    insert into emp_assignment
      select @p_emp_id,					@p_new_assigned_to_code,
             @p_new_job_or_pos_id,			@p_new_hire_date,
             @w_end_of_time,				@w_employment_prior_eff_date, /* @w_end_of_time -changed SSA#28384 */
             @w_no_value,				@w_no_value,
             @w_no_value,				@w_no_value,
             @p_new_hire_date,				@p_position_end_date,
             @w_no_value,				position.organization_chart_name,
             position.organization_unit_name,  		position.organization_group_id,
             @w_no_value,
             position.loc_code,				@w_no_value,
             @w_no_value,				@w_end_of_time,
             @w_end_of_time,				0,
             0,						@w_no_value,
             0,						@w_empl_curr_code,
             "N",					@w_no_value,
             position.standard_work_pd_id,		position.standard_work_hrs,
             position.full_tm_ind,			position.work_shift_code,
             position.salary_structure_id,	 	position.salary_increase_guideline_id,
             position.pay_grade_code,	 		@w_end_of_time,
             position.evaluation_points_nbr,	 	0,
             @w_end_of_time,				@w_no_value,
             @w_no_value,				@w_no_value,
             @w_no_value,				@w_no_value,
             @w_no_value,				@w_no_value,
             @w_no_value,				@w_no_value,
             @w_no_value,				@w_no_value,
             @w_no_value,				@w_no_value,
             @w_no_value,				@w_no_value,
             @w_no_value,				"Y",
             "9",					"3",
             @w_no_value,				@w_no_value,
             @w_no_value,				@w_no_value,
             0,						0,
             @w_no_value,				0,
             0,						0,
             @w_no_value,				0,
             "N",					position.overtime_status_code,
             position.shift_differential_status_code,  	position.standard_daily_work_hrs,
             0,						0,
             @w_no_value,				@w_no_value,
             @w_end_of_time,				@w_end_of_time,
             "N",					"N",
             0,						0,
             @w_empl_curr_code,				@w_no_value,
             @w_no_value, 				@w_no_value,
             'N',					0
        from position
       where @p_new_job_or_pos_id    = position.pos_id
         and position.eff_date      <= @p_new_hire_date
         and position.next_eff_date  > @p_new_hire_date
  end /* H */

/*****************************************/
/* Validate Tax Authorities              */
/*****************************************/
if @p_taxing_country = "US"
  Begin /* I */
    declare emp_tax_entity_crsr cursor
        for Select Distinct tax_entity_id
              From emp_us_tax_authority
             Where emp_id                         = @p_emp_id
               and emp_us_tax_authority_status_cd = '1'
               and tax_authority_id               = 'USFED'
               and tax_entity_id = @p_new_tax_entity_id   -- KB 1601481

    open emp_tax_entity_crsr

    Fetch emp_tax_entity_crsr
     Into @w_st_tax_entity_id

    if @@fetch_status <> 0
      Select @w_st_complete = 'N',
             @w_error       = 300
    else
      while @@fetch_status = 0 and @w_error = 0
        Begin /* J */
          if Exists(Select *
                      from emp_us_tax_authority eusta, us_tax_authority usta
                     where eusta.emp_id = @p_emp_id
                       and eusta.tax_entity_id = @p_new_tax_entity_id   -- KB 1601481
                       and eusta.emp_us_tax_authority_status_cd = '1'
                       and usta.tax_authority_id = eusta.tax_authority_id
                       and usta.tax_authority_type_code = "4")
            if Exists(Select *
                        from emp_us_tax_authority eusta, us_tax_authority usta
                       where eusta.emp_id = @p_emp_id
                         and eusta.tax_entity_id = @p_new_tax_entity_id   -- KB 1601481
                         and eusta.emp_us_tax_authority_status_cd = '1'
                         and usta.tax_authority_id = eusta.tax_authority_id
                         and usta.tax_authority_type_code = "2")
              Begin
                Select @w_st_complete = 'N',
                       @w_error       = 200
              End
            else
              Select @w_validate_terr = 'Y'
          else
            Select @w_validate_state = 'Y'

          if @w_validate_terr = 'Y'              /** Validate territory cursor **/
            Begin /* K */
              Select @w_validate_terr       = 'N',
                     @w_total_tm_worked_pct = 0,
                     @w_nbr_sui_states      = 0,
                     @w_nbr_sdi_states      = 0

              Declare emp_terr_tax_auth_crsr cursor
                  for select a.sui_st_ind,
                             a.tm_worked_pct,
                             a.sdi_status_code
                        from emp_us_tax_authority a, us_tax_authority b
                       where a.emp_id                         = @p_emp_id
                         and a.tax_entity_id                  = @p_new_tax_entity_id   -- KB 1601481
                         and a.emp_us_tax_authority_status_cd = '1'
                         and a.tax_authority_id               = b.tax_authority_id
                         and b.tax_authority_type_code        = '4'
                    order by a.tax_entity_id

              open emp_terr_tax_auth_crsr

              fetch emp_terr_tax_auth_crsr
               into @w_sui_state_ind,
                    @w_time_worked_pct,
                    @w_sdi_status_code

              if @@fetch_status = 0
                while @@fetch_status = 0
                  begin
                    select @w_total_tm_worked_pct = @w_total_tm_worked_pct + @w_time_worked_pct

                    if @w_sui_state_ind = 'Y'
                      select @w_nbr_sui_states = @w_nbr_sui_states + 1

                    if @w_sdi_status_code = '2'
                      select @w_nbr_sdi_states = @w_nbr_sdi_states + 1

                    /** Load next row **/
                    fetch emp_terr_tax_auth_crsr
                     into @w_sui_state_ind,
                          @w_time_worked_pct,
                          @w_sdi_status_code
                  end

              close emp_terr_tax_auth_crsr
              deallocate emp_terr_tax_auth_crsr

              if @w_total_tm_worked_pct <> 100 or
                 @w_nbr_sui_states      <> 1   or
                 @w_nbr_sdi_states       > 1
                Select @w_st_complete = 'N',
                       @w_error       = 400
            End /* K */

          if @w_validate_state = 'Y'              /** Validate State Cursor **/
            Begin /* L */
              Select @w_validate_state      = 'N',
                     @w_total_tm_worked_pct = 0,
                     @w_nbr_sui_states      = 0,
                     @w_nbr_resident_states = 0,
                     @w_nbr_sdi_states      = 0

              declare emp_st_tax_authority_crsr cursor
                  for select a.work_resident_status_code,
                             a.sui_st_ind,
                             a.tm_worked_pct,
                             a.sdi_status_code
                        from emp_us_tax_authority a, us_tax_authority b
                       where a.emp_id                         = @p_emp_id
                         and a.tax_entity_id                  = @p_new_tax_entity_id   -- KB 1601481
                         and a.emp_us_tax_authority_status_cd = '1'
                         and a.tax_authority_id               = b.tax_authority_id
                         and b.tax_authority_type_code        = '2'
                    order by a.tax_entity_id

              open emp_st_tax_authority_crsr

              fetch emp_st_tax_authority_crsr
               into @w_wk_resident_status_code,
                    @w_sui_state_ind,
                    @w_time_worked_pct,
                    @w_sdi_status_code

              if @@fetch_status = 0
                while @@fetch_status = 0
                  begin
                    select @w_total_tm_worked_pct = @w_total_tm_worked_pct + @w_time_worked_pct

                    if @w_sui_state_ind = 'Y'
                      select @w_nbr_sui_states = @w_nbr_sui_states + 1

                    if (@w_wk_resident_status_code = '1' or
                        @w_wk_resident_status_code = '3'   )
                      select @w_nbr_resident_states = @w_nbr_resident_states + 1

                    if (@w_sdi_status_code = '2' or
                        @w_sdi_status_code = '3'   )
                      select @w_nbr_sdi_states = @w_nbr_sdi_states + 1

                    /** Load next row **/
                    fetch emp_st_tax_authority_crsr
                     into @w_wk_resident_status_code,
                          @w_sui_state_ind,
                          @w_time_worked_pct,
                          @w_sdi_status_code
                  end

              close emp_st_tax_authority_crsr
              deallocate emp_st_tax_authority_crsr

              if @w_total_tm_worked_pct <> 100 or
                 @w_nbr_sui_states      <> 1   or
                 @w_nbr_resident_states <> 1   or
                 @w_nbr_sdi_states       > 1
               Select @w_st_complete = 'N',
                      @w_error       = 300

              Fetch emp_tax_entity_crsr
               Into @w_st_tax_entity_id
            End /* L */
        End /* J */

    close emp_tax_entity_crsr
    deallocate emp_tax_entity_crsr

/** check for complete status at end for result set **/
update_usta_complete:
    update employee
       set us_tax_auths_compl_ind   = @w_st_complete,
           last_date_for_which_paid = @w_end_of_time,        /*Sol#525582 added line*/
           chgstamp                 = chgstamp + 1
     where emp_id = @p_emp_id
  end /* I */

/***************************************************
 validate canadian tax authorities
***************************************************/
if @p_taxing_country = "CA"
  Begin
    /* R6.0M - SSA# 28858 - Modified next several lines to use if exists */
    /* instead of select and check @@rowcount                            */
    if Exists(Select ecta.emp_id
               From emp_can_tax_authority ecta, canadian_tax_authority cta
              Where ecta.emp_id                     = @p_emp_id
                and ecta.empl_id                    = @p_new_empl_id
                and ecta.emp_can_tax_auth_status_cd = '1'
                and ecta.primary_province_ind       = 'Y'
                and cta.tax_authority_id            = ecta.tax_authority_id
                and cta.tax_authority_type_code     = '2')

/*    Select @w_rowcount = @@rowcount
      if @w_rowcount = 1                  */
/*R6.0M - SSA# 28858 - End change */

      Select @w_st_complete = 'Y'
    else
      Begin
        Select @w_st_complete = 'N'
        Select @w_error       = 500
      End

    Update employee
       Set canadian_tax_auth_compl_ind = @w_st_complete,
           last_date_for_which_paid    = @w_end_of_time,        /*Sol#525582 added line*/
           chgstamp                    = chgstamp + 1
     where emp_id = @p_emp_id
  End

/*Sol#525582 begin*/
if @p_taxing_country <> "US" and @p_taxing_country <> "CA"
  BEGIN
    Update employee
       Set last_date_for_which_paid = @w_end_of_time,
           chgstamp                 = chgstamp + 1
     where emp_id = @p_emp_id
  END
/*Sol#525582 end*/
/****************End Validate Canadian tax authorities******************/

/***************************************************************/
/* R6.5.03M-ALS#28859: Begin - moved to above                  */
/* AUDIT SECTION ==============================================*/
/* Set up the work employee status audit table                 */
/* ============================================================*/
/* moved to above
declare @W_ACTION_USER      char(30)
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
****************************************************************
   R6.5.03M-ALS#28859: End - moved to above
****************************************************************/

insert into work_emp_status_aud
  (user_id, activity_action_code, action_date, emp_id, status_change_date,
   prior_change_date, prior_emp_id)
values
  (@W_ACTION_USER, 'REHIRE', @W_ACTION_DATETIME,
   @p_emp_id, @p_new_hire_date, '', @p_previous_emp_id)

Delete work_emp_status_aud
 Where user_id              = @W_ACTION_USER
   and activity_action_code = 'REHIRE'
   and emp_id               = @p_emp_id
   and status_change_date   = @p_new_hire_date

insert into work_emp_assignment_aud
  (user_id, activity_action_code, action_date, emp_id, assigned_to_code,
   job_or_pos_id, eff_date, next_eff_date, prior_eff_date, new_eff_date,
   new_begin_date, new_end_date, new_assigned_to_code, new_job_or_pos_id,
   new_assigned_to_begin_date)
values
  (@W_ACTION_USER, 'REHIRE', @W_ACTION_DATETIME,
   @p_emp_id, @p_new_assigned_to_code, @p_new_job_or_pos_id,
   @p_new_hire_date, '', '', '', '', '', '', '', '')

Delete work_emp_assignment_aud
 Where user_id              = @W_ACTION_USER
   and activity_action_code = 'REHIRE'
   and emp_id               = @p_emp_id
   and assigned_to_code     = @p_new_assigned_to_code
   and job_or_pos_id        = @p_new_job_or_pos_id
   and eff_date             = @p_new_hire_date

IF @p_emp_id = @p_previous_emp_id
  begin
    insert into work_emp_employment_aud
      (user_id, activity_action_code, action_date, emp_id, eff_date, next_eff_date,
       prior_eff_date, new_eff_date, new_empl_id, new_tax_entity_id,
       xfer_date, pay_through_date)
    values
      (@W_ACTION_USER, 'REHIREEQ', @W_ACTION_DATETIME,
       @p_emp_id, @p_new_hire_date, '', '', '', '', '','', '')
  end
ELSE
  begin
    insert into work_emp_employment_aud
      (user_id, activity_action_code, action_date, emp_id, eff_date,
       next_eff_date, prior_eff_date, new_eff_date, new_empl_id,
       new_tax_entity_id, xfer_date, pay_through_date)
    values
      (@W_ACTION_USER, 'REHIRENE', @W_ACTION_DATETIME,
       @p_emp_id, @p_new_hire_date, '', '', '', '', '','','')
  end

Delete work_emp_employment_aud
 Where user_id = @W_ACTION_USER
  and (activity_action_code = 'REHIRENE'   or
       activity_action_code = 'REHIREEQ')
  and (emp_id  = @p_emp_id                 or
       emp_id  = @p_previous_emp_id)
  and eff_date = @p_new_hire_date
/* END AUDIT SECTION ========================================*/
/* Set up the work employee status audit table               */
/* ============================================================*/

commit transaction
--select @w_error_26267,
--       @w_st_complete,
--      @w_error




GO
ALTER AUTHORIZATION ON dbo.usp_upd_hmpl_rehire TO  SCHEMA OWNER
GO

IF OBJECT_ID(N'dbo.usp_upd_hmpl_rehire', N'P') IS NOT NULL
    PRINT N'<<< CREATED PROCEDURE dbo.usp_upd_hmpl_rehire >>>'
ELSE
    PRINT N'<<< FAILED CREATING PROCEDURE dbo.usp_upd_hmpl_rehire >>>'
GO
