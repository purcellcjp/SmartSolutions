USE DBShrpn
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER PROCEDURE dbo.usp_ins_salary_change
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

    DECLARE @ret int
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
    DECLARE @i_emp_assignment_exists		char(01)
    DECLARE @i_work_tm_code					char(01)
    DECLARE	@i_base_rate_tbl_id				char(10)
    DECLARE	@i_base_rate_tbl_entry_code		char(08)
    DECLARE @i_pd_salary_tm_pd_id			char(05)

    DECLARE	@emp_status_code				CHAR(1)
    DECLARE @rehire_override			    CHAR(01)

    DECLARE @w_hourly_pay_rate                      float           = 0.00
    DECLARE @w_pd_salary_amt                        money           = 0.00
    DECLARE @w_pd_salary_tm_pd_id                   char(05)        = 'MONTH'
    DECLARE @w_annual_salary_amt                    money           = 0.00
    DECLARE @w_standard_daily_work_hrs              float           = 8
    DECLARE @w_standard_work_hrs                    float           = 40
    DECLARE @w_standard_work_pd_id                  char(05)        = 'WEEK'
    DECLARE @pay_frequency_code		char(05)
    DECLARE @annualizing_factor float


    --
    -- Activate these fields when testing this program standalone.
    --

    --SET @p_userid			=	'JGROSS'
    --SET @p_batchname		=	'GHR'
    --SET @p_qualifier		=	'INTERFACES'
    --SET @p_activity_date	=	GETDATE()
    --SET @p_user_id			=	'JGROSS'
    --SET @p_activity_status	=	'00'
    --SET @p_status			=	0



    --exec @ret = sp_dbs_authenticate
    --if @ret != 0 return -1



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
    DECLARE @individual_id	CHAR(10)

    -- This section declares the interface values from Global HR
    DECLARE	@event_id_01							char(02),
            @emp_id_01								char(15),
            @eff_date_01							char(10),
            @first_name_01							char(25),
            @first_middle_name_01					char(25),
            @last_name_01							char(30),
            @empl_id_01								char(10),
            @national_id_1_type_code_01				char(05),
            @national_id_1_01						char(20),
            @organization_group_id_01				char(05),
            @organization_chart_name_01				varchar(64),
            @organization_unit_name_01				varchar(240),
            @emp_status_classn_code_01				char(02),
            @position_title_01						char(60),
            @employment_type_code_01				char(05),
            @annual_salary_amt_01					char(15),
            @begin_date_02							char(10),
            @end_date_02							char(10),
            @pay_status_code_03						char(01),
            @pay_group_id_03						char(10),
            @pay_element_ctrl_grp_id_03				char(10),
            @time_reporting_meth_code_03			char(01),
            @employment_info_chg_reason_cd_03		char(05),
            @emp_location_code_03					char(10),
            @emp_status_code_5						char(02),
            @reason_code_5							char(02),
            @emp_expected_return_date_5				char(10),
            @pay_through_date_5						char(10),
            @emp_death_date_5						char(10),
            @consider_for_rehire_ind_5				char(01),
            @pay_element_desc_06					char(20),
            @emp_calculation_06						char(15)



    CREATE TABLE #tbl_ghr_msg
        (
          msg_id                                    char(15)            NOT NULL
        , msg_p1                                    char(15)            NOT NULL
        , msg_p2                                    char(15)            NOT NULL
        , msg_desc                                  char(255)           NOT NULL
        )


    -- Set first loop number
    SELECT @cnt = MIN(ID)
    FROM #ghr_employee_events_temp
    WHERE (event_id_01 = '02')

    -- Set last ID number
    SELECT @max = COUNT(ID)
    FROM #ghr_employee_events_temp
    WHERE (event_id_01 = '02')

    DELETE #tbl_ghr_msg

    WHILE (@cnt <= @max)
    BEGIN
        SELECT  @w_fatal_error = '0'

        SELECT  @event_id_01						=	t.event_id_01,
                @emp_id_01							=	t.emp_id_01,
                @eff_date_01						=	t.eff_date_01,
                @first_name_01						=	t.first_name_01,
                @first_middle_name_01				=	t.first_middle_name_01,
                @last_name_01						=	t.last_name_01,
                @empl_id_01							=	t.empl_id_01,
                @national_id_1_type_code_01			=	t.national_id_1_type_code_01,
                @national_id_1_01					=	t.national_id_1_01,
                @organization_group_id_01			=	t.organization_group_id_01,
                @organization_chart_name_01			=	t.organization_chart_name_01,
                @organization_unit_name_01			=	t.organization_unit_name_01,
                @emp_status_classn_code_01			=	t.emp_status_classn_code_01,
                @position_title_01					=	t.position_title_01,
                @employment_type_code_01			=	t.employment_type_code_01,
                @annual_salary_amt_01				=	t.annual_salary_amt_01,
                @begin_date_02						=	t.begin_date_02,
                @end_date_02						=	t.end_date_02,
                @pay_status_code_03					=	t.pay_status_code_03,
                @pay_group_id_03					=	t.pay_group_id_03,
                @pay_element_ctrl_grp_id_03			=	t.pay_element_ctrl_grp_id_03,
                @time_reporting_meth_code_03		=	t.time_reporting_meth_code_03,
                @employment_info_chg_reason_cd_03	=	t.employment_info_chg_reason_cd_03,
                @emp_location_code_03				=	t.emp_location_code_03,
                @emp_status_code_5					=	t.emp_status_code_5,
                @reason_code_5						=	t.reason_code_5,
                @emp_expected_return_date_5			=	t.emp_expected_return_date_5,
                @pay_through_date_5					=	t.pay_through_date_5,
                @emp_death_date_5					=	t.emp_death_date_5,
                @consider_for_rehire_ind_5			=	t.consider_for_rehire_ind_5,
                @pay_element_desc_06				=	t.pay_element_desc_06,
                @emp_calculation_06					=	t.emp_calculation_06
        FROM #ghr_employee_events_temp t
        WHERE t.ID = @cnt

        --
        --	This section will validate the interface data
        --
        --
        -- Override the message if this cycle contains an employee rehire record
        --
        IF  EXISTS (
                    SELECT *
                    FROM DBShrpn.dbo.ghr_employee_events ee
                    WHERE event_id_01 = '05'
                      AND ee.emp_id_01 = @emp_id_01
                      AND emp_status_code_5 = 'RH'
                   )
            SELECT @rehire_override = '1'
        ELSE
            SELECT @rehire_override = '0'

        --
        -- Check to see if the employee current status is terminated and look ahead for Rehire record.
        --

        SELECT @emp_status_code	=  emp_status_code
        FROM DBShrpn.dbo.emp_status s
        WHERE s.emp_id = @emp_id_01
          AND s.status_change_date = (
                                      SELECT MAX(status_change_date)
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
                          AND event_id_01		=	'02'

                        SET @w_fatal_error = '5'

                    END
            END


        --	Obtain the current record for this employee
        SET	@i_emp_assignment_exists = 'N'

        SELECT	@i_emp_id					= ea.emp_id,
                @i_assigned_to_code			= ea.assigned_to_code,
                @i_job_or_pos_id			= ea.job_or_pos_id,
                @i_eff_date					= ea.eff_date,
                @i_next_eff_date			= ea.next_eff_date,
                @i_prior_eff_date			= ea.prior_eff_date,
                @i_standard_work_pd_id		= ea.standard_work_pd_id,
                @i_standard_work_hrs		= ea.standard_work_hrs,
                @i_work_tm_code				= ea.work_tm_code,
                @i_emp_assignment_exists	= ea.prime_assignment_ind,
                @i_base_rate_tbl_id			= ea.base_rate_tbl_id,
                @i_base_rate_tbl_entry_code	= ea.base_rate_tbl_entry_code,
                @i_pd_salary_tm_pd_id		= ea.pd_salary_tm_pd_id
        FROM DBShrpn.dbo.emp_assignment	ea
        WHERE emp_id =	@emp_id_01
          AND eff_date = (
                          SELECT MAX(eff_date)
                          FROM DBShrpn.dbo.emp_assignment t
                          WHERE	t.emp_id = ea.emp_id
                            AND prime_assignment_ind = 'Y'
                         )
          AND prime_assignment_ind = 'Y'

        --
        --	Check to see that the new effective date is greater than the current effective date
        --
        IF	(@i_emp_assignment_exists = 'Y') AND
            (@i_eff_date > CONVERT(datetime, @eff_date_01, 112))
        BEGIN

            UPDATE DBShrpn.dbo.ghr_employee_events_aud
            SET activity_status	=	'02'
            WHERE activity_date	=	@p_activity_date
              AND emp_id_01		=	@emp_id_01
              AND event_id_01	=	'02'

            INSERT INTO #tbl_ghr_msg
            SELECT 'U00027'					AS msg_id,
                    @eff_date_01				AS msg_p1,
                    @emp_id_01					AS msg_p2,
                    'The new effective date for employee must be greater than the current effective date'	AS msg_desc

            -- Historical Message for reporting purpose
            INSERT INTO DBShrpn.dbo.ghr_historical_message
            SELECT  'U00027'					AS msg_id,
                    '02'						AS event_id,
                    @emp_id_01 				AS emp_id,
                    @eff_date_01				AS eff_date,
                    @pay_element_desc_06		AS pay_element_id,
                    @emp_id_01					AS msg_p1,
                    ''							AS msg_p2,
                    'The new effective date for employee must be greater than the current effective date'	AS msg_desc,
                    @p_activity_date			AS activity_date
            -- End of Historical Message for reporting purpose

            SELECT  @w_fatal_error = '5'

            -- GOTO BYPASS_EMPLOYEE
        END


        --
        --	Check to see if salary is blank, by pass record and send email message
        --

        IF  (@annual_salary_amt_01 = '' )
        BEGIN
                UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                SET activity_status	=	'02'
                WHERE activity_date	=	@p_activity_date
                AND emp_id_01		=	@emp_id_01
                AND event_id_01		=	'02'

                INSERT INTO #tbl_ghr_msg
                SELECT 'U00035'					AS msg_id,
                    @emp_id_01					AS msg_p1,
                    ''							AS msg_p2,
                    'Salary cannot be blank for salary change record'	AS msg_desc

                -- Historical Message for reporting purpose
            INSERT INTO DBShrpn.dbo.ghr_historical_message
            SELECT  'U00035'					AS msg_id,
                    '02'						AS event_id,
                    @emp_id_01 					AS emp_id,
                    @eff_date_01				AS eff_date,
                    @pay_element_desc_06		AS pay_element_id,
                    @emp_id_01					AS msg_p1,
                    @national_id_1_01			AS msg_p2,
                    'Salary cannot be blank for salary change record'	AS msg_desc,
                    @p_activity_date			AS activity_date
            -- End of Historical Message for reporting purpose

            SELECT  @w_fatal_error = '5'

            -- GOTO BYPASS_EMPLOYEE
        END

        --
        -- Check to see if the employee does not exists
        --
        IF NOT EXISTS (
                       SELECT *
                       FROM DBShrpn.dbo.employee
                       WHERE emp_id = @emp_id_01
                      )
        BEGIN

            UPDATE	DBShrpn.dbo.ghr_employee_events_aud
            SET activity_status	=	'02'
            WHERE activity_date	=	@p_activity_date
            AND emp_id_01		=	@emp_id_01
            AND event_id_01		=	'02'

            INSERT INTO #tbl_ghr_msg
            SELECT 'U00012'					    AS msg_id,
                   @emp_id_01					AS msg_p1,
                   ''							AS msg_p2,
                   'Employee does not exists'	AS msg_desc

                -- Historical Message for reporting purpose
            INSERT INTO DBShrpn.dbo.ghr_historical_message
            SELECT 'U00012'					    AS msg_id,
                   '02'						    AS event_id,
                   @emp_id_01 					AS emp_id,
                   @eff_date_01				    AS eff_date,
                   @pay_element_desc_06		    AS pay_element_id,
                   @emp_id_01					AS msg_p1,
                   @national_id_1_01			AS msg_p2,
                   'Employee does not exists'	AS msg_desc,
                   @p_activity_date			    AS activity_date
            -- End of Historical Message for reporting purpose

            SELECT  @w_fatal_error = '5'

            --  GOTO BYPASS_EMPLOYEE
        END

        --
        --	Check to make sure that salary is not zero.
        --
        SET @annual_salary = CAST(@annual_salary_amt_01 AS MONEY);

        IF  (
             (@annual_salary_amt_01 = '0') OR
             (@annual_salary = 0)
            )
            BEGIN

                UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status	=	'02'
                WHERE activity_date	=	@p_activity_date
                    AND emp_id_01		=	@emp_id_01
                    AND event_id_01		=	'02'

                INSERT INTO #tbl_ghr_msg
                SELECT 'U00041'					AS msg_id,
                        @emp_id_01					AS msg_p1,
                        ''							AS msg_p2,
                        'Salary cannot be zeroed for a Salary Change'	AS msg_desc

                -- Historical Message for reporting purpose
                INSERT INTO DBShrpn.dbo.ghr_historical_message
                SELECT  'U00041'					AS msg_id,
                        '02'						AS event_id,
                        @emp_id_01 					AS emp_id,
                        @eff_date_01				AS eff_date,
                        @pay_element_desc_06		AS pay_element_id,
                        @emp_id_01					AS msg_p1,
                        @national_id_1_01			AS msg_p2,
                        'Salary cannot be zeroed for a Salary Change'	AS msg_desc,
                        @p_activity_date			AS activity_date
                -- End of Historical Message for reporting purpose

                SET  @w_fatal_error = '5'

                -- GOTO BYPASS_EMPLOYEE
            END
        --
        --
        --	Check to see if pay group id exists
        --
        --
        IF NOT EXISTS (
                       SELECT *
                       FROM DBShrpn.dbo.pay_group
                       WHERE pay_group_id = @pay_group_id_03
                      )
        BEGIN

            UPDATE	DBShrpn.dbo.ghr_employee_events_aud
            SET activity_status	=	'02'
            WHERE activity_date	=	@p_activity_date
            AND emp_id_01		=	@emp_id_01
            AND event_id_01		=	'02'

            INSERT INTO #tbl_ghr_msg
            SELECT 'U00020'					AS msg_id,
                    @emp_id_01					AS msg_p1,
                    @pay_group_id_03			AS msg_p2,
                    'Pay Group does not exists'	AS msg_desc

            -- Historical Message for reporting purpose
            INSERT INTO DBShrpn.dbo.ghr_historical_message
            SELECT  'U00020'					AS msg_id,
                    '02'						AS event_id,
                    @emp_id_01 					AS emp_id,
                    @eff_date_01				AS eff_date,
                    @pay_element_desc_06		AS pay_element_id,
                    @emp_id_01					AS msg_p1,
                    @pay_group_id_03			AS msg_p2,
                    'Pay Group does not exists'	AS msg_desc,
                    @p_activity_date			AS activity_date
            -- End of Historical Message for reporting purpose

            SET @pay_group_id_03 = ' '

            SET @w_fatal_error = '5'

        END

/*
        --
        --
        --  Make sure that frequency is semi monthly starting April 1 of 2023
        --
        --
        SELECT @pay_frequency_code = pay_frequency_code
        FROM DBShrpn.dbo.pay_group
        WHERE pay_group_id = @pay_group_id_03


        IF @pay_frequency_code <> 'SEMI'
        BEGIN
            UPDATE	DBShrpn.dbo.ghr_employee_events_aud
            SET activity_status	=	'02'
            WHERE activity_date	=	@p_activity_date
            AND emp_id_01		=	@emp_id_01
            AND event_id_01		=	'02'

            INSERT INTO #tbl_ghr_msg
                SELECT 'U00048'					AS msg_id,
                        @pay_group_id_03			AS msg_p1,
                        @emp_id_01              	AS msg_p2,
                        'After April 1, 2023,Pay Group, @1, must be semi-monthly.'	AS msg_desc

                -- Historical Message for reporting purpose
                INSERT INTO DBShrpn.dbo.ghr_historical_message
                SELECT  'U00048'					AS msg_id,
                        '02'						AS event_id,
                        @emp_id_01 					AS emp_id,
                        @eff_date_01				AS eff_date,
                        @pay_element_desc_06		AS pay_element_id,
                        @pay_group_id_03			AS msg_p1,
                        @emp_id_01              	AS msg_p2,
                        'After April 1, 2023,Pay Group, ' + RTRIM(@pay_group_id_03) + ' , must be semi-monthly.'	AS msg_desc,
                        @p_activity_date			AS activity_date
                -- End of Historical Message for reporting purpose

            IF GETDATE() > '20230331' SELECT	@w_fatal_error = '5'

        END
*/

	    IF  @w_fatal_error = '5' GOTO BYPASS_EMPLOYEE

        /*
            SELECT  @event_id_01,
                    @emp_id_01,
                    @eff_date_01,
                    @first_name_01,
                    @last_name_01,
                    @empl_id_01,
                    @national_id_1_type_code_01,
                    @national_id_1_01,				-- Check if it exists
                    @organization_group_id_01,
                    @organization_chart_name_01,
                    @organization_unit_name_01,		-- Check if it exists DBSosst Structure If does not exists then blank
                    @emp_status_classn_code_01,
                    @position_title_01,
                    @employment_type_code_01,
                    @annual_salary_amt_01,
                    @begin_date_02,
                    @end_date_02,
                    @pay_status_code_03,
                    @pay_group_id_03,
                    @pay_element_ctrl_grp_id_03,
                    @time_reporting_meth_code_03,
                    @employment_info_chg_reason_cd_03,
                    @emp_location_code_03,
                    @emp_status_code_5,
                    @reason_code_5,
                    @emp_expected_return_date_5,
                    @pay_through_date_5,
                    @emp_death_date_5,
                    @consider_for_rehire_ind_5,
                    @pay_element_desc_06,
                    @emp_calculation_06
        */
        --
        --	Salary table will be removed after a salary change action.
        --
        IF	@i_base_rate_tbl_id	<> ''
            SELECT	@i_base_rate_tbl_id			= '',
                    @i_base_rate_tbl_entry_code	= ''

        --
        --	If the work tm code field is Undefined, then set it to FULL Time Worker
        --

        IF	@i_work_tm_code	=	'U'
            SET @i_work_tm_code = 'F'


        ---------------------------------------------------------------------------
        -- Calculate Annual Salary from Pay rate
        ---------------------------------------------------------------------------


        -- GOSL will only provide hourly rate
        SET @w_hourly_pay_rate = CAST(@annual_salary AS MONEY)
        -- GOSL does not use tm_pd_policy correctly
        -- Calculate Annual Salary = hourly rate * 2080
        SET @w_annual_salary_amt = ROUND(@w_hourly_pay_rate * 2080.00, 2)

        ---------------------------------------------------------------------------
        -- Lookup Pay Frequency Code
        ---------------------------------------------------------------------------
        -- GOSL not using tm_pd_policy
        SELECT @pay_frequency_code	= pay_frequency_code
             , @annualizing_factor = annualizing_factor
        FROM DBShrpn.dbo.pay_group
        WHERE pay_group_id = @pay_group_id_03

        IF (@pay_frequency_code = 'MONTH')
            SELECT @w_pd_salary_amt                 = @annual_salary / @annualizing_factor
                 , @w_pd_salary_tm_pd_id            = @pay_frequency_code
                 , @w_standard_work_pd_id           = 'WEEK'
                 , @w_standard_work_hrs             = 40.0
                 , @w_standard_daily_work_hrs       = 8.0
        ELSE    -- BIWK
            SELECT @w_pd_salary_amt                 = 0.00
                 , @w_pd_salary_tm_pd_id            = ''
                 , @w_standard_work_pd_id           = @pay_frequency_code
                 , @w_standard_work_hrs             = 40.0
                 , @w_standard_daily_work_hrs       = 8.0



        -- Check to see if the record key already exists


        IF NOT EXISTS (
                       SELECT 1
                       FROM DBShrpn.dbo.emp_assignment
                       WHERE emp_id           = @i_emp_id
                         AND assigned_to_code = @i_assigned_to_code
                         AND job_or_pos_id    = @i_job_or_pos_id
                         AND eff_date         = CAST(@eff_date_01 AS datetime)
                      )
            BEGIN

                INSERT DBShrpn.dbo.emp_assignment
                SELECT SELECT emp_id                                                 -- emp_id                                 char(15)
                            , assigned_to_code                                       -- assigned_to_code                       char(1)
                            , job_or_pos_id                                          -- job_or_pos_id                          char(10)
                            , CAST(@eff_date_01 AS datetime)                         -- eff_date                               datetime
                            , CAST('2999-12-31' AS datetime)                         -- next_eff_date                          datetime
                            , eff_date                                               -- prior_eff_date                         datetime
                            , next_assigned_to_code                                  -- next_assigned_to_code                  char(1)
                            , next_job_or_pos_id                                     -- next_job_or_pos_id                     char(10)
                            , prior_assigned_to_code                                 -- prior_assigned_to_code                 char(1)
                            , prior_job_or_pos_id                                    -- prior_job_or_pos_id                    char(10)
                            , CAST(@eff_date_01 AS datetime)                         -- begin_date                             datetime
                            , end_date                                               -- end_date                               datetime
                            , assignment_reason_code                                 -- assignment_reason_code                 char(5)
                            , organization_chart_name                                -- organization_chart_name                varchar(
                            , organization_unit_name                                 -- organization_unit_name                 varchar(
                            , organization_group_id                                  -- organization_group_id                  int
                            , organization_change_reason_cd                          -- organization_change_reason_cd          char(5)
                            , loc_code                                               -- loc_code                               char(10)
                            , mgr_emp_id                                             -- mgr_emp_id                             char(15)
                            , official_title_code                                    -- official_title_code                    char(5)
                            , official_title_date                                    -- official_title_date                    datetime
                            , CAST(@eff_date_01 AS datetime)                         -- salary_change_date                     datetime
                            , CAST(@annual_salary_amt_01 AS MONEY)                   -- annual_salary_amt                      money
                            , @i_period_amt                                          -- pd_salary_amt                          money
                            , @pay_frequency_code                                    -- pd_salary_tm_pd_id                     char(5)
                            , @i_hourly_rate_amt                                     -- hourly_pay_rate                        float
                            , curr_code                                              -- curr_code                              char(3)
                            , pay_on_reported_hrs_ind                                -- pay_on_reported_hrs_ind                char(1)
                            , 'SAL'                                                  -- salary_change_type_code                char(5)
                            , standard_work_pd_id                                    -- standard_work_pd_id                    char(5)
                            , standard_work_hrs                                      -- standard_work_hrs                      float
                            , @i_work_tm_code                                        -- work_tm_code                           char(1)
                            , work_shift_code                                        -- work_shift_code                        char(5)
                            , salary_structure_id                                    -- salary_structure_id                    char(10)
                            , salary_increase_guideline_id                           -- salary_increase_guideline_id           char(10)
                            , pay_grade_code                                         -- pay_grade_code                         char(6)
                            , pay_grade_date                                         -- pay_grade_date                         datetime
                            , job_evaluation_points_nbr                              -- job_evaluation_points_nbr              smallint
                            , salary_step_nbr                                        -- salary_step_nbr                        smallint
                            , salary_step_date                                       -- salary_step_date                       datetime
                            , phone_1_type_code                                      -- phone_1_type_code                      char(5)
                            , phone_1_fmt_code                                       -- phone_1_fmt_code                       char(6)
                            , phone_1_fmt_delimiter                                  -- phone_1_fmt_delimiter                  char(1)
                            , phone_1_intl_code                                      -- phone_1_intl_code                      char(4)
                            , phone_1_country_code                                   -- phone_1_country_code                   char(4)
                            , phone_1_area_city_code                                 -- phone_1_area_city_code                 char(5)
                            , phone_1_nbr                                            -- phone_1_nbr                            char(12)
                            , phone_1_extension_nbr                                  -- phone_1_extension_nbr                  char(5)
                            , phone_2_type_code                                      -- phone_2_type_code                      char(5)
                            , phone_2_fmt_code                                       -- phone_2_fmt_code                       char(6)
                            , phone_2_fmt_delimiter                                  -- phone_2_fmt_delimiter                  char(1)
                            , phone_2_intl_code                                      -- phone_2_intl_code                      char(4)
                            , phone_2_country_code                                   -- phone_2_country_code                   char(4)
                            , phone_2_area_city_code                                 -- phone_2_area_city_code                 char(5)
                            , phone_2_nbr                                            -- phone_2_nbr                            char(12)
                            , phone_2_extension_nbr                                  -- phone_2_extension_nbr                  char(5)
                            , prime_assignment_ind                                   -- prime_assignment_ind                   char(1)
                            , pay_basis_code                                         -- pay_basis_code                         char(1)
                            , occupancy_code                                         -- occupancy_code                         char(1)
                            , regulatory_reporting_unit_code                         -- regulatory_reporting_unit_code         char(10)
                            , @i_base_rate_tbl_id                                    -- base_rate_tbl_id                       char(10)
                            , @i_base_rate_tbl_entry_code                            -- base_rate_tbl_entry_code               char(8)
                            , shift_differential_rate_tbl_id                         -- shift_differential_rate_tbl_id         char(10)
                            , ref_annual_salary_amt                                  -- ref_annual_salary_amt                  money
                            , ref_pd_salary_amt                                      -- ref_pd_salary_amt                      money
                            , ref_pd_salary_tm_pd_id                                 -- ref_pd_salary_tm_pd_id                 char(5)
                            , ref_hourly_pay_rate                                    -- ref_hourly_pay_rate                    float
                            , guaranteed_annual_salary_amt                           -- guaranteed_annual_salary_amt           money
                            , guaranteed_pd_salary_amt                               -- guaranteed_pd_salary_amt               money
                            , guaranteed_pd_salary_tm_pd_id                          -- guaranteed_pd_salary_tm_pd_id          char(5)
                            , guaranteed_hourly_pay_rate                             -- guaranteed_hourly_pay_rate             float
                            , exception_rate_ind                                     -- exception_rate_ind                     char(1)
                            , overtime_status_code                                   -- overtime_status_code                   char(2)
                            , shift_differential_status_code                         -- shift_differential_status_code         char(2)
                            , standard_daily_work_hrs                                -- standard_daily_work_hrs                money
                            , user_amt_1                                             -- user_amt_1                             float
                            , user_amt_2                                             -- user_amt_2                             float
                            , user_code_1                                            -- user_code_1                            char(5)
                            , user_code_2                                            -- user_code_2                            char(5)
                            , user_date_1                                            -- user_date_1                            datetime
                            , user_date_2                                            -- user_date_2                            datetime
                            , user_ind_1                                             -- user_ind_1                             char(1)
                            , user_ind_2                                             -- user_ind_2                             char(1)
                            , user_monetary_amt_1                                    -- user_monetary_amt_1                    money
                            , user_monetary_amt_2                                    -- user_monetary_amt_2                    money
                            , user_monetary_curr_code                                -- user_monetary_curr_code                char(3)
                            , user_text_1                                            -- user_text_1                            char(50)
                            , user_text_2                                            -- user_text_2                            char(50)
                            , unemployment_loc_code                                  -- unemployment_loc_code                  char(10)
                            , include_salary_in_autopay_ind                          -- include_salary_in_autopay_ind          char(1)
                            , chgstamp                                               -- chgstamp                               smallint
                FROM DBShrpn.dbo.emp_assignment
                WHERE	emp_id				=	@i_emp_id
                AND		assigned_to_code	=	@i_assigned_to_code
                AND		job_or_pos_id		=	@i_job_or_pos_id
                AND		eff_date			=	@i_eff_date
                AND		next_eff_date		=	@i_next_eff_date
                AND		prior_eff_date		=	@i_prior_eff_date


                UPDATE DBShrpn.dbo.emp_assignment
                SET		next_eff_date		=	CAST(@eff_date_01 AS datetime) --, end_date = CAST(@eff_date_01 AS datetime)
                WHERE	emp_id				=	@i_emp_id
                AND		assigned_to_code	=	@i_assigned_to_code
                AND		job_or_pos_id		=	@i_job_or_pos_id
                AND		eff_date			=	@i_eff_date
                AND		next_eff_date		=	@i_next_eff_date
                AND		prior_eff_date		=	@i_prior_eff_date

            END
		ELSE
			BEGIN

                UPDATE DBShrpn.dbo.emp_assignment
                SET		annual_salary_amt			=	CAST(@annual_salary_amt_01 AS MONEY),
                        hourly_pay_rate				=	@i_hourly_rate_amt,
                        salary_change_date			=	CAST(@eff_date_01 AS datetime),
                        pd_salary_amt				=	@i_period_amt,
                        salary_change_type_code		=	'SAL',
                        work_tm_code				=	@i_work_tm_code,
                        base_rate_tbl_id			=	@i_base_rate_tbl_id,
                        base_rate_tbl_entry_code	=	@i_base_rate_tbl_entry_code
                WHERE	emp_id					=	@i_emp_id
                AND		assigned_to_code		=	@i_assigned_to_code
                AND		job_or_pos_id			=	@i_job_or_pos_id
                AND		eff_date				=	@i_eff_date
                AND		next_eff_date			=	@i_next_eff_date
                AND		prior_eff_date			=	@i_prior_eff_date
			END

        --
        -- Update the position since could be a new position with a new salary
        --
        SELECT @individual_id = individual_id
        FROM DBShrpn.dbo.employee
        WHERE emp_id = @emp_id_01


        -- UPDATE	DBShrpn.dbo.individual_personal
        -- SET	user_text_1		=	CAST(@position_title_01 AS CHAR(50))
        -- WHERE individual_id	=	@individual_id
        ---------------------------------------------------------------------------
        -- GOSL update NIC and Tax Code
        ---------------------------------------------------------------------------
        -- CJP 7/7/2025
        UPDATE	DBShrpn.dbo.individual_personal
        SET	user_ind_1 = @nic_flag
          , user_ind_2 = @tax_flag
        WHERE (individual_id = @individual_id)



        --
        --
        --

	    BYPASS_EMPLOYEE:

	    SELECT @cnt = @cnt + 1

    END     -- End While loop

    --
    -- Notify the users of all the issues
    --

    --
    -- Send notification of warning message U00014  -- < SALARY CHANGE SECTION (02) >
    --

    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    -- SELECT *
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00014'

    SELECT @max = COUNT(*)
    --  SELECT *
    FROM DBShrpn.dbo.ghr_employee_events
    WHERE event_id_01 = '02'
    SELECT @maxx = CAST(@max AS CHAR(06))
    SELECT @special_value_exists = 0
    SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)
    SELECT @msg_id = 'U00014'

    SELECT @w_msg_text_2 = ''

    EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2 @p_userid,
        @p_batchname,
        @p_qualifier,
        @msg_id ,
        @w_severity_cd,
        @w_msg_text,
        @w_msg_text_2,
        @w_msg_text_3

    --
    -- End of Sending notification of warning message U00014
    --

    --
    -- Send notification of warning message U00009  -- < BEGINING OF WARNING MESSAGES: >
    --

    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    --  SELECT *
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00009'

    SELECT @max = COUNT(*)
    --  SELECT *
    FROM DBShrpn.dbo.ghr_employee_events
    WHERE event_id_01 = '02'
    SELECT @maxx = CAST(@max AS CHAR(06))
    SELECT @special_value_exists = 0
    SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)
    SELECT @msg_id = 'U00009'

    SELECT @w_msg_text_2 = ''

    EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2 @p_userid,
        @p_batchname,
        @p_qualifier,
        @msg_id ,
        @w_severity_cd,
        @w_msg_text,
        @w_msg_text_2,
        @w_msg_text_3

    --
    -- End of Sending notification of warning message U00009
    --

    --
    -- Send notification of warning message U00011 -- Blank Line
    --

    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    --  SELECT *
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00011'

    SELECT @maxx = CAST(@max AS CHAR(06))
    SELECT @special_value_exists = 0
    SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)
    SELECT @msg_id = 'U00011'

    SELECT @w_msg_text_2 = ''

    EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2 @p_userid,
        @p_batchname,
        @p_qualifier,
        @msg_id ,
        @w_severity_cd,
        @w_msg_text,
        @w_msg_text_2,
        @w_msg_text_3

    --
    -- Send notification of warning message U00015  -- Total Global HR Salary Change:
    --

    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    --  SELECT *
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00015'

    SELECT @max = COUNT(*)
    --  SELECT *
    FROM DBShrpn.dbo.ghr_employee_events
    WHERE event_id_01 = '02'
    SELECT @maxx = CAST(@max AS CHAR(06))
    SELECT @special_value_exists = 0
    SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)
    SELECT @msg_id = 'U00015'

    IF @special_value_exists <> 0 SELECT @w_msg_text = REPLACE(@w_msg_text,'@1',RTRIM(@maxx))
    SELECT @w_msg_text_2 = ''

    EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2 @p_userid,
        @p_batchname,
        @p_qualifier,
        @msg_id ,
        @w_severity_cd,
        @w_msg_text,
        @w_msg_text_2,
        @w_msg_text_3



    --
    -- Send notification of warning message U00012 -- Employee does not exists Message
    --

    IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'dbo.ghr_message_temp_2') AND type in (N'U'))
        DROP TABLE dbo.ghr_message_temp_2


    CREATE TABLE dbo.ghr_message_temp_2(
        ID							int IDENTITY(1,1) NOT NULL,
        msg_id						char(15)	NOT NULL,
        msg_p1						char(15)	NOT NULL,
        msg_p2						char(15)	NOT NULL,
        msg_desc						char(255) NOT NULL
    )


    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00012'

    INSERT INTO DBShrpn.dbo.ghr_message_temp_2
    SELECT *
    FROM #tbl_ghr_msg
    WHERE msg_id = 'U00012'

    SET @cnt = 1

    SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_2


    WHILE (@cnt <= @max)
    BEGIN

        SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_2 t1 WHERE t1.ID = @cnt

        SELECT @special_value_exists = 0
        SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)
        SELECT @maxx = CAST(@max AS CHAR(06))

        IF @special_value_exists <> 0 SELECT @w_msg_text = REPLACE(@w_msg_text,'@1',RTRIM(@msg_p1))


        SELECT @special_value_exists = 0
        SELECT @special_value_exists = CHARINDEX('@2',@w_msg_text,1)

        IF @special_value_exists <> 0 SELECT @w_msg_text = REPLACE(@w_msg_text,'@2',RTRIM(@msg_p1))

        SELECT @w_msg_text_2 = ''

        EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2 @p_userid,
            @p_batchname,
            @p_qualifier,
            @msg_id ,
            @w_severity_cd,
            @w_msg_text,
            @w_msg_text_2,
            @w_msg_text_3

        SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
        FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00012'

        SELECT @cnt = @cnt + 1;

    END
    --
    --	End of warning message U00012
    --


    --
    -- Send notification of warning message U00020 -- Pay Group, @1, does not exists for employee, @2 - defaulting 99999
    --
    IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'dbo.ghr_message_temp_2') AND type in (N'U'))
        DROP TABLE dbo.ghr_message_temp_2


    CREATE TABLE dbo.ghr_message_temp_2(
        ID							int IDENTITY(1,1) NOT NULL,
        msg_id						char(15)	NOT NULL,
        msg_p1						char(15)	NOT NULL,
        msg_p2						char(15)	NOT NULL,
        msg_desc						char(255) NOT NULL
    )

    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    --	SELECT *
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00020'

    INSERT INTO DBShrpn.dbo.ghr_message_temp_2
    SELECT *
    FROM #tbl_ghr_msg
    WHERE msg_id = 'U00020'

    SET @cnt = 1

    SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_2


    WHILE (@cnt <= @max)
    BEGIN

        SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_2 t2 WHERE t2.ID = @cnt

        SELECT @special_value_exists = 0
        SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)

        IF @special_value_exists <> 0 SELECT @w_msg_text = REPLACE(@w_msg_text,'@1', RTRIM(@msg_p2))

        SELECT @special_value_exists = 0; SELECT @special_value_exists = CHARINDEX('@2',@w_msg_text,1)

        IF @special_value_exists <> 0 SELECT @w_msg_text = REPLACE(@w_msg_text,'@2', RTRIM(@msg_p1))

        SELECT @w_msg_text_2 =''

        EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2 @p_userid,
            @p_batchname,
            @p_qualifier,
            @msg_id ,
            @w_severity_cd,
            @w_msg_text,
            @w_msg_text_2,
            @w_msg_text_3

        SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
        --    SELECT *
        FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00020'

        SELECT @cnt = @cnt + 1;

    END -- End of Message Loop


    --
    -- Send notification of warning message U00027 -- The new effective date, @1 , for employee, @2, must be greater than the current effective date
    --

    IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'dbo.ghr_message_temp_2') AND type in (N'U'))
        DROP TABLE dbo.ghr_message_temp_2


    CREATE TABLE dbo.ghr_message_temp_2(
        ID							int IDENTITY(1,1) NOT NULL,
        msg_id						char(15)	NOT NULL,
        msg_p1						char(15)	NOT NULL,
        msg_p2						char(15)	NOT NULL,
        msg_desc						char(255) NOT NULL
    )


    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00027'

    INSERT INTO DBShrpn.dbo.ghr_message_temp_2
    SELECT *
    FROM #tbl_ghr_msg
    WHERE msg_id = 'U00027'

    SET @cnt = 1

    SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_2


    WHILE (@cnt <= @max)
    BEGIN

        SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_2 t2 WHERE t2.ID = @cnt

        SELECT @special_value_exists = 0
        SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)

        IF @special_value_exists <> 0 SELECT @w_msg_text = REPLACE(@w_msg_text,'@1',RTRIM(@msg_p1))


        SELECT @special_value_exists = 0
        SELECT @special_value_exists = CHARINDEX('@2',@w_msg_text,1)

        IF @special_value_exists <> 0 SELECT @w_msg_text = REPLACE(@w_msg_text,'@2',RTRIM(@msg_p2))

        SELECT @w_msg_text_2 = ''

        EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2 @p_userid,
            @p_batchname,
            @p_qualifier,
            @msg_id ,
            @w_severity_cd,
            @w_msg_text,
            @w_msg_text_2,
            @w_msg_text_3

        SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
        FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00027'

        SELECT @cnt = @cnt + 1;

    END
    --
    --	End of warning message U00027
    --



    --
    -- Send notification of warning message U00035 -- Salary cannot be blank for salary change record. Employee ID: @1
    --

    IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'dbo.ghr_message_temp_2') AND type in (N'U'))
        DROP TABLE dbo.ghr_message_temp_2


    CREATE TABLE dbo.ghr_message_temp_2(
        ID							int IDENTITY(1,1) NOT NULL,
        msg_id						char(15)	NOT NULL,
        msg_p1						char(15)	NOT NULL,
        msg_p2						char(15)	NOT NULL,
        msg_desc						char(255) NOT NULL
    )


    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00035'

    INSERT INTO DBShrpn.dbo.ghr_message_temp_2
    SELECT *
    FROM #tbl_ghr_msg
    WHERE msg_id = 'U00035'

    SET @cnt = 1

    SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_2


    WHILE (@cnt <= @max)
    BEGIN

        SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_2 t1 WHERE t1.ID = @cnt

        SELECT @special_value_exists = 0
        SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)
        SELECT @maxx = CAST(@max AS CHAR(06))

        IF @special_value_exists <> 0 SELECT @w_msg_text = REPLACE(@w_msg_text,'@1',RTRIM(@msg_p1))


        SELECT @special_value_exists = 0
        SELECT @special_value_exists = CHARINDEX('@2',@w_msg_text,1)

        IF @special_value_exists <> 0 SELECT @w_msg_text = REPLACE(@w_msg_text,'@2',RTRIM(@msg_p1))

        SELECT @w_msg_text_2 = ''

        EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2 @p_userid,
            @p_batchname,
            @p_qualifier,
            @msg_id ,
            @w_severity_cd,
            @w_msg_text,
            @w_msg_text_2,
            @w_msg_text_3

        SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
        FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00035'

        SELECT @cnt = @cnt + 1;

    END
    --
    --	End of warning message U00035
    --



    --
    -- Send notification of warning message U00041 -- Salary cannot be zeroed for a Salary Change
    --

    IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'dbo.ghr_message_temp_2') AND type in (N'U'))
        DROP TABLE dbo.ghr_message_temp_2


    CREATE TABLE dbo.ghr_message_temp_2(
        ID							int IDENTITY(1,1) NOT NULL,
        msg_id						char(15)	NOT NULL,
        msg_p1						char(15)	NOT NULL,
        msg_p2						char(15)	NOT NULL,
        msg_desc						char(255) NOT NULL
    )


    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00041'

    INSERT INTO DBShrpn.dbo.ghr_message_temp_2
    SELECT *
    FROM #tbl_ghr_msg
    WHERE msg_id = 'U00041'

    SET @cnt = 1

    SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_2


    WHILE (@cnt <= @max)
    BEGIN

        SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_2 t2 WHERE t2.ID = @cnt

        SELECT @special_value_exists = 0
        SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)
        SELECT @maxx = CAST(@max AS CHAR(06))

        IF @special_value_exists <> 0 SELECT @w_msg_text = REPLACE(@w_msg_text,'@1',RTRIM(@msg_p1))


        SELECT @special_value_exists = 0
        SELECT @special_value_exists = CHARINDEX('@2',@w_msg_text,1)

        IF @special_value_exists <> 0 SELECT @w_msg_text = REPLACE(@w_msg_text,'@2',RTRIM(@msg_p1))

        SELECT @w_msg_text_2 = ''

        EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2 @p_userid,
            @p_batchname,
            @p_qualifier,
            @msg_id ,
            @w_severity_cd,
            @w_msg_text,
            @w_msg_text_2,
            @w_msg_text_3

        SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
        FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00041'

        SELECT @cnt = @cnt + 1;

    END
    --
    --	End of warning message U00041
    --



    --
    -- Send notification of warning message U00011 -- Blank Line
    --

    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    --  SELECT *
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00011'

    SELECT @maxx = CAST(@max AS CHAR(06))
    SELECT @special_value_exists = 0
    SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)
    SELECT @msg_id = 'U00011'

    SELECT @w_msg_text_2 = ''

    EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2 @p_userid,
        @p_batchname,
        @p_qualifier,
        @msg_id ,
        @w_severity_cd,
        @w_msg_text,
        @w_msg_text_2,
        @w_msg_text_3

    --
    -- Send notification of warning message U00010 -- <ENDING OF WARNING MESSAGES: >
    --

    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    --  SELECT *
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00010'

    SELECT @maxx = CAST(@max AS CHAR(06))
    SELECT @special_value_exists = 0
    SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)
    SELECT @msg_id = 'U00010'

    SELECT @w_msg_text_2 = ''

    EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2 @p_userid,
        @p_batchname,
        @p_qualifier,
        @msg_id ,
        @w_severity_cd,
        @w_msg_text,
        @w_msg_text_2,
        @w_msg_text_3

    --
    -- Send notification of warning message U00011 -- Blank Line
    --

    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    --  SELECT *
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00011'

    SELECT @maxx = CAST(@max AS CHAR(06))
    SELECT @special_value_exists = 0
    SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)
    SELECT @msg_id = 'U00011'

    SELECT @w_msg_text_2 = ''

    EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2 @p_userid,
        @p_batchname,
        @p_qualifier,
        @msg_id ,
        @w_severity_cd,
        @w_msg_text,
        @w_msg_text_2,
        @w_msg_text_3

    /*

    SELECT @p_status = 0

    */

END
GO


ALTER AUTHORIZATION ON dbo.usp_ins_salary_change TO  SCHEMA OWNER
GO
