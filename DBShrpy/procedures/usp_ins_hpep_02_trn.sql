USE DBShrpy
go

IF OBJECT_ID(N'dbo.usp_ins_hpep_02_trn') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_ins_hpep_02_trn
    IF OBJECT_ID(N'dbo.usp_ins_hpep_02_trn') IS NOT NULL
        PRINT N'<<< FAILED DROPPING PROCEDURE dbo.usp_ins_hpep_02_trn >>>'
    ELSE
        PRINT N'<<< DROPPED PROCEDURE dbo.usp_ins_hpep_02_trn >>>'
END
go
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER OFF
GO

/*************************************************************************************

   SP Name:      usp_ins_hpep_02_trn

   Description:  Processes trasnfers from one tax employer to another.

                 (THIS SP PERFORMS ALL PROCESSING NECESSARY TO TABLES WITHIN 'HRPY')

                 Cloned from SmartStream procedure DBShrpy..hsp_ins_hpep_02
                 in order to use with HCM Interface.

   Parameters:


   Tables

   Example:
      exec usp_ins_hpep_02_trn ....

   Revision history:
      version  date        developer   SCR      description
      -------  ----------  ---------   -----    ------------------------------------
      1.0.00                                    - Cloned from SmartStream version DBShrpy.dbo.hsp_ins_hpep_02
                                                    1) Disabled authentication
                                                    2) Replaced all double quotes with single quote

************************************************************************************/

CREATE OR ALTER PROCEDURE [dbo].[usp_ins_hpep_02_trn]
       (@p_emp_id			char(15),
	@p_old_empl_id			char(10),
	@p_new_empl_id			char(10),
	@p_transfer_date		datetime,
	@p_calendar_year		smallint,
	@p_curr_code			char(3),
	@p_return_to_prior_empl		char(1),
	@p_empl_adj_paymnt_run_type	char(10),
	@p_system_user_id		char(10),
	@p_pay_group_id			char(10))

AS
    declare @w_ret   int

 --   execute @w_ret = sp_dbs_authenticate

 -- if @w_ret != 0
 --     return

/*------------------------------------------------------------------

TRANSFER AN EMPLOYEE FROM ONE TAX EMPLOYER TO ANOTHER
(THIS SP PERFORMS ALL PROCESSING NECESSARY TO TABLES WITHIN 'HRPY')

------------------------------------------------------------------*/

declare	@w_pay_element_id			char(10),
	@w_empl_xfer_opt_code			char(2),
	@w_pmt_detail_type_code			char(1),
	@w_pay_element_type_code		char(1),
	@w_new_pay_period_id			char(10),
	@w_seq_control_nbr			int,
	@w_emp_adj_pmt_created			char(1),
	@w_yr_to_date_monetary_amt		money,
	@w_yr_to_date_tm_amt			money,
	@w_yr_to_date_nbr_of_units		money,
	@w_ytd_carry_fwd_ref_monet_amt		money,
	@w_ytd_carry_fwd_ref_tm_amt		money,
	@w_ytd_carry_fwd_ref_nbr_unt		money,
	@w_life_to_date_monetary_amt		money,
	@w_life_to_date_tm_amt			money,
	@w_life_to_date_nbr_of_units		money,
	@w_EOT					datetime

select @w_EOT			= '12/31/2999'
select @w_emp_adj_pmt_created	= 'N'
select @w_pay_element_type_code	= ''
select @w_seq_control_nbr	= 0
select @w_new_pay_period_id	= ''

/*-------------------------------------------------------------------
CREATE EMPLOYEE PAY ELEMENT ACCUMULATOR CURSOR
------------------------------------------------------------------*/
DECLARE cursor1 cursor for
SELECT	pay_element_id,
	yr_to_date_monetary_amt,
	yr_to_date_tm_amt,
	yr_to_date_nbr_of_units,
	ytd_carried_fwd_ref_monet_amt,
	ytd_carried_forward_ref_tm_amt,
	ytd_carried_fwd_ref_nbr_of_unt,
	life_to_date_monetary_amt,
	life_to_date_tm_amt,
	life_to_date_nbr_of_units
FROM	emp_pay_element_accum
WHERE	emp_id	= @p_emp_id
AND	empl_id	= @p_old_empl_id
AND	cal_yr	= @p_calendar_year

OPEN cursor1

FETCH	cursor1
INTO	@w_pay_element_id,
	@w_yr_to_date_monetary_amt,
	@w_yr_to_date_tm_amt,
	@w_yr_to_date_nbr_of_units,
	@w_ytd_carry_fwd_ref_monet_amt,
	@w_ytd_carry_fwd_ref_tm_amt,
	@w_ytd_carry_fwd_ref_nbr_unt,
	@w_life_to_date_monetary_amt,
	@w_life_to_date_tm_amt,
	@w_life_to_date_nbr_of_units

WHILE @@fetch_status = 0
   BEGIN
	select @w_pmt_detail_type_code = '1'

	SELECT	@w_empl_xfer_opt_code		= empl_xfer_opt_code,
		@w_pay_element_type_code	= pay_element_type_code
	  FROM	DBShrpn..pay_element
	  WHERE	pay_element_id	= @w_pay_element_id
	  AND	(eff_date	<= @p_transfer_date
	  AND	next_eff_date	> eff_date)

	if @@rowcount = 0
	   BEGIN
		select @w_pmt_detail_type_code = '2'

		SELECT	@w_empl_xfer_opt_code	= empl_xfer_opt_code
		  FROM	DBShrpn..aggregate
		  WHERE	aggr_id	= @w_pay_element_id

		if @@rowcount = 0
		   BEGIN
--SYBSQL 			raiserror 30000 'Pay Element or Aggregate missing'
          raiserror ('30000 Pay Element or Aggregate missing',16,0)
			CLOSE cursor1
			deallocate cursor1
			return
		   END
	   END

	/*-------------------------------------------------------------------
	SELECT EMPLOYEE'S LAST ADJUSTMENT PAYMENT
	------------------------------------------------------------------*/
	if @w_empl_xfer_opt_code in ('02','03','04')
  	   BEGIN
		if @w_emp_adj_pmt_created = 'N'
	  	   BEGIN
			SELECT	@w_new_pay_period_id = pay_pd_id
			FROM	emp_pmt
			WHERE	emp_id		= @p_emp_id
			AND	pmt_type_code	= '06'
			AND	pay_pd_id	=
			-- R6.5.02m - Solution#412371 Begin
			--		          (SELECT max(pay_pd_id)
                				  (SELECT convert (char,max(convert(int, pay_pd_id)))
			-- R6.5.02m - Solution#412371 End
						   FROM	  emp_pmt
						   WHERE  emp_id	= @p_emp_id
						   AND	  pmt_type_code	= '06')

			if @w_new_pay_period_id is null or @w_new_pay_period_id = ''
				select @w_new_pay_period_id = '1'
			else
		    	   BEGIN
				select @w_new_pay_period_id = convert(char(10),convert(int,@w_new_pay_period_id) + 1)
		    	   END

			/*-------------------------------------------------------------------
			SELECT EMPLOYEE'S LAST PROCESSED PAYMENT
			------------------------------------------------------------------*/
			SELECT	@w_seq_control_nbr = seq_ctrl_nbr
			FROM	emp_pmt
			WHERE	emp_id		= @p_emp_id
			AND	seq_ctrl_yr	= @p_calendar_year
			AND	seq_ctrl_nbr	=
						  (SELECT max(seq_ctrl_nbr)
			 			   FROM	  emp_pmt
			 			   WHERE  emp_id	= @p_emp_id
						   AND	  seq_ctrl_yr	= @p_calendar_year)

			if @w_seq_control_nbr is null
		  	   BEGIN
		   		select @w_seq_control_nbr = 0
		  	   END

			/*-------------------------------------------------------------------
			INSERT ADJUSTMENT TYPE EMPLOYEE PAYMENT
			------------------------------------------------------------------*/
			select @w_seq_control_nbr = @w_seq_control_nbr + 1

			INSERT INTO emp_pmt
			VALUES(	@p_emp_id,			-- emp_id
				@p_empl_adj_paymnt_run_type,	-- payroll_run_type_id
				@w_new_pay_period_id,		-- pay_pd_id
				1,				-- pmt_seq_nbr
				'06',				-- pmt_type_code
				'02',				-- emp_pmt_status_code
				'N',				-- recalculate_pmt_ind
				'N',				-- posted_accumulator_ind
				'99',				-- accumulator_adj_type_code
				@p_transfer_date,		-- accumulator_posting_eff_date
				@p_system_user_id,		-- user_id
				'',				-- accumulator_adj_reason_code
				'07',				-- pmt_origin_code
				@p_new_empl_id,			-- empl_id
				@p_pay_group_id,		-- pay_group_id
				'',				-- procsd_by_payroll_run_ctrl_id
				getdate(),			-- check_date
				@w_EOT,				-- pay_pd_begin_date
				@w_EOT,				-- pay_pd_end_date
				0,0,0,0,0,0,0,0,0,0,0,0,	-- payment & year to date fields
				@p_curr_code,			-- curr_code
				'',				-- time_reporting_meth_code
				@p_calendar_year,		-- seq_ctrl_yr
				@w_seq_control_nbr,		-- seq_ctrl_nbr
				0,0,0,0,			-- user defined fields
				@p_curr_code,
				'','',
				@w_EOT,@w_EOT,
				'N','N','','',
				'N',				/* SSA 14238 ldr_distn_genned_ind */
				0)

			select @w_emp_adj_pmt_created = 'Y'

	  	   END			-- MATCHED W/ if @w_emp_adj_pmt_created = 'N'

		/*-------------------------------------------------------------------
		INSERT EMPLOYEE PAYMENT PAY ELEMENT DETAIL
		------------------------------------------------------------------*/
		INSERT INTO emp_pmt_pay_element_detail
		VALUES (@p_emp_id,			-- emp_id
			@p_empl_adj_paymnt_run_type,	-- payroll_run_type_id
			@w_new_pay_period_id,		-- pay_pd_id
			1,				-- pmt_seq_nbr
			@w_pay_element_id,		-- pay_element_id
			@p_calendar_year,		-- seq_ctrl_yr
			@w_seq_control_nbr,		-- seq_ctrl_nbr
			@w_pmt_detail_type_code,	-- pmt_detail_type_code
			@w_pay_element_type_code,	-- pay_element_type_code
			'','',
			0,0,0,0,0,0,
			'N',				-- override_pay_trans_ind
			0,0,0,
			'N',				-- override_correction_ind
			0,0,0,0,0,0,0,0,0,0,0,0,
			'N',				-- pre_tax_deduction_ind
			'N',				-- pre_tax_deduction_withheld_ind
			'N',				-- reset_pay_pd_sched_code_ind
			'','','','','',
			@p_new_empl_id,			-- employer
			0,0,0,
			'','',
			0,
			0,
                	'')  				/* R7.0M-ALS#566986 */

		/*-------------------------------------------------------------------
		COPY YEAR TO DATE FORWARD FOR REFERENCE ONLY
		------------------------------------------------------------------*/
		if @w_empl_xfer_opt_code = '02'
	  	   BEGIN
			if @p_return_to_prior_empl = 'Y'
				UPDATE	emp_pmt_pay_element_detail
				SET	ytd_carried_fwd_monetary_amt	= @w_yr_to_date_monetary_amt,
					ytd_carried_fwd_tm_amt		= @w_yr_to_date_tm_amt,
					ytd_carried_fwd_nbr_of_units	= @w_yr_to_date_nbr_of_units
				WHERE	emp_id		= @p_emp_id
				AND	payroll_run_type_id= @p_empl_adj_paymnt_run_type
				AND	pay_pd_id	= @w_new_pay_period_id
				AND	pmt_seq_nbr	= 1
				AND	pay_element_id	=  @w_pay_element_id
				AND	seq_ctrl_yr	= @p_calendar_year
				AND	seq_ctrl_nbr	= @w_seq_control_nbr
			else
				UPDATE	emp_pmt_pay_element_detail
				SET	ytd_carried_fwd_monetary_amt	= @w_yr_to_date_monetary_amt + @w_ytd_carry_fwd_ref_monet_amt,
					ytd_carried_fwd_tm_amt	= @w_yr_to_date_tm_amt + @w_ytd_carry_fwd_ref_tm_amt,
					ytd_carried_fwd_nbr_of_units	= @w_yr_to_date_nbr_of_units + @w_ytd_carry_fwd_ref_nbr_unt
				WHERE	emp_id		= @p_emp_id
				AND	payroll_run_type_id= @p_empl_adj_paymnt_run_type
				AND	pay_pd_id	= @w_new_pay_period_id
				AND	pmt_seq_nbr	= 1
				AND	pay_element_id	=  @w_pay_element_id
				AND	seq_ctrl_yr	= @p_calendar_year
				AND	seq_ctrl_nbr	= @w_seq_control_nbr
	  	   END

		/*-------------------------------------------------------------------
		BRING LIFE TO DATE FORWARD
		------------------------------------------------------------------*/
		if @w_empl_xfer_opt_code = '03'
	  	   BEGIN
			if @p_return_to_prior_empl = 'Y'
				UPDATE	emp_pmt_pay_element_detail
				SET	tot_current_monetary_amt= @w_yr_to_date_monetary_amt,
					tot_current_tm_amt	= @w_yr_to_date_tm_amt,
					tot_current_nbr_of_units= @w_yr_to_date_nbr_of_units
				WHERE	emp_id		= @p_emp_id
				AND	payroll_run_type_id= @p_empl_adj_paymnt_run_type
				AND	pay_pd_id	= @w_new_pay_period_id
				AND	pmt_seq_nbr	= 1
				AND	pay_element_id	=  @w_pay_element_id
				AND	seq_ctrl_yr	= @p_calendar_year
				AND	seq_ctrl_nbr	= @w_seq_control_nbr
			else
				UPDATE	emp_pmt_pay_element_detail
				SET	tot_current_monetary_amt= @w_life_to_date_monetary_amt,
					tot_current_tm_amt	= @w_life_to_date_tm_amt,
					tot_current_nbr_of_units= @w_life_to_date_nbr_of_units
				WHERE	emp_id		= @p_emp_id
				AND	payroll_run_type_id= @p_empl_adj_paymnt_run_type
				AND	pay_pd_id	= @w_new_pay_period_id
				AND	pmt_seq_nbr	= 1
				AND	pay_element_id	=  @w_pay_element_id
				AND	seq_ctrl_yr	= @p_calendar_year
				AND	seq_ctrl_nbr	= @w_seq_control_nbr
	  	   END

		/*-------------------------------------------------------------------
		COPY YEAR TO DATE FORWARD FOR REFERENCE ONLY &
		BRING LIFE TO DATE FORWARD
		------------------------------------------------------------------*/
		if @w_empl_xfer_opt_code = '04'
	  	   BEGIN
			if @p_return_to_prior_empl = 'Y'
				UPDATE	emp_pmt_pay_element_detail
				SET	ytd_carried_fwd_monetary_amt	= @w_yr_to_date_monetary_amt,
					ytd_carried_fwd_tm_amt		= @w_yr_to_date_tm_amt,
					ytd_carried_fwd_nbr_of_units	= @w_yr_to_date_nbr_of_units,
					tot_current_monetary_amt	= @w_yr_to_date_monetary_amt,
					tot_current_tm_amt		= @w_yr_to_date_tm_amt,
					tot_current_nbr_of_units	= @w_yr_to_date_nbr_of_units
				WHERE	emp_id		= @p_emp_id
				AND	payroll_run_type_id= @p_empl_adj_paymnt_run_type
				AND	pay_pd_id	= @w_new_pay_period_id
				AND	pmt_seq_nbr	= 1
				AND	pay_element_id	=  @w_pay_element_id
				AND	seq_ctrl_yr	= @p_calendar_year
				AND	seq_ctrl_nbr	= @w_seq_control_nbr
			else
				UPDATE	emp_pmt_pay_element_detail
				SET	ytd_carried_fwd_monetary_amt	= @w_yr_to_date_monetary_amt + @w_ytd_carry_fwd_ref_monet_amt,
					ytd_carried_fwd_tm_amt		= @w_yr_to_date_tm_amt + @w_ytd_carry_fwd_ref_tm_amt,
					ytd_carried_fwd_nbr_of_units	= @w_yr_to_date_nbr_of_units + @w_ytd_carry_fwd_ref_nbr_unt,
					tot_current_monetary_amt	= @w_life_to_date_monetary_amt,
					tot_current_tm_amt		= @w_life_to_date_tm_amt,
					tot_current_nbr_of_units	= @w_life_to_date_nbr_of_units
				WHERE	emp_id		= @p_emp_id
				AND	payroll_run_type_id= @p_empl_adj_paymnt_run_type
				AND	pay_pd_id	= @w_new_pay_period_id
				AND	pmt_seq_nbr	= 1
				AND	pay_element_id	=  @w_pay_element_id
				AND	seq_ctrl_yr	= @p_calendar_year
				AND	seq_ctrl_nbr	= @w_seq_control_nbr
 	 	   END
  	   END		-- MATCHED W/ if @w_empl_xfer_opt_code in ('02','03','04')

	FETCH	cursor1
	INTO	@w_pay_element_id,
		@w_yr_to_date_monetary_amt,
		@w_yr_to_date_tm_amt,
		@w_yr_to_date_nbr_of_units,
		@w_ytd_carry_fwd_ref_monet_amt,
		@w_ytd_carry_fwd_ref_tm_amt,
		@w_ytd_carry_fwd_ref_nbr_unt,
		@w_life_to_date_monetary_amt,
		@w_life_to_date_tm_amt,
		@w_life_to_date_nbr_of_units
    END

CLOSE cursor1
deallocate cursor1

if @w_seq_control_nbr is null
   BEGIN
   	select @w_seq_control_nbr	= 0
   END

if @w_new_pay_period_id is null
   BEGIN
   	select @w_new_pay_period_id	= ''
   END
/*
select	@w_emp_adj_pmt_created,
	@w_seq_control_nbr,
	@w_new_pay_period_id
*/


GO

ALTER AUTHORIZATION ON dbo.usp_ins_hpep_02_trn TO  SCHEMA OWNER
GO

IF OBJECT_ID(N'dbo.usp_ins_hpep_02_trn', N'P') IS NOT NULL
    PRINT N'<<< CREATED PROCEDURE dbo.usp_ins_hpep_02_trn >>>'
ELSE
    PRINT N'<<< FAILED CREATING PROCEDURE dbo.usp_ins_hpep_02_trn >>>'
GO
