USE DBShrpn
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'dbo.usp_ins_labor_group', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_ins_labor_group
    IF OBJECT_ID(N'dbo.usp_ins_labor_group') IS NOT NULL
        PRINT N'<<< FAILED DROPPING PROCEDURE dbo.usp_ins_labor_group >>>'
    ELSE
        PRINT N'<<< DROPPED PROCEDURE dbo.usp_ins_labor_group >>>'
END
GO

/*************************************************************************************
    SP Name:       usp_ins_labor_group

    Description:    Populates labor group on Employee Employment record by creating
                    a new effective dated record.

                    Table: DBShrpn.dbo.emp_employment

                    Field: labor_grp_code


    Parameters:
        @p_user_id       =  User ID (i.e. 'DBS')
        @p_batchname     = Job Scheduler Batch Name (i.e. 'GHR')
        @p_qualifier     = Job Scheduler Qualifier (i.e. 'INTERFACES')
        @p_activity_date = Current System Date


    Example:
        EXEC DBShrpn.dbo.usp_ins_labor_group
              @p_user_id         = @w_userid
            , @p_batchname       = @v_PSC_BATCHNAME
            , @p_qualifier       = @w_PSC_QUALIFIER
            , @p_activity_date   = @w_activity_date


   Revision history:
   version  date        developer   SCR         description
   -------  ----------  ---------   -----       ------------------------------------
   1.0.00   08/27/2025  CJP                     - Cloned from GOG version

************************************************************************************/

CREATE PROCEDURE dbo.usp_ins_labor_group
    (
      @p_user_id            varchar(30)
    , @p_batchname          varchar(08)
    , @p_qualifier          varchar(30)
    , @p_activity_date      datetime
    )
AS

BEGIN

    SET NOCOUNT ON

    DECLARE @v_step_position                varchar(255)        = 'Begin Procedure'

    DECLARE @v_END_OF_TIME_DATE             datetime            = '29991231'
    DECLARE @v_BAD_DATE_INDICATOR           datetime            = '99991231'    -- value used to populate datetime column with value from HCM that is not a valid date after conversion

    DECLARE @v_EMPTY_SPACE                  char(01)            = ''

    DECLARE @v_EVENT_ID_NEW_HIRE            char(2)             = '01'
    DECLARE @v_EVENT_ID_SALARY_CHANGE       char(2)             = '02'
    DECLARE @v_EVENT_ID_TRANSFER            char(2)             = '03'
    DECLARE @v_EVENT_ID_NAME_CHANGE         char(2)             = '04'
    DECLARE @v_EVENT_ID_STATUS_CHANGE       char(2)             = '05'
    DECLARE @v_EVENT_ID_PAY_ELE             char(2)             = '06'
    DECLARE @v_EVENT_ID_PAY_GROUP           char(2)             = '08'
    DECLARE @v_EVENT_ID_LABOR_GROUP         char(2)             = '09'
    DECLARE @v_EVENT_ID_POSITION_TITLE      char(2)             = '10'

    DECLARE @v_ACTIVITY_STATUS_GOOD         char(2)             = '00'
    DECLARE @v_ACTIVITY_STATUS_WARNING      char(2)             = '01'
    DECLARE @v_ACTIVITY_STATUS_BAD          char(2)             = '02'

    DECLARE @ErrorNumber                    varchar(10)
    DECLARE @ErrorMessage                   nvarchar(4000)
    DECLARE @ErrorSeverity                  int
    DECLARE @ErrorState                     int

    DECLARE @v_ret_val                      int = 0

    DECLARE @w_msg_text                     varchar(255)
    DECLARE @w_msg_text_2                   varchar(255)
    DECLARE @w_msg_text_3                   varchar(255)
    DECLARE @w_severity_cd                  tinyint
    DECLARE @w_fatal_error                  bit     = 0         --char(01)

    DECLARE @individual_id                  char(10)
    DECLARE @prior_last_name                char(30)

    DECLARE @maxx                           char(06)
    DECLARE @msg_id                         char(10)

    DECLARE @cur_empl_id                    char(10)
    DECLARE @cur_eempl_eff_date             datetime
    --DECLARE @cur_tax_entity_id              char(10)
    DECLARE @cur_labor_grp_code             char(05)
    DECLARE @cur_stat_emp_status_code       char(01)
    --DECLARE @w_eff_date                     datetime

    -- This section declares the interface values from Global HR
    DECLARE @aud_id                         int             = 0
    DECLARE @emp_id                         char(15)        = @v_EMPTY_SPACE
    DECLARE @eff_date                       datetime
    DECLARE @empl_id                        char(10)
    DECLARE @labor_grp_code                 char(05)
    DECLARE @file_source                    char(50)        -- 'SS VENUS' or 'SS GANYMEDE'


    CREATE TABLE #tbl_ghr_msg
        (
          msg_id                            char(15)            NOT NULL
        , msg_desc                          varchar(255)        NOT NULL
        )


    -- work table for emp employment insert
    CREATE TABLE #temp14
        (
          emp_id                            char(15)            NOT NULL
        , eff_date                          datetime            NOT NULL
        , next_eff_date                     datetime            NOT NULL
        , prior_eff_date                    datetime            NOT NULL
        , employment_type_code              char(5)             NOT NULL
        , work_tm_code                      char(1)             NOT NULL
        , official_title_code               char(5)             NOT NULL
        , official_title_date               datetime            NOT NULL
        , mgr_ind                           char(1)             NOT NULL
        , recruiter_ind                     char(1)             NOT NULL
        , pensioner_indicator               char(1)             NOT NULL
        , payroll_company_code              char(5)             NOT NULL
        , pmt_ctrl_code                     char(5)             NOT NULL
        , us_federal_tax_meth_code          char(1)             NOT NULL
        , us_federal_tax_amt                money               NOT NULL
        , us_federal_tax_pct                money               NOT NULL
        , us_federal_marital_status_code    char(1)             NOT NULL
        , us_federal_exemp_nbr              tinyint             NOT NULL
        , us_work_st_code                   char(2)             NOT NULL
        , canadian_work_province_code       char(2)             NOT NULL
        , ipp_payroll_id                    char(5)             NOT NULL
        , ipp_max_pay_level_amt             money               NOT NULL
        , pay_through_date                  datetime            NOT NULL
        , empl_id                           char(10)            NOT NULL
        , tax_entity_id                     char(10)            NOT NULL
        , pay_status_code                   char(1)             NOT NULL
        , clock_nbr                         char(10)            NOT NULL
        , provided_i_9_ind                  char(1)             NOT NULL
        , time_reporting_meth_code          char(1)             NOT NULL
        , regular_hrs_tracked_code          char(1)             NOT NULL
        , pay_element_ctrl_grp_id           char(10)            NOT NULL
        , pay_group_id                      char(10)            NOT NULL
        , us_pension_ind                    char(1)             NOT NULL
        , professional_cat_code             char(5)             NOT NULL
        , corporate_officer_ind             char(1)             NOT NULL
        , prim_disbursal_loc_code           char(10)            NOT NULL
        , alternate_disbursal_loc_code      char(10)            NOT NULL
        , labor_grp_code                    char(5)             NOT NULL
        , employment_info_chg_reason_cd     char(5)             NOT NULL
        , highly_compensated_emp_ind        char(1)             NOT NULL
        , nbr_of_dependent_children         tinyint             NOT NULL
        , canadian_federal_tax_meth_cd      char(1)             NOT NULL
        , canadian_federal_tax_amt          money               NOT NULL
        , canadian_federal_tax_pct          money               NOT NULL
        , canadian_federal_claim_amt        money               NOT NULL
        , canadian_province_claim_amt       money               NOT NULL
        , tax_unit_code                     char(5)             NOT NULL
        , requires_tm_card_ind              char(1)             NOT NULL
        , xfer_type_code                    char(1)             NOT NULL
        , tax_clear_code                    char(1)             NOT NULL
        , pay_type_code                     char(1)             NOT NULL
        , labor_distn_code                  char(14)            NOT NULL
        , labor_distn_ext_code              char(30)            NOT NULL
        , us_fui_status_code                char(1)             NOT NULL
        , us_fica_status_code               char(1)             NOT NULL
        , payable_through_bank_id           char(11)            NOT NULL
        , disbursal_seq_nbr_1               char(30)            NOT NULL
        , disbursal_seq_nbr_2               char(30)            NOT NULL
        , non_employee_indicator            char(1)             NOT NULL
        , excluded_from_payroll_ind         char(1)             NOT NULL
        , emp_info_source_code              char(1)             NOT NULL
        , user_amt_1                        float               NOT NULL
        , user_amt_2                        float               NOT NULL
        , user_monetary_amt_1               money               NOT NULL
        , user_monetary_amt_2               money               NOT NULL
        , user_monetary_curr_code           char(3)             NOT NULL
        , user_code_1                       char(5)             NOT NULL
        , user_code_2                       char(5)             NOT NULL
        , user_date_1                       datetime            NOT NULL
        , user_date_2                       datetime            NOT NULL
        , user_ind_1                        char(1)             NOT NULL
        , user_ind_2                        char(1)             NOT NULL
        , user_text_1                       char(50)            NOT NULL
        , user_text_2                       char(50)            NOT NULL
        , t4_employ_code                    char(2)             NOT NULL
        , chgstamp                          smallint            NOT NULL
        )


    BEGIN TRY

        SET @v_step_position = 'Declaring cursor crsrHR'

        -- Loop through ghr_employee_events_temp to populate error message log entry
        DECLARE crsrHR CURSOR FAST_FORWARD FOR
        SELECT t.aud_id
             , t.emp_id
             , t.eff_date
             , t.empl_id
             , t.labor_grp_code
             , t.file_source
        FROM #ghr_employee_events_temp t
        WHERE (event_id = @v_EVENT_ID_LABOR_GROUP)

        SET @v_step_position = 'Opening cursor crsrHR'
        OPEN crsrHR

        SET @v_step_position = 'Fetching cursor crsrHR'
        FETCH crsrHR
        INTO  @aud_id
            , @emp_id
            , @eff_date
            , @empl_id
            , @labor_grp_code
            , @file_source


        WHILE (@@FETCH_STATUS = 0)
        BEGIN

            BEGIN TRY

                SET @v_step_position = 'Begin crsrHR While Loop'

                SET @w_fatal_error = 0

                BEGIN TRAN


                ---------------------------------------------------------------------------
                ---------------------------------------------------------------------------
                --   This section will validate the interface data
                ---------------------------------------------------------------------------
                ---------------------------------------------------------------------------
                SET @v_step_position = 'Begin Validation'



                --Skip Record if associate also has New Hire, Transfer, Status Change
                IF EXISTS (
                            SELECT 1
                            FROM #ghr_employee_events_temp
                            WHERE (emp_id = @emp_id)
                            AND (event_id IN (
                                                @v_EVENT_ID_NEW_HIRE
                                             , @v_EVENT_ID_TRANSFER
                                            ))
                            UNION ALL
                            SELECT 1
                            FROM #ghr_employee_events_temp
                            WHERE (emp_id = @emp_id)
                            AND (event_id = @v_EVENT_ID_STATUS_CHANGE)
                            AND (emp_status_code = 'RH')
                          )
                BEGIN

                    SET @msg_id = 'U00119'  -- New code
                    SET @v_step_position = RTRIM(@msg_id) + 'Employee extract contains new hire, transfer, or status change event records'

                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id      AS msg_id
                        , REPLACE(REPLACE(msg_text, '@1', 'labor group'), '@2', @emp_id) AS msg_desc
                    FROM DBSCOMMON.dbo.message_master
                    WHERE (msg_id = @msg_id)

                    -- Historical Message for reporting purpose
                    EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                        @p_msg_id             = @msg_id
                        , @p_event_id           = @v_EVENT_ID_LABOR_GROUP
                        , @p_emp_id             = @emp_id
                        , @p_eff_date           = @eff_date
                        , @p_pay_element_id     = @v_EMPTY_SPACE
                        , @p_msg_p1             = @v_EMPTY_SPACE
                        , @p_msg_p2             = @v_EMPTY_SPACE
                        , @p_msg_desc           = 'Bypassing labor group record since update has either occurred in either new hire, transfer, or rehire status change event in this extract.'
                        , @p_activity_status    = @v_ACTIVITY_STATUS_WARNING
                        , @p_activity_date      = @p_activity_date
                        , @p_audit_id           = @aud_id

                    -- Skip record and al other validations
                    -- since pay group will be processed in the other events
                    GOTO BYPASS_EMPLOYEE

                END


                ---------------------------------------------------------------------------
                -- Skip record if labor group code is blank
                ---------------------------------------------------------------------------
                IF (LEN(RTRIM(@labor_grp_code)) = 0)
                BEGIN

                    SET @msg_id = 'U00110'
                    SET @v_step_position = 'Labor group code is blank'

                    -- Historical Message for reporting purpose
                    EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                        @p_msg_id             = @msg_id
                        , @p_event_id           = @v_EVENT_ID_LABOR_GROUP
                        , @p_emp_id             = @emp_id
                        , @p_eff_date           = @eff_date
                        , @p_pay_element_id     = @v_EMPTY_SPACE
                        , @p_msg_p1             = @v_EMPTY_SPACE
                        , @p_msg_p2             = @v_EMPTY_SPACE
                        , @p_msg_desc           = 'Labor group code is blank - bypassing record'
                        , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                        , @p_activity_date      = @p_activity_date
                        , @p_audit_id           = @aud_id


                    -- Skip record and all other validations
                    GOTO BYPASS_EMPLOYEE

                END


                ---------------------------------------------------------------------------
                -- Validate Effective Date
                ---------------------------------------------------------------------------
                -- Invalid date value from HCM, @v_EMPTY_SPACE@1@v_EMPTY_SPACE, for employee, @2, and event id, @3.

                -- Effective Date
                IF (@eff_date = @v_BAD_DATE_INDICATOR)
                    BEGIN

                        SET @msg_id = 'U00102'  -- New code
                        SET @v_step_position = 'Validation Effective Date - ' + RTRIM(@msg_id)

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id AS msg_id
                            , REPLACE(REPLACE(REPLACE(msg_text, '@1', @eff_date), '@2', @emp_id), '@3', @v_EVENT_ID_LABOR_GROUP) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master
                        WHERE (msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_LABOR_GROUP
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @v_EMPTY_SPACE
                            , @p_msg_p1             = @v_EMPTY_SPACE
                            , @p_msg_p2             = @v_EMPTY_SPACE
                            , @p_msg_desc           = 'Invalid Effective Date'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id


                        SET @w_fatal_error = 1

                    END


                ---------------------------------------------------------------------------
                -- Check to see if the employee exists
                ---------------------------------------------------------------------------
                SET @msg_id = 'U00012'
                SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

                SELECT @cur_empl_id                 = eempl.empl_id
                    --, @cur_tax_entity_id            = eempl.tax_entity_id
                    , @cur_eempl_eff_date           = eempl.eff_date
                    , @cur_labor_grp_code           = eempl.labor_grp_code
                    , @cur_stat_emp_status_code     = stat.emp_status_code
                FROM DBShrpn.dbo.employee emp
                JOIN DBShrpn.dbo.uvu_emp_employment_most_rec eempl ON
                    (emp.emp_id = eempl.emp_id)
                JOIN DBShrpn.dbo.uvu_emp_status_most_rec stat ON
                    (emp.emp_id = stat.emp_id)
                WHERE (emp.emp_id = @emp_id)

                IF (@@ROWCOUNT = 0)
                    BEGIN

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id      As msg_id
                            , REPLACE(msg_text, '@1', @emp_id) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master
                        WHERE (msg_id = @msg_id)


                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_LABOR_GROUP
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @v_EMPTY_SPACE
                            , @p_msg_p1             = @v_EMPTY_SPACE
                            , @p_msg_p2             = @v_EMPTY_SPACE
                            , @p_msg_desc           = 'Employee does not exist'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id


                        SET @w_fatal_error = 1

                    END


                ---------------------------------------------------------------------------
                -- Is Associate Terminated in SmartStream
                ---------------------------------------------------------------------------
                SET @msg_id = 'U00120'
                SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

                IF (@cur_stat_emp_status_code = 'T')
                    BEGIN

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id      As msg_id
                            , REPLACE(REPLACE(msg_text, '@1', 'labor group'), '@2', @emp_id) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master
                        WHERE (msg_id = @msg_id)


                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_POSITION_TITLE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @v_EMPTY_SPACE
                            , @p_msg_p1             = @labor_grp_code
                            , @p_msg_p2             = @v_EMPTY_SPACE
                            , @p_msg_desc           = 'Employee is terminated in SmartStream - bypassing record.'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id


                        SET @w_fatal_error = 1

                    END


                ---------------------------------------------------------------------------
                -- Is new labor group code same as old labor group code?
                ---------------------------------------------------------------------------
                SET @msg_id = 'U00109'
                SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

                IF (@labor_grp_code = @cur_labor_grp_code)
                    BEGIN

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id      As msg_id
                            , REPLACE(REPLACE(msg_text, '@1', @labor_grp_code), '@2', @emp_id) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master
                        WHERE (msg_id = @msg_id)


                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_LABOR_GROUP
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @v_EMPTY_SPACE
                            , @p_msg_p1             = @labor_grp_code
                            , @p_msg_p2             = @cur_labor_grp_code
                            , @p_msg_desc           = 'New labor group code is same as current labor group code - bypassing record.'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id

                        SET @w_fatal_error = 1

                    END



                ---------------------------------------------------------------------------
                -- Is Labor Group Code Valid
                ---------------------------------------------------------------------------
                SET @msg_id = 'U00111'
                SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

                IF NOT EXISTS(
                            SELECT 1
                            FROM DBShrpn.dbo.code_entry_policy
                            WHERE (code_tbl_id = '10204')   -- 'Labor Group' code table id
                            and (code_value = @labor_grp_code)
                            )
                    BEGIN

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id As msg_id
                            , REPLACE(REPLACE(msg_text, '@1', @labor_grp_code), '@2', @emp_id) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master
                        WHERE (msg_id = @msg_id)


                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_LABOR_GROUP
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @v_EMPTY_SPACE
                            , @p_msg_p1             = @labor_grp_code
                            , @p_msg_p2             = @v_EMPTY_SPACE
                            , @p_msg_desc           = 'Invalid labor group code.'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id

                        SET  @w_fatal_error = 1

                    END


                ---------------------------------------------------------------------------
                -- Effective date must be greater or equal to current effective date
                ---------------------------------------------------------------------------
                SET @msg_id = 'U00027'
                SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

                IF  (@w_fatal_error = 0) AND
                    (@eff_date < @cur_eempl_eff_date)
                    BEGIN

                        -- Convert date to string for log table
                        SET @w_msg_text_2 = CONVERT(char(8), @cur_eempl_eff_date, 112)

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id As msg_id
                            , REPLACE(REPLACE(msg_text, '@1', @eff_date), '@2', @emp_id) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master
                        WHERE (msg_id = @msg_id)


                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_LABOR_GROUP
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @v_EMPTY_SPACE
                            , @p_msg_p1             = @w_msg_text_2
                            , @p_msg_p2             = @v_EMPTY_SPACE
                            , @p_msg_desc           = 'New effective date must be greater or equal to current employee employment effective date.'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id

                        SET  @w_fatal_error = 1

                    END


                IF (@w_fatal_error = 1)
                    GOTO BYPASS_EMPLOYEE


                -- If pay group even in current transaction
                -- then update current emp employment record
                IF (@eff_date = @cur_eempl_eff_date)
                    BEGIN
                        -- Update existing record
                        UPDATE DBShrpn.dbo.emp_employment
                        SET labor_grp_code = @labor_grp_code
                        WHERE (emp_id = @emp_id)
                        AND (eff_date = @eff_date)

                    END

                ELSE -- Create new record
                    BEGIN

                        ---------------------------------------------------------------------------
                        -- Update Employee Employment with new Pay Group
                        ---------------------------------------------------------------------------

                        -- Update current record date pointers
                        UPDATE DBShrpn.dbo.emp_employment
                        SET next_eff_date = @eff_date
                        WHERE (emp_id = @emp_id)
                        AND (eff_date = @eff_date)


                        -- Create new record
                        INSERT INTO #temp14
                        SELECT emp_id
                            , @eff_date                      -- eff_date
                            , @v_END_OF_TIME_DATE              -- next_eff_date
                            , @cur_eempl_eff_date              -- prior_eff_date
                            , employment_type_code
                            , work_tm_code
                            , official_title_code
                            , official_title_date
                            , mgr_ind
                            , recruiter_ind
                            , pensioner_indicator
                            , payroll_company_code
                            , pmt_ctrl_code
                            , us_federal_tax_meth_code
                            , us_federal_tax_amt
                            , us_federal_tax_pct
                            , us_federal_marital_status_code
                            , us_federal_exemp_nbr
                            , us_work_st_code
                            , canadian_work_province_code
                            , ipp_payroll_id
                            , ipp_max_pay_level_amt
                            , pay_through_date
                            , empl_id
                            , tax_entity_id
                            , pay_status_code
                            , clock_nbr
                            , provided_i_9_ind
                            , time_reporting_meth_code
                            , regular_hrs_tracked_code
                            , pay_element_ctrl_grp_id
                            , pay_group_id
                            , us_pension_ind
                            , professional_cat_code
                            , corporate_officer_ind
                            , prim_disbursal_loc_code
                            , alternate_disbursal_loc_code
                            ---------------------------------------------------------------------------
                            , @labor_grp_code                  -- labor_grp_code
                            ---------------------------------------------------------------------------
                            , employment_info_chg_reason_cd
                            , highly_compensated_emp_ind
                            , nbr_of_dependent_children
                            , canadian_federal_tax_meth_cd
                            , canadian_federal_tax_amt
                            , canadian_federal_tax_pct
                            , canadian_federal_claim_amt
                            , canadian_province_claim_amt
                            , tax_unit_code
                            , requires_tm_card_ind
                            , xfer_type_code
                            , tax_clear_code
                            , pay_type_code
                            , labor_distn_code
                            , labor_distn_ext_code
                            , us_fui_status_code
                            , us_fica_status_code
                            , payable_through_bank_id
                            , disbursal_seq_nbr_1
                            , disbursal_seq_nbr_2
                            , non_employee_indicator
                            , excluded_from_payroll_ind
                            , emp_info_source_code
                            , user_amt_1
                            , user_amt_2
                            , user_monetary_amt_1
                            , user_monetary_amt_2
                            , user_monetary_curr_code
                            , user_code_1
                            , user_code_2
                            , user_date_1
                            , user_date_2
                            , user_ind_1
                            , user_ind_2
                            , user_text_1
                            , user_text_2
                            , t4_employ_code
                            , chgstamp
                        FROM DBShrpn.dbo.emp_employment
                        WHERE (emp_id   = @emp_id)
                        AND (eff_date = @cur_eempl_eff_date)


                        INSERT INTO emp_employment
                        SELECT emp_id
                            , eff_date
                            , next_eff_date
                            , prior_eff_date
                            , employment_type_code
                            , work_tm_code
                            , official_title_code
                            , official_title_date
                            , mgr_ind
                            , recruiter_ind
                            , pensioner_indicator
                            , payroll_company_code
                            , pmt_ctrl_code
                            , us_federal_tax_meth_code
                            , us_federal_tax_amt
                            , us_federal_tax_pct
                            , us_federal_marital_status_code
                            , us_federal_exemp_nbr
                            , us_work_st_code
                            , canadian_work_province_code
                            , ipp_payroll_id
                            , ipp_max_pay_level_amt
                            , pay_through_date
                            , empl_id
                            , tax_entity_id
                            , pay_status_code
                            , clock_nbr
                            , provided_i_9_ind
                            , time_reporting_meth_code
                            , regular_hrs_tracked_code
                            , pay_element_ctrl_grp_id
                            , pay_group_id
                            , us_pension_ind
                            , professional_cat_code
                            , corporate_officer_ind
                            , prim_disbursal_loc_code
                            , alternate_disbursal_loc_code
                            ---------------------------------------------------------------------------
                            , labor_grp_code
                            ---------------------------------------------------------------------------
                            , employment_info_chg_reason_cd
                            , highly_compensated_emp_ind
                            , nbr_of_dependent_children
                            , canadian_federal_tax_meth_cd
                            , canadian_federal_tax_amt
                            , canadian_federal_tax_pct
                            , canadian_federal_claim_amt
                            , canadian_province_claim_amt
                            , tax_unit_code
                            , requires_tm_card_ind
                            , xfer_type_code
                            , tax_clear_code
                            , pay_type_code
                            , labor_distn_code
                            , labor_distn_ext_code
                            , us_fui_status_code
                            , us_fica_status_code
                            , payable_through_bank_id
                            , disbursal_seq_nbr_1
                            , disbursal_seq_nbr_2
                            , non_employee_indicator
                            , excluded_from_payroll_ind
                            , emp_info_source_code
                            , user_amt_1
                            , user_amt_2
                            , user_monetary_amt_1
                            , user_monetary_amt_2
                            , user_monetary_curr_code
                            , user_code_1
                            , user_code_2
                            , user_date_1
                            , user_date_2
                            , user_ind_1
                            , user_ind_2
                            , user_text_1
                            , user_text_2
                            , t4_employ_code
                            , chgstamp
                        FROM #temp14 t14
                        WHERE NOT EXISTS (
                                        SELECT 1
                                        FROM DBShrpn.dbo.emp_employment t2
                                        WHERE (t2.emp_id = t14.emp_id)
                                            AND (t2.eff_date = @eff_date)
                                        )



                        /*  DO WE NEED TO CREATE AN AUDIT RECORD?????
                            -- WE'LL NEED AN ACTIVITY ACTION CODE

                                INSERT INTO work_emp_employment_aud
                                    (user_id, activity_action_code, action_date, emp_id, eff_date,
                                    next_eff_date, prior_eff_date, new_eff_date, new_empl_id,
                                    new_tax_entity_id, xfer_date, pay_through_date)
                                VALUES
                                    (@W_ACTION_USER, 'ERTRANSFER', @W_ACTION_DATETIME, @emp_id,
                                    @p_eff_date, @v_EMPTY_SPACE, @v_EMPTY_SPACE, @p_transfer_date, @v_EMPTY_SPACE, @v_EMPTY_SPACE, @v_EMPTY_SPACE, @v_EMPTY_SPACE)

                                DELETE work_emp_employment_aud
                                WHERE user_id = @W_ACTION_USER
                                AND activity_action_code = 'ERTRANSFER'
                                AND emp_id = @emp_id
                        */
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
                    , @p_event_id           = @v_EVENT_ID_LABOR_GROUP
                    , @p_emp_id             = @emp_id
                    , @p_eff_date           = @eff_date
                    , @p_pay_element_id     = @v_EMPTY_SPACE
                    , @p_msg_p1             = @v_EMPTY_SPACE
                    , @p_msg_p2             = @v_EMPTY_SPACE
                    , @p_msg_desc           = @ErrorMessage
                    , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                    , @p_activity_date      = @p_activity_date
                    , @p_audit_id           = @aud_id


            END CATCH

BYPASS_EMPLOYEE:
            -- commit records before next record in order to maintain log entries
            IF (@@TRANCOUNT > 0)
                COMMIT TRAN


            FETCH crsrHR
            INTO  @aud_id
                , @emp_id
                , @eff_date
                , @empl_id
                , @labor_grp_code
                , @file_source


        END -- end of while loop

        -- Cleanup Cursor
        CLOSE crsrHR
        DEALLOCATE crsrHR

        -- commit after every record
        IF (@@TRANCOUNT > 0)
            COMMIT TRAN


        ---------------------------------------------------------------------------
        -- Send notification of warning message U00013  -- < PAY GROUP SECTION (8) >
        ---------------------------------------------------------------------------
        SET @msg_id = 'U00107'
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

        SELECT @w_msg_text   = msg_text
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
        -- Send notification of warning message U00105 - Total nbr of employees labor group changes
        ---------------------------------------------------------------------------
        SET @msg_id = 'U00108'
        SET @v_step_position = 'Log ' + @msg_id

        SELECT @msg_id       = msg_id
            , @w_msg_text    = msg_text
            , @w_msg_text_2  = msg_text_2
            , @w_msg_text_3  = msg_text_3
            , @w_severity_cd = severity_cd
        FROM DBSCOMMON.dbo.message_master
        WHERE (msg_id = @msg_id)

        -- Get total labor group records from HCM
        SELECT @maxx = CAST(COUNT(*) AS varchar(6))
        FROM #ghr_employee_events_temp
        WHERE (event_id =   @v_EVENT_ID_LABOR_GROUP)

        IF (CHARINDEX('@1', @w_msg_text,1) > 0)
            SELECT @w_msg_text = REPLACE(@w_msg_text, '@1', @maxx)

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
        -- NOTE: log entries were created in validation section

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
            , @v_ret_val      = -1

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
            , @p_event_id           = @v_EVENT_ID_LABOR_GROUP
            , @p_emp_id             = @emp_id
            , @p_eff_date           = @eff_date
            , @p_pay_element_id     = @v_EMPTY_SPACE
            , @p_msg_p1             = @v_EMPTY_SPACE
            , @p_msg_p2             = @v_EMPTY_SPACE
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
    DROP TABLE #temp14

    RETURN @v_ret_val

END
GO

ALTER AUTHORIZATION ON dbo.usp_ins_labor_group TO  SCHEMA OWNER
GO

IF OBJECT_ID(N'dbo.usp_ins_labor_group', N'P') IS NOT NULL
    PRINT N'<<< CREATED PROCEDURE dbo.usp_ins_labor_group >>>'
ELSE
    PRINT N'<<< FAILED CREATING PROCEDURE dbo.usp_ins_labor_group >>>'
GO