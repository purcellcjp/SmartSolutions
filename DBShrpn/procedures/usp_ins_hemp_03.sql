USE [DBShrpn]
GO
/****** Object:  StoredProcedure [dbo].[usp_ins_hemp_03]    Script Date: 4/1/2025 4:33:00 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO




CREATE procedure [dbo].[usp_ins_hemp_03](
    @p_employer_taxing_ctry_code char(2),
    @p_employer_id               char(10),
    @p_employee_id               char(15),
    @p_pay_element_ctrl_grp      char(10),
    @p_original_hire_date        datetime,
    @p_pensioner_indicator       char(1),
    @p_autopay_pay_element_id    char(10),
    @p_rc                        int OUTPUT)

as
/*----------------------------------------------------------------------*/
/*  Authenticate the use of this stored procedure                       */
/*----------------------------------------------------------------------*/

declare @ret int
--execute @ret = sp_dbs_authenticate if @ret != 0 return

/*============================================================*/
/*Cursor used for inserting pay elements to be established on */
/*hire, based on pay element control group.                   */
/*The cursor is dependent on the taxing country and whether   */
/*the employee being hired has been designated as a pentioner.*/
/*In the U.S., the only earnings established for new hires    */
/*that are pensioners are pension earnings.  In Canada, all   */
/*earnings are established even if new employee is a pensioner*/
/*============================================================*/
Declare @w_pay_element_id           char(10),
        @w_deduction_type_code      char(1),
        @w_calc_method              char(02),
        @w_schedule_code            char(02),
        @w_std_calc_factor_1        money,
        @w_std_calc_factor_2        money,
        @w_limit_amt                money,
        @w_limit_cycle_type_code    char(1), /* 557375 */
        @w_start_date               datetime,
        @w_stop_date                datetime,
        @w_next_eff_date            datetime,
    	@w_inact_by_pay_element_ind char(1),
        @w_direct_deposit_ind       char(1),
        @w_prenote_code             char(1),
        @w_rate_tbl_id              char(10)

if @p_employer_taxing_ctry_code = "US" and @p_pensioner_indicator = 'N'
    Declare pay_element_hire cursor
        For Select DISTINCT hpge.pay_element_id,
               hpay.deduction_type_code,
               hpay.calc_meth_code,
               hpay.pay_pd_sched_code,
               hpay.rate_tbl_id,
               hpay.standard_calc_factor_1,
               hpay.standard_calc_factor_2,
               hpay.start_date,
               hpay.stop_date,
               hpay.next_eff_date,
               hpay.limit_amt,
               hpay.limit_cycle_type_code /* 557375 */
        From pay_element_ctrl_grp_entry hpge, pay_element hpay
        Where hpge.pay_element_ctrl_grp_id = @p_pay_element_ctrl_grp and
              hpge.pay_element_id          = hpay.pay_element_id     and
              hpge.establish_on_hire_ind   = "Y"                     and
              hpay.eff_date               <= @p_original_hire_date   and
              hpay.next_eff_date           > @p_original_hire_date   and
              hpay.start_date             <= @p_original_hire_date   and
              hpay.stop_date               > @p_original_hire_date   and
              (hpay.earn_type_code        <> "6")
else
/*Declare cursor to select pay element info for CANADA*/
    Declare pay_element_hire cursor
    For Select DISTINCT hpge.pay_element_id,
               hpay.deduction_type_code,
               hpay.calc_meth_code,
               hpay.pay_pd_sched_code,
               hpay.rate_tbl_id,
               hpay.standard_calc_factor_1,
               hpay.standard_calc_factor_2,
               hpay.start_date,
               hpay.stop_date,
               hpay.next_eff_date,
               hpay.limit_amt,
               hpay.limit_cycle_type_code /* 557375 */
            From pay_element_ctrl_grp_entry hpge, pay_element hpay
            Where hpge.pay_element_ctrl_grp_id = @p_pay_element_ctrl_grp and
                  hpge.pay_element_id          = hpay.pay_element_id     and
                  hpge.establish_on_hire_ind   = "Y"                     and
                  hpay.eff_date               <= @p_original_hire_date   and
                  hpay.next_eff_date           > @p_original_hire_date   and
                  hpay.start_date             <= @p_original_hire_date   and
                  hpay.stop_date               > @p_original_hire_date

/*OPEN CURSOR*/
Open pay_element_hire
/*FETCH THE FIRST RECORD*/
Fetch pay_element_hire Into
    @w_pay_element_id,
    @w_deduction_type_code,
    @w_calc_method,
    @w_schedule_code,
    @w_rate_tbl_id,
    @w_std_calc_factor_1,
    @w_std_calc_factor_2,
    @w_start_date,
    @w_stop_date,
    @w_next_eff_date,
    @w_limit_amt,
    @w_limit_cycle_type_code /* 557375 */

If ( @@fetch_status = 1 )
    Begin
        Select @p_rc = 1
        close pay_element_hire
        deallocate pay_element_hire
        return
    End

Select @w_direct_deposit_ind = "N"

While ( @@fetch_status = 0 )
/*Start processing each record selected in the CURSOR*/
    Begin
        if @p_autopay_pay_element_id <> @w_pay_element_id
        Begin
        if @w_start_date < = @p_original_hire_date
            Select @w_start_date = @p_original_hire_date

       if @w_stop_date = "12/31/2999"
            Begin
                Select @w_inact_by_pay_element_ind = "N"
                if @w_next_eff_date = "12/31/2999"
                    Select @w_stop_date = stop_date
                    From pay_element
                    Where pay_element_id = @w_pay_element_id and
                          next_eff_date  = "12/31/2999"
            End
        else
            Select @w_inact_by_pay_element_ind = "Y"

         if @w_calc_method = '01' or
            @w_calc_method = '02' or
            @w_calc_method = '04' or
            @w_calc_method = '06' or
            @w_calc_method = '13' or
            @w_calc_method = '14' or
            @w_calc_method = '17' or
            @w_calc_method = '18' or
            @w_calc_method = '19' or
            @w_calc_method = '21' or
            @w_calc_method = '22' or
            @w_calc_method = '25'
            Begin
            if @w_std_calc_factor_1 = 0
                Select @w_schedule_code = '00'
            else
                Select @w_schedule_code = ''
            End
         else if @w_calc_method = '03' or
                @w_calc_method = '05' or
                @w_calc_method = '23' or
                @w_calc_method = '24'
            Begin
            if @w_std_calc_factor_1 = 0 or @w_std_calc_factor_2 = 0
                Select @w_schedule_code = '00'
            else
                Select @w_schedule_code = ''
            End
         else if @w_calc_method = '07' or
                @w_calc_method = '08' or
                @w_calc_method = '09' or
                @w_calc_method = '10' or
                @w_calc_method = '11' or
                @w_calc_method = '12' or
                @w_calc_method = '15' or
                @w_calc_method = '16' or
                @w_calc_method = '20'
            Begin
                Select @w_schedule_code = '00'
            End
        else
            Select @w_schedule_code = ''

        /* Sol#524177 -  Reset Employee Pay Element Fields which Default From Policy Pay Element 
           Note: the following code is necessary to insure the Policy Pay Element Values are
                 defaulted to the Employee Pay Element                                       */
        
        /* select @w_limit_amt = 0  Sol#524177  deleted with 557375 */
 
        /*Insert data into emp_pay_element*/
         Insert Into emp_pay_element(
            emp_id,
            empl_id,
            pay_element_id,
            eff_date,
            prior_eff_date,
            next_eff_date,
            inactivated_by_pay_element_ind,
            start_date,
            stop_date,
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
            first_roth_ctrb,                    /* r71m-578919 in 576240 */  
            ira_sep_simple_ind,                 /* r71m-581591 in 582025 */ 
            taxable_amt_not_determined_ind)     /* r71m-581591 in 582025 */ 
        Values(
            @p_employee_id,
            @p_employer_id,
            @w_pay_element_id,
            @p_original_hire_date,
            "12/31/2999",
            "12/31/2999",
            @w_inact_by_pay_element_ind,
            @w_start_date,
            @w_stop_date,
            "",
            @w_schedule_code,
            "",
            0,
            0,
            0,
            0,
            0,
            0,
            @w_rate_tbl_id,
            "","","","",
            "","","","",
            0, /* @w_limit_amt, 557375 */
            0,
            "","","","","",
            0,0,0,0,0,0,0,
            "","","",
            "12/31/2999",
            "12/31/2999",
            "N","N","","","N",
            "","","",
            0, 
            "12/31/2999",  /* r71m-578919 in 576240 */ 
            "N","N")       /* r71m-581591 in 582025 */ 

        if @@error <> 0
	    Begin
	        Select @p_rc = -1
            close pay_element_hire
            deallocate pay_element_hire
           	return
    	End
        if @w_deduction_type_code = "3"
            Select @w_prenote_code = "4",
                   @w_direct_deposit_ind = "Y"
        else
            Select @w_prenote_code = ""

        Insert Into emp_pay_element_non_dtd
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
        Values(@p_employee_id,
               @p_employer_id,
               @w_pay_element_id,
               0, 0, "9", "N",
               "12/31/2999",
               @w_prenote_code,
               0)
        if @@error <> 0
	        Begin
	            Select @p_rc = -1
                close pay_element_hire
                deallocate pay_element_hire
           	    return
    	    End

--      if @w_limit_amt <> 0 /* 557375 */
        if @w_limit_cycle_type_code = '2' /* other cycle type */ /* 557375 */
            Insert Into emp_pay_element_limit
                (emp_id,
                 empl_id,
                 pay_element_id,
                 start_date,
                 towards_the_limit_amt,
                 chgstamp)
            Values
                (@p_employee_id,
                 @p_employer_id,
                 @w_pay_element_id,
                 @w_start_date,
                 0,0)
        End
        /*Fetch next record*/
        Fetch pay_element_hire Into
            @w_pay_element_id,
            @w_deduction_type_code,
            @w_calc_method,
            @w_schedule_code,
            @w_rate_tbl_id,
            @w_std_calc_factor_1,
            @w_std_calc_factor_2,
            @w_start_date,
            @w_stop_date,
            @w_next_eff_date,
            @w_limit_amt,
            @w_limit_cycle_type_code /* 557375 */

End  /*END WHILE LOOP*/

close pay_element_hire
deallocate pay_element_hire

if @w_direct_deposit_ind = "Y"
    Select @p_rc = 50436
else
    Select @p_rc = 1
 

 
GO
ALTER AUTHORIZATION ON [dbo].[usp_ins_hemp_03] TO  SCHEMA OWNER 
GO
