USE DBShrpn;
GO

SET ANSI_NULLS OFF;
GO
SET QUOTED_IDENTIFIER OFF;
GO

IF OBJECT_ID(N'dbo.usp_sel_employee_events', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_sel_employee_events
    IF OBJECT_ID(N'dbo.usp_sel_employee_events') IS NOT NULL
        PRINT N'<<< FAILED DROPPING PROCEDURE dbo.usp_sel_employee_events >>>'
    ELSE
        PRINT N'<<< DROPPED PROCEDURE dbo.usp_sel_employee_events >>>'
END
GO

/*************************************************************************************
    SP Name:       usp_sel_employee_events

    Description:   Parent procedure that executes the following procedures
                   organized by event code in the interface file.

    Event                       ID      Stored Procedure
    -----------------------     --      ---------------------
    Update New Hires            01      dbo.usp_ins_new_hires
    Employee Salary Changes     02      NOT APPLICABLE FOR GOSL
    Employee Transfers          03      dbo.usp_perform_transfer
    Employee Name Change        04      dbo.usp_ins_name_change
    Employee Status Change      05      dbo.usp_ins_status_change
    Employee Pay Allowances     06      dbo.usp_ins_pay_element
    Employee Pay Group          08      dbo.usp_ins_pay_group
    Employee Labor Group        09      dbo.usp_ins_labor_group
    Employee Position Title     10      dbo.usp_ins_position_title

    Interface records are imported into table DBShrpn..ghr_employee_events. This procedure
    will copy teh records to temp table #ghr_employee_events_temp that all the child procedures
    interact with.

    The records are then copied to the audit table DBShrpn.dbo.ghr_employee_events_aud. This table
    is used to track the extracts whether or not the record was processed.

    Salary change transactions (Event ID '02') will be excluded from the interface. The transactions are sill included in theSalaries in HCM
    cloud suite are not compatible with salary setup in SmartStream.


    Parameters:
        None


    Example:
        exec dbo.usp_sel_employee_events


   Revision history:
   version  date        developer   SCR         description
   -------  ----------  ---------   -----       ------------------------------------
   1.0.00   08/27/2025  CJP                     - Cloned from GOG version

************************************************************************************/

CREATE PROCEDURE dbo.usp_sel_employee_events

AS

BEGIN

    SET NOCOUNT ON

    DECLARE @v_step_position                varchar(255)        = 'Begin Procedure'

    DECLARE @ErrorNumber                    varchar(10)
    DECLARE @ErrorMessage                   nvarchar(4000)
    DECLARE @ErrorSeverity                  int
    DECLARE @ErrorState                     int
    DECLARE @v_ret_val                      int                 = 0
    DECLARE @v_msg                          varchar(255)        = ''

    DECLARE @v_event_id                     char(2)

    DECLARE @v_PSC_BATCHNAME                char(08)            = 'GHR'
    DECLARE @w_PSC_QUALIFIER                char(30)            = 'INTERFACES'
    DECLARE @w_PSC_PSC_PGM_PARMS            varchar(255)        = 'GHR_EMPLOYEE_EVENTS'

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
    DECLARE @v_ACTIVITY_STATUS_BAD          char(2)             = '02'
    --DECLARE @v_ACTIVITY_STATUS_UNPROCESSED  char(2)             = '99'

    DECLARE @w_activity_date	            datetime
    DECLARE @w_status			            int
    DECLARE @w_userid			            varchar(30)



    CREATE TABLE #ghr_employee_events_temp
    (
      aud_id                                int	IDENTITY(1,1)   NOT NULL
    , event_id                              char(02)            NULL
    , emp_id                                char(15)            NULL
    , eff_date                              char(10)            NULL
    , first_name                            char(25)            NULL
    , first_middle_name                     char(25)            NULL
    , last_name                             char(30)            NULL
    , empl_id                               char(10)            NULL
    , national_id_type_code                 char(05)            NULL
    , national_id                           char(20)            NULL
    , organization_group_id                 char(05)            NULL
    , organization_chart_name               varchar(64)         NULL
    , organization_unit_name                varchar(240)        NULL
    , emp_status_classn_code                char(02)            NULL
    , position_title                        char(50)            NULL    -- DBShrpn..emp_assignment.user_text_2
    , employment_type_code                  varchar(70)         NULL    -- increased size to 70 from 5
    , annual_salary_amt                     char(15)            NULL
    , begin_date                            char(10)            NULL
    , end_date                              char(10)            NULL
    , pay_status_code                       char(01)            NULL
    , pay_group_id                          char(10)            NULL
    , pay_element_ctrl_grp_id               char(10)            NULL
    , time_reporting_meth_code              char(01)            NULL
    , employment_info_chg_reason_cd         char(05)            NULL
    , emp_location_code                     char(10)            NULL
    , emp_status_code                       char(02)            NULL
    , reason_code                           char(02)            NULL
    , emp_expected_return_date              char(10)            NULL
    , pay_through_date                      char(10)            NULL
    , emp_death_date                        char(10)            NULL
    , consider_for_rehire_ind               char(01)            NULL
    , pay_element_id                        char(10)            NULL
    , emp_calculation                       char(15)            NULL
    , tax_flag                              char(1)             NULL    -- individual_personal.user_ind_2
    , nic_flag                              char(1)             NULL    -- individual_personal.user_ind_1
    , tax_ceiling_amt                       char(15)            NULL    -- employee.user_monetary_amt_1
    , labor_grp_code                        char(50)            NULL    -- DBShrpn..emp_employment.labor_grp_code   char(5)
    , file_source                           char(50)            NULL    -- 'SS VENUS' or 'SS GANYMEDE'

    , job_or_pos_id                        char(10)             NULL    -- derived value based on file_source
    )


    BEGIN TRY

        SET @v_step_position = 'Set Variables'

        SET @w_userid = SYSTEM_USER

        -- Find the Batch name and qualifier for the job running the Bulk Copy
        SELECT @w_activity_date = psc_last_comp_date
        FROM DBSpscb.dbo.psc_step
        WHERE psc_userid = @w_userid
            AND (psc_batchname = @v_PSC_BATCHNAME)
            AND (psc_qualifier = @w_PSC_QUALIFIER)
            AND (psc_pgm_parms = @w_PSC_PSC_PGM_PARMS)     -- bulkcopy step


        --SET @w_activity_status	= '00'
        -- Use date on bulkcopy step    SET @w_activity_date = CAST(CONVERT(CHAR(20),GETDATE(),120) as DATETIME)


        -- Get input filename
        -- WHY IS THIS NEEDED???
        -- SELECT @w_inputfile	= batch_parameter_3
        -- FROM DBSentp.dbo.batch_parameters
        -- WHERE (batch_parameter_key = 'GHR_EMPLOYEE_EVENTS')


        ---------------------------------------------------------------------------
        -- Load imported data to temp table
        ---------------------------------------------------------------------------
        -- This allows a central location to transform data
        SET @v_step_position = 'Insert INTO #ghr_employee_events_temp'

        INSERT INTO #ghr_employee_events_temp
        SELECT t.event_id
            , t.emp_id
            , t.eff_date
            , t.first_name
            , t.first_middle_name
            , t.last_name
            , UPPER(t.empl_id)
            , t.national_id_type_code
            , t.national_id
            , t.organization_group_id
            , ''    -- organization_chart_name
            , ''    -- organization_unit_name
            , t.emp_status_classn_code
            , LEFT(t.position_title, 50) AS position_title    -- trim value since HCM sends it over as char(60)
            , UPPER(t.employment_type_code)
            , t.annual_salary_amt
            , t.begin_date
            , t.end_date
            , t.pay_status_code
            , UPPER(t.pay_group_id)
            , t.pay_element_ctrl_grp_id
            , t.time_reporting_meth_code
            , t.employment_info_chg_reason_cd
            , t.emp_location_code
            , t.emp_status_code
            , t.reason_code
            , t.emp_expected_return_date
            , t.pay_through_date
            , t.emp_death_date
            , t.consider_for_rehire_ind
            , UPPER(t.pay_element_id)
            , t.emp_calculation
            , CASE t.tax_flag WHEN '1' THEN 'Y' WHEN '0' THEN 'N' ELSE tax_flag END tax_flag
            , CASE t.nic_flag WHEN '1' THEN 'Y' WHEN '0' THEN 'N' ELSE nic_flag END nic_flag
            , t.tax_ceiling_amt
            , t.labor_grp_code
            , t.file_source
            , DBShrpn.dbo.ufn_ret_job_or_pos_id(t.file_source, t.empl_id) AS job_or_pos_id
        FROM DBShrpn.dbo.ghr_employee_events t
        WHERE (t.event_id <> @v_EVENT_ID_SALARY_CHANGE)  -- Exclude Salary Changes


        SET @v_step_position = 'INSERT INTO DBShrpn.dbo.ghr_employee_events_aud'

        INSERT INTO DBShrpn.dbo.ghr_employee_events_aud
        SELECT ee.event_id
            , ee.emp_id
            , ee.eff_date
            , ee.first_name
            , ee.first_middle_name
            , ee.last_name
            , ee.empl_id
            , ee.national_id_type_code
            , ee.national_id
            , ee.organization_group_id
            , ee.organization_chart_name
            , ee.organization_unit_name
            , ee.emp_status_classn_code
            , LEFT(ee.position_title, 50) AS position_title    -- trim value since HCM sends it over as char(60)
            , ee.employment_type_code
            , ee.annual_salary_amt
            , ee.begin_date
            , ee.end_date
            , ee.pay_status_code
            , ee.pay_group_id
            , ee.pay_element_ctrl_grp_id
            , ee.time_reporting_meth_code
            , ee.employment_info_chg_reason_cd
            , ee.emp_location_code
            , ee.emp_status_code
            , ee.reason_code
            , ee.emp_expected_return_date
            , ee.pay_through_date
            , ee.emp_death_date
            , ee.consider_for_rehire_ind
            , ee.pay_element_id
            , ee.emp_calculation
            , ee.tax_flag
            , ee.nic_flag
            , ee.tax_ceiling_amt
            , ee.labor_grp_code
            , ee.file_source
            , DBShrpn.dbo.ufn_ret_job_or_pos_id(ee.file_source, ee.empl_id) AS job_or_pos_id
            , @w_activity_date                                              AS activity_date
            , ee.aud_id
            , @w_userid                                                     AS activity_user
            , 'N'                                                           AS proc_flag
        FROM #ghr_employee_events_temp ee


        ---------------------------------------------------------------------------
        -- New Hires (Event 01)
        ---------------------------------------------------------------------------
        SELECT @v_step_position = 'Execute DBShrpn.dbo.usp_ins_new_hire'
        SET @v_event_id = @v_EVENT_ID_NEW_HIRE
        SET @w_status = 0   -- reset return code

        IF  EXISTS (
                    SELECT event_id
                    FROM #ghr_employee_events_temp
                    WHERE (event_id = @v_EVENT_ID_NEW_HIRE)
                   )
        BEGIN

            EXEC @w_status = DBShrpn.dbo.usp_ins_new_hire
                  @p_user_id         = @w_userid
                , @p_batchname       = @v_PSC_BATCHNAME
                , @p_qualifier       = @w_PSC_QUALIFIER
                , @p_activity_date   = @w_activity_date

            -- Log error if return code is not zero
            IF (@w_status <> 0)
            BEGIN
                SET @v_msg = 'Stored procedure DBShrpn.dbo.usp_ins_new_hire returned code: ' + CONVERT(varchar(10), @w_status)

                -- Historical Message for reporting purpose
                EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                      @p_msg_id             = '0'
                    , @p_event_id           = @v_event_id
                    , @p_emp_id             = ''
                    , @p_eff_date           = ''
                    , @p_pay_element_id     = ''
                    , @p_msg_p1             = ''
                    , @p_msg_p2             = ''
                    , @p_msg_desc           = @v_msg
                    , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                    , @p_activity_date      = @w_activity_date
            END

        END

/*
        -- GOSL: Salaries are not interfaced into SS. Will be managed manually by user
        ---------------------------------------------------------------------------
        -- Salary Change (Event 02)
        ---------------------------------------------------------------------------
        SET @v_step_position = 'Execute DBShrpn.dbo.usp_ins_salary_change'
        SET @v_event_id = @v_EVENT_ID_SALARY_CHANGE

        IF  EXISTS (
                    SELECT event_id
                    FROM #ghr_employee_events_temp
                    WHERE (event_id = @v_EVENT_ID_SALARY_CHANGE)
                   )
        BEGIN
            EXEC	DBShrpn.dbo.usp_ins_salary_change
                    @w_userid,
                    @v_PSC_BATCHNAME,
                    @w_PSC_QUALIFIER,
                    @w_activity_date,
                    @w_userid,
                    @w_activity_status,
                    @w_status
        END
*/


        ---------------------------------------------------------------------------
        -- Employee Transfer (Event 03)
        ---------------------------------------------------------------------------
        SET @v_step_position = 'Execute DBShrpn.dbo.usp_perform_transfer'
        SET @v_event_id = @v_EVENT_ID_TRANSFER
        SET @w_status = 0   -- reset return code

        IF EXISTS (
                   SELECT event_id
                   FROM #ghr_employee_events_temp
                   WHERE (event_id = @v_EVENT_ID_TRANSFER)
                  )
        BEGIN
            EXEC @w_status = DBShrpn.dbo.usp_perform_transfer
                        @p_user_id         = @w_userid
                      , @p_batchname       = @v_PSC_BATCHNAME
                      , @p_qualifier       = @w_PSC_QUALIFIER
                      , @p_activity_date   = @w_activity_date

            -- Log error if return code is not zero
            IF (@w_status <> 0)
            BEGIN
                SET @v_msg = 'Stored procedure DBShrpn.dbo.usp_perform_transfer returned code: ' + CONVERT(varchar(10), @w_status)

                -- Historical Message for reporting purpose
                EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                      @p_msg_id             = '0'
                    , @p_event_id           = @v_event_id
                    , @p_emp_id             = ''
                    , @p_eff_date           = ''
                    , @p_pay_element_id     = ''
                    , @p_msg_p1             = ''
                    , @p_msg_p2             = ''
                    , @p_msg_desc           = @v_msg
                    , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                    , @p_activity_date      = @w_activity_date
            END

        END


        ---------------------------------------------------------------------------
        -- Name Change  (Event 04)
        ---------------------------------------------------------------------------
        SET @v_step_position = 'Execute DBShrpn.dbo.usp_ins_name_change'
        SET @v_event_id = @v_EVENT_ID_NAME_CHANGE
        SET @w_status = 0   -- reset return code

        IF EXISTS (
                   SELECT event_id
                   FROM #ghr_employee_events_temp
                   WHERE (event_id = @v_EVENT_ID_NAME_CHANGE)
                  )
        BEGIN
            EXEC @w_status = DBShrpn.dbo.usp_ins_name_change
                              @p_user_id         = @w_userid
                            , @p_batchname       = @v_PSC_BATCHNAME
                            , @p_qualifier       = @w_PSC_QUALIFIER
                            , @p_activity_date   = @w_activity_date

            -- Log error if return code is not zero
            IF (@w_status <> 0)
            BEGIN
                SET @v_msg = 'Stored procedure DBShrpn.dbo.usp_ins_name_change returned code: ' + CONVERT(varchar(10), @w_status)

                -- Historical Message for reporting purpose
                EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                      @p_msg_id             = '0'
                    , @p_event_id           = @v_event_id
                    , @p_emp_id             = ''
                    , @p_eff_date           = ''
                    , @p_pay_element_id     = ''
                    , @p_msg_p1             = ''
                    , @p_msg_p2             = ''
                    , @p_msg_desc           = @v_msg
                    , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                    , @p_activity_date      = @w_activity_date
            END

        END


        ---------------------------------------------------------------------------
        -- Status Change (Event 05)
        ---------------------------------------------------------------------------
        SET @v_step_position = 'Execute DBShrpn.dbo.usp_ins_status_change'
        SET @v_event_id = @v_EVENT_ID_STATUS_CHANGE
        SET @w_status = 0   -- reset return code

        IF  EXISTS (
                    SELECT event_id
                    FROM #ghr_employee_events_temp
                    WHERE (event_id = @v_EVENT_ID_STATUS_CHANGE)
                   )
        BEGIN

            EXEC @w_status = DBShrpn.dbo.usp_ins_status_change
                        @p_user_id         = @w_userid
                      , @p_batchname       = @v_PSC_BATCHNAME
                      , @p_qualifier       = @w_PSC_QUALIFIER
                      , @p_activity_date   = @w_activity_date

            -- Log error if return code is not zero
            IF (@w_status <> 0)
            BEGIN
                SET @v_msg = 'Stored procedure DBShrpn.dbo.usp_ins_status_change returned code: ' + CONVERT(varchar(10), @w_status)

                -- Historical Message for reporting purpose
                EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                      @p_msg_id             = '0'
                    , @p_event_id           = @v_event_id
                    , @p_emp_id             = ''
                    , @p_eff_date           = ''
                    , @p_pay_element_id     = ''
                    , @p_msg_p1             = ''
                    , @p_msg_p2             = ''
                    , @p_msg_desc           = @v_msg
                    , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                    , @p_activity_date      = @w_activity_date
            END

        END


        ---------------------------------------------------------------------------
        -- Pay Element (Event 06)
        ---------------------------------------------------------------------------
        SET @v_step_position = 'Execute DBShrpn.dbo.usp_ins_pay_element'
        SET @v_event_id = @v_EVENT_ID_PAY_ELE
        SET @w_status = 0   -- reset return code

        IF  EXISTS (
                    SELECT event_id
                    FROM #ghr_employee_events_temp
                    WHERE (event_id = @v_EVENT_ID_PAY_ELE)
                   )
        BEGIN
            EXEC @w_status = DBShrpn.dbo.usp_ins_pay_element
                        @p_user_id         = @w_userid
                      , @p_batchname       = @v_PSC_BATCHNAME
                      , @p_qualifier       = @w_PSC_QUALIFIER
                      , @p_activity_date   = @w_activity_date

            -- Log error if return code is not zero
            IF (@w_status <> 0)
            BEGIN
                SET @v_msg = 'Stored procedure DBShrpn.dbo.usp_ins_pay_element returned code: ' + CONVERT(varchar(10), @w_status)

                -- Historical Message for reporting purpose
                EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                      @p_msg_id             = '0'
                    , @p_event_id           = @v_event_id
                    , @p_emp_id             = ''
                    , @p_eff_date           = ''
                    , @p_pay_element_id     = ''
                    , @p_msg_p1             = ''
                    , @p_msg_p2             = ''
                    , @p_msg_desc           = @v_msg
                    , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                    , @p_activity_date      = @w_activity_date
            END


        END


        ---------------------------------------------------------------------------
        -- Pay Group (Event 08)
        ---------------------------------------------------------------------------
        SET @v_step_position = 'Execute DBShrpn.dbo.usp_ins_pay_group'
        SET @v_event_id = @v_EVENT_ID_PAY_GROUP
        SET @w_status = 0   -- reset return code

        IF  EXISTS (
                    SELECT event_id
                    FROM #ghr_employee_events_temp
                    WHERE (event_id = @v_EVENT_ID_PAY_GROUP)
                   )
        BEGIN
            EXEC @w_status = DBShrpn.dbo.usp_ins_pay_group
                        @p_user_id         = @w_userid
                      , @p_batchname       = @v_PSC_BATCHNAME
                      , @p_qualifier       = @w_PSC_QUALIFIER
                      , @p_activity_date   = @w_activity_date

            -- Log error if return code is not zero
            IF (@w_status <> 0)
            BEGIN
                SET @v_msg = 'Stored procedure DBShrpn.dbo.usp_ins_pay_group returned code: ' + CONVERT(varchar(10), @w_status)

                -- Historical Message for reporting purpose
                EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                      @p_msg_id             = '0'
                    , @p_event_id           = @v_event_id
                    , @p_emp_id             = ''
                    , @p_eff_date           = ''
                    , @p_pay_element_id     = ''
                    , @p_msg_p1             = ''
                    , @p_msg_p2             = ''
                    , @p_msg_desc           = @v_msg
                    , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                    , @p_activity_date      = @w_activity_date
            END


        END


        ---------------------------------------------------------------------------
        -- Labor Group Update (Event 09)
        ---------------------------------------------------------------------------
        SET @v_step_position = 'Execute DBShrpn.dbo.usp_ins_labor_group'
        SET @v_event_id = @v_EVENT_ID_LABOR_GROUP
        SET @w_status = 0   -- reset return code

        IF  EXISTS (
                    SELECT event_id
                    FROM #ghr_employee_events_temp
                    WHERE (event_id = @v_EVENT_ID_LABOR_GROUP)
                   )
        BEGIN
            EXEC @w_status = DBShrpn.dbo.usp_ins_labor_group
                        @p_user_id         = @w_userid
                      , @p_batchname       = @v_PSC_BATCHNAME
                      , @p_qualifier       = @w_PSC_QUALIFIER
                      , @p_activity_date   = @w_activity_date

            -- Log error if return code is not zero
            IF (@w_status <> 0)
            BEGIN
                SET @v_msg = 'Stored procedure DBShrpn.dbo.usp_ins_labor_group returned code: ' + CONVERT(varchar(10), @w_status)

                -- Historical Message for reporting purpose
                EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                      @p_msg_id             = '0'
                    , @p_event_id           = @v_event_id
                    , @p_emp_id             = ''
                    , @p_eff_date           = ''
                    , @p_pay_element_id     = ''
                    , @p_msg_p1             = ''
                    , @p_msg_p2             = ''
                    , @p_msg_desc           = @v_msg
                    , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                    , @p_activity_date      = @w_activity_date
            END


        END


        ---------------------------------------------------------------------------
        -- Position Title (Event 10)
        ---------------------------------------------------------------------------
        SET @v_step_position = 'Execute DBShrpn.dbo.usp_ins_position_title'
        SET @v_event_id = @v_EVENT_ID_POSITION_TITLE
        SET @w_status = 0   -- reset return code

        IF  EXISTS (
                    SELECT event_id
                    FROM #ghr_employee_events_temp
                    WHERE (event_id = @v_EVENT_ID_POSITION_TITLE)
                   )
        BEGIN
            EXEC @w_status = DBShrpn.dbo.usp_ins_position_title
                        @p_user_id         = @w_userid
                      , @p_batchname       = @v_PSC_BATCHNAME
                      , @p_qualifier       = @w_PSC_QUALIFIER
                      , @p_activity_date   = @w_activity_date

            -- Log error if return code is not zero
            IF (@w_status <> 0)
            BEGIN
                SET @v_msg = 'Stored procedure DBShrpn.dbo.usp_ins_position_title returned code: ' + CONVERT(varchar(10), @w_status)

                -- Historical Message for reporting purpose
                EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                      @p_msg_id             = '0'
                    , @p_event_id           = @v_event_id
                    , @p_emp_id             = ''
                    , @p_eff_date           = ''
                    , @p_pay_element_id     = ''
                    , @p_msg_p1             = ''
                    , @p_msg_p2             = ''
                    , @p_msg_desc           = @v_msg
                    , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                    , @p_activity_date      = @w_activity_date

            END

        END


    END TRY
    BEGIN CATCH

      SELECT @ErrorNumber   = CAST(ERROR_NUMBER() AS varchar(10))
           , @ErrorMessage  = @v_step_position + ' - ' + ERROR_MESSAGE()
           , @ErrorSeverity = ERROR_SEVERITY()
           , @ErrorState    = ERROR_STATE()
           , @v_ret_val     = -1

        /*
        SELECT @ErrorMessage  AS err_msg
            , @ErrorSeverity AS err_sev
            , @ErrorState    AS err_state
        */

        -- Log error to message queue
        EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2
              @userid   = @w_userid
            , @batch    = @v_PSC_BATCHNAME
            , @qual     = @w_PSC_QUALIFIER
            , @msgno    = @ErrorNumber
            , @severity = 0
            , @text     = @ErrorMessage
            , @text_2   = ''
            , @text_3   = ''


        -- Log system error
		SET @v_event_id = ISNULL(@v_event_id, '')

        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
              @p_msg_id             = @ErrorNumber
            , @p_event_id           = @v_event_id
            , @p_emp_id             = ''
            , @p_eff_date           = ''
            , @p_pay_element_id     = ''
            , @p_msg_p1             = @v_step_position
            , @p_msg_p2             = ''
            , @p_msg_desc           = @ErrorMessage
            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
            , @p_activity_date      = @w_activity_date


    END CATCH

    -- Clear import table
    TRUNCATE TABLE DBShrpn.dbo.ghr_employee_events;

    -- Clean up temp table
    DROP TABLE #ghr_employee_events_temp

    RETURN @v_ret_val

END
GO


ALTER AUTHORIZATION ON dbo.usp_sel_employee_events TO  SCHEMA OWNER
GO

IF OBJECT_ID(N'dbo.usp_sel_employee_events', N'P') IS NOT NULL
    PRINT N'<<< CREATED PROCEDURE dbo.usp_sel_employee_events >>>'
ELSE
    PRINT N'<<< FAILED CREATING PROCEDURE dbo.usp_sel_employee_events >>>'
GO
