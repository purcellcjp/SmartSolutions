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

    DECLARE @v_ACTIVITY_STATUS_GOOD         char(2)             = '00'
    DECLARE @v_ACTIVITY_STATUS_BAD          char(2)             = '02'

    DECLARE @w_activity_date	            datetime
    DECLARE @w_status			            int
    DECLARE @w_userid			            varchar(30)



    CREATE TABLE #ghr_employee_events_temp
    (
      ID                                    int	IDENTITY(1,1)   NOT NULL
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
    , position_title                        char(50)            NULL
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
    , tax_flag                              char(1)             NULL    -- individual_personal.ind_2
    , nic_flag                              char(1)             NULL    -- individual_personal.ind_1
    , tax_ceiling_amt                       char(15)            NULL    -- employee.user_monetary_amt_1
    , labor_grp_code                        char(50)            NULL    -- emp_assignment.user_text_1
    , file_source                           char(50)            NULL    -- 'SS VENUS' or 'SS GANYMEDE'
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
        SET @v_step_position = 'Copy Imported Data Temp'

        INSERT INTO #ghr_employee_events_temp
        SELECT event_id
            , emp_id
            , eff_date
            , first_name
            , first_middle_name
            , last_name
            , UPPER(empl_id)
            , 'NIS' -- national_id_type_code
            , national_id
            , organization_group_id
            , ''    -- organization_chart_name
            , ''    -- organization_unit_name
            , emp_status_classn_code
            , position_title
            , UPPER(employment_type_code)
            , annual_salary_amt
            , begin_date
            , end_date
            , pay_status_code
            , UPPER(pay_group_id)
            , pay_element_ctrl_grp_id
            , time_reporting_meth_code
            , employment_info_chg_reason_cd
            , emp_location_code
            , emp_status_code
            , reason_code
            , emp_expected_return_date
            , pay_through_date
            , emp_death_date
            , consider_for_rehire_ind
            , UPPER(pay_element_id)
            , emp_calculation
            , tax_flag
            , nic_flag
            , tax_ceiling_amt
            , labor_grp_code
            , file_source
        FROM DBShrpn.dbo.ghr_employee_events
        ORDER BY event_id
               , emp_id


        SET @v_step_position = 'Copy Imported Data to Audit'

        INSERT INTO DBShrpn.dbo.ghr_employee_events_aud
        SELECT event_id
            , emp_id
            , eff_date
            , first_name
            , first_middle_name
            , last_name
            , empl_id
            , national_id_type_code
            , national_id
            , organization_group_id
            , organization_chart_name
            , organization_unit_name
            , emp_status_classn_code
            , position_title
            , employment_type_code
            , annual_salary_amt
            , begin_date
            , end_date
            , pay_status_code
            , pay_group_id
            , pay_element_ctrl_grp_id
            , time_reporting_meth_code
            , employment_info_chg_reason_cd
            , emp_location_code
            , emp_status_code
            , reason_code
            , emp_expected_return_date
            , pay_through_date
            , emp_death_date
            , consider_for_rehire_ind
            , pay_element_id
            , emp_calculation
            , tax_flag
            , nic_flag
            , tax_ceiling_amt
            , labor_grp_code
            , file_source
            , @w_activity_date          AS activity_date
            , @w_userid                 AS activity_user
            , @v_ACTIVITY_STATUS_GOOD   AS activity_status
        FROM DBShrpn.dbo.ghr_employee_events ee
        WHERE NOT EXISTS (
                        SELECT 1
                        FROM DBShrpn.dbo.ghr_employee_events_aud t
                        WHERE t.event_id = ee.event_id
                            AND t.emp_id = ee.emp_id
                            AND t.activity_date	= @w_activity_date
                        )


        ---------------------------------------------------------------------------
        -- New Hires
        ---------------------------------------------------------------------------
        SET @v_step_position = 'Execute New Hires'
        SET @v_event_id = @v_EVENT_ID_NEW_HIRE

        IF  EXISTS (
                    SELECT event_id
                    FROM DBShrpn.dbo.ghr_employee_events
                    WHERE event_id = @v_EVENT_ID_NEW_HIRE
                   )
        BEGIN

			EXEC DBShrpn.dbo.usp_ins_new_hire
                  @p_userid          = @w_userid
                , @p_batchname       = @v_PSC_BATCHNAME
                , @p_qualifier       = @w_PSC_QUALIFIER
                , @p_activity_date   = @w_activity_date
                , @p_user_id         = @w_userid
                , @p_status          = @w_status
        END

/*
        -- GOSL: Salaries are not interfaced into SS. Will be managed manually by user
        ---------------------------------------------------------------------------
        -- Salary Change
        ---------------------------------------------------------------------------
        SET @v_step_position = 'Execute Salary Change'
        SET @v_event_id = @v_EVENT_ID_SALARY_CHANGE

        IF  EXISTS (
                    SELECT event_id
                    FROM DBShrpn.dbo.ghr_employee_events
                    WHERE (event_id = @v_EVENT_ID_SALARY_CHANGE)
                   )
        BEGIN
            EXEC	DBShrpn.dbo.usp_ins_salary_change @w_userid,
                    @v_PSC_BATCHNAME,
                    @w_PSC_QUALIFIER,
                    @w_activity_date,
                    @w_userid,
                    @w_activity_status,
                    @w_status
        END
*/

        ---------------------------------------------------------------------------
        -- Employee Transfer
        ---------------------------------------------------------------------------
        SET @v_step_position = 'Execute Transfer'
        SET @v_event_id = @v_EVENT_ID_TRANSFER

        IF EXISTS (
                   SELECT event_id
                   FROM DBShrpn.dbo.ghr_employee_events
                   WHERE event_id = @v_EVENT_ID_TRANSFER
                  )
        BEGIN
            EXEC DBShrpn.dbo.usp_perform_transfer
                        @p_userid          = @w_userid
                      , @p_batchname       = @v_PSC_BATCHNAME
                      , @p_qualifier       = @w_PSC_QUALIFIER
                      , @p_activity_date   = @w_activity_date
                      , @p_user_id         = @w_userid
                      , @p_status          = @w_status
        END


        ---------------------------------------------------------------------------
        -- Name Change
        ---------------------------------------------------------------------------
        SET @v_step_position = 'Execute Name Change'
        SET @v_event_id = @v_EVENT_ID_NAME_CHANGE


        IF EXISTS (
                   SELECT event_id
                   FROM DBShrpn.dbo.ghr_employee_events
                   WHERE event_id = @v_EVENT_ID_NAME_CHANGE
                  )
        BEGIN
            EXEC DBShrpn.dbo.usp_ins_name_change
                        @p_userid          = @w_userid
                      , @p_batchname       = @v_PSC_BATCHNAME
                      , @p_qualifier       = @w_PSC_QUALIFIER
                      , @p_activity_date   = @w_activity_date
                      , @p_user_id         = @w_userid
                      , @p_status          = @w_status
        END


        ---------------------------------------------------------------------------
        -- Status Change
        ---------------------------------------------------------------------------
        SET @v_step_position = 'Execute Status Change'
        SET @v_event_id = @v_EVENT_ID_STATUS_CHANGE

        IF  EXISTS (
                    SELECT event_id
                    FROM DBShrpn.dbo.ghr_employee_events
                    WHERE event_id = @v_EVENT_ID_STATUS_CHANGE
                   )
        BEGIN
            EXEC DBShrpn.dbo.usp_ins_status_change
                        @p_userid          = @w_userid
                      , @p_batchname       = @v_PSC_BATCHNAME
                      , @p_qualifier       = @w_PSC_QUALIFIER
                      , @p_activity_date   = @w_activity_date
                      , @p_user_id         = @w_userid
                      , @p_status          = @w_status
        END


        ---------------------------------------------------------------------------
        -- Pay Element
        ---------------------------------------------------------------------------
        SET @v_step_position = 'Execute Pay Allowances'
        SET @v_event_id = @v_EVENT_ID_PAY_ELE

        IF  EXISTS (
                    SELECT event_id
                    FROM DBShrpn.dbo.ghr_employee_events
                    WHERE event_id = @v_EVENT_ID_PAY_ELE
                   )
        BEGIN
            EXEC DBShrpn.dbo.usp_ins_pay_element
                        @p_userid          = @w_userid
                      , @p_batchname       = @v_PSC_BATCHNAME
                      , @p_qualifier       = @w_PSC_QUALIFIER
                      , @p_activity_date   = @w_activity_date
                      , @p_user_id         = @w_userid
                      , @p_status          = @w_status
        END


    END TRY
    BEGIN CATCH

      SELECT @ErrorNumber   = CAST(ERROR_NUMBER() AS varchar(10))
           , @ErrorMessage  = ERROR_MESSAGE()
           , @ErrorSeverity = ERROR_SEVERITY()
           , @ErrorState    = ERROR_STATE()
           , @v_ret_val     = -1

        /*
        SELECT @ErrorMessage  AS err_msg
            , @ErrorSeverity AS err_sev
            , @ErrorState    AS err_state
        */

        -- Log system error
        INSERT INTO DBShrpn.dbo.ghr_historical_message
        VALUES
        (
          @ErrorNumber      -- msg_id
        , @v_event_id       -- event_id
        , ''                -- emp_id
        , ''                -- eff_date
        , ''                -- pay_element_desc
        , @v_step_position  -- msg_p1
        , ''                -- msg_p2
        , @ErrorMessage     -- msg_desc
        , @w_activity_date  -- activity_date
        )

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
