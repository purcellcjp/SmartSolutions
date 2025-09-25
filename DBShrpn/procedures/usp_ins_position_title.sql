USE DBShrpn
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'dbo.usp_ins_position_title', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_ins_position_title
    IF OBJECT_ID(N'dbo.usp_ins_position_title') IS NOT NULL
        PRINT N'<<< FAILED DROPPING PROCEDURE dbo.usp_ins_position_title >>>'
    ELSE
        PRINT N'<<< DROPPED PROCEDURE dbo.usp_ins_position_title >>>'
END
GO

CREATE PROCEDURE dbo.usp_ins_position_title
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

    DECLARE @maxx                           char(06)
    DECLARE @msg_id                         char(10)
    DECLARE @cur_ea_assigned_to_code        char(01)
    DECLARE @cur_ea_job_or_pos_id           char(10)
    DECLARE @cur_ea_eff_date                datetime
    DECLARE @cur_ea_user_text_2             char(50)
    DECLARE @cur_stat_emp_status_code       char(01)

    DECLARE @w_eff_date                     datetime


    -- This section declares the interface values from Global HR
    DECLARE @emp_id                         char(15)
    DECLARE @eff_date                       char(10)
    DECLARE @empl_id                        char(10)
    DECLARE @file_source                    char(50)        -- 'SS VENUS' or 'SS GANYMEDE'
    DECLARE @position_title				    char(50)        -- DBShrpn..emp_assignment.user_text_2

    CREATE TABLE #tbl_ghr_msg
        (
          msg_id                            char(15)            NOT NULL
        , msg_desc                          varchar(255)        NOT NULL
        )


    CREATE TABLE #tbl_msg_master
        (
          msg_id                            char(15)            NOT NULL
        , severity_cd                       tinyint             NOT NULL
        , msg_text                          varchar(255)        NOT NULL
        , msg_text_2                        varchar(255)        NOT NULL
        , msg_text_3                        varchar(255)        NOT NULL
        , loop_flag                         char(1)             NOT NULL
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
                         'U00009'
                        ,'U00010'
                        ,'U00011'
                        ,'U00012'
                        ,'U00027'
                        ,'U00102'
                        ,'U00115'
                        ,'U00116'
                        ,'U00117'
                        ,'U00118'
                        ,'U00119'
                        ,'U00120'
                        ))

        -- ID Message templates that need to loop through errors to add to log table
        UPDATE #tbl_msg_master
        SET loop_flag = 'Y'
        WHERE (msg_id IN (
                          'U00012'
                         ,'U00027'
                         ,'U00102'
                         ,'U00117'
                         ,'U00118'
                         ,'U00119'
                         ,'U00120'
                        ))


        SET @v_step_position = 'Declaring cursor crsrHR'

        -- Loop through ghr_employee_events_temp to populate error message log entry
        DECLARE crsrHR CURSOR FAST_FORWARD FOR
        SELECT t.emp_id
             , t.eff_date
             , t.empl_id
             , t.position_title
             , t.file_source
        FROM #ghr_employee_events_temp t
        WHERE (event_id = @v_EVENT_ID_POSITION_TITLE)

        SET @v_step_position = 'Opening cursor crsrHR'
        OPEN crsrHR

        SET @v_step_position = 'Fetching cursor crsrHR'
        FETCH crsrHR
        INTO  @emp_id
            , @eff_date
            , @empl_id
            , @position_title
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


                ---------------------------------------------------------------------------
                -- Skip record if position title is blank
                ---------------------------------------------------------------------------
                IF (LEN(RTRIM(@position_title)) = 0)
                BEGIN

                    SET @msg_id = 'U00118'
                    SET @v_step_position = 'Position title is blank'

                    UPDATE DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status   = @v_ACTIVITY_STATUS_BAD
                    WHERE activity_date   = @p_activity_date
                    AND emp_id =   @emp_id
                    AND event_id = @v_EVENT_ID_POSITION_TITLE

                    -- Historical Message for reporting purpose
                    EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                        @p_msg_id             = @msg_id
                        , @p_event_id           = @v_EVENT_ID_POSITION_TITLE
                        , @p_emp_id             = @emp_id
                        , @p_eff_date           = @eff_date
                        , @p_pay_element_id     = ''
                        , @p_msg_p1             = ''
                        , @p_msg_p2             = ''
                        , @p_msg_desc           = 'Position title is blank - bypassing record'
                        , @p_activity_date      = @p_activity_date

                    -- Skip record and all other validations
                    GOTO BYPASS_EMPLOYEE

                END

                ---------------------------------------------------------------------------
                --Skip Record if associate also has New Hire, Transfer, Status Change
                ---------------------------------------------------------------------------
                IF EXISTS (
                    SELECT 1
                    FROM #ghr_employee_events_temp
                    WHERE (emp_id = @emp_id)
                    AND (event_id IN (
                                        @v_EVENT_ID_NEW_HIRE
                                    , @v_EVENT_ID_TRANSFER
                                    , @v_EVENT_ID_STATUS_CHANGE
                                    ))
                )
                BEGIN

                    SET @msg_id = 'U00119'  -- New code
                    SET @v_step_position = RTRIM(@msg_id) + 'Employee extract contains new hire, transfer, or status change event records'

                    UPDATE DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status   = @v_ACTIVITY_STATUS_WARNING
                    WHERE activity_date   = @p_activity_date
                    AND emp_id =   @emp_id
                    AND event_id = @v_EVENT_ID_POSITION_TITLE

                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id      AS msg_id
                        , REPLACE(REPLACE(t.msg_text, '@1', 'position title'), '@2', @emp_id) AS msg_desc
                    FROM #tbl_msg_master t
                    WHERE (msg_id = @msg_id)

                    -- Historical Message for reporting purpose
                    EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                        , @p_event_id           = @v_EVENT_ID_POSITION_TITLE
                        , @p_emp_id             = @emp_id
                        , @p_eff_date           = @eff_date
                        , @p_pay_element_id     = ''
                        , @p_msg_p1             = ''
                        , @p_msg_p2             = ''
                        , @p_msg_desc           = 'Bypassing position title record since employee has either a new hire, transfer, or status change event in this extract.'
                        , @p_activity_date      = @p_activity_date

                    -- Skip record and all other validations
                    -- since labor group will be processed in the other events
                    GOTO BYPASS_EMPLOYEE

                END


                ---------------------------------------------------------------------------
                -- Validate Effective Date
                ---------------------------------------------------------------------------
                -- Invalid date value from HCM, ''@1'', for employee, @2, and event id, @3.

                -- Effective Date
                IF (TRY_CONVERT(datetime, @eff_date) IS NULL)
                    BEGIN

                        SET @msg_id = 'U00102'  -- New code
                        SET @v_step_position = 'Validation Effective Date - ' + RTRIM(@msg_id)

                        UPDATE DBShrpn.dbo.ghr_employee_events_aud
                        SET activity_status   = @v_ACTIVITY_STATUS_BAD
                        WHERE activity_date = @p_activity_date
                        AND event_id = @v_EVENT_ID_POSITION_TITLE
                        AND emp_id = @emp_id

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id      AS msg_id
                            , REPLACE(REPLACE(REPLACE(t.msg_text, '@1', @eff_date), '@2', @emp_id), '@3', @v_EVENT_ID_POSITION_TITLE) AS msg_desc
                        FROM #tbl_msg_master t
                        WHERE (msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_POSITION_TITLE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = ''
                            , @p_msg_p1             = ''
                            , @p_msg_p2             = ''
                            , @p_msg_desc           = 'Invalid Effective Date'
                            , @p_activity_date      = @p_activity_date


                        SET @w_fatal_error = 1

                    END
                ELSE
                    -- Convert amount to money data type
                    SELECT @w_eff_date = CONVERT(datetime, @eff_date)




                ---------------------------------------------------------------------------
                -- Check to see if the employee exists
                ---------------------------------------------------------------------------
                SET @msg_id = 'U00012'
                SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

                SELECT @cur_ea_assigned_to_code     = ea.assigned_to_code
                    , @cur_ea_job_or_pos_id        = ea.job_or_pos_id
                    , @cur_ea_eff_date             = ea.eff_date
                    , @cur_ea_user_text_2          = ea.user_text_2
                    , @cur_stat_emp_status_code     = stat.emp_status_code
                FROM DBShrpn.dbo.employee emp
                JOIN DBShrpn.dbo.uvu_emp_assignment_most_rec ea ON
                    (emp.emp_id = ea.emp_id)
                JOIN DBShrpn.dbo.emp_status_most_rec stat ON
                    (emp.emp_id = stat.emp_id)
                WHERE (emp.emp_id = @emp_id)

                IF (@@ROWCOUNT = 0)
                    BEGIN

                        UPDATE DBShrpn.dbo.ghr_employee_events_aud
                            SET activity_status = @v_ACTIVITY_STATUS_BAD
                        WHERE activity_date = @p_activity_date
                            AND emp_id = @emp_id
                            AND event_id = @v_EVENT_ID_POSITION_TITLE


                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id As msg_id
                            , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                        FROM #tbl_msg_master t
                        WHERE (msg_id = @msg_id)


                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_POSITION_TITLE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = ''
                            , @p_msg_p1             = ''
                            , @p_msg_p2             = ''
                            , @p_msg_desc           = 'Employee does not exist'
                            , @p_activity_date      = @p_activity_date

                        SET @w_fatal_error = 1

                    END


                ---------------------------------------------------------------------------
                -- Is Associate Terminated in SmartStream
                ---------------------------------------------------------------------------
                SET @msg_id = 'U00120'
                SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

                IF (@cur_stat_emp_status_code = 'T')
                    BEGIN

                        UPDATE DBShrpn.dbo.ghr_employee_events_aud
                            SET activity_status = @v_ACTIVITY_STATUS_BAD
                        WHERE activity_date = @p_activity_date
                            AND emp_id = @emp_id
                            AND event_id = @v_EVENT_ID_POSITION_TITLE


                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id      As msg_id
                            , REPLACE(REPLACE(t.msg_text, '@1', 'position title'), '@2', @emp_id) AS msg_desc
                        FROM #tbl_msg_master t
                        WHERE (msg_id = @msg_id)


                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_POSITION_TITLE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = ''
                            , @p_msg_p1             = @position_title
                            , @p_msg_p2             = ''
                            , @p_msg_desc           = 'Employee is terminated in SmartStream - bypassing record.'
                            , @p_activity_date      = @p_activity_date


                        SET @w_fatal_error = 1

                    END


                ---------------------------------------------------------------------------
                -- Is new position title same as old position title?
                ---------------------------------------------------------------------------
                SET @msg_id = 'U00117'
                SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

                IF (@position_title = @cur_ea_user_text_2)
                    BEGIN

                        UPDATE DBShrpn.dbo.ghr_employee_events_aud
                            SET activity_status = @v_ACTIVITY_STATUS_BAD
                        WHERE activity_date = @p_activity_date
                            AND emp_id = @emp_id
                            AND event_id = @v_EVENT_ID_POSITION_TITLE


                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id      As msg_id
                            , REPLACE(REPLACE(t.msg_text, '@1', @position_title), '@2', @emp_id) AS msg_desc
                        FROM #tbl_msg_master t
                        WHERE (msg_id = @msg_id)


                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_POSITION_TITLE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = ''
                            , @p_msg_p1             = @position_title
                            , @p_msg_p2             = @cur_ea_user_text_2
                            , @p_msg_desc           = 'New position title is same as current position title - bypassing record.'
                            , @p_activity_date      = @p_activity_date


                        SET @w_fatal_error = 1

                    END


                ---------------------------------------------------------------------------
                -- Effective date must be greater than current effective date
                ---------------------------------------------------------------------------
                SET @msg_id = 'U00027'
                SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

                IF (@w_fatal_error = 0) AND
                (@w_eff_date <= @cur_ea_eff_date)
                    BEGIN

                        -- Convert date to string for log table
                        SET @w_msg_text_2 = CONVERT(char(8), @cur_ea_eff_date, 112)

                        UPDATE DBShrpn.dbo.ghr_employee_events_aud
                        SET activity_status = @v_ACTIVITY_STATUS_BAD
                        WHERE activity_date = @p_activity_date
                        AND emp_id = @emp_id
                        AND event_id = @v_EVENT_ID_POSITION_TITLE

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id As msg_id
                            , REPLACE(REPLACE(t.msg_text, '@1', @w_eff_date), '@2', @emp_id) AS msg_desc
                        FROM #tbl_msg_master t
                        WHERE (msg_id = @msg_id)


                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_POSITION_TITLE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = ''
                            , @p_msg_p1             = @w_msg_text_2
                            , @p_msg_p2             = ''
                            , @p_msg_desc           = 'New effective date must be greater than current employee employment effective date.'
                            , @p_activity_date      = @p_activity_date


                        SET  @w_fatal_error = 1

                    END


                IF (@w_fatal_error = 1)
                    GOTO BYPASS_EMPLOYEE



                ---------------------------------------------------------------------------
                -- Update Employee Assignment with new position title
                ---------------------------------------------------------------------------

                -- Update date pointer on old record
                UPDATE DBShrpn.dbo.emp_assignment
                SET next_eff_date = @w_eff_date
                WHERE emp_id = @emp_id
                AND (assigned_to_code = @cur_ea_assigned_to_code)
                AND (job_or_pos_id    = @cur_ea_job_or_pos_id)
                AND (eff_date         = @cur_ea_eff_date)


                -- insert new record
                INSERT DBShrpn.dbo.emp_assignment
                SELECT emp_id                                                    -- emp_id                                 char(15)
                            , assigned_to_code                                          -- assigned_to_code                       char(1)
                            , job_or_pos_id                                             -- job_or_pos_id                          char(10)
                            , @w_eff_date                                               -- eff_date                               datetime
                            , @v_END_OF_TIME_DATE                                       -- next_eff_date                          datetime
                            , @cur_ea_eff_date                                          -- prior_eff_date                         datetime
                            , next_assigned_to_code                                     -- next_assigned_to_code                  char(1)
                            , next_job_or_pos_id                                        -- next_job_or_pos_id                     char(10)
                            , prior_assigned_to_code                                    -- prior_assigned_to_code                 char(1)
                            , prior_job_or_pos_id                                       -- prior_job_or_pos_id                    char(10)
                            , begin_date                                                -- begin_date                             datetime
                            , end_date                                                  -- end_date                               datetime
                            , assignment_reason_code                                    -- assignment_reason_code                 char(5)
                            , organization_chart_name                                   -- organization_chart_name                varchar(
                            , organization_unit_name                                    -- organization_unit_name                 varchar(
                            , organization_group_id                                     -- organization_group_id                  int
                            , organization_change_reason_cd                             -- organization_change_reason_cd          char(5)
                            , loc_code                                                  -- loc_code                               char(10)
                            , mgr_emp_id                                                -- mgr_emp_id                             char(15)
                            , official_title_code                                       -- official_title_code                    char(5)
                            , official_title_date                                       -- official_title_date                    datetime
                            , salary_change_date                                        -- salary_change_date                     datetime
                            , annual_salary_amt                                         -- annual_salary_amt                      money
                            , pd_salary_amt                                             -- pd_salary_amt                          money
                            , pd_salary_tm_pd_id                                        -- pd_salary_tm_pd_id                     char(5)
                            , hourly_pay_rate                                           -- hourly_pay_rate                        float
                            , curr_code                                                 -- curr_code                              char(3)
                            , pay_on_reported_hrs_ind                                   -- pay_on_reported_hrs_ind                char(1)
                            , ''                                                        -- salary_change_type_code                char(5)
                            , standard_work_pd_id                                       -- standard_work_pd_id                    char(5)
                            , standard_work_hrs                                         -- standard_work_hrs                      float
                            , work_tm_code                                           -- work_tm_code                           char(1)
                            , work_shift_code                                           -- work_shift_code                        char(5)
                            , salary_structure_id                                       -- salary_structure_id                    char(10)
                            , salary_increase_guideline_id                              -- salary_increase_guideline_id           char(10)
                            , pay_grade_code                                            -- pay_grade_code                         char(6)
                            , pay_grade_date                                            -- pay_grade_date                         datetime
                            , job_evaluation_points_nbr                                 -- job_evaluation_points_nbr              smallint
                            , salary_step_nbr                                           -- salary_step_nbr                        smallint
                            , salary_step_date                                          -- salary_step_date                       datetime
                            , phone_1_type_code                                         -- phone_1_type_code                      char(5)
                            , phone_1_fmt_code                                          -- phone_1_fmt_code                       char(6)
                            , phone_1_fmt_delimiter                                     -- phone_1_fmt_delimiter                  char(1)
                            , phone_1_intl_code                                         -- phone_1_intl_code                      char(4)
                            , phone_1_country_code                                      -- phone_1_country_code                   char(4)
                            , phone_1_area_city_code                                    -- phone_1_area_city_code                 char(5)
                            , phone_1_nbr                                               -- phone_1_nbr                            char(12)
                            , phone_1_extension_nbr                                     -- phone_1_extension_nbr                  char(5)
                            , phone_2_type_code                                         -- phone_2_type_code                      char(5)
                            , phone_2_fmt_code                                          -- phone_2_fmt_code                       char(6)
                            , phone_2_fmt_delimiter                                     -- phone_2_fmt_delimiter                  char(1)
                            , phone_2_intl_code                                         -- phone_2_intl_code                      char(4)
                            , phone_2_country_code                                      -- phone_2_country_code                   char(4)
                            , phone_2_area_city_code                                    -- phone_2_area_city_code                 char(5)
                            , phone_2_nbr                                               -- phone_2_nbr                            char(12)
                            , phone_2_extension_nbr                                     -- phone_2_extension_nbr                  char(5)
                            , prime_assignment_ind                                      -- prime_assignment_ind                   char(1)
                            , pay_basis_code                                            -- pay_basis_code                         char(1)
                            , occupancy_code                                            -- occupancy_code                         char(1)
                            , regulatory_reporting_unit_code                            -- regulatory_reporting_unit_code         char(10)
                            , base_rate_tbl_id                                       -- base_rate_tbl_id                       char(10)
                            , base_rate_tbl_entry_code                               -- base_rate_tbl_entry_code               char(8)
                            , shift_differential_rate_tbl_id                            -- shift_differential_rate_tbl_id         char(10)
                            , ref_annual_salary_amt                                     -- ref_annual_salary_amt                  money
                            , ref_pd_salary_amt                                         -- ref_pd_salary_amt                      money
                            , ref_pd_salary_tm_pd_id                                    -- ref_pd_salary_tm_pd_id                 char(5)
                            , ref_hourly_pay_rate                                       -- ref_hourly_pay_rate                    float
                            , guaranteed_annual_salary_amt                              -- guaranteed_annual_salary_amt           money
                            , guaranteed_pd_salary_amt                                  -- guaranteed_pd_salary_amt               money
                            , guaranteed_pd_salary_tm_pd_id                             -- guaranteed_pd_salary_tm_pd_id          char(5)
                            , guaranteed_hourly_pay_rate                                -- guaranteed_hourly_pay_rate             float
                            , exception_rate_ind                                        -- exception_rate_ind                     char(1)
                            , overtime_status_code                                      -- overtime_status_code                   char(2)
                            , shift_differential_status_code                            -- shift_differential_status_code         char(2)
                            , standard_daily_work_hrs                                   -- standard_daily_work_hrs                money
                            , user_amt_1                                                -- user_amt_1                             float
                            , user_amt_2                                                -- user_amt_2                             float
                            , user_code_1                                               -- user_code_1                            char(5)
                            , user_code_2                                               -- user_code_2                            char(5)
                            , user_date_1                                               -- user_date_1                            datetime
                            , user_date_2                                               -- user_date_2                            datetime
                            , user_ind_1                                                -- user_ind_1                             char(1)
                            , user_ind_2                                                -- user_ind_2                             char(1)
                            , user_monetary_amt_1                                       -- user_monetary_amt_1                    money
                            , user_monetary_amt_2                                       -- user_monetary_amt_2                    money
                            , user_monetary_curr_code                                   -- user_monetary_curr_code                char(3)
                            , user_text_1                                               -- user_text_1                            char(50)
                            , @position_title                                           -- user_text_2                            char(50)
                            , unemployment_loc_code                                     -- unemployment_loc_code                  char(10)
                            , include_salary_in_autopay_ind                             -- include_salary_in_autopay_ind          char(1)
                            , chgstamp                                                  -- chgstamp                               smallint
                    FROM DBShrpn.dbo.emp_assignment
                    WHERE (emp_id =	@emp_id)
                    AND (assigned_to_code = @cur_ea_assigned_to_code)
                    AND (job_or_pos_id    = @cur_ea_job_or_pos_id)
                    AND (eff_date         = @cur_ea_eff_date)

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
                    , @p_event_id           = @v_EVENT_ID_POSITION_TITLE
                    , @p_emp_id             = @emp_id
                    , @p_eff_date           = @eff_date
                    , @p_pay_element_id     = ''
                    , @p_msg_p1             = ''
                    , @p_msg_p2             = ''
                    , @p_msg_desc           = @ErrorMessage
                    , @p_activity_date      = @p_activity_date


            END CATCH


BYPASS_EMPLOYEE:
            -- committ records before next record in order to maintain log entries
            IF (@@TRANCOUNT > 0)
                COMMIT TRAN


            FETCH crsrHR
            INTO  @emp_id
                , @eff_date
                , @empl_id
                , @position_title
                , @file_source


        END -- end of while loop

        -- Cleanup Cursor
        CLOSE crsrHR
        DEALLOCATE crsrHR



        ---------------------------------------------------------------------------
        -- Send notification of warning message U00115  -- < POSITION TITLE SECTION (10) >
        ---------------------------------------------------------------------------
        SET @msg_id = 'U00115'
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
        -- Send notification of warning message U00116 - Total nbr of changes
        ---------------------------------------------------------------------------
        SET @msg_id = 'U00116'
        SET @v_step_position = 'Log ' + @msg_id

        SELECT @msg_id        = msg_id
            , @w_msg_text    = msg_text
            , @w_msg_text_2  = msg_text_2
            , @w_msg_text_3  = msg_text_3
            , @w_severity_cd = severity_cd
        FROM #tbl_msg_master
        WHERE (msg_id = @msg_id)

        -- Get total name records from HCM
        SELECT @maxx = CAST(COUNT(*) AS varchar(6))
        FROM #ghr_employee_events_temp
        WHERE (event_id =   @v_EVENT_ID_PAY_GROUP)

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

        -- commit after every record
        IF (@@TRANCOUNT > 0)
            COMMIT TRAN


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
            , @p_event_id           = @v_EVENT_ID_POSITION_TITLE
            , @p_emp_id             = @emp_id
            , @p_eff_date           = @eff_date
            , @p_pay_element_id     = ''
            , @p_msg_p1             = ''
            , @p_msg_p2             = ''
            , @p_msg_desc           = @ErrorMessage
            , @p_activity_date      = @p_activity_date

        -- send error back to calling procedure
        RAISERROR(
                   @ErrorMessage
                 , @ErrorSeverity
                 , @ErrorState
                 );

    END CATCH


    -- Cleanup temp tables
    DROP TABLE #tbl_ghr_msg
    DROP TABLE #tbl_msg_master

    RETURN @v_ret_val

END
GO

ALTER AUTHORIZATION ON dbo.usp_ins_position_title TO  SCHEMA OWNER
GO

IF OBJECT_ID(N'dbo.usp_ins_position_title', N'P') IS NOT NULL
    PRINT N'<<< CREATED PROCEDURE dbo.usp_ins_position_title >>>'
ELSE
    PRINT N'<<< FAILED CREATING PROCEDURE dbo.usp_ins_position_title >>>'
GO