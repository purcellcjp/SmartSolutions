USE [DBShrpn]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER PROCEDURE [dbo].[usp_ins_pay_element]
(
	@p_userid						varchar(30),
	@p_batchname					varchar(08),
	@p_qualifier					varchar(30),
    @p_activity_date				datetime,
    @p_user_id						varchar(30),
	@p_activity_status				char(02),
	@p_status						int  output
)
AS


BEGIN

    DECLARE @ret int
    --DECLARE @p_activity_date				datetime
    --DECLARE @p_userid						varchar(30)
    --DECLARE @p_batchname					varchar(08)
    --DECLARE @p_qualifier					varchar(30)
    --DECLARE @p_user_id						varchar(30)
    --DECLARE @p_activity_status				char(02)
    --DECLARE @p_status						int
    DECLARE @w_msg_text						varchar(255)
    DECLARE @w_msg_text_2					varchar(255)
    DECLARE @w_msg_text_3					varchar(255)
    DECLARE @w_severity_cd					tinyint
    DECLARE @w_fatal_error					char(01)
    DECLARE @w_trace_sw						char(01)

    DECLARE @special_value_exists			int
    DECLARE @individual_id					char(10)
    DECLARE @prior_last_name				char(30)
    DECLARE @pay_through_date				datetime
    DECLARE	@start_date						datetime
    DECLARE @pay_frequency_code				char(05)
    DECLARE @emp_calculation_06_nbr			money
    DECLARE @emp_calculation_06_conv		money
    DECLARE @emp_calculation_06_char        char(15)

    SELECT @w_trace_sw = 'Y'

    IF @w_trace_sw = 'Y'
    INSERT INTO DBSosxp.dbo.msg SELECT CAST(GETDATE() AS CHAR (20)) AS msg_desc

    IF @w_trace_sw = 'Y'
    INSERT INTO DBSosxp.dbo.msg SELECT 'Start usp_ins_pay_element' AS msg_desc
    --
    -- Activate these fields when testing this program standalone.
    --

    --SET @p_userid			=	'DBS'
    --SET @p_batchname		=	'GHR'
    --SET @p_qualifier		=	'INTERFACES'
    --SET @p_activity_date	=	GETDATE()
    --SET @p_user_id			=	'GHRUser'
    --SET @p_activity_status	=	'00'
    --SET @p_status			=	0



    --exec @ret = sp_dbs_authenticate
    --if @ret != 0 return -1

    IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_employee_events_temp6]') AND type in (N'U'))
        DROP TABLE [dbo].[ghr_employee_events_temp6]

    CREATE TABLE [dbo].[ghr_employee_events_temp6](
        [ID]									[int]	IDENTITY(1,1) NOT NULL,
        [event_id_01]							[char](02) NULL,
        [emp_id_01]								[char](15) NULL,
        [eff_date_01]							[char](10) NULL,
        [first_name_01]							[char](25) NULL,
        [first_middle_name_01]					[char](25) NULL,
        [last_name_01]							[char](30) NULL,
        [empl_id_01]							[char](10) NULL,
        [national_id_1_type_code_01]			[char](05) NULL,
        [national_id_1_01]						[char](20) NULL,
        [organization_group_id_01]				[char](05) NULL,
        [organization_chart_name_01]			[varchar](64) NULL,
        [organization_unit_name_01]				[varchar](240) NULL,
        [emp_status_classn_code_01]				[char](02) NULL,
        [position_title_01]						[char](60) NULL,
        [employment_type_code_01]				[char](05) NULL,
        [annual_salary_amt_01]					[char](15) NULL,
        [begin_date_02]							[char](10) NULL,
        [end_date_02]							[char](10) NULL,
        [pay_status_code_03]					[char](01) NULL,
        [pay_group_id_03]						[char](10) NULL,
        [pay_element_ctrl_grp_id_03]			[char](10) NULL,
        [time_reporting_meth_code_03]			[char](01) NULL,
        [employment_info_chg_reason_cd_03]		[char](05) NULL,
        [emp_location_code_03]					[char](10) NULL,
        [emp_status_code_5]						[char](02) NULL,
        [reason_code_5]							[char](02) NULL,
        [emp_expected_return_date_5]			[char](10) NULL,
        [pay_through_date_5]					[char](10) NULL,
        [emp_death_date_5]						[char](10) NULL,
        [consider_for_rehire_ind_5]				[char](01) NULL,
        [pay_element_desc_06]					[char](20) NULL,
        [emp_calculation_06]					[char](15) NULL
    )

    INSERT INTO DBShrpn.dbo.ghr_employee_events_temp6    ---#t0
    SELECT *
    FROM DBShrpn.dbo.ghr_employee_events
    WHERE [event_id_01] = '06'

    DECLARE @max			INT
    DECLARE @maxx			CHAR(06)
    DECLARE @cnt			INT
    DECLARE @ind_id			INT
    DECLARE @ind_idx		CHAR(10)
    DECLARE @annual_salary	MONEY
    DECLARE @tax_entity_id	CHAR(10)
    DECLARE @display_name	CHAR(45)
    DECLARE @msg_id			CHAR(10)
    DECLARE @msg_p1			CHAR(15)
    DECLARE @msg_p2			CHAR(15)
    DECLARE @msg_cnt		INT

    DECLARE         @i_stop_date_1					   char(12),
                    @i_emp_id                          char(15),
                    @i_empl_id                         char(10),
                    @i_pay_element_id                  char(10),
                    @i_eff_date                        datetime,
                    @i_stop_date					   datetime,
                    @i_pay_element_exists			   char(01)

    -- Declare
    DECLARE         @w_stop_date_1					   char(12),
                    @w_emp_id                          char(15),
                    @w_empl_id                         char(10),
                    @w_pay_element_id                  char(10),
                    @w_eff_date                        datetime,
                    @w_prior_eff_date                  datetime,
                    @w_next_eff_date                   datetime,
                    @w_inact_by_pay_element_ind		   char(1),
                    @w_start_date                      datetime,
                    @w_stop_date                       datetime,
                    @w_change_reason_code              char(5),
                    @w_pay_ele_pay_pd_sched_code	   char(2),
                    @w_calc_meth_code                  char(2),
                    @w_standard_calc_factor_1          money,
                    @w_standard_calc_factor_2          money,
                    @w_special_calc_factor_1           money,
                    @w_special_calc_factor_2           money,
                    @w_special_calc_factor_3           money,
                    @w_special_calc_factor_4           money,
                    @w_rate_tbl_id                     char(10),
                    @w_rate_code                       char(8),
                    @w_payee_name                      char(35),
                    @w_payee_pmt_sched_code            char(5),
                    @w_payee_bank_transit_nbr          char(17),
                    @w_payee_bank_acct_nbr             char(17),
                    @w_pmt_ref_nbr                     char(20),
                    @w_pmt_ref_name                    char(35),
                    @w_vendor_id                       char(10),
                    @w_limit_amt                       money,
                    @w_guaranteed_net_pay_amt          money,
                    @w_start_after_pay_element_id      char(10),
                    @w_indiv_addr_typ_to_prt_code	   char(5),
                    @w_bank_id                         char(11),
                    @w_dir_dep_bank_acct_nbr		   char(17),
                    @w_bank_acct_type_code             char(1),
                    @w_pay_pd_arrs_rec_fixed_amt	   money,
                    @w_pay_pd_arrs_rec_fixed_pct	   money,
                    @w_min_pay_pd_recovery_amt         money,
                    @w_user_amt_1                      float,
                    @w_user_amt_2					   float,
                    @w_user_monetary_amt_1             money,
                    @w_user_monetary_amt_2             money,
                    @w_user_monetary_curr_code         char(3),
                    @w_user_code_1                     char(5),
                    @w_user_code_2                     char(5),
                    @w_user_date_1                     datetime,
                    @w_user_date_2                     datetime,
                    @w_user_ind_1                      char(1),
                    @w_user_ind_2                      char(1),
                    @w_user_text_1                     char(50),
                    @w_user_text_2						char(50),
                    @w_chgstamp							smallint,
                    @w_epend_emp_id						char(15),
                    @w_epend_empl_id					char(10),
                    @w_epend_pay_element_id				char(10),
                    @w_epend_arrears_bal_amt			money,
                    @w_epend_rec_ovr_nbr_pay_pds		tinyint,
                    @w_epend_wh_status_code				char(1),
                    @w_epend_calc_last_pay_pd_ind		char(1),
                    @w_epend_prenotif_chk_date			datetime,
                    @w_epend_prenotification_code		char(1),
                    @w_epend_chgstamp					smallint,
                    @w_epec_emp_id						char(15),
                    @w_epec_empl_id						char(10),
                    @w_epec_pay_element_id				char(10),
                    @w_epec_start_date					datetime,
                    @w_epec_comnt_type_code				char(1),
                    @w_epec_seq_nbr						smallint,
                    @w_epec_comnt_text					varchar(255),
                    @w_epec_chgstamp					smallint,
                    @w_pe_descp							char(35),
                    @w_pe_type							char(1),
                    @w_pe_earning_type					char(1),
                    @w_pe_deduction_type				char(1),
                    @w_pe_pay_pd_sched					char(2),
                    @w_pe_calc_meth						char(2),
                    @w_pe_stndrd_calc_fac_1				money,
                    @w_pe_stndrd_calc_fac_2				money,
                    @w_pe_spec_calc_fac_1				money,
                    @w_pe_spec_calc_fac_2				money,
                    @w_pe_spec_calc_fac_3				money,
                    @w_pe_spec_calc_fac_4				money,
                    @w_pe_limit_amt						money,
                    @w_pe_limit_cyc_type				char(1),
                    @w_pe_ded_rec_meth					char(1),
                    @w_pe_rec_fixed_amt					money,
                    @w_pe_rec_fixed_pct					float,
                    @w_pe_min_pay_pd_rec_amt			money,
                    @w_pe_rate_tbl_id					char(10),
                    @w_pe_ben_plan_id					char(15),
                    @w_rt_descp							char(35),
                    @w_rte_descp						char(35),
                    @w_epel_towards_lmt_amt				money,
                    @w_tpp_descp						char(15),
                    @w_comments_flag					char(1),
                    @w_current_ver_eff_date				datetime,
                    @w_pe_curr_code						char(3),
                    @w_scrty_cat_code					char(3),
                    @w_original_stop_date				datetime,
                    @w_pension_tot_distn_ind			char(1),
                    @w_pension_distn_code_1				char(1),
                    @w_pension_distn_code_2				char(1),
                    @w_pre_1990_rpp_ctrb_type			char(1),
                    @w_first_roth_ctrb					datetime,
                    @w_ira_sep_simple_ind				char(1),
                    @w_txbl_amt_not_det_ind				char(1),
                    @w_result_set_ind					char(1) = 'N',
                    @w_ret								int

    -- Default Values:
    SELECT  @w_stop_date_1					=	'29991231',
            @w_emp_id                       =	'000325',
            @w_empl_id                      =	'5001',
            @w_pay_element_id				=	'ACTI',
            @w_eff_date                     =	'20210801',
            @w_prior_eff_date               =	'19000101',
            @w_next_eff_date                =	'19000101',
            @w_inact_by_pay_element_ind		=	'N',
            @w_start_date                   =	'20210801',
            @w_stop_date                    =	'29991231',
            @w_change_reason_code           =	'',
            @w_pay_ele_pay_pd_sched_code	=	'01',
            @w_calc_meth_code               =	'01',
            @w_standard_calc_factor_1       =	361.00,
            @w_standard_calc_factor_2       =	0.00,
            @w_special_calc_factor_1		=	0.00,
            @w_special_calc_factor_2		=	0.00,
            @w_special_calc_factor_3 		=	0.00,
            @w_special_calc_factor_4		=	0.00,
            @w_rate_tbl_id                  =	'',
            @w_rate_code                    =	'',
            @w_payee_name                   =	'',
            @w_payee_pmt_sched_code         =	'',
            @w_payee_bank_transit_nbr       =	'',
            @w_payee_bank_acct_nbr          =	'',
            @w_pmt_ref_nbr                  =	'',
            @w_pmt_ref_name                 =	'',
            @w_vendor_id                    =	'',
            @w_limit_amt                    =	0 ,
            @w_guaranteed_net_pay_amt		=	0 ,
            @w_start_after_pay_element_id   =	'',
            @w_indiv_addr_typ_to_prt_code	=	'',
            @w_bank_id                      =	'',
            @w_dir_dep_bank_acct_nbr		=	'',
            @w_bank_acct_type_code          =	' ',
            @w_pay_pd_arrs_rec_fixed_amt	=	0,
            @w_pay_pd_arrs_rec_fixed_pct	=	0,
            @w_min_pay_pd_recovery_amt      =	0,
            @w_user_amt_1                   =	0,
            @w_user_amt_2					=	0,
            @w_user_monetary_amt_1			=	0,
            @w_user_monetary_amt_2			=	0,
            @w_user_monetary_curr_code      =	'',
            @w_user_code_1                  =	'',
            @w_user_code_2                  =	'',
            @w_user_date_1                  =	'19000101',
            @w_user_date_2                  =	'19000101',
            @w_user_ind_1                   =	'N',
            @w_user_ind_2                   =	'N',
            @w_user_text_1                  =	'',
            @w_user_text_2					=	'',
            @w_chgstamp						=	0,
            @w_epend_emp_id					=	'',
            @w_epend_empl_id				=	'',
            @w_epend_pay_element_id			=	'',
            @w_epend_arrears_bal_amt		=	0,
            @w_epend_rec_ovr_nbr_pay_pds	=	0,
            @w_epend_wh_status_code			=	'9',
            @w_epend_calc_last_pay_pd_ind	=	'N',
            @w_epend_prenotif_chk_date		=	'19000101',
            @w_epend_prenotification_code	=	'',
            @w_epend_chgstamp				=	0,
            @w_epec_emp_id					=	'',
            @w_epec_empl_id					=	'',
            @w_epec_pay_element_id			=	'',
            @w_epec_start_date				=	'19000101',
            @w_epec_comnt_type_code			=	'',
            @w_epec_seq_nbr					=	0,
            @w_epec_comnt_text				=	'',
            @w_epec_chgstamp				=	0,
            @w_pe_descp						=	'Acting Salary',
            @w_pe_type						=	'1',
            @w_pe_earning_type				=	'1',
            @w_pe_deduction_type			=	'',
            @w_pe_pay_pd_sched				=	'01',
            @w_pe_calc_meth					=	'01',
            @w_pe_stndrd_calc_fac_1			=	0,
            @w_pe_stndrd_calc_fac_2			=	0,
            @w_pe_spec_calc_fac_1			=	0,
            @w_pe_spec_calc_fac_2			=	0,
            @w_pe_spec_calc_fac_3			=	0,
            @w_pe_spec_calc_fac_4			=	0,
            @w_pe_limit_amt					=	0,
            @w_pe_limit_cyc_type			=	'0'	,
            @w_pe_ded_rec_meth				=	''	,
            @w_pe_rec_fixed_amt				=	0,
            @w_pe_rec_fixed_pct				=	0,
            @w_pe_min_pay_pd_rec_amt		=	0,
            @w_pe_rate_tbl_id				=	'',
            @w_pe_ben_plan_id				=	'',
            @w_rt_descp						=	'',
            @w_rte_descp					=	'',
            @w_epel_towards_lmt_amt			=	0,
            @w_tpp_descp					=	'',
            @w_comments_flag				=	'',
            @w_current_ver_eff_date			=	'19000101',
            @w_pe_curr_code					=	'XCD',
            @w_scrty_cat_code				=	'NA',
            @w_original_stop_date			=	'19000101',
            @w_pension_tot_distn_ind		=	'N',
            @w_pension_distn_code_1			=	'0',
            @w_pension_distn_code_2			=	'0',
            @w_pre_1990_rpp_ctrb_type		=	'0',
            @w_first_roth_ctrb				=	'29991231',
            @w_ira_sep_simple_ind			=	'N',
            @w_txbl_amt_not_det_ind			=	'N',
            @w_result_set_ind				=	'N',
            @w_ret							=	0


    -- This section declares the interface values from Global HR
    DECLARE	@event_id_01							char(02),
            @emp_id_01								char(15),
            @eff_date_01							char(10),
            @first_name_01							char(25),
            @first_middle_name_01					char(25),
            @last_name_01							char(30),
            @empl_id_01								char(10),
            @national_id_1_type_code_01				char(05),
            @national_id_1_01						char(20),
            @organization_group_id_01				char(05),
            @organization_chart_name_01				varchar(64),
            @organization_unit_name_01				varchar(240),
            @emp_status_classn_code_01				char(02),
            @position_title_01						char(60),
            @employment_type_code_01				char(05),
            @annual_salary_amt_01					char(15),
            @begin_date_02							char(10),
            @end_date_02							char(10),
            @pay_status_code_03						char(01),
            @pay_group_id_03						char(10),
            @pay_element_ctrl_grp_id_03				char(10),
            @time_reporting_meth_code_03			char(01),
            @employment_info_chg_reason_cd_03		char(05),
            @emp_location_code_03					char(10),
            @emp_status_code_5						char(02),
            @reason_code_5							char(02),
            @emp_expected_return_date_5				char(10),
            @pay_through_date_5						char(10),
            @emp_death_date_5						char(10),
            @consider_for_rehire_ind_5				char(01),
            @pay_element_desc_06					char(20),
            @emp_calculation_06						char(15)



    SET @cnt = 1

    SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_employee_events_temp6

    DELETE DBShrpn.dbo.ghr_msg_tbl

    WHILE (@cnt <= @max)
    BEGIN
        SELECT  @event_id_01						=	event_id_01,
                @emp_id_01							=	emp_id_01,
                @eff_date_01						=	eff_date_01,
                @first_name_01						=	first_name_01,
                @first_middle_name_01				=	first_middle_name_01,
                @last_name_01						=	last_name_01,
                @empl_id_01							=	empl_id_01,
                @national_id_1_type_code_01			=	national_id_1_type_code_01,
                @national_id_1_01					=	national_id_1_01,
                @organization_group_id_01			=	organization_group_id_01,
                @organization_chart_name_01			=	organization_chart_name_01,
                @organization_unit_name_01			=	organization_unit_name_01,
                @emp_status_classn_code_01			=	emp_status_classn_code_01,
                @position_title_01					=	position_title_01,
                @employment_type_code_01			=	employment_type_code_01,
                @annual_salary_amt_01				=	annual_salary_amt_01,
                @begin_date_02						=	begin_date_02,
                @end_date_02						=	end_date_02,
                @pay_status_code_03					=	pay_status_code_03,
                @pay_group_id_03					=	pay_group_id_03,
                @pay_element_ctrl_grp_id_03			=	pay_element_ctrl_grp_id_03,
                @time_reporting_meth_code_03		=	time_reporting_meth_code_03,
                @employment_info_chg_reason_cd_03	=	employment_info_chg_reason_cd_03,
                @emp_location_code_03				=	emp_location_code_03,
                @emp_status_code_5					=	emp_status_code_5,
                @reason_code_5						=	reason_code_5,
                @emp_expected_return_date_5			=	emp_expected_return_date_5,
                @pay_through_date_5					=	pay_through_date_5,
                @emp_death_date_5					=	emp_death_date_5,
                @consider_for_rehire_ind_5			=	consider_for_rehire_ind_5,
                @pay_element_desc_06				=	pay_element_desc_06,
                @emp_calculation_06					=	emp_calculation_06
        FROM DBShrpn.dbo.ghr_employee_events_temp6 t WHERE t.ID = @cnt

        INSERT INTO DBSosxp.dbo.msg SELECT 'Detail_Loop: ' + ' event_id: ' + @event_id_01 + ' emp_id: ' + @emp_id_01 + ' eff date: ' + @eff_date_01 + ' pay element: ' + @pay_element_desc_06 + ' count: ' + CAST(@cnt AS CHAR(10))  AS msg_desc
        --
        --	This section will validate the interface data
        --

        --
        -- Check to see if the employee does not exists
        --

        IF  NOT EXISTS (SELECT * FROM DBShrpn.dbo.emp_status WHERE emp_id = @emp_id_01)
            BEGIN
                UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status	=	'02'
                WHERE activity_date	=	@p_activity_date
                    AND emp_id_01		=	@emp_id_01
                    AND event_id_01		=	'06'

                INSERT INTO DBShrpn.dbo.ghr_msg_tbl
                SELECT 'U00012'					As msg_id,
                        @emp_id_01					As msg_p1,
                        @emp_id_01					As msg_p2,
                        'Employee does not exists'	As msg_desc

                -- Historical Message for reporting purpose
                INSERT INTO DBShrpn.dbo.ghr_historical_message
                SELECT  'U00012'						As msg_id,
                        '06'							As event_id,
                        @emp_id_01 						As emp_id,
                        @eff_date_01					As eff_date,
                        @pay_element_desc_06			As pay_element_id,
                        @emp_id_01						As msg_p1,
                        @emp_id_01						As msg_p2,
                        'Employee does not exists'		As msg_desc,
                        @p_activity_date				AS activity_date
                -- End of Historical Message for reporting purpose

                SELECT	@w_fatal_error = '5'

                -- GOTO BYPASS_EMPLOYEE
            END

        --
        -- Check to see if the employer exists
        --

        IF NOT EXISTS (SELECT * FROM [DBShrpn].[dbo].[employer] WHERE empl_id = @empl_id_01)
            BEGIN
                IF EXISTS (SELECT * FROM [DBShrpn].[dbo].[employer] WHERE empl_id = '0' + @empl_id_01)
                        SELECT @empl_id_01	= '0' + @empl_id_01
                    ELSE
                        BEGIN

                            UPDATE DBShrpn.dbo.ghr_employee_events_aud
                                SET activity_status	= '02'
                                WHERE activity_date	=	@p_activity_date
                                AND emp_id_01		=	@emp_id_01
                                AND event_id_01		=	'06'


                                INSERT INTO DBShrpn.dbo.ghr_msg_tbl
                                SELECT 'U00039'					As msg_id,
                                    @emp_id_01					As msg_p1,
                                    @empl_id_01					As msg_p2,
                                    'Employer does not exists - bypassing record'	As msg_desc

                                -- Historical Message for reporting purpose
                            INSERT INTO DBShrpn.dbo.ghr_historical_message
                            SELECT  'U00039'					As msg_id,
                                    '06'						As event_id,
                                    @emp_id_01 					As emp_id,
                                    @eff_date_01				As eff_date,
                                    @pay_element_desc_06		As pay_element_id,
                                    @emp_id_01					As msg_p1,
                                    @empl_id_01					As msg_p2,
                                    'Employer does not exists - bypassing record'	As msg_desc,
                                    @p_activity_date			AS activity_date
                            -- End of Historical Message for reporting purpose

                            SELECT	@w_fatal_error = '5'

                                -- GOTO BYPASS_EMPLOYEE
                        END
            END

        /*
            SELECT  @event_id_01,
                    @emp_id_01,
                    @eff_date_01,
                    @first_name_01,
                    @last_name_01,
                    @empl_id_01,
                    @national_id_1_type_code_01,
                    @national_id_1_01,				-- Check if it exists
                    @organization_group_id_01,
                    @organization_chart_name_01,
                    @organization_unit_name_01,		-- Check if it exists DBSosst Structure If does not exists then blank
                    @emp_status_classn_code_01,
                    @position_title_01,
                    @employment_type_code_01,
                    @annual_salary_amt_01,
                    @begin_date_02,
                    @end_date_02,
                    @pay_status_code_03,
                    @pay_group_id_03,
                    @pay_element_ctrl_grp_id_03,
                    @time_reporting_meth_code_03,
                    @employment_info_chg_reason_cd_03
                    @emp_location_code_03,
                    @emp_status_code_5,
                    @reason_code_5,
                    @emp_expected_return_date_5,
                    @pay_through_date_5,
                    @emp_death_date_5,
                    @consider_for_rehire_ind_5,
                    @pay_element_desc_06,
                    @emp_calculation_06

            SELECT @last_name_01
        */

        --
        --	Obtain the setup variables
        --

        --
        --
        --

        --
        --	Obtain the current record for this employee pay element
        --
        SELECT	@i_pay_element_exists	=	'N'

        SELECT	@i_emp_id				=	emp_id,
                @i_empl_id				=	empl_id,
                @i_pay_element_id		=	pay_element_id,
                @i_eff_date				=	eff_date,
                @i_stop_date			=	stop_date,
                @i_pay_element_exists	=	'Y'
        FROM	[DBShrpn].[dbo].[emp_pay_element]	pe
        WHERE	emp_id					=	@emp_id_01
        AND  empl_id					=	@empl_id_01
        AND  pay_element_id			=	@pay_element_desc_06
        and  eff_date				=	(SELECT	MAX(eff_date) FROM	[DBShrpn].[dbo].[emp_pay_element] t
                                            WHERE	t.emp_id			=	pe.emp_id
                                                AND	t.empl_id			=	pe.empl_id
                                                AND	t.pay_element_id	=	pe.pay_element_id)
        --
        --	Check to see that the new effective date is greater than the current effective date
        --
        IF	@i_pay_element_exists	=	'Y' AND @i_eff_date > @eff_date_01
            BEGIN
                UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status	=	'02'
                WHERE activity_date	=	@p_activity_date
                    AND emp_id_01		=	@emp_id_01
                    AND event_id_01		=	'06'

                INSERT INTO DBShrpn.dbo.ghr_msg_tbl
                SELECT 'U00027'					As msg_id,
                        @eff_date_01				As msg_p1,
                        @emp_id_01					As msg_p2,
                        'The new effective date, @2 , for employee, @1, must be greater than the current effective date'	As msg_desc

                -- Historical Message for reporting purpose
                INSERT INTO DBShrpn.dbo.ghr_historical_message
                SELECT  'U00027'						As msg_id,
                        '06'							As event_id,
                        @emp_id_01 						As emp_id,
                        @eff_date_01					As eff_date,
                        @pay_element_desc_06			As pay_element_id,
                        @emp_id_01						As msg_p1,
                        @emp_id_01						As msg_p2,
                        'The new effective date for employee must be greater than the current effective date'		As msg_desc,
                        @p_activity_date				AS activity_date
                -- End of Historical Message for reporting purpose

                SELECT	@w_fatal_error = '5'

                -- GOTO BYPASS_EMPLOYEE
            END

        --
        -- Validate the important fields in this section.
        --

        --	Validate that the start date is the same or ealier than the pay through date of the employee
            SELECT	@pay_through_date	=	pay_through_date
            FROM	DBShrpn.dbo.emp_employment ee
            WHERE	emp_id		=	@emp_id_01
            AND	eff_date	=  (SELECT MAX(eff_date) FROM DBShrpn.dbo.emp_employment t WHERE t.emp_id =	ee.emp_id)

            SELECT @start_date = CAST(@begin_date_02 AS datetime)

            IF	@start_date > @pay_through_date
                BEGIN
                    UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                        SET activity_status	=	'02'
                    WHERE activity_date	=	@p_activity_date
                        AND emp_id_01		=	@emp_id_01
                        AND event_id_01		=	'06'

                    INSERT INTO DBShrpn.dbo.ghr_msg_tbl
                    SELECT 'U00030'					As msg_id,
                            @begin_date_02				As msg_p1,
                            @emp_id_01					As msg_p2,
                            'The Begin Date cannot be greater than the pay through date for employee.'	As msg_desc

                    -- Historical Message for reporting purpose
                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                    SELECT  'U00030'						As msg_id,
                            '06'							As event_id,
                            @emp_id_01 						As emp_id,
                            @eff_date_01					As eff_date,
                            @pay_element_desc_06			As pay_element_id,
                            @emp_id_01						As msg_p1,
                            @emp_id_01						As msg_p2,
                            'The Begin Date cannot be greater than the pay through date for employee.'		As msg_desc,
                            @p_activity_date				AS activity_date
                    -- End of Historical Message for reporting purpose

                    SELECT	@w_fatal_error = '5'

                    -- GOTO BYPASS_EMPLOYEE
                END

        ---
        --- Validate the stop date against the effective date
        ---

        IF	CONVERT(date,@end_date_02) < CONVERT(date,@eff_date_01)
            BEGIN
                UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status	=	'02'
                WHERE activity_date	=	@p_activity_date
                    AND emp_id_01		=	@emp_id_01
                    AND event_id_01		=	'06'

                INSERT INTO DBShrpn.dbo.ghr_msg_tbl
                SELECT 'U00047'					As msg_id,
                        @begin_date_02				As msg_p1,
                        @emp_id_01					As msg_p2,
                        'The stop date must be the same or later than the employee pay element effective date for employee.'	As msg_desc

                -- Historical Message for reporting purpose
                INSERT INTO DBShrpn.dbo.ghr_historical_message
                SELECT  'U00047'						As msg_id,
                        '06'							As event_id,
                        @emp_id_01 						As emp_id,
                        @eff_date_01					As eff_date,
                        @pay_element_desc_06			As pay_element_id,
                        @emp_id_01						As msg_p1,
                        @emp_id_01						As msg_p2,
                        'The stop date must be the same or later than the employee pay element effective date - Defaulting the stop date.'		As msg_desc,
                        @p_activity_date				AS activity_date
                -- End of Historical Message for reporting purpose

                SELECT @eff_date_01 = @end_date_02
            END


        --
        --
        --  Make sure that frequency is semi monthly starting April 1 of 2023
        --
        --
        SELECT @pay_frequency_code	= pay_frequency_code
        FROM [DBShrpn].[dbo].[pay_group]
        WHERE [pay_group_id] = @pay_group_id_03

        IF @pay_frequency_code <> 'SEMI'
        BEGIN
            UPDATE	DBShrpn.dbo.ghr_employee_events_aud
            SET activity_status	=	'02'
            WHERE activity_date	=	@p_activity_date
            AND emp_id_01		=	@emp_id_01
            AND event_id_01		=	'06'

            INSERT INTO DBShrpn.dbo.ghr_msg_tbl
                SELECT 'U00048'					As msg_id,
                        @pay_group_id_03			As msg_p1,
                        @emp_id_01              	As msg_p2,
                        'After April 1, 2023,Pay Group, @1, must be semi-monthly.'	As msg_desc

            -- Historical Message for reporting purpose
            INSERT INTO DBShrpn.dbo.ghr_historical_message
            SELECT  'U00048'					As msg_id,
                    '06'						As event_id,
                    @emp_id_01 					As emp_id,
                    @eff_date_01				As eff_date,
                    @pay_element_desc_06		As pay_element_id,
                    @pay_group_id_03			As msg_p1,
                    @emp_id_01              	As msg_p2,
                    'After April 1, 2023,Pay Group, ' + RTRIM(@pay_group_id_03) + ' , must be semi-monthly.'	As msg_desc,
                    @p_activity_date			AS activity_date
            -- End of Historical Message for reporting purpose

            IF GETDATE() > '20230331'
                SELECT	@w_fatal_error = '5'

        END


        IF  @w_fatal_error = '5'
            GOTO BYPASS_EMPLOYEE


        --
        -- start pay element logic
        --

        --	SELECT @pay_frequency_code	= pay_frequency_code
        --    FROM [DBShrpn].[dbo].[pay_group] WHERE [pay_group_id] = @pay_group_id_03

        SELECT @emp_calculation_06_nbr = CAST(@emp_calculation_06 AS MONEY)


        IF	@pay_frequency_code	= 'WEEK'	SELECT @emp_calculation_06_conv	=	@emp_calculation_06_nbr / 4
        ELSE
        IF	@pay_frequency_code	= 'BIWK'	SELECT @emp_calculation_06_conv	=	@emp_calculation_06_nbr / 2
        ELSE
        IF	@pay_frequency_code	= 'SEMI'	SELECT @emp_calculation_06_conv	=	@emp_calculation_06_nbr / 2
        ELSE
        IF	@pay_frequency_code	= 'MONTH'	SELECT @emp_calculation_06_conv	=	@emp_calculation_06_nbr / 1

        SELECT @emp_calculation_06 = CAST(@emp_calculation_06_conv AS CHAR(15))

        IF	NOT EXISTS (SELECT * FROM DBShrpn.dbo.emp_pay_element
                        WHERE	emp_id			=	@emp_id_01
                        AND	empl_id			=	@empl_id_01
                        AND	pay_element_id	=	@pay_element_desc_06
                        AND	eff_date		=	@eff_date_01)
        BEGIN

        IF	@i_pay_element_exists	=	'Y' AND CONVERT(date,@i_stop_date) < CONVERT(date,@w_stop_date_1)
            BEGIN
                UPDATE DBShrpn.dbo.emp_pay_element
                SET  stop_date					=	@w_stop_date_1
                WHERE	emp_id						=	@i_emp_id
                AND	empl_id						=	@i_empl_id
                AND	pay_element_id				=	@i_pay_element_id
                AND	eff_date					=	@i_eff_date
            END

        IF @w_trace_sw = 'Y'
            INSERT INTO DBSosxp.dbo.msg SELECT 'Before_SP: ' + 'DBShrpn.dbo.gsp_ins_hepy_insert'  AS msg_desc

        EXEC DBShrpn.dbo.usp_ins_hepy_insert @w_stop_date	=	@w_stop_date_1,
                    @p_emp_id								=	@emp_id_01,
                    @p_empl_id								=	@empl_id_01,
                    @p_pay_element_id						=	@pay_element_desc_06,
                    @p_eff_date								=	@eff_date_01,
                    @p_prior_eff_date						=	@w_prior_eff_date,
                    @p_next_eff_date						=	@w_next_eff_date,
                    @p_inact_by_pay_element_ind				=	@w_inact_by_pay_element_ind,
                    @p_start_date							=	@begin_date_02,
                    @p_stop_date							=	@end_date_02,
                    @p_change_reason_code					=	@w_change_reason_code,
                    @p_pay_ele_pay_pd_sched_code			=	@w_pay_ele_pay_pd_sched_code,
                    @p_calc_meth_code						=	@w_calc_meth_code,
                    @p_standard_calc_factor_1				=	@emp_calculation_06,
                    @p_standard_calc_factor_2				=	@w_standard_calc_factor_2,
                    @p_special_calc_factor_1				=	@w_special_calc_factor_1,
                    @p_special_calc_factor_2				=	@w_special_calc_factor_1,
                    @p_special_calc_factor_3				=	@w_special_calc_factor_1,
                    @p_special_calc_factor_4				=	@w_special_calc_factor_1,
                    @p_rate_tbl_id							=	@w_rate_tbl_id,
                    @p_rate_code							=	@w_rate_code,
                    @p_payee_name							=	@w_payee_name,
                    @p_payee_pmt_sched_code					=	@w_payee_pmt_sched_code,
                    @p_payee_bank_transit_nbr				=	@w_payee_bank_transit_nbr,
                    @p_payee_bank_acct_nbr					=	@w_payee_bank_acct_nbr,
                    @p_pmt_ref_nbr							=	@w_pmt_ref_nbr,
                    @p_pmt_ref_name							=	@w_pmt_ref_name,
                    @p_vendor_id							=	@w_vendor_id ,
                    @p_limit_amt							=	@w_limit_amt,
                    @p_guaranteed_net_pay_amt				=	@w_guaranteed_net_pay_amt,
                    @p_start_after_pay_element_id			=	@w_start_after_pay_element_id,
                    @p_indiv_addr_typ_to_prt_code			=	@w_indiv_addr_typ_to_prt_code,
                    @p_bank_id								=	@w_bank_id,
                    @p_dir_dep_bank_acct_nbr				=	@w_dir_dep_bank_acct_nbr,
                    @p_bank_acct_type_code					=	@w_bank_acct_type_code,
                    @p_pay_pd_arrs_rec_fixed_amt			=	@w_pay_pd_arrs_rec_fixed_amt,
                    @p_pay_pd_arrs_rec_fixed_pct			=	@w_pay_pd_arrs_rec_fixed_pct,
                    @p_min_pay_pd_recovery_amt				=	@w_min_pay_pd_recovery_amt,
                    @p_user_amt_1							=	@w_user_amt_1,
                    @p_user_amt_2							=	@w_user_amt_2,
                    @p_user_monetary_amt_1					=	@w_user_monetary_amt_1,
                    @p_user_monetary_amt_2					=	@w_user_monetary_amt_2,
                    @p_user_monetary_curr_code				=	@w_user_monetary_curr_code ,
                    @p_user_code_1							=	@w_user_code_1,
                    @p_user_code_2							=	@w_user_code_2,
                    @p_user_date_1							=	@w_user_date_1,
                    @p_user_date_2							=	@w_user_date_2,
                    @p_user_ind_1							=	@w_user_ind_1,
                    @p_user_ind_2							=	@w_user_ind_2,
                    @p_user_text_1							=	@w_user_text_1,
                    @p_user_text_2							=	@w_user_text_2,
                    @p_chgstamp								=	@w_chgstamp,
                    @p_epend_emp_id							=	@w_epend_emp_id,
                    @p_epend_empl_id						=	@w_epend_empl_id,
                    @p_epend_pay_element_id					=	@w_epend_pay_element_id,
                    @p_epend_arrears_bal_amt				=	@w_epend_arrears_bal_amt,
                    @p_epend_rec_ovr_nbr_pay_pds			=	@w_epend_rec_ovr_nbr_pay_pds,
                    @p_epend_wh_status_code					=	@w_epend_wh_status_code,
                    @p_epend_calc_last_pay_pd_ind			=	@w_epend_calc_last_pay_pd_ind,
                    @p_epend_prenotif_chk_date				=	@w_epend_prenotif_chk_date,
                    @p_epend_prenotification_code			=	@w_epend_prenotification_code,
                    @p_epend_chgstamp						=	@w_epend_chgstamp,
                    @p_epec_emp_id							=	@w_epec_emp_id,
                    @p_epec_empl_id							=	@w_epec_empl_id,
                    @p_epec_pay_element_id					=	@w_epec_pay_element_id,
                    @p_epec_start_date						=	@w_epec_start_date,
                    @p_epec_comnt_type_code					=	@w_epec_comnt_type_code,
                    @p_epec_seq_nbr							=	@w_epec_seq_nbr,
                    @p_epec_comnt_text						=	@w_epec_comnt_text,
                    @p_epec_chgstamp						=	@w_epec_chgstamp,
                    @p_pe_descp								=	@w_pe_descp,
                    @p_pe_type								=	@w_pe_type,
                    @p_pe_earning_type						=	@w_pe_earning_type,
                    @p_pe_deduction_type					=	@w_pe_deduction_type,
                    @p_pe_pay_pd_sched						=	@w_pe_pay_pd_sched,
                    @p_pe_calc_meth							=	@w_pe_calc_meth,
                    @p_pe_stndrd_calc_fac_1					=	@w_pe_stndrd_calc_fac_1,
                    @p_pe_stndrd_calc_fac_2					=	@w_pe_stndrd_calc_fac_2,
                    @p_pe_spec_calc_fac_1					=	@w_pe_spec_calc_fac_1,
                    @p_pe_spec_calc_fac_2					=	@w_pe_spec_calc_fac_2,
                    @p_pe_spec_calc_fac_3					=	@w_pe_spec_calc_fac_3,
                    @p_pe_spec_calc_fac_4					=	@w_pe_spec_calc_fac_4,
                    @p_pe_limit_amt							=	@w_pe_limit_amt,
                    @p_pe_limit_cyc_type					=	@w_pe_limit_cyc_type,
                    @p_pe_ded_rec_meth						=	@w_pe_ded_rec_meth,
                    @p_pe_rec_fixed_amt						=	@w_pe_rec_fixed_amt,
                    @p_pe_rec_fixed_pct						=	@w_pe_rec_fixed_pct,
                    @p_pe_min_pay_pd_rec_amt				=	@w_pe_min_pay_pd_rec_amt,
                    @p_pe_rate_tbl_id						=	@w_pe_rate_tbl_id,
                    @p_pe_ben_plan_id						=	@w_pe_ben_plan_id,
                    @p_rt_descp								=	@w_rt_descp,
                    @p_rte_descp							=	@w_rte_descp,
                    @p_epel_towards_lmt_amt					=	@w_epel_towards_lmt_amt,
                    @p_tpp_descp							=	@w_tpp_descp,
                    @p_comments_flag						=	@w_comments_flag,
                    @p_current_ver_eff_date					=	@w_current_ver_eff_date,
                    @p_pe_curr_code							=	@w_pe_curr_code,
                    @p_scrty_cat_code						=	@w_scrty_cat_code,
                    @p_original_stop_date					=	@w_original_stop_date,
                    @p_pension_tot_distn_ind				=	@w_pension_tot_distn_ind,
                    @p_pension_distn_code_1					=	@w_pension_distn_code_1,
                    @p_pension_distn_code_2					=	@w_pension_distn_code_2,
                    @p_pre_1990_rpp_ctrb_type				=	@w_pre_1990_rpp_ctrb_type,
                    @p_first_roth_ctrb						=	@w_first_roth_ctrb,
                    @p_ira_sep_simple_ind					=	@w_ira_sep_simple_ind,
                    @p_txbl_amt_not_det_ind					=	@w_txbl_amt_not_det_ind,
                    @p_result_set_ind						=	@w_result_set_ind,
                    @ret									=	@ret

            IF @w_trace_sw = 'Y'
                INSERT INTO DBSosxp.dbo.msg SELECT 'After_SP: ' + 'DBShrpn.dbo.gsp_ins_hepy_insert'  AS msg_desc


            IF  CONVERT(date,@end_date_02) < CONVERT(date,@w_stop_date_1)
                UPDATE DBShrpn.dbo.emp_pay_element
                SET  stop_date					=	CASE WHEN CONVERT(date,@end_date_02) < CONVERT(date,@i_eff_date) THEN @i_eff_date ELSE CONVERT(date,@end_date_02) END
                WHERE	emp_id						=	@emp_id_01
                AND	empl_id						=	@empl_id_01
                AND	pay_element_id				=	@pay_element_desc_06
                AND	eff_date					=	@eff_date_01

            IF	@i_pay_element_exists	=	'Y'
            BEGIN
                --  Current Record
                UPDATE DBShrpn.dbo.emp_pay_element
                SET prior_eff_date				=	@i_eff_date
                WHERE	emp_id						=	@emp_id_01
                AND	empl_id						=	@empl_id_01
                AND	pay_element_id				=	@pay_element_desc_06
                AND	eff_date					=	@eff_date_01
                -- Prior Record
                UPDATE DBShrpn.dbo.emp_pay_element
                SET next_eff_date				=	@eff_date_01
                WHERE	emp_id						=	@emp_id_01
                AND	empl_id						=	@empl_id_01
                AND	pay_element_id				=	@pay_element_desc_06
                AND	eff_date					=	@i_eff_date
            END

	END
	ELSE
	BEGIN
		UPDATE	[DBShrpn].[dbo].[emp_pay_element]
		SET		[start_date]				=	@begin_date_02,
                [stop_date]					=	@end_date_02,
                [standard_calc_factor_1]	=	@emp_calculation_06,
                [calc_meth_code]			=	@w_calc_meth_code,
                [rate_tbl_id]				=	@w_rate_tbl_id,
                [rate_code]					=	@w_rate_code
		WHERE	emp_id						=	@emp_id_01
		AND		empl_id						=	@empl_id_01
		AND		pay_element_id				=	@pay_element_desc_06
		AND		eff_date					=	@eff_date_01
	END

--
-- End of pay element logic
--
	 SELECT @individual_id = individual_id FROM [DBShrpn].[dbo].[employee] WHERE emp_id = @emp_id_01
	 /*
	 UPDATE	[DBShrpn].[dbo].[individual_personal]
		SET	user_text_1		=	CAST(@position_title_01 AS CHAR(50))
	  WHERE individual_id	=	@individual_id
	 */
	BYPASS_EMPLOYEE:

	SELECT w_fatal_error = '0'

	SELECT @cnt = @cnt + 1
END

--
-- Notify the users of all the issues
--

--
-- Send notification of warning message U00028  -- < PAY ELEMENT SECTION (6) >
--

SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00028'

SELECT @max = COUNT(*)
--  SELECT *
  FROM DBShrpn.dbo.ghr_employee_events
 WHERE [event_id_01] = '06'
SELECT @maxx = CAST(@max As CHAR(06))
SELECT @special_value_exists = 0
SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)
SELECT @msg_id = 'U00028'

SELECT @w_msg_text_2 = ''

EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2 @p_userid,
    @p_batchname,
    @p_qualifier,
    @msg_id ,
    @w_severity_cd,
    @w_msg_text,
    @w_msg_text_2,
    @w_msg_text_3

--
-- End of Sending notification of warning message U00000
--

--
-- Send notification of warning message U00009  -- < BEGINING OF WARNING MESSAGES: >
--

SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
--  SELECT *
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00009'

SELECT @max = COUNT(*)
--  SELECT *
  FROM DBShrpn.dbo.ghr_employee_events
 WHERE [event_id_01] = '06'
SELECT @maxx = CAST(@max As CHAR(06))
SELECT @special_value_exists = 0
SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)
SELECT @msg_id = 'U00009'

SELECT @w_msg_text_2 = ''

EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2 @p_userid,
    @p_batchname,
    @p_qualifier,
    @msg_id ,
    @w_severity_cd,
    @w_msg_text,
    @w_msg_text_2,
    @w_msg_text_3

--
-- End of Sending notification of warning message U00009
--

--
-- Send notification of warning message U00011 -- Blank Line
--

SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
--  SELECT *
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00011'

SELECT @maxx = CAST(@max As CHAR(06))
SELECT @special_value_exists = 0
SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)
SELECT @msg_id = 'U00011'

SELECT @w_msg_text_2 = ''

EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2 @p_userid,
    @p_batchname,
    @p_qualifier,
    @msg_id ,
    @w_severity_cd,
    @w_msg_text,
    @w_msg_text_2,
    @w_msg_text_3

--
-- Send notification of warning message U00029  -- Total Global HR Pay Elements Read:
--

SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
--  SELECT *
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00029'

SELECT @max = COUNT(*)
--  SELECT *
  FROM DBShrpn.dbo.ghr_employee_events
 WHERE [event_id_01] = '06'
SELECT @maxx = CAST(@max As CHAR(06))
SELECT @special_value_exists = 0
SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)
SELECT @msg_id = 'U00029'

IF @special_value_exists <> 0 SELECT @w_msg_text = REPLACE(@w_msg_text,'@1',RTRIM(@maxx))
SELECT @w_msg_text_2 = ''

EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2 @p_userid,
    @p_batchname,
    @p_qualifier,
    @msg_id ,
    @w_severity_cd,
    @w_msg_text,
    @w_msg_text_2,
    @w_msg_text_3

--
-- Send notification of warning message U00012 -- Employee does not exists Message
--

IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_message_temp_6]') AND type in (N'U'))
	DROP TABLE [dbo].[ghr_message_temp_6]


CREATE TABLE [dbo].[ghr_message_temp_6](
	[ID]							[int] IDENTITY(1,1) NOT NULL,
	[msg_id]						[char](15)	NOT NULL,
	[msg_p1]						[char](15)	NOT NULL,
	[msg_p2]						[char](15)	NOT NULL,
	[msg_desc]						[char](255) NOT NULL
)


SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00012'

INSERT INTO DBShrpn.dbo.ghr_message_temp_6
SELECT *
  FROM DBShrpn.dbo.ghr_msg_tbl
 WHERE msg_id = 'U00012'

SET @cnt = 1

SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_6


WHILE (@cnt <= @max)
BEGIN

SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_6 t4 WHERE t4.[ID] = @cnt

SELECT @special_value_exists = 0
SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)

IF @special_value_exists <> 0 SELECT @w_msg_text = REPLACE(@w_msg_text,'@1',RTRIM(@msg_p2))


SELECT @special_value_exists = 0
SELECT @special_value_exists = CHARINDEX('@2',@w_msg_text,1)

IF @special_value_exists <> 0 SELECT @w_msg_text = REPLACE(@w_msg_text,'@2',RTRIM(@msg_p1))

SELECT @w_msg_text_2 = ''

EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2 @p_userid,
    @p_batchname,
    @p_qualifier,
    @msg_id ,
    @w_severity_cd,
    @w_msg_text,
    @w_msg_text_2,
    @w_msg_text_3

SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00012'

SELECT @cnt = @cnt + 1;

END
--
--	End of warning message U00012
--

--
-- Send notification of warning message U00027 -- The new effective date, @1 , for employee, @2, must be greater than the current effective date
--

IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_message_temp_6]') AND type in (N'U'))
	DROP TABLE [dbo].[ghr_message_temp_6]


CREATE TABLE [dbo].[ghr_message_temp_6](
	[ID]							[int] IDENTITY(1,1) NOT NULL,
	[msg_id]						[char](15)	NOT NULL,
	[msg_p1]						[char](15)	NOT NULL,
	[msg_p2]						[char](15)	NOT NULL,
	[msg_desc]						[char](255) NOT NULL
)


SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00027'

INSERT INTO DBShrpn.dbo.ghr_message_temp_6
SELECT *
  FROM DBShrpn.dbo.ghr_msg_tbl
 WHERE msg_id = 'U00027'

SET @cnt = 1

SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_6


WHILE (@cnt <= @max)
BEGIN

SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_6 t6 WHERE t6.[ID] = @cnt

SELECT @special_value_exists = 0
SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)

IF @special_value_exists <> 0 SELECT @w_msg_text = REPLACE(@w_msg_text,'@1',RTRIM(@msg_p1))


SELECT @special_value_exists = 0
SELECT @special_value_exists = CHARINDEX('@2',@w_msg_text,1)

IF @special_value_exists <> 0 SELECT @w_msg_text = REPLACE(@w_msg_text,'@2',RTRIM(@msg_p2))

SELECT @w_msg_text_2 = ''

EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2 @p_userid,
    @p_batchname,
    @p_qualifier,
    @msg_id ,
    @w_severity_cd,
    @w_msg_text,
    @w_msg_text_2,
    @w_msg_text_3

SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00027'

SELECT @cnt = @cnt + 1;

END
--
--	End of warning message U00027
--


--
-- Send notification of warning message U00030 -- The Begin Date, @1, cannot be greater than the pay through date for employee @2
--

IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_message_temp_6]') AND type in (N'U'))
	DROP TABLE [dbo].[ghr_message_temp_6]


CREATE TABLE [dbo].[ghr_message_temp_6](
	[ID]							[int] IDENTITY(1,1) NOT NULL,
	[msg_id]						[char](15)	NOT NULL,
	[msg_p1]						[char](15)	NOT NULL,
	[msg_p2]						[char](15)	NOT NULL,
	[msg_desc]						[char](255) NOT NULL
)


SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00030'

INSERT INTO DBShrpn.dbo.ghr_message_temp_6
SELECT *
  FROM DBShrpn.dbo.ghr_msg_tbl
 WHERE msg_id = 'U00030'

SET @cnt = 1

SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_6


WHILE (@cnt <= @max)
BEGIN

SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_6 t6 WHERE t6.[ID] = @cnt

SELECT @special_value_exists = 0
SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)

IF @special_value_exists <> 0 SELECT @w_msg_text = REPLACE(@w_msg_text,'@1',RTRIM(@msg_p1))


SELECT @special_value_exists = 0
SELECT @special_value_exists = CHARINDEX('@2',@w_msg_text,1)

IF @special_value_exists <> 0 SELECT @w_msg_text = REPLACE(@w_msg_text,'@2',RTRIM(@msg_p2))

SELECT @w_msg_text_2 = ''

EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2 @p_userid,
    @p_batchname,
    @p_qualifier,
    @msg_id ,
    @w_severity_cd,
    @w_msg_text,
    @w_msg_text_2,
    @w_msg_text_3

SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00030'

SELECT @cnt = @cnt + 1;

END
--
--	End of warning message U00030
--
--JAG

--
-- Send notification of warning message U00039 -- Employer does not exists: @1 - bypassing record
--

IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_message_temp_6]') AND type in (N'U'))
	DROP TABLE [dbo].[ghr_message_temp_6]


CREATE TABLE [dbo].[ghr_message_temp_6](
	[ID]							[int] IDENTITY(1,1) NOT NULL,
	[msg_id]						[char](15)	NOT NULL,
	[msg_p1]						[char](15)	NOT NULL,
	[msg_p2]						[char](15)	NOT NULL,
	[msg_desc]						[char](255) NOT NULL
)


SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00039'

INSERT INTO DBShrpn.dbo.ghr_message_temp_6
SELECT *
  FROM DBShrpn.dbo.ghr_msg_tbl
 WHERE msg_id = 'U00039'

SET @cnt = 1

SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_6


WHILE (@cnt <= @max)
BEGIN

SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_6 t6 WHERE t6.[ID] = @cnt

SELECT @special_value_exists = 0
SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)

IF @special_value_exists <> 0 SELECT @w_msg_text = REPLACE(@w_msg_text,'@1',RTRIM(@msg_p1))


SELECT @special_value_exists = 0
SELECT @special_value_exists = CHARINDEX('@2',@w_msg_text,1)

IF @special_value_exists <> 0 SELECT @w_msg_text = REPLACE(@w_msg_text,'@2',RTRIM(@msg_p2))

SELECT @w_msg_text_2 = ''

EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2 @p_userid,
    @p_batchname,
    @p_qualifier,
    @msg_id ,
    @w_severity_cd,
    @w_msg_text,
    @w_msg_text_2,
    @w_msg_text_3

SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00039'

SELECT @cnt = @cnt + 1;

END
--
--	End of warning message U00030
--

--
-- Send notification of warning message U00047 -- The stop date must be the same or later than the employee pay element effective date for employee @1
--

IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_message_temp_6]') AND type in (N'U'))
	DROP TABLE [dbo].[ghr_message_temp_6]


CREATE TABLE [dbo].[ghr_message_temp_6](
	[ID]							[int] IDENTITY(1,1) NOT NULL,
	[msg_id]						[char](15)	NOT NULL,
	[msg_p1]						[char](15)	NOT NULL,
	[msg_p2]						[char](15)	NOT NULL,
	[msg_desc]						[char](255) NOT NULL
)


SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00047'

INSERT INTO DBShrpn.dbo.ghr_message_temp_6
SELECT *
  FROM DBShrpn.dbo.ghr_msg_tbl
 WHERE msg_id = 'U00047'

SET @cnt = 1

SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_6


WHILE (@cnt <= @max)
BEGIN

SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_6 t6 WHERE t6.[ID] = @cnt

SELECT @special_value_exists = 0
SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)

IF @special_value_exists <> 0 SELECT @w_msg_text = REPLACE(@w_msg_text,'@1',RTRIM(@msg_p1))


SELECT @special_value_exists = 0
SELECT @special_value_exists = CHARINDEX('@2',@w_msg_text,1)

IF @special_value_exists <> 0 SELECT @w_msg_text = REPLACE(@w_msg_text,'@2',RTRIM(@msg_p2))

SELECT @w_msg_text_2 = ''

EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2 @p_userid,
    @p_batchname,
    @p_qualifier,
    @msg_id ,
    @w_severity_cd,
    @w_msg_text,
    @w_msg_text_2,
    @w_msg_text_3

SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00047'

SELECT @cnt = @cnt + 1;

END


--
-- Send notification of warning message U00011 -- Blank Line
--

SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
--  SELECT *
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00011'

SELECT @maxx = CAST(@max As CHAR(06))
SELECT @special_value_exists = 0
SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)
SELECT @msg_id = 'U00011'

SELECT @w_msg_text_2 = ''

EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2 @p_userid,
    @p_batchname,
    @p_qualifier,
    @msg_id ,
    @w_severity_cd,
    @w_msg_text,
    @w_msg_text_2,
    @w_msg_text_3

--
-- Send notification of warning message U00010 -- <ENDING OF WARNING MESSAGES: >
--

SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
--  SELECT *
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00010'

SELECT @maxx = CAST(@max As CHAR(06))
SELECT @special_value_exists = 0
SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)
SELECT @msg_id = 'U00010'

SELECT @w_msg_text_2 = ''

EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2 @p_userid,
    @p_batchname,
    @p_qualifier,
    @msg_id ,
    @w_severity_cd,
    @w_msg_text,
    @w_msg_text_2,
    @w_msg_text_3


--
-- Send notification of warning message U00011 -- Blank Line
--

SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
--  SELECT *
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00011'

SELECT @maxx = CAST(@max As CHAR(06))
SELECT @special_value_exists = 0
SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)
SELECT @msg_id = 'U00011'

SELECT @w_msg_text_2 = ''

EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2 @p_userid,
    @p_batchname,
    @p_qualifier,
    @msg_id ,
    @w_severity_cd,
    @w_msg_text,
    @w_msg_text_2,
    @w_msg_text_3

IF @w_trace_sw = 'Y'
INSERT INTO DBSosxp.dbo.msg SELECT 'End usp_ins_pay_element' AS msg_desc
/*

SELECT @p_status = 0

*/
END
GO

ALTER AUTHORIZATION ON [dbo].[usp_ins_pay_element] TO  SCHEMA OWNER
GO
