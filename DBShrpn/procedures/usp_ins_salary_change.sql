USE DBShrpn
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'dbo.usp_ins_salary_change', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_ins_salary_change
    IF OBJECT_ID(N'dbo.usp_ins_salary_change') IS NOT NULL
        PRINT N'<<< FAILED DROPPING PROCEDURE dbo.usp_ins_salary_change >>>'
    ELSE
        PRINT N'<<< DROPPED PROCEDURE dbo.usp_ins_salary_change >>>'
END
GO

/*************************************************************************************
    SP Name:       usp_ins_salary_change

    Description:


    Parameters:
        @p_user_id       =  User ID (i.e. 'DBS')
        @p_batchname     = Job Scheduler Batch Name (i.e. 'GHR')
        @p_qualifier     = Job Scheduler Qualifier (i.e. 'INTERFACES')
        @p_activity_date = Current System Date


    Example:
        EXEC DBShrpn.dbo.usp_ins_salary_change
              @p_user_id          = @w_userid
            , @p_batchname       = @v_PSC_BATCHNAME
            , @p_qualifier       = @w_PSC_QUALIFIER
            , @p_activity_date   = @w_activity_date


   Revision history:
   version  date        developer   SCR         description
   -------  ----------  ---------   -----       ------------------------------------
   1.0.00   11/24/2025  CJP                     - Derived from GOG version but adapted for GOSL

************************************************************************************/

CREATE PROCEDURE dbo.usp_ins_salary_change
    (
      @p_user_id            varchar(30)
    , @p_batchname          varchar(08)
    , @p_qualifier          varchar(30)
    , @p_activity_date      datetime
    )
AS

BEGIN

    SET NOCOUNT ON

    DECLARE @v_step_position                    varchar(255)        = 'Begin Procedure'
    DECLARE @v_single_quote						char(01)            = char(39)

    DECLARE @v_END_OF_TIME_DATE                 datetime            = '29991231'
    DECLARE @v_BAD_DATE_INDICATOR               datetime            = '99991231'    -- value used to populate datetime column with value from HCM that is not a valid date after conversion

    DECLARE @v_EMPTY_SPACE                      char(01)            = ''

    DECLARE @v_EVENT_ID_NEW_HIRE                char(2)             = '01'
    DECLARE @v_EVENT_ID_SALARY_CHANGE           char(2)             = '02'
    DECLARE @v_EVENT_ID_TRANSFER                char(2)             = '03'
    DECLARE @v_EVENT_ID_NAME_CHANGE             char(2)             = '04'
    DECLARE @v_EVENT_ID_STATUS_CHANGE           char(2)             = '05'
    DECLARE @v_EVENT_ID_PAY_ELE                 char(2)             = '06'
    DECLARE @v_EVENT_ID_PAY_GROUP               char(2)             = '08'
    DECLARE @v_EVENT_ID_LABOR_GROUP             char(2)             = '09'
    DECLARE @v_EVENT_ID_POSITION_TITLE          char(2)             = '10'

    DECLARE @v_ACTIVITY_STATUS_GOOD             char(2)             = '00'
    DECLARE @v_ACTIVITY_STATUS_WARNING          char(2)             = '01'
    DECLARE @v_ACTIVITY_STATUS_BAD              char(2)             = '02'

    DECLARE @v_ASSIGNED_TO_CODE                 char(01)            = 'P'
    DECLARE @v_ORGANIZATION_CHART_NAME          varchar(64)         = 'HRGOSL'  -- Wrong value in file
    DECLARE @v_ORGANIZATION_GROUP_ID            float               = 5         -- In file but can I trust it?

    --DECLARE @v_STANDARD_DAILY_WORK_HRS          float               = 8.0       -- Correct for GOSL?
    DECLARE @v_SHIFT_DIFFERENTIAL_STATUS_CODE   char(02)            = '99'      -- Correct for GOSL?
	--DECLARE @v_PAY_BASIS_CODE					char(01)			= '9'    -- 9 = Not Applicable  -- 10/29/2025 looking up current value to bring forward
    --DECLARE @v_POSITION_OVERTIME_STATUS_CODE    char(02)            = '99'

    DECLARE @ErrorNumber                        varchar(10)
    DECLARE @ErrorMessage                       nvarchar(4000)
    DECLARE @ErrorSeverity                      int
    DECLARE @ErrorState                         int

    DECLARE @v_ret_val                          int = 0

    DECLARE @w_msg_text                         varchar(255)
    DECLARE @w_msg_text_2                       varchar(255)
    DECLARE @w_msg_text_3                       varchar(255)
    DECLARE @w_severity_cd                      tinyint
    DECLARE @w_fatal_error                      bit     = 0         --char(01)

    DECLARE @maxx                               char(06)
    DECLARE @msg_id                             char(10)
    DECLARE @cur_ea_assigned_to_code            char(01)
    DECLARE @cur_ea_job_or_pos_id               char(10)
    DECLARE @cur_ea_eff_date                    datetime
    DECLARE @cur_ea_begin_date                  datetime
    DECLARE @cur_ea_end_date                    datetime
/*
    DECLARE @cur_ea_work_tm_code                char(01)
    DECLARE @cur_ea_standard_work_hrs           float
    DECLARE @cur_ea_standard_work_pd_id         char(05)
    DECLARE @cur_ea_salary_change_date          datetime
    DECLARE @cur_ea_pd_salary_amt               money
    DECLARE @cur_ea_hourly_pay_rate             float
    DECLARE @cur_ea_annual_salary_amt           money
    DECLARE @cur_ea_curr_code                   char(03)
    DECLARE @cur_ea_pd_salary_tm_pd_id          char(05)
    DECLARE @cur_ea_pay_basis_code              char(01)
*/
    DECLARE @cur_ea_user_amt_1                  float
    DECLARE @cur_ea_user_amt_2                  float
    DECLARE @cur_ea_user_code_1                 char(05)
    DECLARE @cur_ea_user_code_2                 char(05)
    DECLARE @cur_ea_user_date_1                 datetime
    DECLARE @cur_ea_user_date_2                 datetime
    DECLARE @cur_ea_user_ind_1                  char(01)
    DECLARE @cur_ea_user_ind_2                  char(01)
    DECLARE @cur_ea_user_monetary_amt_1         money
    DECLARE @cur_ea_user_monetary_amt_2         money
    DECLARE @cur_ea_user_monetary_curr_code     char(03)
    DECLARE @cur_ea_user_text_1                 char(50)
    DECLARE @cur_ea_user_text_2                 char(50)

    DECLARE @cur_ea_chgstamp                    smallint
    DECLARE @cur_stat_emp_status_code           char(01)
    DECLARE @cur_stat_status_change_date        datetime
/*
    DECLARE @w_eff_date                         datetime
    DECLARE @w_tm_pd_annualizing_factor         float
    DECLARE @w_tm_pd_hrs                        float
	DECLARE @v_calc_fte							float
    DECLARE @w_annual_salary_amt                money
    DECLARE @w_pg_pay_frequency_code            char(05)
    DECLARE @w_pg_tm_reporting_pd_code          char(01)
*/

    -- Error message descriptions for procedure usp_hsp_upd_hasg_reassign
    DECLARE @w_error_number                     INT             = 0
    DECLARE @w_em_msg                           char(50)

    DECLARE @w_hourly_pay_rate                      float           = 0.00
    DECLARE @w_pd_salary_amt                        money           = 0.00
    DECLARE @w_pd_salary_tm_pd_id                   char(05)        = 'MONTH'
    DECLARE @w_annual_salary_amt                    money           = 0.00
    DECLARE @w_pay_basis_code                       char(01)        = '9'
    DECLARE @w_curr_code                            char(03)        = 'XCD'
    DECLARE @w_work_tm_code                         char(01)        = 'F'
    DECLARE @w_standard_daily_work_hrs              float           = 8
    DECLARE @w_standard_work_hrs                    float           = 40
    DECLARE @w_standard_work_pd_id                  char(05)        = 'WEEK'
    DECLARE @w_overtime_status_code                 char(02)        = '99'
    DECLARE @w_pay_on_reported_hrs_ind              char(01)        = 'N'
    DECLARE @w_tm_pd_hrs                            float
    DECLARE @w_calc_fte							    float

    -- This section declares the interface values from Global HR
    DECLARE @aud_id                                 int             = 0
    DECLARE @emp_id                                 char(15)        = ''
    DECLARE @eff_date                               datetime
    DECLARE @position_title                         char(50)        -- DBShrpn..emp_assignment.user_text_2
    DECLARE @pay_rate                               money
    DECLARE @file_source                            char(50)        -- 'SS VENUS' or 'SS GANYMEDE'
    DECLARE @job_or_pos_id                          char(10)        = @v_EMPTY_SPACE
    DECLARE @annual_hrs_per_fte                     money
    DECLARE @annual_rate                            money

    -- Table variable to store results from procedure usp_hsp_upd_hasg_reassign
    DECLARE @tbl_sp_err TABLE
    (
          w_error_number                        int                 NULL
        , w_jp_beg_date                         datetime            NULL
        , w_jp_eff_date                         datetime            NULL
        , w_jp_end_date                         datetime            NULL
        , asg_new_assign_id                     char(10)            NULL
        , asg_new_beg_date                      datetime            NULL
        , asg_new_end_date                      datetime            NULL
    )


    CREATE TABLE #tbl_ghr_msg
        (
          msg_id                                char(15)            NOT NULL
        , msg_desc                              varchar(255)        NOT NULL
        )

    BEGIN TRY

        SET @v_step_position = 'Declaring cursor crsrHR'

        -- Loop through ghr_employee_events_temp to populate error message log entry
        DECLARE crsrHR CURSOR FAST_FORWARD FOR
        SELECT  t.aud_id
             , t.emp_id
             , t.eff_date
             , LEFT(t.position_title, 50) AS position_title
             , t.annual_salary_amt
             , t.file_source
             , t.annual_hrs_per_fte
             , t.annual_rate
             , t.job_or_pos_id
        FROM #ghr_employee_events_temp t
        WHERE (event_id = @v_EVENT_ID_SALARY_CHANGE)

        SET @v_step_position = 'Opening cursor crsrHR'
        OPEN crsrHR

        SET @v_step_position = 'Fetching cursor crsrHR'
        FETCH crsrHR
        INTO  @aud_id
            , @emp_id
            , @eff_date
            , @position_title
            , @pay_rate
            , @file_source
            , @annual_hrs_per_fte
            , @annual_rate
            , @job_or_pos_id


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


                ---------------------------------------------------------------------------
                --Skip Record if associate has New Hire event
                ---------------------------------------------------------------------------
                IF EXISTS (
                    SELECT 1
                    FROM #ghr_employee_events_temp
                    WHERE (emp_id = @emp_id)
                    AND (event_id IN (
                                        @v_EVENT_ID_NEW_HIRE
                                    ))
                )
                BEGIN

                    SET @msg_id = 'U00119'  -- New code
                    SET @v_step_position = RTRIM(@msg_id) + 'Employee extract contains a new hire change event record'

                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id      AS msg_id
                        , REPLACE(REPLACE(t.msg_text, '@1', 'employee transfer'), '@2', @emp_id) AS msg_desc
                    FROM DBSCOMMON.dbo.message_master t
                    WHERE (t.msg_id = @msg_id)

                    -- Historical Message for reporting purpose
                    EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                        , @p_event_id           = @v_EVENT_ID_SALARY_CHANGE
                        , @p_emp_id             = @emp_id
                        , @p_eff_date           = @eff_date
                        , @p_pay_element_id     = @v_EMPTY_SPACE
                        , @p_msg_p1             = @v_EMPTY_SPACE
                        , @p_msg_p2             = @v_EMPTY_SPACE
                        , @p_msg_desc           = 'Bypassing salary update since employee has a new hire update event in this extract.'
                        , @p_activity_status    = @v_ACTIVITY_STATUS_WARNING
                        , @p_activity_date      = @p_activity_date
                        , @p_audit_id           = @aud_id

                    -- Skip record and all other validations
                    -- since labor group will be processed in the other events
                    GOTO BYPASS_EMPLOYEE

                END

                ---------------------------------------------------------------------------
                --Skip Record if associate has Status Change Rehire Event
                ---------------------------------------------------------------------------
                IF EXISTS (
                    SELECT 1
                    FROM #ghr_employee_events_temp
                    WHERE (emp_id          = @emp_id)
                      AND (event_id        = @v_EVENT_ID_STATUS_CHANGE)
                      AND (emp_status_code = 'RH')

                )
                BEGIN

                    SET @msg_id = 'U00119'  -- New code
                    SET @v_step_position = RTRIM(@msg_id) + 'Employee extract contains a rehire status change event record'

                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id      AS msg_id
                        , REPLACE(REPLACE(t.msg_text, '@1', 'rehire status change'), '@2', @emp_id) AS msg_desc
                    FROM DBSCOMMON.dbo.message_master t
                    WHERE (t.msg_id = @msg_id)

                    -- Historical Message for reporting purpose
                    EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                        , @p_event_id           = @v_EVENT_ID_SALARY_CHANGE
                        , @p_emp_id             = @emp_id
                        , @p_eff_date           = @eff_date
                        , @p_pay_element_id     = @v_EMPTY_SPACE
                        , @p_msg_p1             = @v_EMPTY_SPACE
                        , @p_msg_p2             = @v_EMPTY_SPACE
                        , @p_msg_desc           = 'Bypassing salary update since employee has a new hire update event in this extract.'
                        , @p_activity_status    = @v_ACTIVITY_STATUS_WARNING
                        , @p_activity_date      = @p_activity_date
                        , @p_audit_id           = @aud_id

                    -- Skip record and all other validations
                    -- since labor group will be processed in the other events
                    GOTO BYPASS_EMPLOYEE

                END

                ---------------------------------------------------------------------------
                -- Validate Salary Amount
                ---------------------------------------------------------------------------
                SET @v_step_position = 'Validate Annual Salary (PayRate)'

                IF (@pay_rate = 0.00)
                    BEGIN

                        SET @msg_id = 'U00041'
                        SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id AS msg_id
                            , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master t
                        WHERE (t.msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_SALARY_CHANGE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @v_EMPTY_SPACE
                            , @p_msg_p1             = @pay_rate
                            , @p_msg_p2             = @v_EMPTY_SPACE
                            , @p_msg_desc           = 'Annual salary amount (PayRate) cannot be zero.'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id

                        SET @w_fatal_error = 1

                    END


                ---------------------------------------------------------------------------
                -- Validate Annual Hours Per FTE
                ---------------------------------------------------------------------------
                SET @v_step_position = 'Validate Annual Hours per FTE'

                IF (@annual_hrs_per_fte = 0.00)
                    BEGIN

                        SET @msg_id = 'U00124'
                        SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id AS msg_id
                            , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master t
                        WHERE (msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_SALARY_CHANGE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @v_EMPTY_SPACE
                            , @p_msg_p1             = @annual_hrs_per_fte
                            , @p_msg_p2             = @v_EMPTY_SPACE
                            , @p_msg_desc           = 'Invalid annual hours per FTE.'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id

                        SET @w_fatal_error = 1

                    END


                -- Log warning if annual hours are less than 2080
                IF (@annual_hrs_per_fte > 0.00) AND
                   (@annual_hrs_per_fte < 2080.00)
                    BEGIN

                        SET @msg_id = 'U00124'
                        SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id AS msg_id
                            , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master t
                        WHERE (msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_SALARY_CHANGE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @v_EMPTY_SPACE
                            , @p_msg_p1             = @annual_hrs_per_fte
                            , @p_msg_p2             = @v_EMPTY_SPACE
                            , @p_msg_desc           = 'Warning - annual hours per FTE less than 2080 hours.'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_WARNING
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id

                    END


                ---------------------------------------------------------------------------
                -- Validate Annual Rate
                ---------------------------------------------------------------------------
                SET @v_step_position = 'Validate Annual Rate'

                IF (@annual_rate = 0.00)
                    BEGIN

                        SET @msg_id = 'U00125'
                        SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id AS msg_id
                            , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master t
                        WHERE (msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_SALARY_CHANGE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @v_EMPTY_SPACE
                            , @p_msg_p1             = @annual_rate
                            , @p_msg_p2             = @v_EMPTY_SPACE
                            , @p_msg_desc           = 'Invalid annual hours per FTE.'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id

                        SET @w_fatal_error = 1

                    END


                ---------------------------------------------------------------------------
                -- Validate Effective Date
                ---------------------------------------------------------------------------
                IF (@eff_date = @v_BAD_DATE_INDICATOR)
                    BEGIN

                        SET @msg_id = 'U00102'  -- New code
                        SET @v_step_position = 'Validation Effective Date - ' + RTRIM(@msg_id)

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id AS msg_id
                            , REPLACE(REPLACE(REPLACE(t.msg_text, '@1', CONVERT(char(8), @eff_date, 112)), '@2', @emp_id), '@3', @v_EVENT_ID_NEW_HIRE) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master t
                        WHERE (msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_SALARY_CHANGE
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

                SELECT    @cur_ea_assigned_to_code              = ea.assigned_to_code
                        , @cur_ea_job_or_pos_id                 = ea.job_or_pos_id
                        , @cur_ea_eff_date                      = ea.eff_date
                        , @cur_ea_begin_date                    = ea.begin_date
                        , @cur_ea_end_date                      = ea.end_date
                        /*
                        , @cur_ea_work_tm_code                  = ea.work_tm_code
                        , @cur_ea_standard_work_hrs             = ea.standard_work_hrs
                        , @cur_ea_standard_work_pd_id           = ea.standard_work_pd_id
                        , @cur_ea_salary_change_date            = ea.salary_change_date
                        , @cur_ea_pd_salary_amt                 = ea.pd_salary_amt
                        , @cur_ea_hourly_pay_rate               = ea.hourly_pay_rate
                        , @cur_ea_annual_salary_amt             = ea.annual_salary_amt
                        , @cur_ea_curr_code                     = ea.curr_code
                        , @cur_ea_pd_salary_tm_pd_id            = ea.pd_salary_tm_pd_id
                        , @cur_ea_pay_basis_code                = ea.pay_basis_code
                        */
                        -- Capture values from user defined fields to bring forward
                        , @cur_ea_user_amt_1                    = ea.user_amt_1
                        , @cur_ea_user_amt_2                    = ea.user_amt_2
                        , @cur_ea_user_code_1                   = ea.user_code_1
                        , @cur_ea_user_code_2                   = ea.user_code_2
                        , @cur_ea_user_date_1                   = ea.user_date_1
                        , @cur_ea_user_date_2                   = ea.user_date_2
                        , @cur_ea_user_ind_1                    = ea.user_ind_1
                        , @cur_ea_user_ind_2                    = ea.user_ind_2
                        , @cur_ea_user_monetary_amt_1           = ea.user_monetary_amt_1
                        , @cur_ea_user_monetary_amt_2           = ea.user_monetary_amt_2
                        , @cur_ea_user_monetary_curr_code       = ea.user_monetary_curr_code
                        , @cur_ea_user_text_1                   = ea.user_text_1
                        , @cur_ea_user_text_2                   = ea.user_text_2

                        , @cur_ea_chgstamp                      = ea.chgstamp
                        , @cur_stat_emp_status_code             = stat.emp_status_code
                        , @cur_stat_status_change_date          = stat.status_change_date

                FROM DBShrpn.dbo.employee emp
                JOIN DBShrpn.dbo.uvu_emp_assignment_most_rec ea ON
                    (emp.emp_id = ea.emp_id)
                JOIN DBShrpn.dbo.uvu_emp_status_most_rec stat ON
                    (emp.emp_id = stat.emp_id)
                WHERE (emp.emp_id = @emp_id)

                IF (@@ROWCOUNT = 0)
                    BEGIN

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id As msg_id
                            , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master t
                        WHERE (t.msg_id = @msg_id)


                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_SALARY_CHANGE
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
                            , REPLACE(REPLACE(t.msg_text, '@1', 'salary update'), '@2', @emp_id) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master t
                        WHERE (t.msg_id = @msg_id)


                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_SALARY_CHANGE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @v_EMPTY_SPACE
                            , @p_msg_p1             = @position_title
                            , @p_msg_p2             = @v_EMPTY_SPACE
                            , @p_msg_desc           = 'Employee is terminated in SmartStream - bypassing record.'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id


                        SET @w_fatal_error = 1

                    END


                ---------------------------------------------------------------------------
                -- Effective date must be greater or equal to current effective date
                ---------------------------------------------------------------------------
                SET @msg_id = 'U00027'
                SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

                IF (@w_fatal_error = 0) AND
                (@eff_date < @cur_ea_eff_date)
                    BEGIN

                        -- Convert date to string for log table
                        SET @w_msg_text_2 = CONVERT(char(8), @cur_ea_eff_date, 112)

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id As msg_id
                            , REPLACE(REPLACE(t.msg_text, '@1', @w_msg_text_2), '@2', @emp_id) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master t
                        WHERE (t.msg_id = @msg_id)


                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_SALARY_CHANGE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @v_EMPTY_SPACE
                            , @p_msg_p1             = @w_msg_text_2
                            , @p_msg_p2             = @v_EMPTY_SPACE
                            , @p_msg_desc           = 'New effective date must be greater than or equal to current employee assignment effective date.'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id


                        SET  @w_fatal_error = 1

                    END


                IF (@w_fatal_error = 1)
                    GOTO BYPASS_EMPLOYEE


                ---------------------------------------------------------------------------
                -- Salary Setup
                ---------------------------------------------------------------------------
                -- Universally setup all associates as monthly; 8 hrs/day; 40 hrs/week
                -- Indicates that the associate is setup as annually
                IF (@pay_rate = @annual_rate)
                    SELECT @w_annual_salary_amt       = @pay_rate
                         , @w_pay_basis_code          = '2'     -- Period Salary
                         , @w_pd_salary_amt           = ROUND(@pay_rate / 12, 2)
                         , @w_pd_salary_tm_pd_id      = 'MONTH'
                         , @w_hourly_pay_rate         = ROUND(@annual_rate / @annual_hrs_per_fte, 2)
                         , @w_work_tm_code            = 'F'     -- Fulltime
                         , @w_pay_on_reported_hrs_ind = 'N'     -- Pay Based on Standard Hours Checkbox
                         , @w_standard_work_hrs       = 40.0
                         , @w_standard_work_pd_id     = 'WEEK'

                ELSE
                    -- Hourly setup
                    BEGIN
                        -- unique settings based on environment
                        IF (@file_source = 'SS VENUS')
                            SELECT @w_standard_work_hrs   = 188.0
                                , @w_standard_work_pd_id = 'MONTH'
                        ELSE
                            -- SS GANYMEDE
                            SELECT @w_standard_work_hrs  = 80.0
                                , @w_standard_work_pd_id = 'BI-WK'

                        -- Universal hourly rate setup
                        SELECT @w_annual_salary_amt      = @annual_rate
                            , @w_pay_basis_code          = '9'      -- Not Applicable
                            , @w_pd_salary_amt           = 0.00     -- ROUND((@pay_rate * @annual_hrs_per_fte) / 12, 2)
                            , @w_pd_salary_tm_pd_id      = @v_EMPTY_SPACE
                            , @w_hourly_pay_rate         = @pay_rate
                            , @w_work_tm_code            = 'U'      -- Unspecified
                            , @w_pay_on_reported_hrs_ind = 'Y'      -- Pay Based on Standard Hours Checkbox

                    END

                ---------------------------------------------------------------------------
                -- Calculate FTE
                ---------------------------------------------------------------------------
                -- Lookup Time Period Hours
                SELECT @w_tm_pd_hrs = tm_pd_hrs
                FROM DBShrpn.dbo.tm_pd_policy
                WHERE (tm_pd_id = @w_standard_work_pd_id)

                SET @w_calc_fte = ROUND(@w_standard_work_hrs / @w_tm_pd_hrs, 2)




                -- Is old position still in place
                -- need to end current assignment and begin new one
                -- begin date is for new record and end date is for the prior record
                IF (@cur_ea_job_or_pos_id <> @job_or_pos_id)
                    BEGIN

                        /*
                        SET @v_step_position = 'Emp Assignment - Reassign Debug'

                        -- Debug
                        INSERT DBShrpn.dbo.ghr_debug (text_line)
                        VALUES ('EXEC DBShrpn.dbo.usp_hsp_upd_hasg_reassign')
                        , ('  @asg_cur_id                  = ' + @v_single_quote + RTRIM(@emp_id)                                        + @v_single_quote)
                        , (', @asg_cur_assign_to           = ' + @v_single_quote + @v_ASSIGNED_TO_CODE                                   + @v_single_quote)
                        , (', @asg_cur_assign_id           = ' + @v_single_quote + RTRIM(@cur_ea_job_or_pos_id)                          + @v_single_quote)
                        , (', @asg_cur_eff_date            = ' + @v_single_quote + CONVERT(char(8), @cur_ea_eff_date, 112)               + @v_single_quote)
                        , (', @asg_cur_chgstamp            = ' +                   CONVERT(varchar, @cur_ea_chgstamp, 0)                                  )
                        , (', @asg_new_assign_to           = ' + @v_single_quote + @v_ASSIGNED_TO_CODE                                   + @v_single_quote)
                        , (', @asg_new_assign_id           = ' + @v_single_quote + RTRIM(@job_or_pos_id)                                 + @v_single_quote)
                        , (', @asg_new_assign_reason       = ' + @v_single_quote + @v_EMPTY_SPACE                                        + @v_single_quote)
                        , (', @asg_new_beg_date            = ' + @v_single_quote + CONVERT(char(8), @w_eff_date, 112)                    + @v_single_quote)
                        , (', @asg_new_end_date            = ' + @v_single_quote + CONVERT(char(8), @v_END_OF_TIME_DATE, 112)            + @v_single_quote)
                        , (', @asg_fte_error_level         = ' + @v_single_quote + 'R'                                                   + @v_single_quote)
                        , (', @asg_incumbent_error_level   = ' + @v_single_quote + @v_EMPTY_SPACE                                        + @v_single_quote)    -- was 'R' in WTW
                        , (', @asf_fs_error_level          = ' + @v_single_quote + 'R'                                                   + @v_single_quote)
                        , (', @asg_new_work_time_ind       = ' + @v_single_quote + @w_work_tm_code                                       + @v_single_quote)
                        , (', @asg_new_std_hours           = ' +                   CONVERT(varchar, @w_standard_work_hrs, 0)                              )
                        , (', @asg_new_std_work_period     = ' + @v_single_quote + @w_standard_work_pd_id                                + @v_single_quote)
                        , (', @asg_new_salary_chg_date     = ' + @v_single_quote + CONVERT(char(8), @eff_date, 112)                      + @v_single_quote)
                        , (', @asg_new_pd_salry            = ' +                   CONVERT(varchar, @w_pd_salary_amt, 0)                                  )
                        , (', @asg_new_hourly_rate         = ' +                   CONVERT(varchar, @w_hourly_pay_rate, 0)                                )
                        , (', @asg_new_annual_salry        = ' +                   CONVERT(varchar, @w_annual_salary_amt, 0)                              )
                        , (', @asg_new_fte                 = ' +                   CONVERT(varchar, @w_calc_fte, 0)                                       )
                        , (', @app_offer_curr_code         = ' + @v_single_quote + @w_curr_code                                          + @v_single_quote)     -- char(03)
                        , (', @app_offer_pd_salary_time_cd = ' + @v_single_quote + @w_pd_salary_tm_pd_id                                 + @v_single_quote)
                        , (', @app_offer_org_chart_id      = ' + @v_single_quote + @v_ORGANIZATION_CHART_NAME                            + @v_single_quote)
                        , (', @app_offer_org_unit_id       = ' + @v_single_quote + @v_EMPTY_SPACE                                        + @v_single_quote)
                        , (', @app_offer_pay_hours_rpt_ind = ' + @v_single_quote + 'N'                                                   + @v_single_quote)
                        , (', @app_offer_work_shift_code   = ' + @v_single_quote + @v_EMPTY_SPACE                                        + @v_single_quote)
                        , (', @app_offer_pay_grade         = ' + @v_single_quote + @v_EMPTY_SPACE                                        + @v_single_quote)
                        , (', @app_offer_points            = 0'                                                                                           )
                        , (', @app_offer_salary_step       = 0'                                                                                           )
                        , (', @app_offer_mgr_emp_id        = ' + @v_single_quote + @v_EMPTY_SPACE                                        + @v_single_quote)
                        , (', @from_window                 = ' + @v_single_quote + 'HASG'                                                + @v_single_quote)
                        , (', @w_primary_ind               = ' + @v_single_quote + 'Y'                                                   + @v_single_quote)
                        , (', @w_new_guar_pd_salry         = 0'                                                                                           )
                        , (', @w_new_guar_hourly_rate      = 0'                                                                                           )
                        , (', @w_new_guar_annual_salry     = 0'                                                                                           )
                        , (', @w_new_ref_pd_salry          = 0'                                                                                           )
                        , (', @w_new_ref_hourly_rate       = 0'                                                                                           )
                        , (', @w_new_ref_salry             = 0'                                                                                           )
                        , (', @w_new_org_group             = ' +                   CONVERT(varchar, @v_ORGANIZATION_GROUP_ID, 0)                          )         -- NOT USED IN PROCEDURE
                        , (', @app_new_shift_rate_id       = ' + @v_single_quote + @v_EMPTY_SPACE                                        + @v_single_quote)
                        , (' ');
                        */

                        SET @v_step_position = 'Emp Assignment - Reassign'

                        -- Clear any previous messages
                        DELETE FROM @tbl_sp_err

                        INSERT INTO @tbl_sp_err (
                                                  w_error_number
                                                , w_jp_beg_date
                                                , w_jp_eff_date
                                                , w_jp_end_date
                                                , asg_new_assign_id
                                                , asg_new_beg_date
                                                , asg_new_end_date
                                                )
                        EXEC DBShrpn.dbo.usp_hsp_upd_hasg_reassign
                              @asg_cur_id                  = @emp_id                                    -- char(15)
                            , @asg_cur_assign_to           = @v_ASSIGNED_TO_CODE                        -- char(01)
                            , @asg_cur_assign_id           = @cur_ea_job_or_pos_id                      -- char(10)
                            , @asg_cur_eff_date            = @cur_ea_eff_date                           -- datetime
                            , @asg_cur_chgstamp            = @cur_ea_chgstamp                           -- smallint
                            , @asg_new_assign_to           = @v_ASSIGNED_TO_CODE                        -- char(01)
                            , @asg_new_assign_id           = @job_or_pos_id                             -- char(10)
                            , @asg_new_assign_reason       = @v_EMPTY_SPACE                             -- char(05)
                            , @asg_new_beg_date            = @eff_date                                -- datetime
                            , @asg_new_end_date            = @v_END_OF_TIME_DATE                        -- datetime
                            , @asg_fte_error_level         = 'R'                                        -- char(01)
                            , @asg_incumbent_error_level   = @v_EMPTY_SPACE                             -- char(01)        -- was 'R' in WTW
                            , @asf_fs_error_level          = 'R'                                        -- char(01)
                            , @asg_new_work_time_ind       = @w_work_tm_code                            -- char(01)
                            , @asg_new_std_hours           = @w_standard_work_hrs                       -- float
                            , @asg_new_std_work_period     = @w_standard_work_pd_id                     -- char(05)
                            , @asg_new_salary_chg_date     = @eff_date                                  -- datetime
                            , @asg_new_pd_salry            = @w_pd_salary_amt                           -- money
                            , @asg_new_hourly_rate         = @w_hourly_pay_rate                         -- float
                            , @asg_new_annual_salry        = @w_annual_salary_amt                       -- money
                            , @asg_new_fte                 = @w_calc_fte                                -- float
                            , @app_offer_curr_code         = @w_curr_code                               -- char(03)
                            , @app_offer_pd_salary_time_cd = @w_pd_salary_tm_pd_id                      -- char(05)
                            , @app_offer_org_chart_id      = @v_ORGANIZATION_CHART_NAME                 -- char(64)
                            , @app_offer_org_unit_id       = @v_EMPTY_SPACE                             -- char(240)
                            , @app_offer_pay_hours_rpt_ind = 'N'                                        -- char(01)
                            , @app_offer_work_shift_code   = @v_EMPTY_SPACE                             -- char(05)
                            , @app_offer_pay_grade         = @v_EMPTY_SPACE                             -- char(06)
                            , @app_offer_points            = 0                                          -- smallint
                            , @app_offer_salary_step       = 0                                          -- smallint
                            , @app_offer_mgr_emp_id        = @v_EMPTY_SPACE                             -- char(15)
                            , @from_window                 = 'HASG'                                     -- char(04)
                            , @w_primary_ind               = 'Y'                                        -- char(01)
                            , @w_new_guar_pd_salry         = 0                                          -- money
                            , @w_new_guar_hourly_rate      = 0                                          -- float
                            , @w_new_guar_annual_salry     = 0                                          -- money
                            , @w_new_ref_pd_salry          = 0                                          -- money
                            , @w_new_ref_hourly_rate       = 0                                          -- float
                            , @w_new_ref_salry             = 0                                          -- money
                            , @w_new_org_group             = @v_ORGANIZATION_GROUP_ID                   -- int              -- NOT USED IN PROCEDURE
                            , @app_new_shift_rate_id       = @v_EMPTY_SPACE                             -- char(10)

                        -- Raise error if there any error number is returned by procedure
                        -- Note: The other error codes in the procedure will be raised there
                        SELECT @w_error_number = ISNULL(w_error_number, -1)
                        FROM @tbl_sp_err

                        IF (@w_error_number <> 0)
                        BEGIN
                            -- Translate error codes from procedure
                            SELECT @w_em_msg = CASE @w_error_number
                                                 WHEN 26177 THEN '26177 - Employee is already assigned to this job/position.'
                                                 WHEN 26178 THEN '26178 - Employee is already assigned to this job/position.'
                                                 WHEN 26132 THEN '26132 - Invalid job/position.'
                                                 WHEN 26129 THEN '26129 - Job exists in the future.'
                                                 WHEN 26130 THEN '26130 - New begin date is not within job''s end date.'
                                                 WHEN 26131 THEN '26131 - New end date is not within job''s end date.'
                                                 WHEN 26133 THEN '26133 - Position exists in the future.'
                                                 WHEN 26138 THEN '26138 - New begin date is not within position''s end date.'
                                                 WHEN 26139 THEN '26139 - New end date is not within position''s end date.'
                                                 WHEN 26082 THEN '26082 - Assignments to this position are not allowed.'
                                                 WHEN 26007 THEN '26007 - Position incumbent''s exceeded but you may continue.'
                                                 WHEN 26008 THEN '26008 - Position incumbent''s exceeded but you not may continue.'
                                                 WHEN 26005 THEN '26005 - Position FTE''s exceeded but you may continue.'
                                                 WHEN 26006 THEN '26006 - Position FTE''s exceeded but you not may continue.'
                                                 ELSE 'Unidentified error'
                                              END
                            -- Return error back to catch block
                            RAISERROR (
                                       @w_em_msg
                                      , 16
                                      , 1
                                      )
                        END


                        ---------------------------------------------------------------------------
                        -- Update position title
                        ---------------------------------------------------------------------------
                        -- Also bring forward the other user defined field values to new employee assignment record

                        SET @v_step_position = @v_step_position + ' - User Defined Fields'

                        UPDATE DBShrpn.dbo.emp_assignment
                        SET   user_amt_1                = @cur_ea_user_amt_1
                            , user_amt_2                = @cur_ea_user_amt_2
                            , user_code_1               = @cur_ea_user_code_1
                            , user_code_2               = @cur_ea_user_code_2
                            , user_date_1               = @cur_ea_user_date_1
                            , user_date_2               = @cur_ea_user_date_2
                            , user_ind_1                = @cur_ea_user_ind_1
                            , user_ind_2                = @cur_ea_user_ind_2
                            , user_monetary_amt_1       = @cur_ea_user_monetary_amt_1
                            , user_monetary_amt_2       = @cur_ea_user_monetary_amt_2
                            , user_monetary_curr_code   = @cur_ea_user_monetary_curr_code
                            , user_text_1               = @cur_ea_user_text_1
                            , user_text_2               = @position_title
                        WHERE   (emp_id             = @emp_id)
                            AND (assigned_to_code   = @v_ASSIGNED_TO_CODE)
                            AND (job_or_pos_id      = @job_or_pos_id)
                            AND (eff_date           = @eff_date)
                            AND (next_eff_date      = @v_END_OF_TIME_DATE)


                    END

                ELSE
                    BEGIN
                        /*
                        SET @v_step_position = 'Emp Assignment - Update Assignment Debug'

                        -- DEBUG
                        INSERT DBShrpn.dbo.ghr_debug (text_line)
                        VALUES ('EXEC DBShrpn.dbo.usp_hsp_upd_hasg')
                        , ('@use_eff_date                  = ' + @v_single_quote + CONVERT(varchar, @w_eff_date, 112)                                        + @v_single_quote)         -- datetime
                        , (', @use_end_date                  = ' + @v_single_quote + CONVERT(varchar, @v_END_OF_TIME_DATE, 112)                              + @v_single_quote)         -- datetime     -- NOT USED IN PROCEDURE
                        , (', @employee_identifier           = ' + @v_single_quote + RTRIM(@emp_id)                                                          + @v_single_quote)         -- char(15)
                        , (', @emp_asgmt_assigned_to_code    = ' + @v_single_quote + @v_ASSIGNED_TO_CODE                                                     + @v_single_quote)         -- char(01)
                        , (', @emp_asgmt_job_or_pos_id       = ' + @v_single_quote + RTRIM(@job_or_pos_id)                                                   + @v_single_quote)         -- char(10)
                        , (', @emp_asgmt_eff_date            = ' + @v_single_quote + CONVERT(varchar, @eff_date, 112)                                 + @v_single_quote)         -- datetime
                        , (', @emp_asgmt_next_eff_date       = ' + @v_single_quote + CONVERT(varchar, @v_END_OF_TIME_DATE, 112)                              + @v_single_quote)         -- datetime
                        , (', @emp_asgmt_prior_eff_dt        = ' + @v_single_quote + CONVERT(varchar, @cur_ea_eff_date, 112)                                 + @v_single_quote)         -- datetime     -- NOT USED IN PROCEDURE
                        , (', @emp_asgmt_begin_date          = ' + @v_single_quote + CONVERT(varchar, @cur_ea_begin_date, 112)                               + @v_single_quote)         -- datetime     ** since assignment didn't change then get original begin date
                        , (', @emp_asgmt_end_date            = ' + @v_single_quote + CONVERT(varchar, @v_END_OF_TIME_DATE, 112)                              + @v_single_quote)         -- datetime
                        , (', @emp_display_name              = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(45)     -- NOT USED IN PROCEDURE
                        , (', @emp_status_code               = ' + @v_single_quote + @cur_stat_emp_status_code                                               + @v_single_quote)         -- char(01)     -- NOT USED IN PROCEDURE
                        , (', @emp_status_change_date        = ' + @v_single_quote + CONVERT(varchar, @cur_stat_status_change_date, 112)                     + @v_single_quote)         -- datetime     -- NOT USED IN PROCEDURE
                        , (', @w_job_or_pos_title            = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(10)     -- NOT USED IN PROCEDURE
                        , (', @tm_pd_id                      = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(05)
                        , (', @tm_pd_hrs                     = 0'                                                                                                             )         -- float        -- NOT USED IN PROCEDURE
                        , (', @emp_asgmt_reason_code         = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(05)
                        , (', @emp_prime_assignment_ind      = ' + @v_single_quote + 'Y'                                                                     + @v_single_quote)         -- char(01)
                        , (', @emp_asgmt_reason_code         = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(05)
                        , (', @emp_occupancy_code            = ' + @v_single_quote + '3'                                                                     + @v_single_quote)         -- char(01)
                        , (', @emp_asgmt_official_title_code = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(05)
                        , (', @emp_asgmt_official_title_date = ' + @v_single_quote + CONVERT(varchar, @v_END_OF_TIME_DATE, 112)                              + @v_single_quote)         -- datetime
                        , (', @emp_autopay_ind               = ' + @v_single_quote + 'N'                                                                     + @v_single_quote)         -- char(1)
                        , (', @emp_asgmt_annual_salary       = ' +                   CONVERT(varchar, @w_annual_salary_amt, 0)                                                )         -- money
                        , (', @emp_asgmt_salary_curr_cd      = ' + @v_single_quote + @w_curr_code                                                            + @v_single_quote)         -- char(03)
                        , (', @emp_asgmt_pd_salary           = ' +                   CONVERT(varchar, @w_pd_salary_amt, 0)                                                    )         -- money
                        , (', @emp_pay_on_rptd_hrs_ind       = ' + @v_single_quote + @w_pay_on_reported_hrs_ind                                              + @v_single_quote)         -- char(01)
                        , (', @emp_asgmt_hourly_pay_rate     = ' +                   CONVERT(varchar, @w_hourly_pay_rate, 0)                                                  )         -- float
                        , (', @emp_asgmt_salary_change_type  = ' + @v_single_quote + 'M'                                                                     + @v_single_quote)         -- char(05)          -- Was 'M' in WTW
                        , (', @emp_asgmt_standard_work_hrs   = ' +                   CONVERT(varchar, @w_standard_work_hrs, 0)                                                )         -- float
                        , (', @emp_asgmt_standard_work_pd_id = ' + @v_single_quote + @w_standard_work_pd_id                                                  + @v_single_quote)         -- char(05)
                        , (', @emp_asgmt_work_tm_code        = ' + @v_single_quote + @w_work_tm_code                                                         + @v_single_quote)         -- char(01)
                        , (', @emp_pay_basis_code            = ' + @v_single_quote + @w_pay_basis_code                                                       + @v_single_quote)         -- char(01)
                        , (', @emp_asgmt_salary_change_date  = ' + @v_single_quote + CONVERT(varchar, @eff_date, 112)                                        + @v_single_quote)         -- datetime
                        , (', @emp_asgmt_pd_salary_tm_pd     = ' + @v_single_quote + RTRIM(@w_pd_salary_tm_pd_id)                                       + @v_single_quote)         -- char(05)
                        , (', @emp_base_rate_tbl_id          = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(10)
                        , (', @emp_base_rate_tbl_entry_code  = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(08)
                        , (', @emp_exception_rate_ind        = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(01)
                        , (', @emp_overtime_status_code      = ' + @v_single_quote + @w_overtime_status_code                                                 + @v_single_quote)         -- char(02)
                        , (', @emp_standard_daily_work_hrs   = ' +                   CONVERT(varchar, @w_standard_daily_work_hrs, 0)                                          )         -- float
                        , (', @pd_salary_pd_annlzg_factor    = 0.00'                                                                                                          )         -- float        -- NOT USED IN PROCEDURE
                        , (', @pd_salary_pd_hrs              = 0.00'                                                                                                          )         -- float        -- NOT USED IN PROCEDURE
                        , (', @emp_asgmt_salary_structure_id = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(10)
                        , (', @emp_asgmt_increase_guidel_id  = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(10)
                        , (', @emp_asgmt_pay_grade           = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(06)
                        , (', @emp_asgmt_pay_grade_date      = ' + @v_single_quote + CONVERT(varchar, @v_END_OF_TIME_DATE, 112)                              + @v_single_quote)         -- datetime
                        , (', @emp_asgmt_job_eval_points     = 0'                                                                                                             )         -- smallint
                        , (', @emp_asgmt_salary_step         = 0'                                                                                                             )         -- smallint
                        , (', @emp_asgmt_salary_step_date    = ' + @v_single_quote + CONVERT(varchar, @v_END_OF_TIME_DATE, 112)                              + @v_single_quote)         -- datetime
                        , (', @emp_asgmt_phn1_type_code      = ' + @v_single_quote + 'WORK'                                                                  + @v_single_quote)         -- char(05)
                        , (', @emp_asgmt_phn1_fmt_code       = ' + @v_single_quote + 'L34'                                                                   + @v_single_quote)         -- char(06)
                        , (', @emp_asgmt_phn1_fmt_delimeter  = ' + @v_single_quote + '-'                                                                     + @v_single_quote)         -- char(01)
                        , (', @emp_asgmt_phn2_type_code      = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(05)
                        , (', @emp_asgmt_phn2_fmt_code       = ' + @v_single_quote + 'L34'                                                                   + @v_single_quote)         -- char(06)
                        , (', @emp_asgmt_phn2_fmt_delimeter  = ' + @v_single_quote + '-'                                                                     + @v_single_quote)         -- char(01)
                        , (', @emp_asgmt_phn1_intl_code      = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(04)
                        , (', @emp_asgmt_phn1_country_code   = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(04)
                        , (', @emp_asgmt_phn1_area_city_code = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(05)
                        , (', @emp_asgmt_phn1_nbr            = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(12)
                        , (', @emp_asgmt_phn1_ext_nbr        = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(05)
                        , (', @emp_asgmt_phn2_intl_code      = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(04)
                        , (', @emp_asgmt_phn2_country_code   = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(04)
                        , (', @emp_asgmt_phn2_area_city_code = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(05)
                        , (', @emp_asgmt_phn2_nbr            = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(12)
                        , (', @emp_asgmt_phn2_ext_nbr        = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(05)
                        , (', @emp_asgmt_user_amt_1          = ' +                   CONVERT(varchar, @cur_ea_user_amt_1, 0)                                                  )         -- float
                        , (', @emp_asgmt_user_amt_2          = ' +                   CONVERT(varchar, @cur_ea_user_amt_2, 0)                                                  )         -- float
                        , (', @emp_asgmt_user_code_1         = ' + @v_single_quote + @cur_ea_user_code_1                                                     + @v_single_quote)         -- char(05)
                        , (', @emp_asgmt_user_code_2         = ' + @v_single_quote + @cur_ea_user_code_2                                                     + @v_single_quote)         -- char(05)
                        , (', @emp_asgmt_user_date_1         = ' + @v_single_quote + CONVERT(varchar, @cur_ea_user_date_1, 112)                              + @v_single_quote)         -- datetime
                        , (', @emp_asgmt_user_date_2         = ' + @v_single_quote + CONVERT(varchar, @cur_ea_user_date_2, 112)                              + @v_single_quote)         -- datetime
                        , (', @emp_asgmt_user_ind_1          = ' + @v_single_quote + @cur_ea_user_ind_1                                                      + @v_single_quote)         -- char(01)
                        , (', @emp_asgmt_user_ind_2          = ' + @v_single_quote + @cur_ea_user_ind_2                                                      + @v_single_quote)         -- char(01)
                        , (', @emp_user_monetary_amt_1       = ' +                   CONVERT(varchar, @cur_ea_user_monetary_amt_1, 0)                                         )         -- money
                        , (', @emp_user_monetary_amt_2       = ' +                   CONVERT(varchar, @cur_ea_user_monetary_amt_2, 0)                                         )         -- money
                        , (', @emp_user_monetary_curr_code   = ' + @v_single_quote + @cur_ea_curr_code                                                       + @v_single_quote)         -- char(03)
                        , (', @emp_user_text_1               = ' + @v_single_quote + @cur_ea_user_text_1                                                     + @v_single_quote)         -- char(50)
                        , (', @emp_user_text_2               = ' + @v_single_quote + @position_title                                                         + @v_single_quote)         -- char(50)
                        , (', @emp_asgmt_org_chart_id        = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(64)      -- Was @v_ORGANIZATION_CHART_NAME
                        , (', @emp_asgmt_org_unit_id         = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(240)
                        , (', @emp_asgmt_org_change_reason   = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(05)
                        , (', @emp_asgmt_loc_code            = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(10)
                        , (', @emp_asgmt_mgr_emp_id          = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(15)
                        , (', @emp_organization_group_id     = ' +                   CONVERT(varchar, @v_ORGANIZATION_GROUP_ID, 0)                                            )         -- float
                        , (', @emp_regulatory_rtg_unit_code  = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(10)
                        , (', @emp_unemployment_loc_code     = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(10)
                        , (', @emp_shift_diff_rate_tbl_id    = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(10)
                        , (', @emp_asgmt_work_shift_code     = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(05)
                        , (', @emp_shift_diff_status_code    = ' + @v_single_quote + @v_SHIFT_DIFFERENTIAL_STATUS_CODE                                       + @v_single_quote)         -- char(02)
                        , (', @emp_ref_annual_salary_amt     = 0'                                                                                                             )         -- money
                        , (', @emp_ref_pd_salary_amt         = 0'                                                                                                             )         -- money
                        , (', @emp_ref_pd_salary_tm_pd_id    = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(5)
                        , (', @emp_ref_hourly_pay_rate       = 0'                                                                                                             )         -- float
                        , (', @emp_guar_annual_salary_amt    = 0'                                                                                                             )         -- money
                        , (', @emp_guar_pd_salary_amt        = 0'                                                                                                             )         -- money
                        , (', @emp_guar_pd_salary_tm_pd_id   = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(5)
                        , (', @emp_guar_hourly_pay_rate      = 0'                                                                                                             )         -- float
                        , (', @w_emp_ver_code                = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(01)     -- NOT USED IN PROCEDURE
                        , (', @w_emp_ver_count               = 0'                                                                                                             )         -- smallint     -- NOT USED IN PROCEDURE
                        , (', @pos_allowed_fte               = 0'                                                                                                             )         -- float        -- NOT USED IN PROCEDURE
                        , (', @pos_allowed_incumbents        = 0'                                                                                                             )         -- int          -- NOT USED IN PROCEDURE
                        , (', @pos_standard_work_hrs         = 0'                                                                                                             )         -- float        -- NOT USED IN PROCEDURE
                        , (', @pos_policy_id                 = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(08)     -- NOT USED IN PROCEDURE
                        , (', @pol_incumb_val_err_lvl        = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(01)     -- NOT USED IN PROCEDURE
                        , (', @pol_fte_val_err_lvl_cd        = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(01)     -- NOT USED IN PROCEDURE
                        , (', @tm_pd_annlzg_factor           = 0'                                                                                                             )         -- float        -- NOT USED IN PROCEDURE
                        , (', @emp_asgmt_next_asgd_to_code   = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(01)
                        , (', @emp_asgmt_next_job_or_pos_id  = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(10)
                        , (', @emp_asgmt_prior_asgd_to_code  = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(01)
                        , (', @emp_asgmt_prior_job_or_pos_id = ' + @v_single_quote + @v_EMPTY_SPACE                                                          + @v_single_quote)         -- char(10)
                        , (', @w_asg_life_end_date           = ' + @v_single_quote + CONVERT(varchar, @v_END_OF_TIME_DATE, 112)                              + @v_single_quote)         -- datetime     -- NOT USED IN PROCEDURE
                        , (', @emp_chgstamp                  = ' +                   CONVERT(varchar, @cur_ea_chgstamp, 0)                                                    )         -- smallint
                        , (' ');
                        */


                        SET @v_step_position = 'Emp Assignment - Update Assignment'

                        -- Update existing Emp Assignment Job/Position - Will create new eff date record
                        EXEC DBShrpn.dbo.usp_hsp_upd_hasg
                              @use_eff_date                  = @eff_date                                      -- datetime
                            , @use_end_date                  = @v_END_OF_TIME_DATE                              -- datetime         -- NOT USED IN PROCEDURE
                            , @employee_identifier           = @emp_id                                          -- char(15)
                            , @emp_asgmt_assigned_to_code    = @v_ASSIGNED_TO_CODE                              -- char(01)
                            , @emp_asgmt_job_or_pos_id       = @job_or_pos_id                                   -- char(10)
                            , @emp_asgmt_eff_date            = @eff_date                                        -- datetime
                            , @emp_asgmt_next_eff_date       = @v_END_OF_TIME_DATE                              -- datetime
                            , @emp_asgmt_prior_eff_dt        = @cur_ea_eff_date                                 -- datetime         -- NOT USED IN PROCEDURE
                            , @emp_asgmt_begin_date          = @cur_ea_begin_date                               -- datetime         ** since assignment didn't change then get original begin date
                            , @emp_asgmt_end_date            = @v_END_OF_TIME_DATE                              -- datetime
                            , @emp_display_name              = @v_EMPTY_SPACE                                   -- char(45)         -- NOT USED IN PROCEDURE
                            , @emp_status_code               = @cur_stat_emp_status_code                        -- char(01)         -- NOT USED IN PROCEDURE
                            , @emp_status_change_date        = @cur_stat_status_change_date                     -- datetime         -- NOT USED IN PROCEDURE
                            , @w_job_or_pos_title            = @v_EMPTY_SPACE                                   -- char(10)         -- NOT USED IN PROCEDURE
                            , @tm_pd_id                      = @v_EMPTY_SPACE                                   -- char(05)
                            , @tm_pd_hrs                     = 0                                                -- float            -- NOT USED IN PROCEDURE
                            , @emp_asgmt_reason_code         = @v_EMPTY_SPACE                                   -- char(05)
                            , @emp_prime_assignment_ind      = 'Y'                                              -- char(01)
                            , @emp_occupancy_code            = '3'                                              -- char(01)
                            , @emp_asgmt_official_title_code = @v_EMPTY_SPACE                                   -- char(05)
                            , @emp_asgmt_official_title_date = @v_END_OF_TIME_DATE                              -- datetime
                            , @emp_autopay_ind               = 'N'                                              -- char(1)
                            , @emp_asgmt_annual_salary       = @w_annual_salary_amt                             -- money
                            , @emp_asgmt_salary_curr_cd      = @w_curr_code                                     -- char(03)
                            , @emp_asgmt_pd_salary           = @w_pd_salary_amt                                 -- money
                            , @emp_pay_on_rptd_hrs_ind       = @w_pay_on_reported_hrs_ind                       -- char(01)
                            , @emp_asgmt_hourly_pay_rate     = @w_hourly_pay_rate                               -- float
                            , @emp_asgmt_salary_change_type  = 'M'  --M or P???                                 -- char(05)
                            , @emp_asgmt_standard_work_hrs   = @w_standard_work_hrs                             -- float
                            , @emp_asgmt_standard_work_pd_id = @w_standard_work_pd_id                           -- char(05)
                            , @emp_asgmt_work_tm_code        = @w_work_tm_code                                  -- char(01)
                            , @emp_pay_basis_code            = @w_pay_basis_code                                -- char(01)
                            , @emp_asgmt_salary_change_date  = @eff_date                                        -- datetime
                            , @emp_asgmt_pd_salary_tm_pd     = @w_pd_salary_tm_pd_id                            -- char(05)
                            , @emp_base_rate_tbl_id          = @v_EMPTY_SPACE                                   -- char(10)
                            , @emp_base_rate_tbl_entry_code  = @v_EMPTY_SPACE                                   -- char(08)
                            , @emp_exception_rate_ind        = @v_EMPTY_SPACE                                   -- char(01)
                            , @emp_overtime_status_code      = @w_overtime_status_code                          -- char(02)
                            , @emp_standard_daily_work_hrs   = @w_standard_daily_work_hrs                       -- float
                            , @pd_salary_pd_annlzg_factor    = 0.00                                             -- float            -- NOT USED IN PROCEDURE
                            , @pd_salary_pd_hrs              = 0.00                                             -- float            -- NOT USED IN PROCEDURE
                            , @emp_asgmt_salary_structure_id = @v_EMPTY_SPACE                                   -- char(10)
                            , @emp_asgmt_increase_guidel_id  = @v_EMPTY_SPACE                                   -- char(10)
                            , @emp_asgmt_pay_grade           = @v_EMPTY_SPACE                                   -- char(06)
                            , @emp_asgmt_pay_grade_date      = @v_END_OF_TIME_DATE                              -- datetime
                            , @emp_asgmt_job_eval_points     = 0                                                -- smallint
                            , @emp_asgmt_salary_step         = 0                                                -- smallint
                            , @emp_asgmt_salary_step_date    = @v_END_OF_TIME_DATE                              -- datetime
                            , @emp_asgmt_phn1_type_code      = 'WORK'                                           -- char(05)
                            , @emp_asgmt_phn1_fmt_code       = 'L34'                                            -- char(06)
                            , @emp_asgmt_phn1_fmt_delimeter  = '-'                                              -- char(01)
                            , @emp_asgmt_phn2_type_code      = @v_EMPTY_SPACE                                   -- char(05)
                            , @emp_asgmt_phn2_fmt_code       = 'L34'                                            -- char(06)
                            , @emp_asgmt_phn2_fmt_delimeter  = '-'                                              -- char(01)
                            , @emp_asgmt_phn1_intl_code      = @v_EMPTY_SPACE                                   -- char(04)
                            , @emp_asgmt_phn1_country_code   = @v_EMPTY_SPACE                                   -- char(04)
                            , @emp_asgmt_phn1_area_city_code = @v_EMPTY_SPACE                                   -- char(05)
                            , @emp_asgmt_phn1_nbr            = @v_EMPTY_SPACE                                   -- char(12)
                            , @emp_asgmt_phn1_ext_nbr        = @v_EMPTY_SPACE                                   -- char(05)
                            , @emp_asgmt_phn2_intl_code      = @v_EMPTY_SPACE                                   -- char(04)
                            , @emp_asgmt_phn2_country_code   = @v_EMPTY_SPACE                                   -- char(04)
                            , @emp_asgmt_phn2_area_city_code = @v_EMPTY_SPACE                                   -- char(05)
                            , @emp_asgmt_phn2_nbr            = @v_EMPTY_SPACE                                   -- char(12)
                            , @emp_asgmt_phn2_ext_nbr        = @v_EMPTY_SPACE                                   -- char(05)
                            , @emp_asgmt_user_amt_1          = @cur_ea_user_amt_1                               -- float
                            , @emp_asgmt_user_amt_2          = @cur_ea_user_amt_2                               -- float
                            , @emp_asgmt_user_code_1         = @cur_ea_user_code_1                              -- char(05)
                            , @emp_asgmt_user_code_2         = @cur_ea_user_code_2                              -- char(05)
                            , @emp_asgmt_user_date_1         = @cur_ea_user_date_1                              -- datetime
                            , @emp_asgmt_user_date_2         = @cur_ea_user_date_2                              -- datetime
                            , @emp_asgmt_user_ind_1          = @cur_ea_user_ind_1                               -- char(01)
                            , @emp_asgmt_user_ind_2          = @cur_ea_user_ind_2                               -- char(01)
                            , @emp_user_monetary_amt_1       = @cur_ea_user_monetary_amt_1                      -- money
                            , @emp_user_monetary_amt_2       = @cur_ea_user_monetary_amt_2                      -- money
                            , @emp_user_monetary_curr_code   = @cur_ea_user_monetary_curr_code                  -- char(03)
                            , @emp_user_text_1               = @cur_ea_user_text_1                              -- char(50)
                            ---------------------------------------------------------------------------
                            , @emp_user_text_2               = @position_title                                  -- char(50)
                            ---------------------------------------------------------------------------
                            , @emp_asgmt_org_chart_id        = @v_EMPTY_SPACE                                   -- char(64)         -- Was @v_ORGANIZATION_CHART_NAME error on screen when populated without organization_unit_name
                            , @emp_asgmt_org_unit_id         = @v_EMPTY_SPACE                                   -- char(240)
                            , @emp_asgmt_org_change_reason   = @v_EMPTY_SPACE                                   -- char(05)
                            , @emp_asgmt_loc_code            = @v_EMPTY_SPACE                                   -- char(10)
                            , @emp_asgmt_mgr_emp_id          = @v_EMPTY_SPACE                                   -- char(15)
                            , @emp_organization_group_id     = @v_ORGANIZATION_GROUP_ID                         -- float
                            , @emp_regulatory_rtg_unit_code  = @v_EMPTY_SPACE                                   -- char(10)
                            , @emp_unemployment_loc_code     = @v_EMPTY_SPACE                                   -- char(10)
                            , @emp_shift_diff_rate_tbl_id    = @v_EMPTY_SPACE                                   -- char(10)
                            , @emp_asgmt_work_shift_code     = @v_EMPTY_SPACE                                   -- char(05)
                            , @emp_shift_diff_status_code    = @v_SHIFT_DIFFERENTIAL_STATUS_CODE                -- char(02)
                            , @emp_ref_annual_salary_amt     = 0                                                -- money
                            , @emp_ref_pd_salary_amt         = 0                                                -- money
                            , @emp_ref_pd_salary_tm_pd_id    = @v_EMPTY_SPACE                                   -- char(5)
                            , @emp_ref_hourly_pay_rate       = 0                                                -- float
                            , @emp_guar_annual_salary_amt    = 0                                                -- money
                            , @emp_guar_pd_salary_amt        = 0                                                -- money
                            , @emp_guar_pd_salary_tm_pd_id   = @v_EMPTY_SPACE                                   -- char(5)
                            , @emp_guar_hourly_pay_rate      = 0                                                -- float
                            , @w_emp_ver_code                = @v_EMPTY_SPACE                                   -- char(01)         -- NOT USED IN PROCEDURE
                            , @w_emp_ver_count               = 0                                                -- smallint         -- NOT USED IN PROCEDURE
                            , @pos_allowed_fte               = 0                                                -- float            -- NOT USED IN PROCEDURE
                            , @pos_allowed_incumbents        = 0                                                -- int              -- NOT USED IN PROCEDURE
                            , @pos_standard_work_hrs         = 0                                                -- float            -- NOT USED IN PROCEDURE
                            , @pos_policy_id                 = @v_EMPTY_SPACE                                   -- char(08)         -- NOT USED IN PROCEDURE
                            , @pol_incumb_val_err_lvl        = @v_EMPTY_SPACE                                   -- char(01)         -- NOT USED IN PROCEDURE
                            , @pol_fte_val_err_lvl_cd        = @v_EMPTY_SPACE                                   -- char(01)         -- NOT USED IN PROCEDURE
                            , @tm_pd_annlzg_factor           = 24                                               -- float            -- NOT USED IN PROCEDURE
                            , @emp_asgmt_next_asgd_to_code   = @v_EMPTY_SPACE                                   -- char(01)
                            , @emp_asgmt_next_job_or_pos_id  = @v_EMPTY_SPACE                                   -- char(10)
                            , @emp_asgmt_prior_asgd_to_code  = @v_EMPTY_SPACE                                   -- char(01)
                            , @emp_asgmt_prior_job_or_pos_id = @v_EMPTY_SPACE                                   -- char(10)
                            , @w_asg_life_end_date           = @v_END_OF_TIME_DATE                              -- datetime         -- NOT USED IN PROCEDURE
                            , @emp_chgstamp                  = @cur_ea_chgstamp                                 -- smallint


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
                    , @p_event_id           = @v_EVENT_ID_SALARY_CHANGE
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
            -- committ records before next record in order to maintain log entries
            IF (@@TRANCOUNT > 0)
                COMMIT TRAN


            FETCH crsrHR
            INTO  @aud_id
                , @emp_id
                , @eff_date
                , @position_title
                , @pay_rate
                , @file_source
                , @annual_hrs_per_fte
                , @annual_rate
                , @job_or_pos_id


        END -- end of while loop

        -- Cleanup Cursor
        CLOSE crsrHR
        DEALLOCATE crsrHR


        -- commit after every record
        IF (@@TRANCOUNT > 0)
            COMMIT TRAN


        ---------------------------------------------------------------------------
        -- Send notification of warning message U00115  -- < POSITION TITLE SECTION (10) >
        ---------------------------------------------------------------------------
        SET @msg_id = 'U00014'
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
        -- Send notification of warning message U00015 - Total nbr of changes
        ---------------------------------------------------------------------------
        SET @msg_id = 'U00015'
        SET @v_step_position = 'Log ' + @msg_id

        SELECT @msg_id        = msg_id
            , @w_msg_text    = msg_text
            , @w_msg_text_2  = msg_text_2
            , @w_msg_text_3  = msg_text_3
            , @w_severity_cd = severity_cd
        FROM DBSCOMMON.dbo.message_master
        WHERE (msg_id = @msg_id)

        -- Get total name records from HCM
        SELECT @maxx = CAST(COUNT(*) AS varchar(6))
        FROM #ghr_employee_events_temp
        WHERE (event_id = @v_EVENT_ID_SALARY_CHANGE)

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
            , @p_event_id           = @v_EVENT_ID_SALARY_CHANGE
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

    RETURN @v_ret_val

END
GO

ALTER AUTHORIZATION ON dbo.usp_ins_salary_change TO  SCHEMA OWNER
GO

IF OBJECT_ID(N'dbo.usp_ins_salary_change', N'P') IS NOT NULL
    PRINT N'<<< CREATED PROCEDURE dbo.usp_ins_salary_change >>>'
ELSE
    PRINT N'<<< FAILED CREATING PROCEDURE dbo.usp_ins_salary_change >>>'
GO