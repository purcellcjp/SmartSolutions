USE DBShrpn
GO

SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

IF OBJECT_ID(N'dbo.usp_ins_status_change', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_ins_status_change
    IF OBJECT_ID(N'dbo.usp_ins_status_change') IS NOT NULL
        PRINT N'<<< FAILED DROPPING PROCEDURE dbo.usp_ins_status_change >>>'
    ELSE
        PRINT N'<<< DROPPED PROCEDURE dbo.usp_ins_status_change >>>'
END
GO

/*************************************************************************************
    SP Name:       usp_ins_status_change

    Description:    Updates the SmartStream associate status utilizing the applicable SmartStream procedures.

                    Status is updated based on the code from HCM #ghr_employee_events_temp.emp_status_code:

                    Code    Description     SmartStream Procedure
                    ----    -----------     ---------------------
                    RH      Rehire          DBShrpn.dbo.usp_upd_hmpl_rehire
                                            DBShrpn.dbo.usp_ins_hpcg_hepy

                    RA      Reactivate      DBShrpn.dbo.usp_upd_hmpl_reactivate

                    I       Inactivate      DBShrpn.dbo.usp_upd_hmpl_inactivate

                    T       Terminate       DBShrpn.dbo.usp_upd_hmpl_terminate


    Parameters:
        @p_user_id       =  User ID (i.e. 'DBS')
        @p_batchname     = Job Scheduler Batch Name (i.e. 'GHR')
        @p_qualifier     = Job Scheduler Qualifier (i.e. 'INTERFACES')
        @p_activity_date = Current System Date


    Example:
        EXEC DBShrpn.dbo.usp_ins_status_change
              @p_user_id          = @w_userid
            , @p_batchname       = @v_PSC_BATCHNAME
            , @p_qualifier       = @w_PSC_QUALIFIER
            , @p_activity_date   = @w_activity_date


   Revision history:
   version  date        developer   SCR         description
   -------  ----------  ---------   -----       ------------------------------------
   1.0.00   08/27/2025  CJP                     - Cloned from GOG version

************************************************************************************/

CREATE PROCEDURE dbo.usp_ins_status_change
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
    DECLARE @v_single_quote                     char(01)            = char(39)

    DECLARE @v_EVENT_ID_NEW_HIRE                char(2)             = '01'
    DECLARE @v_EVENT_ID_STATUS_CHANGE           char(2)             = '05'

    DECLARE @v_END_OF_TIME_DATE                 datetime            = '29991231'
    DECLARE @v_BEG_OF_TIME_DATE                 datetime            = '19000101'
    DECLARE @v_BAD_DATE_INDICATOR               datetime            = '99991231'    -- value used to populate datetime column with value from HCM that is not a valid date after conversion

    DECLARE @v_EMPTY_SPACE                      char(01)            = ''

    DECLARE @v_ACTIVITY_STATUS_GOOD             char(2)             = '00'
    DECLARE @v_ACTIVITY_STATUS_WARNING          char(2)             = '01'
    DECLARE @v_ACTIVITY_STATUS_BAD              char(2)             = '02'

    DECLARE @ErrorNumber                        varchar(10)
    DECLARE @ErrorMessage                       nvarchar(4000)
    DECLARE @ErrorSeverity                      int
    DECLARE @ErrorState                         int

    DECLARE @v_ret_val                          int = 0

    DECLARE @w_msg_text				            varchar(255)
    DECLARE @w_msg_text_2               	    varchar(255)
    DECLARE @w_msg_text_3               	    varchar(255)
    DECLARE @w_severity_cd              	    tinyint
    DECLARE @w_fatal_error              	    bit     = 0         --char(01)
    DECLARE @w_curr_status_value        	    char(10)

    DECLARE @w_addr_1_type_code                     char(05)        = '1'   -- Home

    DECLARE @special_value_exists       	    int
    DECLARE @individual_id              	    char(10)
    DECLARE @prior_last_name            	    char(30)
    DECLARE @w_status_change_date       	    datetime
    DECLARE @w_previous_emp_id        	        char(15)
    DECLARE @w_job_end_date             	    datetime
    DECLARE @w_position_end_date        	    datetime
    DECLARE @w_todays_date              	    char(12)
    DECLARE @w_old_chgstamp             	    smallint
    DECLARE @w_taxing_country_code    	        char(02)

    DECLARE @w_eff_date                 	    datetime
    DECLARE @w_curr_status              	    char(02)
    DECLARE @w_pos_eff_date           	        datetime
    DECLARE @w_assigned_to_code         	    char(01)    = 'P'   -- All assocs are code 'P' in VENUS and Ganymede
    DECLARE @w_job_or_pos_id            	    char(10)
    DECLARE @old_eff_date               	    datetime

    DECLARE @pay_frequency_code         	    char(05) = @v_EMPTY_SPACE
    DECLARE @rehire_override            	    CHAR(01)

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

    DECLARE @w_ee_eff_date             				datetime
    DECLARE @maxx           						char(06)
    DECLARE @tax_entity_id  						char(10)
    DECLARE @msg_id         						char(10)




    -- This section declares the interface values from Global HR
    DECLARE @aud_id                                 int             = 0
    DECLARE @emp_id                                 char(15)        = @v_EMPTY_SPACE
    DECLARE @eff_date                               datetime
    DECLARE @first_name                      	    char(25)
    DECLARE @first_middle_name               	    char(25)
    DECLARE @last_name                       	    char(30)
    DECLARE @empl_id                         	    char(10)
    DECLARE @national_id_type_code           	    char(05)
    DECLARE @national_id                     	    char(20)
    DECLARE @organization_group_id           	    int
    DECLARE @organization_chart_name         	    varchar(64)
    DECLARE @organization_unit_name          	    varchar(240)
    DECLARE @emp_status_classn_code          	    char(02)
    DECLARE @position_title                  	    char(50)        -- DBShrpn..emp_assignment.user_text
    DECLARE @employment_type_code            	    varchar(70)     -- increased size to 70 from 5
    DECLARE @pay_rate               	            money
    DECLARE @begin_date                      	    datetime
    DECLARE @end_date                        	    datetime
    DECLARE @pay_status_code                 	    char(01)
    DECLARE @pay_group_id                    	    char(10)
    DECLARE @pay_element_ctrl_grp_id         	    char(10)
    DECLARE @time_reporting_meth_code        	    char(01)
    DECLARE @employment_info_chg_reason_cd   	    char(05)
    DECLARE @emp_location_code               	    char(10)
    DECLARE @emp_status_code                 	    char(02)
    DECLARE @reason_code                     	    char(02)
    DECLARE @emp_expected_return_date        	    char(10)
    DECLARE @pay_through_date                	    datetime
    DECLARE @emp_death_date                  	    datetime
    DECLARE @consider_for_rehire_ind         	    char(01)
    --DECLARE @pay_element_id                  	    char(10)
    --DECLARE @emp_calculation                 	    char(15)
    DECLARE @tax_flag                        	    char(1)         -- individual_personal.ind_2
    DECLARE @nic_flag                        	    char(1)         -- individual_personal.ind_1
    DECLARE @tax_ceiling_amt                 	    money           -- employee.user_monetary_amt_1
    DECLARE @labor_grp_code                  	    char(5)         -- DBShrpn..emp_employment.labor_grp_code
    DECLARE @file_source                     	    char(50)        -- 'SS VENUS' or 'SS GANYMEDE'
    DECLARE @annual_hrs_per_fte                     money
    DECLARE @annual_rate                            money
    DECLARE @addr_fmt_code                          char(06)
    DECLARE @country_code                           char(02)
    DECLARE @addr_line_1                            varchar(35)
    DECLARE @addr_line_2                            varchar(35)
    DECLARE @addr_line_3                            varchar(35)
    DECLARE @addr_line_4                            varchar(35)
    DECLARE @city_name                              varchar(35)
    DECLARE @state_prov                             char(09)
    DECLARE @postal_code                            char(09)
    DECLARE @county_name                            varchar(255)
    DECLARE @region_name                            varchar(255)
    DECLARE @pay_frequency_code                     varchar(255)


    -- Temp table stores message master error templates in use for this procedure
    CREATE TABLE #tbl_ghr_msg
        (
          msg_id                                char(15)            NOT NULL
        , msg_desc                              varchar(255)        NOT NULL
        )


    -- Used helper proc DBShrpn.dbo.usp_upd_hmpl_terminate
    CREATE TABLE #temp1
        (
         pay_element_id                         char(10)            NULL
        )


    -- Used helper proc DBShrpn.dbo.usp_upd_hmpl_terminate
    CREATE TABLE #temp2
        (
          row_id                                int                 NULL
        , emp_id                                char(15)            NULL
        , assigned_to_code                      char(01)            NULL
        , job_or_pos_id                         char(10)            NULL
        , eff_date                              datetime            NULL
        , next_eff_date                         datetime            NULL
        , prior_eff_date                        datetime            NULL
        , end_date                              datetime            NULL
        )


    BEGIN TRY

       SET @v_step_position = 'Declaring cursor crsrHR'

        -- Loop through ghr_employee_events_temp to populate error message log entry
        DECLARE crsrHR CURSOR FAST_FORWARD FOR
        SELECT t.aud_id
             , t.emp_id
             , t.eff_date
             , t.first_name
             , t.first_middle_name
             , t.last_name
             , t.empl_id
             , t.national_id_type_code
             , t.national_id
             , t.organization_group_id
             , @v_EMPTY_SPACE       -- t.organization_chart_name
             , @v_EMPTY_SPACE       -- t.organization_unit_name
             , t.emp_status_classn_code
             , t.position_title
             , t.employment_type_code
             , t.annual_salary_amt
             , t.begin_date
             , t.end_date
             , t.pay_status_code
             , t.pay_group_id
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
             --, t.pay_element_id
             --, t.emp_calculation
             , t.tax_flag
             , t.nic_flag
             , t.tax_ceiling_amt
             , t.labor_grp_code
             , t.file_source

             , t.annual_hrs_per_fte
             , t.annual_rate
             , t.addr_fmt_code
             , t.country_code
             , t.addr_line_1
             , t.addr_line_2
             , t.addr_line_3
             , t.addr_line_4
             , t.city_name
             , t.state_prov
             , t.postal_code
             , t.county_name
             , t.region_name
             , t.pay_frequency_code
             , t.job_or_pos_id
        FROM #ghr_employee_events_temp t
        WHERE (event_id = @v_EVENT_ID_STATUS_CHANGE)

        SET @v_step_position = 'Opening cursor crsrHR'
        OPEN crsrHR

        SET @v_step_position = 'Fetching cursor crsrHR'
        FETCH crsrHR
        INTO  @aud_id
            , @emp_id
            , @eff_date
            , @first_name
            , @first_middle_name
            , @last_name
            , @empl_id
            , @national_id_type_code
            , @national_id
            , @organization_group_id
            , @organization_chart_name
            , @organization_unit_name
            , @emp_status_classn_code
            , @position_title
            , @employment_type_code
            , @pay_rate
            , @begin_date
            , @end_date
            , @pay_status_code
            , @pay_group_id
            , @pay_element_ctrl_grp_id
            , @time_reporting_meth_code
            , @employment_info_chg_reason_cd
            , @emp_location_code
            , @emp_status_code
            , @reason_code
            , @emp_expected_return_date
            , @pay_through_date
            , @emp_death_date
            , @consider_for_rehire_ind
            , @tax_flag
            , @nic_flag
            , @tax_ceiling_amt
            , @labor_grp_code
            , @file_source
            , @annual_hrs_per_fte
            , @annual_rate
            , @addr_fmt_code                -- Address is included for re-hires
            , @country_code
            , @addr_line_1
            , @addr_line_2
            , @addr_line_3
            , @addr_line_4
            , @city_name
            , @state_prov
            , @postal_code
            , @county_name
            , @region_name
            , @pay_frequency_code
            , @w_job_or_pos_id


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
                        , REPLACE(REPLACE(t.msg_text, '@1', 'employee status change'), '@2', @emp_id) AS msg_desc
                    FROM DBSCOMMON.dbo.message_master t
                    WHERE (t.msg_id = @msg_id)

                    -- Historical Message for reporting purpose
                    EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                        , @p_event_id           = @v_EVENT_ID_STATUS_CHANGE
                        , @p_emp_id             = @emp_id
                        , @p_eff_date           = @eff_date
                        , @p_pay_element_id     = @v_EMPTY_SPACE
                        , @p_msg_p1             = @v_EMPTY_SPACE
                        , @p_msg_p2             = @v_EMPTY_SPACE
                        , @p_msg_desc           = 'Bypassing employee status change since employee has a new hire update event in this extract.'
                        , @p_activity_status    = @v_ACTIVITY_STATUS_WARNING
                        , @p_activity_date      = @p_activity_date
                        , @p_audit_id           = @aud_id

                    -- Skip record and all other validations
                    -- since labor group will be processed in the other events
                    GOTO BYPASS_EMPLOYEE

                END


                ---------------------------------------------------------------------------
                -- Validate Effective Date
                ---------------------------------------------------------------------------


                -- Effective Date
                IF (@eff_date = @v_BAD_DATE_INDICATOR)
                    BEGIN

                        SET @msg_id = 'U00102'  -- New code
                        SET @v_step_position = 'Validation Effective Date - ' + RTRIM(@msg_id)


                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id      AS msg_id
                            , REPLACE(REPLACE(REPLACE(t.msg_text, '@1', @eff_date), '@2', @emp_id), '@3', @v_EVENT_ID_STATUS_CHANGE) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master t
                        WHERE (t.msg_id = @msg_id)


                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_STATUS_CHANGE
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

                SELECT @w_status_change_date = stat.status_change_date
                    , @w_old_chgstamp       = stat.chgstamp
                    , @w_curr_status        = stat.emp_status_code
                    , @w_curr_status_value  = CASE stat.emp_status_code
                                                WHEN 'A' THEN 'Active'
                                                WHEN 'I' THEN 'Inactive'
                                                WHEN 'T' THEN 'Terminated'
                                                ELSE @v_EMPTY_SPACE
                                            END
                    , @w_ee_eff_date = eempl.eff_date
                    , @individual_id = emp.individual_id
                FROM DBShrpn.dbo.employee emp
                JOIN DBShrpn.dbo.individual ind ON
                     (emp.individual_id = ind.individual_id)
                JOIN DBShrpn.dbo.uvu_emp_status_most_rec stat ON
                    (emp.emp_id = stat.emp_id)
                JOIN DBShrpn.dbo.uvu_emp_employment_most_rec eempl ON
                    (emp.emp_id = eempl.emp_id)
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
                            , @p_event_id           = @v_EVENT_ID_STATUS_CHANGE
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
                -- Check to see if the employer exists
                ---------------------------------------------------------------------------
                SET @msg_id = 'U00039'
                SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

                IF NOT EXISTS (
                                SELECT *
                                FROM DBShrpn.dbo.employer
                                WHERE empl_id = @empl_id
                                )
                    BEGIN

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id                   As msg_id
                            , REPLACE(REPLACE(t.msg_text, '@1', @empl_id), '@2', @emp_id) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master t
                        WHERE (t.msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_STATUS_CHANGE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @v_EMPTY_SPACE
                            , @p_msg_p1             = @emp_id
                            , @p_msg_p2             = @empl_id
                            , @p_msg_desc           = 'Invalid Employer ID - bypassing record.'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id


                        -- SET @empl_id = '99999'
                        SET @w_fatal_error = 1


                    END



                ---------------------------------------------------------------------------
                -- Check to see that the new record effective date is greater than the existing record.
                ---------------------------------------------------------------------------
                SET @msg_id = 'U00037'
                SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

                IF (@w_status_change_date >= @eff_date)
                    BEGIN

                        -- Convert date to string for log table
                        SET @w_msg_text_2 = CONVERT(char(8), @w_status_change_date, 112)

                            INSERT INTO #tbl_ghr_msg
                            SELECT @msg_id As msg_id
                                , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                            FROM DBSCOMMON.dbo.message_master t
                            WHERE (t.msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_STATUS_CHANGE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @v_EMPTY_SPACE
                            , @p_msg_p1             = @eff_date
                            , @p_msg_p2             = @w_msg_text_2
                            , @p_msg_desc           = 'New Status Effective date must be greater than current effective date.'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id

                        SET @w_fatal_error = 1

                    END

                ---------------------------------------------------------------------------
                -- Check to see if the transfer date is greater than position effective date.
                ---------------------------------------------------------------------------
                SET @msg_id = 'U00036'
                SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

                SELECT @w_pos_eff_date = eff_date
                FROM DBShrpn.dbo.position
                WHERE pos_id = '99999'

                IF (@w_pos_eff_date > @eff_date)
                    BEGIN

                        -- Convert date to string for log table
                        SET @w_msg_text_2 = CONVERT(char(8), @w_pos_eff_date, 112)

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id                   As msg_id
                            , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master t
                        WHERE (t.msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_STATUS_CHANGE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @v_EMPTY_SPACE
                            , @p_msg_p1             = @eff_date
                            , @p_msg_p2             = @w_msg_text_2
                            , @p_msg_desc           = 'Transfer date must be greater than default position effective date.'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id

                        SET @w_fatal_error = 1

                    END


                ---------------------------------------------------------------------------
                -- Check to see if the rehire date is greater than employee employment effective date.
                ---------------------------------------------------------------------------
                SET @msg_id = 'U00043'
                SET @v_step_position = 'Begin ' + RTRIM(@msg_id)


                IF (@w_ee_eff_date >= @eff_date)
                    BEGIN
                        -- Convert date to string for log table
                        SET @w_msg_text_2 = CONVERT(char(8), @w_ee_eff_date, 112)

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id As msg_id
                            , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master t
                        WHERE (t.msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_STATUS_CHANGE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @v_EMPTY_SPACE
                            , @p_msg_p1             = @eff_date
                            , @p_msg_p2             = @w_msg_text_2
                            , @p_msg_desc           = 'Rehire date must be greater than current employee employment effective date.'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id

                        SET @w_fatal_error = 1

                    END


                ---------------------------------------------------------------------------
                --   Check to see if pay group id exists
                ---------------------------------------------------------------------------
                SET @msg_id = 'U00020'
                SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

                IF NOT EXISTS(
                            SELECT *
                            FROM   DBShrpn.dbo.pay_group
                            WHERE   pay_group_id = @pay_group_id
                            )
                    BEGIN

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id As msg_id
                            , REPLACE(REPLACE(t.msg_text, '@1', @pay_group_id), '@2', @emp_id) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master t
                        WHERE (t.msg_id = @msg_id)


                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_STATUS_CHANGE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @v_EMPTY_SPACE
                            , @p_msg_p1             = @emp_id
                            , @p_msg_p2             = @pay_group_id
                            , @p_msg_desc           = 'Invalid pay group id.'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id

                        SET @w_fatal_error = 1

                    END


                ---------------------------------------------------------------------------
                ---------------------------------------------------------------------------
                -- Validate the important fields in this section.
                ---------------------------------------------------------------------------
                ---------------------------------------------------------------------------


                ---------------------------------------------------------------------------
                --   Check to see if the rehire date is greater than the termination date. Reject the record
                ---------------------------------------------------------------------------
                SET @msg_id = 'U00032'
                SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

                IF   @emp_status_code = 'RH'
                    BEGIN
                        IF (@w_curr_status = 'T') AND
                        (@eff_date   <= @w_status_change_date)
                            BEGIN

                                -- Convert date to string for log table
                                SET @w_msg_text_2 = CONVERT(char(8), @w_status_change_date, 112)

                                INSERT INTO #tbl_ghr_msg
                                SELECT @msg_id      As msg_id
                                    , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                                FROM DBSCOMMON.dbo.message_master t
                                WHERE (t.msg_id = @msg_id)

                                -- Historical Message for reporting purpose
                                EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                                    @p_msg_id             = @msg_id
                                    , @p_event_id           = @v_EVENT_ID_STATUS_CHANGE
                                    , @p_emp_id             = @emp_id
                                    , @p_eff_date           = @eff_date
                                    , @p_pay_element_id     = @v_EMPTY_SPACE
                                    , @p_msg_p1             = @w_curr_status
                                    , @p_msg_p2             = @w_msg_text_2
                                    , @p_msg_desc           = 'The rehire date must be greater than the termination date - By passing the employee.'
                                    , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                                    , @p_activity_date      = @p_activity_date
                                    , @p_audit_id           = @aud_id

                                SET @w_fatal_error = 1

                            END
                    END


                ---------------------------------------------------------------------------
                --   Check to see if the reactivation date is greater than the inactivation date. Reject the record
                ---------------------------------------------------------------------------
                SET @msg_id = 'U00033'
                SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

                IF (@emp_status_code = 'RA')
                    BEGIN
                        IF (@w_curr_status = 'I') AND
                        (@eff_date <= @w_status_change_date)
                            BEGIN

                                -- Convert date to string for log table
                                SET @w_msg_text_2 = CONVERT(char(8), @w_status_change_date, 112)

                                INSERT INTO #tbl_ghr_msg
                                SELECT @msg_id As msg_id
                                    , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                                FROM DBSCOMMON.dbo.message_master t
                                WHERE (t.msg_id = @msg_id)

                                -- Historical Message for reporting purpose
                                EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                                    @p_msg_id             = @msg_id
                                    , @p_event_id           = @v_EVENT_ID_STATUS_CHANGE
                                    , @p_emp_id             = @emp_id
                                    , @p_eff_date           = @eff_date
                                    , @p_pay_element_id     = @v_EMPTY_SPACE
                                    , @p_msg_p1             = @w_curr_status
                                    , @p_msg_p2             = @w_msg_text_2
                                    , @p_msg_desc           = 'The Reactivation date must be greater than the inactivation date - By passing the employee.'
                                    , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                                    , @p_activity_date      = @p_activity_date
                                    , @p_audit_id           = @aud_id


                                SET @w_fatal_error = 1

                            END
                    END

                -- Skip record if errors encountered
                IF (@w_fatal_error = 1)
                    GOTO BYPASS_EMPLOYEE

                ---------------------------------------------------------------------------
                ---------------------------------------------------------------------------
                --   Obtain the setup variables
                ---------------------------------------------------------------------------
                ---------------------------------------------------------------------------


                ---------------------------------------------------------------------------
                -- Find the tax entity
                ---------------------------------------------------------------------------
                SELECT @tax_entity_id = tax_entity_id
                FROM DBShrpn.dbo.empl_tax_entity
                WHERE empl_id = @empl_id


                ---------------------------------------------------------------------------
                --   Find the Job_position end date and Assignment end date
                ---------------------------------------------------------------------------
                SELECT @w_position_end_date = @v_END_OF_TIME_DATE
                     , @w_job_end_date      = @v_END_OF_TIME_DATE



                ---------------------------------------------------------------------------
                --   Obtain prior employee number
                ---------------------------------------------------------------------------
                SELECT @w_previous_emp_id = prior_emp_id
                FROM employee emp
                JOIN emp_status stat ON
                    (emp.emp_id = stat.emp_id)
                WHERE emp.emp_id =   @emp_id
                AND (stat.status_change_date <= @p_activity_date)     -- @w_todays_date
                AND (stat.next_change_date    > @p_activity_date)     -- @w_todays_date

                IF (@w_previous_emp_id = ' ')
                    SET @w_previous_emp_id = @emp_id


                SELECT @w_taxing_country_code = empl.taxing_country_code
                    , @w_curr_code = empl.curr_code
                FROM DBShrpn.dbo.employer empl
                WHERE (empl.empl_id = @empl_id)



                ---------------------------------------------------------------------------
                -- Rehire Associate
                ---------------------------------------------------------------------------
                IF (@emp_status_code = 'RH')
                    BEGIN


                        IF (@w_curr_status = 'T')
                            BEGIN


                                -- Debug
                                SET @v_step_position = 'Rehire RH usp_upd_hmpl_rehire DEBUG'


                                INSERT DBShrpn.dbo.ghr_debug (text_line)
                                VALUES('EXECUTE DBShrpn.dbo.usp_upd_hmpl_rehire')
                                , ( ' @p_emp_id =                 = ' + @v_single_quote + RTRIM(@emp_id)                                + @v_single_quote)
                                , (', @p_previous_emp_id          = ' + @v_single_quote + RTRIM(@w_previous_emp_id)                     + @v_single_quote)
                                , (', @p_status_change_date       = ' + @v_single_quote + CONVERT(char(8), @w_status_change_date, 112)  + @v_single_quote)
                                , (', @p_new_empl_id              = ' + @v_single_quote + RTRIM(@empl_id)                               + @v_single_quote)
                                , (', @p_new_tax_entity_id        = ' + @v_single_quote + RTRIM(@tax_entity_id)                         + @v_single_quote)
                                , (', @p_new_hire_date            = ' + @v_single_quote + CONVERT(char(8), @eff_date, 112)              + @v_single_quote)
                                , (', @p_new_classn_cd            = ' + @v_single_quote + RTRIM(@emp_status_classn_code)                + @v_single_quote)
                                , (', @p_new_reason_cd            = ' + @v_single_quote + @v_EMPTY_SPACE                                + @v_single_quote)
                                , (', @p_new_assigned_to_code     = ' + @v_single_quote + RTRIM(@w_assigned_to_code)                    + @v_single_quote)
                                , (', @p_new_job_or_pos_id        = ' + @v_single_quote + RTRIM(@w_job_or_pos_id)                       + @v_single_quote)
                                , (', @p_new_pay_group_id         = ' + @v_single_quote + RTRIM(@pay_group_id)                          + @v_single_quote)
                                , (', @p_new_time_reporting_meth  = ' + @v_single_quote + RTRIM(@time_reporting_meth_code)              + @v_single_quote)
                                , (', @p_job_end_date             = ' + @v_single_quote + CONVERT(char(8), @w_job_end_date, 112)        + @v_single_quote)
                                , (', @p_position_end_date        = ' + @v_single_quote + CONVERT(char(8), @w_position_end_date, 112)   + @v_single_quote)
                                , (', @p_taxing_country           = ' + @v_single_quote + RTRIM(@w_taxing_country_code)                 + @v_single_quote)
                                , (', @p_new_pay_elem_ctrl_grp_id = ' + @v_single_quote + RTRIM(@pay_element_ctrl_grp_id)               + @v_single_quote)
                                , (', @p_allow_pay_updates_ind    = ' + @v_single_quote + 'Y'                                           + @v_single_quote)
                                , (', @p_old_chgstamp             = ' + @v_single_quote + CONVERT(varchar, @w_old_chgstamp, 0)          + @v_single_quote)
                                , (' ');



                                SET @v_step_position = 'Rehire RH usp_upd_hmpl_rehire'

                                EXECUTE DBShrpn.dbo.usp_upd_hmpl_rehire
                                      @p_emp_id                   = @emp_id
                                    , @p_previous_emp_id          = @w_previous_emp_id
                                    , @p_status_change_date       = @w_status_change_date
                                    , @p_new_empl_id              = @empl_id
                                    , @p_new_tax_entity_id        = @tax_entity_id
                                    , @p_new_hire_date            = @eff_date
                                    , @p_new_classn_cd            = @emp_status_classn_code
                                    , @p_new_reason_cd            = @v_EMPTY_SPACE
                                    , @p_new_assigned_to_code     = @w_assigned_to_code             -- Hardcoded to 'P'
                                    , @p_new_job_or_pos_id        = @w_job_or_pos_id
                                    , @p_new_pay_group_id         = @pay_group_id
                                    , @p_new_time_reporting_meth  = @time_reporting_meth_code
                                    , @p_job_end_date             = @w_job_end_date                 --   datetime         --'29991231'
                                    , @p_position_end_date        = @w_position_end_date            --   datetime         --'29991231'
                                    , @p_taxing_country           = @w_taxing_country_code          --   char(2)         --'GD'
                                    , @p_new_pay_elem_ctrl_grp_id = @pay_element_ctrl_grp_id        --   'MTH'
                                    , @p_allow_pay_updates_ind    = 'Y'
                                    , @p_old_chgstamp             = @w_old_chgstamp                 --   0



                                ---------------------------------------------------------------------------
                                -- Updates associate's pay elements
                                ---------------------------------------------------------------------------
                                SET @v_step_position = 'Rehire RH - Update Pay Elements Debug'

                                INSERT DBShrpn.dbo.ghr_debug (text_line)
                                VALUES('EXECUTE DBShrpn.dbo.usp_ins_hpcg_hepy')
                                , ('@p_emp_id             = ' + @v_single_quote + RTRIM(@emp_id)                        + @v_single_quote)
                                , (', @p_empl_id          = ' + @v_single_quote + RTRIM(@empl_id)                       + @v_single_quote)
                                , (', @p_new_pay_group_id = ' + @v_single_quote + RTRIM(@pay_group_id)                  + @v_single_quote)
                                , (', @p_new_pecg_id      = ' + @v_single_quote + RTRIM(@pay_element_ctrl_grp_id)       + @v_single_quote)
                                , (', @p_as_of_date       = ' + @v_single_quote + CONVERT(char(8), @eff_date, 112)    + @v_single_quote)
                                , (' ');


                                -- Builds pay elements for rehired associate
                                SET @v_step_position = 'Rehire RH - Update Pay Elements'

                                EXECUTE DBShrpn.dbo.usp_ins_hpcg_hepy
                                      @p_emp_id           = @emp_id
                                    , @p_empl_id          = @empl_id
                                    , @p_new_pay_group_id = @pay_group_id
                                    , @p_new_pecg_id      = @pay_element_ctrl_grp_id
                                    , @p_as_of_date       = @eff_date


                                ---------------------------------------------------------------------------
                                --   Lookup the pointers to the new employee assignment record
                                ---------------------------------------------------------------------------
                                SET @v_step_position = 'Rehire RH Emp Asgn Pointer Lookup'

                                SELECT @w_assigned_to_code = ea.assigned_to_code
                                     , @w_job_or_pos_id    = ea.job_or_pos_id
                                     , @w_eff_date         = ea.eff_date
                                FROM DBShrpn.dbo.uvu_emp_assignment_most_rec ea
                                WHERE (ea.emp_id = @emp_id)


                                ---------------------------------------------------------------------------
                                -- Salary Setup
                                ---------------------------------------------------------------------------
                                -- Universally setup all associates as monthly; 8 hrs/day; 40 hrs/week
                                -- Indicates that the associate is setup as annually
                                SET @v_step_position = 'Rehire RH Salary Setup'

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
                                -- Update Employee Assignment record post Rehire
                                ---------------------------------------------------------------------------
                                SET @v_step_position = 'Rehire RH Salary Update'

                                UPDATE DBShrpn.dbo.emp_assignment
                                SET   annual_salary_amt        = @w_annual_salary_amt
                                    , hourly_pay_rate          = @w_hourly_pay_rate
                                    , pd_salary_amt            = @w_pd_salary_amt
                                    , work_tm_code             = @w_work_tm_code
                                    , pd_salary_tm_pd_id       = @w_pd_salary_tm_pd_id
                                    , standard_work_pd_id      = @w_standard_work_pd_id
                                    , standard_work_hrs        = @w_standard_work_hrs
                                    , organization_group_id    = CAST(@organization_group_id AS int)
                                    , organization_chart_name  = @v_EMPTY_SPACE
                                    , organization_unit_name   = @v_EMPTY_SPACE
                                    , user_text_2              = @position_title
                                WHERE (emp_id           = @emp_id)
                                  AND (assigned_to_code = @w_assigned_to_code)
                                  AND (job_or_pos_id    = @w_job_or_pos_id)
                                  AND (eff_date         = @w_eff_date)


                                ---------------------------------------------------------------------------
                                -- Update home address
                                ---------------------------------------------------------------------------
                                SET @v_step_position = 'Rehire RH Address Update'

                                UPDATE DBShrpn.dbo.individual
                                SET addr_1_line_1                  = @addr_line_1
                                  , addr_1_line_2                  = @addr_line_2
                                  , addr_1_line_3                  = ''
                                  , addr_1_line_4                  = ''
                                  , addr_1_line_5                  = ''
                                  , addr_1_street_or_pob_1         = @addr_line_3
                                  , addr_1_street_or_pob_2         = @addr_line_4
                                  , addr_1_street_or_pob_3         = ''
                                  , addr_1_city_name               = @city_name
                                  --, addr_1_country_sub_entity_code = -- @state_prov  -- Parrish Drop Down is not being used by St Lucia
                                  , addr_1_postal_code             = @postal_code
                                  , addr_1_country_code            = @country_code
                                  , addr_1_fmt_code                = @addr_fmt_code
                                  , addr_1_type_code               = @w_addr_1_type_code
                                WHERE (individual_id = @individual_id)


                            END
                        ELSE    -- Associate Not terminated
                            BEGIN
                                SET @msg_id = 'U00022'
                                SET @v_step_position = 'Rehire Not Terminated ' + RTRIM(@msg_id)

                                INSERT INTO #tbl_ghr_msg
                                SELECT @msg_id As msg_id
                                    , REPLACE(REPLACE(t.msg_text, '@1', RTRIM(@w_curr_status_value)), '@2', @emp_id) AS msg_desc
                                FROM DBSCOMMON.dbo.message_master t
                                WHERE (t.msg_id = @msg_id)

                                -- Historical Message for reporting purpose
                                EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                                    @p_msg_id             = @msg_id
                                    , @p_event_id           = @v_EVENT_ID_STATUS_CHANGE
                                    , @p_emp_id             = @emp_id
                                    , @p_eff_date           = @eff_date
                                    , @p_pay_element_id     = @v_EMPTY_SPACE
                                    , @p_msg_p1             = @w_curr_status
                                    , @p_msg_p2             = @v_EMPTY_SPACE
                                    , @p_msg_desc           = 'Cannot rehire an employee if the current status is not terminated.'
                                    , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                                    , @p_activity_date      = @p_activity_date
                                    , @p_audit_id           = @aud_id

                            END
                    END  -- End of Rehire (RH) Logic


                ---------------------------------------------------------------------------
                -- Inactivate Associate
                ---------------------------------------------------------------------------
                IF (@emp_status_code = 'I')
                    BEGIN
                        SET @v_step_position = 'Inactivate Associate'

                        IF (@w_curr_status = 'A')
                            BEGIN

                                /*
                                SET @v_step_position = @v_step_position + ' - Active DEBUG'
                                INSERT DBShrpn.dbo.ghr_debug (text_line)
                                VALUES('EXECUTE DBShrpn.dbo.usp_upd_hmpl_inactivate')
                                , ('@p_emp_id                           = ' + @v_single_quote + RTRIM(@emp_id)                                      + @v_single_quote)
                                , (', @p_status_change_date             = ' + @v_single_quote + CONVERT(char(8), @w_status_change_date, 112)        + @v_single_quote)
                                , (', @p_inactivate_date                = ' + @v_single_quote + CONVERT(char(8), @eff_date)                       + @v_single_quote)
                                , (', @p_new_reason                     = ' + @v_single_quote + @v_EMPTY_SPACE                                      + @v_single_quote)
                                , (', @p_new_loa_expd_date              = ' + @v_single_quote + CONVERT(char(8), @v_END_OF_TIME_DATE, 112)          + @v_single_quote)
                                , (', @p_new_classification_cd          = ' + @v_single_quote + RTRIM(@emp_status_classn_code)                      + @v_single_quote)
                                , (', @p_allow_emp_pay_updates_ind      = ' + @v_single_quote + 'Y'                                                 + @v_single_quote)
                                , (', @p_pay_status_code                = ' + @v_single_quote + @pay_status_code                                    + @v_single_quote)
                                , (', @p_last_day_paid                  = ' + @v_single_quote + CONVERT(char(8), @v_BEG_OF_TIME_DATE, 112)          + @v_single_quote)
                                , (', @p_old_chgstamp                   = ' + @v_single_quote + CONVERT(varchar, @w_old_chgstamp, 0)                + @v_single_quote)
                                , (' ');
                                */

                                SET @v_step_position = @v_step_position + ' - Active'

                                EXECUTE DBShrpn.dbo.usp_upd_hmpl_inactivate
                                    @p_emp_id                    = @emp_id
                                    , @p_status_change_date        = @w_status_change_date
                                    , @p_inactivate_date           = @eff_date
                                    , @p_new_reason                = @v_EMPTY_SPACE
                                    , @p_new_loa_expd_date         = @v_END_OF_TIME_DATE
                                    , @p_new_classification_cd     = @emp_status_classn_code
                                    , @p_allow_emp_pay_updates_ind = 'Y'
                                    , @p_pay_status_code           = @pay_status_code
                                    , @p_last_day_paid             = @v_BEG_OF_TIME_DATE
                                    , @p_old_chgstamp              = @w_old_chgstamp

                            END
                        ELSE
                            BEGIN
                                SET @msg_id = 'U00024'
                                SET @v_step_position = @v_step_position + ' - ' + @w_curr_status + ' - ' + RTRIM(@msg_id)

                                INSERT INTO #tbl_ghr_msg
                                SELECT @msg_id      As msg_id
                                    , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                                FROM DBSCOMMON.dbo.message_master t
                                WHERE (t.msg_id = @msg_id)


                                -- Historical Message for reporting purpose
                                EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                                    @p_msg_id             = @msg_id
                                    , @p_event_id           = @v_EVENT_ID_STATUS_CHANGE
                                    , @p_emp_id             = @emp_id
                                    , @p_eff_date           = @eff_date
                                    , @p_pay_element_id     = @v_EMPTY_SPACE
                                    , @p_msg_p1             = @w_curr_status
                                    , @p_msg_p2             = @w_msg_text_2
                                    , @p_msg_desc           = 'Cannot inactivate associate if the current status is not active.'
                                    , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                                    , @p_activity_date      = @p_activity_date
                                    , @p_audit_id           = @aud_id

                            END

                    END  -- End of Inactivate Logic


                ---------------------------------------------------------------------------
                -- Terminate Associate
                ---------------------------------------------------------------------------
                IF (@emp_status_code = 'T')
                    BEGIN

                        SET @v_step_position = 'Terminate Associate'

                        IF (@w_curr_status IN ('A','I'))
                            BEGIN



                                SELECT @pay_status_code = eempl.pay_status_code
                                    , @old_eff_date     = eempl.eff_date
                                FROM DBShrpn.dbo.uvu_emp_employment_most_rec eempl
                                WHERE (emp_id = @emp_id)

                                /*
                                SET @v_step_position = @v_step_position + ' (''A'' or ''I'') - DEBUG'
                                INSERT DBShrpn.dbo.ghr_debug (text_line)
                                VALUES('EXECUTE DBShrpn.dbo.usp_upd_hmpl_terminate')
                                , ('@p_emp_id                       = ' + @v_single_quote + RTRIM(@emp_id)                                      + @v_single_quote)
                                , (', @p_status_change_date         = ' + @v_single_quote + CONVERT(char(8), @w_status_change_date, 112)        + @v_single_quote)
                                , (', @p_termination_date           = ' + @v_single_quote + CONVERT(char(8), @eff_date, 112)                  + @v_single_quote)
                                , (', @p_new_classn_cd              = ' + @v_single_quote + @emp_status_classn_code                             + @v_single_quote)
                                , (', @p_date_of_death              = ' + @v_single_quote + CONVERT(char(8), @v_END_OF_TIME_DATE, 112)          + @v_single_quote)
                                , (', @p_new_reason_code            = ' + @v_single_quote + RTRIM(@reason_code)                                 + @v_single_quote)
                                , (', @p_new_pay_through_date       = ' + @v_single_quote + CONVERT(char(8), @eff_date, 112)                  + @v_single_quote)
                                , (', @p_new_rehire_conson          = ' + @v_single_quote + @consider_for_rehire_ind                            + @v_single_quote)
                                , (', @p_pay_status_code            = ' + @v_single_quote + RTRIM(pay_status_code)                              + @v_single_quote)
                                , (', @p_last_day_paid              = ' + @v_single_quote + CONVERT(char(8), @v_BEG_OF_TIME_DATE, 112)          + @v_single_quote)
                                , (', @p_old_chgstamp               = ' + @v_single_quote + CONVERT(varchar, @w_old_chgstamp, 0)                + @v_single_quote)
                                , (' ');
                                */

                                SET @v_step_position = @v_step_position + ' (''A'' or ''I'')'

                                -- Note: proc needs temp tables #temp1 and #temp2 to work
                                -- No transaction committ/rollbacks in this procedure
                                EXECUTE DBShrpn.dbo.usp_upd_hmpl_terminate
                                    @p_emp_id                 = @emp_id
                                    , @p_status_change_date     = @w_status_change_date
                                    , @p_termination_date       = @eff_date
                                    , @p_new_classn_cd          = @emp_status_classn_code
                                    , @p_date_of_death          = @emp_death_date
                                    , @p_new_reason_code        = @reason_code
                                    , @p_new_pay_through_date   = @eff_date
                                    , @p_new_rehire_conson      = @consider_for_rehire_ind
                                    , @p_pay_status_code        = @pay_status_code
                                    , @p_last_day_paid          = @v_BEG_OF_TIME_DATE
                                    , @p_old_chgstamp           = @w_old_chgstamp



                                --  New Record Update to resolve conflict with the rehire date
                                UPDATE DBShrpn.dbo.emp_employment
                                SET pay_status_code = @pay_status_code
                                , eff_date        = @eff_date
                                WHERE (emp_id        = @emp_id)
                                AND (next_eff_date = @v_END_OF_TIME_DATE)

                                --  Update prior record to point to the new record.
                                UPDATE DBShrpn.dbo.emp_employment
                                SET next_eff_date = @eff_date
                                WHERE (emp_id   = @emp_id)
                                AND (eff_date = @old_eff_date)

                            END
                        ELSE
                            BEGIN
                                SET @msg_id = 'U00042'
                                SET @v_step_position = @v_step_position + ' - ' + @msg_id + ' Associate Already Terminated'

                                INSERT INTO #tbl_ghr_msg
                                SELECT @msg_id AS msg_id
                                    , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                                FROM DBSCOMMON.dbo.message_master t
                                WHERE (t.msg_id = @msg_id)

                                -- Historical Message for reporting purpose
                                EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                                    @p_msg_id             = @msg_id
                                    , @p_event_id           = @v_EVENT_ID_STATUS_CHANGE
                                    , @p_emp_id             = @emp_id
                                    , @p_eff_date           = @eff_date
                                    , @p_pay_element_id     = @v_EMPTY_SPACE
                                    , @p_msg_p1             = @w_curr_status
                                    , @p_msg_p2             = @v_EMPTY_SPACE
                                    , @p_msg_desc           = 'Associate is already terminated in SmartStream.'
                                    , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                                    , @p_activity_date      = @p_activity_date
                                    , @p_audit_id           = @aud_id

                            END

                    END  -- End of Terminate Logic



                ---------------------------------------------------------------------------
                -- Set Rehire Override Flag
                ---------------------------------------------------------------------------
                -- If current record is reactivation (RA) and rehire (RH) transaction is present in extract
                -- Used to generate log messages when associate is not inactive and
                -- interface is trying to reactivate

                IF  EXISTS (
                            SELECT 1
                            FROM #ghr_employee_events_temp t
                            WHERE (t.event_id = @v_EVENT_ID_STATUS_CHANGE)
                            AND (t.aud_id <> @aud_id)   --
                            AND (t.emp_id = @emp_id)
                            AND (t.emp_status_code = 'RH')
                        )
                    SET @rehire_override = 'Y'
                ELSE
                    SET @rehire_override = 'N'



                ---------------------------------------------------------------------------
                -- Reactivate Associate
                ---------------------------------------------------------------------------
                -- Assocaite must be inactive otherwise log error based on rehire overide flag

                IF   (@emp_status_code = 'RA')
                    BEGIN --1

                        IF (@w_curr_status = 'I')
                            BEGIN  --2
                                SET @v_step_position = 'Rehire RA Inactive'

                                -- Note: This procedure does not create a new employee assignment record
                                EXECUTE DBShrpn.dbo.usp_upd_hmpl_reactivate
                                      @p_emp_id                    = @emp_id
                                    , @p_status_change_date        = @w_status_change_date
                                    , @p_reactivate_date           = @eff_date
                                    , @p_new_reason                = @reason_code
                                    , @p_new_classification_cd     = @emp_status_classn_code
                                    , @p_allow_emp_pay_updates_ind = 'Y'
                                    , @p_pay_status_code           = @pay_status_code
                                    , @p_old_chgstamp              = @w_old_chgstamp

                                -- UPDATE SALARY ??????????



                            END  --2
                        ELSE
                            -- Terminated Associate
                            BEGIN --3
                                -- RH record not present in extract
                                IF (@rehire_override = 'N')
                                    BEGIN  --4

                                        SET @msg_id = 'U00025'
                                        SET @v_step_position = 'Rehire Overide - ''0'' - ' + @msg_id

                                        INSERT INTO #tbl_ghr_msg
                                        SELECT @msg_id As msg_id
                                            , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                                        FROM DBSCOMMON.dbo.message_master t
                                        WHERE (t.msg_id = @msg_id)

                                        -- Historical Message for reporting purpose
                                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                                              @p_msg_id             = @msg_id
                                            , @p_event_id           = @v_EVENT_ID_STATUS_CHANGE
                                            , @p_emp_id             = @emp_id
                                            , @p_eff_date           = @eff_date
                                            , @p_pay_element_id     = @v_EMPTY_SPACE
                                            , @p_msg_p1             = @w_curr_status
                                            , @p_msg_p2             = @v_EMPTY_SPACE
                                            , @p_msg_desc           = 'Cannot Reactivate an employee if the current status is not inactive.'
                                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                                            , @p_activity_date      = @p_activity_date
                                            , @p_audit_id           = @aud_id

                                    END    --4
                                ELSE
                                    BEGIN --5
                                        -- RH record present in extract
                                        -- RH transaction record will process status update
                                        SET @v_step_position = 'Rehire RA - ' + @w_curr_status + ' - ' + 'Activity Status ' + @v_ACTIVITY_STATUS_WARNING

                                        SET @w_msg_text = 'RH record transaction record present in current extract. '
                                                        + 'Re-activiation will occur on that transaction '
                                                        + '- bypassing record.'

                                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                                            @p_msg_id             = @msg_id
                                            , @p_event_id           = @v_EVENT_ID_STATUS_CHANGE
                                            , @p_emp_id             = @emp_id
                                            , @p_eff_date           = @eff_date
                                            , @p_pay_element_id     = @v_EMPTY_SPACE
                                            , @p_msg_p1             = @w_curr_status
                                            , @p_msg_p2             = @v_EMPTY_SPACE
                                            , @p_msg_desc           = @w_msg_text
                                            , @p_activity_status    = @v_ACTIVITY_STATUS_WARNING
                                            , @p_activity_date      = @p_activity_date
                                            , @p_audit_id           = @aud_id

                                    END  --5
                            END --3
                    END --1  -- End of Reactivate Logic


                ---------------------------------------------------------------------------
                -- Update NIC, TAX Flag, Tax Ceiling
                ---------------------------------------------------------------------------
                IF (@emp_status_code IN ('RA','RH'))
                    BEGIN

                        ---------------------------------------------------------------------------
                        -- Update Labor Group Code
                        ---------------------------------------------------------------------------
                        -- update latest emp employment record with labor group code
                        UPDATE DBShrpn.dbo.emp_employment
                        SET labor_grp_code = @labor_grp_code
                        WHERE (next_eff_date = @v_END_OF_TIME_DATE)

                        ---------------------------------------------------------------------------
                        -- GOSL update NIC and Tax Code
                        ---------------------------------------------------------------------------
                        -- CJP 7/7/2025
                        SET @v_step_position = 'Update NIC/Tax Code'

                        UPDATE   DBShrpn.dbo.individual_personal
                        SET   user_ind_1 = @nic_flag
                        , user_ind_2 = @tax_flag
                        WHERE (individual_id = @individual_id)

                        ---------------------------------------------------------------------------
                        -- GOSL update Tax Ceiling Amount
                        ---------------------------------------------------------------------------
                        SET @v_step_position = 'Update Tax Ceiling'

                        UPDATE DBShrpn.dbo.employee
                        SET user_monetary_amt_1 = @tax_ceiling_amt
                        WHERE (emp_id = @emp_id)

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
                    , @p_event_id           = @v_EVENT_ID_STATUS_CHANGE
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
                , @first_name
                , @first_middle_name
                , @last_name
                , @empl_id
                , @national_id_type_code
                , @national_id
                , @organization_group_id
                , @organization_chart_name
                , @organization_unit_name
                , @emp_status_classn_code
                , @position_title
                , @employment_type_code
                , @pay_rate
                , @begin_date
                , @end_date
                , @pay_status_code
                , @pay_group_id
                , @pay_element_ctrl_grp_id
                , @time_reporting_meth_code
                , @employment_info_chg_reason_cd
                , @emp_location_code
                , @emp_status_code
                , @reason_code
                , @emp_expected_return_date
                , @pay_through_date
                , @emp_death_date
                , @consider_for_rehire_ind
                , @tax_flag
                , @nic_flag
                , @tax_ceiling_amt
                , @labor_grp_code
                , @file_source
                , @annual_hrs_per_fte
                , @annual_rate
                , @addr_fmt_code
                , @country_code
                , @addr_line_1
                , @addr_line_2
                , @addr_line_3
                , @addr_line_4
                , @city_name
                , @state_prov
                , @postal_code
                , @county_name
                , @region_name
                , @pay_frequency_code
                , @w_job_or_pos_id

        END  -- While Loop

      -- Cleanup Cursor
      CLOSE crsrHR
      DEALLOCATE crsrHR

        -- commit after every record
        IF (@@TRANCOUNT > 0)
            COMMIT TRAN


    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    -- Notify the users of all the issues
    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------


    ---------------------------------------------------------------------------
    -- Send notification of warning message U00023  -- < STATUS CHANGE SECTION (5) >
    ---------------------------------------------------------------------------
        SET @msg_id = 'U00023'
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
        -- Send notification of warning message U00001 -- Total Global HR Status Changes: @1
        ---------------------------------------------------------------------------
        SET @msg_id = 'U00019'
        SET @v_step_position = 'Log ' + RTRIM(@msg_id)

        SELECT @w_msg_text    = msg_text
            , @w_msg_text_2  = msg_text_2
            , @w_msg_text_3  = msg_text_3
            , @w_severity_cd = severity_cd
        FROM DBSCOMMON.dbo.message_master
        WHERE (msg_id = @msg_id)

        -- Get total new hire records from HCM
        SELECT @maxx = CAST(COUNT(*) AS varchar(6))
        FROM #ghr_employee_events_temp
        WHERE (event_id = @v_EVENT_ID_STATUS_CHANGE)

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

/*
INSERT DBShrpn.dbo.ghr_debug (text_line)
VALUES (@ErrorMessage)
, (' ');
*/

        -- Historical Message for reporting purpose
        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
              @p_msg_id             = @ErrorNumber
            , @p_event_id           = @v_EVENT_ID_STATUS_CHANGE
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
    -- there are temp tables in
    DROP TABLE #temp1
    DROP TABLE #temp2
    DROP TABLE #tbl_ghr_msg


    RETURN @v_ret_val

END
GO


ALTER AUTHORIZATION ON dbo.usp_ins_status_change TO  SCHEMA OWNER
GO

IF OBJECT_ID(N'dbo.usp_ins_status_change', N'P') IS NOT NULL
    PRINT N'<<< CREATED PROCEDURE dbo.usp_ins_status_change >>>'
ELSE
    PRINT N'<<< FAILED CREATING PROCEDURE dbo.usp_ins_status_change >>>'
GO