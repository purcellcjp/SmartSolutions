USE [DBShrpn]
GO
/****** Object:  StoredProcedure [dbo].[usp_ins_hepy_insert]    Script Date: 4/1/2025 4:33:00 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE procedure [dbo].[usp_ins_hepy_insert]
               (@w_stop_date    char(12),
				@p_emp_id                          char(15),
                @p_empl_id                         char(10),
                @p_pay_element_id                  char(10),
                @p_eff_date                        datetime,
                @p_prior_eff_date                  datetime,
                @p_next_eff_date                   datetime,
				@p_inact_by_pay_element_ind		   char(1),
                @p_start_date                      datetime,
                @p_stop_date                       datetime,
                @p_change_reason_code              char(5),
                @p_pay_ele_pay_pd_sched_code	   char(2),
                @p_calc_meth_code                  char(2),
                @p_standard_calc_factor_1          money,
                @p_standard_calc_factor_2          money,
                @p_special_calc_factor_1           money,
                @p_special_calc_factor_2           money,
                @p_special_calc_factor_3           money,
                @p_special_calc_factor_4           money,
                @p_rate_tbl_id                     char(10),
                @p_rate_code                       char(8),
                @p_payee_name                      char(35),
                @p_payee_pmt_sched_code            char(5),
                @p_payee_bank_transit_nbr          char(17),
                @p_payee_bank_acct_nbr             char(17),
                @p_pmt_ref_nbr                     char(20),
                @p_pmt_ref_name                    char(35),
                @p_vendor_id                       char(10),
                @p_limit_amt                       money,
				@p_guaranteed_net_pay_amt          money,
                @p_start_after_pay_element_id      char(10),
                @p_indiv_addr_typ_to_prt_code	   char(5),
                @p_bank_id                         char(11),
                @p_dir_dep_bank_acct_nbr		   char(17),
                @p_bank_acct_type_code             char(1),
                @p_pay_pd_arrs_rec_fixed_amt	   money,
                @p_pay_pd_arrs_rec_fixed_pct	   money,
                @p_min_pay_pd_recovery_amt         money,
                @p_user_amt_1                      float,
                @p_user_amt_2					   float,
                @p_user_monetary_amt_1             money,
                @p_user_monetary_amt_2             money,
                @p_user_monetary_curr_code         char(3),
                @p_user_code_1                     char(5),
                @p_user_code_2                     char(5),
                @p_user_date_1                     datetime,
                @p_user_date_2                     datetime,
                @p_user_ind_1                      char(1),
                @p_user_ind_2                      char(1),
                @p_user_text_1                     char(50),
				@p_user_text_2						char(50),
				@p_chgstamp							smallint,
				@p_epend_emp_id						char(15),
				@p_epend_empl_id					char(10),
				@p_epend_pay_element_id				char(10),
				@p_epend_arrears_bal_amt			money,
				@p_epend_rec_ovr_nbr_pay_pds		tinyint,
				@p_epend_wh_status_code				char(1),
				@p_epend_calc_last_pay_pd_ind		char(1),
				@p_epend_prenotif_chk_date			datetime,
				@p_epend_prenotification_code		char(1),
				@p_epend_chgstamp					smallint,
				@p_epec_emp_id						char(15),
				@p_epec_empl_id						char(10),
				@p_epec_pay_element_id				char(10),
				@p_epec_start_date					datetime,
				@p_epec_comnt_type_code				char(1),
				@p_epec_seq_nbr						smallint,
				@p_epec_comnt_text					varchar(255),
				@p_epec_chgstamp					smallint,
				@p_pe_descp							char(35),
				@p_pe_type							char(1),
				@p_pe_earning_type					char(1),
				@p_pe_deduction_type				char(1),
				@p_pe_pay_pd_sched					char(2),
				@p_pe_calc_meth						char(2),
				@p_pe_stndrd_calc_fac_1				money,
				@p_pe_stndrd_calc_fac_2				money,
				@p_pe_spec_calc_fac_1				money,
				@p_pe_spec_calc_fac_2				money,
				@p_pe_spec_calc_fac_3				money,
				@p_pe_spec_calc_fac_4				money,
				@p_pe_limit_amt						money,
				@p_pe_limit_cyc_type				char(1),
				@p_pe_ded_rec_meth					char(1),
				@p_pe_rec_fixed_amt					money,
				@p_pe_rec_fixed_pct					float,
				@p_pe_min_pay_pd_rec_amt			money,
				@p_pe_rate_tbl_id					char(10),
				@p_pe_ben_plan_id					char(15),
				@p_rt_descp							char(35),
				@p_rte_descp						char(35),
				@p_epel_towards_lmt_amt				money,
				@p_tpp_descp						char(15),
				@p_comments_flag					char(1),
				@p_current_ver_eff_date				datetime,
				@p_pe_curr_code						char(3),
				@p_scrty_cat_code					char(3),
				@p_original_stop_date				datetime,
				@p_pension_tot_distn_ind			char(1),
				@p_pension_distn_code_1				char(1),
				@p_pension_distn_code_2				char(1),
				@p_pre_1990_rpp_ctrb_type			char(1),
				@p_first_roth_ctrb					datetime,
				@p_ira_sep_simple_ind				char(1),
				@p_txbl_amt_not_det_ind				char(1),
				@p_result_set_ind					char(1) = 'Y',
				@ret								int = 0 OUTPUT )
AS

declare   @W_ACTION_DATETIME char(30)
  EXEC @ret = sp_dbs_authenticate
  IF @ret != 0 RETURN

/*=== Variable Declaration ===*/
DECLARE @w_pe_eff_date  datetime,
@w_eot   datetime,
@w_bot   datetime,
@lv_dummy  char(15),
        @w_pay_element_added    char(01)      /*R4.1M - SSA# 19517*/

SELECT @w_eot = "29991231"
SELECT @w_bot = "19000101"
SELECT @w_pay_element_added = 'N'    /*R4.1M - SSA# 19517*/

SELECT @p_user_monetary_curr_code = @p_pe_curr_code

IF @p_user_date_1 = @w_bot
   SELECT @p_user_date_1 = @w_eot

IF @p_user_date_2 = @w_bot
   SELECT @p_user_date_2 = @w_eot

IF @p_prior_eff_date = @w_bot
   SELECT @p_prior_eff_date = @w_eot

IF @p_next_eff_date = @w_bot
   SELECT @p_next_eff_date = @w_eot

IF @w_stop_date = @w_bot OR @w_stop_date IS Null
   SELECT @w_stop_date = @w_eot

IF @p_start_after_pay_element_id != "" AND
@p_stop_date != @w_eot
 BEGIN
  IF EXISTS( SELECT *
   FROM emp_pay_element
  WHERE  emp_id = @p_emp_id
  AND empl_id = @p_empl_id
  AND pay_element_id = @p_start_after_pay_element_id
  AND start_date > @p_stop_date )

    BEGIN
     SELECT @ret = 261256
     goto setandreturn
    END
 END


/*=== Determine If Policy Pay Element has differect rate table in
      future version ===*/
IF @w_stop_date = "00/00/0000"
 BEGIN
   IF (ltrim(rtrim(@p_rate_tbl_id)) IS NOT NULL AND ltrim(rtrim(@p_rate_tbl_id))!="")
    BEGIN
     SELECT @w_pe_eff_date = eff_date
      FROM pay_element
     WHERE  pay_element_id = @p_pay_element_id
      AND eff_date > @p_start_date
      AND eff_date <= @p_stop_date
      AND (ltrim(rtrim(rate_tbl_id)) IS NOT NULL AND ltrim(rtrim(rate_tbl_id))!="")
      AND rate_tbl_id != @p_rate_tbl_id
     IF @@rowcount != 0
      SELECT @w_stop_date = convert(char(12),dateadd(day,-1,@w_pe_eff_date),101)
     ELSE
      SELECT @w_stop_date = convert(char(12),@p_stop_date,101)
    END
  END
/*======================================================================*/
/*    START     */
/* Reset Employee Pay Element Fields whcich defaulted from Policy Pay */
/* Element        */
/*======================================================================*/
IF @p_pay_ele_pay_pd_sched_code = @p_pe_pay_pd_sched
  SELECT @p_pay_ele_pay_pd_sched_code = " "
IF @p_calc_meth_code = @p_pe_calc_meth
  SELECT @p_calc_meth_code = " "
IF @p_standard_calc_factor_1 = @p_pe_stndrd_calc_fac_1
  SELECT @p_standard_calc_factor_1 = 0
IF @p_standard_calc_factor_2 = @p_pe_stndrd_calc_fac_2
  SELECT @p_standard_calc_factor_2 = 0
IF @p_special_calc_factor_1 = @p_pe_spec_calc_fac_1
  SELECT @p_special_calc_factor_1 = 0
IF @p_special_calc_factor_2 = @p_pe_spec_calc_fac_2
  SELECT @p_special_calc_factor_2 = 0
IF @p_special_calc_factor_3 = @p_pe_spec_calc_fac_3
  SELECT @p_special_calc_factor_3 = 0
IF @p_special_calc_factor_4 = @p_pe_spec_calc_fac_4
  SELECT @p_special_calc_factor_4 = 0
IF @p_limit_amt = @p_pe_limit_amt
  SELECT @p_limit_amt = 0
IF @p_pay_pd_arrs_rec_fixed_amt = @p_pe_rec_fixed_amt
  SELECT @p_pay_pd_arrs_rec_fixed_amt = 0
IF @p_pay_pd_arrs_rec_fixed_pct= @p_pe_rec_fixed_pct
  SELECT @p_pay_pd_arrs_rec_fixed_pct = 0
IF @p_min_pay_pd_recovery_amt = @p_pe_min_pay_pd_rec_amt
  SELECT @p_min_pay_pd_recovery_amt = 0
/*======================================================================*/
/*    END     */
/* Reset Employee Pay Element Fields whcich defaulted from Policy Pay */
/* Element        */
/*======================================================================*/
/*R4.1M - SSA# 19517 check if the pay element has been added - Begin*/
if exists (select * from emp_pay_element
           where emp_id  = @p_emp_id
             and empl_id = @p_empl_id
             and pay_element_id = @p_pay_element_id)
   select @w_pay_element_added = 'Y'
/*R4.1M - SSA# 19517 check if the pay element has been added - end*/
/*======================================================================*/
/*    START     */
/* Insert into Employee Pay Element     */
/*======================================================================*/
  INSERT INTO emp_pay_element
            ( emp_id,
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
              first_roth_ctrb,                /* r71m - 578919 in 2006 reg pack 576240 */
              ira_sep_simple_ind,             /* r71m - 581591 in reg pack catchup 582025 */
              taxable_amt_not_determined_ind) /* r71m - 581591 in reg pack catchup 582025 */

     VALUES ( @p_emp_id,
              @p_empl_id,
              @p_pay_element_id,
              @p_eff_date,
              @p_prior_eff_date,
              @p_next_eff_date,
              @p_inact_by_pay_element_ind,
              @p_start_date,
              @w_stop_date,
              @p_change_reason_code,
              @p_pay_ele_pay_pd_sched_code,
              @p_calc_meth_code,
              @p_standard_calc_factor_1,
              @p_standard_calc_factor_2,
              @p_special_calc_factor_1,
              @p_special_calc_factor_2,
              @p_special_calc_factor_3,
              @p_special_calc_factor_4,
              @p_rate_tbl_id,
              @p_rate_code,
              @p_payee_name,
              @p_payee_pmt_sched_code,
              @p_payee_bank_transit_nbr,
              @p_payee_bank_acct_nbr,
              @p_pmt_ref_nbr,
              @p_pmt_ref_name,
              @p_vendor_id,
              @p_limit_amt,
              @p_guaranteed_net_pay_amt,
              @p_start_after_pay_element_id,
              @p_indiv_addr_typ_to_prt_code,
              @p_bank_id,
              @p_dir_dep_bank_acct_nbr,
              @p_bank_acct_type_code,
              @p_pay_pd_arrs_rec_fixed_amt,
              @p_pay_pd_arrs_rec_fixed_pct,
              @p_min_pay_pd_recovery_amt,
              @p_user_amt_1,
              @p_user_amt_2,
              @p_user_monetary_amt_1,
              @p_user_monetary_amt_2,
              @p_user_monetary_curr_code,
              @p_user_code_1,
              @p_user_code_2,
              @p_user_date_1,
              @p_user_date_2,
              @p_user_ind_1,
              @p_user_ind_2,
              @p_user_text_1,
              @p_user_text_2,
              @p_pension_tot_distn_ind,
              @p_pension_distn_code_1,
              @p_pension_distn_code_2,
              @p_pre_1990_rpp_ctrb_type,
              0,
              @p_first_roth_ctrb,               /* r71m - 578919 in 2006 reg pack 576240 */
              @p_ira_sep_simple_ind,            /* r71m - 581591 in reg pack catchup 582025 */
              @p_txbl_amt_not_det_ind)          /* r71m - 581591 in reg pack catchup 582025 */

/*======================================================================*/
/*    END     */
/* Insert into Employee Pay Element     */
/*======================================================================*/

/*======================================================================*/
/*    START     */
/* Insert into Employee Pay Element Limit If the Employee Pay Element */
/* Limit Amount is present OR the Pay Element Limit amount is present */
/*======================================================================*/
SELECT @lv_dummy = emp_id
 FROM emp_pay_element_limit
WHERE  emp_id = @p_emp_id
 AND empl_id = @p_empl_id
 AND pay_element_id = @p_pay_element_id
 AND start_date = @p_start_date

IF @@rowcount = 0
 BEGIN
  IF @p_limit_amt != 0 OR @p_pe_limit_amt != 0
   BEGIN
    INSERT INTO emp_pay_element_limit
( emp_id,
empl_id,
pay_element_id,
start_date,
towards_the_limit_amt,
chgstamp )

    VALUES ( @p_emp_id,
           @p_empl_id,
           @p_pay_element_id,
@p_start_date,
0,
0 )
   END
 END
/*======================================================================*/
/*    END     */
/* Insert into Employee Pay Element Limit If the Employee Pay Element */
/* Limit Amount is present OR the Pay Element Limit amount is present */
/*======================================================================*/

/*======================================================================*/
/*    START     */
/* Insert into Employee Pay Element Non Dated      */
/*======================================================================*/
SELECT @lv_dummy = emp_id
 FROM emp_pay_element_non_dtd
WHERE  emp_id = @p_emp_id
 AND empl_id = @p_empl_id
 AND pay_element_id = @p_pay_element_id

IF @@rowcount = 0
 BEGIN
     INSERT INTO emp_pay_element_non_dtd
( emp_id,
empl_id,
pay_element_id,
arrears_bal_amt,
recover_over_nbr_of_pay_pds,
wh_status_code,
calc_last_pay_pd_ind,
prenotification_check_date,
prenotification_code,
 chgstamp )

     VALUES ( @p_emp_id,
@p_empl_id,
@p_pay_element_id,
0,
@p_epend_rec_ovr_nbr_pay_pds,
@p_epend_wh_status_code,
@p_epend_calc_last_pay_pd_ind,
@w_eot,
@p_epend_prenotification_code,
0 )

 END
/*======================================================================*/
/*    END     */
/* Insert into Employee Pay Element Non Dated      */
/*======================================================================*/

/* AUDIT SECTION ==============================================*/
/* Set up the work employee pay element audit table                                            */
/* ============================================================*/
/*R4.1M - SSA# 19517 if the pay element has been added do not write 'ADD' - Begin*/
if @w_pay_element_added = 'Y'
   goto setandreturn
/*R4.1M - SSA# 19517 if the pay element has been added do not write 'ADD' - end*/

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

insert into work_emp_pay_element_aud
(user_id, activity_action_code, action_date, emp_id, empl_id, pay_element_id,    eff_date, prior_eff_date, next_eff_date, new_eff_date, new_start_date,     new_stop_date)
values
(@W_ACTION_USER, 'ADD', @W_ACTION_DATETIME,
@p_emp_id, @p_empl_id, @p_pay_element_id, @p_eff_date,'', '', '', '', '')

Delete work_emp_pay_element_aud
Where user_id = @W_ACTION_USER
and action_date = @W_ACTION_DATETIME
and activity_action_code = 'ADD'
and emp_id = @p_emp_id
and empl_id = @p_empl_id
and pay_element_id = @p_pay_element_id
and eff_date = @p_eff_date

/* END AUDIT SECTION ==========================================*/
/* Set up the work employee pay element audit table                                            */
/* ============================================================*/


setandreturn:
   IF @p_result_set_ind = 'Y'
     SELECT @ret





GO
ALTER AUTHORIZATION ON [dbo].[usp_ins_hepy_insert] TO  SCHEMA OWNER
GO
