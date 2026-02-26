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

/*************************************************************************************
    SP Name:       usp_ins_pay_element

    Description:


    Parameters:
        @p_user_id       =  User ID (i.e. 'DBS')
        @p_batchname     = Job Scheduler Batch Name (i.e. 'GHR')
        @p_qualifier     = Job Scheduler Qualifier (i.e. 'INTERFACES')
        @p_activity_date = Current System Date


    Example:
        EXEC DBShrpn.dbo.usp_ins_pay_element
              @p_user_id          = @w_userid
            , @p_batchname       = @v_PSC_BATCHNAME
            , @p_qualifier       = @w_PSC_QUALIFIER
            , @p_activity_date   = @w_activity_date


   Revision history:
   version  date        developer   SCR         description
   -------  ----------  ---------   -----       ------------------------------------
   1.0.00   08/27/2025  CJP                     - Cloned from GOG version

************************************************************************************/

CREATE PROCEDURE dbo.usp_ins_pay_element
    (
      @p_user_id            varchar(30)
    , @p_batchname          varchar(08)
    , @p_qualifier          varchar(30)
    , @p_activity_date      datetime
    )
AS

BEGIN

    SET NOCOUNT ON

    DECLARE @v_step_position                    varchar(255)            = 'Begin Procedure'

    DECLARE @v_EVENT_ID_SALARY_CHANGE           char(2)                 = '02'
    DECLARE @v_EVENT_ID_TRANSFER                char(2)                 = '03'
    DECLARE @v_EVENT_ID_STATUS_CHANGE           char(2)                 = '05'
    DECLARE @v_EVENT_ID_PAY_ELE                 char(2)                 = '06'

    DECLARE @v_ACTIVITY_STATUS_GOOD             char(2)                 = '00'
    DECLARE @v_ACTIVITY_STATUS_WARNING          char(2)                 = '01'
    DECLARE @v_ACTIVITY_STATUS_BAD              char(2)                 = '02'

    DECLARE @v_BEG_OF_TIME_DATE                 datetime                = '19000101'
    DECLARE @v_END_OF_TIME_DATE                 datetime                = '29991231'
    DECLARE @v_BAD_DATE_INDICATOR               datetime                = '99991231'    -- value used to populate datetime column with value from HCM that is not a valid date after conversion

    DECLARE @ErrorNumber                        varchar(10)
    DECLARE @ErrorMessage                       nvarchar(4000)
    DECLARE @ErrorSeverity                      int
    DECLARE @ErrorState                         int

    DECLARE @v_ret_val                          int                     = 0
    DECLARE @v_ret_val_usp_ins_hepy_insert      int                     = 0


    DECLARE @w_msg_text                         varchar(255)
    DECLARE @w_msg_text_2                       varchar(255)
    DECLARE @w_msg_text_3                       varchar(255)
    DECLARE @w_severity_cd                      tinyint
    DECLARE @w_fatal_error                      bit                     = 0         --char(01)

    DECLARE @maxx                               char(06)
    DECLARE @msg_id                             char(10)

    DECLARE @i_stop_date_1                      char(12)
    -- DECLARE @i_emp_id                           char(15)
    -- DECLARE @i_empl_id                          char(10)
    -- DECLARE @i_pay_element_id                   char(10)
    DECLARE @i_eff_date                         datetime
    DECLARE @i_stop_date                        datetime
    DECLARE @i_pay_element_exists               char(01)
    DECLARE @i_calc_meth_code                   char(02)

    -- Declare
    DECLARE @w_emp_id                           char(15)                = '000325'
    DECLARE @w_cur_empl_id                      char(10)                = '5001'
    -- DECLARE @w_pay_element_id                   char(10)                = 'ACTI'
    DECLARE @w_prior_eff_date                   datetime                = '19000101'
    DECLARE @w_next_eff_date                    datetime                = '19000101'
    DECLARE @w_inact_by_pay_element_ind         char(1)                 = 'N'
    DECLARE @w_change_reason_code               char(5)                 = ''
    DECLARE @w_pay_ele_pay_pd_sched_code        char(2)                 = '01'
    DECLARE @w_calc_meth_code                   char(2)                 = '01'
    DECLARE @w_standard_calc_factor_2           money                   = 0.00
    DECLARE @w_special_calc_factor_1            money                   = 0.00
    DECLARE @w_special_calc_factor_2            money                   = 0.00
    DECLARE @w_special_calc_factor_3            money                   = 0.00
    DECLARE @w_special_calc_factor_4            money                   = 0.00
    DECLARE @w_rate_tbl_id                      char(10)                = ''
    DECLARE @w_rate_code                        char(8)                 = ''
    DECLARE @w_payee_name                       char(35)                = ''
    DECLARE @w_payee_pmt_sched_code             char(5)                 = ''
    DECLARE @w_payee_bank_transit_nbr           char(17)                = ''
    DECLARE @w_payee_bank_acct_nbr              char(17)                = ''
    DECLARE @w_pmt_ref_nbr                      char(20)                = ''
    DECLARE @w_pmt_ref_name                     char(35)                = ''
    DECLARE @w_vendor_id                        char(10)                = ''
    DECLARE @w_limit_amt                        money                   = 0
    DECLARE @w_guaranteed_net_pay_amt           money                   = 0
    DECLARE @w_start_after_pay_element_id       char(10)                = ''
    DECLARE @w_indiv_addr_typ_to_prt_code       char(5)                 = ''
    DECLARE @w_bank_id                          char(11)                = ''
    DECLARE @w_dir_dep_bank_acct_nbr            char(17)                = ''
    DECLARE @w_bank_acct_type_code              char(1)                 = ' '
    DECLARE @w_pay_pd_arrs_rec_fixed_amt        money                   = 0
    DECLARE @w_pay_pd_arrs_rec_fixed_pct        money                   = 0
    DECLARE @w_min_pay_pd_recovery_amt          money                   = 0
    DECLARE @w_user_amt_1                       float                   = 0
    DECLARE @w_user_amt_2                       float                   = 0
    DECLARE @w_user_monetary_amt_1              money                   = 0
    DECLARE @w_user_monetary_amt_2              money                   = 0
    DECLARE @w_user_monetary_curr_code          char(3)                 = ''
    DECLARE @w_user_code_1                      char(5)                 = ''
    DECLARE @w_user_code_2                      char(5)                 = ''
    DECLARE @w_user_date_1                      datetime                = '19000101'
    DECLARE @w_user_date_2                      datetime                = '19000101'
    DECLARE @w_user_ind_1                       char(1)                 = 'N'
    DECLARE @w_user_ind_2                       char(1)                 = 'N'
    DECLARE @w_user_text_1                      char(50)                = ''
    DECLARE @w_user_text_2                      char(50)                = ''
    DECLARE @w_chgstamp                         smallint                = 0
    DECLARE @w_epend_emp_id                     char(15)                = ''
    DECLARE @w_epend_empl_id                    char(10)                = ''
    DECLARE @w_epend_pay_element_id             char(10)                = ''
    DECLARE @w_epend_arrears_bal_amt            money                   = 0
    DECLARE @w_epend_rec_ovr_nbr_pay_pds        tinyint                 = 0
    DECLARE @w_epend_wh_status_code             char(1)                 = '9'
    DECLARE @w_epend_calc_last_pay_pd_ind       char(1)                 = 'N'
    DECLARE @w_epend_prenotif_chk_date          datetime                = '19000101'
    DECLARE @w_epend_prenotification_code        char(1)                = ''
    DECLARE @w_epend_chgstamp                   smallint                = 0
    DECLARE @w_epec_emp_id                      char(15)                = ''
    DECLARE @w_epec_empl_id                     char(10)                = ''
    DECLARE @w_epec_pay_element_id              char(10)                = ''
    DECLARE @w_epec_start_date                  datetime                = '19000101'
    DECLARE @w_epec_comnt_type_code             char(1)                 = ''
    DECLARE @w_epec_seq_nbr                     smallint                = 0
    DECLARE @w_epec_comnt_text                  varchar(255)            = ''
    DECLARE @w_epec_chgstamp                    smallint                = 0
    DECLARE @w_pe_descp                         char(35)                = 'Acting Salary'
    DECLARE @w_pe_type                          char(1)                 = '1'
    DECLARE @w_pe_earning_type                  char(1)                 = '1'
    DECLARE @w_pe_deduction_type                char(1)                 = ''
    DECLARE @w_pe_pay_pd_sched                  char(2)                 = '01'
    DECLARE @w_pe_calc_meth                     char(2)                 = '01'
    DECLARE @w_pe_stndrd_calc_fac_1             money                   = 0
    DECLARE @w_pe_stndrd_calc_fac_2             money                   = 0
    DECLARE @w_pe_spec_calc_fac_1               money                   = 0
    DECLARE @w_pe_spec_calc_fac_2               money                   = 0
    DECLARE @w_pe_spec_calc_fac_3               money                   = 0
    DECLARE @w_pe_spec_calc_fac_4               money                   = 0
    DECLARE @w_pe_limit_amt                     money                   = 0
    DECLARE @w_pe_limit_cyc_type                char(1)                 = '0'
    DECLARE @w_pe_ded_rec_meth                  char(1)                 = ''
    DECLARE @w_pe_rec_fixed_amt                 money                   = 0
    DECLARE @w_pe_rec_fixed_pct                 float                   = 0
    DECLARE @w_pe_min_pay_pd_rec_amt            money                   = 0
    DECLARE @w_pe_rate_tbl_id                   char(10)                = ''
    DECLARE @w_pe_ben_plan_id                   char(15)                = ''
    DECLARE @w_rt_descp                         char(35)                = ''
    DECLARE @w_rte_descp                        char(35)                = ''
    DECLARE @w_epel_towards_lmt_amt             money                   = 0
    DECLARE @w_tpp_descp                        char(15)                = ''
    DECLARE @w_comments_flag                    char(1)                 = ''
    DECLARE @w_current_ver_eff_date             datetime                = '19000101'
    DECLARE @w_pe_curr_code                     char(3)                 = 'XCD'
    DECLARE @w_scrty_cat_code                   char(3)                 = 'NA'
    DECLARE @w_original_stop_date               datetime                = '19000101'
    DECLARE @w_pension_tot_distn_ind            char(1)                 = 'N'
    DECLARE @w_pension_distn_code_1             char(1)                 = '0'
    DECLARE @w_pension_distn_code_2             char(1)                 = '0'
    DECLARE @w_pre_1990_rpp_ctrb_type           char(1)                 = '0'
    DECLARE @w_first_roth_ctrb                  datetime                = '29991231'
    DECLARE @w_ira_sep_simple_ind               char(1)                 = 'N'
    DECLARE @w_txbl_amt_not_det_ind             char(1)                 = 'N'
    DECLARE @w_result_set_ind                   char(1)                 = 'N'



    -- This section declares the interface values from Global HR
    DECLARE @aud_id                                 int             = 0
    DECLARE @emp_id                                 char(15)        = ''
    DECLARE @eff_date                               datetime
    DECLARE @empl_id                                char(10)
    DECLARE @begin_date                             datetime
    DECLARE @end_date                               datetime
    DECLARE @pay_element_id                         char(10)
    DECLARE @emp_calculation                        money
    DECLARE @file_source                            char(50)        -- 'SS VENUS' or 'SS GANYMEDE'

    DECLARE @cur_eempl_pay_through_date             datetime


    CREATE TABLE #tbl_ghr_msg
        (
          msg_id                                    char(15)            NOT NULL
        , msg_desc                                  varchar(255)        NOT NULL
        )


    BEGIN TRY


        SET @v_step_position = 'Declaring cursor crsrHR'

        -- Loop through ghr_employee_events_temp to populate error message log entry
        DECLARE crsrHR CURSOR FAST_FORWARD FOR
        SELECT t.aud_id
             , t.emp_id
             , t.eff_date
             , t.empl_id
             , t.begin_date
             , t.end_date
             , t.pay_element_id
             , t.emp_calculation
             , t.file_source
        FROM #ghr_employee_events_temp t
        WHERE (event_id = @v_EVENT_ID_PAY_ELE)

        SET @v_step_position = 'Opening cursor crsrHR'
        OPEN crsrHR

        SET @v_step_position = 'Fetching cursor crsrHR'
        FETCH crsrHR
        INTO  @aud_id
            , @emp_id
            , @eff_date
            , @empl_id
            , @begin_date
            , @end_date
            , @pay_element_id
            , @emp_calculation
            , @file_source


        WHILE (@@FETCH_STATUS = 0)
        BEGIN

            BEGIN TRY

                SET @v_step_position = 'Begin crsrHR While Loop'

                SET @w_fatal_error = 0


                ---------------------------------------------------------------------------
                -- Validate Amount
                ---------------------------------------------------------------------------
                SET @v_step_position = 'Validate Pay Element Amount'

                IF (@emp_calculation = 0.00)
                    BEGIN

                        SET @msg_id = 'U00101'  -- New code
                        SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id      AS msg_id
                            , REPLACE(REPLACE(REPLACE(t.msg_text, '@1', RTRIM(@emp_calculation)), '@2', @emp_id   ), '@3', @pay_element_id   ) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master t
                        WHERE (msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_PAY_ELE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @pay_element_id
                            , @p_msg_p1             = @emp_calculation
                            , @p_msg_p2             = ''
                            , @p_msg_desc           = 'Invalid pay element amount.'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id

                        SET @w_fatal_error = 1

                    END



                ---------------------------------------------------------------------------
                -- Validate Dates
                ---------------------------------------------------------------------------
                -- Invalid date value from HCM, ''@1'', for employee, @2, and event id, @3.

                -- Effective Date
                IF (@eff_date = @v_BAD_DATE_INDICATOR)
                    BEGIN

                        SET @msg_id = 'U00102'  -- New code
                        SET @v_step_position = 'Validation Effective Date - ' + RTRIM(@msg_id)

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id      AS msg_id
                            , REPLACE(REPLACE(REPLACE(t.msg_text, '@1', @eff_date), '@2', @emp_id), '@3', @v_EVENT_ID_PAY_ELE) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master t
                        WHERE (msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_PAY_ELE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @pay_element_id
                            , @p_msg_p1             = @emp_calculation
                            , @p_msg_p2             = ''
                            , @p_msg_desc           = 'Invalid Effective Date'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id

                        SET @w_fatal_error = 1

                    END


                -- Begin Date
                IF (@begin_date = @v_BAD_DATE_INDICATOR)
                    BEGIN

                        SET @msg_id = 'U00102'  -- New code
                        SET @v_step_position = 'Validation Begin Date - ' + RTRIM(@msg_id)

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id      AS msg_id
                            , REPLACE(REPLACE(REPLACE(t.msg_text, '@1', @begin_date   ), '@2', @emp_id   ), '@3', @v_EVENT_ID_PAY_ELE) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master t
                        WHERE (msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_PAY_ELE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @pay_element_id
                            , @p_msg_p1             = @begin_date
                            , @p_msg_p2             = ''
                            , @p_msg_desc           = 'Invalid Begin Date'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id

                        SET @w_fatal_error = 1

                    END


                -- End Date
                IF (@end_date = @v_BAD_DATE_INDICATOR)
                    BEGIN

                        SET @msg_id = 'U00102'  -- New code
                        SET @v_step_position = 'Validation End Date - ' + RTRIM(@msg_id)

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id AS msg_id
                            , REPLACE(REPLACE(REPLACE(t.msg_text, '@1', @end_date ), '@2', @emp_id ), '@3', @v_EVENT_ID_PAY_ELE) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master t
                        WHERE (msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_PAY_ELE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @pay_element_id
                            , @p_msg_p1             = @end_date
                            , @p_msg_p2             = ''
                            , @p_msg_desc           = 'Invalid End Date'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id

                        SET @w_fatal_error = 1

                    END


                ---------------------------------------------------------------------------
                -- Check to see if the employee exists
                ---------------------------------------------------------------------------
                -- Lookup current employer id to compare to extract

                SELECT @w_cur_empl_id = eempl.empl_id
                FROM DBShrpn.dbo.uvu_emp_employment_most_rec eempl
                WHERE (eempl.emp_id = @emp_id)

                IF (@@ROWCOUNT = 0)
                    BEGIN

                        SET @msg_id = 'U00012'
                        SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id AS msg_id
                            , REPLACE(t.msg_text, '@1', RTRIM(@emp_id   )) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master t
                        WHERE (msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_PAY_ELE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @pay_element_id
                            , @p_msg_p1             = @emp_calculation
                            , @p_msg_p2             = ''
                            , @p_msg_desc           = 'Invalid Employee ID'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id

                        SET @w_fatal_error = 1

                    END


                ---------------------------------------------------------------------------
                -- Check to see if the employer exists
                ---------------------------------------------------------------------------
                IF NOT EXISTS (
                            SELECT 1
                            FROM DBShrpn.dbo.employer
                            WHERE (empl_id = @empl_id)
                            )
                BEGIN

                    SET @msg_id = 'U00039'
                    SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id AS msg_id
                        , REPLACE(t.msg_text, '@1', RTRIM(@empl_id   )) AS msg_desc
                    FROM DBSCOMMON.dbo.message_master t
                    WHERE (msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_PAY_ELE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @pay_element_id
                            , @p_msg_p1             = @empl_id
                            , @p_msg_p2             = ''
                            , @p_msg_desc           = 'Invalid Employer ID'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id

                    SET @w_fatal_error = 1

                END


                ---------------------------------------------------------------------------
                -- Does extract employer id match SS employer id?
                ---------------------------------------------------------------------------
                IF (@w_cur_empl_id <> @empl_id)
                BEGIN

                    SET @msg_id = 'U00039'
                    SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id AS msg_id
                        , REPLACE(t.msg_text, '@1', RTRIM(@empl_id   )) AS msg_desc
                    FROM DBSCOMMON.dbo.message_master t
                    WHERE (msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_PAY_ELE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @pay_element_id
                            , @p_msg_p1             = @empl_id
                            , @p_msg_p2             = @w_cur_empl_id
                            , @p_msg_desc           = 'Employer id from HCM does not match associate''s current employer id in SmartStream.'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id

                    SET @w_fatal_error = 1

                END


                ---------------------------------------------------------------------------
                -- Validate Pay Element ID
                ---------------------------------------------------------------------------
                -- Lookup base pay element setting
                -- if not present log error and skip record
                -- if pay element exists key variables will be passed to DBShrpn.dbo.usp_ins_hepy_insert
                SELECT @w_pe_pay_pd_sched               = pe.pay_pd_sched_code
                    , @w_pe_calc_meth                  = pe.calc_meth_code
                    , @w_pe_stndrd_calc_fac_1          = pe.standard_calc_factor_1
                    , @w_pe_stndrd_calc_fac_2          = pe.standard_calc_factor_2
                    , @w_pe_spec_calc_fac_1            = pe.special_calc_factor_1
                    , @w_pe_spec_calc_fac_2            = pe.special_calc_factor_2
                    , @w_pe_spec_calc_fac_3            = pe.special_calc_factor_3
                    , @w_pe_spec_calc_fac_4            = pe.special_calc_factor_4
                    , @w_pe_limit_amt                  = pe.limit_amt
                    , @w_pe_rec_fixed_amt              = pe.pay_pd_arrears_rec_fixed_amt
                    , @w_pe_rec_fixed_pct              = pe.pay_pd_arrears_rec_fixed_pct
                    , @w_pe_min_pay_pd_rec_amt         = pe.min_pay_pd_recovery_amt
                FROM DBShrpn.dbo.pay_element pe
                WHERE (pe.pay_element_id = @pay_element_id)
                AND (pe.next_eff_date  = @v_END_OF_TIME_DATE)
                AND (pe.stop_date      > @eff_date)

                IF (@@ROWCOUNT = 0) -- record not found
                BEGIN

                    SET @msg_id = 'U00103'
                    SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id      AS msg_id
                        , REPLACE(REPLACE(t.msg_text, '@1', RTRIM(@pay_element_id   )), '@2', RTRIM(@emp_id   )) AS msg_desc
                    FROM DBSCOMMON.dbo.message_master t
                    WHERE (msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_PAY_ELE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @pay_element_id
                            , @p_msg_p1             = @emp_calculation
                            , @p_msg_p2             = ''
                            , @p_msg_desc           = 'Invalid pay element id.'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id

                    SET @w_fatal_error = 1

                END



                ---------------------------------------------------------------------------
                --   Obtain the current pay element record for this employee pay element
                ---------------------------------------------------------------------------
                SELECT   @i_pay_element_exists   =   'N'

                SELECT @i_eff_date           = epe.eff_date
                    , @i_stop_date          = epe.stop_date
                    , @i_pay_element_exists = 'Y'
                    , @i_calc_meth_code     = epe.calc_meth_code   -- employee's calc method
                FROM DBShrpn.dbo.emp_pay_element epe
                WHERE epe.emp_id         = @emp_id
                AND epe.empl_id        = @empl_id
                AND epe.pay_element_id = @pay_element_id
                AND epe.next_eff_date  = @v_END_OF_TIME_DATE

                --   AND epe.eff_date       =   (
                --                              SELECT MAX(t.eff_date)
                --                              FROM DBShrpn.dbo.emp_pay_element t
                --                              WHERE t.emp_id         = epe.emp_id
                --                                AND t.empl_id        = epe.empl_id
                --                                AND t.pay_element_id = epe.pay_element_id
                --                             )


                ---------------------------------------------------------------------------
                --   Check to see that the new effective date is greater than the current effective date
                ---------------------------------------------------------------------------
                IF (@i_pay_element_exists = 'Y') AND
                (@i_eff_date           > @eff_date)
                    BEGIN

                        SET @msg_id = 'U00027'
                        SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

                        -- Convert date to string for log table
                        SET @w_msg_text_2 = CONVERT(char(8), @i_eff_date, 112)

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id AS msg_id
                            , REPLACE(REPLACE(t.msg_text, '@1', @eff_date), '@2', @emp_id) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master t
                        WHERE (msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_PAY_ELE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @pay_element_id
                            , @p_msg_p1             = @emp_calculation
                            , @p_msg_p2             = @w_msg_text_2
                            , @p_msg_desc           = 'The new effective date must be greater than the current effective date.'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id

                        SET   @w_fatal_error = 1

                    END



                ---------------------------------------------------------------------------
                --   Validate that the start date is the same or earlier than the pay through date of the employee
                ---------------------------------------------------------------------------
                -- The Begin Date, @1, cannot be greater than the pay through date for employee, @2.

                SELECT @cur_eempl_pay_through_date = eempl.pay_through_date
                FROM DBShrpn.dbo.uvu_emp_employment_most_rec eempl
                WHERE (eempl.emp_id = @emp_id)



                IF (@begin_date > @cur_eempl_pay_through_date)
                    BEGIN

                        SET @msg_id = 'U00030'
                        SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

                        -- Convert date to string for log table
                        SET @w_msg_text_2 = CONVERT(char(8), @cur_eempl_pay_through_date, 112)

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id                   AS msg_id
                            , REPLACE(REPLACE(t.msg_text, '@1', @begin_date), '@2', @emp_id) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master t
                        WHERE (msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_PAY_ELE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @pay_element_id
                            , @p_msg_p1             = @begin_date
                            , @p_msg_p2             = @w_msg_text_2
                            , @p_msg_desc           = 'The Begin Date cannot be greater than the pay through date for employee.'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id

                        SET @w_fatal_error = 1

                    END


                ---------------------------------------------------------------------------
                --- Validate the stop date against the effective date
                ---------------------------------------------------------------------------
                -- If stop date less than eff date then set eff date = stop date
                IF (@end_date < @eff_date)
                --IF CONVERT(date, @end_date   ) < CONVERT(date, @eff_date   )
                    BEGIN

                        SET @msg_id = 'U00047'
                        SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id AS msg_id
                            , REPLACE(REPLACE(t.msg_text, '@1', @end_date), '@2', @emp_id) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master t
                        WHERE (msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_PAY_ELE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @pay_element_id
                            , @p_msg_p1             = @end_date
                            , @p_msg_p2             = ''
                            , @p_msg_desc           = 'The stop date must be greater or equal to the employee pay element effective date - Defaulting effective date to stop date.'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id

                        SET @eff_date = @end_date
                        --SELECT @eff_date    = @end_date

                    END


                IF (@w_fatal_error = 1)
                    GOTO BYPASS_EMPLOYEE


                ---------------------------------------------------------------------------
                -- start pay element logic
                ---------------------------------------------------------------------------
                SET @v_step_position = 'Pay Element Setup'
                -- Does employee record exist with same effective date?
                IF NOT EXISTS (
                                SELECT 1
                                FROM DBShrpn.dbo.emp_pay_element
                                WHERE emp_id = @emp_id
                                AND empl_id = @empl_id
                                AND pay_element_id = @pay_element_id
                                AND eff_date = @eff_date
                            )
                    BEGIN

                        -- IF (@i_pay_element_exists = 'Y') AND  -- record exists but <> eff date
                        --    --(CONVERT(date, @i_stop_date) < CONVERT(date, @end_date))    -- compare old stop date with eot date. @end_date hardcoded to 12/31/2999
                        --    (@i_stop_date < @v_END_OF_TIME_DATE)
                        --     BEGIN
                        --         SET @v_step_position = 'Pay Element Setup - Pay Element Exists'

                        --         -- Update existing record with new stop date
                        --         UPDATE DBShrpn.dbo.emp_pay_element
                        --         SET  stop_date     = @v_END_OF_TIME_DATE
                        --         WHERE emp_id       = @i_emp_id
                        --         AND empl_id        = @i_empl_id
                        --         AND pay_element_id = @i_pay_element_id
                        --         AND eff_date       = @i_eff_date
                        --     END

                        SET @v_step_position = 'Pay Element Setup - Exec DBShrpn.dbo.usp_ins_hepy_insert'

                        -- Create new pay element record
                        EXEC DBShrpn.dbo.usp_ins_hepy_insert
                            @w_stop_date                   = @end_date                  -- used in insert statement
                            , @p_emp_id                      = @emp_id
                            , @p_empl_id                     = @empl_id
                            , @p_pay_element_id              = @pay_element_id
                            , @p_eff_date                    = @eff_date
                            , @p_prior_eff_date              = @w_prior_eff_date
                            , @p_next_eff_date               = @w_next_eff_date
                            , @p_inact_by_pay_element_ind    = @w_inact_by_pay_element_ind
                            , @p_start_date                  = @begin_date                   -- not used in insert statement
                            , @p_stop_date                   = @end_date
                            , @p_change_reason_code          = @w_change_reason_code
                            , @p_pay_ele_pay_pd_sched_code   = @w_pay_ele_pay_pd_sched_code
                            , @p_calc_meth_code              = @w_calc_meth_code
                            , @p_standard_calc_factor_1      = @emp_calculation
                            , @p_standard_calc_factor_2      = @w_standard_calc_factor_2
                            , @p_special_calc_factor_1       = @w_special_calc_factor_1
                            , @p_special_calc_factor_2       = @w_special_calc_factor_2
                            , @p_special_calc_factor_3       = @w_special_calc_factor_3
                            , @p_special_calc_factor_4       = @w_special_calc_factor_4
                            , @p_rate_tbl_id                 = @w_rate_tbl_id
                            , @p_rate_code                   = @w_rate_code
                            , @p_payee_name                  = @w_payee_name
                            , @p_payee_pmt_sched_code        = @w_payee_pmt_sched_code
                            , @p_payee_bank_transit_nbr      = @w_payee_bank_transit_nbr
                            , @p_payee_bank_acct_nbr         = @w_payee_bank_acct_nbr
                            , @p_pmt_ref_nbr                 = @w_pmt_ref_nbr
                            , @p_pmt_ref_name                = @w_pmt_ref_name
                            , @p_vendor_id                   = @w_vendor_id
                            , @p_limit_amt                   = @w_limit_amt
                            , @p_guaranteed_net_pay_amt      = @w_guaranteed_net_pay_amt
                            , @p_start_after_pay_element_id  = @w_start_after_pay_element_id
                            , @p_indiv_addr_typ_to_prt_code  = @w_indiv_addr_typ_to_prt_code
                            , @p_bank_id                     = @w_bank_id
                            , @p_dir_dep_bank_acct_nbr       = @w_dir_dep_bank_acct_nbr
                            , @p_bank_acct_type_code         = @w_bank_acct_type_code
                            , @p_pay_pd_arrs_rec_fixed_amt   = @w_pay_pd_arrs_rec_fixed_amt
                            , @p_pay_pd_arrs_rec_fixed_pct   = @w_pay_pd_arrs_rec_fixed_pct
                            , @p_min_pay_pd_recovery_amt     = @w_min_pay_pd_recovery_amt
                            , @p_user_amt_1                  = @w_user_amt_1
                            , @p_user_amt_2                  = @w_user_amt_2
                            , @p_user_monetary_amt_1         = @w_user_monetary_amt_1
                            , @p_user_monetary_amt_2         = @w_user_monetary_amt_2
                            , @p_user_monetary_curr_code     = @w_user_monetary_curr_code
                            , @p_user_code_1                 = @w_user_code_1
                            , @p_user_code_2                 = @w_user_code_2
                            , @p_user_date_1                 = @w_user_date_1
                            , @p_user_date_2                 = @w_user_date_2
                            , @p_user_ind_1                  = @w_user_ind_1
                            , @p_user_ind_2                  = @w_user_ind_2
                            , @p_user_text_1                 = @w_user_text_1
                            , @p_user_text_2                 = @w_user_text_2
                            , @p_chgstamp                    = @w_chgstamp
                            , @p_epend_emp_id                = @w_epend_emp_id
                            , @p_epend_empl_id               = @w_epend_empl_id
                            , @p_epend_pay_element_id        = @w_epend_pay_element_id
                            , @p_epend_arrears_bal_amt       = @w_epend_arrears_bal_amt
                            , @p_epend_rec_ovr_nbr_pay_pds   = @w_epend_rec_ovr_nbr_pay_pds
                            , @p_epend_wh_status_code        = @w_epend_wh_status_code
                            , @p_epend_calc_last_pay_pd_ind  = @w_epend_calc_last_pay_pd_ind
                            , @p_epend_prenotif_chk_date     = @w_epend_prenotif_chk_date
                            , @p_epend_prenotification_code  = @w_epend_prenotification_code
                            , @p_epend_chgstamp              = @w_epend_chgstamp
                            , @p_epec_emp_id                 = @w_epec_emp_id
                            , @p_epec_empl_id                = @w_epec_empl_id
                            , @p_epec_pay_element_id         = @w_epec_pay_element_id
                            , @p_epec_start_date             = @w_epec_start_date
                            , @p_epec_comnt_type_code        = @w_epec_comnt_type_code
                            , @p_epec_seq_nbr                = @w_epec_seq_nbr
                            , @p_epec_comnt_text             = @w_epec_comnt_text
                            , @p_epec_chgstamp               = @w_epec_chgstamp
                            , @p_pe_descp                    = @w_pe_descp
                            , @p_pe_type                     = @w_pe_type
                            , @p_pe_earning_type             = @w_pe_earning_type
                            , @p_pe_deduction_type           = @w_pe_deduction_type
                            , @p_pe_pay_pd_sched             = @w_pe_pay_pd_sched
                            , @p_pe_calc_meth                = @w_pe_calc_meth
                            , @p_pe_stndrd_calc_fac_1        = @w_pe_stndrd_calc_fac_1
                            , @p_pe_stndrd_calc_fac_2        = @w_pe_stndrd_calc_fac_2
                            , @p_pe_spec_calc_fac_1          = @w_pe_spec_calc_fac_1
                            , @p_pe_spec_calc_fac_2          = @w_pe_spec_calc_fac_2
                            , @p_pe_spec_calc_fac_3          = @w_pe_spec_calc_fac_3
                            , @p_pe_spec_calc_fac_4          = @w_pe_spec_calc_fac_4
                            , @p_pe_limit_amt                = @w_pe_limit_amt
                            , @p_pe_limit_cyc_type           = @w_pe_limit_cyc_type
                            , @p_pe_ded_rec_meth             = @w_pe_ded_rec_meth
                            , @p_pe_rec_fixed_amt            = @w_pe_rec_fixed_amt
                            , @p_pe_rec_fixed_pct            = @w_pe_rec_fixed_pct
                            , @p_pe_min_pay_pd_rec_amt       = @w_pe_min_pay_pd_rec_amt
                            , @p_pe_rate_tbl_id              = @w_pe_rate_tbl_id
                            , @p_pe_ben_plan_id              = @w_pe_ben_plan_id
                            , @p_rt_descp                    = @w_rt_descp
                            , @p_rte_descp                   = @w_rte_descp
                            , @p_epel_towards_lmt_amt        = @w_epel_towards_lmt_amt
                            , @p_tpp_descp                   = @w_tpp_descp
                            , @p_comments_flag               = @w_comments_flag
                            , @p_current_ver_eff_date        = @w_current_ver_eff_date
                            , @p_pe_curr_code                = @w_pe_curr_code
                            , @p_scrty_cat_code              = @w_scrty_cat_code
                            , @p_original_stop_date          = @w_original_stop_date
                            , @p_pension_tot_distn_ind       = @w_pension_tot_distn_ind
                            , @p_pension_distn_code_1        = @w_pension_distn_code_1
                            , @p_pension_distn_code_2        = @w_pension_distn_code_2
                            , @p_pre_1990_rpp_ctrb_type      = @w_pre_1990_rpp_ctrb_type
                            , @p_first_roth_ctrb             = @w_first_roth_ctrb
                            , @p_ira_sep_simple_ind          = @w_ira_sep_simple_ind
                            , @p_txbl_amt_not_det_ind        = @w_txbl_amt_not_det_ind
                            , @p_result_set_ind              = @w_result_set_ind
                            , @ret                           = @v_ret_val_usp_ins_hepy_insert


                        IF (@v_ret_val_usp_ins_hepy_insert <> 0)
                        BEGIN
                            -- Log proc usp_ins_hepy_insert returned an error code
                            -- that did not raise a system error
                            EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                                @p_msg_id             = @msg_id
                                , @p_event_id           = @v_EVENT_ID_PAY_ELE
                                , @p_emp_id             = @emp_id
                                , @p_eff_date           = @eff_date
                                , @p_pay_element_id     = @pay_element_id
                                , @p_msg_p1             = @begin_date
                                , @p_msg_p2             = @w_msg_text_2
                                , @p_msg_desc           = 'Stored Procedure DBShrpn.dbo.usp_ins_hepy_insert Returned an error.'
                                , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                                , @p_activity_date      = @p_activity_date
                                , @p_audit_id           = @aud_id

                        END



                        -- IF (@end_date < @v_END_OF_TIME_DATE) -- not sure why not comparing to previous record's stop date -- Are all new records stop date = 12/31/2999?
                        -- --IF (CONVERT(date, @end_date   ) < CONVERT(date, @end_date))
                        --     BEGIN

                        --         SET @v_step_position = 'Pay Element Setup - Stop Date < 12/31/2999'

                        --         UPDATE DBShrpn.dbo.emp_pay_element
                        --         SET  stop_date = CASE
                        --                            --WHEN CONVERT(date, @end_date   ) < CONVERT(date, @i_eff_date) THEN @i_eff_date
                        --                            WHEN @end_date < @i_eff_date THEN @i_eff_date
                        --                            ELSE CONVERT(date, @end_date   )
                        --                          END
                        --         WHERE emp_id         = @emp_id
                        --           AND empl_id        = @empl_id
                        --           AND pay_element_id = @pay_element_id
                        --           AND eff_date       = @eff_date  --@eff_date
                        --     END


                        IF (@i_pay_element_exists = 'Y')
                            BEGIN

                                SET @v_step_position = 'Pay Element Setup - Pay Element Exists Update current/prior recs'

                                --  Current Record
                                UPDATE DBShrpn.dbo.emp_pay_element
                                SET prior_eff_date = @i_eff_date
                                WHERE emp_id         = @emp_id
                                AND empl_id        = @empl_id
                                AND pay_element_id = @pay_element_id
                                AND eff_date       = @eff_date     --@eff_date

                                -- Prior Record
                                UPDATE DBShrpn.dbo.emp_pay_element
                                SET next_eff_date =   @eff_date     --@eff_date
                                WHERE emp_id         = @emp_id
                                AND empl_id        = @empl_id
                                AND pay_element_id = @pay_element_id
                                AND eff_date       = @i_eff_date
                            END

                    END
                ELSE    -- Pay Element Exists with Same Effective Date - Just update existing record
                    BEGIN
                        SET @v_step_position = 'Pay Element Setup - Pay Element Exists with same effective date'

                        UPDATE   DBShrpn.dbo.emp_pay_element
                        SET start_date             = @begin_date
                        , stop_date              = @end_date                  -- @end_date   ,
                        , standard_calc_factor_1 = @emp_calculation      -- @emp_calculation   ,
                        , calc_meth_code         = @w_calc_meth_code
                        , rate_tbl_id            = @w_rate_tbl_id
                        , rate_code              = @w_rate_code
                        WHERE emp_id         = @emp_id
                        AND empl_id        = @empl_id
                        AND pay_element_id = @pay_element_id
                        AND eff_date       = @eff_date      --@eff_date

                    END


                ---------------------------------------------------------------------------
                -- Update Processed Flag after successful update
                ---------------------------------------------------------------------------
                UPDATE DBShrpn.dbo.ghr_employee_events_aud
                SET proc_flag = 'Y'
                WHERE (activity_date = @p_activity_date)
                  AND (aud_id        = @aud_id)


            END TRY
            BEGIN CATCH

                SELECT @ErrorNumber   = CAST(ERROR_NUMBER() AS varchar(10))
                    , @ErrorMessage  = @v_step_position + ' - ' + ERROR_MESSAGE()
                    , @ErrorSeverity = ERROR_SEVERITY()
                    , @ErrorState    = ERROR_STATE()

                IF (@@TRANCOUNT > 0)
                    ROLLBACK TRAN

                BEGIN TRAN

                -- Log error
                EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                      @p_msg_id             = @ErrorNumber
                    , @p_event_id           = @v_EVENT_ID_PAY_ELE
                    , @p_emp_id             = @emp_id
                    , @p_eff_date           = @eff_date
                    , @p_pay_element_id     = ''
                    , @p_msg_p1             = ''
                    , @p_msg_p2             = ''
                    , @p_msg_desc           = @ErrorMessage
                    , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                    , @p_activity_date      = @p_activity_date
                    , @p_audit_id           = @aud_id


            END CATCH

BYPASS_EMPLOYEE:

            FETCH crsrHR
            INTO  @aud_id
                , @emp_id
                , @eff_date
                , @empl_id
                , @begin_date
                , @end_date
                , @pay_element_id
                , @emp_calculation
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
        FROM DBSCOMMON.dbo.message_master
        WHERE (msg_id = @msg_id)

        EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2
            @userid   = @p_user_id
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
        FROM DBSCOMMON.dbo.message_master
        WHERE (msg_id = @msg_id)

        EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2
            @userid   = @p_user_id
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
        FROM DBSCOMMON.dbo.message_master
        WHERE (msg_id = @msg_id)

        EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2
            @userid   = @p_user_id
            , @batch    = @p_batchname
            , @qual     = @p_qualifier
            , @msgno    = @msg_id
            , @severity = @w_severity_cd
            , @text     = @w_msg_text
            , @text_2   = @w_msg_text_2
            , @text_3   = @w_msg_text_3


        ---------------------------------------------------------------------------
        -- Send notification of warning message U00029 - Total nbr of employees that already exist: @1
        ---------------------------------------------------------------------------
        SET @msg_id = 'U00029'
        SET @v_step_position = 'Log ' + @msg_id

        SELECT @msg_id        = msg_id
            , @w_msg_text    = msg_text
            , @w_msg_text_2  = msg_text_2
            , @w_msg_text_3  = msg_text_3
            , @w_severity_cd = severity_cd
        FROM DBSCOMMON.dbo.message_master
        WHERE (msg_id = @msg_id)

        -- Get total new hire records from HCM
        SELECT @maxx = CAST(COUNT(*) AS varchar(6))
        FROM #ghr_employee_events_temp
        WHERE (event_id = @v_EVENT_ID_PAY_ELE)


        SET @w_msg_text = REPLACE(@w_msg_text, '@1', @maxx)

        EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2
            @userid   = @p_user_id
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
        JOIN DBSCOMMON.dbo.message_master msg ON
            (ghr.msg_id = msg.msg_id)
        WHERE (msg.msg_text_2 = 'Y')

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
                @userid   = @p_user_id
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
        FROM DBSCOMMON.dbo.message_master
        WHERE (msg_id = @msg_id)

        EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2
            @userid   = @p_user_id
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
        FROM DBSCOMMON.dbo.message_master
        WHERE (msg_id = @msg_id)

        EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2
            @userid   = @p_user_id
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
        FROM DBSCOMMON.dbo.message_master
        WHERE (msg_id = @msg_id)

        EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2
            @userid   = @p_user_id
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

        SELECT @ErrorNumber   = CAST(ERROR_NUMBER() AS varchar(10))
            , @ErrorMessage  = @v_step_position + ' - ' + ERROR_MESSAGE()
            , @ErrorSeverity = ERROR_SEVERITY()
            , @ErrorState    = ERROR_STATE()
            , @v_ret_val     = -1

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

        -- Historical Message for reporting purpose
        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
              @p_msg_id             = @ErrorNumber
            , @p_event_id           = @v_EVENT_ID_PAY_ELE
            , @p_emp_id             = @emp_id
            , @p_eff_date           = @eff_date
            , @p_pay_element_id     = ''
            , @p_msg_p1             = ''
            , @p_msg_p2             = ''
            , @p_msg_desc           = @ErrorMessage
            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
            , @p_activity_date      = @p_activity_date
            , @p_audit_id           = @aud_id


        -- send error back to calling procedure
        RAISERROR(
                   @ErrorMessage
                 , @ErrorSeverity
                 , @ErrorState
                 );

    END CATCH


    -- Cleanup temp tables
    DROP TABLE #tbl_ghr_msg


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