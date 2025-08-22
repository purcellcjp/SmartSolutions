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

CREATE PROCEDURE dbo.usp_ins_status_change
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

    DECLARE @v_EVENT_ID_STATUS_CHANGE       char(2)             = '05'
    DECLARE @v_END_OF_TIME_DATE             datetime            = '29991231'
    DECLARE @v_BEG_OF_TIME_DATE             datetime            = '19000101'

    DECLARE @v_ACTIVITY_STATUS_GOOD         char(2)             = '00'
    DECLARE @v_ACTIVITY_STATUS_WARNING      char(2)             = '01'
    DECLARE @v_ACTIVITY_STATUS_BAD          char(2)             = '02'

    DECLARE @ErrorMessage                   nvarchar(4000)
    DECLARE @ErrorSeverity                  int
    DECLARE @ErrorState                     int

    DECLARE @v_ret_val						int					= 0

    DECLARE @w_msg_text						varchar(255)
    DECLARE @w_msg_text_2					varchar(255)
    DECLARE @w_msg_text_3					varchar(255)
    DECLARE @w_severity_cd					tinyint
    DECLARE @w_fatal_error					bit     = 0         --char(01)
    DECLARE @w_curr_status_value            CHAR(10)

    DECLARE @special_value_exists			int
    DECLARE @individual_id					char(10)
    DECLARE @prior_last_name				char(30)
    DECLARE @w_status_change_date			datetime
    DECLARE	@w_previous_emp_id				char(15)
    DECLARE @w_job_end_date					datetime
    DECLARE @w_position_end_date			datetime
    DECLARE @w_todays_date					char(12)
    DECLARE @w_old_chgstamp					smallint
    DECLARE	@w_taxing_country_code			char(02)
    DECLARE	@w_curr_code					char(03)
    DECLARE @w_eff_date					    datetime
    DECLARE @w_curr_status					char(02)
    DECLARE	@w_pos_eff_date					datetime
    DECLARE @w_assigned_to_code             char(01)
    DECLARE @w_job_or_pos_id                char(10)
    DECLARE @w_pd_salary_tm_pd_id           char(05)
    DECLARE @old_eff_date					datetime

    DECLARE @pay_frequency_code		        char(05) = ''
    DECLARE @rehire_override			    CHAR(01)

    DECLARE @i_empl_id                      char(10),
            @i_emp_assignment_exists		char(01),
            @i_work_tm_code					char(01),
            @i_base_rate_tbl_id				char(10),
            @i_base_rate_tbl_entry_code		char(08),
            @i_pd_salary_tm_pd_id			char(05),
            @i_salary_change_type_code		char(05)

    DECLARE @i_emp_id						char(15)
    DECLARE @i_assigned_to_code				char(01)
    DECLARE @i_job_or_pos_id				char(10)
    DECLARE @i_eff_date						datetime
    DECLARE @i_next_eff_date				datetime
    DECLARE @i_prior_eff_date				datetime
    DECLARE @i_standard_work_pd_id			char(5)
    DECLARE @i_standard_work_hrs			float
    DECLARE @i_yearly_std_work_hrs			float
    DECLARE @i_hourly_rate_amt				money
    DECLARE @i_period_amt					money

    DECLARE @w_ee_eff_date					datetime

    DECLARE @max				INT
    DECLARE @maxx				CHAR(06)
    DECLARE @cnt				INT
    DECLARE @ind_id				INT
    DECLARE @ind_idx			CHAR(10)
    DECLARE @annual_salary		MONEY
    DECLARE @tax_entity_id		CHAR(10)
    DECLARE @display_name		CHAR(45)
    DECLARE @msg_id				CHAR(10)
    DECLARE @msg_p1				CHAR(15)
    DECLARE @msg_p2				CHAR(15)
    DECLARE @msg_cnt			INT



    -- This section declares the interface values from Global HR
    DECLARE	@event_id							    char(02)
          , @emp_id								    char(15)
          , @eff_date							    char(10)
          , @first_name							    char(25)
          , @first_middle_name					    char(25)
          , @last_name							    char(30)
          , @empl_id							    char(10)
          , @national_id_type_code				    char(05)
          , @national_id						    char(20)
          , @organization_group_id				    char(05)
          , @organization_chart_name			    varchar(64)
          , @organization_unit_name				    varchar(240)
          , @emp_status_classn_code				    char(02)
          , @position_title						    char(50)        -- DBShrpn..emp_assignment.user_text
          , @employment_type_code				    varchar(70)     -- increased size to 70 from 5
          , @annual_salary_amt					    char(15)
          , @begin_date							    char(10)
          , @end_date							    char(10)
          , @pay_status_code					    char(01)
          , @pay_group_id						    char(10)
          , @pay_element_ctrl_grp_id			    char(10)
          , @time_reporting_meth_code			    char(01)
          , @employment_info_chg_reason_cd		    char(05)
          , @emp_location_code					    char(10)
          , @emp_status_code					    char(02)
          , @reason_code						    char(02)
          , @emp_expected_return_date			    char(10)
          , @pay_through_date					    char(10)
          , @emp_death_date						    char(10)
          , @consider_for_rehire_ind			    char(01)
          , @pay_element_id					        char(10)
          , @emp_calculation						char(15)
          , @tax_flag                               char(1)         -- individual_personal.ind_2
          , @nic_flag                               char(1)         -- individual_personal.ind_1
          , @tax_ceiling_amt                        char(15)        -- employee.user_monetary_amt_1
          , @labor_grp_code                         char(5)         -- DBShrpn..emp_employment.labor_grp_code
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


    -- Used helper proc DBShrpn.dbo.usp_upd_hmpl_terminate
    CREATE TABLE #temp1
        (
         pay_element_id     char(10)    NULL
        )


    -- Used helper proc DBShrpn.dbo.usp_upd_hmpl_terminate
    CREATE TABLE #temp2
        (
          row_id                int         NULL
        , emp_id                char(15)    NULL
        , assigned_to_code      char(01)    NULL
        , job_or_pos_id		    char(10)    NULL
        , eff_date			    datetime    NULL
        , next_eff_date		    datetime    NULL
        , prior_eff_date		datetime    NULL
        , end_date 			    datetime    NULL
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
        WHERE (msg_id IN ('U00023'
                        ,'U00009'
                        ,'U00011'
                        ,'U00019'
                        ,'U00005'
                        ,'U00012'
                        ,'U00024'
                        ,'U00025'
                        ,'U00026'
                        ,'U00032'
                        ,'U00033'
                        ,'U00022'
                        ,'U00036'
                        ,'U00037'
                        ,'U00042'
                        ,'U00043'
                        ,'U00010'
                        ))

        -- ID Message templates that need to loop through errors to add to log table
        UPDATE #tbl_msg_master
        SET loop_flag = 'Y'
        WHERE (msg_id IN (
                         'U00005'
                        ,'U00012'
                        ,'U00024'
                        ,'U00025'
                        ,'U00026'
                        ,'U00032'
                        ,'U00033'
                        ,'U00022'
                        ,'U00036'
                        ,'U00037'
                        ,'U00042'
                        ,'U00043'
                        ))


       SET @v_step_position = 'Declaring cursor crsrHR'

        -- Loop through ghr_employee_events_temp to populate error message log entry
        DECLARE crsrHR CURSOR FAST_FORWARD FOR
        SELECT t.event_id
             , t.emp_id
             , t.eff_date
             , t.first_name
             , t.first_middle_name
             , t.last_name
             , t.empl_id
             , t.national_id_type_code
             , t.national_id
             , t.organization_group_id
             , ''       -- t.organization_chart_name
             , ''       -- t.organization_unit_name
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
             , t.pay_element_id
             , t.emp_calculation
             , t.tax_flag
             , t.nic_flag
             , t.tax_ceiling_amt
             , t.labor_grp_code
             , t.file_source
        FROM #ghr_employee_events_temp t
		WHERE (event_id = @v_EVENT_ID_STATUS_CHANGE)

        SET @v_step_position = 'Opening cursor crsrHR'
        OPEN crsrHR

        SET @v_step_position = 'Fetching cursor crsrHR'
        FETCH crsrHR
        INTO  @event_id
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
            , @annual_salary_amt
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
            , @pay_element_id
            , @emp_calculation
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
            --	Obtain the current status record
            ---------------------------------------------------------------------------
            -- using view
            SELECT @w_status_change_date = stat.status_change_date
                 , @w_old_chgstamp       = stat.chgstamp
                 , @w_curr_status        = stat.emp_status_code
                 , @w_curr_status_value  = CASE stat.emp_status_code
                                             WHEN 'A' THEN 'Active'
                                             WHEN 'I' THEN 'Inactive'
                                             WHEN 'T' THEN 'Terminated'
                                             ELSE ''
                                           END
            FROM DBShrpn.dbo.uvu_emp_status_most_rec stat
            WHERE (emp_id = @emp_id)


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
                            WHERE emp_id = @emp_id
                           )
                BEGIN

                    UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                        SET activity_status	= @v_ACTIVITY_STATUS_BAD
                    WHERE activity_date	=	@p_activity_date
                        AND emp_id		=	@emp_id
                        AND event_id		=	@v_EVENT_ID_STATUS_CHANGE


                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id As msg_id
                        , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                    FROM #tbl_msg_master t
                    WHERE (msg_id = @msg_id)


                    -- Historical Message for reporting purpose
                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                    SELECT  @msg_id						As msg_id,
                            @v_EVENT_ID_STATUS_CHANGE As event_id,
                            @emp_id 						As emp_id,
                            @eff_date					As eff_date,
                            @pay_element_id			As pay_element_id,
                            @emp_id						As msg_p1,
                            ''						        As msg_p2,
                            'Employee does not exist'		As msg_desc,
                            @p_activity_date				AS activity_date

                    SET @w_fatal_error = 1

                END


            ---------------------------------------------------------------------------
            -- Check to see if the employer exists
            ---------------------------------------------------------------------------
            SET @msg_id = 'U00005'
            SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

            IF NOT EXISTS (
                            SELECT *
                            FROM DBShrpn.dbo.employer
                            WHERE empl_id = @empl_id
                            )
                BEGIN

                    IF EXISTS (
                                SELECT *
                                FROM DBShrpn.dbo.employer
                                WHERE empl_id = '0' + @empl_id
                                )
                        SELECT @empl_id	= '0' + @empl_id
                    ELSE
                        BEGIN
                            UPDATE DBShrpn.dbo.ghr_employee_events_aud
                            SET activity_status	= @v_ACTIVITY_STATUS_BAD
                            WHERE activity_date	= @p_activity_date
                            AND emp_id		= @emp_id
                            AND event_id		= '01'

                            INSERT INTO #tbl_ghr_msg
                            SELECT @msg_id					    As msg_id
                                , REPLACE(REPLACE(t.msg_text, '@1', @empl_id), '@2', @emp_id) AS msg_desc
                            FROM #tbl_msg_master t
                            WHERE (msg_id = @msg_id)

                            -- Historical Message for reporting purpose
                            INSERT INTO DBShrpn.dbo.ghr_historical_message
                            SELECT  @msg_id					As msg_id,
                                    @v_EVENT_ID_STATUS_CHANGE					As event_id,
                                    @emp_id 					As emp_id,
                                    @eff_date				As eff_date,
                                    @pay_element_id		As pay_element_id,
                                    @emp_id					As msg_p1,
                                    @empl_id					As msg_p2,
                                    'Employer does not exists - defaulting 99999'	As msg_desc,
                                    @p_activity_date			AS activity_date
                            -- End of Historical Message for reporting purpose

                            SELECT @empl_id = '99999'

                        END
                END



            ---------------------------------------------------------------------------
            -- Check to see that the new record is greater than the existing record.
            ---------------------------------------------------------------------------
            SET @msg_id = 'U00037'
            SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

            IF  @w_status_change_date >= @eff_date
                BEGIN
                    UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                        SET activity_status	= @v_ACTIVITY_STATUS_BAD
                    WHERE activity_date	=	@p_activity_date
                        AND emp_id		=	@emp_id
                        AND event_id		=	@v_EVENT_ID_STATUS_CHANGE

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id					    As msg_id
                            , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                        FROM #tbl_msg_master t
                        WHERE (msg_id = @msg_id)

                    -- Historical Message for reporting purpose
                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                    SELECT  @msg_id						    As msg_id,
                            @v_EVENT_ID_STATUS_CHANGE						As event_id,
                            @emp_id 						As emp_id,
                            @eff_date					As eff_date,
                            @pay_element_id			As pay_element_id,
                            @emp_id						As msg_p1,
                            @emp_id						As msg_p2,
                            'New Status Effective date must be greater than current effective date.'	As msg_desc,
                            @p_activity_date				AS activity_date
                    -- End of Historical Message for reporting purpose

                    SET @w_fatal_error = 1

                END

            ---------------------------------------------------------------------------
            -- Check to see if the transfer date is greater than position effective date.
            ---------------------------------------------------------------------------
            SET @msg_id = 'U00036'
            SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

            SELECT @w_pos_eff_date = eff_date FROM DBShrpn.dbo.position WHERE pos_id = '99999'

            IF  @w_pos_eff_date > CAST(@eff_date AS datetime)
                BEGIN
                    UPDATE DBShrpn.dbo.ghr_employee_events_aud
                        SET activity_status	= @v_ACTIVITY_STATUS_BAD
                        WHERE activity_date	=	@p_activity_date
                        AND emp_id		=	@emp_id
                        AND event_id		=	@v_EVENT_ID_STATUS_CHANGE

                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id					    As msg_id
                        , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                    FROM #tbl_msg_master t
                    WHERE (msg_id = @msg_id)

                    -- Historical Message for reporting purpose
                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                    SELECT  @msg_id						    As msg_id,
                            @v_EVENT_ID_STATUS_CHANGE						As event_id,
                            @emp_id 						As emp_id,
                            @eff_date					As eff_date,
                            @pay_element_id			As pay_element_id,
                            @emp_id						As msg_p1,
                            @empl_id						As msg_p2,
                            'Transfer date must be greater than default position effective date'		As msg_desc,
                            @p_activity_date				AS activity_date
                        -- End of Historical Message for reporting purpose

                    SET @w_fatal_error = 1

                    -- GOTO BYPASS_EMPLOYEE

                END

            ---------------------------------------------------------------------------
            -- Check to see if the rehire date is greater than employee employment effective date.
            ---------------------------------------------------------------------------
            SET @msg_id = 'U00043'
            SET @v_step_position = 'Begin ' + RTRIM(@msg_id)


            SELECT @w_ee_eff_date = eff_date
            FROM DBShrpn.dbo.uvu_emp_employment_most_rec ee
            WHERE (ee.emp_id = @emp_id)

            IF  @w_ee_eff_date >= CAST(@eff_date AS datetime)
                BEGIN

                    UPDATE DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status = @v_ACTIVITY_STATUS_BAD
                    WHERE activity_date = @p_activity_date
                    AND emp_id     = @emp_id
                    AND event_id   = @v_EVENT_ID_STATUS_CHANGE

                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id					    As msg_id
                        , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                    FROM #tbl_msg_master t
                    WHERE (msg_id = @msg_id)

                    -- Historical Message for reporting purpose
                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                    SELECT  @msg_id						    As msg_id,
                            @v_EVENT_ID_STATUS_CHANGE						As event_id,
                            @emp_id 						As emp_id,
                            @eff_date					As eff_date,
                            @pay_element_id			As pay_element_id,
                            @emp_id						As msg_p1,
                            @empl_id						As msg_p2,
                            'Rehire date must be greater than current employee employment effective date'		As msg_desc,
                            @p_activity_date				AS activity_date
                    -- End of Historical Message for reporting purpose

                    SET @w_fatal_error = 1

                    -- GOTO BYPASS_EMPLOYEE

                END


            ---------------------------------------------------------------------------
            --	Check to see if pay group id exists
            ---------------------------------------------------------------------------
            SET @msg_id = 'U00020'
            SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

            IF NOT EXISTS(
                        SELECT *
                        FROM	DBShrpn.dbo.pay_group
                        WHERE	pay_group_id = @pay_group_id
                        )
                BEGIN

                    UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status	= @v_ACTIVITY_STATUS_BAD
                    WHERE activity_date	=	@p_activity_date
                    AND emp_id		=	@emp_id
                    AND event_id		=	'01'

                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id					As msg_id
                         , REPLACE(REPLACE(t.msg_text, '@1', @pay_group_id), '@2', @emp_id) AS msg_desc
                    FROM #tbl_msg_master t
                    WHERE (msg_id = @msg_id)


                    -- Historical Message for reporting purpose
                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                    SELECT  @msg_id					As msg_id,
                            @v_EVENT_ID_STATUS_CHANGE					As event_id,
                            @emp_id 					As emp_id,
                            @eff_date				As eff_date,
                            @pay_element_id		As pay_element_id,
                            @emp_id					As msg_p1,
                            @pay_group_id			As msg_p2,
                            'Pay Group does not exists'	As msg_desc,
                            @p_activity_date			AS activity_date
                    -- End of Historical Message for reporting purpose

                    SET	@pay_group_id = ' '

                    SET @w_fatal_error = 1

                END



            ---------------------------------------------------------------------------
            ---------------------------------------------------------------------------
            -- Validate the important fields in this section.
            ---------------------------------------------------------------------------
            ---------------------------------------------------------------------------


            ---------------------------------------------------------------------------
            --	Check to see if the rehire date is greater than the termination date. Reject the record
            ---------------------------------------------------------------------------
            SET @msg_id = 'U00032'
            SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

            IF	@emp_status_code = 'RH'
                BEGIN
                    IF @w_curr_status = 'T' AND @w_eff_date <= @w_status_change_date
                        BEGIN

                            UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                            SET activity_status	= @v_ACTIVITY_STATUS_BAD
                            WHERE activity_date	=	@p_activity_date
                            AND emp_id		=	@emp_id

                            INSERT INTO #tbl_ghr_msg
                            SELECT @msg_id      As msg_id
                                 , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                            FROM #tbl_msg_master t
                            WHERE (msg_id = @msg_id)

                            -- Historical Message for reporting purpose
                            INSERT INTO DBShrpn.dbo.ghr_historical_message
                            SELECT  @msg_id						    As msg_id,
                                    @v_EVENT_ID_STATUS_CHANGE As event_id,
                                    @emp_id 						As emp_id,
                                    @eff_date					As eff_date,
                                    @pay_element_id			As pay_element_id,
                                    @emp_id						As msg_p1,
                                    @emp_id						As msg_p2,
                                    'The rehire date must be greater than the termination date - By passing the employee.'	 As msg_desc,
                                    @p_activity_date				AS activity_date
                            -- End of Historical Message for reporting purpose

                            SET @w_fatal_error = 1

                        END
                END

            ---------------------------------------------------------------------------
            --	Check to see if the reactivation date is greater than the inactivation date. Reject the record
            ---------------------------------------------------------------------------
            SET @msg_id = 'U00033'
            SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

            IF	@emp_status_code = 'RA'
                BEGIN
                    IF @w_curr_status = 'I' AND @w_eff_date <= @w_status_change_date
                        BEGIN
                            UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                            SET activity_status	= @v_ACTIVITY_STATUS_BAD
                            WHERE activity_date	=	@p_activity_date
                            AND emp_id		=	@emp_id

                            INSERT INTO DBShrpn.dbo.ghr_msg_tbl
                            SELECT @msg_id					    As msg_id,
                                    @emp_id					As msg_p1,
                                    @emp_id					As msg_p2,
                                    'The Reactivation date must be greater than the inactivation date - By passing the employee.'	As msg_desc

                            -- Historical Message for reporting purpose
                            INSERT INTO DBShrpn.dbo.ghr_historical_message
                            SELECT  @msg_id						    As msg_id,
                                    @v_EVENT_ID_STATUS_CHANGE						As event_id,
                                    @emp_id 						As emp_id,
                                    @eff_date					As eff_date,
                                    @pay_element_id			As pay_element_id,
                                    @emp_id						As msg_p1,
                                    @emp_id						As msg_p2,
                                    'The Reactivation date must be greater than the inactivation date - By passing the employee.'	 As msg_desc,
                                    @p_activity_date				AS activity_date
                            -- End of Historical Message for reporting purpose

                            SET @w_fatal_error = 1

                        END
                END

            -- Skip record if errors encountered
            IF (@w_fatal_error = 1)
                GOTO BYPASS_EMPLOYEE

            ---------------------------------------------------------------------------
            ---------------------------------------------------------------------------
            --	Obtain the setup variables
            ---------------------------------------------------------------------------
            ---------------------------------------------------------------------------

            ---------------------------------------------------------------------------
            -- Determine Emp Assignment Position - Not provided by HCM
            ---------------------------------------------------------------------------
            -- Added here to allow validate of value in case not setup in SS

            SET @v_step_position = 'Begin Emp Assignment Position'

            -- Based on server and employer
            -- source field has been added to input file
            IF (CHARINDEX('VENUS', @@SERVERNAME) > 0)
                IF EXISTS(
                        SELECT 1
                        FROM DBShrpn.dbo.employer
                        WHERE empl_id = @empl_id
                            AND (name LIKE 'PEN%')
                        )
                    SET @w_job_or_pos_id = 'PEN-0001'
                ELSE
                    SET @w_job_or_pos_id = 'GEN-0001'
            ELSE   -- Ganymede FORTHCM
                SET @w_job_or_pos_id = 'FORT-0001'


            ---------------------------------------------------------------------------
            -- Find the tax entity
            ---------------------------------------------------------------------------
            SELECT @tax_entity_id = tax_entity_id
            FROM DBShrpn.dbo.empl_tax_entity
            WHERE empl_id = @empl_id


            ---------------------------------------------------------------------------
            --	Find the Job_position end date and Assignment end date
            ---------------------------------------------------------------------------
            SELECT	@w_position_end_date		=	@v_END_OF_TIME_DATE
            SELECT	@w_job_end_date				=	@v_END_OF_TIME_DATE



            ---------------------------------------------------------------------------
            --	Obtain prior employee number
            ---------------------------------------------------------------------------
            SELECT @w_previous_emp_id = prior_emp_id
            FROM employee, emp_status
            WHERE employee.emp_id				=	@emp_id
            AND emp_status.emp_id				=	@emp_id
            AND emp_status.status_change_date	<=	@w_todays_date
            AND emp_status.next_change_date	>	@w_todays_date

            IF	@w_previous_emp_id = ' '
                SELECT	@w_previous_emp_id	=	@emp_id


            SELECT	@w_taxing_country_code		=	e.taxing_country_code,
                    @w_curr_code				=	e.curr_code
            FROM	DBShrpn.dbo.employer e
            WHERE  e.empl_id	=	@empl_id

            --
            --
            --
            SELECT	@w_eff_date = CAST(@eff_date	As datetime)

            --
            --
            --	Perform the main logic
            --
            --
            IF (@emp_status_code = 'RH')
                BEGIN


                    IF (@w_curr_status = 'T')
                        BEGIN

                            SET @v_step_position = 'Rehire RH ' + @w_curr_status

                            SELECT	@i_eff_date = ea.eff_date
                            FROM DBShrpn.dbo.emp_assignment	ea
                            WHERE emp_id  = @emp_id
                            AND  prime_assignment_ind	=	'Y'
                            AND  eff_date = (
                                            SELECT MAX(eff_date)
                                            FROM DBShrpn.dbo.emp_assignment t
                                            WHERE (t.emp_id =	ea.emp_id)
                                            AND (prime_assignment_ind = 'Y')
                                            )


                            EXECUTE DBShrpn.dbo.usp_upd_hmpl_rehire
                                @p_emp_id                       =	@emp_id,
                                @p_previous_emp_id				=	@w_previous_emp_id,
                                @p_status_change_date			=	@w_status_change_date,
                                @p_new_empl_id					=	@empl_id,
                                @p_new_tax_entity_id			=	@tax_entity_id,
                                @p_new_hire_date				=	@w_eff_date,
                                @p_new_classn_cd				=	@emp_status_classn_code,
                                @p_new_reason_cd				=	' ',
                                @p_new_assigned_to_code			=	@w_assigned_to_code,
                                @p_new_job_or_pos_id			=   @w_job_or_pos_id,
                                @p_new_pay_group_id				=	@pay_group_id,
                                @p_new_time_reporting_meth		=	@time_reporting_meth_code,
                                @p_job_end_date					=	@w_job_end_date,							--	datetime,			--'29991231'
                                @p_position_end_date			=	@w_position_end_date,						--	datetime,			--'29991231'
                                @p_taxing_country              	=	@w_taxing_country_code,						--	char(2),			--'GD'
                                @p_new_pay_elem_ctrl_grp_id		=	@pay_element_ctrl_grp_id,				--	'MTH'
                                @p_allow_pay_updates_ind		=	'Y',
                                @p_old_chgstamp					=	@w_old_chgstamp								--	0

                            EXECUTE DBShrpn.dbo.usp_ins_hpcg_hepy
                                @p_emp_id                       =	@emp_id,
                                @p_empl_id                      =	@empl_id,
                                @p_new_pay_group_id             =	@pay_group_id,
                                @p_new_pecg_id					=	@pay_element_ctrl_grp_id,
                                @p_as_of_date					=	@w_eff_date


                            ---------------------------------------------------------------------------
                            ---------------------------------------------------------------------------
                            --	Obtain the current record for this employee assignment
                            ---------------------------------------------------------------------------
                            ---------------------------------------------------------------------------


                            ---------------------------------------------------------------------------
                            --	Update the Salary and Position Title in the Assignment Record
                            ---------------------------------------------------------------------------


                            SELECT	@i_emp_id				=	emp_id,
                                    @i_assigned_to_code		=	assigned_to_code,
                                    @i_job_or_pos_id		=	job_or_pos_id,
                                    @i_eff_date				=	eff_date,
                                    @i_next_eff_date		=	next_eff_date,
                                    @i_prior_eff_date		=	prior_eff_date
                            FROM DBShrpn.dbo.emp_assignment	ea
                            WHERE emp_id =	@emp_id
                            AND prime_assignment_ind	=	'Y'
                            AND eff_date = (
                                            SELECT MAX(eff_date)
                                            FROM	DBShrpn.dbo.emp_assignment t
                                            WHERE	t.emp_id =	ea.emp_id
                                                AND prime_assignment_ind = 'Y'
                                            )

                            -- GOSL: HCM Salary data will not be extracted to SS
                            -- Blank them out
                            SELECT @annual_salary				=	0.00
                                , @i_hourly_rate_amt			=	0.00
                                , @i_period_amt				=	0.00
                                , @i_salary_change_type_code	=	''
                                , @i_work_tm_code				=	''
                                , @i_base_rate_tbl_id			=	''
                                , @i_base_rate_tbl_entry_code	=	''
                                , @i_standard_work_pd_id		=	''
                                , @i_standard_work_hrs		    =	0.00
                                , @i_pd_salary_tm_pd_id		=	''



                            UPDATE DBShrpn.dbo.emp_assignment
                            SET   annual_salary_amt        = CAST(@annual_salary_amt AS MONEY)
                                , hourly_pay_rate          = @i_hourly_rate_amt
                                , pd_salary_amt            = @i_period_amt
                                , salary_change_type_code  = @i_salary_change_type_code
                                , work_tm_code             = @i_work_tm_code
                                , base_rate_tbl_id         = @i_base_rate_tbl_id
                                , base_rate_tbl_entry_code = @i_base_rate_tbl_entry_code
                                , pd_salary_tm_pd_id       = @pay_frequency_code
                                , standard_work_pd_id      = @i_standard_work_pd_id
                                , standard_work_hrs        = @i_standard_work_hrs
                                , organization_group_id    = CAST(@organization_group_id AS INT)
                                , organization_chart_name  = @organization_chart_name
                                , organization_unit_name   = @organization_unit_name
                                , user_text_2              = @position_title
                            WHERE emp_id         = @i_emp_id
                            AND assigned_to_code = @i_assigned_to_code
                            AND job_or_pos_id    = @i_job_or_pos_id
                            AND eff_date         = @i_eff_date
                            AND next_eff_date    = @i_next_eff_date
                            AND prior_eff_date   = @i_prior_eff_date


                        END
                    ELSE    -- Associate Not terminated
                        BEGIN
                            SET @msg_id = 'U00022'
                            SET @v_step_position = 'Rehire Not Terminated ' + RTRIM(@msg_id)

                            UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                            SET activity_status	= @v_ACTIVITY_STATUS_BAD
                            WHERE activity_date	=	@p_activity_date
                            AND emp_id		=	@emp_id
                            AND event_id		= @v_EVENT_ID_STATUS_CHANGE

                                    INSERT INTO #tbl_ghr_msg
                                    SELECT @msg_id					    As msg_id
                                        , REPLACE(REPLACE(t.msg_text, '@1', RTRIM(@w_curr_status_value)), '@2', @emp_id) AS msg_desc
                                    FROM #tbl_msg_master t
                                    WHERE (msg_id = @msg_id)

                            -- Historical Message for reporting purpose
                            INSERT INTO DBShrpn.dbo.ghr_historical_message
                            SELECT  @msg_id						    As msg_id,
                                    @v_EVENT_ID_STATUS_CHANGE As event_id,
                                    @emp_id 						As emp_id,
                                    @eff_date					As eff_date,
                                    @pay_element_id			As pay_element_id,
                                    @w_curr_status					As msg_p1,
                                    @emp_id						As msg_p2,
                                    'The current status is ' + RTRIM(@w_curr_status_value) + '.' + ' Cannot rehire an employee if the current status is not terminated.'	 As msg_desc,
                                    @p_activity_date				AS activity_date


                        END
                END  -- End of RH Logic


            IF (@emp_status_code = 'I')
                BEGIN
                    SET @v_step_position = 'Begin Inactive'

                    IF (@w_curr_status = 'A')
                        BEGIN

                            SET @v_step_position = @v_step_position + ' - Active'

                            EXECUTE DBShrpn.dbo.usp_upd_hmpl_inactivate	@p_emp_id	=	@emp_id,
                                @p_status_change_date			=	@w_status_change_date,
                                @p_inactivate_date				=	@w_eff_date,
                                @p_new_reason					=	' ',
                                @p_new_loa_expd_date			=	@v_END_OF_TIME_DATE,
                                @p_new_classification_cd		=	@emp_status_classn_code,
                                @p_allow_emp_pay_updates_ind	=	'Y',
                                @p_pay_status_code				=	@pay_status_code,
                                @p_last_day_paid				=	@v_BEG_OF_TIME_DATE,
                                @p_old_chgstamp				=	@w_old_chgstamp

                        END
                    ELSE
                        BEGIN
                            SET @msg_id = 'U00024'
                            SET @v_step_position = @v_step_position + ' - ' + @w_curr_status + ' - ' + RTRIM(@msg_id)

                            UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                            SET activity_status	=	@v_ACTIVITY_STATUS_BAD
                            WHERE activity_date	=	@p_activity_date
                            AND emp_id		=	@emp_id

                            INSERT INTO #tbl_ghr_msg
                            SELECT @msg_id      As msg_id
                                , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                            FROM #tbl_msg_master t
                            WHERE (msg_id = @msg_id)


                            -- Historical Message for reporting purpose
                            INSERT INTO DBShrpn.dbo.ghr_historical_message
                            SELECT  @msg_id						    As msg_id,
                                    @v_EVENT_ID_STATUS_CHANGE						As event_id,
                                    @emp_id 						As emp_id,
                                    @eff_date					As eff_date,
                                    @pay_element_id			As pay_element_id,
                                    @w_curr_status					As msg_p1,
                                    @emp_id						As msg_p2,
                                    'The current status is ' + RTRIM(@w_curr_status_value) + '.' + ' Cannot inactivate an employee if the current status is not active.'	 As msg_desc,
                                    @p_activity_date				AS activity_date
                            -- End of Historical Message for reporting purpose

                        END
                END  -- End of Inactivate Logic


            IF (@emp_status_code = 'T')
                BEGIN

                    SET @v_step_position = 'Termination'

                    IF (@w_curr_status IN ('A','I'))
                        BEGIN

                            SET @v_step_position = @v_step_position + ' (''A'') or (''I'')'

                            SELECT @pay_status_code = eempl.pay_status_code
                                , @old_eff_date     = eempl.eff_date
                            FROM DBShrpn.dbo.uvu_emp_employment_most_rec eempl
                            WHERE (emp_id = @emp_id)


                            -- Note: proc needs temp tables #temp1 and #temp2 to work
                            EXECUTE DBShrpn.dbo.usp_upd_hmpl_terminate
                                @p_emp_id                       =	@emp_id,
                                @p_status_change_date           =	@w_status_change_date,
                                @p_termination_date             =	@w_eff_date,
                                @p_new_classn_cd                =	@emp_status_classn_code,
                                @p_date_of_death                =	@v_END_OF_TIME_DATE,
                                @p_new_reason_code              =	@reason_code,
                                @p_new_pay_through_date         =	@w_eff_date,
                                @p_new_rehire_conson            =	@consider_for_rehire_ind,
                                @p_pay_status_code              =	@pay_status_code,
                                @p_last_day_paid                =	@v_BEG_OF_TIME_DATE,
                                @p_old_chgstamp                 =	@w_old_chgstamp



                            --  New Record Update to resolve conflict with the rehire date
                            UPDATE DBShrpn.dbo.emp_employment
                            SET pay_status_code = @pay_status_code
                              , eff_date        = @w_eff_date
                            WHERE (emp_id        = @emp_id)
                              AND (next_eff_date = @v_END_OF_TIME_DATE)

                            --  Update prior record to point to the new record.
                            UPDATE DBShrpn.dbo.emp_employment
                            SET next_eff_date = @w_eff_date
                            WHERE (emp_id   = @emp_id)
                              AND (eff_date = @old_eff_date)

                        END
                    ELSE
                        BEGIN
                            SET @msg_id = 'U00042'
                            SET @v_step_position = @v_step_position + ' (''T'') ' + @msg_id

                            UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                            SET activity_status	=	@v_ACTIVITY_STATUS_BAD
                            WHERE activity_date	=	@p_activity_date
                            AND emp_id		=	@emp_id
                            AND event_id		=	@v_EVENT_ID_STATUS_CHANGE

                            INSERT INTO #tbl_ghr_msg
                            SELECT @msg_id						As msg_id
                                , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                            FROM #tbl_msg_master t
                            WHERE (msg_id = @msg_id)

                            -- Historical Message for reporting purpose
                            INSERT INTO DBShrpn.dbo.ghr_historical_message
                            SELECT  @msg_id						    As msg_id,
                                    @v_EVENT_ID_STATUS_CHANGE						As event_id,
                                    @emp_id 						As emp_id,
                                    @eff_date					As eff_date,
                                    @pay_element_id			As pay_element_id,
                                    @w_curr_status					As msg_p1,
                                    @emp_id						As msg_p2,
                                    'The current status is ' + RTRIM(@w_curr_status_value) + '.' + ' Cannot terminate an employee if the current status is not active or inactive.'	 As msg_desc,
                                    @p_activity_date				AS activity_date
                            -- End of Historical Message for reporting purpose

                        END

                END  -- End of Terminate Logic


            ---------------------------------------------------------------------------
            -- Override the message if this cycle contains an employee rehire record
            ---------------------------------------------------------------------------
            IF  EXISTS (
                        SELECT *
                        FROM #ghr_employee_events_temp ee
                        WHERE event_id = @v_EVENT_ID_STATUS_CHANGE
                        AND ee.emp_id = @emp_id
                        AND emp_status_code = 'RH'
                    )
                SET @rehire_override = '1'
            ELSE
                SET @rehire_override = '0'

            --
            --
            --

            IF	(@emp_status_code = 'RA')
                BEGIN --1

                    IF @w_curr_status = 'I'
                        BEGIN  --2
                            SET @v_step_position = 'Rehire RA Inactive'

                            EXECUTE DBShrpn.dbo.usp_upd_hmpl_reactivate	@p_emp_id	=	@emp_id,
                                @p_status_change_date				=	@w_status_change_date,
                                @p_reactivate_date					=	@w_eff_date,
                                @p_new_reason						=	@reason_code,
                                @p_new_classification_cd			=	@emp_status_classn_code,
                                @p_allow_emp_pay_updates_ind		=	'Y',
                                @p_pay_status_code					=	@pay_status_code,
                                @p_old_chgstamp					    =	@w_old_chgstamp

                        END  --2
                    ELSE
                        BEGIN --3
                            IF @rehire_override = '0'
                                BEGIN  --4

                                    SET @msg_id = 'U00025'
                                    SET @v_step_position = 'Rehire Overide - ''0'' - ' + @msg_id

                                    UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                                    SET activity_status	=	@v_ACTIVITY_STATUS_BAD
                                    WHERE activity_date	=	@p_activity_date
                                    AND emp_id		=	@emp_id
                                    AND event_id		=	@v_EVENT_ID_STATUS_CHANGE

                                    INSERT INTO #tbl_ghr_msg
                                    SELECT @msg_id						As msg_id
                                        , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                                    FROM #tbl_msg_master t
                                    WHERE (msg_id = @msg_id)

                                    -- Historical Message for reporting purpose
                                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                                    SELECT  @msg_id						As msg_id,
                                            @v_EVENT_ID_STATUS_CHANGE							As event_id,
                                            @emp_id 						As emp_id,
                                            @eff_date					As eff_date,
                                            @pay_element_id			As pay_element_id,
                                            @w_curr_status					As msg_p1,
                                            @emp_id						As msg_p2,
                                            -- 'Cannot Reactivate an employee if the current status is not inactivate.'	 As msg_desc,
                                            'The current status is ' + RTRIM(@w_curr_status_value) + '.' + ' Cannot Reactivate an employee if the current status is not inactivate.'  As msg_desc,
                                            @p_activity_date				AS activity_date
                                    -- End of Historical Message for reporting purpose
                                END	 --4
                            ELSE
                                BEGIN --5

                                    SET @v_step_position = 'Rehire RA - ' + @w_curr_status + ' - ' + 'Activity Status ''' + @v_ACTIVITY_STATUS_WARNING + ''''

                                    UPDATE DBShrpn.dbo.ghr_employee_events_aud
                                    SET activity_status	=   @v_ACTIVITY_STATUS_WARNING
                                    WHERE activity_date	=	@p_activity_date
                                    AND emp_id		=	@emp_id
                                    AND event_id		=	@v_EVENT_ID_STATUS_CHANGE
                                    AND emp_status_code=   'RA'

                                END  --5
                        END --3
                END --1  -- End of Reactivate Logic

            --
            -- Update the position since could be a new position
            --
            SELECT @individual_id = individual_id
            FROM DBShrpn.dbo.employee
            WHERE emp_id = @emp_id

            IF (@emp_status_code = 'RH')
                BEGIN

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
                    -- GOSL update Tax Ceiling Amount
                    ---------------------------------------------------------------------------
                    SET @v_step_position = 'Update Tax Ceiling'

                    UPDATE DBShrpn.dbo.employee
                    SET user_monetary_amt_1 = @tax_ceiling_amt
                    WHERE (emp_id = @emp_id)


                END



BYPASS_EMPLOYEE:

            FETCH crsrHR
            INTO  @event_id
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
                , @annual_salary_amt
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
                , @pay_element_id
                , @emp_calculation
                , @tax_flag
                , @nic_flag
                , @tax_ceiling_amt
                , @labor_grp_code
                , @file_source

        END  -- Error Loop

      -- Cleanup Cursor
      CLOSE crsrHR
      DEALLOCATE crsrHR


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
        -- Send notification of warning message U00001 -- Total Global HR Status Changes: @1
        ---------------------------------------------------------------------------
        SET @msg_id = 'U00019'
        SET @v_step_position = 'Log ' + RTRIM(@msg_id)

        SELECT @w_msg_text    = msg_text
            , @w_msg_text_2  = msg_text_2
            , @w_msg_text_3  = msg_text_3
            , @w_severity_cd = severity_cd
        FROM #tbl_msg_master
        WHERE (msg_id = @msg_id)

        -- Get total new hire records from HCM
        SELECT @maxx = CAST(COUNT(*) AS varchar(6))
        FROM #ghr_employee_events_temp
        WHERE (event_id = @v_EVENT_ID_STATUS_CHANGE)

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
    -- there are temp tables in
    DROP TABLE #temp1
    DROP TABLE #temp2
    DROP TABLE #tbl_ghr_msg
    DROP TABLE #tbl_msg_master


END
GO


ALTER AUTHORIZATION ON dbo.usp_ins_status_change TO  SCHEMA OWNER
GO

IF OBJECT_ID(N'dbo.usp_ins_status_change', N'P') IS NOT NULL
    PRINT N'<<< CREATED PROCEDURE dbo.usp_ins_status_change >>>'
ELSE
    PRINT N'<<< FAILED CREATING PROCEDURE dbo.usp_ins_status_change >>>'
GO