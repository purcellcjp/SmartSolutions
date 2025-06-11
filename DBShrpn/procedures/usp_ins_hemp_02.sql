USE [DBShrpn]
GO
/****** Object:  StoredProcedure [dbo].[usp_ins_hemp_02]    Script Date: 4/1/2025 4:33:00 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO




CREATE procedure [dbo].[usp_ins_hemp_02](
        @p_employer_taxing_ctry_code    char(2),
        @p_employer_id                  char(10),
        @p_employee_id                  char(15),
        @p_income_tax_stat_code         char(1),
        @p_ei_status_code               char(1),
        @p_ppip_status_code             char(1), /* 566986 */
        @p_fed_pp_stat_code             char(1),
        @p_tax_authority_id             char(10),
 /*     @p_qit_stat_code                char(1),  R6.0 SSA 165213 */
	@p_pit_stat_code                char(1), /* R6.0 SSA 165213 */
        @p_provincial_pp_stat_code      char(1),
        @p_autopay_pay_element_id       char(10),
        @p_autopay_rtn                  int,
        @p_original_hire_date           datetime,
        @p_inact_by_pay_element_ind     char(1),
        @p_stop_date                    datetime,
        @p_pay_element_ctrl_grp         char(10),
        @p_pensioner_indicator          char(1),
        @p_auto_rt_tbl_id               char(10),
        @p_rc                           int OUTPUT,
        @p_ret_mess                     varchar(50) OUTPUT)
as
/*----------------------------------------------------------------------*/
/*  Authenticate the use of this stored procedure                       */
/*----------------------------------------------------------------------*/

declare @ret int
--execute @ret = sp_dbs_authenticate if @ret != 0 return 

select @p_rc = 1

Declare @w_other_prov_tax_1_stat_code char(1),
        @w_fed_basic_amount           money,
  /*    @w_quebec_basic_amt           money   	R6.0M SSA 165213 */
        @w_provincial_basic_amt       money   /*R6.0M SSA 165213 */
       ,@w_hlth_ctrb_status_code      char(1) /* kb 1383272 - def 393072 */

    
if @p_employer_taxing_ctry_code = 'CA' 
    if not exists (Select tax_authority_id 
                   From empl_canadian_tax_authority
                   Where empl_id                     = @p_employer_id and
                         tax_authority_id = 'CANFED' and 
                         empl_can_tax_auth_status_cd = '1') 
       Select @p_rc = 50438
    else
/* ==================================================================== */
/*   --  Insert the emp_can_tax_authority data                          */
/* ==================================================================== */
    Begin
/* R6.0.03 SSA 165213 Begin */   
	if exists(Select inc_tax_basic_amt 
                  from canadian_standard_tax_credits
		  where tax_authority_id  = 'CANFED')
         Begin
		Select @w_fed_basic_amount = inc_tax_basic_amt
        	from canadian_standard_tax_credits
		where tax_authority_id  = 'CANFED'
         End 
	else
                Select @w_fed_basic_amount = 0

	if exists(Select pit_basic_amt 
                  from canadian_standard_tax_credits
		  where tax_authority_id  = @p_tax_authority_id)
         Begin
 		Select @w_provincial_basic_amt = pit_basic_amt
		from canadian_standard_tax_credits
		where tax_authority_id  = @p_tax_authority_id
         End 
	else
	          Select @w_provincial_basic_amt = 0

	if (@p_income_tax_stat_code != '2' and
           @p_income_tax_stat_code != '3')
               Select @w_fed_basic_amount = 0

	if (@p_pit_stat_code != '2' and
           @p_pit_stat_code != '3')
   /* kb 1383272 - def 393072 begin */
    begin
	   Select @w_provincial_basic_amt = 0
      if @p_tax_authority_id = 'QC'
         Select @w_hlth_ctrb_status_code = '1'
    end
   else
    begin
     if @p_tax_authority_id = 'QC'
        Select @w_hlth_ctrb_status_code = '2'
    end    
   /* kb 1383272 - def 393072 end */

 /*     @w_quebec_basic_amt = qit_basic_amt  			R6.0 SSA 165213 */
 /*       From canadian_standard_tax_credits			R6.0 SSA 165213 */
/* R6.0.03 SSA 165213 End */ 
        Insert into emp_can_tax_authority
        (emp_id,
             empl_id,
             tax_authority_id,
             emp_can_tax_auth_status_cd,
             inc_tax_status_code,
             inc_tax_adj_code,
             inc_tax_adj_amt,
             inc_tax_adj_pct,
             tot_estd_remuneration_amt,
             tot_estimated_expense_amt,
             inc_tax_basic_amt,
             inc_tax_spousal_disabled_amt,
             inc_tax_depn_relative_amt,
             inc_tax_eligible_pens_inc_amt,
             inc_tax_age_amt,
             inc_tax_tuition_fees_educ_amt,
             inc_tax_disability_amt,
             inc_tax_transferred_amt,
             inc_tax_tot_claim_amt,
             inc_tax_ded_dsgnd_liv_area_amt,
             inc_tax_auth_annual_ded_amt,
             inc_tax_other_tax_cr_amt,
             canadian_status_indian_ind,
             ei_status_code,
             pit_basic_amt,
             pit_spouse_support_amt,
             pit_dependent_children_amt,
             pit_other_dependent_amt,
             pit_domestic_estab_amt,
             pit_age_amt,
             unused_amt_1,
             unused_amt_2,
             pit_retmt_income_amt,
             pit_family_amt,
             unused_amt_3,
             pit_tot_claim_amt,
             pit_other_deds_amt,
             pit_other_tax_cr_amt,
             primary_province_ind,
             sales_tax_status_code,
             lbr_sponsored_fund_tax_cr_amt,
             pp_status_code,
             other_provincial_tax_1_stat_cd,
             other_provincial_tax_2_stat_cd,
             other_provincial_tax_3_stat_cd,
             nbr_of_days_wrkd_os_canada,
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
	     /* R6.0M SSA 165213 new columns added to table */
             inc_tax_caregiver_amt,
	     pit_disability_amt,
             pit_transferred_amt,	
             /* R6.0M SSA 165213 End */	
	     chgstamp
             ,ppip_status_code /* 566986 */
             ,inc_tax_infirm_depn_amt        /* 585743 */
             ,inc_tax_child_amt              /* 585743 */
             ,inc_tax_transferred_depn_amt   /* 585743 */
             ,cpp_election_code         --1061321 [delivered in 2011 reg pack 1012803]
             ,cpp_election_date         --1061321 [delivered in 2011 reg pack 1012803]
             ,prev_cpp_election_code    --1061321 [delivered in 2011 reg pack 1012803]
             ,prev_cpp_election_date    --1061321 [delivered in 2011 reg pack 1012803]
			 ,rcv_pp_pension_ind        --1118754 def341775 
  )

        values (@p_employee_id,
             	@p_employer_id,
          	'CANFED',
        	'1',
		@p_income_tax_stat_code,
        	'1',
        	0,0,0,0,
             	@w_fed_basic_amount,
             	0,0,0,
             	0,0,0,0,
             	@w_fed_basic_amount,
             	0,0,0,
            	'N',
             	@p_ei_status_code,
             	0,0,0,0,0,0,0,0,
             	0,0,0,0,0,0,
             	' ',' ',
             	0,
             	@p_fed_pp_stat_code,
             	'1','1','1',
             	0,0,0,0,0,
             	' ',' ',' ',
             	'12/31/2999',
             	'12/31/2999',
             	'N','N',
             	' ',' ',
             	/* R6.0M SSA 165213 new columns added to table */
             	0,
	     	0,
             	0,	
             	/* R6.0M SSA 165213 End */	
	     	0
             	,'1' /* @p_ppip_status_code = 1 for CANFED 566986 */
                ,0   /* inc_tax_infirm_depn_amt         585743 */
                ,0   /* inc_tax_child_amt               585743 */
                ,0   /* inc_tax_transferred_depn_amt    585743 */
                ,'0'           --cpp_election_code      1061321 [delivered in 2011 reg pack 1012803]
                ,'12/31/2999'  --cpp_election_date      1061321 [delivered in 2011 reg pack 1012803]
                ,'0'           --prev_cpp_election_code 1061321 [delivered in 2011 reg pack 1012803]
                ,'12/31/2999'  --prev_cpp_election_date 1061321 [delivered in 2011 reg pack 1012803]
				,'N'           --rcv_pp_pension_ind     1118754 def341775 
             	)

if @@error <> 0 
    Begin
        Select @p_rc       = 500014
        Select @p_ret_mess = 'Error on emp_can_tax_authority for FED'
return
    End

    if (rtrim(@p_tax_authority_id) IS NOT NULL AND rtrim(@p_tax_authority_id)!='')    
        Begin
            if @p_tax_authority_id = 'QC' or @p_tax_authority_id = 'NT' or 
			@p_tax_authority_id = 'NN'
                Select @w_other_prov_tax_1_stat_code = '2'
            else
                Select @w_other_prov_tax_1_stat_code = '1'

        Insert into emp_can_tax_authority
            (emp_id,
             empl_id,
             tax_authority_id,
             emp_can_tax_auth_status_cd,
             inc_tax_status_code,
             inc_tax_adj_code,
             inc_tax_adj_amt,
             inc_tax_adj_pct,
             tot_estd_remuneration_amt,
             tot_estimated_expense_amt,
             inc_tax_basic_amt,
             inc_tax_spousal_disabled_amt,
             inc_tax_depn_relative_amt,
             inc_tax_eligible_pens_inc_amt,
             inc_tax_age_amt,
             inc_tax_tuition_fees_educ_amt,
             inc_tax_disability_amt,
             inc_tax_transferred_amt,
             inc_tax_tot_claim_amt,
             inc_tax_ded_dsgnd_liv_area_amt,
             inc_tax_auth_annual_ded_amt,
             inc_tax_other_tax_cr_amt,
             canadian_status_indian_ind,
             ei_status_code,
             pit_basic_amt,
             pit_spouse_support_amt,
             pit_dependent_children_amt,
             pit_other_dependent_amt,
             pit_domestic_estab_amt,
             pit_age_amt,
             unused_amt_1,
             unused_amt_2,
             pit_retmt_income_amt,
             pit_family_amt,
             unused_amt_3,
             pit_tot_claim_amt,
             pit_other_deds_amt,
             pit_other_tax_cr_amt,
             primary_province_ind,
             sales_tax_status_code,
             lbr_sponsored_fund_tax_cr_amt,
             pp_status_code,
             other_provincial_tax_1_stat_cd,
             other_provincial_tax_2_stat_cd,
             other_provincial_tax_3_stat_cd,
             nbr_of_days_wrkd_os_canada,
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
             /* R6.0M SSA 165213 new columns added to table */
             inc_tax_caregiver_amt,
	     pit_disability_amt,
             pit_transferred_amt,	
             /* R6.0M SSA 165213 End */	   
             chgstamp
             ,ppip_status_code /* 566986 */
             ,inc_tax_infirm_depn_amt        /* 585743 */
             ,inc_tax_child_amt              /* 585743 */
             ,inc_tax_transferred_depn_amt   /* 585743 */
             ,cpp_election_code         --1061321 [delivered in 2011 reg pack 1012803]
             ,cpp_election_date         --1061321 [delivered in 2011 reg pack 1012803]
             ,prev_cpp_election_code    --1061321 [delivered in 2011 reg pack 1012803]
             ,prev_cpp_election_date    --1061321 [delivered in 2011 reg pack 1012803]
			 ,rcv_pp_pension_ind        --1118754 def341775
             ,hlth_ctrb_status_code      /* kb 1383272 - def 393072 */
  )

        values (@p_employee_id,
             	@p_employer_id,
          	@p_tax_authority_id,
        	'1',
		@p_pit_stat_code,
        	'1',
        	0,0,0,0,0,0,0,0,
             	0,0,0,0,0,0,0,0,
             	' ',
             	'1',
        	/*   @w_quebec_basic_amt,  	R6.0M SSA 165213 */
             	@w_provincial_basic_amt,	/*R6.0M SSA 165213 */
             	0,0,0,0,0,0,0,0,0,0,
        	/*   @w_quebec_basic_amt,   	R6.0M SSA 165213 */
	     	@w_provincial_basic_amt,	/*R6.0M SSA 165213 */
             	0,0,
             	'Y','2',
             	0,
             	@p_provincial_pp_stat_code,
             	@w_other_prov_tax_1_stat_code,
             	'1','1',
             	0,0,0,0,0,
             	' ',' ',' ',
             	'12/31/2999',
             	'12/31/2999',
             	'N','N',
             	' ',' ',
             	/* R6.0M SSA 165213 new columns added to table */
             	0,
	     	0,
             	0,	
             	/* R6.0M SSA 165213 End */	
             	0
             	,@p_ppip_status_code /* 566986 */
                ,0   /* inc_tax_infirm_depn_amt         585743 */
                ,0   /* inc_tax_child_amt               585743 */
                ,0   /* inc_tax_transferred_depn_amt    585743 */
                ,'0'           --cpp_election_code      1061321 [delivered in 2011 reg pack 1012803]
                ,'12/31/2999'  --cpp_election_date      1061321 [delivered in 2011 reg pack 1012803]
                ,'0'           --prev_cpp_election_code 1061321 [delivered in 2011 reg pack 1012803]
                ,'12/31/2999'  --prev_cpp_election_date 1061321 [delivered in 2011 reg pack 1012803]
				,'N'           --rcv_pp_pension_ind     1118754 def341775
                ,@w_hlth_ctrb_status_code      /* kb 1383272 - def 393072 */
             	)
        End
    End

if @@error <> 0 
    Begin
        Select @p_rc       = 500015
        Select @p_ret_mess = 'Error on emp_can_tax_authority for Provincial'
return
    End


if (rtrim(@p_autopay_pay_element_id) IS NOT NULL AND rtrim(@p_autopay_pay_element_id)!='')    and @p_autopay_rtn = 0 
   Begin
    insert into emp_pay_element
       (emp_id,
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
	first_roth_ctrb,                 /* r71m-578919 in 576240 */
        ira_sep_simple_ind,              /* r71m-581591 in 582025 */
        taxable_amt_not_determined_ind)  /* r71m-581591 in 582025 */ 

       values (	@p_employee_id,
               	@p_employer_id,
		@p_autopay_pay_element_id,
    		@p_original_hire_date,
		'12/31/2999','12/31/2999',
               	@p_inact_by_pay_element_ind,
               	@p_original_hire_date,
               	@p_stop_date,
		' ','00',' ',
		0,0,0,0,0,0,
    		@p_auto_rt_tbl_id,
               	' ',' ',' ',' ',' ',' ',' ',' ',
               	0,0,
		' ',' ',' ',' ',' ',
    		0,0,0,0,0,0,0,
		' ',' ',' ',
		'12/31/2999','12/31/2999',
    		'N','N',
		' ',' ', 'N', ' ', ' ',' ',
               	0, 
                '12/31/2999',          /* r71m-578919 in 576240 */ 
                'N','N')               /* r71m-581591 in 582025 */ 

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
    	      @p_autopay_pay_element_id,
              0, 0, '9', 'N',
              '12/31/2999', '', 0)

    END

if @@error <> 0 
    begin
        Select @p_rc       = 500013
        Select @p_ret_mess = 'Error on emp_pay_element'
return
end

Declare @p_cursor_rc int
Execute usp_ins_hemp_03 @p_employer_taxing_ctry_code,
                        @p_employer_id,
                        @p_employee_id,
                        @p_pay_element_ctrl_grp,
                        @p_original_hire_date,
                        @p_pensioner_indicator,
                        @p_autopay_pay_element_id,
                        @p_cursor_rc    OUTPUT

if @p_cursor_rc = -1 
    Begin
        Select @p_rc       = 500016
        Select @p_ret_mess = 'Error on emp_pay_element'
        return
    End

if exists (Select hpge.pay_element_id 
    From pay_element_ctrl_grp_entry hpge, pay_element hpay
    Where hpge.pay_element_ctrl_grp_id = @p_pay_element_ctrl_grp and
          hpge.pay_element_id = hpay.pay_element_id and 
          hpge.establish_on_hire_ind = 'Y' and 
          hpay.start_date > @p_original_hire_date) 
    Select @p_rc = 50433 

if @p_employer_taxing_ctry_code = 'US' 
    if @p_pensioner_indicator = 'N' 
        if exists (Select hpge.pay_element_id 
            From pay_element_ctrl_grp_entry hpge, pay_element hpay
            Where hpge.pay_element_ctrl_grp_id = @p_pay_element_ctrl_grp and
                  hpge.pay_element_id = hpay.pay_element_id and 
                  hpge.establish_on_hire_ind = 'Y' and 
                  hpay.pay_element_type_code = '1' and 
                  hpay.earn_type_code = '6') 
            Select @p_rc       = 50435

if @p_cursor_rc = 50436 
    Select @p_rc = @p_cursor_rc

 

 
GO
ALTER AUTHORIZATION ON [dbo].[usp_ins_hemp_02] TO  SCHEMA OWNER 
GO
