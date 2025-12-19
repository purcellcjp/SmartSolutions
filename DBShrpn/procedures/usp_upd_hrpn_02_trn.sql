USE DBShrpn
go
IF OBJECT_ID(N'dbo.usp_upd_hrpn_02_trn') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_upd_hrpn_02_trn
    IF OBJECT_ID(N'dbo.usp_upd_hrpn_02_trn') IS NOT NULL
        PRINT N'<<< FAILED DROPPING PROCEDURE dbo.usp_upd_hrpn_02_trn >>>'
    ELSE
        PRINT N'<<< DROPPED PROCEDURE dbo.usp_upd_hrpn_02_trn >>>'
END
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

/*************************************************************************************

   SP Name:      usp_upd_hrpn_02_trn

   Description:  Transfers employee from one tax employer to another.

                 (THIS SP PERFORMS ALL PROCESSING NECESSARY TO TABLES WITHIN 'HRPN')

                 Cloned from SmartStream procedure DBShrpn..hsp_upd_hrpn_02
                 in order to use with HCM Interface.

   Parameters:


   Tables

   Example:
      exec usp_upd_hrpn_02_trn ....

   Revision history:
      version  date        developer   SCR      description
      -------  ----------  ---------   -----    ------------------------------------
      1.0.00                                    - Cloned from SmartStream version DBShrpn..hsp_upd_hrpn_02
                                                    1) Disabled authentication

************************************************************************************/

CREATE PROCEDURE [dbo].[usp_upd_hrpn_02_trn]
	(@p_emp_id                       char(15),
	@p_empl_id                       char(10),
	@p_new_empl_id                   char(10),
	@p_transfer_date                 datetime,
	@p_assign_to                     char(1),
	@p_job_or_pos_id                 char(10),
	@p_org_grp_id                    int,
	@p_org_chart_name                varchar(64),
	@p_org_unit_name                 varchar(245),
	@p_location                      char(10),
	@p_new_tax_entity_id             char(10),
	@p_old_tax_entity_id             char(10),
	@p_eff_date                      datetime,
	@p_pay_group                     char(10),
	@p_emp_info_change_reason        char(5),
	@p_job_position_end_date         datetime,
	@p_assignment_end_date           datetime,
	@p_xfer_different_taxing_cntry   char(1),
	@p_new_empl_taxing_country_cd	 char(2),
	@p_new_empl_curr_code		     char(3),
	@p_use_policy_xfer_options       char(1) )   /* R6.1M-SSA#131067 */

AS
    declare @w_ret   int,
	@W_ACTION_DATETIME      char(30)

    --execute @w_ret = sp_dbs_authenticate

  -- if @w_ret != 0
   --   return

/*   TRANSFER AN EMPLOYEE FROM ONE EMPLOYER TO ANOTHER
   (THIS SP PERFORMS ALL PROCESSING NECESSARY TO TABLES WITHIN 'HRPN') */
declare @w_empl_transfer_w_no_salary    char(1),
	@w_emp_id                       char(15),
	@w_empl_id                      char(10),
	@w_eff_date                     datetime,
	@w_next_eff_date                datetime,
	@w_pay_element_id               char(10),
	@w_start_date                   datetime,
	@w_prev_pay_element_id		  char(10),
	@w_prev_start_date              datetime,
	@w_empl_xfer_opt_code           char(2),
	@w_assigned_to_code             char(1),
	@w_job_or_pos_id                char(10),
	@w_prev_assign_eff_date         datetime,
	@w_base_rate_tbl_id             char(10),
	@w_base_rate_tbl_entry_code     char(8),
	@w_asgmt_curr_code		char(3),
	@w_rate_tbl_id                  char(10),
	@w_rate_tbl_eff_date            datetime,
	@w_rate_tbl_amt_type_code       char(1),
	@w_job_eff_date                 datetime,
	@w_per_sal_ann_factor           float,
	@w_standard_work_pd_id          char(5),
	@w_standard_work_hrs            float,
	@w_std_work_ann_factor          float,
	@w_pay_grade                    char(6),
	@w_evaluation_pts               int,
	@w_annual_salary_amt            money,
	@w_hourly_pay_rate              float,
	@w_pd_salary_amt                money,
	@w_tax_authority_id             char(10),
	@w_tax_entity_id                char(10),
	@w_tax_entity_id_prev           char(10),
	@w_pct_of_time_worked           money,
	@w_work_resident_status_code    char(1),
	@w_sui_st_ind                   char(1),
	@w_sdi_status_code              char(1),
	@w_us_authorities_complete      char(1),
	@w_emp_can_tax_auth_complete    char(1),
	@w_total_pct_of_time_worked     money,
	@w_no_of_sui_states             smallint,
	@w_no_of_resident_states        smallint,
	@w_no_of_sdi_states             smallint,
	@w_no_of_sui_territories	smallint,
	@w_no_of_sdi_territories	smallint,
	@w_return_to_prior_empl         char(1),
	@w_return_to_prior_tax_entity   char(1),
	@job_base_rate_tbl_id           char(10),
	@job_base_rate_tbl_entry_code   char(8),
	@job_end_date                   datetime,
	@job_work_time                  char(1),
	@job_sal_struct_id              char(10),
	@job_sal_inc_guid_tbl_id        char(10),
	@job_overtime_stat_code         char(2),
	@job_shift_diff_stat_code       char(2),
	@job_std_wk_hrs_per_day         money,
	@job_pay_grade                  char(6),
	@job_entry_step                 smallint,
	@job_evaluation_pts             int,
	@pos_base_rate_tbl_id           char(10),
	@pos_base_rate_tbl_entry_code   char(8),
	@pos_end_date                   datetime,
	@pos_work_time                  char(1),
	@pos_sal_struct_id              char(10),
	@pos_sal_inc_guid_tbl_id        char(10),
	@pos_overtime_stat_code         char(2),
	@pos_shift_diff_stat_code       char(2),
	@pos_std_wk_hrs_per_day         money,
	@pos_organization_group_id      int,
	@pos_organization_chart_name    varchar(64),
	@pos_organization_unit_name     varchar(245),
	@pos_work_shift_code            char(5),
	@pos_standard_work_hrs          float,
	@pos_standard_work_pd_id        char(5),
	@pos_loc_code                   char(10),
	@pos_pay_grade_code             char(6),
	@pos_entry_salary_step_nbr      smallint,
	@pos_evaluation_points_nbr      int,
	@j_rate_tbl_id                  char(10),
	@j_rate_tbl_amt_type_code       char(1),
	@j_rate_tbl_eff_date            datetime,
	@j_rate_tbl_tm_pd_id            char(5),
	@p_rate_tbl_id                  char(10),
	@p_rate_tbl_amt_type_code       char(1),
	@p_rate_tbl_eff_date            datetime,
	@p_rate_tbl_tm_pd_id            char(5),
	@rate_tbl_entry_rate_amt        money,
	@w_EOT                          datetime,
	@w_temp1                        char(1),
	@w_temp12                       char(1),
	@w_temp13                       char(1),
	@w_dummy                        char(1),
	@w_ben_plan_id                  char(15),
	@w_ben_plan_opt_id              char(8),
	@w_participant_id               char(15),
	@w_stop_date                    datetime,
	@w_tax_auth_complete_ret_cd     char(3),
	@w_pay_element_ctrl_grp_id	    char(10),
	@w_end_active_assignment        char(1),           /* R6.1M-SSA#131194 */
    @w_emp_status_code              char(1),           /* R6.1M-SSA#131194 */
    @w_emp_assign_end_date          datetime,          /* R6.1M-SSA#131194 */
    @w_reg_rpt_unit_loc_code        char(10)           /* R653m SSAa#465447 */

select @w_EOT = '12/31/2999',
       @w_end_active_assignment = 'Y'                  /* R6.1M-SSA#131194 */


/*------ AUDIT SECTION ------*/

declare @W_MS	char(3), @W_ACTION_USER	char(30)

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

select @W_ACTION_DATETIME = convert(char(10), getdate(), 111) + '-' +convert(char(8), getdate(), 108) + ':' + @W_MS

/*-------------------*/

select @w_total_pct_of_time_worked	= 0, @w_no_of_sui_states        = 0,
	   @w_no_of_resident_states     = 0, @w_no_of_sdi_states        = 0,
       @w_per_sal_ann_factor        = 0, @w_standard_work_hrs       = 0,
       @w_std_work_ann_factor       = 0, @w_evaluation_pts          = 0,
       @w_annual_salary_amt         = 0, @w_hourly_pay_rate         = 0,
       @w_pd_salary_amt             = 0, @w_pct_of_time_worked      = 0,
       @w_total_pct_of_time_worked  = 0, @w_no_of_sui_states        = 0,
       @w_no_of_resident_states     = 0, @w_no_of_sdi_states        = 0,
       @w_no_of_sui_territories	    = 0, @w_no_of_sdi_territories   = 0,
       @job_std_wk_hrs_per_day      = 0, @job_entry_step            = 0,
       @job_evaluation_pts          = 0, @pos_std_wk_hrs_per_day    = 0,
       @pos_organization_group_id   = 0, @pos_standard_work_hrs     = 0,
       @pos_entry_salary_step_nbr   = 0, @pos_evaluation_points_nbr = 0,
       @rate_tbl_entry_rate_amt     = 0

DELETE FROM #temp11

/***************************************************************/
/***  ssa#23033, 23012 All pay element processing is split   ***/
/***  out into new procedure usp_upd_hrpn_02_trna                ***/
/***                                                         ***/
/***  All of the original parms passed to this proc are      ***/
/***  passed to the new one with the addition of the         ***/
/***  action date time used for audit purposes.              ***/
/***************************************************************/
declare @w_emp_pay_elem_ret_cd int
exec @w_emp_pay_elem_ret_cd = hsp_upd_hrpn_02a_trn
                                             @p_emp_id,
                                             @p_empl_id,
                                             @p_new_empl_id,
                                             @p_transfer_date,
                                             @p_assign_to,
                                             @p_job_or_pos_id,
                                             @p_org_grp_id,
                                             @p_org_chart_name,
                                             @p_org_unit_name,
                                             @p_location,
                                             @p_new_tax_entity_id,
                                             @p_old_tax_entity_id,
                                             @p_eff_date,
                                             @p_pay_group,
                                             @p_emp_info_change_reason,
                                             @p_job_position_end_date,
                                             @p_assignment_end_date,
                                             @p_xfer_different_taxing_cntry,
                                             @p_new_empl_taxing_country_cd,
                                             @p_new_empl_curr_code,
                                             @W_ACTION_DATETIME,
                                             @p_use_policy_xfer_options  /* R6.1M-SSA#131067 */

if  @w_emp_pay_elem_ret_cd <> 0
  begin
--SYBSQL     raiserror 30001 'Error occurred when trying to transfer employee pay elements'
          raiserror ('30001 Error occurred when trying to transfer employee pay elements',16,0)
    return
  end
/***************************************************************/
/***  ssa#23033, 23012 from this point, the original         ***/
/***  procedure processing picks up                          ***/
/***************************************************************/

/*   END EMPLOYEE'S ACTIVE ASSIGNMENTS */
declare  @audit_eff_date     datetime,
	     @audit_next_eff_date        datetime,
	     @audit_prior_eff_date   datetime,
	     @audit_new_end_date    datetime

Select @audit_new_end_date = dateadd(day,-1,@p_transfer_date)

/* R6.1M-SSA#131194 - begin add */
SELECT @w_emp_status_code = emp_status_code
  FROM emp_status
 WHERE emp_id = @p_emp_id
   AND next_change_date = @w_EOT
/* R6.1M-SSA#131194 - end add */

/* R6.1M-SSA#131194 added end_date to cursor3 select below */
	DECLARE cursor3 cursor for
	SELECT  DISTINCT assigned_to_code, end_date, job_or_pos_id,
	                 eff_date, next_eff_date, prior_eff_date
	FROM    emp_assignment
	WHERE   emp_id		= @p_emp_id
	AND     eff_date	< @p_transfer_date
	AND     ((next_eff_date	>= @p_transfer_date AND
			next_eff_date	!= @w_EOT)
	OR     (next_eff_date	 = @w_EOT AND
			end_date		>= @p_transfer_date))

	OPEN cursor3

/* R6.1M-SSA#131194 added @w_emp_assign_end_date to fetch below */
	FETCH cursor3
		INTO  @w_assigned_to_code, @w_emp_assign_end_date, @w_job_or_pos_id,
		      @audit_eff_date, @audit_next_eff_date, @audit_prior_eff_date

/* R6.1M-SSA#131194 begin add */
    if (@@fetch_status <> 0) or
       (@w_emp_assign_end_date = @p_transfer_date and
        @w_emp_status_code = 'T')
          select @w_end_active_assignment = 'N'
/* R6.1M-SSA#131194 end add */

WHILE @@fetch_status = 0

BEGIN       /*****  begin while loop for cursor3  ******/
/* ===AUDIT SECTION ===*/
	INSERT into work_emp_assignment_aud
		(user_id, activity_action_code, action_date, emp_id, assigned_to_code,job_or_pos_id,
	 eff_date, next_eff_date, prior_eff_date, new_eff_date,new_begin_date, new_end_date,
	 new_assigned_to_code, new_job_or_pos_id,new_assigned_to_begin_date)
	VALUES
	(@W_ACTION_USER, 'ERXFERAGEN', @W_ACTION_DATETIME,@p_emp_id, @w_assigned_to_code,@w_job_or_pos_id,
	@audit_eff_date, @audit_next_eff_date,@audit_prior_eff_date, '', '', @audit_new_end_date, '', '', '')

	DELETE work_emp_assignment_aud
	WHERE user_id = @W_ACTION_USER
	AND	activity_action_code ='ERXFERAGEN'
	AND	emp_id = @p_emp_id

/* NOTE: See Employee Assignment for trigger */

/*   END ACTIVE ASSIGNMENT VERSION */
	UPDATE  emp_assignment
	SET     end_date                = dateadd(day,-1,@p_transfer_date),
		next_eff_date           = @w_EOT,
		next_assigned_to_code   = '',
		next_job_or_pos_id      = ''
	WHERE   emp_id          = @p_emp_id
	AND     assigned_to_code        = @w_assigned_to_code
	AND     job_or_pos_id           = @w_job_or_pos_id
	AND     eff_date       < @p_transfer_date
	AND     ((next_eff_date  >= @p_transfer_date AND
			next_eff_date                   != @w_EOT)
	OR     (next_eff_date    = @w_EOT AND
			end_date        >= @p_transfer_date))
/*   DELETE FUTURE DATED EMPLOYEE ASSIGNMENT VERSIONS */

/* ===AUDIT SECTION ===*/
	INSERT into work_emp_assignment_aud
	SELECT @W_ACTION_USER, 'ERXFERAGDV', @W_ACTION_DATETIME,
			asg.emp_id, asg.assigned_to_code, asg.job_or_pos_id, asg.eff_date, asg.next_eff_date,
			asg.prior_eff_date, '', '', '', '', '', ''
/*---------------------------------*/
	FROM    emp_assignment asg
	WHERE   emp_id             = @p_emp_id
	AND     assigned_to_code   = @w_assigned_to_code
	AND     job_or_pos_id      = @w_job_or_pos_id
	AND     eff_date           >= @p_transfer_date

	DELETE  emp_assignment
	WHERE   emp_id                  = @p_emp_id
	AND     assigned_to_code        = @w_assigned_to_code
	AND     job_or_pos_id           = @w_job_or_pos_id
	AND     eff_date                >= @p_transfer_date

/* R6.1M-SSA#131194 added @w_emp_assign_end_date to fetch below */
	FETCH cursor3
	INTO    @w_assigned_to_code, @w_emp_assign_end_date, @w_job_or_pos_id,
	        @audit_eff_date, @audit_next_eff_date, @audit_prior_eff_date

/* R6.1M-SSA#131194 begin add */
    if (@@fetch_status <> 0) or
       (@w_emp_assign_end_date = @p_transfer_date and
        @w_emp_status_code = 'T')
          select @w_end_active_assignment = 'N'
/* R6.1M-SSA#131194 end add */

          /*******************************************/
END       /*****  end   while loop for cursor3  ******/
          /*******************************************/

CLOSE cursor3
deallocate cursor3

/*   DELETE EMPLOYEE'S ASSIGNMENTS THAT BEGIN ON OR AFTER TRANSFER DATE */

/* ===AUDIT SECTION ===*/
	INSERT into work_emp_assignment_aud
	SELECT @W_ACTION_USER, 'ERXFERAGDL', @W_ACTION_DATETIME,
			asg.emp_id, asg.assigned_to_code, asg.job_or_pos_id, asg.eff_date,
		'', '', '', '', '', '', '', ''
	FROM	emp_assignment asg
	WHERE	emp_id	= @p_emp_id
	AND	begin_date	>= @p_transfer_date
	AND	begin_date	= eff_date
/*---------------------------------*/
	DELETE  emp_assignment
	WHERE   emp_id                  = @p_emp_id
	AND     begin_date              >= @p_transfer_date

	DELETE  emp_assignment_comnt
	WHERE   emp_id                  = @p_emp_id
	AND     begin_date              >= @p_transfer_date

/*   DETERMINE IF EMPLOYEE HAS BEEN PREVIOUSLY ASSIGNED TO
   THE NEW JOB OR POSITION */
	SELECT  @w_prev_assign_eff_date = eff_date
	FROM    emp_assignment
	WHERE   emp_id                  = @p_emp_id
	AND     assigned_to_code        = @p_assign_to
	AND     job_or_pos_id           = @p_job_or_pos_id
	AND     next_eff_date           = @w_EOT

if @@rowcount = 0
   select @w_prev_assign_eff_date = @w_EOT
else
	UPDATE  emp_assignment
	SET     next_eff_date           = @p_transfer_date
	WHERE   emp_id                  = @p_emp_id
	AND     assigned_to_code        = @p_assign_to
	AND     job_or_pos_id           = @p_job_or_pos_id
	AND     next_eff_date           = @w_EOT
/*   SELECT NEW JOB TO DEFAULT INFORMATION INTO EMPLOYEE TABLES */
if @p_assign_to = 'J'
   BEGIN       /*****  begin @p_assign_to = 'J'  ******/
	SELECT  @job_end_date                   = end_date,
		@job_work_time                  = pos_full_tm_ind,
		@job_sal_struct_id              = salary_structure_id,
		@job_sal_inc_guid_tbl_id        = salary_increase_guideline_id,
		@job_overtime_stat_code         = overtime_status_code,
		@job_shift_diff_stat_code       = shift_differential_status_code,
		@job_std_wk_hrs_per_day         = standard_daily_work_hrs,
		@job_pay_grade                  = pay_grade_code,
		@job_entry_step                 = entry_salary_step_nbr,
		@job_evaluation_pts             = evaluation_points_nbr,
		@job_base_rate_tbl_id           = base_rate_tbl_id,
		@job_base_rate_tbl_entry_code   = base_rate_tbl_entry_code,
		@w_pay_element_ctrl_grp_id	= pay_element_ctrl_grp_id
	FROM    job
	WHERE   job_id          = @p_job_or_pos_id
	AND     (eff_date       <= @p_transfer_date
	AND     next_eff_date   > @p_transfer_date)

	if @job_base_rate_tbl_id != '' and @job_base_rate_tbl_id != null

/*   SELECT JOB BASE RATE TABLE INFORMATION */
	  BEGIN
		SELECT  @j_rate_tbl_amt_type_code       = amt_type_code,
			@j_rate_tbl_id                  = rate_tbl_id,
			@j_rate_tbl_eff_date            = eff_date,
			@j_rate_tbl_tm_pd_id            = tm_pd_id
		FROM    rate_tbl
		WHERE   rate_tbl_id                     = @job_base_rate_tbl_id
		AND     (eff_date                       <= @p_transfer_date
		AND     next_eff_date                   > @p_transfer_date)

		if @@rowcount = 0
			BEGIN
--SYBSQL 			  raiserror 30000 'hpn26258'
          raiserror ('30000 hpn26258',16,0)
			  return
			END
		if @job_base_rate_tbl_entry_code != '' and @job_base_rate_tbl_entry_code != null
		   BEGIN
				SELECT  @rate_tbl_entry_rate_amt= rate_tbl_amt
				FROM    rate_tbl_entry
				WHERE   rate_tbl_id     = @j_rate_tbl_id
				AND     eff_date        = @j_rate_tbl_eff_date
				AND     rate_code       = @job_base_rate_tbl_entry_code

				if @@rowcount = 0
				  BEGIN
--SYBSQL 				    raiserror 30000 'hpn26258'
          raiserror ('30000 hpn26258',16,0)
				    return
				  END

				if @j_rate_tbl_amt_type_code = '2'
					SELECT  @w_per_sal_ann_factor   = annualizing_factor
					FROM    tm_pd_policy
					WHERE   tm_pd_id                = @j_rate_tbl_tm_pd_id
				else
				     select @w_per_sal_ann_factor = 0
		   END
	  END
             /***************************************/
   END       /*****  end   @p_assign_to = 'J'  ******/
             /***************************************/
else
   BEGIN     /*****  begin @p_assign_to = 'P'  ******/
/*   SELECT NEW POSITION TO DEFAULT INFORMATION INTO EMPLOYEE TABLES */

	SELECT  @pos_end_date               = end_date,
		@pos_work_time                  = full_tm_ind,
		@pos_sal_struct_id              = salary_structure_id,
		@pos_sal_inc_guid_tbl_id        = salary_increase_guideline_id,
		@pos_overtime_stat_code         = overtime_status_code,
		@pos_shift_diff_stat_code       = shift_differential_status_code,
		@pos_std_wk_hrs_per_day         = standard_daily_work_hrs,
		@pos_organization_group_id      = organization_group_id,
		@pos_organization_chart_name    = organization_chart_name,
		@pos_organization_unit_name     = organization_unit_name,
		@pos_work_shift_code            = work_shift_code,
		@pos_standard_work_hrs          = standard_work_hrs,
		@pos_standard_work_pd_id        = standard_work_pd_id,
		@pos_loc_code                   = loc_code,
		@pos_pay_grade_code             = pay_grade_code,
		@pos_entry_salary_step_nbr      = entry_salary_step_nbr,
		@pos_evaluation_points_nbr      = evaluation_points_nbr,
		@pos_base_rate_tbl_id           = base_rate_tbl_id,
		@pos_base_rate_tbl_entry_code   = base_rate_tbl_entry_code,
		@w_pay_element_ctrl_grp_id	= pay_element_ctrl_grp_id,
                @w_reg_rpt_unit_loc_code        = regulatory_reporting_unit_code   /* R653m SSA 465447 */

	FROM    position
	WHERE   pos_id          = @p_job_or_pos_id
	AND     (eff_date       <= @p_transfer_date
	AND     next_eff_date   > @p_transfer_date)

	if @pos_base_rate_tbl_id != '' and @pos_base_rate_tbl_id != null

/*   SELECT POSITION BASE RATE TABLE INFORMATION */
	  BEGIN
		SELECT  @p_rate_tbl_amt_type_code       = amt_type_code,
			@p_rate_tbl_id                  = rate_tbl_id,
			@p_rate_tbl_eff_date            = eff_date,
			@p_rate_tbl_tm_pd_id            = tm_pd_id
		FROM    rate_tbl
		WHERE   rate_tbl_id             = @pos_base_rate_tbl_id
		AND     (eff_date               <= @p_transfer_date
		AND     next_eff_date           > @p_transfer_date)

		if @@rowcount = 0
			BEGIN
--SYBSQL 			  raiserror 30000 'hpn26258'
          raiserror ('30000 hpn26258',16,0)
			  return
			END
		if @pos_base_rate_tbl_entry_code != '' and @pos_base_rate_tbl_entry_code != null
		   BEGIN
				SELECT  @rate_tbl_entry_rate_amt= rate_tbl_amt
				FROM    rate_tbl_entry
				WHERE   rate_tbl_id             = @p_rate_tbl_id
				AND     eff_date                = @p_rate_tbl_eff_date
				AND     rate_code               = @pos_base_rate_tbl_entry_code

				if @@rowcount = 0
				  BEGIN
--SYBSQL 				    raiserror 30000 'hpn26258'
          raiserror ('30000 hpn26258',16,0)
				    return
				  END

				if @p_rate_tbl_amt_type_code = '2'
					SELECT  @w_per_sal_ann_factor   = annualizing_factor
					FROM    tm_pd_policy
					WHERE   tm_pd_id                = @p_rate_tbl_tm_pd_id
				else
				     select @w_per_sal_ann_factor = 0
		   END
	  END
             /***************************************/
   END       /*****  end   @p_assign_to = 'P'  ******/
             /***************************************/

/*   SELECT EMPLOYEE'S CURRENT PRIME ASSIGNMENT */

SELECT  @w_standard_work_hrs= standard_work_hrs,
	@w_standard_work_pd_id	= standard_work_pd_id,
	@w_base_rate_tbl_id		= base_rate_tbl_id,
	@w_annual_salary_amt	= annual_salary_amt,
	@w_hourly_pay_rate		= hourly_pay_rate,
	@w_pd_salary_amt		= pd_salary_amt,
	@w_asgmt_curr_code		= curr_code
FROM    emp_assignment
WHERE   emp_id				= @p_emp_id
AND     end_date			= dateadd(day,-1,@p_transfer_date)
AND     prime_assignment_ind= 'Y'

if @@rowcount = 0 /* THERE WAS NO PRIME ASSIGNMENT IN EFFECT 1 DAY EARLIER THAN TRANSFER DATE */
   BEGIN
	SELECT  @w_standard_work_hrs    = standard_work_hrs,
		@w_standard_work_pd_id  = standard_work_pd_id,
		@w_base_rate_tbl_id     = base_rate_tbl_id,
		@w_annual_salary_amt    = annual_salary_amt,
		@w_hourly_pay_rate      = hourly_pay_rate,
		@w_pd_salary_amt        = pd_salary_amt,
		@w_asgmt_curr_code	= curr_code
	FROM    emp_assignment
	WHERE   emp_id                  = @p_emp_id
	AND     end_date                = dateadd(day,-1,@p_transfer_date)

	if @@rowcount = 1
	   BEGIN
		INSERT INTO  #temp11
		SELECT *
		FROM    emp_assignment
		WHERE   emp_id          = @p_emp_id
		AND     end_date        = dateadd(day,-1,@p_transfer_date)
	   END
	else    /* INITIALIZE ALL COLUMNS */
	   BEGIN
         if @w_emp_status_code = 'T'                           /* R6.1M-SSA#131194 */
            select @p_assignment_end_date = @p_transfer_date   /* R6.1M-SSA#131194 */

		 INSERT INTO #temp11
			values (@p_emp_id,'','',@w_EOT,@w_EOT,@w_EOT,'','','','',@w_EOT,@w_EOT,
					'','','',0,
					'','','','',@w_EOT,@w_EOT,0,0,'',0,'','','','',0,'','','','','',
					@w_EOT,0,0,@w_EOT,
					'','','','','','','','','','','','','','','','','','','','','','','',
					0,0,'',0,0,0,'',0,'','','',0,0,0,'','',@w_EOT,@w_EOT,'','',0,0,
					'','','','','',0)
	   END
   END
else
  BEGIN
    if @w_end_active_assignment = 'N' and @w_emp_status_code = 'T' /* R6.1M-SSA#131194 */
       select @p_assignment_end_date = @p_transfer_date            /* R6.1M-SSA#131194 */

	INSERT INTO  #temp11
	SELECT *
	FROM    emp_assignment
	WHERE   emp_id          = @p_emp_id
	AND     end_date        = dateadd(day,-1,@p_transfer_date)
	AND     prime_assignment_ind    = 'Y'
  END

/*   INSERT NEW PRIME EMPLOYEE ASSIGNMENT */

UPDATE #temp11
SET     prior_eff_date		= @w_prev_assign_eff_date,
	next_eff_date           = @w_EOT,
	next_assigned_to_code   = '',
	next_job_or_pos_id      = '',
	prior_assigned_to_code  = '',
	prior_job_or_pos_id     = '',
	prime_assignment_ind    = 'Y',
	occupancy_code          = '3',
	assignment_reason_code  = '',
	organization_change_reason_cd   = '',
	salary_change_type_code = '',
	salary_change_date      = @w_EOT,
	shift_differential_rate_tbl_id = '',
	work_shift_code                 = '',
	begin_date              = @p_transfer_date,
	eff_date                = @p_transfer_date,
	assigned_to_code        = @p_assign_to,
	job_or_pos_id           = @p_job_or_pos_id,
	organization_group_id   = @p_org_grp_id,
	organization_chart_name = @p_org_chart_name,
	organization_unit_name  = @p_org_unit_name,
	loc_code                = @p_location

if @w_base_rate_tbl_id != '' and @w_base_rate_tbl_id != null
   or @w_asgmt_curr_code != @p_new_empl_curr_code
   BEGIN
	UPDATE #temp11
	SET base_rate_tbl_id				= '',	base_rate_tbl_entry_code	= '',
		annual_salary_amt               = 0,	pd_salary_amt				= 0,
		pd_salary_tm_pd_id              = '',	hourly_pay_rate				= 0,
		pay_basis_code                  = '9',	exception_rate_ind			= 'N',
		ref_annual_salary_amt           = 0,	ref_pd_salary_amt			= 0,
		ref_pd_salary_tm_pd_id          = '',	ref_hourly_pay_rate			= 0,
		guaranteed_annual_salary_amt    = 0,	guaranteed_pd_salary_amt    = 0,
		guaranteed_pd_salary_tm_pd_id   = '',	guaranteed_hourly_pay_rate  = 0,
		curr_code 			= @p_new_empl_curr_code
   END

/*	CHECK FOR A STANDARD WORK PERIOD ID ON THE POSITION FIRST, IF
	IT'S NOT PRESENT CHECK FOR ONE ON THE ASSIGNMENT.  USE THE ONE
	YOU FIND TO GET THE ANNUALIZING FACTOR FROM THE TIME PERIOD POLICY,
	ELSE SET IT TO ZERO */

if	@pos_standard_work_pd_id != '' and @pos_standard_work_pd_id != null
	SELECT  @w_std_work_ann_factor  = annualizing_factor
	FROM    tm_pd_policy
	WHERE   tm_pd_id                = @pos_standard_work_pd_id
else
	BEGIN
	  if @w_standard_work_pd_id != '' and @w_standard_work_pd_id != null
		SELECT  @w_std_work_ann_factor  = annualizing_factor
		FROM    tm_pd_policy
		WHERE   tm_pd_id                = @w_standard_work_pd_id
	  else
		select @w_std_work_ann_factor = 0
	END

if @p_assign_to = 'J'

/*   DEFAULT JOB INFORMATION INTO EMPLOYEE ASSIGNMENT */
   BEGIN       /*****  begin @p_assign_to = 'J'  ******/
	UPDATE #temp11
	SET work_tm_code					= @job_work_time,
		salary_structure_id				= @job_sal_struct_id,
		salary_increase_guideline_id	= @job_sal_inc_guid_tbl_id,
		overtime_status_code			= @job_overtime_stat_code,
		shift_differential_status_code	= @job_shift_diff_stat_code,
		standard_daily_work_hrs			= @job_std_wk_hrs_per_day

	if @p_job_position_end_date < @p_assignment_end_date
		UPDATE #temp11
		SET     end_date	= @p_job_position_end_date
	else
		UPDATE #temp11
		SET     end_date	= @p_assignment_end_date

/* SET PAY GRADE AND STEP DATES  */

	if @job_pay_grade != @w_pay_grade
	   BEGIN
		UPDATE #temp11
		SET	pay_grade_code	= @job_pay_grade,
			pay_grade_date	= @p_transfer_date,
			salary_step_nbr	= @job_entry_step

		if @job_entry_step = 0
			UPDATE #temp11
			SET     salary_step_date = @w_EOT
		else
		    UPDATE #temp11
		    SET    salary_step_date = @p_transfer_date
	   END

	if @job_evaluation_pts != @w_evaluation_pts
	   BEGIN
		UPDATE #temp11
		SET	job_evaluation_points_nbr	= @job_evaluation_pts,
			pay_grade_date		= @p_transfer_date,
			salary_step_nbr		= @job_entry_step

		if @job_entry_step = 0
			UPDATE #temp11
			SET     salary_step_date = @w_EOT
		else
		    UPDATE #temp11
		    SET    salary_step_date = @p_transfer_date

	   END
/*   INITIALIZE ASSIGNMENT SALARY AMOUNTS WHEN JOB BASE PAY RATE TABLE PRESENT */
	if @job_base_rate_tbl_id != '' and @job_base_rate_tbl_id != null
	   BEGIN
		UPDATE #temp11
		SET base_rate_tbl_id	= @job_base_rate_tbl_id,annual_salary_amt	= 0,
			pd_salary_amt			= 0,	pd_salary_tm_pd_id		= '',
			hourly_pay_rate			= 0,	pay_basis_code			= '9',
			exception_rate_ind		= 'N',	ref_annual_salary_amt	= 0,
			ref_pd_salary_amt		= 0,	ref_pd_salary_tm_pd_id	= '',
			ref_hourly_pay_rate		= 0,	guaranteed_annual_salary_amt= 0,
			guaranteed_pd_salary_amt= 0,	guaranteed_pd_salary_tm_pd_id= '',
			guaranteed_hourly_pay_rate	= 0
	    END
/*   CALCULATE SALARY AMOUNTS WHEN JOB RATE ENTRY CODE PRESENT */

	if @job_base_rate_tbl_entry_code != '' and @job_base_rate_tbl_entry_code != null
	   BEGIN
	     UPDATE #temp11
		SET     base_rate_tbl_entry_code = @job_base_rate_tbl_entry_code

	   if @j_rate_tbl_amt_type_code = '1'   /* HOURLY RATES */
		BEGIN
		   UPDATE #temp11
		   SET  pay_basis_code  = '1',
			hourly_pay_rate = @rate_tbl_entry_rate_amt

		   if @w_standard_work_hrs != 0 and
			@w_standard_work_pd_id != '' and @w_standard_work_pd_id != null
			BEGIN
			   UPDATE #temp11
			   SET  annual_salary_amt =
			   (@rate_tbl_entry_rate_amt * @w_standard_work_hrs * @w_std_work_ann_factor)
			END
		END
	   else
	     BEGIN
		if @w_per_sal_ann_factor = 1   /* ANNUAL SALARY AMOUNTS */
		   BEGIN
			UPDATE #temp11
			SET     pay_basis_code	= '3',
				annual_salary_amt = @rate_tbl_entry_rate_amt

			if @w_standard_work_hrs != 0 and
			   @w_standard_work_pd_id != '' and @w_standard_work_pd_id != null
			   BEGIN
			      UPDATE #temp11
			      SET     hourly_pay_rate =
			round((@rate_tbl_entry_rate_amt / (@w_standard_work_hrs * @w_std_work_ann_factor)),4)
			   END
		   END
		else    /* PERIOD SALARY AMOUNTS */
		    BEGIN
		       UPDATE #temp11
		       SET pay_basis_code	= '2',
			   pd_salary_amt		= @rate_tbl_entry_rate_amt,
			   pd_salary_tm_pd_id	= @j_rate_tbl_tm_pd_id,
			   annual_salary_amt	= (@rate_tbl_entry_rate_amt * @w_per_sal_ann_factor)

			if @w_standard_work_hrs != 0 and
			   @w_standard_work_pd_id != '' and @w_standard_work_pd_id != null
			   BEGIN
			      UPDATE #temp11
			      SET     hourly_pay_rate =
 round(((@rate_tbl_entry_rate_amt * @w_per_sal_ann_factor) / (@w_standard_work_hrs * @w_std_work_ann_factor)),4)
			   END
		    END
	     END
	   END
	else    /* if @job_base_rate_tbl_entry_code != '' */

/* YOU CAN'T PLACE A RATE TABLE ID INTO THE NEW ASSIGNMENT W/OUT A RATE CODE */
	  BEGIN
	    UPDATE #temp11
	    SET base_rate_tbl_id = ''
	  END

   INSERT INTO emp_assignment
   SELECT *
   FROM   #temp11

             /***************************************/
   END       /*****  end   @p_assign_to = 'J'  ******/
             /***************************************/
else
    BEGIN    /*****  begin @p_assign_to = 'P'  ******/

/*   DEFAULT POSITION INFORMATION INTO EMPLOYEE ASSIGNMENT */
/* bhrpl R6.1 defect 980928132812 if user entered loc,use it otherwise dft pos loc*/
    if @p_location != '' and @p_location != null
	Select @pos_loc_code = @p_location
    BEGIN
	UPDATE #temp11
	SET work_tm_code                       = @pos_work_time,
		salary_structure_id            = @pos_sal_struct_id,
		salary_increase_guideline_id   = @pos_sal_inc_guid_tbl_id,
		overtime_status_code           = @pos_overtime_stat_code,
		shift_differential_status_code = @pos_shift_diff_stat_code,
		standard_daily_work_hrs        = @pos_std_wk_hrs_per_day,
		organization_group_id          = @pos_organization_group_id,
		organization_chart_name        = @pos_organization_chart_name,
		organization_unit_name         = @pos_organization_unit_name,
		work_shift_code                = @pos_work_shift_code,
		loc_code                       = @pos_loc_code,
                regulatory_reporting_unit_code = @w_reg_rpt_unit_loc_code    /* R653m SSA 465447 */
    end

	if @p_job_position_end_date < @p_assignment_end_date
		UPDATE #temp11
		SET     end_date	= @p_job_position_end_date
	else
		UPDATE #temp11
		SET     end_date	= @p_assignment_end_date

	if @pos_standard_work_hrs != 0
	BEGIN
	  UPDATE #temp11
	  SET	standard_work_hrs	= @pos_standard_work_hrs,
			standard_work_pd_id	= @pos_standard_work_pd_id
	END

/*   SET PAY GRADE AND STEP DATES   */

    if @pos_pay_grade_code != @w_pay_grade
	BEGIN
		UPDATE #temp11
		SET     pay_grade_code	= @pos_pay_grade_code,
			pay_grade_date		= @p_transfer_date,
			salary_step_nbr		= @pos_entry_salary_step_nbr

		if @pos_entry_salary_step_nbr = 0
			UPDATE #temp11
			SET     salary_step_date = @w_EOT
		else
		    UPDATE #temp11
		    SET    salary_step_date = @p_transfer_date
	END

	if @pos_evaluation_points_nbr != @w_evaluation_pts
	   BEGIN
		UPDATE #temp11
		SET     job_evaluation_points_nbr	= @pos_evaluation_points_nbr,
			pay_grade_date					= @p_transfer_date,
			salary_step_nbr					= @pos_entry_salary_step_nbr

		if @pos_entry_salary_step_nbr	= 0
		    UPDATE #temp11
		    SET     salary_step_date = @w_EOT
		else
		    UPDATE #temp11
		    SET    salary_step_date = @p_transfer_date

	   END
/*   INITIALIZE ASSIGNMENT SALARY AMOUNTS WHEN POSITION BASE PAY RATE TABLE PRESENT */
	if @pos_base_rate_tbl_id != '' and @pos_base_rate_tbl_id != null
	   BEGIN
		UPDATE #temp11
		SET base_rate_tbl_id	= @pos_base_rate_tbl_id,annual_salary_amt		= 0,
			pd_salary_amt			= 0,	pd_salary_tm_pd_id		= '',
			hourly_pay_rate			= 0,	pay_basis_code			= '9',
			exception_rate_ind		= 'N',	ref_annual_salary_amt	= 0,
			ref_pd_salary_amt		= 0,	ref_pd_salary_tm_pd_id	= '',
			ref_hourly_pay_rate		= 0,	guaranteed_annual_salary_amt	= 0,
			guaranteed_pd_salary_amt		= 0,guaranteed_pd_salary_tm_pd_id	= '',
			guaranteed_hourly_pay_rate		= 0
	    END

/*   CALCULATE SALARY AMOUNTS WHEN POSITION RATE ENTRY CODE PRESENT */

	if @pos_base_rate_tbl_entry_code != '' and @pos_base_rate_tbl_entry_code != null
	   BEGIN
		UPDATE #temp11
		SET     base_rate_tbl_entry_code = @pos_base_rate_tbl_entry_code

	   if @p_rate_tbl_amt_type_code = '1'	/* HOURLY RATES */
		BEGIN
		   UPDATE #temp11
		   SET  pay_basis_code  = '1',
			hourly_pay_rate = @rate_tbl_entry_rate_amt

		   if   @pos_standard_work_hrs != 0 and
				@pos_standard_work_pd_id != '' and @pos_standard_work_pd_id != null
			BEGIN
			   UPDATE #temp11
			   SET  annual_salary_amt =
			   (@rate_tbl_entry_rate_amt * @pos_standard_work_hrs * @w_std_work_ann_factor)
			END
		   else
			BEGIN
			   if @w_standard_work_hrs != 0 and
				@w_standard_work_pd_id != '' and @w_standard_work_pd_id != null
				BEGIN
				   UPDATE #temp11
				   SET  annual_salary_amt =
				   (@rate_tbl_entry_rate_amt * @w_standard_work_hrs * @w_std_work_ann_factor)
				END
			END
		END
	   else
	     BEGIN
		if @w_per_sal_ann_factor = 1   /* ANNUAL SALARY AMOUNTS */
		   BEGIN
			UPDATE #temp11
			SET	pay_basis_code	= '3',
				annual_salary_amt = @rate_tbl_entry_rate_amt

			if 	@pos_standard_work_hrs	!= 0 and
				@pos_standard_work_pd_id != '' and @pos_standard_work_pd_id != null
				BEGIN
				   UPDATE #temp11
				   SET     hourly_pay_rate =
			round((@rate_tbl_entry_rate_amt / (@pos_standard_work_hrs * @w_std_work_ann_factor)),4)
				END
			else
			  BEGIN
				if @w_standard_work_hrs != 0 and
				   @w_standard_work_pd_id != '' and @w_standard_work_pd_id != null
				   BEGIN
				      UPDATE #temp11
				      SET     hourly_pay_rate =
			round((@rate_tbl_entry_rate_amt / (@w_standard_work_hrs * @w_std_work_ann_factor)),4)
				   END
			  END
		   END
		else    /*  PERIOD SALARY AMOUNTS  */
		    BEGIN
		       UPDATE #temp11
		       SET pay_basis_code	= '2',
			   pd_salary_amt        = @rate_tbl_entry_rate_amt,
			   pd_salary_tm_pd_id   = @p_rate_tbl_tm_pd_id,
			   annual_salary_amt    = (@rate_tbl_entry_rate_amt * @w_per_sal_ann_factor)

			if 	@pos_standard_work_hrs != 0 and
				@pos_standard_work_pd_id != '' and @pos_standard_work_pd_id != null
				BEGIN
				   UPDATE #temp11
				   SET	hourly_pay_rate =
round(((@rate_tbl_entry_rate_amt * @w_per_sal_ann_factor)/ (@pos_standard_work_hrs * @w_std_work_ann_factor)),4)
				END
			else
			  BEGIN
				if @w_standard_work_hrs != 0 and
				   @w_standard_work_pd_id != '' and @w_standard_work_pd_id != null
				   BEGIN
				      UPDATE #temp11
				      SET	hourly_pay_rate =
round(((@rate_tbl_entry_rate_amt * @w_per_sal_ann_factor)/ (@w_standard_work_hrs * @w_std_work_ann_factor)),4)
				   END
			  END
		    END
	     END
	   END
	else    /* if @pos_base_rate_tbl_entry_code != '' */

/* YOU CAN'T PLACE A RATE TABLE ID INTO THE NEW ASSIGNMENT W/OUT A RATE CODE */
	  BEGIN
	    UPDATE #temp11
	    SET base_rate_tbl_id = ''
	  END

INSERT INTO emp_assignment
SELECT *
FROM   #temp11

       /*************************************/
END    /*****  end @p_assign_to = 'P'  ******/
       /*************************************/

if @w_hourly_pay_rate = 0 and
   @w_pd_salary_amt = 0 and
   @w_annual_salary_amt = 0
   select @w_empl_transfer_w_no_salary = 'Y'
else
  BEGIN
	select @w_empl_transfer_w_no_salary = 'N'
  END

/*	UPDATE POSITION SUCCESSION PLANNING INFORMATION IF IT EXISTS  */

if @p_assign_to = 'P'
  BEGIN
	if exists(	SELECT *
				FROM	pos_successor_candidate
				WHERE	pos_id	= @p_job_or_pos_id
				AND		emp_id	= @p_emp_id)

		BEGIN
			UPDATE	pos_successor_candidate
			SET		candidate_status_code = '05'
			WHERE	pos_id	= @p_job_or_pos_id
			AND		emp_id	= @p_emp_id
		END
  END

/* ======AUDIT SECTION ===*/

INSERT  into work_emp_assignment_aud
SELECT  @W_ACTION_USER, 'ERXFERAGBG', @W_ACTION_DATETIME,
		tmp.emp_id, tmp.assigned_to_code, tmp.job_or_pos_id, tmp.eff_date,
		'', '', '', '', '', '', '', ''
FROM	#temp11 tmp

DELETE	work_emp_assignment_aud
WHERE	user_id = @W_ACTION_USER
AND		activity_action_code = 'ERXFERAGBG'
AND		emp_id = @p_emp_id

DELETE FROM #temp11


EXECUTE hsp_upd_hrpn_04_trn @p_emp_id,
	  		@p_empl_id,
	  		@p_new_empl_id,
	  		@p_old_tax_entity_id,
	  		@p_new_tax_entity_id,
	  		@p_new_empl_taxing_country_cd,
            @w_us_authorities_complete  output,
			@w_tax_auth_complete_ret_cd output

/*   SET YEAR BEGIN DATE TO JANUARY 1 OF THE YEAR OF THE TRANSFER  */

declare @w_date_1	int,
		@w_year_begin_date	datetime

select @w_date_1			= datepart(year,@p_transfer_date)

select @w_year_begin_date 	= dateadd(month,0, convert(char(4),@w_date_1))

/*DETERMINE IF EMPLOYEE IS RETURNING TO A PRIOR EMPLOYER */
	if exists(SELECT *
				FROM	emp_employment
				WHERE	emp_id		= @p_emp_id
				AND		empl_id		= @p_new_empl_id
				AND		(eff_date	>= @w_year_begin_date
				OR		(eff_date	< @w_year_begin_date
				AND		(next_eff_date	!= @w_EOT
				AND		next_eff_date	> @w_year_begin_date
				OR		pay_through_date> @w_year_begin_date))))
		select  @w_return_to_prior_empl = 'Y'
	else
		select  @w_return_to_prior_empl = 'N'

/*DETERMINE IF EMPLOYEE IS RETURNING TO A PRIOR TAX ENTITY */
	if exists(SELECT *
				FROM	emp_employment
				WHERE	emp_id			= @p_emp_id
				AND		tax_entity_id	= @p_new_tax_entity_id
				AND		(eff_date		>= @w_year_begin_date
				OR		(eff_date		< @w_year_begin_date
				AND		(next_eff_date  != @w_EOT
				AND		next_eff_date   > @w_year_begin_date
				OR		pay_through_date > @w_year_begin_date))))
		select  @w_return_to_prior_tax_entity = 'Y'
	else
		select  @w_return_to_prior_tax_entity = 'N'

/*   UPDATE CURRENT EMPLOYMENT VERSION EFFECTIVE DATE POINTER */

	UPDATE  emp_employment
	SET     next_eff_date	= @p_transfer_date
	WHERE   emp_id			= @p_emp_id
	 AND    eff_date		= @p_eff_date

/*   INSERT NEW EMPLOYMENT VERSION WITH TRANSFER INFORMATION  */

	INSERT INTO #temp14
	SELECT *
	FROM    emp_employment
	WHERE   emp_id	= @p_emp_id
	 AND    eff_date= @p_eff_date

	UPDATE #temp14
	SET prior_eff_date	= @p_eff_date,
		next_eff_date	= @w_EOT,
		emp_info_source_code	= '2',
		empl_id			= @p_new_empl_id,
		eff_date		= @p_transfer_date,
		tax_entity_id	= @p_new_tax_entity_id,
		employment_info_chg_reason_cd	= @p_emp_info_change_reason,
		pay_group_id	= @p_pay_group,
		pay_element_ctrl_grp_id = @w_pay_element_ctrl_grp_id,
		chgstamp		= 0

	INSERT INTO emp_employment
	SELECT *
	FROM   #temp14 t14
	WHERE not exists (SELECT 1 FROM DBShrpn.dbo.emp_employment t2
							  WHERE t2.emp_id = t14.emp_id
							    AND t2.eff_date = @p_transfer_date)

	DELETE FROM #temp14

	INSERT INTO work_emp_employment_aud
		(user_id, activity_action_code, action_date, emp_id, eff_date,
		 next_eff_date, prior_eff_date, new_eff_date, new_empl_id,
		 new_tax_entity_id, xfer_date, pay_through_date)
	VALUES
		(@W_ACTION_USER, 'ERTRANSFER', @W_ACTION_DATETIME, @p_emp_id,
		 @p_eff_date, '', '', @p_transfer_date, '', '', '', '')

	DELETE work_emp_employment_aud
	WHERE user_id = @W_ACTION_USER
	  AND activity_action_code = 'ERTRANSFER'
	  AND emp_id = @p_emp_id

	Delete	work_emp_assignment_aud
	WHERE	user_id = @W_ACTION_USER
	AND	activity_action_code = 'ERXFERAGDV'
	AND	emp_id = @p_emp_id

	DELETE	work_emp_assignment_aud
	WHERE	user_id = @W_ACTION_USER
	AND	activity_action_code = 'ERXFERAGDL'
	AND	emp_id = @p_emp_id
/*
select  @w_return_to_prior_empl,
	@w_return_to_prior_tax_entity,
	@w_us_authorities_complete,
	@w_empl_transfer_w_no_salary,
	@w_tax_auth_complete_ret_cd
*/


GO


ALTER AUTHORIZATION ON dbo.usp_upd_hrpn_02_trn TO  SCHEMA OWNER
GO

IF OBJECT_ID(N'dbo.usp_upd_hrpn_02_trn', N'P') IS NOT NULL
    PRINT N'<<< CREATED PROCEDURE dbo.usp_upd_hrpn_02_trn >>>'
ELSE
    PRINT N'<<< FAILED CREATING PROCEDURE dbo.usp_upd_hrpn_02_trn >>>'
GO
