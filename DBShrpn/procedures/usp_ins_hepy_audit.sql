USE [DBShrpn]
GO
/****** Object:  StoredProcedure [dbo].[usp_ins_hepy_audit]    Script Date: 4/1/2025 4:33:00 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO




CREATE procedure [dbo].[usp_ins_hepy_audit] (
        @p_activity_action_code 	char(10),
        @p_user_id 			char(30),
        @p_action_date 			char(30),
        @p_b_emp_id 			char(15),
        @p_b_empl_id 			char(10),
        @p_b_pay_element_id 		char(10),
        @p_b_eff_date 			datetime,
        @p_a_emp_id 			char(15),
        @p_a_empl_id 			char(10),
        @p_a_pay_element_id 		char(10),
        @p_a_eff_date 			datetime,
        @p_new_start_date 		datetime,
        @p_new_stop_date 		datetime,
        @p_next_eff_date 		datetime,
        @p_inactivated_by_pay_el_in 	char (1))
as
/*  This procedure inserts a row into Employee Pay Element Audit, using
data passed from the caller.  The procedure is called from the Work
Employee Pay Element Audit insert trigger, htrg_ins_work_emp_elmt_aud.

Four different types of insertions are employed, based upon the value
of @p_activity_action_code. Prior to performing the insertion, a test
is performed to prevent the insertion of duplicate rows.  */

begin
    declare @w_pay_elmt_pay_pd_sched_code char(02) /* R7.0M-ALS#567582 */

    declare @w_ret int

  --  execute @w_ret = sp_dbs_authenticate
  -- if @w_ret != 0
  --      return

/*  See if audit table row already exists; return without performing
        insertions, if the row exists  */
    exec @w_ret = hsp_val_hepy_audit @p_activity_action_code, @p_user_id,
        @p_action_date, @p_b_emp_id, @p_b_empl_id, @p_b_pay_element_id,
        @p_b_eff_date, @p_a_emp_id, @p_a_empl_id, @p_a_pay_element_id,
        @p_a_eff_date
    if @w_ret = 1
        return

    /*  Insert where before is null.  */
    if @p_activity_action_code = 'ERXFERPECP'  or
       @p_activity_action_code = 'ADD'         or
       @p_activity_action_code = 'HIREAPPL'    or
       @p_activity_action_code = 'HIREEMP'     or
       @p_activity_action_code = 'POPTADD'     or
       @p_activity_action_code = 'PTCPLOANAD'  or
       @p_activity_action_code = 'PTCPCLAIMA'  or
       @p_activity_action_code = 'PECGEPE'     or  /* R6.5.03M-ALS#28859 */
       @p_activity_action_code = 'REHIRE'      or  /* R6.5.03M-ALS#28859 */
       @p_activity_action_code = 'CHGEMPNE'    or  /* R7.0M-SOL#565937 */
       @p_activity_action_code = 'ERUNXFPECP'      /* FYI: can't find in any stored procedure. */
         begin
            insert into emp_pay_element_aud (ACTION_CODE, ACTION_USER,
                ACTION_DATETIME, B_emp_id, B_empl_id, B_pay_element_id,
                B_eff_date, A_emp_id, A_empl_id, A_pay_element_id,
                A_eff_date, A_prior_eff_date, A_next_eff_date,
                A_activated_by_pay_element_ind, A_start_date, A_stop_date,
                A_change_reason_code, A_y_element_pay_pd_sched_code,
                A_calc_meth_code, A_standard_calc_factor_1,
                A_standard_calc_factor_2, A_special_calc_factor_1,
                A_special_calc_factor_2, A_special_calc_factor_3,
                A_special_calc_factor_4, A_rate_tbl_id, A_rate_code,
                A_payee_name, A_payee_pmt_sched_code,
                A_payee_bank_transit_nbr, A_payee_bank_acct_nbr,
                A_pmt_ref_nbr, A_pmt_ref_name, A_vendor_id, A_limit_amt,
                A_guaranteed_net_pay_amt, A_start_after_pay_element_id,
                A_div_addr_type_to_print_code, A_bank_id,
                A_rect_deposit_bank_acct_nbr, A_bank_acct_type_code,
                A_y_pd_arrears_rec_fixed_amt, A_y_pd_arrears_rec_fixed_pct,
                A_min_pay_pd_recovery_amt, A_user_amt_1, A_user_amt_2,
                A_user_monetary_amt_1, A_user_monetary_amt_2,
                A_user_monetary_curr_code, A_user_code_1, A_user_code_2,
                A_user_date_1, A_user_date_2, A_user_ind_1, A_user_ind_2,
                A_user_text_1, A_user_text_2, A_pension_tot_distn_ind,
                A_pension_distn_code_1, A_pension_distn_code_2,
                A_pre_1990_rpp_ctrb_type_cd, A_chgstamp)
            select @p_activity_action_code, @p_user_id, @p_action_date,
	        @p_b_emp_id, @p_b_empl_id, @p_b_pay_element_id,
	        @p_b_eff_date, @p_a_emp_id, @p_a_empl_id,
                @p_a_pay_element_id, @p_a_eff_date, after.prior_eff_date,
	        after.next_eff_date, after.inactivated_by_pay_element_ind,
                after.start_date, after.stop_date, after.change_reason_code,
                after.pay_element_pay_pd_sched_code, after.calc_meth_code,
                after.standard_calc_factor_1, after.standard_calc_factor_2,
                after.special_calc_factor_1, after.special_calc_factor_2,
                after.special_calc_factor_3, after.special_calc_factor_4,
                after.rate_tbl_id, after.rate_code, after.payee_name,
	        after.payee_pmt_sched_code, after.payee_bank_transit_nbr,
 	        after.payee_bank_acct_nbr, after.pmt_ref_nbr,
                after.pmt_ref_name, after.vendor_id, after.limit_amt,
                after.guaranteed_net_pay_amt,
                after.start_after_pay_element_id,
                after.indiv_addr_type_to_print_code, after.bank_id,
	        after.direct_deposit_bank_acct_nbr,
                after.bank_acct_type_code,
                after.pay_pd_arrears_rec_fixed_amt,
                after.pay_pd_arrears_rec_fixed_pct,
                after.min_pay_pd_recovery_amt, after.user_amt_1,
                after.user_amt_2, after.user_monetary_amt_1,
                after.user_monetary_amt_2, after.user_monetary_curr_code,
                after.user_code_1, after.user_code_2, after.user_date_1,
	        after.user_date_2, after.user_ind_1, after.user_ind_2,
                after.user_text_1, after.user_text_2,
                after.pension_tot_distn_ind, after.pension_distn_code_1,
                after.pension_distn_code_2, after.pre_1990_rpp_ctrb_type_cd,
	        after.chgstamp
            from emp_pay_element after
            where after.emp_id           = @p_a_emp_id
	        and after.empl_id        = @p_a_empl_id
	        and after.pay_element_id = @p_a_pay_element_id
	        and after.eff_date       = @p_a_eff_date
            return
        end

    /*  Insert where after is null.  */
    if @p_activity_action_code = 'ERXFERPEDL'  or
       @p_activity_action_code = 'ERUNXFPEDL'  or
       @p_activity_action_code = 'REVTRMPEDV'  or
       @p_activity_action_code = 'REVTRMSTPE'  or
       @p_activity_action_code = 'CHGEMPPYEQ'  or
       @p_activity_action_code = 'TERMDELPE'   or
       @p_activity_action_code = 'REHIREDEL'   or
       @p_activity_action_code = 'POPTCHGEQ'   or
       @p_activity_action_code = 'PTCPDELPE'   or  /* R6.5.02MCEXP-ALS#523706 */
       @p_activity_action_code = 'TERMEMPDEL'  or  /* R6.5.02MCEXP-ALS#523706 */
       @p_activity_action_code = 'DELETE'      or
       @p_activity_action_code = 'POPTUNCDEL'  or
       @p_activity_action_code = 'PTCPLOANDL'  or
       @p_activity_action_code = 'PTCPCLAIMD'  or
       @p_activity_action_code = 'POPTDELETE' 
         begin
            insert into emp_pay_element_aud (ACTION_CODE, ACTION_USER,
                ACTION_DATETIME, B_emp_id, B_empl_id, B_pay_element_id,
                B_eff_date, B_prior_eff_date, B_next_eff_date,
                B_activated_by_pay_element_ind, B_start_date, B_stop_date,
                B_change_reason_code, B_y_element_pay_pd_sched_code,
                B_calc_meth_code, B_standard_calc_factor_1,
                B_standard_calc_factor_2, B_special_calc_factor_1,
                B_special_calc_factor_2, B_special_calc_factor_3,
                B_special_calc_factor_4, B_rate_tbl_id, B_rate_code,
                B_payee_name, B_payee_pmt_sched_code,
                B_payee_bank_transit_nbr, B_payee_bank_acct_nbr,
                B_pmt_ref_nbr, B_pmt_ref_name, B_vendor_id, B_limit_amt,
                B_guaranteed_net_pay_amt, B_start_after_pay_element_id,
                B_div_addr_type_to_print_code, B_bank_id,
                B_rect_deposit_bank_acct_nbr, B_bank_acct_type_code,
                B_y_pd_arrears_rec_fixed_amt, B_y_pd_arrears_rec_fixed_pct,
                B_min_pay_pd_recovery_amt, B_user_amt_1, B_user_amt_2,
                B_user_monetary_amt_1, B_user_monetary_amt_2,
                B_user_monetary_curr_code, B_user_code_1, B_user_code_2,
                B_user_date_1, B_user_date_2, B_user_ind_1, B_user_ind_2,
                B_user_text_1, B_user_text_2, B_pension_tot_distn_ind,
                B_pension_distn_code_1, B_pension_distn_code_2,
                B_pre_1990_rpp_ctrb_type_cd, B_chgstamp,
                A_emp_id, A_empl_id, A_pay_element_id, A_eff_date,
                DBS_INTERFACE_EXTRACT_DATE, USER_INTERFACE_EXTRACT_DATE)
            select @p_activity_action_code, @p_user_id, @p_action_date,
	        @p_b_emp_id, @p_b_empl_id, @p_b_pay_element_id,
	        @p_b_eff_date, before.prior_eff_date,
	        before.next_eff_date, before.inactivated_by_pay_element_ind,
                before.start_date, before.stop_date, before.change_reason_code,
                before.pay_element_pay_pd_sched_code, before.calc_meth_code,
                before.standard_calc_factor_1, before.standard_calc_factor_2,
                before.special_calc_factor_1, before.special_calc_factor_2,
                before.special_calc_factor_3, before.special_calc_factor_4,
                before.rate_tbl_id, before.rate_code, before.payee_name,
	        before.payee_pmt_sched_code, before.payee_bank_transit_nbr,
 	        before.payee_bank_acct_nbr, before.pmt_ref_nbr,
                before.pmt_ref_name, before.vendor_id, before.limit_amt,
                before.guaranteed_net_pay_amt,
                before.start_after_pay_element_id,
                before.indiv_addr_type_to_print_code, before.bank_id,
	        before.direct_deposit_bank_acct_nbr,
                before.bank_acct_type_code,
                before.pay_pd_arrears_rec_fixed_amt,
                before.pay_pd_arrears_rec_fixed_pct,
                before.min_pay_pd_recovery_amt, before.user_amt_1,
                before.user_amt_2, before.user_monetary_amt_1,
                before.user_monetary_amt_2, before.user_monetary_curr_code,
                before.user_code_1, before.user_code_2, before.user_date_1,
	        before.user_date_2, before.user_ind_1, before.user_ind_2,
                before.user_text_1, before.user_text_2,
                before.pension_tot_distn_ind, before.pension_distn_code_1,
                before.pension_distn_code_2, before.pre_1990_rpp_ctrb_type_cd,
	        before.chgstamp, @p_a_emp_id, @p_a_empl_id,
                @p_a_pay_element_id, @p_a_eff_date, null, null
            from emp_pay_element before
           where before.emp_id         = @p_b_emp_id
	     and before.empl_id        = @p_b_empl_id
	     and before.pay_element_id = @p_b_pay_element_id
	     and before.eff_date       = @p_b_eff_date
           return
         end

    /* R7.0M-ALS#567582: Begin */
    /* Put this here because pay_element_pay_pd_sched_code   */
    /* isn't passed and more than one row could be affected. */             
    if @p_activity_action_code = 'EPHDELPMT'
         select @w_pay_elmt_pay_pd_sched_code = "11"
    else 
         select @w_pay_elmt_pay_pd_sched_code = after.pay_element_pay_pd_sched_code
           from emp_pay_element after
          where after.emp_id          = @p_a_emp_id
	    and after.empl_id         = @p_a_empl_id
	    and after.pay_element_id  = @p_a_pay_element_id
	    and after.eff_date        = @p_a_eff_date
    /* R7.0M-ALS#567582: End */

    /*  Insert with different before and after.  */
    if @p_activity_action_code = 'ERXFERPEDV'  or
       @p_activity_action_code = 'DELETEVER'   or
       @p_activity_action_code = 'REACTIVATE'  or
       @p_activity_action_code = 'CHGEMPPYNE'  or
       @p_activity_action_code = 'POPTCHGNE'   or
       @p_activity_action_code = 'EPHDELPMT'      /* R7.0M-ALS#567582 */  
        begin
            insert into emp_pay_element_aud
            select @p_activity_action_code, @p_user_id, @p_action_date,
	        @p_b_emp_id, @p_b_empl_id, @p_b_pay_element_id,
	        @p_b_eff_date, before.prior_eff_date,
	        before.next_eff_date, before.inactivated_by_pay_element_ind,
                before.start_date, before.stop_date, before.change_reason_code,
                before.pay_element_pay_pd_sched_code, before.calc_meth_code,
                before.standard_calc_factor_1, before.standard_calc_factor_2,
                before.special_calc_factor_1, before.special_calc_factor_2,
                before.special_calc_factor_3, before.special_calc_factor_4,
                before.rate_tbl_id, before.rate_code, before.payee_name,
	        before.payee_pmt_sched_code, before.payee_bank_transit_nbr,
 	        before.payee_bank_acct_nbr, before.pmt_ref_nbr,
                before.pmt_ref_name, before.vendor_id, before.limit_amt,
                before.guaranteed_net_pay_amt,
                before.start_after_pay_element_id,
                before.indiv_addr_type_to_print_code, before.bank_id,
	        before.direct_deposit_bank_acct_nbr,
                before.bank_acct_type_code,
                before.pay_pd_arrears_rec_fixed_amt,
                before.pay_pd_arrears_rec_fixed_pct,
                before.min_pay_pd_recovery_amt, before.user_amt_1,
                before.user_amt_2, before.user_monetary_amt_1,
                before.user_monetary_amt_2, before.user_monetary_curr_code,
                before.user_code_1, before.user_code_2, before.user_date_1,
	        before.user_date_2, before.user_ind_1, before.user_ind_2,
                before.user_text_1, before.user_text_2,
                before.pension_tot_distn_ind, before.pension_distn_code_1,
                before.pension_distn_code_2, before.pre_1990_rpp_ctrb_type_cd,
	        before.chgstamp, @p_a_emp_id, @p_a_empl_id,
                @p_a_pay_element_id, @p_a_eff_date, after.prior_eff_date,
	        after.next_eff_date, after.inactivated_by_pay_element_ind,
                after.start_date, after.stop_date, after.change_reason_code,
                @w_pay_elmt_pay_pd_sched_code, after.calc_meth_code,   /* after.pay_element_pay_pd_sched_code */
                after.standard_calc_factor_1, after.standard_calc_factor_2,
                after.special_calc_factor_1, after.special_calc_factor_2,
                after.special_calc_factor_3, after.special_calc_factor_4,
                after.rate_tbl_id, after.rate_code, after.payee_name,
	        after.payee_pmt_sched_code, after.payee_bank_transit_nbr,
 	        after.payee_bank_acct_nbr, after.pmt_ref_nbr,
                after.pmt_ref_name, after.vendor_id, after.limit_amt,
                after.guaranteed_net_pay_amt,
                after.start_after_pay_element_id,
                after.indiv_addr_type_to_print_code, after.bank_id,
	        after.direct_deposit_bank_acct_nbr,
                after.bank_acct_type_code,
                after.pay_pd_arrears_rec_fixed_amt,
                after.pay_pd_arrears_rec_fixed_pct,
                after.min_pay_pd_recovery_amt, after.user_amt_1,
                after.user_amt_2, after.user_monetary_amt_1,
                after.user_monetary_amt_2, after.user_monetary_curr_code,
                after.user_code_1, after.user_code_2, after.user_date_1,
	        after.user_date_2, after.user_ind_1, after.user_ind_2,
                after.user_text_1, after.user_text_2,
                after.pension_tot_distn_ind, after.pension_distn_code_1,
                after.pension_distn_code_2, after.pre_1990_rpp_ctrb_type_cd,
	        after.chgstamp, null, null
            from emp_pay_element before, emp_pay_element after
           where before.emp_id         = @p_b_emp_id
	     and before.empl_id        = @p_b_empl_id
	     and before.pay_element_id = @p_b_pay_element_id
	     and before.eff_date       = @p_b_eff_date
	     and after.emp_id          = @p_a_emp_id
	     and after.empl_id         = @p_a_empl_id
	     and after.pay_element_id  = @p_a_pay_element_id
	     and after.eff_date        = @p_a_eff_date
           return
        end

    /*  Insert where the before and after are essentially the same  */
    if @p_activity_action_code = 'PTCPUDPENX'  or  /* R6.5.02MCEXP-ALS#523706 */
       @p_activity_action_code = 'CHGVEREFF'   or
       @p_activity_action_code = 'POPTCHGVER'  or 
       @p_activity_action_code = 'CHGSTARTDT'  or
       @p_activity_action_code = 'REVHIRE'     or
       @p_activity_action_code = 'REVREHIRE'   or
       @p_activity_action_code = 'POPTCHGSTR'  or
       @p_activity_action_code = 'INACTIVATE'  or
       @p_activity_action_code = 'POPTSTOP'    or
       @p_activity_action_code = 'PTCPTERM'    or
       @p_activity_action_code = 'BPOPTSTOP'   or
       @p_activity_action_code = 'TERMSTOPPE'  or
       @p_activity_action_code = 'DELSTOPDT'   or  /* R6.5.03M-ALS#28859: missing */
       @p_activity_action_code = 'CHGSTOPDT'   or
       @p_activity_action_code = 'PTCPDELTRM'  or  /* R6.5.02MC-ALS#521145 */
       @p_activity_action_code = 'ERXFERPESP'  
         begin
            insert into emp_pay_element_aud
            select @p_activity_action_code, @p_user_id, @p_action_date,
	        @p_b_emp_id, @p_b_empl_id, @p_b_pay_element_id,
	        @p_b_eff_date, before.prior_eff_date,
	        before.next_eff_date, before.inactivated_by_pay_element_ind,
                before.start_date, before.stop_date, before.change_reason_code,
                before.pay_element_pay_pd_sched_code, before.calc_meth_code,
                before.standard_calc_factor_1, before.standard_calc_factor_2,
                before.special_calc_factor_1, before.special_calc_factor_2,
                before.special_calc_factor_3, before.special_calc_factor_4,
                before.rate_tbl_id, before.rate_code, before.payee_name,
	        before.payee_pmt_sched_code, before.payee_bank_transit_nbr,
 	        before.payee_bank_acct_nbr, before.pmt_ref_nbr,
                before.pmt_ref_name, before.vendor_id, before.limit_amt,
                before.guaranteed_net_pay_amt,
                before.start_after_pay_element_id,
                before.indiv_addr_type_to_print_code, before.bank_id,
	        before.direct_deposit_bank_acct_nbr,
                before.bank_acct_type_code,
                before.pay_pd_arrears_rec_fixed_amt,
                before.pay_pd_arrears_rec_fixed_pct,
                before.min_pay_pd_recovery_amt, before.user_amt_1,
                before.user_amt_2, before.user_monetary_amt_1,
                before.user_monetary_amt_2, before.user_monetary_curr_code,
                before.user_code_1, before.user_code_2, before.user_date_1,
	        before.user_date_2, before.user_ind_1, before.user_ind_2,
                before.user_text_1, before.user_text_2,
                before.pension_tot_distn_ind, before.pension_distn_code_1,
                before.pension_distn_code_2, before.pre_1990_rpp_ctrb_type_cd,
	        before.chgstamp, @p_a_emp_id, @p_a_empl_id,
                @p_a_pay_element_id, @p_a_eff_date, before.prior_eff_date,
	        @p_next_eff_date, @p_inactivated_by_pay_el_in,
                @p_new_start_date, @p_new_stop_date, before.change_reason_code,
                before.pay_element_pay_pd_sched_code, before.calc_meth_code,
                before.standard_calc_factor_1, before.standard_calc_factor_2,
                before.special_calc_factor_1, before.special_calc_factor_2,
                before.special_calc_factor_3, before.special_calc_factor_4,
                before.rate_tbl_id, before.rate_code, before.payee_name,
	        before.payee_pmt_sched_code, before.payee_bank_transit_nbr,
 	        before.payee_bank_acct_nbr, before.pmt_ref_nbr,
                before.pmt_ref_name, before.vendor_id, before.limit_amt,
                before.guaranteed_net_pay_amt,
                before.start_after_pay_element_id,
                before.indiv_addr_type_to_print_code, before.bank_id,
	        before.direct_deposit_bank_acct_nbr,
                before.bank_acct_type_code,
                before.pay_pd_arrears_rec_fixed_amt,
                before.pay_pd_arrears_rec_fixed_pct,
                before.min_pay_pd_recovery_amt, before.user_amt_1,
                before.user_amt_2, before.user_monetary_amt_1,
                before.user_monetary_amt_2, before.user_monetary_curr_code,
                before.user_code_1, before.user_code_2, before.user_date_1,
	        before.user_date_2, before.user_ind_1, before.user_ind_2,
                before.user_text_1, before.user_text_2,
                before.pension_tot_distn_ind, before.pension_distn_code_1,
                before.pension_distn_code_2, before.pre_1990_rpp_ctrb_type_cd,
	        before.chgstamp, null, null
            from emp_pay_element before
           where before.emp_id         = @p_b_emp_id
	     and before.empl_id        = @p_b_empl_id
	     and before.pay_element_id = @p_b_pay_element_id
	     and before.eff_date       = @p_b_eff_date
           return
         end
end
 

 
GO
ALTER AUTHORIZATION ON [dbo].[usp_ins_hepy_audit] TO  SCHEMA OWNER 
GO
