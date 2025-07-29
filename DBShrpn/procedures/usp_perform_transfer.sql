USE DBShrpn
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'dbo.usp_perform_transfer', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_perform_transfer
    IF OBJECT_ID(N'dbo.usp_perform_transfer') IS NOT NULL
        PRINT N'<<< FAILED DROPPING PROCEDURE dbo.usp_perform_transfer >>>'
    ELSE
        PRINT N'<<< DROPPED PROCEDURE dbo.usp_perform_transfer >>>'
END
GO

CREATE PROCEDURE dbo.usp_perform_transfer
(
	@p_userid						varchar(30),
	@p_batchname					varchar(08),
	@p_qualifier					varchar(30),
    @p_activity_date				datetime,
    @p_user_id						varchar(30),
	@p_activity_status				char(02),
	@p_status						int  output
)
AS


BEGIN

    SET NOCOUNT ON

    DECLARE @v_step_position                varchar(255)        = 'Begin Procedure'

    DECLARE @v_EVENT_ID_SALARY_CHANGE       char(2)             = '02'
    DECLARE @v_EVENT_ID_TRANSFER            char(2)             = '03'
    DECLARE @v_EVENT_ID_STATUS_CHANGE       char(2)             = '05'
    DECLARE @v_END_OF_TIME_DATE             datetime            = '29991231'

    DECLARE @ErrorMessage                   nvarchar(4000)
    DECLARE @ErrorSeverity                  int
    DECLARE @ErrorState                     int

    DECLARE @v_ret_val int
    --DECLARE @p_activity_date				datetime
    --DECLARE @p_userid						varchar(30)
    --DECLARE @p_batchname					varchar(08)
    --DECLARE @p_qualifier					varchar(30)
    --DECLARE @p_user_id					varchar(30)
    --DECLARE @p_activity_status			char(02)
    --DECLARE @p_status						int
    DECLARE @w_msg_text						varchar(255)
    DECLARE @w_msg_text_2					varchar(255)
    DECLARE @w_msg_text_3					varchar(255)
    DECLARE @w_severity_cd					tinyint
    DECLARE @w_fatal_error					char(01)

    DECLARE @special_value_exists			int
    DECLARE @individual_id					char(10)
    DECLARE @prior_last_name				char(30)
    DECLARE	@pos_eff_date					datetime

    DECLARE @ea_emp_id					CHAR(15)
    DECLARE @ea_assigned_to_code		CHAR(01)
    DECLARE @ea_job_or_pos_id			CHAR(10)
    DECLARE @ea_eff_date				DATETIME
    DECLARE	@ea_next_eff_date			DATETIME
    DECLARE	@ea_prior_eff_date			DATETIME
    DECLARE @rehire_override			CHAR(01)


    DECLARE @i_empl_id                      char(10),
            @i_emp_employment_exists		char(01),
            @i_work_tm_code					char(01),
            @i_base_rate_tbl_id				char(10),
            @i_base_rate_tbl_entry_code		char(08),
            @i_pd_salary_tm_pd_id			char(05)

    --
    -- Activate these fields when testing this program standalone.
    --

    --SET @p_userid			=	'DBS'
    --SET @p_batchname		=	'GHR'
    --SET @p_qualifier		=	'INTERFACES'
    --SET @p_activity_date	=	'2021-09-10'
    --SET @p_user_id		=	'JGROSS'
    --SET @p_activity_status=	'00'
    --SET @p_status			=	0



    DECLARE @max							INT
    DECLARE @maxx							CHAR(06)
    DECLARE @cnt							INT
    DECLARE @ind_id							INT
    DECLARE @ind_idx						CHAR(10)
    DECLARE @annual_salary					MONEY
    DECLARE @tax_entity_id					CHAR(10)
    DECLARE @display_name					CHAR(45)
    DECLARE @msg_id							CHAR(10)
    DECLARE @msg_p1							CHAR(15)
    DECLARE @msg_p2							CHAR(15)
    DECLARE @msg_cnt						INT
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


    DECLARE	@emp_status_code				CHAR(1)


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
          , @position_title_01						char(60)
          , @employment_type_code_01				char(05)
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


    -- Setup the variables for the first sp: hsp_upd_hrpn_02
	DECLARE @p_emp_id								char(15)
	DECLARE @p_old_empl_id							char(10)
	DECLARE @p_new_empl_id							char(10)
	DECLARE @p_transfer_date						datetime
	DECLARE @p_assign_to							char(1)
	DECLARE @p_job_or_pos_id						char(10)
	DECLARE @p_org_grp_id							int
	DECLARE @p_org_chart_name						varchar(64)
	DECLARE @p_org_unit_name						varchar(240)
	DECLARE @p_location								char(10)
	DECLARE @p_new_tax_entity_id					char(10)
	DECLARE @p_old_tax_entity_id					char(10)
	DECLARE @p_eff_date								datetime
	DECLARE @p_pay_group							char(10)
	DECLARE @p_emp_info_change_reason				char(5)
	DECLARE @p_job_position_end_date				datetime
	DECLARE @p_assignment_end_date					datetime
	DECLARE @p_xfer_different_taxing_cntry			char(1)
	DECLARE @p_new_empl_taxing_country_cd			char(2)
	DECLARE @p_new_empl_curr_code					char(3)
	DECLARE @p_use_policy_xfer_options				char(1)

    -- Transfer Varaibles
	DECLARE @old_entity								CHAR(10)
	DECLARE @old_tax_entity							CHAR(10)
	DECLARE @eff_date								datetime
	DECLARE @new_tax_entity							CHAR(10)
	DECLARE	@assignment_end_date					datetime
	DECLARE	@job_position_end_date					datetime
	DECLARE @assigned_to_code						char(01)
	DECLARE	@new_taxing_country_code				char(02)
	DECLARE	@new_curr_code							char(03)

    -- Setup the variables for the second sp: hsp_ins_hpep_02
	DECLARE @p_calendar_year						smallint
	DECLARE @p_curr_code							char(03)   --@p_new_empl_curr_code
	DECLARE @p_return_to_prior_empl					char(01)   --'N'
	DECLARE @p_empl_adj_paymnt_run_type				char(10)  --'#ADJUSTMNT'
	DECLARE @p_system_user_id						char(10)  --'jgross'
	DECLARE @p_pay_group_id							char(10)  --@p_pay_group


    CREATE TABLE #tbl_ghr_msg
        (
          msg_id                                    char(15)            NOT NULL
        , msg_p1                                    varchar(255)        NOT NULL
        , msg_p2                                    varchar(255)        NOT NULL
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
        WHERE (msg_id IN ('U00017'
                         ,'U00009'
                         ,'U00011'
                         ,'U00018'
                         ,'U00012'
                         ,'U00027'
                         ,'U00036'
                         ,'U00034'
                         ,'U00038'
                         ,'U00039'
                         ,'U00044'
                         ,'U00045'
                         ,'U00010'
                        ))

        -- ID Message templates that need to loop through errors to add to log table
        UPDATE #tbl_msg_master
        SET loop_flag = 'Y'
        WHERE (msg_id IN ('U00012'
                         ,'U00027'
                         ,'U00036'
                         ,'U00034'
                         ,'U00038'
                         ,'U00039'
                         ,'U00044'
                         ,'U00045'
                        ))


        SET @v_step_position = 'Declaring cursor crsrHR'

        -- Loop through tbl_ghr_msg to populate error message log entry
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
             , t.organization_chart_name_01
             , t.organization_unit_name_01
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
		WHERE (event_id_01 = @v_EVENT_ID_TRANSFER)

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

            SET  @w_fatal_error = '0'

            ---------------------------------------------------------------------------
            --	Find missing values for the fields below
            ---------------------------------------------------------------------------


            ---------------------------------------------------------------------------
            -- Override the message if this cycle contains an employee rehire record
            ---------------------------------------------------------------------------
            IF  EXISTS (
                        SELECT 1
                        FROM DBShrpn.dbo.ghr_employee_events
                        WHERE event_id_01 = @v_EVENT_ID_STATUS_CHANGE
                          AND emp_id_01 = @emp_id_01
                          AND emp_status_code_5 = 'RH'
                       )
                SELECT @rehire_override = '1'
            ELSE
                SELECT @rehire_override = '0'


            ---------------------------------------------------------------------------
            -- Check to see if the employee current status is terminated and look ahead for Rehire record.
            ---------------------------------------------------------------------------
            SET @v_step_position = 'Validation - Emp Status Check'
            -- DO I NEED TO ADD LOG ERROR MESSAGE ????

            SELECT @emp_status_code	=  emp_status_code
            FROM DBShrpn.dbo.emp_status s
            WHERE s.emp_id = @emp_id_01
            AND s.status_change_date = (
                                        SELECT MAX(t.status_change_date)
                                        FROM DBShrpn.dbo.emp_status t
                                        WHERE t.emp_id = s.emp_id
                                       )

            IF (@emp_status_code = 'T')
            BEGIN
                IF (@rehire_override = '1')
                BEGIN

                    UPDATE DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status	= '99'
                    WHERE activity_date	=	@p_activity_date
                      AND emp_id_01		=	@emp_id_01
                      AND event_id_01		= @v_EVENT_ID_TRANSFER

                    SET @w_fatal_error = '5'

                END
            END

            ---------------------------------------------------------------------------
            --	Obtain the current record for this employee employment
            ---------------------------------------------------------------------------
            set @v_step_position = 'Emp Employment Lookup'

            SELECT (@i_emp_employment_exists = 'N')

            SELECT	@i_emp_id					=	emp_id,
                    @i_empl_id					=	empl_id,
                    @i_eff_date					=	eff_date,
                    @i_emp_employment_exists	=	'Y'
            FROM	DBShrpn.dbo.emp_employment	ee
            WHERE	emp_id					=	@emp_id_01
            and  eff_date				=	(SELECT	MAX(eff_date) FROM	DBShrpn.dbo.emp_employment t
                                                WHERE	t.emp_id			=	ee.emp_id)


            SET @v_step_position = 'Validation'


            IF (@i_emp_employment_exists = 'Y') AND
               (@i_eff_date              > CAST(@eff_date_01 AS datetime))
                BEGIN

                    SET @msg_id = 'U00027'
                    SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

                    UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                        SET activity_status	=	'02'
                    WHERE activity_date	=	@p_activity_date
                        AND emp_id_01		=	@emp_id_01
                        AND event_id_01		= @v_EVENT_ID_TRANSFER

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id					    As msg_id
                            , @emp_id_01					As msg_p1
                            , @empl_id_01					As msg_p2
                            -- create error message for logging
                            , REPLACE(REPLACE(t.msg_text, '@1', @eff_date_01), '@2', @emp_id_01) AS msg_desc
                        FROM #tbl_msg_master t
                        WHERE (msg_id = @msg_id)


                    -- Historical Message for reporting purpose
                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                    SELECT  @msg_id						As msg_id,
                            @v_EVENT_ID_TRANSFER			As event_id,
                            @emp_id_01 						As emp_id,
                            @eff_date_01					As eff_date,
                            @pay_element_desc_06			As pay_element_id,
                            @emp_id_01						As msg_p1,
                            CONVERT(char,@i_eff_date,112)	As msg_p2,
                            'The new effective date for employee must be greater than the current effective date'	As msg_desc,
                            @p_activity_date				AS activity_date
                    -- End of Historical Message for reporting purpose

                    SELECT  @w_fatal_error = '5'


                END

            ---------------------------------------------------------------------------
            -- Check to see if the employee does not exists
            ---------------------------------------------------------------------------

            IF  NOT EXISTS (SELECT * FROM DBShrpn.dbo.emp_status WHERE emp_id = @emp_id_01)
                BEGIN

                    SET @msg_id = 'U00012'
                    SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

                    UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                        SET activity_status	=	'02'
                    WHERE activity_date	=	@p_activity_date
                        AND emp_id_01		=	@emp_id_01
                        AND event_id_01		= @v_EVENT_ID_TRANSFER

                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id      As msg_id
                        , @emp_id_01    As msg_p1
                        , ''            As msg_p2
                        -- create error message for logging
                        , REPLACE(t.msg_text, '@1', @emp_id_01) AS msg_desc
                    FROM #tbl_msg_master t
                    WHERE (msg_id = @msg_id)

                    -- Historical Message for reporting purpose
                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                    SELECT  @msg_id						As msg_id,
                            @v_EVENT_ID_TRANSFER							As event_id,
                            @emp_id_01 						As emp_id,
                            @eff_date_01					As eff_date,
                            @pay_element_desc_06			As pay_element_id,
                            @emp_id_01						As msg_p1,
                            CONVERT(char,@eff_date_01,112)	As msg_p2,
                            'Employee does not exists'		As msg_desc,
                            @p_activity_date				AS activity_date
                    -- End of Historical Message for reporting purpose

                    SELECT  @w_fatal_error = '5'


                END

            --
            -- Existing payments have not been updated into the accumulator for this employee.
            --
            IF EXISTS (SELECT * FROM DBShrpy.dbo.emp_pmt WHERE	emp_id = @emp_id_01 AND	posted_accumulator_ind	= 'N' AND	seq_ctrl_yr		> 0)
                BEGIN
                    SET @msg_id = 'U00038'
                    SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

                    UPDATE DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status	= '02'
                    WHERE activity_date	=	@p_activity_date
                    AND emp_id_01		=	@emp_id_01
                    AND event_id_01		= @v_EVENT_ID_TRANSFER

                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id      As msg_id
                        , @emp_id_01    As msg_p1
                        , ''            As msg_p2
                        -- create error message for logging
                        , REPLACE(t.msg_text, '@1', @emp_id_01) AS msg_desc
                    FROM #tbl_msg_master t
                    WHERE (msg_id = @msg_id)


                    -- Historical Message for reporting purpose
                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                    SELECT  @msg_id						As msg_id,
                            @v_EVENT_ID_TRANSFER							As event_id,
                            @emp_id_01 						As emp_id,
                            @eff_date_01					As eff_date,
                            @pay_element_desc_06			As pay_element_id,
                            @emp_id_01						As msg_p1,
                            @empl_id_01						As msg_p2,
                            'Existing payments have not been updated into the accumulator for this employee.'		As msg_desc,
                            @p_activity_date				AS activity_date

                    SET @w_fatal_error = '5'

                END


            ---------------------------------------------------------------------------
            -- Check to see if the employer exists
            ---------------------------------------------------------------------------
            IF NOT EXISTS (SELECT * FROM DBShrpn.dbo.employer WHERE empl_id = @empl_id_01)
            BEGIN
                IF EXISTS (SELECT * FROM DBShrpn.dbo.employer WHERE empl_id = '0' + @empl_id_01)
                        SELECT @empl_id_01	= '0' + @empl_id_01
                ELSE
                    BEGIN

                        SET @msg_id = 'U00039'
                        SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

                        UPDATE DBShrpn.dbo.ghr_employee_events_aud
                        SET activity_status	= '02'
                        WHERE activity_date	=	@p_activity_date
                        AND emp_id_01		=	@emp_id_01
                        AND event_id_01		= @v_EVENT_ID_TRANSFER

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id      As msg_id
                            , @emp_id_01    As msg_p1
                            , ''            As msg_p2
                            -- create error message for logging
                            , REPLACE(t.msg_text, '@1', @empl_id_01) AS msg_desc
                        FROM #tbl_msg_master t
                        WHERE (msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                        INSERT INTO DBShrpn.dbo.ghr_historical_message
                        SELECT  @msg_id					As msg_id,
                                @v_EVENT_ID_TRANSFER						As event_id,
                                @emp_id_01 					As emp_id,
                                @eff_date_01				As eff_date,
                                @pay_element_desc_06		As pay_element_id,
                                @emp_id_01					As msg_p1,
                                @empl_id_01					As msg_p2,
                                'Employer does not exist - bypassing record'	As msg_desc,
                                @p_activity_date			AS activity_date
                        -- End of Historical Message for reporting purpose

                        SET @w_fatal_error = '5'

                    END
            END

            --
            -- Check to see if the new employer is not the same as the current employer
            --
            --	INSERT INTO DBShrpn.dbo.ghr_msgtbl SELECT 'Before 1' + @emp_id_01 + 'cnt: ' + CONVERT(CHAR,@cnt) + '@i_empl_id: ' + @i_empl_id + '@empl_id_01: ' + @empl_id_01 AS msgdesc
            IF @i_empl_id = @empl_id_01
                BEGIN

                    -- If salary Change Record Exists in this run, bypass transfer record
                    IF EXISTS (
                               SELECT 1
                               FROM DBShrpn.dbo.ghr_employee_events
                               WHERE emp_id_01   = @emp_id_01
                                 AND event_id_01 = @v_EVENT_ID_SALARY_CHANGE
                              )
                        BEGIN
                            UPDATE DBShrpn.dbo.ghr_employee_events_aud
                            SET activity_status = '99'
                            WHERE emp_id_01 = @emp_id_01 AND activity_date = @p_activity_date AND event_id_01 = @v_EVENT_ID_TRANSFER

                            GOTO BYPASS_EMPLOYEE
                        END
                    ELSE
                        BEGIN
                            SET @msg_id = 'U00034'
                            SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

                            UPDATE DBShrpn.dbo.ghr_employee_events_aud
                                SET activity_status	= '02'
                                WHERE activity_date	=	@p_activity_date
                                AND emp_id_01		=	@emp_id_01
                                AND event_id_01		= @v_EVENT_ID_TRANSFER

                            INSERT INTO #tbl_ghr_msg
                            SELECT @msg_id					    As msg_id
                                , @emp_id_01					As msg_p1
                                , @empl_id_01					As msg_p2
                                -- create error message for logging
                                , REPLACE(REPLACE(t.msg_text, '@1', @empl_id_01), '@2', @emp_id_01) AS msg_desc
                            FROM #tbl_msg_master t
                            WHERE (msg_id = @msg_id)

                                -- Historical Message for reporting purpose
                            INSERT INTO DBShrpn.dbo.ghr_historical_message
                            SELECT  @msg_id						As msg_id,
                                    @v_EVENT_ID_TRANSFER							As event_id,
                                    @emp_id_01 						As emp_id,
                                    @eff_date_01					As eff_date,
                                    @pay_element_desc_06			As pay_element_id,
                                    @emp_id_01						As msg_p1,
                                    @empl_id_01						As msg_p2,
                                    'Cannot transfer an employee to the same employer.'		As msg_desc,
                                    @p_activity_date				AS activity_date
                            -- End of Historical Message for reporting purpose

                            SELECT  @w_fatal_error = '5'
                        END



                END


/*
            --
            --	Check to see if pay element control group is blank
            --

            IF	@pay_element_ctrl_grp_id_03 = ''
            BEGIN

                UPDATE DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status	=	'02'
                    WHERE activity_date	=	@p_activity_date
                    AND emp_id_01		=	@emp_id_01
                    AND event_id_01		=	@v_EVENT_ID_TRANSFER

                INSERT INTO DBShrpn.dbo.ghr_msg_tbl
                SELECT	'U00040'				As msg_id,
                        @emp_id_01				As msg_p1,
                        @empl_id_01				As msg_p2,
                        'Pay Element Ctrl Grp cannot be blank'	As msg_desc

                -- Historical Message for reporting purpose
                INSERT INTO DBShrpn.dbo.ghr_historical_message
                SELECT  'U00040'						As msg_id,
                        @v_EVENT_ID_TRANSFER							As event_id,
                        @emp_id_01 						As emp_id,
                        @eff_date_01					As eff_date,
                        @pay_element_desc_06			As pay_element_id,
                        @emp_id_01						As msg_p1,
                        @empl_id_01						As msg_p2,
                        'Pay Element Ctrl Grp cannot be blank'		As msg_desc,
                        @p_activity_date				AS activity_date
                -- End of Historical Message for reporting purpose

                SELECT	@pay_element_ctrl_grp_id_03 = ' ', @pay_group_id_03 = ' '
            END

            --
            -- Check to see if the transfer date is greater than position effective date.
            --
            SELECT @pos_eff_date = eff_date FROM DBShrpn.dbo.position WHERE pos_id = '99999'

            IF  @pos_eff_date > CAST(@eff_date_01 AS datetime)
            BEGIN
                UPDATE DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status	= '02'
                    WHERE activity_date	=	@p_activity_date
                    AND emp_id_01		=	@emp_id_01
                    AND event_id_01		=	@v_EVENT_ID_TRANSFER

                INSERT INTO DBShrpn.dbo.ghr_msg_tbl
                SELECT 'U00036'				As msg_id,
                        @emp_id_01			As msg_p1,
                        @empl_id_01			As msg_p2,
                'Transfer date must be greater than default position effective date'	As msg_desc

                -- Historical Message for reporting purpose
                INSERT INTO DBShrpn.dbo.ghr_historical_message
                SELECT  'U00036'						As msg_id,
                    @v_EVENT_ID_TRANSFER							As event_id,
                    @emp_id_01 						As emp_id,
                    @eff_date_01					As eff_date,
                    @pay_element_desc_06			As pay_element_id,
                    @emp_id_01						As msg_p1,
                    @empl_id_01						As msg_p2,
                    'Transfer date must be greater than default position effective date'		As msg_desc,
                    @p_activity_date				AS activity_date
                -- End of Historical Message for reporting purpose

                SELECT  @w_fatal_error = '5'



            END
*/

            --
            -- Check to see if the employee is getting transfer to pensioner employer.
            --

            SELECT @pos_eff_date = eff_date FROM DBShrpn.dbo.position WHERE pos_id = '99999'

            IF EXISTS(
                      SELECT 1
                      FROM DBShrpn.dbo.employer
                      WHERE empl_id = @empl_id_01
                        AND name like 'Pen%'
                     )
                BEGIN
                    SET @msg_id = 'U00044'
                    SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

                    IF @rehire_override = '0'
                        BEGIN
                            UPDATE DBShrpn.dbo.ghr_employee_events_aud
                                SET activity_status	= '02'
                            WHERE activity_date	=	@p_activity_date
                                AND emp_id_01		=	@emp_id_01
                                AND event_id_01		= @v_EVENT_ID_TRANSFER

                            INSERT INTO #tbl_ghr_msg
                            SELECT @msg_id					    As msg_id
                                , @emp_id_01					As msg_p1
                                , ''   					        As msg_p2
                                -- create error message for logging
                                , REPLACE(t.msg_text, '@1', @emp_id_01) AS msg_desc
                            FROM #tbl_msg_master t
                            WHERE (msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                            INSERT INTO DBShrpn.dbo.ghr_historical_message
                            SELECT  @msg_id						As msg_id,
                                    @v_EVENT_ID_TRANSFER							As event_id,
                                    @emp_id_01 					As emp_id,
                                    @eff_date_01					As eff_date,
                                    @pay_element_desc_06			As pay_element_id,
                                    @emp_id_01					As msg_p1,
                                    @empl_id_01					As msg_p2,
                                    'Cannot transfer an employee to a pensioner employer'		As msg_desc,
                                    @p_activity_date				AS activity_date
                            -- End of Historical Message for reporting purpose

                            SELECT  @w_fatal_error = '5'
                        END
                    ELSE
                        BEGIN
                            UPDATE DBShrpn.dbo.ghr_employee_events_aud
                                SET activity_status	= '99'
                                WHERE activity_date	=	@p_activity_date
                                AND emp_id_01		=	@emp_id_01
                                AND event_id_01		=	@v_EVENT_ID_TRANSFER
                        END



            END
            --
            -- Check to see if the employee current status is terminated.
            --
            SET @msg_id = 'U00045'
            SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

            SELECT @emp_status_code	=  emp_status_code
            FROM DBShrpn.dbo.emp_status s
            WHERE s.emp_id = @emp_id_01
            AND s.status_change_date = (SELECT MAX(status_change_date) FROM DBShrpn.dbo.emp_status t WHERE t.emp_id = s.emp_id)

            IF	@emp_status_code = 'T'
                BEGIN
                    IF @rehire_override = '0'
                        BEGIN
                            UPDATE DBShrpn.dbo.ghr_employee_events_aud
                                SET activity_status	= '02'
                                WHERE activity_date	=	@p_activity_date
                                AND emp_id_01		=	@emp_id_01
                                AND event_id_01		=	@v_EVENT_ID_TRANSFER

                            INSERT INTO #tbl_ghr_msg
                            SELECT @msg_id					    As msg_id
                                , @emp_id_01					As msg_p1
                                , ''   					        As msg_p2
                                -- create error message for logging
                                , REPLACE(t.msg_text, '@1', @emp_id_01) AS msg_desc
                            FROM #tbl_msg_master t
                            WHERE (msg_id = @msg_id)

                            -- Historical Message for reporting purpose
                            INSERT INTO DBShrpn.dbo.ghr_historical_message
                            SELECT  @msg_id						As msg_id,
                                    @v_EVENT_ID_TRANSFER							As event_id,
                                    @emp_id_01 					As emp_id,
                                    @eff_date_01					As eff_date,
                                    @pay_element_desc_06			As pay_element_id,
                                    @emp_id_01					As msg_p1,
                                    @empl_id_01					As msg_p2,
                                    'Terminated employee cannot be transferred'		As msg_desc,
                                    @p_activity_date		        AS activity_date
                            -- End of Historical Message for reporting purpose

                            SELECT  @w_fatal_error = '5'
                        END
                    ELSE
                        BEGIN

                            UPDATE DBShrpn.dbo.ghr_employee_events_aud
                            SET activity_status	= '99'
                            WHERE activity_date	=	@p_activity_date
                            AND emp_id_01		=	@emp_id_01
                            AND event_id_01		=	@v_EVENT_ID_TRANSFER

                            SELECT  @w_fatal_error = '5'
                        END



                END


            IF  @w_fatal_error = '5'
                GOTO BYPASS_EMPLOYEE



            --	Clear the fields:
            SELECT	@old_entity					=	'',
                    @old_tax_entity				=	'',
                    @eff_date					=	'',
                    @new_tax_entity				=	'',
                    @assignment_end_date		=	'',
                    @job_position_end_date		=	'',
                    @assigned_to_code			=	'',
                    @new_taxing_country_code	=	'',
                    @new_curr_code				=	''

            --	Find the old entity & old tax entity & eff date
            SELECT	@old_entity	=	empl_id, @old_tax_entity =	tax_entity_id, @eff_date	=	eff_date
            FROM	DBShrpn.dbo.emp_employment ee
            WHERE	emp_id = 	@emp_id_01
            AND	eff_date = (SELECT MAX(eff_date) FROM DBShrpn.dbo.emp_employment t WHERE t.emp_id = ee.emp_id)

            --	Find new tax entity
            SELECT	@new_tax_entity	=	tax_entity_id
            FROM	DBShrpn.dbo.empl_tax_entity
            WHERE	empl_id		=	@empl_id_01

            --	Find the Job_position end date and Assignment end date limited to after Jan 1, 2021
            SELECT	@assignment_end_date		=	ea.end_date,
                    @job_position_end_date		=	ea.end_date,
                    @assigned_to_code			=	ea.assigned_to_code
            FROM	DBShrpn.dbo.emp_assignment ea
            WHERE	ea.emp_id					=	@emp_id_01
            AND	ea.eff_date					=	(SELECT MAX(t.eff_date) FROM DBShrpn.dbo.emp_assignment t WHERE t.emp_id = ea.emp_id AND t.end_date >= CAST('Jan 1, 2021' AS DATE))
            AND	ea.prime_assignment_ind		=	'Y'


            --	Obtain the current record for this employee assignment
            SELECT	@ea_emp_id					=	emp_id,
                    @ea_assigned_to_code		=	assigned_to_code,
                    @ea_job_or_pos_id			=	job_or_pos_id,
                    @ea_eff_date				=	eff_date,
                    @ea_next_eff_date			=	next_eff_date,
                    @ea_prior_eff_date			=	prior_eff_date,
                    @i_base_rate_tbl_id			=	base_rate_tbl_id,
                    @i_base_rate_tbl_entry_code	=	base_rate_tbl_entry_code,
                    @i_pd_salary_tm_pd_id		=	pd_salary_tm_pd_id,
                    @i_standard_work_pd_id		=	standard_work_pd_id,
                    @i_standard_work_hrs		=	standard_work_hrs,
                    @i_hourly_rate_amt			=	hourly_pay_rate,
                    @i_period_amt				=	pd_salary_amt,
                    @i_work_tm_code				=	work_tm_code
            FROM	DBShrpn.dbo.emp_assignment	ea
            WHERE	emp_id					=	@emp_id_01
            AND	prime_assignment_ind	=	'Y'
            AND  eff_date				=	(
                                            SELECT	MAX(eff_date)
                                            FROM	DBShrpn.dbo.emp_assignment t
                                            WHERE	t.emp_id =	ea.emp_id
                                              AND prime_assignment_ind	=	'Y'
                                            )


            --	e.taxing_country_code	AS new_taxing_country_code AND e.curr_code	AS new_curr_code,

            SELECT	@new_taxing_country_code	=	e.taxing_country_code,
                    @new_curr_code				=	e.curr_code
            FROM	DBShrpn.dbo.employer e
            WHERE  e.empl_id	=	@empl_id_01


            --
            -- Start of the transfer process
            --
            SELECT	@p_emp_id						=	@emp_id_01,
                    @p_old_empl_id					=	@old_entity,
                    @p_new_empl_id					=	@empl_id_01,
                    @p_transfer_date				=	CAST(@eff_date_01 AS datetime),
                    @p_assign_to					=	@assigned_to_code,
                    @p_job_or_pos_id				=	'99999',							-- Default Position
                    @p_org_grp_id					=	CAST(@organization_group_id_01 AS INT),
                    @p_org_chart_name				=	@organization_chart_name_01,
                    @p_org_unit_name				=	@organization_unit_name_01,
                    @p_location						=	@emp_location_code_03,
                    @p_new_tax_entity_id			=	@new_tax_entity,
                    @p_old_tax_entity_id			=	@old_tax_entity,
                    @p_eff_date						=	@eff_date,								--	emp_employment
                    @p_pay_group					=	@pay_group_id_03,
                    @p_emp_info_change_reason		=	@employment_info_chg_reason_cd_03,
                    @p_job_position_end_date		=	@job_position_end_date,
                    @p_assignment_end_date			=	@assignment_end_date,
                    @p_xfer_different_taxing_cntry	=	'N',									--	different_taxing_country,
                    @p_new_empl_taxing_country_cd	=	@new_taxing_country_code,
                    @p_new_empl_curr_code			=	@new_curr_code,
                    @p_use_policy_xfer_options		=	'Y' 									--	'Y' As policy_xfer_options



            CREATE TABLE #temp1  (emp_id                      char(15) 		not null, empl_id                        char(10) 		not null, pay_element_id                 char(10) 		not null, eff_date                       datetime 		not null,	prior_eff_date                 datetime 		not null,	next_eff_date                  datetime 		not null,	inactivated_by_pay_element_ind char(1) 		not null,	start_date                     datetime 		not null,	stop_date                      datetime 		not null,	change_reason_code             char(5) 		not null,	pay_element_pay_pd_sched_code  char(2) 		not null,	calc_meth_code                 char(2) 		not null,	standard_calc_factor_1         money 			not null,	standard_calc_factor_2         money 			not null,	special_calc_factor_1          money 			not null,	special_calc_factor_2          money 			not null,	special_calc_factor_3          money 			not null,	special_calc_factor_4          money 			not null,	rate_tbl_id                    char(10) 		not null,	rate_code                      char(8) 		not null,	payee_name                     char(35)		not null,	payee_pmt_sched_code           char(5) 		not null,	payee_bank_transit_nbr         char(17) 		not null,	payee_bank_acct_nbr            char(17) 		not null,	pmt_ref_nbr                    char(20) 		not null,	pmt_ref_name                   char(35) 		not null,	vendor_id                      char(10) 		not null,	limit_amt                      money 			not null,	guaranteed_net_pay_amt         money 			not null,	start_after_pay_element_id     char(10) 		not null,	indiv_addr_type_to_print_code  char(5) 		not null,	bank_id                        char(11) 		not null,	direct_deposit_bank_acct_nbr   char(17) 		not null,	bank_acct_type_code            char(1) 		not null,	pay_pd_arrears_rec_fixed_amt   money 			not null,	pay_pd_arrears_rec_fixed_pct   money 			not null,	min_pay_pd_recovery_amt        money 			not null,	user_amt_1                     float 			not null,	user_amt_2                     float 			not null,	user_monetary_amt_1            money 			not null,	user_monetary_amt_2            money 			not null,	user_monetary_curr_code        char(3) 		not null,	user_code_1                    char(5) 		not null,	user_code_2                    char(5) 		not null,	user_date_1                    datetime 		not null,	user_date_2                    datetime 		not null,	user_ind_1                     char(1) 		not null,	user_ind_2                     char(1) 		not null,	user_text_1                    char(50) 		not null,	user_text_2                    char(50) 		not null,	pension_tot_distn_ind          char(1) 		not null,	pension_distn_code_1           char(1) 		not null,	pension_distn_code_2           char(1) 		not null, pre_1990_rpp_ctrb_type_cd      char(1) 		not null,	chgstamp                       smallint 		not null,	first_roth_ctrb                datetime 		not null,	ira_sep_simple_ind             char(1) 		not null, taxable_amt_not_determined_ind char(1) 		not null)
            CREATE TABLE #temp4  (emp_id                      char(15) 		not null, empl_id                        char(10) 		not null, pay_element_id                 char(10) 		not null, arrears_bal_amt                money 			not null,	recover_over_nbr_of_pay_pds    tinyint 		not null,	wh_status_code                 char(1) 		not null,	calc_last_pay_pd_ind           char(1) 		not null,	prenotification_check_date     datetime 		not null,	prenotification_code           char(1) 		not null,	chgstamp                       smallint 		not null)
            CREATE TABLE #temp5  (emp_id                      char(15) 		not null, empl_id                        char(10) 		not null, pay_element_id                 char(10) 		not null, start_date                     datetime 		not null,	towards_the_limit_amt          money 			not null,	chgstamp                       smallint 		not null)
            CREATE TABLE #temp6  (emp_id                      char(15) 		not null, empl_id                        char(10) 		not null, pay_element_id                 char(10) 		not null, start_date                     datetime 		not null,	comnt_type_code                char(1) 		not null,	seq_nbr                        smallint 		not null,	comnt_text                     varchar(255) 	not null,	chgstamp                       smallint 		not null)
            CREATE TABLE #temp7  (participant_id              char(15) 		not null, ben_plan_id                    char(15) 		not null, ben_plan_opt_id                char(08) 		not null, eff_date                       datetime 		not null, next_eff_date                  datetime 		not null, prior_eff_date                 datetime 		not null, start_date                     datetime 		not null, stop_date                      datetime 		not null, chained_with_option_id         char(8) 		not null, chained_to_option_id           char(8) 		not null, stopped_due_to_plan_ending_ind char(1) 		not null, stopped_due_to_opt_ending_ind  char(1) 		not null, stopped_due_to_terminated_ind  char(1) 		not null, cobra_cost_amt                 money 			not null, cobra_cost_tm_pd_id            char(5) 		not null, cobra_empl_cost_amt            money 			not null, cobra_empl_cost_tm_pd_id       char(5) 		not null, user_amt_1                     float 			not null, user_amt_2                     float 			not null, user_monetary_curr_code        char(3) 		not null, user_monetary_amt_1            money 			not null, user_monetary_amt_2            money 			not null, user_code_1                    char(5) 		not null, user_code_2                    char(5) 		not null, user_date_1                    datetime 		not null, user_date_2                    datetime 		not null, user_ind_1                     char(1) 		not null, user_ind_2                     char(1) 		not null, user_text_1                    char(50) 		not null, user_text_2                    char(50) 		not null, chgstamp                       smallint 		not null)
            CREATE TABLE #temp8  (participant_id              char(15) 		not null, ben_plan_id                    char(15) 		not null, ben_plan_opt_id                char(08) 		not null, eff_date                       datetime 		not null, ben_plan_alloc_opt_id          char(10) 		not null, allocated_amt                  money 			not null, allocated_pct                  float 			not null, user_amt_1                     float 			not null, user_amt_2                     float 			not null, user_monetary_curr_code        char(3) 		not null, user_monetary_amt_1            money 			not null, user_monetary_amt_2            money 			not null, user_code_1                    char(5) 		not null, user_code_2                    char(5) 		not null, user_date_1                    datetime 		not null, user_date_2                    datetime 		not null, user_ind_1                     char(1) 		not null, user_ind_2                     char(1) 		not null, user_text_1                    char(50) 		not null, user_text_2                    char(50) 		not null, chgstamp                       smallint 		not null)
            CREATE TABLE #temp9  (participant_id  			  char(15) 		not null, ben_plan_id     				 char(15) 		not null, ben_plan_opt_id 				 char(08) 		not null, start_date      				 datetime 		not null, comnt_type_code 					char(1) 			not null, seq_nbr         					smallint 		not null, comnt_text      					varchar(255) 	not null, chgstamp        					smallint 		not null)
            CREATE TABLE #temp11 (emp_id                      char(15) 		not null, assigned_to_code               char(1) 		not null, job_or_pos_id                  char(10) 		not null, eff_date                       datetime 		not null,	next_eff_date                  datetime 		not null,	prior_eff_date                 datetime 		not null,	next_assigned_to_code          char(1) 		not null,	next_job_or_pos_id             char(10) 		not null,	prior_assigned_to_code         char(1) 		not null,	prior_job_or_pos_id            char(10) 		not null,	begin_date                     datetime 		not null,	end_date                       datetime 		not null,	assignment_reason_code         char(5) 		not null,	organization_chart_name        varchar(64) 	not null, organization_unit_name         varchar(240) 	not null,	organization_group_id          int 				not null,	organization_change_reason_cd  char(5) 		not null,	loc_code                       char(10) 		not null,	mgr_emp_id                     char(15) 		not null,	official_title_code            char(5) 		not null,	official_title_date            datetime 		not null,	salary_change_date             datetime 		not null,	annual_salary_amt              money 			not null,	pd_salary_amt                  money 			not null,	pd_salary_tm_pd_id             char(5) 		not null,	hourly_pay_rate                float 			not null,	curr_code                      char(3) 		not null,	pay_on_reported_hrs_ind        char(1) 		not null,	salary_change_type_code        char(5) 		not null,	standard_work_pd_id            char(5) 		not null,	standard_work_hrs              float 			not null,	work_tm_code                   char(1) 	not null,	work_shift_code                char(5) 		not null,	salary_structure_id            char(10) 		not null,	salary_increase_guideline_id   char(10) 		not null,	pay_grade_code                 char(6) 		not null,	pay_grade_date                 datetime 		not null,	job_evaluation_points_nbr      smallint 		not null,	salary_step_nbr                smallint 		not null,	salary_step_date               datetime 		not null,	phone_1_type_code              char(5) 		not null,	phone_1_fmt_code               char(6) 		not null,	phone_1_fmt_delimiter          char(1) 		not null,	phone_1_intl_code              char(4) 		not null,	phone_1_country_code           char(4) 		not null,	phone_1_area_city_code         char(5) 		not null,	phone_1_nbr                    char(12) 		not null,	phone_1_extension_nbr          char(5) 		not null,	phone_2_type_code              char(5) 		not null,	phone_2_fmt_code               char(6) 		not null,	phone_2_fmt_delimiter          char(1) 		not null,	phone_2_intl_code              char(4) 		not null,	phone_2_country_code           char(4) 		not null,	phone_2_area_city_code         char(5) 		not null,	phone_2_nbr                    char(12) 		not null,	phone_2_extension_nbr          char(5) 		not null,	prime_assignment_ind           char(1) 		not null,	pay_basis_code                 char(1) 		not null,	occupancy_code                 char(1) 		not null,	regulatory_reporting_unit_code char(10) 		not null,	base_rate_tbl_id               char(10) 		not null,	base_rate_tbl_entry_code       char(8) 		not null,	shift_differential_rate_tbl_id char(10) 		not null,	ref_annual_salary_amt          money 			not null,	ref_pd_salary_amt              money 			not null,	ref_pd_salary_tm_pd_id         char(5) 		not null,	ref_hourly_pay_rate            float 			not null,	guaranteed_annual_salary_amt   money 			not null,	guaranteed_pd_salary_amt       money 			not null,	guaranteed_pd_salary_tm_pd_id  char(5) 		not null,	guaranteed_hourly_pay_rate     float 			not null,	exception_rate_ind             char(1) 		not null,	overtime_status_code           char(2) 		not null,	shift_differential_status_code char(2) 		not null,	standard_daily_work_hrs        money 			not null,	user_amt_1                     float 			not null,	user_amt_2                     float 			not null,	user_code_1                    char(5) 		not null,	user_code_2                    char(5) 		not null,	user_date_1                    datetime 		not null,	user_date_2                    datetime 		not null,	user_ind_1                     char(1) 		not null,	user_ind_2                     char(1) 		not null,	user_monetary_amt_1            money 			not null,	user_monetary_amt_2            money 			not null,	user_monetary_curr_code        char(3) 		not null,	user_text_1                    char(50) 		not null,	user_text_2                    char(50) 		not null,	unemployment_loc_code          char(10) 		not null, include_salary_in_autopay_ind  char(1) 		not null,	chgstamp                       smallint 		not null)
            CREATE TABLE #temp12 (emp_id                      char(15) 		not null, tax_entity_id                  char(10) 		not null, tax_authority_id               char(10) 		not null, emp_us_tax_authority_status_cd char(1) 		not null,	tax_marital_status_code        char(1) 		not null,	tm_worked_pct                  money 			not null,	work_resident_status_code      char(1) 		not null,	reciprocal_tax_authority_id    char(10) 		not null,	income_tax_calc_meth_cd        char(2) 		not null,	earned_income_cr_calc_meth_cd  char(1) 		not null,	income_tax_adj_code            char(1) 		not null,	income_tax_adj_amt             money 			not null,	income_tax_adj_pct             money 			not null,	income_tax_nbr_of_exemps       smallint 		not null,	income_tax_nbr_of_pers_exemps  smallint 		not null,	income_tax_nbr_of_depn_exemps  smallint 		not null,	income_tax_nbr_exemps_over_65  smallint 		not null,	income_tax_nbr_of_allowances   smallint 		not null,	use_inc_tax_low_inc_tbls_ind   char(1) 		not null,	income_tax_blind_crs           smallint 		not null,	income_tax_personal_exemp_amt  money 			not null,	income_tax_senior_citizen_cr   smallint 		not null,	oasdi_status_code              char(1) 		not null,	medicare_status_code           char(1) 		not null,	fui_status_code                char(1) 		not null,	sui_st_ind                     char(1) 		not null,	resident_county_code           char(5) 		not null,	work_county_code               char(5) 		not null,	sui_status_code                char(1) 		not null,	sdi_status_code                char(1) 		not null,	other_st_tax_1_status_code     char(1) 		not null,	other_st_tax_2_status_code     char(1) 		not null,	other_st_tax_3_status_code     char(1) 		not null,	other_st_tax_4_status_code     char(1) 		not null,	other_st_tax_5_status_code     char(1) 		not null,	wage_plan_code                 char(1) 		not null,	emp_health_insurance_cvrg_cd   char(1) 		not null,	user_amt_1                     float 			not null,	user_amt_2                     float 			not null,	user_monetary_amt_1            money 			not null,	user_monetary_amt_2            money 			not null,	user_monetary_curr_code        char(3) 		not null,	user_code_1                    char(5) 		not null,	user_code_2                    char(5) 		not null,	user_date_1                    datetime 		not null,	user_date_2                    datetime 		not null,	user_ind_1                     char(1) 		not null,	user_ind_2                     char(1) 		not null,	user_text_1                    char(50) 		not null,	user_text_2                    char(50) 		not null, emp_workers_comp_cvrg_cd       char(1) 		not null, puerto_rico_resident_status_cd char(1) 		not null, allowances_based_on_ded_amt    money 			not null, az_income_tax_ovrd_opt_cd		 char(1) 		not null,	chgstamp                       smallint 		not null, us_resident_status_cd			 char(1)       null, other_st_tax_1a_status_code    char(1)       null, eic_nbr_of_children	          smallint      null, hire_act_status_code	          char(1)       null, emp_workers_comp_class        char(1)       null, resident_psd                           char(10)      null, add_vet_pers_exemps	               float         null, income_tax_nbr_joint_dep_exemp  smallint      null, allowance_based_on_special_ded   float         null, allowance_based_on_deds	       smallint      null, rec_chg_ind	                   char(1)       null, visa_type 	                   char(1)       null)
            CREATE TABLE #temp14 (emp_id                      char(15) 		not null, eff_date                       datetime 		not null, next_eff_date                  datetime 		not null, prior_eff_date                 datetime 		not null,	employment_type_code           char(5) 		not null,	work_tm_code                   char(1) 		null,	official_title_code            char(5) 		not null,	official_title_date            datetime 		not null,	mgr_ind                        char(1) 		not null,	recruiter_ind                  char(1) 		not null,	pensioner_indicator            char(1) 		not null,	payroll_company_code           char(5) 		not null,	pmt_ctrl_code                  char(5) 		not null,	us_federal_tax_meth_code       char(1) 		not null,	us_federal_tax_amt             money 			not null,	us_federal_tax_pct             money 			not null,	us_federal_marital_status_code char(1) 		not null,	us_federal_exemp_nbr           tinyint 		not null,	us_work_st_code                char(2) 		not null,	canadian_work_province_code    char(2) 		not null,	ipp_payroll_id                 char(5) 		not null,	ipp_max_pay_level_amt          money 			not null,	pay_through_date               datetime 		not null,	empl_id                        char(10) 		not null,	tax_entity_id                  char(10) 		not null,	pay_status_code                char(1) 		not null,	clock_nbr                      char(10) 		not null,	provided_i_9_ind               char(1) 		not null,	time_reporting_meth_code       char(1) 		not null,	regular_hrs_tracked_code       char(1) 		not null,	pay_element_ctrl_grp_id        char(10) 		not null,	pay_group_id                   char(10) 		not null,	us_pension_ind                 char(1) 		not null,	professional_cat_code          char(5) 		not null,	corporate_officer_ind          char(1) 		not null,	prim_disbursal_loc_code        char(10) 		not null,	alternate_disbursal_loc_code   char(10) 		not null,	labor_grp_code                 char(5) 		not null,	employment_info_chg_reason_cd  char(5) 		not null,	highly_compensated_emp_ind     char(1) 		not null,	nbr_of_dependent_children      tinyint 		not null,	canadian_federal_tax_meth_cd   char(1) 		not null,	canadian_federal_tax_amt       money 			not null,	canadian_federal_tax_pct       money 			not null,	canadian_federal_claim_amt     money 			not null,	canadian_province_claim_amt    money 			not null,	tax_unit_code                  char(5) 		not null,	requires_tm_card_ind           char(1) 		not null,	xfer_type_code                 char(1) 		not null,	tax_clear_code                 char(1) 		not null,	pay_type_code                  char(1) 		not null,	labor_distn_code               char(14) 		not null,	labor_distn_ext_code           char(30) 		not null,	us_fui_status_code             char(1) 		not null,	us_fica_status_code            char(1) 		not null,	payable_through_bank_id        char(11) 		not null,	disbursal_seq_nbr_1            char(30) 		not null,	disbursal_seq_nbr_2            char(30) 		not null,	non_employee_indicator         char(1) 		not null,	excluded_from_payroll_ind      char(1) 		not null,	emp_info_source_code           char(1) 		not null,	user_amt_1                     float 			not null,	user_amt_2                     float 			not null,	user_monetary_amt_1            money 			not null,	user_monetary_amt_2            money 			not null,	user_monetary_curr_code        char(3) 		not null,	user_code_1                    char(5) 		not null,	user_code_2                    char(5) 		not null,	user_date_1                    datetime 		not null,	user_date_2                    datetime 		not null,	user_ind_1                     char(1) 		not null,	user_ind_2                     char(1) 		not null,	user_text_1                    char(50) 		not null,	user_text_2                    char(50) 		not null,	t4_employ_code                 char(2) 		not null,	chgstamp                       smallint 		not null)
            CREATE TABLE #temp15 (emp_id                      char(15)		NOT NULL, empl_id                        char(10)       NOT NULL, tax_authority_id               char(10)       NOT NULL, emp_can_tax_auth_status_cd     char(1)       NOT NULL, inc_tax_status_code            char(1)       NOT NULL, inc_tax_adj_code               char(1)       NOT NULL, inc_tax_adj_amt                money         NOT NULL, inc_tax_adj_pct                money         NOT NULL, tot_estd_remuneration_amt      money         NOT NULL, tot_estimated_expense_amt      money         NOT NULL, inc_tax_basic_amt              money         NOT NULL, inc_tax_spousal_disabled_amt   money         NOT NULL, inc_tax_depn_relative_amt      money         NOT NULL, inc_tax_eligible_pens_inc_amt  money         NOT NULL, inc_tax_age_amt                money         NOT NULL, inc_tax_tuition_fees_educ_amt  money         NOT NULL, inc_tax_disability_amt         money         NOT NULL, inc_tax_transferred_amt        money         NOT NULL, inc_tax_tot_claim_amt          money         NOT NULL, inc_tax_ded_dsgnd_liv_area_amt money         NOT NULL, inc_tax_auth_annual_ded_amt    money         NOT NULL, inc_tax_other_tax_cr_amt       money         NOT NULL, canadian_status_indian_ind     char(1)       NOT NULL, ei_status_code                 char(1)       NOT NULL, pit_basic_amt                  money         NOT NULL, pit_spouse_support_amt         money         NOT NULL, pit_dependent_children_amt     money         NOT NULL, pit_other_dependent_amt        money         NOT NULL, pit_domestic_estab_amt         money         NOT NULL, pit_age_amt                    money         NOT NULL, unused_amt_1		             money         NOT NULL, unused_amt_2				       money         NOT NULL, pit_retmt_income_amt           money         NOT NULL, pit_family_amt                 money         NOT NULL, unused_amt_3		             money         NOT NULL, pit_tot_claim_amt              money         NOT NULL, pit_other_deds_amt             money         NOT NULL, pit_other_tax_cr_amt           money         NOT NULL, primary_province_ind           char(1)       NOT NULL, sales_tax_status_code          char(1)       NOT NULL, lbr_sponsored_fund_tax_cr_amt  money         NOT NULL, pp_status_code                 char(1)       NOT NULL, other_provincial_tax_1_stat_cd char(1)       NOT NULL, other_provincial_tax_2_stat_cd char(1)       NOT NULL, other_provincial_tax_3_stat_cd char(1)       NOT NULL, nbr_of_days_wrkd_os_canada     float         NOT NULL, user_amt_1                     float         NOT NULL, user_amt_2                     float         NOT NULL, user_monetary_amt_1            money         NOT NULL, user_monetary_amt_2            money         NOT NULL, user_monetary_curr_code        char(3)       NOT NULL, user_code_1                    char(5)       NOT NULL, user_code_2                    char(5)       NOT NULL, user_date_1                    datetime      NOT NULL, user_date_2                    datetime      NOT NULL, user_ind_1                     char(1)       NOT NULL, user_ind_2                     char(1)       NOT NULL, user_text_1                    varchar(50)   NOT NULL, user_text_2                    varchar(50)	NOT NULL, inc_tax_caregiver_amt			 money			NOT NULL, pit_disability_amt			 	 money			NOT NULL, pit_transferred_amt			 	 money			NOT NULL, chgstamp                       smallint      NOT NULL, ppip_status_code               char(1)       NOT NULL, inc_tax_infirm_depn_amt        money         NULL, inc_tax_child_amt              money         NULL, inc_tax_transferred_depn_amt   money         NULL, cpp_election_code              char(1)       NULL, cpp_election_date              datetime      NULL, prev_cpp_election_code         char(1)       NULL, prev_cpp_election_date         datetime      NULL, rcv_pp_pension_ind             char(1)       NULL, hlth_ctrb_status_code          char(1)       NULL)


            EXECUTE DBShrpn.dbo.usp_upd_hrpn_02_trn @p_emp_id,
                            @p_old_empl_id,
                            @p_new_empl_id,
                            @p_transfer_date,
                            @p_assign_to,
                            @p_job_or_pos_id,
                            @p_org_grp_id,
                            @p_org_chart_name,
                            @p_org_unit_name,
                            @p_location,
                            @p_new_tax_entity_id,
                            @p_old_tax_entity_id,
                            @p_eff_date,
                            @p_pay_group,
                            @p_emp_info_change_reason,
                            @p_job_position_end_date,
                            @p_assignment_end_date,
                            @p_xfer_different_taxing_cntry,
                            @p_new_empl_taxing_country_cd,
                            @p_new_empl_curr_code,
                            @p_use_policy_xfer_options



            SELECT
                    @p_calendar_year			=	LEFT(convert(varchar(10),@p_transfer_date,112),4),
                    @p_curr_code				=	@p_new_empl_curr_code,
                    @p_return_to_prior_empl		=	'N',
                    @p_empl_adj_paymnt_run_type =	'#ADJUSTMNT',
                    @p_system_user_id			=	'DBS',
                    @p_pay_group_id				=	 @p_pay_group



            EXECUTE DBShrpy.dbo.usp_ins_hpep_02_trn
                            @p_emp_id,
                            @p_old_empl_id,
                            @p_new_empl_id,
                            @p_transfer_date,
                            @p_calendar_year,
                            @p_curr_code,
                            @p_return_to_prior_empl,
                            @p_empl_adj_paymnt_run_type,
                            @p_system_user_id,
                            @p_pay_group_id



            DROP TABLE #temp1
            DROP TABLE #temp4
            DROP TABLE #temp5
            DROP TABLE #temp6
            DROP TABLE #temp7
            DROP TABLE #temp8
            DROP TABLE #temp9
            DROP TABLE #temp11
            DROP TABLE #temp12
            DROP TABLE #temp14
            DROP TABLE #temp15

            ---------------------------------------------------------------------------
            --	Update the Salary in the Assignment Record
            ---------------------------------------------------------------------------

            SELECT	@i_emp_id				=	emp_id,
                    @i_assigned_to_code		=	assigned_to_code,
                    @i_job_or_pos_id		=	job_or_pos_id,
                    @i_eff_date				=	eff_date,
                    @i_next_eff_date		=	next_eff_date,
                    @i_prior_eff_date		=	prior_eff_date
            FROM	DBShrpn.dbo.emp_assignment	ea
            WHERE	emp_id					=	@emp_id_01
            AND prime_assignment_ind	=	'Y'
            AND  eff_date				=	(
                                            SELECT	MAX(eff_date)
                                            FROM DBShrpn.dbo.emp_assignment t
                                            WHERE t.emp_id =	ea.emp_id
                                            AND prime_assignment_ind	=	'Y'
                                            )

            -- GOSL: HCM Salary data will not be extracted to SS
            -- Blank them out
            SELECT @annual_salary				    =	0.00
                    , @i_hourly_rate_amt			=	0.00
                    , @i_period_amt				    =	0.00
                    , @i_salary_change_type_code	=	''
                    , @i_work_tm_code				=	''
                    , @i_base_rate_tbl_id			=	''
                    , @i_base_rate_tbl_entry_code	=	''
                    , @i_standard_work_pd_id		=	''
                    , @i_standard_work_hrs		    =	0.00
                    , @i_pd_salary_tm_pd_id		    =	''




            UPDATE DBShrpn.dbo.emp_assignment
            SET		annual_salary_amt			=	CAST(@annual_salary_amt_01 AS MONEY),
                    hourly_pay_rate				=	@i_hourly_rate_amt,
                    pd_salary_amt				=	@i_period_amt,
                    salary_change_type_code		=	'',
                    work_tm_code				=	@i_work_tm_code,
                    base_rate_tbl_id			=	@i_base_rate_tbl_id,
                    base_rate_tbl_entry_code	=	@i_base_rate_tbl_entry_code,
                    organization_group_id		=	@p_org_grp_id,
                    organization_chart_name		=	@p_org_chart_name,
                    organization_unit_name		=	@p_org_unit_name
            WHERE	emp_id				=	@i_emp_id
            AND		assigned_to_code	=	@i_assigned_to_code
            AND		job_or_pos_id		=	@i_job_or_pos_id
            AND		eff_date			=	@i_eff_date
            AND		next_eff_date		=	@i_next_eff_date
            AND		prior_eff_date		=	@i_prior_eff_date


            --
            -- Update the position since could be a new position with a new transfer
            --
            SELECT @individual_id = individual_id FROM DBShrpn.dbo.employee WHERE emp_id = @emp_id_01

            UPDATE	DBShrpn.dbo.individual_personal
                SET	user_text_1		=	CAST(@position_title_01 AS CHAR(50))
            WHERE individual_id	=	@individual_id


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

        END  -- Error Loop

        -- Cleanup Cursor
        CLOSE crsrHR
        DEALLOCATE crsrHR


        ---------------------------------------------------------------------------
        -- Log warning message U00000 -- < EMPLOYEE TRANSFER SECTION (3) >
        ---------------------------------------------------------------------------

        SET @msg_id = 'U00017'
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
        SET @msg_id = 'U00018'
        SET @v_step_position = 'Log ' + @msg_id

        SELECT @msg_id        = msg_id
            , @w_msg_text    = msg_text
            , @w_msg_text_2  = msg_text_2
            , @w_msg_text_3  = msg_text_3
            , @w_severity_cd = severity_cd
        FROM #tbl_msg_master
        WHERE (msg_id = @msg_id)

        -- Get total new hire records from HCM
        SELECT @maxx = CAST(COUNT(*) AS varchar(6))
        FROM #tbl_ghr_msg
        WHERE (msg_id = @msg_id)

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

        SELECT @ErrorMessage  = LEFT(ERROR_MESSAGE(), 1024) + ' (' + @v_step_position + ')'
             , @ErrorSeverity = ERROR_SEVERITY()
             , @ErrorState    = ERROR_STATE()
             , @v_ret_val     = -1

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

/*
        SELECT @v_step_position AS step_position
             , @ErrorMessage  AS err_msg
             , @ErrorSeverity AS err_sev
             , @ErrorState    AS err_state
*/

        RAISERROR(@ErrorMessage
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

ALTER AUTHORIZATION ON dbo.usp_perform_transfer TO  SCHEMA OWNER
GO

IF OBJECT_ID(N'dbo.usp_perform_transfer', N'P') IS NOT NULL
    PRINT N'<<< CREATED PROCEDURE dbo.usp_perform_transfer >>>'
ELSE
    PRINT N'<<< FAILED CREATING PROCEDURE dbo.usp_perform_transfer >>>'
GO
