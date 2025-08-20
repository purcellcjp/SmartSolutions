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
	@p_userid               varchar(30),
	@p_batchname            varchar(08),
	@p_qualifier            varchar(30),
    @p_activity_date        datetime,
    @p_user_id              varchar(30),
	@p_status						int         = 0 OUTPUT
)
AS


BEGIN

    SET NOCOUNT ON

    DECLARE @v_step_position                varchar(255)        = 'Begin Procedure'
    DECLARE @v_END_OF_TIME_DATE             datetime            = '29991231'

    DECLARE @v_EVENT_ID_SALARY_CHANGE       char(2)             = '02'
    DECLARE @v_EVENT_ID_TRANSFER            char(2)             = '03'
    DECLARE @v_EVENT_ID_NAME_CHANGE         char(2)             = '04'
    DECLARE @v_EVENT_ID_STATUS_CHANGE       char(2)             = '05'
    DECLARE @v_EVENT_ID_PAY_ELE             char(2)             = '06'

    DECLARE @v_ACTIVITY_STATUS_GOOD         char(2)             = '00'
    DECLARE @v_ACTIVITY_STATUS_WARNING      char(2)             = '01'
    DECLARE @v_ACTIVITY_STATUS_BAD          char(2)             = '02'


    DECLARE @ErrorMessage                   nvarchar(4000)
    DECLARE @ErrorSeverity                  int
    DECLARE @ErrorState                     int

    DECLARE @v_ret_val                      int = 0

    DECLARE @w_msg_text						varchar(255)
    DECLARE @w_msg_text_2					varchar(255)
    DECLARE @w_msg_text_3					varchar(255)
    DECLARE @w_severity_cd					tinyint
    DECLARE @w_fatal_error					bit     = 0         --char(01)
    DECLARE @w_trace_sw						char(01)

    DECLARE @special_value_exists			int
    DECLARE @individual_id					char(10)
    DECLARE @prior_last_name				char(30)


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
          , @position_title_01						char(50)
          , @employment_type_code_01				varchar(70)     -- increased size to 70 from 5
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


    CREATE TABLE #tbl_ghr_msg
        (
          msg_id                                    char(15)            NOT NULL
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
             , ''   -- t.organization_chart_name_01
             , ''   -- t.organization_unit_name_01
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
		WHERE (event_id_01 = @v_EVENT_ID_NAME_CHANGE)

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

            SET @w_fatal_error = 0

            ---------------------------------------------------------------------------
            ---------------------------------------------------------------------------
            --	This section will validate the interface data
            ---------------------------------------------------------------------------
            ---------------------------------------------------------------------------
            SET @v_step_position = 'Begin Validation'

            ---------------------------------------------------------------------------
            -- Check to see if the employee exists
            ---------------------------------------------------------------------------
            SET @msg_id = 'U00012'
            SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

            IF  NOT EXISTS (
                            SELECT 1
                            FROM DBShrpn.dbo.employee
                            WHERE emp_id = @emp_id_01
                           )
                BEGIN

                    UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                        SET activity_status	= @v_ACTIVITY_STATUS_BAD
                    WHERE activity_date	= @p_activity_date
                        AND emp_id_01 =	@emp_id_01
                        AND event_id_01 = @v_EVENT_ID_NAME_CHANGE


                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id      As msg_id
                         , REPLACE(t.msg_text, '@1', @emp_id_01) AS msg_desc
                    FROM #tbl_msg_master t
                    WHERE (msg_id = @msg_id)


                    -- Historical Message for reporting purpose
                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                    SELECT  @msg_id					        As msg_id,
                            @v_EVENT_ID_NAME_CHANGE						As event_id,
                            @emp_id_01 						As emp_id,
                            @eff_date_01					As eff_date,
                            @pay_element_desc_06			As pay_element_id,
                            @emp_id_01						As msg_p1,
                            ''						        As msg_p2,
                            'Employee does not exist'		As msg_desc,
                            @p_activity_date				AS activity_date
                    -- End of Historical Message for reporting purpose

                    SET @w_fatal_error = 1

                END

            IF (@w_fatal_error = 1)
                GOTO BYPASS_EMPLOYEE


            ---------------------------------------------------------------------------
            -- Lookup individual_id and Prior Last Name
            ---------------------------------------------------------------------------
            SET @v_step_position = 'Lookup Ind ID Prior Last Name'

            SELECT @individual_id = emp.individual_id
                 , @prior_last_name = ind.last_name
            FROM DBShrpn.dbo.employee emp
            JOIN DBShrpn.dbo.individual ind ON
                 (emp.individual_id = ind.individual_id)
            WHERE (emp_id = @emp_id_01)


            ---------------------------------------------------------------------------
            -- Update name fields
            ---------------------------------------------------------------------------
            SET @v_step_position = 'Update Name Fields'

            UPDATE DBShrpn.dbo.individual
            SET	first_name        = RTRIM(@first_name_01)
              , first_middle_name = RTRIM(@first_middle_name_01)
              , last_name         = RTRIM(@last_name_01)
              , prior_last_name   = RTRIM(@prior_last_name)
              , pay_to_name       = RTRIM(@last_name_01) + ', ' + RTRIM(@first_name_01) + RTRIM(' ' + RTRIM(@first_middle_name_01))
            WHERE (individual_id = @individual_id)


            ---------------------------------------------------------------------------
            -- Update Employee Display Name and Tax Ceiling
            ---------------------------------------------------------------------------
            SET @v_step_position = 'Update Emp Display Name Tax Ceiling'

            UPDATE DBShrpn.dbo.employee
            SET	emp_display_name = RTRIM(@last_name_01) + ', ' + RTRIM(@first_name_01) + RTRIM(' ' + RTRIM(@first_middle_name_01))
              , user_monetary_amt_1 = @tax_ceiling_amt
            WHERE (emp_id = @emp_id_01)


            ---------------------------------------------------------------------------
            -- GOSL update NIC and Tax Code
            ---------------------------------------------------------------------------
            -- CJP 7/7/2025
            SET @v_step_position = 'Update NIC/Tax Code'

            UPDATE	DBShrpn.dbo.individual_personal
            SET	user_ind_1 = @nic_flag
              , user_ind_2 = @tax_flag
            WHERE (individual_id = @individual_id)


            ---------------------------------------------------------------------------
            -- Update Labor Group
            ---------------------------------------------------------------------------
            SET @v_step_position = 'Update Labor Group'

            UPDATE DBShrpn..emp_employment
            SET labor_grp_code = @labor_grp_code
            WHERE (emp_id = @emp_id_01)
              AND (next_eff_date = @v_END_OF_TIME_DATE)


            ---------------------------------------------------------------------------
            -- Update Position Title
            ---------------------------------------------------------------------------
            SET @v_step_position = 'Update Position'

            -- Note: GOSL uses DBShrpn..emp_assignment.user_text_2;
            --       Grenada uses DBShrpn.dbo.individual_personal.user_text_1
            UPDATE	DBShrpn.dbo.emp_assignment
            SET	user_text_2 = @position_title_01
            FROM DBShrpn.dbo.emp_assignment ea
            WHERE (ea.next_eff_date = @v_END_OF_TIME_DATE)
              AND (ea.end_date = (
                                    SELECT MAX(ea2.end_date)
                                    FROM DBShrpn..emp_assignment ea2
                                    WHERE (ea2.emp_id        = ea.emp_id)
                                      AND (ea2.next_eff_date = @v_END_OF_TIME_DATE)
                                 ))


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


        END -- end of while loop

        -- Cleanup Cursor
        CLOSE crsrHR
        DEALLOCATE crsrHR



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
        WHERE (event_id_01 =	@v_EVENT_ID_NAME_CHANGE)

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

        SELECT @ErrorMessage  = @v_step_position + ' - ' + LEFT(ERROR_MESSAGE(), 1024)
             , @ErrorSeverity = ERROR_SEVERITY()
             , @ErrorState    = ERROR_STATE()
             , @p_status      = -1

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