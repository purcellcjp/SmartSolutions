USE DBShrpn
go
IF OBJECT_ID(N'dbo.usp_upd_hmpl_reactivate') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_upd_hmpl_reactivate
    IF OBJECT_ID(N'dbo.usp_upd_hmpl_reactivate') IS NOT NULL
        PRINT N'<<< FAILED DROPPING PROCEDURE dbo.usp_upd_hmpl_reactivate >>>'
    ELSE
        PRINT N'<<< DROPPED PROCEDURE dbo.usp_upd_hmpl_reactivate >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER OFF
GO


/*************************************************************************************

   SP Name:      usp_upd_hmpl_reactivate

   Description:  Executes SmartStream rehire process

                 Cloned from DBShrpn..hsp_upd_hmpl_reactivate in order to use with
                 HCM Interface position title update procedure DBShrpn..usp_ins_position_title.

   Parameters:


   Tables

   Example:
      exec usp_upd_hmpl_reactivate ....

   Revision history:
      version  date        developer   SCR      description
      -------  ----------  ---------   -----    ------------------------------------
      1.0.00                                    - Cloned from SmmartStream version DBShrpn..hsp_upd_hmpl_reactivate
                                                    1) Disabled authentication

************************************************************************************/
CREATE procedure [dbo].[usp_upd_hmpl_reactivate]

(	@p_emp_id							char(15),
	@p_status_change_date			datetime,
	@p_reactivate_date				datetime,
	@p_new_reason						char(5),
	@p_new_classification_cd		char(2),
	@p_allow_emp_pay_updates_ind	char(1),
	@p_pay_status_code				char(1),
	@p_old_chgstamp					smallint
)

as
declare @ret int,
	@W_ACTION_DATETIME char(30)
--exec @ret = sp_dbs_authenticate
--if @ret != 0 return

declare	@w_end_of_time		datetime,
			@w_status_code		char(1),
			@w_last_action_cd 	char(2),
			@w_rehire_conson  	char(1),
			@w_return_status		int,
			@w_new_chgstamp		smallint,
			@w_spaces		char(5)

execute sp_dbs_calc_chgstamp @p_old_chgstamp, @w_new_chgstamp output

select	@w_end_of_time	= "12/31/2999",
	@w_status_code		= "A",
	@w_last_action_cd 	= "RA",
	@w_rehire_conson 		= "N",
	@w_spaces	 			= " "

/****************************************************************/
/* Update the current Employee Status Row with the Reactivation */
/* date.																  */
/****************************************************************/
begin transaction

update emp_status
	set	next_change_date  = @p_reactivate_date,
		chgstamp          = @w_new_chgstamp
	where	emp_id = @p_emp_id
	and	status_change_date = @p_status_change_date
	and	chgstamp = @p_old_chgstamp

if @@rowcount = 0
	begin
		if exists (select * from emp_status
				where emp_id = @p_emp_id
				and	status_change_date = @p_status_change_date)
--SYBSQL 			raiserror 20001 "Row updated by another user."
          raiserror ('20001 Row updated by another user.',16,0)
		else
--SYBSQL 			raiserror 20002 "Row does not exist."
          raiserror ('20002 Row does not exist.',16,0)
			rollback transaction
			return
		end

/***************************************************************/
/* Insert the new Employee Status row with the status change   */
/* date equal to the reactivation date.								*/
/***************************************************************/

insert into emp_status
	select  @p_emp_id,			@p_reactivate_date,
		@p_status_change_date,	@w_end_of_time,
		@w_status_code,			@p_new_classification_cd,
		@w_spaces,					hire_date,
		@w_end_of_time,			@w_rehire_conson,
		@p_new_reason,			@w_spaces,
		@w_last_action_cd,		0
	from	emp_status
	where	emp_id	= @p_emp_id
	and	status_change_date = @p_status_change_date

if @@error != 0
		begin
			rollback transaction
			return
		end


/***************************************************************/
/* Execute the Employee Update Employment stored procedure     */
/* if the Allow Employee Pay Updates indicator is on.          */
/***************************************************************/
if @p_allow_emp_pay_updates_ind = "Y"
	begin
		execute @w_return_status =
			hsp_upd_hrpn_status
			@p_reactivate_date,
			@p_emp_id,
			@p_pay_status_code
		if @w_return_status = -1
			begin
--SYBSQL 				raiserror 26097 "Employee has corrupted Employee Employment info."
          raiserror ('26097 Employee has corrupted Employee Employment info.',16,0)
				rollback transaction
				return
			end
		else
			if @w_return_status = 1
				begin
					rollback transaction
					return
				end
	end

/* AUDIT SECTION ==============================================*/
/* Set up the work employee status audit table                                          */
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

	insert into work_emp_status_aud
		(user_id, activity_action_code, action_date, emp_id,
        status_change_date, prior_change_date, prior_emp_id)
	values
		(@W_ACTION_USER, 'REACTIVATE', @W_ACTION_DATETIME,
		@p_emp_id, @p_reactivate_date, @p_status_change_date, '')

	Delete work_emp_status_aud
	Where user_id = @W_ACTION_USER
	and activity_action_code = 'REACTIVATE'
	and emp_id = @p_emp_id
	and status_change_date = @p_reactivate_date

/* END AUDIT SECTION ========================================*/
/* Set up the work employee status audit table                                          */
/* ============================================================*/


commit transaction




GO
ALTER AUTHORIZATION ON [dbo].[usp_upd_hmpl_reactivate] TO  SCHEMA OWNER
GO

IF OBJECT_ID(N'dbo.usp_upd_hmpl_reactivate', N'P') IS NOT NULL
    PRINT N'<<< CREATED PROCEDURE dbo.usp_upd_hmpl_reactivate >>>'
ELSE
    PRINT N'<<< FAILED CREATING PROCEDURE dbo.usp_upd_hmpl_reactivate >>>'
GO
