USE DBShrpn
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'dbo.usp_ins_pay_element', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_ins_pay_element
    IF OBJECT_ID(N'dbo.usp_ins_pay_element') IS NOT NULL
        PRINT N'<<< FAILED DROPPING PROCEDURE dbo.usp_ins_pay_element >>>'
    ELSE
        PRINT N'<<< DROPPED PROCEDURE dbo.usp_ins_pay_element >>>'
END
GO

CREATE PROCEDURE dbo.usp_ins_pay_element
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

    SET NOCOUNT ON

    DECLARE @v_step_position                varchar(255)        = 'Begin Procedure'

    DECLARE @v_EVENT_ID_SALARY_CHANGE       char(2)             = '02'
    DECLARE @v_EVENT_ID_TRANSFER            char(2)             = '03'
    DECLARE @v_EVENT_ID_STATUS_CHANGE       char(2)             = '05'
    DECLARE @v_EVENT_ID_PAY_ELE             char(2)             = '06'
    DECLARE @v_ACTIVITY_STATUS_BAD          char(2)             = '02'
    DECLARE @v_BEG_OF_TIME_DATE             datetime            = '19000101'
    DECLARE @v_END_OF_TIME_DATE             datetime            = '29991231'

    DECLARE @ErrorMessage                   nvarchar(4000)
    DECLARE @ErrorSeverity                  int
    DECLARE @ErrorState                     int

    DECLARE @v_ret_val                      int                 = 0
    DECLARE @v_ret_val_usp_ins_hepy_insert  INT                 = 0

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


    DECLARE @pay_through_date				datetime
    --DECLARE	@start_date						datetime
    --DECLARE @pay_frequency_code				char(05)
    --DECLARE @emp_calculation_06_nbr			money
    --DECLARE @emp_calculation_06_char        char(15)

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




    --DECLARE @max			INT
    DECLARE @maxx			CHAR(06)
    --DECLARE @cnt			INT
    --DECLARE @ind_id			INT
    --DECLARE @ind_idx		CHAR(10)
    --DECLARE @annual_salary	MONEY
    --DECLARE @tax_entity_id	CHAR(10)
    --DECLARE @display_name	CHAR(45)
    DECLARE @msg_id			CHAR(10)
    --DECLARE @msg_p1			CHAR(15)
    --DECLARE @msg_p2			CHAR(15)
    --DECLARE @msg_cnt		INT

    DECLARE         @i_stop_date_1					   char(12),
                    @i_emp_id                          char(15),
                    @i_empl_id                         char(10),
                    @i_pay_element_id                  char(10),
                    @i_eff_date                        datetime,
                    @i_stop_date					   datetime,
                    @i_pay_element_exists			   char(01)

    -- Declare
    DECLARE @w_stop_date_1                      char(12)                = '29991231'
          , @w_emp_id                           char(15)                = '000325'
          , @w_empl_id                          char(10)                = '5001'
          , @w_pay_element_id                   char(10)                = 'ACTI'
          , @w_eff_date                         datetime                = '20210801'
          , @w_prior_eff_date                   datetime                = '19000101'
          , @w_next_eff_date                    datetime                = '19000101'
          , @w_inact_by_pay_element_ind         char(1)                 = 'N'
          , @w_start_date                       datetime                = '20210801'
          , @w_stop_date                        datetime                = '29991231'
          , @w_change_reason_code               char(5)                 = ''
          , @w_pay_ele_pay_pd_sched_code        char(2)                 = '01'
          , @w_calc_meth_code                   char(2)                 = '01'
          , @w_standard_calc_factor_1           money                   = 0.00
          , @w_standard_calc_factor_2           money                   = 0.00
          , @w_special_calc_factor_1            money                   = 0.00
          , @w_special_calc_factor_2            money                   = 0.00
          , @w_special_calc_factor_3            money                   = 0.00
          , @w_special_calc_factor_4            money                   = 0.00
          , @w_rate_tbl_id                      char(10)                = ''
          , @w_rate_code                        char(8)                 = ''
          , @w_payee_name                       char(35)                = ''
          , @w_payee_pmt_sched_code             char(5)                 = ''
          , @w_payee_bank_transit_nbr           char(17)                = ''
          , @w_payee_bank_acct_nbr              char(17)                = ''
          , @w_pmt_ref_nbr                      char(20)                = ''
          , @w_pmt_ref_name                     char(35)                = ''
          , @w_vendor_id                        char(10)                = ''
          , @w_limit_amt                        money                   = 0
          , @w_guaranteed_net_pay_amt           money                   = 0
          , @w_start_after_pay_element_id       char(10)                = ''
          , @w_indiv_addr_typ_to_prt_code       char(5)                 = ''
          , @w_bank_id                          char(11)                = ''
          , @w_dir_dep_bank_acct_nbr            char(17)                = ''
          , @w_bank_acct_type_code              char(1)                 = ' '
          , @w_pay_pd_arrs_rec_fixed_amt        money                   = 0
          , @w_pay_pd_arrs_rec_fixed_pct        money                   = 0
          , @w_min_pay_pd_recovery_amt          money                   = 0
          , @w_user_amt_1                       float                   = 0
          , @w_user_amt_2                       float                   = 0
          , @w_user_monetary_amt_1              money                   = 0
          , @w_user_monetary_amt_2              money                   = 0
          , @w_user_monetary_curr_code          char(3)                 = ''
          , @w_user_code_1                      char(5)                 = ''
          , @w_user_code_2                      char(5)                 = ''
          , @w_user_date_1                      datetime                = '19000101'
          , @w_user_date_2                      datetime                = '19000101'
          , @w_user_ind_1                       char(1)                 = 'N'
          , @w_user_ind_2                       char(1)                 = 'N'
          , @w_user_text_1                      char(50)                = ''
          , @w_user_text_2                      char(50)                = ''
          , @w_chgstamp                         smallint                = 0
          , @w_epend_emp_id                     char(15)                = ''
          , @w_epend_empl_id                    char(10)                = ''
          , @w_epend_pay_element_id             char(10)                = ''
          , @w_epend_arrears_bal_amt            money                   = 0
          , @w_epend_rec_ovr_nbr_pay_pds        tinyint                 = 0
          , @w_epend_wh_status_code             char(1)                 = '9'
          , @w_epend_calc_last_pay_pd_ind       char(1)                 = 'N'
          , @w_epend_prenotif_chk_date          datetime                = '19000101'
          , @w_epend_prenotification_code        char(1)                = ''
          , @w_epend_chgstamp                   smallint                = 0
          , @w_epec_emp_id                      char(15)                = ''
          , @w_epec_empl_id                     char(10)                = ''
          , @w_epec_pay_element_id              char(10)                = ''
          , @w_epec_start_date                  datetime                = '19000101'
          , @w_epec_comnt_type_code             char(1)                 = ''
          , @w_epec_seq_nbr                     smallint                = 0
          , @w_epec_comnt_text                  varchar(255)            = ''
          , @w_epec_chgstamp                    smallint                = 0
          , @w_pe_descp                         char(35)                = 'Acting Salary'
          , @w_pe_type                          char(1)                 = '1'
          , @w_pe_earning_type                  char(1)                 = '1'
          , @w_pe_deduction_type                char(1)                 = ''
          , @w_pe_pay_pd_sched                  char(2)                 = '01'
          , @w_pe_calc_meth                     char(2)                 = '01'
          , @w_pe_stndrd_calc_fac_1             money                   = 0
          , @w_pe_stndrd_calc_fac_2             money                   = 0
          , @w_pe_spec_calc_fac_1               money                   = 0
          , @w_pe_spec_calc_fac_2               money                   = 0
          , @w_pe_spec_calc_fac_3               money                   = 0
          , @w_pe_spec_calc_fac_4               money                   = 0
          , @w_pe_limit_amt                     money                   = 0
          , @w_pe_limit_cyc_type                char(1)                 = '0'
          , @w_pe_ded_rec_meth                  char(1)                 = ''
          , @w_pe_rec_fixed_amt                 money                   = 0
          , @w_pe_rec_fixed_pct                 float                   = 0
          , @w_pe_min_pay_pd_rec_amt            money                   = 0
          , @w_pe_rate_tbl_id                   char(10)                = ''
          , @w_pe_ben_plan_id                   char(15)                = ''
          , @w_rt_descp                         char(35)                = ''
          , @w_rte_descp                        char(35)                = ''
          , @w_epel_towards_lmt_amt             money                   = 0
          , @w_tpp_descp                        char(15)                = ''
          , @w_comments_flag                    char(1)                 = ''
          , @w_current_ver_eff_date             datetime                = '19000101'
          , @w_pe_curr_code                     char(3)                 = 'XCD'
          , @w_scrty_cat_code                   char(3)                 = 'NA'
          , @w_original_stop_date               datetime                = '19000101'
          , @w_pension_tot_distn_ind            char(1)                 = 'N'
          , @w_pension_distn_code_1             char(1)                 = '0'
          , @w_pension_distn_code_2             char(1)                 = '0'
          , @w_pre_1990_rpp_ctrb_type           char(1)                 = '0'
          , @w_first_roth_ctrb                  datetime                = '29991231'
          , @w_ira_sep_simple_ind               char(1)                 = 'N'
          , @w_txbl_amt_not_det_ind             char(1)                 = 'N'
          , @w_result_set_ind                   char(1)                 = 'N'



    -- This section declares the interface values from Global HR
    DECLARE	@event_id_01							char(02)
          , @emp_id_01								char(15)
          , @eff_date_01							char(10)
          , @first_name_01							char(25)
          , @first_middle_name_01					char(25)
          , @last_name_01							char(30)
          , @empl_id_01								char(10)
          , @national_id_1_type_code_01				char(05)
          , @national_id_1_01						char(20)
          , @organization_group_id_01				char(05)
          , @organization_chart_name_01				varchar(64)
          , @organization_unit_name_01				varchar(240)
          , @emp_status_classn_code_01				char(02)
          , @position_title_01						char(60)
          , @employment_type_code_01				char(05)
          , @annual_salary_amt_01					char(15)
          , @begin_date_02							char(10)
          , @end_date_02							char(10)
          , @pay_status_code_03						char(01)
          , @pay_group_id_03						char(10)
          , @pay_element_ctrl_grp_id_03				char(10)
          , @time_reporting_meth_code_03			char(01)
          , @employment_info_chg_reason_cd_03		char(05)
          , @emp_location_code_03					char(10)
          , @emp_status_code_5						char(02)
          , @reason_code_5							char(02)
          , @emp_expected_return_date_5				char(10)
          , @pay_through_date_5						char(10)
          , @emp_death_date_5						char(10)
          , @consider_for_rehire_ind_5				char(01)
          , @pay_element_desc_06					char(20)
          , @emp_calculation_06						char(15)
          -- CJP 7/7/2025
          , @tax_flag                               char(1)         -- individual_personal.ind_2
          , @nic_flag                               char(1)         -- individual_personal.ind_1
          , @tax_ceiling_amt                        char(15)        -- employee.user_monetary_amt_1
          , @labor_grp_code                         char(50)        -- emp_assignment.user_text_1
          , @file_source                            char(50)        -- 'SS VENUS' or 'SS GANYMEDE'


    DECLARE @w_eff_date                             datetime
    DECLARE @w_begin_date                           datetime
    DECLARE @w_end_date                             datetime


    CREATE TABLE #tbl_ghr_msg
        (
          msg_id                                    char(15)            NOT NULL
        , msg_p1                                    varchar(255)        NOT NULL
        , msg_p2                                    varchar(255)        NOT NULL
        , msg_desc                                  varchar(255)        NOT NULL
        )


    CREATE TABLE #tbl_msg_master
        (
          msg_id            char(15)    NOT NULL
        , severity_cd       tinyint     NOT NULL
        , msg_text          varchar(255)    NOT NULL
        , msg_text_2        varchar(255)    NOT NULL
        , msg_text_3        varchar(255)    NOT NULL
        , loop_flag         char(1)     NOT NULL
        )


    BEGIN TRY

        SET @v_step_position = '#tbl_msg_master'

        ---------------------------------------------------------------------------
        -- Retrieve all error message templates
        ---------------------------------------------------------------------------
        INSERT INTO #tbl_msg_master
        SELECT msg_id
            , severity_cd
            , msg_text
            , msg_text_2
            , msg_text_3
            , 'N' AS loop_flag
        FROM DBSCOMMON.dbo.message_master
        WHERE (msg_id IN (
                         'U00028'
                        ,'U00009'
                        ,'U00029'
                        ,'U00011'
                        ,'U00012'
                        ,'U00027'
                        ,'U00030'
                        ,'U00039'
                        ,'U00047'
                        ,'U00010'
                        ,'U00101'
                        ,'U00102'
                        ))

        -- ID Message templates that need to loop through errors to add to log table
        UPDATE #tbl_msg_master
        SET loop_flag = 'Y'
        WHERE (msg_id IN (
                         'U00029'
                        ,'U00011'
                        ,'U00012'
                        ,'U00027'
                        ,'U00030'
                        ,'U00039'
                        ,'U00047'
                        ,'U00101'
                        ,'U00102'
                        ))



        SET @v_step_position = 'Declaring cursor crsrHR'

        -- Loop through tbl_ghr_msg to populate error message log entry
        DECLARE crsrHR CURSOR FAST_FORWARD FOR
        SELECT t.event_id_01
             , t.emp_id_01
             , t.eff_date_01
             , t.first_name_01
             , t.first_middle_name_01
             , t.last_name_01
             , t.empl_id_01
             , t.national_id_1_type_code_01
             , t.national_id_1_01
             , t.organization_group_id_01
             , t.organization_chart_name_01
             , t.organization_unit_name_01
             , t.emp_status_classn_code_01
             , t.position_title_01
             , t.employment_type_code_01
             , t.annual_salary_amt_01
             , t.begin_date_02
             , t.end_date_02
             , t.pay_status_code_03
             , t.pay_group_id_03
             , t.pay_element_ctrl_grp_id_03
             , t.time_reporting_meth_code_03
             , t.employment_info_chg_reason_cd_03
             , t.emp_location_code_03
             , t.emp_status_code_5
             , t.reason_code_5
             , t.emp_expected_return_date_5
             , t.pay_through_date_5
             , t.emp_death_date_5
             , t.consider_for_rehire_ind_5
             , t.pay_element_desc_06
             , t.emp_calculation_06
             , t.tax_flag
             , t.nic_flag
             , t.tax_ceiling_amt
             , t.labor_grp_code
             , t.file_source
        FROM #ghr_employee_events_temp t
		WHERE (event_id_01 = @v_EVENT_ID_PAY_ELE)

        SET @v_step_position = 'Opening cursor crsrHR'
        OPEN crsrHR

        SET @v_step_position = 'Fetching cursor crsrHR'
        FETCH crsrHR
        INTO  @event_id_01
            , @emp_id_01
            , @eff_date_01
            , @first_name_01
            , @first_middle_name_01
            , @last_name_01
            , @empl_id_01
            , @national_id_1_type_code_01
            , @national_id_1_01
            , @organization_group_id_01
            , @organization_chart_name_01
            , @organization_unit_name_01
            , @emp_status_classn_code_01
            , @position_title_01
            , @employment_type_code_01
            , @annual_salary_amt_01
            , @begin_date_02
            , @end_date_02
            , @pay_status_code_03
            , @pay_group_id_03
            , @pay_element_ctrl_grp_id_03
            , @time_reporting_meth_code_03
            , @employment_info_chg_reason_cd_03
            , @emp_location_code_03
            , @emp_status_code_5
            , @reason_code_5
            , @emp_expected_return_date_5
            , @pay_through_date_5
            , @emp_death_date_5
            , @consider_for_rehire_ind_5
            , @pay_element_desc_06
            , @emp_calculation_06
            , @tax_flag
            , @nic_flag
            , @tax_ceiling_amt
            , @labor_grp_code
            , @file_source


        WHILE (@@FETCH_STATUS = 0)
        BEGIN

            SET @v_step_position = 'Begin crsrHR While Loop'

            SET @w_fatal_error = '0'


            ---------------------------------------------------------------------------
            -- Check to see if the employee exists
            ---------------------------------------------------------------------------
            IF NOT EXISTS (
                           SELECT 1
                           FROM DBShrpn.dbo.emp_status
                           WHERE emp_id = @emp_id_01
                          )
                BEGIN

                    SET @msg_id = 'U00012'
                    SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

                    UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status	= @v_ACTIVITY_STATUS_BAD
                    WHERE activity_date	= @p_activity_date
                      AND emp_id_01 = @emp_id_01
                      AND pay_element_desc_06 = @pay_element_desc_06
                      AND event_id_01 = @v_EVENT_ID_PAY_ELE

                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id      As msg_id
                        , @emp_id_01    As msg_p1
                        , ''            As msg_p2
                        -- create error message for logging
                        , REPLACE(t.msg_text, '@1', @emp_id_01) AS msg_desc
                    FROM #tbl_msg_master t
                    WHERE (msg_id = @msg_id)

                    -- Historical Message for reporting purpose
                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                    SELECT  @msg_id						As msg_id,
                            @v_EVENT_ID_PAY_ELE			As event_id,
                            @emp_id_01 						As emp_id,
                            @eff_date_01					As eff_date,
                            @pay_element_desc_06			As pay_element_id,
                            @emp_id_01						As msg_p1,
                            CONVERT(char,@eff_date_01,112)	As msg_p2,
                            'Employee does not exists'		As msg_desc,
                            @p_activity_date				AS activity_date

                    SET @w_fatal_error = '5'

                END


            ---------------------------------------------------------------------------
            -- Check to see if the employer exists
            ---------------------------------------------------------------------------
            IF NOT EXISTS (
                           SELECT 1
                           FROM DBShrpn.dbo.employer
                           WHERE empl_id = @empl_id_01
                          )
            BEGIN

                SET @msg_id = 'U00039'
                SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

                UPDATE DBShrpn.dbo.ghr_employee_events_aud
                SET activity_status	= @v_ACTIVITY_STATUS_BAD
                WHERE activity_date = @p_activity_date
                  AND emp_id_01 = @emp_id_01
                  AND pay_element_desc_06 = @pay_element_desc_06
                  AND event_id_01 = @v_EVENT_ID_PAY_ELE

                INSERT INTO #tbl_ghr_msg
                SELECT @msg_id      As msg_id
                    , @emp_id_01    As msg_p1
                    , ''            As msg_p2
                    -- create error message for logging
                    , REPLACE(t.msg_text, '@1', @empl_id_01) AS msg_desc
                FROM #tbl_msg_master t
                WHERE (msg_id = @msg_id)

                -- Historical Message for reporting purpose
                INSERT INTO DBShrpn.dbo.ghr_historical_message
                SELECT  @msg_id                                      As msg_id,
                        @v_EVENT_ID_PAY_ELE                          As event_id,
                        @emp_id_01                                   As emp_id,
                        @eff_date_01                                 As eff_date,
                        @pay_element_desc_06                         As pay_element_id,
                        @emp_id_01                                   As msg_p1,
                        @empl_id_01                                  As msg_p2,
                        'Employer does not exist - bypassing record' As msg_desc,
                        @p_activity_date                             AS activity_date

                SET @w_fatal_error = '5'

            END


            ---------------------------------------------------------------------------
            -- Validate Amount
            ---------------------------------------------------------------------------
            SET @v_step_position 'Validate Pay Element Amount'

            IF (TRY_CONVERT(money, @emp_calculation_06) IS NULL)
                BEGIN

                    SET @msg_id = 'U00101'  -- New code
                    SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

                    UPDATE DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status	= @v_ACTIVITY_STATUS_BAD
                    WHERE activity_date = @p_activity_date
                    AND emp_id_01 = @emp_id_01
                    AND pay_element_desc_06 = @pay_element_desc_06
                    AND event_id_01 = @v_EVENT_ID_PAY_ELE

                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id      As msg_id
                        , @emp_id_01    As msg_p1
                        , @pay_element_desc_06 As msg_p2
                        -- create error message for logging
                        , REPLACE(REPLACE(REPLACE(t.msg_text, '@1', @emp_calculation_06), '@2', @emp_id_01), '@3', @pay_element_desc_06) AS msg_desc
                    FROM #tbl_msg_master t
                    WHERE (msg_id = @msg_id)

                    -- Historical Message for reporting purpose
                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                    SELECT  @msg_id                                      As msg_id,
                            @v_EVENT_ID_PAY_ELE                          As event_id,
                            @emp_id_01                                   As emp_id,
                            @eff_date_01                                 As eff_date,
                            @pay_element_desc_06                         As pay_element_id,
                            @emp_id_01                                   As msg_p1,
                            @empl_id_01                                  As msg_p2,
                            'Invalid pay element amount.' As msg_desc,
                            @p_activity_date                             AS activity_date

                    SET @w_fatal_error = '5'

                END
            ELSE
                -- Convert amount to money data type
                SELECT @w_standard_calc_factor_1 = CONVERT(money, @emp_calculation_06)


            ---------------------------------------------------------------------------
            -- Validate Dates
            ---------------------------------------------------------------------------
            -- Invalid date value from HCM, ''@1'', for employee, @2, and event id, @3.

            -- Effective Date
            IF (TRY_CONVERT(datetime, @eff_date_01) IS NULL)
                BEGIN

                    SET @msg_id = 'U00102'  -- New code
                    SET @v_step_position = 'Validation Effective Date - ' + RTRIM(@msg_id)

                    UPDATE DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status	= @v_ACTIVITY_STATUS_BAD
                    WHERE activity_date = @p_activity_date
                    AND emp_id_01 = @emp_id_01
                    AND pay_element_desc_06 = @pay_element_desc_06
                    AND event_id_01 = @v_EVENT_ID_PAY_ELE

                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id      As msg_id
                        , @emp_id_01    As msg_p1
                        , @pay_element_desc_06 As msg_p2
                        -- create error message for logging
                        , REPLACE(REPLACE(REPLACE(t.msg_text, '@1', @eff_date_01), '@2', @emp_id_01), '@3', @v_EVENT_ID_PAY_ELE) AS msg_desc
                    FROM #tbl_msg_master t
                    WHERE (msg_id = @msg_id)

                    -- Historical Message for reporting purpose
                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                    SELECT  @msg_id                                      As msg_id,
                            @v_EVENT_ID_PAY_ELE                          As event_id,
                            @emp_id_01                                   As emp_id,
                            @eff_date_01                                 As eff_date,
                            @pay_element_desc_06                         As pay_element_id,
                            @emp_id_01                                   As msg_p1,
                            @empl_id_01                                  As msg_p2,
                            'Invalid Effective Date' As msg_desc,
                            @p_activity_date                             AS activity_date

                    SET @w_fatal_error = '5'

                END
            ELSE
                -- Convert amount to money data type
                SELECT @w_eff_date = CONVERT(money, @eff_date_01)


            -- Begin Date
            IF (TRY_CONVERT(datetime, @begin_date_02) IS NULL)
                BEGIN

                    SET @msg_id = 'U00102'  -- New code
                    SET @v_step_position = 'Validation Begin Date - ' + RTRIM(@msg_id)

                    UPDATE DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status	= @v_ACTIVITY_STATUS_BAD
                    WHERE activity_date = @p_activity_date
                    AND emp_id_01 = @emp_id_01
                    AND pay_element_desc_06 = @pay_element_desc_06
                    AND event_id_01 = @v_EVENT_ID_PAY_ELE

                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id      As msg_id
                        , @emp_id_01    As msg_p1
                        , @pay_element_desc_06 As msg_p2
                        -- create error message for logging
                        , REPLACE(REPLACE(REPLACE(t.msg_text, '@1', @begin_date_02), '@2', @emp_id_01), '@3', @v_EVENT_ID_PAY_ELE) AS msg_desc
                    FROM #tbl_msg_master t
                    WHERE (msg_id = @msg_id)

                    -- Historical Message for reporting purpose
                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                    SELECT  @msg_id                                      As msg_id,
                            @v_EVENT_ID_PAY_ELE                          As event_id,
                            @emp_id_01                                   As emp_id,
                            @eff_date_01                                 As eff_date,
                            @pay_element_desc_06                         As pay_element_id,
                            @begin_date_02                                   As msg_p1,
                            ''                                  As msg_p2,
                            'Invalid Begin Date' As msg_desc,
                            @p_activity_date                             AS activity_date

                    SET @w_fatal_error = '5'

                END
            ELSE
                -- Convert amount to money data type
                SELECT @w_start_date = CONVERT(datetime, @begin_date_02)

            -- End Date
            IF (TRY_CONVERT(datetime, @end_date_02) IS NULL)
                BEGIN

                    SET @msg_id = 'U00102'  -- New code
                    SET @v_step_position = 'Validation End Date - ' + RTRIM(@msg_id)

                    UPDATE DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status	= @v_ACTIVITY_STATUS_BAD
                    WHERE activity_date = @p_activity_date
                    AND emp_id_01 = @emp_id_01
                    AND pay_element_desc_06 = @pay_element_desc_06
                    AND event_id_01 = @v_EVENT_ID_PAY_ELE

                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id      As msg_id
                        , @emp_id_01    As msg_p1
                        , @pay_element_desc_06 As msg_p2
                        -- create error message for logging
                        , REPLACE(REPLACE(REPLACE(t.msg_text, '@1', @begin_date_02), '@2', @emp_id_01), '@3', @v_EVENT_ID_PAY_ELE) AS msg_desc
                    FROM #tbl_msg_master t
                    WHERE (msg_id = @msg_id)

                    -- Historical Message for reporting purpose
                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                    SELECT  @msg_id                                      As msg_id,
                            @v_EVENT_ID_PAY_ELE                          As event_id,
                            @emp_id_01                                   As emp_id,
                            @eff_date_01                                 As eff_date,
                            @pay_element_desc_06                         As pay_element_id,
                            @begin_date_02                              As msg_p1,
                            ''                                  As msg_p2,
                            'Invalid Begin Date' As msg_desc,
                            @p_activity_date                             AS activity_date

                    SET @w_fatal_error = '5'

                END
            ELSE
                -- Convert amount to money data type
                SELECT @w_stop_date = CONVERT(money, @end_date_02)


            ---------------------------------------------------------------------------
            --	Obtain the current record for this employee pay element
            ---------------------------------------------------------------------------
            SELECT	@i_pay_element_exists	=	'N'


            SELECT @i_emp_id				=	emp_id,         --don't need
                   @i_empl_id				=	empl_id,        --don't need
                   @i_pay_element_id		=	pay_element_id, -- don't need
                   @i_eff_date				=	eff_date,
                   @i_stop_date			    =	stop_date,
                   @i_pay_element_exists	=	'Y'
            FROM DBShrpn.dbo.emp_pay_element	pe
            WHERE emp_id         =	@emp_id_01
              AND empl_id        =	@empl_id_01
              AND pay_element_id =	@pay_element_desc_06
              AND eff_date       =	(
                                     SELECT MAX(eff_date)
                                     FROM DBShrpn.dbo.emp_pay_element t
                                     WHERE t.emp_id         = pe.emp_id
                                       AND t.empl_id        = pe.empl_id
                                       AND t.pay_element_id = pe.pay_element_id
                                    )


            ---------------------------------------------------------------------------
            --	Check to see that the new effective date is greater than the current effective date
            ---------------------------------------------------------------------------
            IF (@i_pay_element_exists = 'Y') AND
               (@i_eff_date           > @w_eff_date)
                BEGIN

                    SET @msg_id = 'U00027'
                    SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

                    UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                        SET activity_status	= @v_ACTIVITY_STATUS_BAD
                    WHERE activity_date	=	@p_activity_date
                        AND emp_id_01 = @emp_id_01
                        AND event_id_01 = @v_EVENT_ID_PAY_ELE

                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id						As msg_id
                        , @eff_date_01					As msg_p1
                        , @emp_id_01			As msg_p2
                        , REPLACE(REPLACE(t.msg_text, '@1', @eff_date_01), '@2', @emp_id_01) AS msg_desc
                    FROM #tbl_msg_master t
                    WHERE (msg_id = @msg_id)

                    -- Historical Message for reporting purpose
                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                    SELECT  @msg_id						As msg_id,
                            @v_EVENT_ID_PAY_ELE             As event_id,
                            @emp_id_01 						As emp_id,
                            @eff_date_01					As eff_date,
                            @pay_element_desc_06			As pay_element_id,
                            @emp_id_01						As msg_p1,
                            @emp_id_01						As msg_p2,
                            'The new effective date for employee must be greater than the current effective date'		As msg_desc,
                            @p_activity_date				AS activity_date

                    SET	@w_fatal_error = '5'

                END



            ---------------------------------------------------------------------------
            --	Validate that the start date is the same or earlier than the pay through date of the employee
            ---------------------------------------------------------------------------
            -- The Begin Date, @1, cannot be greater than the pay through date for employee, @2.

            SELECT @pay_through_date = pay_through_date
            FROM DBShrpn.dbo.emp_employment ee
            WHERE emp_id =	@emp_id_01
              AND eff_date = (
                              SELECT MAX(t.eff_date)
                              FROM DBShrpn.dbo.emp_employment t
                              WHERE t.emp_id =	ee.emp_id
                             )



            IF (@w_start_date > @pay_through_date)
                BEGIN

                    SET @msg_id = 'U00030'
                    SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

                    UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                        SET activity_status	= @v_ACTIVITY_STATUS_BAD
                    WHERE activity_date	=	@p_activity_date
                        AND emp_id_01		=	@emp_id_01
                        AND event_id_01		= @v_EVENT_ID_PAY_ELE

                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id					    As msg_id
                        , @emp_id_01					As msg_p1
                        , @empl_id_01					As msg_p2
                        -- create error message for logging
                        , REPLACE(REPLACE(t.msg_text, '@1', @w_start_date), '@2', @emp_id_01) AS msg_desc
                    FROM #tbl_msg_master t
                    WHERE (msg_id = @msg_id)

                    -- Historical Message for reporting purpose
                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                    SELECT  @msg_id						As msg_id,
                            @v_EVENT_ID_PAY_ELE As event_id,
                            @emp_id_01 						As emp_id,
                            @eff_date_01					As eff_date,
                            @pay_element_desc_06			As pay_element_id,
                            @emp_id_01						As msg_p1,
                            @emp_id_01						As msg_p2,
                            'The Begin Date cannot be greater than the pay through date for employee.'		As msg_desc,
                            @p_activity_date				AS activity_date


                    SET @w_fatal_error = '5'

                END


            ---------------------------------------------------------------------------
            --- Validate the stop date against the effective date
            ---------------------------------------------------------------------------
            -- If stop date less than eff date then set eff date = stop date
            IF (@w_stop_date < @w_eff_date)
            --IF CONVERT(date, @end_date_02) < CONVERT(date, @eff_date_01)
                BEGIN

                    SET @msg_id = 'U00047'
                    SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

                    UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                        SET activity_status	= @v_ACTIVITY_STATUS_BAD
                    WHERE activity_date	=	@p_activity_date
                        AND emp_id_01		=	@emp_id_01
                        AND event_id_01		= @v_EVENT_ID_PAY_ELE

                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id					    As msg_id
                        , @end_date_02					As msg_p1
                        , @emp_id_01					As msg_p2
                        -- create error message for logging
                        , REPLACE(REPLACE(t.msg_text, '@1', @end_date_02), '@2', @emp_id_01) AS msg_desc
                    FROM #tbl_msg_master t
                    WHERE (msg_id = @msg_id)

                    -- Historical Message for reporting purpose
                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                    SELECT  @msg_id						As msg_id,
                            @v_EVENT_ID_PAY_ELE				As event_id,
                            @emp_id_01 						As emp_id,
                            @eff_date_01					As eff_date,
                            @pay_element_desc_06			As pay_element_id,
                            @emp_id_01						As msg_p1,
                            @emp_id_01						As msg_p2,
                            'The stop date must be greater or equal to the employee pay element effective date - Defaulting effective date to stop date.'		As msg_desc,
                            @p_activity_date				AS activity_date

                    SET @w_eff_date = @w_stop_date
                    --SELECT @eff_date_01 = @end_date_02

                END


            IF @w_fatal_error = '5'
                GOTO BYPASS_EMPLOYEE


            ---------------------------------------------------------------------------
            -- start pay element logic
            ---------------------------------------------------------------------------
            SET @v_step_position = 'Begin Pay Element Setup'
            -- Does record exist with same effective date?
            IF	NOT EXISTS (
                            SELECT 1
                            FROM DBShrpn.dbo.emp_pay_element
                            WHERE emp_id = @emp_id_01
                              AND empl_id = @empl_id_01
                              AND pay_element_id = @pay_element_desc_06
                              AND eff_date = @w_eff_date
                           )
                BEGIN

                    IF (@i_pay_element_exists = 'Y') AND  -- record exists but <> eff date
                       --(CONVERT(date, @i_stop_date) < CONVERT(date, @w_stop_date_1))    -- compare old stop date with eot date
                       (@i_stop_date < @v_END_OF_TIME_DATE)
                        BEGIN
                            -- Update existing record with new stop date
                            UPDATE DBShrpn.dbo.emp_pay_element
                            SET  stop_date     = @v_END_OF_TIME_DATE
                            WHERE emp_id       = @i_emp_id
                            AND empl_id        = @i_empl_id
                            AND pay_element_id = @i_pay_element_id
                            AND eff_date       = @i_eff_date
                        END


                    -- Create new pay element record
                    EXEC DBShrpn.dbo.usp_ins_hepy_insert
                                @w_stop_date	                        =	@w_stop_date_1,
                                @p_emp_id								=	@emp_id_01,
                                @p_empl_id								=	@empl_id_01,
                                @p_pay_element_id						=	@pay_element_desc_06,
                                @p_eff_date								=	@eff_date_01,
                                @p_prior_eff_date						=	@w_prior_eff_date,
                                @p_next_eff_date						=	@w_next_eff_date,
                                @p_inact_by_pay_element_ind				=	@w_inact_by_pay_element_ind,
                                @p_start_date							=	@begin_date_02,
                                @p_stop_date							=	@w_stop_date,
                                @p_change_reason_code					=	@w_change_reason_code,
                                @p_pay_ele_pay_pd_sched_code			=	@w_pay_ele_pay_pd_sched_code,
                                @p_calc_meth_code						=	@w_calc_meth_code,
                                @p_standard_calc_factor_1				=	@w_standard_calc_factor_1,
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
                                @ret									=	@v_ret_val_usp_ins_hepy_insert

                    IF (@w_stop_date < @v_END_OF_TIME_DATE) -- not sure why not comparing to previous record's stop date -- Are all new records stop date = 12/31/2999?
                    --IF (CONVERT(date, @end_date_02) < CONVERT(date, @w_stop_date_1))
                        BEGIN
                            UPDATE DBShrpn.dbo.emp_pay_element
                            SET  stop_date = CASE
                                               --WHEN CONVERT(date, @end_date_02) < CONVERT(date, @i_eff_date) THEN @i_eff_date
                                               WHEN @w_stop_date < @i_eff_date THEN @i_eff_date
                                               ELSE CONVERT(date, @end_date_02)
                                             END
                            WHERE emp_id         = @emp_id_01
                              AND empl_id        = @empl_id_01
                              AND pay_element_id = @pay_element_desc_06
                              AND eff_date       = @w_eff_date  --@eff_date_01
                        END


                    IF (@i_pay_element_exists = 'Y')
                        BEGIN
                            --  Current Record
                            UPDATE DBShrpn.dbo.emp_pay_element
                            SET prior_eff_date				=	@i_eff_date
                            WHERE emp_id					=	@emp_id_01
                            AND	empl_id						=	@empl_id_01
                            AND	pay_element_id				=	@pay_element_desc_06
                            AND	eff_date					=	@w_eff_date     --@eff_date_01

                            -- Prior Record
                            UPDATE DBShrpn.dbo.emp_pay_element
                            SET next_eff_date				=	@w_eff_date     --@eff_date_01
                            WHERE	emp_id					=	@emp_id_01
                            AND	empl_id						=	@empl_id_01
                            AND	pay_element_id				=	@pay_element_desc_06
                            AND	eff_date					=	@i_eff_date
                        END

                END
	        ELSE    -- Exact record exists
                BEGIN

                    UPDATE	DBShrpn.dbo.emp_pay_element
                    SET start_date             = @begin_date_02,
                        stop_date              = @w_stop_date       --@end_date_02,
                        standard_calc_factor_1 = @emp_calculation_06,
                        calc_meth_code         = @w_calc_meth_code,
                        rate_tbl_id            = @w_rate_tbl_id,
                        rate_code              = @w_rate_code
                    WHERE emp_id         = @emp_id_01
                      AND empl_id        = @empl_id_01
                      AND pay_element_id = @pay_element_desc_06
                      AND eff_date       = @w_eff_date      --@eff_date_01

                END



            BYPASS_EMPLOYEE:

            FETCH crsrHR
            INTO  @event_id_01
                , @emp_id_01
                , @eff_date_01
                , @first_name_01
                , @first_middle_name_01
                , @last_name_01
                , @empl_id_01
                , @national_id_1_type_code_01
                , @national_id_1_01
                , @organization_group_id_01
                , @organization_chart_name_01
                , @organization_unit_name_01
                , @emp_status_classn_code_01
                , @position_title_01
                , @employment_type_code_01
                , @annual_salary_amt_01
                , @begin_date_02
                , @end_date_02
                , @pay_status_code_03
                , @pay_group_id_03
                , @pay_element_ctrl_grp_id_03
                , @time_reporting_meth_code_03
                , @employment_info_chg_reason_cd_03
                , @emp_location_code_03
                , @emp_status_code_5
                , @reason_code_5
                , @emp_expected_return_date_5
                , @pay_through_date_5
                , @emp_death_date_5
                , @consider_for_rehire_ind_5
                , @pay_element_desc_06
                , @emp_calculation_06
                , @tax_flag
                , @nic_flag
                , @tax_ceiling_amt
                , @labor_grp_code
                , @file_source

        END  -- Error Loop

        -- Cleanup Cursor
        CLOSE crsrHR
        DEALLOCATE crsrHR



        ---------------------------------------------------------------------------
        -- Log warning message U00000 -- < NEW HIRE SECTION (1) >
        ---------------------------------------------------------------------------

        SET @msg_id = 'U00028'
        SET @v_step_position = 'Log ' + @msg_id

        SELECT @w_msg_text    = msg_text
            , @w_msg_text_2  = msg_text_2
            , @w_msg_text_3  = msg_text_3
            , @w_severity_cd = severity_cd
        FROM #tbl_msg_master
        WHERE (msg_id = @msg_id)

        EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2
            @userid   = @p_userid
            , @batch    = @p_batchname
            , @qual     = @p_qualifier
            , @msgno    = @msg_id
            , @severity = @w_severity_cd
            , @text     = @w_msg_text
            , @text_2   = @w_msg_text_2
            , @text_3   = @w_msg_text_3


        ---------------------------------------------------------------------------
        -- Send notification of warning message U00009  -- < BEGINING OF WARNING MESSAGES: >
        ---------------------------------------------------------------------------
        SET @msg_id = 'U00009'
        SET @v_step_position = 'Log ' + @msg_id

        SELECT @w_msg_text    = msg_text
            , @w_msg_text_2  = msg_text_2
            , @w_msg_text_3  = msg_text_3
            , @w_severity_cd = severity_cd
        FROM #tbl_msg_master
        WHERE (msg_id = @msg_id)

        EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2
            @userid   = @p_userid
            , @batch    = @p_batchname
            , @qual     = @p_qualifier
            , @msgno    = @msg_id
            , @severity = @w_severity_cd
            , @text     = @w_msg_text
            , @text_2   = @w_msg_text_2
            , @text_3   = @w_msg_text_3


        ---------------------------------------------------------------------------
        -- Send notification of warning message U00011 -- Blank Line
        ---------------------------------------------------------------------------
        SET @msg_id = 'U00011'
        SET @v_step_position = 'Log ' + @msg_id

        SELECT @w_msg_text    = msg_text
            , @w_msg_text_2  = msg_text_2
            , @w_msg_text_3  = msg_text_3
            , @w_severity_cd = severity_cd
        FROM #tbl_msg_master
        WHERE (msg_id = @msg_id)

        EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2
            @userid   = @p_userid
            , @batch    = @p_batchname
            , @qual     = @p_qualifier
            , @msgno    = @msg_id
            , @severity = @w_severity_cd
            , @text     = @w_msg_text
            , @text_2   = @w_msg_text_2
            , @text_3   = @w_msg_text_3


        ---------------------------------------------------------------------------
        -- Send notification of warning message U00003 - Total nbr of employees that already exist: @1
        ---------------------------------------------------------------------------
        SET @msg_id = 'U00029'
        SET @v_step_position = 'Log ' + @msg_id

        SELECT @msg_id        = msg_id
            , @w_msg_text    = msg_text
            , @w_msg_text_2  = msg_text_2
            , @w_msg_text_3  = msg_text_3
            , @w_severity_cd = severity_cd
        FROM #tbl_msg_master
        WHERE (msg_id = @msg_id)

        -- Get total new hire records from HCM
        SELECT @maxx = CAST(COUNT(*) AS varchar(6))
        FROM #tbl_ghr_msg
        WHERE (msg_id = @msg_id)

        IF (CHARINDEX('@1', @w_msg_text,1) > 0)
            SELECT @w_msg_text = REPLACE(@w_msg_text, '@1', @maxx)

        EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2
            @userid   = @p_userid
            , @batch    = @p_batchname
            , @qual     = @p_qualifier
            , @msgno    = @msg_id
            , @severity = @w_severity_cd
            , @text     = @w_msg_text
            , @text_2   = @w_msg_text_2
            , @text_3   = @w_msg_text_3


        ---------------------------------------------------------------------------
        -- Add log entries that contain employee details
        ---------------------------------------------------------------------------
        SET @v_step_position = 'Log Cursor'

        -- Loop through tbl_ghr_msg to populate error message log entry
        DECLARE crsrLog CURSOR FAST_FORWARD FOR
        SELECT msg.msg_id
            , msg.severity_cd
            , ghr.msg_desc
            , msg.msg_text_2
            , msg.msg_text_3
        FROM #tbl_ghr_msg ghr
        JOIN #tbl_msg_master msg ON
            (ghr.msg_id = msg.msg_id)
        WHERE (msg.loop_flag = 'Y')

        OPEN crsrLog

        FETCH crsrLog
        INTO @msg_id
        , @w_severity_cd
        , @w_msg_text
        , @w_msg_text_2
        , @w_msg_text_3


        WHILE (@@FETCH_STATUS = 0)
        BEGIN
            -- Add entries to DBSpscb..ssw_psc_messages_work
            EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2
                @userid   = @p_userid
                , @batch    = @p_batchname
                , @qual     = @p_qualifier
                , @msgno    = @msg_id
                , @severity = @w_severity_cd
                , @text     = @w_msg_text
                , @text_2   = @w_msg_text_2
                , @text_3   = @w_msg_text_3

			FETCH crsrLog
			INTO @msg_id
			, @w_severity_cd
			, @w_msg_text
			, @w_msg_text_2
			, @w_msg_text_3

        END

        CLOSE crsrLog
        DEALLOCATE crsrLog


        ---------------------------------------------------------------------------
        -- Send notification of warning message U00011 -- Blank Line
        ---------------------------------------------------------------------------
        SET @msg_id = 'U00011'
        SET @v_step_position = 'Log ' + @msg_id

        SELECT @w_msg_text    = msg_text
            , @w_msg_text_2  = msg_text_2
            , @w_msg_text_3  = msg_text_3
            , @w_severity_cd = severity_cd
        FROM #tbl_msg_master
        WHERE (msg_id = @msg_id)

        EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2
            @userid   = @p_userid
            , @batch    = @p_batchname
            , @qual     = @p_qualifier
            , @msgno    = @msg_id
            , @severity = @w_severity_cd
            , @text     = @w_msg_text
            , @text_2   = @w_msg_text_2
            , @text_3   = @w_msg_text_3


        ---------------------------------------------------------------------------
        -- Send notification of warning message U00010 -- <ENDING OF WARNING MESSAGES: >
        ---------------------------------------------------------------------------
        SET @msg_id = 'U00010'
        SET @v_step_position = 'Log ' + @msg_id

        SELECT @w_msg_text    = msg_text
            , @w_msg_text_2  = msg_text_2
            , @w_msg_text_3  = msg_text_3
            , @w_severity_cd = severity_cd
        FROM #tbl_msg_master
        WHERE (msg_id = @msg_id)

        EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2
            @userid   = @p_userid
            , @batch    = @p_batchname
            , @qual     = @p_qualifier
            , @msgno    = @msg_id
            , @severity = @w_severity_cd
            , @text     = @w_msg_text
            , @text_2   = @w_msg_text_2
            , @text_3   = @w_msg_text_3


        ---------------------------------------------------------------------------
        -- Send notification of warning message U00011 -- Blank Line
        ---------------------------------------------------------------------------
        SET @msg_id = 'U00011'
        SET @v_step_position = 'Log ' + @msg_id

        SELECT @w_msg_text    = msg_text
            , @w_msg_text_2  = msg_text_2
            , @w_msg_text_3  = msg_text_3
            , @w_severity_cd = severity_cd
        FROM #tbl_msg_master
        WHERE (msg_id = @msg_id)

        EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2
            @userid   = @p_userid
            , @batch    = @p_batchname
            , @qual     = @p_qualifier
            , @msgno    = @msg_id
            , @severity = @w_severity_cd
            , @text     = @w_msg_text
            , @text_2   = @w_msg_text_2
            , @text_3   = @w_msg_text_3

        SET @v_step_position = 'End Logging'

    END TRY
    BEGIN CATCH

        SELECT @ErrorMessage  = LEFT(ERROR_MESSAGE(), 1024) + ' (' + @v_step_position + ')'
             , @ErrorSeverity = ERROR_SEVERITY()
             , @ErrorState    = ERROR_STATE()
             , @v_ret_val     = -1

        SET @p_status = @v_ret_val

        -- Handle cursors
        IF (CURSOR_STATUS('local', 'crsrHR') > 0)
        BEGIN
            CLOSE crsrHR
            DEALLOCATE crsrHR
        END

        IF (CURSOR_STATUS('local', 'crsrLog') > 0)
        BEGIN
            CLOSE crsrLog
            DEALLOCATE crsrLog
        END

        /*
                SELECT @v_step_position AS step_position
                    , @ErrorMessage  AS err_msg
                    , @ErrorSeverity AS err_sev
                    , @ErrorState    AS err_state
        */

        RAISERROR(@ErrorMessage
                  , @ErrorSeverity
                  , @ErrorState
                  )

    END CATCH


    -- Cleanup temp tables
    DROP TABLE #tbl_ghr_msg
    DROP TABLE #tbl_msg_master


    RETURN @v_ret_val

END
GO

ALTER AUTHORIZATION ON dbo.usp_ins_pay_element TO  SCHEMA OWNER
GO

IF OBJECT_ID(N'dbo.usp_ins_pay_element', N'P') IS NOT NULL
    PRINT N'<<< CREATED PROCEDURE dbo.usp_ins_pay_element >>>'
ELSE
    PRINT N'<<< FAILED CREATING PROCEDURE dbo.usp_ins_pay_element >>>'
GO