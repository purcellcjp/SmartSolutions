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

    DECLARE @ErrorNumber        varchar(10)
    DECLARE @ErrorMessage       nvarchar(4000)
    DECLARE @ErrorSeverity      int
    DECLARE @ErrorState         int
    DECLARE @v_ret_val          int = 0

    DECLARE @v_event_id                     char(2)
    DECLARE @v_EVENT_ID_NEW_HIRE            char(2)             = '01'
    DECLARE @v_EVENT_ID_SALARY_CHANGE       char(2)             = '02'
    DECLARE @v_EVENT_ID_TRANSFER            char(2)             = '03'
    DECLARE @v_EVENT_ID_NAME_CHANGE         char(2)             = '04'
    DECLARE @v_EVENT_ID_STATUS_CHANGE       char(2)             = '05'
    DECLARE @v_EVENT_ID_PAY_ELE             char(2)             = '06'

    DECLARE @v_ACTIVITY_STATUS_GOOD         char(2)             = '00'
    DECLARE @v_ACTIVITY_STATUS_BAD          char(2)             = '02'

    DECLARE @w_activity_date	datetime
          , @w_inputfile		varchar(254)
          , @w_wflow_userid		varchar(30)
          , @w_activity_status	char(02)
          , @w_status			int
          , @w_userid			varchar(30)
          , @w_batchname		varchar(08)
          , @w_qualifier		varchar(30)


    CREATE TABLE #ghr_employee_events_temp
    (
      ID									    int	IDENTITY(1,1)   NOT NULL
    , event_id_01							    char(02)            NULL
    , emp_id_01							        char(15)            NULL
    , eff_date_01							    char(10)            NULL
    , first_name_01						        char(25)            NULL
    , first_middle_name_01				        char(25)            NULL
    , last_name_01						        char(30)            NULL
    , empl_id_01							    char(10)            NULL
    , national_id_1_type_code_01			    char(05)            NULL
    , national_id_1_01					        char(20)            NULL
    , organization_group_id_01			        char(05)            NULL
    , organization_chart_name_01			    varchar(64)         NULL
    , organization_unit_name_01			        varchar(240)        NULL
    , emp_status_classn_code_01			        char(02)            NULL
    , position_title_01					        char(50)            NULL
    , employment_type_code_01				    varchar(70)         NULL    -- increased size to 70 from 5
    , annual_salary_amt_01				        char(15)            NULL
    , begin_date_02						        char(10)            NULL
    , end_date_02							    char(10)            NULL
    , pay_status_code_03					    char(01)            NULL
    , pay_group_id_03						    char(10)            NULL
    , pay_element_ctrl_grp_id_03			    char(10)            NULL
    , time_reporting_meth_code_03			    char(01)            NULL
    , employment_info_chg_reason_cd_03	        char(05)            NULL
    , emp_location_code_03				        char(10)            NULL
    , emp_status_code_5					        char(02)            NULL
    , reason_code_5						        char(02)            NULL
    , emp_expected_return_date_5			    char(10)            NULL
    , pay_through_date_5					    char(10)            NULL
    , emp_death_date_5					        char(10)            NULL
    , consider_for_rehire_ind_5			        char(01)            NULL
    , pay_element_desc_06					    char(20)            NULL
    , emp_calculation_06					    char(15)            NULL
    , tax_flag                                  char(1)             NULL    -- individual_personal.ind_2
    , nic_flag                                  char(1)             NULL    -- individual_personal.ind_1
    , tax_ceiling_amt                           char(15)            NULL    -- employee.user_monetary_amt_1
    , labor_grp_code                            char(50)            NULL    -- emp_assignment.user_text_1
    , file_source                               char(50)            NULL    -- 'SS VENUS' or 'SS GANYMEDE'
    )


    BEGIN TRY

        SET @v_step_position = 'Set Variables'

        SET @w_wflow_userid = SYSTEM_USER

        -- Find the Batch name and qualifier for the job running the Bulk Copy
        SELECT @w_userid       = psc_userid
            , @w_batchname     = psc_batchname
            , @w_qualifier     = psc_qualifier
            , @w_activity_date = psc_last_comp_date
        FROM DBSpscb.dbo.psc_step
        WHERE (psc_userid = @w_wflow_userid)
          AND (psc_pgm_parms = 'GHR_EMPLOYEE_EVENTS')     -- bulkcopy step


        --SET @w_activity_status	= '00'
        -- Use date on bulkcopy step    SET @w_activity_date = CAST(CONVERT(CHAR(20),GETDATE(),120) as DATETIME)


        -- Get input filename
        -- WHY IS THIS NEEDED???
        SELECT @w_inputfile	= batch_parameter_3
        FROM DBSentp.dbo.batch_parameters
        WHERE (batch_parameter_key = 'GHR_EMPLOYEE_EVENTS')

        -- Load imported data to table table
        SET @v_step_position = 'Copy Imported Data Temp'


        INSERT INTO #ghr_employee_events_temp
        SELECT event_id_01
            , emp_id_01
            , eff_date_01
            , first_name_01
            , first_middle_name_01
            , last_name_01
            , UPPER(empl_id_01)
            , 'NIS' -- national_id_1_type_code_01
            , national_id_1_01
            , organization_group_id_01
            , ''    -- organization_chart_name_01
            , ''    -- organization_unit_name_01
            , emp_status_classn_code_01
            , position_title_01
            , UPPER(employment_type_code_01)
            , annual_salary_amt_01
            , begin_date_02
            , end_date_02
            , pay_status_code_03
            , UPPER(pay_group_id_03)
            , pay_element_ctrl_grp_id_03
            , time_reporting_meth_code_03
            , employment_info_chg_reason_cd_03
            , emp_location_code_03
            , emp_status_code_5
            , reason_code_5
            , emp_expected_return_date_5
            , pay_through_date_5
            , emp_death_date_5
            , consider_for_rehire_ind_5
            , UPPER(pay_element_desc_06)
            , emp_calculation_06
            , tax_flag
            , nic_flag
            , tax_ceiling_amt
            , labor_grp_code
            , file_source
        FROM DBShrpn.dbo.ghr_employee_events
        ORDER BY event_id_01
               , emp_id_01


        SET @v_step_position = 'Copy Imported Data to Audit'

        INSERT INTO DBShrpn.dbo.ghr_employee_events_aud
        SELECT event_id_01
            , emp_id_01
            , eff_date_01
            , first_name_01
            , first_middle_name_01
            , last_name_01
            , empl_id_01
            , national_id_1_type_code_01
            , national_id_1_01
            , organization_group_id_01
            , organization_chart_name_01
            , organization_unit_name_01
            , emp_status_classn_code_01
            , position_title_01
            , employment_type_code_01
            , annual_salary_amt_01
            , begin_date_02
            , end_date_02
            , pay_status_code_03
            , pay_group_id_03
            , pay_element_ctrl_grp_id_03
            , time_reporting_meth_code_03
            , employment_info_chg_reason_cd_03
            , emp_location_code_03
            , emp_status_code_5
            , reason_code_5
            , emp_expected_return_date_5
            , pay_through_date_5
            , emp_death_date_5
            , consider_for_rehire_ind_5
            , pay_element_desc_06
            , emp_calculation_06
            , tax_flag
            , nic_flag
            , tax_ceiling_amt
            , labor_grp_code
            , file_source
            , @w_activity_date		    AS activity_date
            , @w_wflow_userid		    AS activity_user
            , @v_ACTIVITY_STATUS_GOOD		AS activity_status
        FROM DBShrpn.dbo.ghr_employee_events ee
        WHERE NOT EXISTS (
                        SELECT 1
                        FROM DBShrpn.dbo.ghr_employee_events_aud t
                        WHERE t.event_id_01	=   ee.event_id_01
                            AND t.emp_id_01		=	ee.emp_id_01
                            AND t.activity_date	=	@w_activity_date
                        )


        ---------------------------------------------------------------------------
        -- New Hires
        ---------------------------------------------------------------------------
        SET @v_step_position = 'Execute New Hires'
        SET @v_event_id = @v_EVENT_ID_NEW_HIRE

        IF  EXISTS (
                    SELECT event_id_01
                    FROM DBShrpn.dbo.ghr_employee_events
                    WHERE event_id_01 = @v_EVENT_ID_NEW_HIRE
                   )
        BEGIN

			EXEC DBShrpn.dbo.usp_ins_new_hire
                  @p_userid          = @w_userid
                , @p_batchname       = @w_batchname
                , @p_qualifier       = @w_qualifier
                , @p_activity_date   = @w_activity_date
                , @p_user_id         = @w_wflow_userid
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
                    SELECT event_id_01
                    FROM DBShrpn.dbo.ghr_employee_events
                    WHERE (event_id_01 = @v_EVENT_ID_SALARY_CHANGE)
                   )
        BEGIN
            EXEC	DBShrpn.dbo.usp_ins_salary_change @w_userid,
                    @w_batchname,
                    @w_qualifier,
                    @w_activity_date,
                    @w_wflow_userid,
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
                   SELECT event_id_01
                   FROM DBShrpn.dbo.ghr_employee_events
                   WHERE event_id_01 = @v_EVENT_ID_TRANSFER
                  )
        BEGIN
            EXEC DBShrpn.dbo.usp_perform_transfer
                        @p_userid          = @w_userid
                      , @p_batchname       = @w_batchname
                      , @p_qualifier       = @w_qualifier
                      , @p_activity_date   = @w_activity_date
                      , @p_user_id         = @w_wflow_userid
                      , @p_status          = @w_status
        END


        ---------------------------------------------------------------------------
        -- Name Change
        ---------------------------------------------------------------------------
        SET @v_step_position = 'Execute Name Change'
        SET @v_event_id = @v_EVENT_ID_NAME_CHANGE


        IF EXISTS (
                   SELECT event_id_01
                   FROM DBShrpn.dbo.ghr_employee_events
                   WHERE event_id_01 = @v_EVENT_ID_NAME_CHANGE
                  )
        BEGIN
            EXEC DBShrpn.dbo.usp_ins_name_change
                        @p_userid          = @w_userid
                      , @p_batchname       = @w_batchname
                      , @p_qualifier       = @w_qualifier
                      , @p_activity_date   = @w_activity_date
                      , @p_user_id         = @w_wflow_userid
                      , @p_status          = @w_status
        END


        ---------------------------------------------------------------------------
        -- Status Change
        ---------------------------------------------------------------------------
        SET @v_step_position = 'Execute Status Change'
        SET @v_event_id = @v_EVENT_ID_STATUS_CHANGE

        IF  EXISTS (
                    SELECT event_id_01
                    FROM DBShrpn.dbo.ghr_employee_events
                    WHERE event_id_01 = @v_EVENT_ID_STATUS_CHANGE
                   )
        BEGIN
            EXEC DBShrpn.dbo.usp_ins_status_change
                        @p_userid          = @w_userid
                      , @p_batchname       = @w_batchname
                      , @p_qualifier       = @w_qualifier
                      , @p_activity_date   = @w_activity_date
                      , @p_user_id         = @w_wflow_userid
                      , @p_status          = @w_status
        END


        ---------------------------------------------------------------------------
        -- Pay Element
        ---------------------------------------------------------------------------
        SET @v_step_position = 'Execute Pay Allowances'
        SET @v_event_id = @v_EVENT_ID_PAY_ELE

        IF  EXISTS (
                    SELECT event_id_01
                    FROM DBShrpn.dbo.ghr_employee_events
                    WHERE event_id_01 = @v_EVENT_ID_PAY_ELE
                   )
        BEGIN
            EXEC DBShrpn.dbo.usp_ins_pay_element
                        @p_userid          = @w_userid
                      , @p_batchname       = @w_batchname
                      , @p_qualifier       = @w_qualifier
                      , @p_activity_date   = @w_activity_date
                      , @p_user_id         = @w_wflow_userid
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
        , ''                -- pay_element_desc_06
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
