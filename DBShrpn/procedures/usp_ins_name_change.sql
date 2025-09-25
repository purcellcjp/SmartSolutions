USE DBShrpn
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'dbo.usp_ins_name_change', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_ins_name_change
    IF OBJECT_ID(N'dbo.usp_ins_name_change') IS NOT NULL
        PRINT N'<<< FAILED DROPPING PROCEDURE dbo.usp_ins_name_change >>>'
    ELSE
        PRINT N'<<< DROPPED PROCEDURE dbo.usp_ins_name_change >>>'
END
GO

CREATE PROCEDURE dbo.usp_ins_name_change
    (
      @p_userid             varchar(30)
    , @p_batchname          varchar(08)
    , @p_qualifier          varchar(30)
    , @p_activity_date      datetime
    , @p_user_id            varchar(30)
    , @p_status             int             = 0 OUTPUT
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

    DECLARE @individual_id                  char(10)
    DECLARE @prior_last_name                char(30)

    DECLARE @maxx                           CHAR(06)
    DECLARE @msg_id                         CHAR(10)


    -- This section declares the interface values from Global HR

    DECLARE @emp_id                         char(15)
    DECLARE @eff_date                       char(10)
    DECLARE @first_name                     char(25)
    DECLARE @first_middle_name              char(25)
    DECLARE @last_name                      char(30)
    DECLARE @empl_id                        char(10)
    DECLARE @tax_flag                       char(1)         -- individual_personal.ind_2
    DECLARE @nic_flag                       char(1)         -- individual_personal.ind_1
    DECLARE @tax_ceiling_amt                char(15)        -- employee.user_monetary_amt_1
    DECLARE @file_source                    char(50)        -- 'SS VENUS' or 'SS GANYMEDE'


    CREATE TABLE #tbl_ghr_msg
        (
          msg_id                           char(15)         NOT NULL
        , msg_desc                         varchar(255)     NOT NULL
        )


    CREATE TABLE #tbl_msg_master
        (
          msg_id                            char(15)        NOT NULL
        , severity_cd                       tinyint         NOT NULL
        , msg_text                          varchar(255)    NOT NULL
        , msg_text_2                        varchar(255)    NOT NULL
        , msg_text_3                        varchar(255)    NOT NULL
        , loop_flag                         char(1)         NOT NULL
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
        WHERE (msg_id IN ('U00013'
                        ,'U00009'
                        ,'U00010'
                        ,'U00011'
                        ,'U00016'
                        ,'U00012'
                        ))

        -- ID Message templates that need to loop through errors to add to log table
        UPDATE #tbl_msg_master
        SET loop_flag = 'Y'
        WHERE (msg_id IN (
                          'U00012'
                        ))


        SET @v_step_position = 'Declaring cursor crsrHR'

        -- Loop through ghr_employee_events_temp to populate error message log entry
        DECLARE crsrHR CURSOR FAST_FORWARD FOR
        SELECT t.emp_id
             , t.eff_date
             , t.first_name
             , t.first_middle_name
             , t.last_name
             , t.empl_id
             , t.tax_flag
             , t.nic_flag
             , t.tax_ceiling_amt
             , t.file_source
        FROM #ghr_employee_events_temp t
        WHERE (event_id = @v_EVENT_ID_NAME_CHANGE)

        SET @v_step_position = 'Opening cursor crsrHR'
        OPEN crsrHR

        SET @v_step_position = 'Fetching cursor crsrHR'
        FETCH crsrHR
        INTO  @emp_id
            , @eff_date
            , @first_name
            , @first_middle_name
            , @last_name
            , @empl_id
            , @tax_flag
            , @nic_flag
            , @tax_ceiling_amt
            , @file_source


        WHILE (@@FETCH_STATUS = 0)
        BEGIN

            BEGIN TRY

                SET @v_step_position = 'Begin crsrHR While Loop'

                SET @w_fatal_error = 0

                BEGIN TRAN

                ---------------------------------------------------------------------------
                ---------------------------------------------------------------------------
                -- This section will validate the interface data
                ---------------------------------------------------------------------------
                ---------------------------------------------------------------------------
                SET @v_step_position = 'Begin Validation'

                ---------------------------------------------------------------------------
                -- Check to see if the employee exists
                ---------------------------------------------------------------------------
                SET @msg_id = 'U00012'
                SET @v_step_position = 'Begin ' + RTRIM(@msg_id)


                -- Lookup individual_id and Prior Last Name
                SELECT @individual_id = emp.individual_id
                    , @prior_last_name = ind.last_name
                FROM DBShrpn.dbo.employee emp
                JOIN DBShrpn.dbo.individual ind ON
                    (emp.individual_id = ind.individual_id)
                WHERE (emp_id = @emp_id)

                IF (@@ROWCOUNT = 0)
                    BEGIN

                        UPDATE DBShrpn.dbo.ghr_employee_events_aud
                            SET activity_status = @v_ACTIVITY_STATUS_BAD
                        WHERE activity_date = @p_activity_date
                            AND emp_id = @emp_id
                            AND event_id = @v_EVENT_ID_NAME_CHANGE


                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id      As msg_id
                            , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                        FROM #tbl_msg_master t
                        WHERE (msg_id = @msg_id)


                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_NAME_CHANGE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = ''
                            , @p_msg_p1             = ''
                            , @p_msg_p2             = ''
                            , @p_msg_desc           = 'Employee does not exist'
                            , @p_activity_date      = @p_activity_date

                        SET @w_fatal_error = 1

                    END

                IF (@w_fatal_error = 1)
                    GOTO BYPASS_EMPLOYEE


                ---------------------------------------------------------------------------
                -- Update name fields
                ---------------------------------------------------------------------------
                SET @v_step_position = 'Update Name Fields'

                UPDATE DBShrpn.dbo.individual
                SET first_name        = RTRIM(@first_name)
                , first_middle_name = RTRIM(@first_middle_name)
                , last_name         = RTRIM(@last_name)
                , prior_last_name   = RTRIM(@prior_last_name)
                , pay_to_name       = RTRIM(@last_name) + ', ' + RTRIM(@first_name) + RTRIM(' ' + RTRIM(@first_middle_name))
                WHERE (individual_id = @individual_id)


                ---------------------------------------------------------------------------
                -- Update Employee Display Name and Tax Ceiling
                ---------------------------------------------------------------------------
                SET @v_step_position = 'Update Emp Display Name Tax Ceiling'

                UPDATE DBShrpn.dbo.employee
                SET emp_display_name = RTRIM(@last_name) + ', ' + RTRIM(@first_name) + RTRIM(' ' + RTRIM(@first_middle_name))
                , user_monetary_amt_1 = @tax_ceiling_amt
                WHERE (emp_id = @emp_id)


                ---------------------------------------------------------------------------
                -- GOSL update NIC and Tax Code
                ---------------------------------------------------------------------------
                -- CJP 7/7/2025
                SET @v_step_position = 'Update NIC/Tax Code'

                UPDATE DBShrpn.dbo.individual_personal
                SET user_ind_1 = @nic_flag
                , user_ind_2 = @tax_flag
                WHERE (individual_id = @individual_id)

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
                    , @p_event_id           = @v_EVENT_ID_NAME_CHANGE
                    , @p_emp_id             = @emp_id
                    , @p_eff_date           = @eff_date
                    , @p_pay_element_id     = ''
                    , @p_msg_p1             = ''
                    , @p_msg_p2             = ''
                    , @p_msg_desc           = @ErrorMessage
                    , @p_activity_date      = @p_activity_date


            END CATCH


BYPASS_EMPLOYEE:

            FETCH crsrHR
            INTO  @emp_id
                , @eff_date
                , @first_name
                , @first_middle_name
                , @last_name
                , @empl_id
                , @tax_flag
                , @nic_flag
                , @tax_ceiling_amt
                , @file_source


        END -- end of while loop

        -- Cleanup Cursor
        CLOSE crsrHR
        DEALLOCATE crsrHR

        -- commit after every record
        IF (@@TRANCOUNT > 0)
            COMMIT TRAN


        ---------------------------------------------------------------------------
        -- Send notification of warning message U00013  -- < NAME CHANGE SECTION (4) >
        ---------------------------------------------------------------------------
        SET @msg_id = 'U00013'
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
        SET @msg_id = 'U00016'
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
        WHERE (event_id = @v_EVENT_ID_NAME_CHANGE)

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
             , @p_status      = -1

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
            , @p_event_id           = @v_EVENT_ID_NAME_CHANGE
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


END
GO

ALTER AUTHORIZATION ON dbo.usp_ins_name_change TO  SCHEMA OWNER
GO

IF OBJECT_ID(N'dbo.usp_ins_name_change', N'P') IS NOT NULL
    PRINT N'<<< CREATED PROCEDURE dbo.usp_ins_name_change >>>'
ELSE
    PRINT N'<<< FAILED CREATING PROCEDURE dbo.usp_ins_name_change >>>'
GO