USE [DBShrpn]
GO
/****** Object:  StoredProcedure [dbo].[usp_upd_hmpl_chgid]    Script Date: 4/1/2025 4:33:00 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO




CREATE procedure [dbo].[usp_upd_hmpl_chgid]
(
  	@p_old_emp_id						char(15),
	@p_new_emp_id						char(15),
	@p_ptcp_id_assign_meth_code		char(1)

)
as
declare @ret int,
	@W_ACTION_USER	char(30),
	@W_ACTION_DATETIME	char(30)
--exec @ret = sp_dbs_authenticate if @ret != 0 return

declare	@w_new_chgstamp					tinyint

select @w_new_chgstamp	= 0			

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



/*********************************************************************/
/* Update  new Employee rows using the new employee id as the key and*/
/* using the old employee id as the prior employee id. 				*/
/*********************************************************************/

/* AUDIT SECTION ==============================================*/
/* Set up the work employee status audit table                                          */
/* ============================================================*/
	Update hr_audit_ctrl
		set working_bypass_audit_ind = bypass_audit_ind,
		bypass_audit_ind = 'N'

/* We need to lock the audit control table for
the duration of the "Change Employee ID" process.
to fix the defect # 970709155107 or SSA # 19106 */

begin transaction
if exists( SELECT *  FROM hr_audit_ctrl tablockx with (holdlock))


	insert into work_emp_status_aud
		(user_id, activity_action_code, action_date, emp_id,
        status_change_date, prior_change_date, prior_emp_id)
	values
		(@W_ACTION_USER, 'CHGEMPID', @W_ACTION_DATETIME,
		@p_new_emp_id, '', '', @p_old_emp_id)

	Delete work_emp_status_aud
	Where user_id = @W_ACTION_USER
	and action_date = @W_ACTION_DATETIME
	and activity_action_code = 'CHGEMPID'
	and emp_id = @p_new_emp_id


/* END AUDIT SECTION ========================================*/
/* Set up the work employee status audit table                                          */
/* ============================================================*/


	update employee
		set emp_id = @p_new_emp_id,
			 prior_emp_id 			= @p_old_emp_id,
			 chgstamp 				= @w_new_chgstamp
	  from employee
	 where emp_id = @p_old_emp_id

	update participant
		set emp_id = @p_new_emp_id
		  where emp_id = @p_old_emp_id
	
	if @p_ptcp_id_assign_meth_code = "2"
		begin
			update participant
				set participant_id = @p_new_emp_id,
					chgstamp = chgstamp + 1
				where participant_id = @p_old_emp_id

			update ben_plan_ptcp
				set participant_id = @p_new_emp_id,
					chgstamp = chgstamp + 1
				where participant_id = @p_old_emp_id
	
			update ben_plan_ptcp_comnt
				set participant_id = @p_new_emp_id,
					chgstamp = chgstamp + 1
				where participant_id = @p_old_emp_id

			update ben_plan_ptcp_com
				set participant_id = @p_new_emp_id,
					chgstamp = chgstamp + 1
				where participant_id = @p_old_emp_id

			update ben_plan_ptcp_com_comnt
				set participant_id = @p_new_emp_id,
					chgstamp = chgstamp + 1
				where participant_id = @p_old_emp_id

			update ben_plan_ptcp_acct
				set participant_id = @p_new_emp_id,
					chgstamp = chgstamp + 1
				where participant_id = @p_old_emp_id

			update ben_plan_ptcp_acct_comnt
				set participant_id = @p_new_emp_id,
					chgstamp = chgstamp + 1
				where participant_id = @p_old_emp_id

			update ben_plan_ptcp_associate
				set participant_id = @p_new_emp_id,
					chgstamp = chgstamp + 1
				where participant_id = @p_old_emp_id

			update ben_plan_ptcp_assoc_comnt
				set participant_id = @p_new_emp_id,
					chgstamp = chgstamp + 1
				where participant_id = @p_old_emp_id

			update ben_plan_ptcp_claim
				set participant_id = @p_new_emp_id,
					chgstamp = chgstamp + 1
				where participant_id = @p_old_emp_id

			update ben_plan_ptcp_comnt
				set participant_id = @p_new_emp_id,
					chgstamp = chgstamp + 1
				where participant_id = @p_old_emp_id

			update ben_plan_ptcp_claim_comnt
				set participant_id = @p_new_emp_id,
					chgstamp = chgstamp + 1
				where participant_id = @p_old_emp_id	

			update ben_plan_ptcp_loan
				set participant_id = @p_new_emp_id,
					chgstamp = chgstamp + 1
				where participant_id = @p_old_emp_id

			update ben_plan_ptcp_loan_comnt
				set participant_id = @p_new_emp_id,
					chgstamp = chgstamp + 1
				where participant_id = @p_old_emp_id

			update ben_plan_ptcp_opt
				set participant_id = @p_new_emp_id,
					chgstamp = chgstamp + 1
				where participant_id = @p_old_emp_id

			update ben_plan_ptcp_opt_comnt
				set participant_id = @p_new_emp_id,
					chgstamp = chgstamp + 1
				where participant_id = @p_old_emp_id

			update ben_plan_ptcp_opt_alloc
				set participant_id = @p_new_emp_id,
					chgstamp = chgstamp + 1
				where participant_id = @p_old_emp_id

			update ben_plan_ptcp_status
				set participant_id = @p_new_emp_id,
					chgstamp = chgstamp + 1
				where participant_id = @p_old_emp_id

			update ben_plan_ptcp_withdrawal
				set participant_id = @p_new_emp_id,
					chgstamp = chgstamp + 1
				where participant_id = @p_old_emp_id

			update ben_plan_ptcp_wdr_comnt
				set participant_id = @p_new_emp_id,
					chgstamp = chgstamp + 1
				where participant_id = @p_old_emp_id
		end


Commit transaction
/* AUDIT SECTION ==============================================*/
/* Set up the work employee status audit table                                          */
/* ============================================================*/
	Update hr_audit_ctrl
		set bypass_audit_ind = working_bypass_audit_ind,
		working_bypass_audit_ind = ''

/* END AUDIT SECTION ========================================*/
/* Set up the work employee status audit table                                          */
/* ============================================================*/

 

 
GO
ALTER AUTHORIZATION ON [dbo].[usp_upd_hmpl_chgid] TO  SCHEMA OWNER 
GO
