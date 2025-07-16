USE [DBShrpn]
GO

SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE OR ALTER PROCEDURE [dbo].[usp_ins_status_change]
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
    DECLARE @w_eff_date_01					datetime
    DECLARE @w_curr_status					char(02)
    DECLARE	@w_pos_eff_date					datetime
    DECLARE @w_assigned_to_code             char(01)
    DECLARE @w_job_or_pos_id                char(10)
    DECLARE @w_pd_salary_tm_pd_id           char(05)
    DECLARE @old_eff_date					datetime

    DECLARE @pay_frequency_code		        char(05)
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
    DECLARE @i_eff_date_02					datetime
    DECLARE @i_next_eff_date				datetime
    DECLARE @i_prior_eff_date				datetime
    DECLARE @i_standard_work_pd_id			char(5)
    DECLARE @i_standard_work_hrs			float
    DECLARE @i_yearly_std_work_hrs			float
    DECLARE @i_hourly_rate_amt				money
    DECLARE @i_period_amt					money

    DECLARE @w_ee_eff_date					datetime

    --
    -- Activate these fields when testing this program standalone.
    --

    --SET @p_userid			=	'DBS'
    --SET @p_batchname		=	'GHR'
    --SET @p_qualifier		=	'INTERFACES'
    --SET @p_activity_date	=	'2021-09-10'
    --SET @p_user_id			=	'DBS'
    --SET @p_activity_status	=	'00'
    --SET @p_status			=	0



    --exec @ret = sp_dbs_authenticate
    --if @ret != 0 return -1

    IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_employee_events_temp5]') AND type in (N'U'))
        DROP TABLE [dbo].[ghr_employee_events_temp5]


    CREATE TABLE [dbo].[ghr_employee_events_temp5](
        [ID]									[int]	IDENTITY(1,1) NOT NULL,
        [event_id_01]							[char](02) NULL,
        [emp_id_01]								[char](15) NULL,
        [eff_date_01]							[char](10) NULL,
        [first_name_01]							[char](25) NULL,
        [first_middle_name_01]					[char](25) NULL,
        [last_name_01]							[char](30) NULL,
        [empl_id_01]							[char](10) NULL,
        [national_id_1_type_code_01]			[char](05) NULL,
        [national_id_1_01]						[char](20) NULL,
        [organization_group_id_01]				[char](05) NULL,
        [organization_chart_name_01]			[varchar](64) NULL,
        [organization_unit_name_01]				[varchar](240) NULL,
        [emp_status_classn_code_01]				[char](02) NULL,
        [position_title_01]						[char](60) NULL,
        [employment_type_code_01]				[char](05) NULL,
        [annual_salary_amt_01]					[char](15) NULL,
        [begin_date_02]							[char](10) NULL,
        [end_date_02]							[char](10) NULL,
        [pay_status_code_03]					[char](01) NULL,
        [pay_group_id_03]						[char](10) NULL,
        [pay_element_ctrl_grp_id_03]			[char](10) NULL,
        [time_reporting_meth_code_03]			[char](01) NULL,
        [employment_info_chg_reason_cd_03]		[char](05) NULL,
        [emp_location_code_03]					[char](10) NULL,
        [emp_status_code_5]						[char](02) NULL,
        [reason_code_5]							[char](02) NULL,
        [emp_expected_return_date_5]			[char](10) NULL,
        [pay_through_date_5]					[char](10) NULL,
        [emp_death_date_5]						[char](10) NULL,
        [consider_for_rehire_ind_5]				[char](01) NULL,
        [pay_element_desc_06]					[char](20) NULL,
        [emp_calculation_06]					[char](15) NULL
    )

    INSERT INTO DBShrpn.dbo.ghr_employee_events_temp5    ---#t0
    SELECT *
    FROM DBShrpn.dbo.ghr_employee_events
    WHERE [event_id_01] = '05' --AND emp_id_01 = '1012529'

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
    DECLARE @pay_status_code	CHAR(01)


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

    SELECT @w_todays_date = convert(char(12),getdate(),101)

    SET @cnt = 1

    SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_employee_events_temp5

    DELETE DBShrpn.dbo.ghr_msg_tbl

    WHILE (@cnt <= @max)
    BEGIN
        SELECT  @w_fatal_error = '0'

        SELECT  @event_id_01						=	event_id_01,
                @emp_id_01							=	emp_id_01,
                @eff_date_01						=	eff_date_01,
                @first_name_01						=	first_name_01,
                @first_middle_name_01				=	first_middle_name_01,
                @last_name_01						=	last_name_01,
                @empl_id_01							=	empl_id_01,
                @national_id_1_type_code_01			=	national_id_1_type_code_01,
                @national_id_1_01					=	national_id_1_01,
                @organization_group_id_01			=	organization_group_id_01,
                @organization_chart_name_01			=	organization_chart_name_01,
                @organization_unit_name_01			=	organization_unit_name_01,
                @emp_status_classn_code_01			=	emp_status_classn_code_01,
                @position_title_01					=	position_title_01,
                @employment_type_code_01			=	employment_type_code_01,
                @annual_salary_amt_01				=	annual_salary_amt_01,
                @begin_date_02						=	begin_date_02,
                @end_date_02						=	end_date_02,
                @pay_status_code_03					=	pay_status_code_03,
                @pay_group_id_03					=	pay_group_id_03,
                @pay_element_ctrl_grp_id_03			=	pay_element_ctrl_grp_id_03,
                @time_reporting_meth_code_03		=	time_reporting_meth_code_03,
                @employment_info_chg_reason_cd_03	=	employment_info_chg_reason_cd_03,
                @emp_location_code_03				=	emp_location_code_03,
                @emp_status_code_5					=	emp_status_code_5,
                @reason_code_5						=	reason_code_5,
                @emp_expected_return_date_5			=	emp_expected_return_date_5,
                @pay_through_date_5					=	pay_through_date_5,
                @emp_death_date_5					=	emp_death_date_5,
                @consider_for_rehire_ind_5			=	consider_for_rehire_ind_5,
                @pay_element_desc_06				=	pay_element_desc_06,
                @emp_calculation_06					=	emp_calculation_06
        FROM DBShrpn.dbo.ghr_employee_events_temp5 t WHERE t.ID = @cnt

        --
        --	This section will validate the interface data
        --

        --
        --	Obtain the current status record
        --
        SELECT @w_status_change_date		=	status_change_date,
                @w_old_chgstamp				=	chgstamp,
                @w_curr_status				=	emp_status_code
            --	SELECT *
        FROM [DBShrpn].[dbo].[emp_status] s WHERE [emp_id] = @emp_id_01																			--'1002123'
        AND status_change_date = (SELECT MAX(status_change_date) FROM [DBShrpn].[dbo].[emp_status] t WHERE t.[emp_id]	=	@emp_id_01)

        SELECT @w_curr_status_value =  CASE WHEN @w_curr_status = 'I'  THEN 'Inactive'
                                            WHEN @w_curr_status = 'T'  THEN 'Terminate'
                                            WHEN @w_curr_status = 'A'  THEN 'Active'
            END

        --
        -- Check to see if the employee does not exists
        --

        IF  NOT EXISTS (SELECT * FROM DBShrpn.dbo.emp_status WHERE emp_id = @emp_id_01)
            BEGIN
                UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status	=	'02'
                WHERE activity_date	=	@p_activity_date
                    AND emp_id_01		=	@emp_id_01
                    AND event_id_01		=	'05'

                INSERT INTO DBShrpn.dbo.ghr_msg_tbl
                SELECT 'U00012'					As msg_id,
                        @emp_id_01					As msg_p1,
                        @emp_id_01					As msg_p2,
                        'Employee does not exists'	As msg_desc

                -- Historical Message for reporting purpose
                INSERT INTO DBShrpn.dbo.ghr_historical_message
                SELECT  'U00012'						As msg_id,
                        '05'							As event_id,
                        @emp_id_01 						As emp_id,
                        @eff_date_01					As eff_date,
                        @pay_element_desc_06			As pay_element_id,
                        @emp_id_01						As msg_p1,
                        @emp_id_01						As msg_p2,
                        'Employee does not exists'		As msg_desc,
                        @p_activity_date				AS activity_date
                -- End of Historical Message for reporting purpose

                SELECT  @w_fatal_error = '5'

                -- GOTO BYPASS_EMPLOYEE
            END

        --
        -- Check to see if the employer exists
        --

        IF NOT EXISTS (SELECT * FROM [DBShrpn].[dbo].[employer] WHERE empl_id = @empl_id_01)
        BEGIN

            IF EXISTS (SELECT * FROM [DBShrpn].[dbo].[employer] WHERE empl_id = '0' + @empl_id_01)
                SELECT @empl_id_01	= '0' + @empl_id_01
            ELSE
                BEGIN

                    UPDATE DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status	= '02'
                    WHERE activity_date	=	@p_activity_date
                    AND emp_id_01		=	@emp_id_01
                    AND event_id_01		=	'05'

                    INSERT INTO DBShrpn.dbo.ghr_msg_tbl
                    SELECT 'U00005'					As msg_id,
                            @emp_id_01					As msg_p1,
                            @empl_id_01					As msg_p2,
                            'Employer does not exists - defaulting 99999'	As msg_desc

                    -- Historical Message for reporting purpose
                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                    SELECT  'U00005'					As msg_id,
                            '05'						As event_id,
                            @emp_id_01 					As emp_id,
                            @eff_date_01				As eff_date,
                            @pay_element_desc_06		As pay_element_id,
                            @emp_id_01					As msg_p1,
                            @empl_id_01					As msg_p2,
                            'Employer does not exists - defaulting 99999'	As msg_desc,
                            @p_activity_date			AS activity_date
                    -- End of Historical Message for reporting purpose

                    SELECT @empl_id_01 = '99999'

                END
        END

        --
        -- Check to see that the new record is greater than the existing record.
        --
        IF  @w_status_change_date >= @eff_date_01
            BEGIN
                UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status	=	'02'
                WHERE activity_date	=	@p_activity_date
                    AND emp_id_01		=	@emp_id_01
                    AND event_id_01		=	'05'

                INSERT INTO DBShrpn.dbo.ghr_msg_tbl
                SELECT 'U00037'					As msg_id,
                        @emp_id_01					As msg_p1,
                        @emp_id_01					As msg_p2,
                        'New Status Effective date must be greater than current effective date.'	As msg_desc

                -- Historical Message for reporting purpose
                INSERT INTO DBShrpn.dbo.ghr_historical_message
                SELECT  'U00037'						As msg_id,
                        '05'							As event_id,
                        @emp_id_01 						As emp_id,
                        @eff_date_01					As eff_date,
                        @pay_element_desc_06			As pay_element_id,
                        @emp_id_01						As msg_p1,
                        @emp_id_01						As msg_p2,
                        'New Status Effective date must be greater than current effective date.'	As msg_desc,
                        @p_activity_date				AS activity_date
                -- End of Historical Message for reporting purpose

                SELECT  @w_fatal_error = '5'

                -- GOTO BYPASS_EMPLOYEE

            END

        --
        -- Check to see if the transfer date is greater than position effective date.
        --
		SELECT @w_pos_eff_date = eff_date FROM DBShrpn.dbo.position WHERE pos_id = '99999'

        IF  @w_pos_eff_date > CAST(@eff_date_01 AS datetime)
            BEGIN
                UPDATE DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status	= '02'
                    WHERE activity_date	=	@p_activity_date
                    AND emp_id_01		=	@emp_id_01
                    AND event_id_01		=	'05'

                INSERT INTO DBShrpn.dbo.ghr_msg_tbl
                SELECT 'U00036'				As msg_id,
                        @emp_id_01			As msg_p1,
                        @empl_id_01			As msg_p2,
                'Transfer date must be greater than default position effective date'	As msg_desc

                -- Historical Message for reporting purpose
                INSERT INTO DBShrpn.dbo.ghr_historical_message
                SELECT  'U00036'						As msg_id,
                        '05'							As event_id,
                        @emp_id_01 						As emp_id,
                        @eff_date_01					As eff_date,
                        @pay_element_desc_06			As pay_element_id,
                        @emp_id_01						As msg_p1,
                        @empl_id_01						As msg_p2,
                        'Transfer date must be greater than default position effective date'		As msg_desc,
                        @p_activity_date				AS activity_date
                    -- End of Historical Message for reporting purpose

                SELECT  @w_fatal_error = '5'

                -- GOTO BYPASS_EMPLOYEE

            END

        --
        -- Check to see if the rehire date is greater than employee employment effective date.
        --
        SELECT @w_ee_eff_date = eff_date
        FROM DBShrpn.dbo.emp_employment ee
        WHERE ee.eff_date = (
                            SELECT MAX(t.eff_date)
                            FROM DBShrpn.dbo.emp_employment t
                            WHERE t.emp_id = ee.emp_id
                           )
          AND ee.emp_id = @emp_id_01

        IF  @w_ee_eff_date >= CAST(@eff_date_01 AS datetime)
            BEGIN

                UPDATE DBShrpn.dbo.ghr_employee_events_aud
                SET activity_status = '02'
                WHERE activity_date = @p_activity_date
                  AND emp_id_01     = @emp_id_01
                  AND event_id_01   = '05'

                INSERT INTO DBShrpn.dbo.ghr_msg_tbl
                SELECT 'U00043' As msg_id,
                       @emp_id_01 As msg_p1,
                       @empl_id_01 As msg_p2,
                       'Rehire date must be greater than current employee employment effective date' As msg_desc

                -- Historical Message for reporting purpose
                INSERT INTO DBShrpn.dbo.ghr_historical_message
                SELECT  'U00043'						As msg_id,
                        '05'							As event_id,
                        @emp_id_01 						As emp_id,
                        @eff_date_01					As eff_date,
                        @pay_element_desc_06			As pay_element_id,
                        @emp_id_01						As msg_p1,
                        @empl_id_01						As msg_p2,
                        'Rehire date must be greater than current employee employment effective date'		As msg_desc,
                        @p_activity_date				AS activity_date
                -- End of Historical Message for reporting purpose

                SELECT  @w_fatal_error = '5'

                -- GOTO BYPASS_EMPLOYEE

            END


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
        --	Check to see if pay group id exists
        --
        IF NOT EXISTS(
                      SELECT *
                      FROM	[DBShrpn].[dbo].[pay_group]
                      WHERE	pay_group_id = @pay_group_id_03
                     )
            BEGIN

                UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                SET activity_status	=	'02'
                WHERE activity_date	=	@p_activity_date
                AND emp_id_01		=	@emp_id_01

                INSERT INTO DBShrpn.dbo.ghr_msg_tbl
                SELECT 'U00020'					As msg_id,
                        @pay_group_id_03			As msg_p1,
                        @emp_id_01					As msg_p2,
                        'Pay Group does not exists'	As msg_desc

                -- Historical Message for reporting purpose
                INSERT INTO DBShrpn.dbo.ghr_historical_message
                SELECT  'U00020'						As msg_id,
                        '05'							As event_id,
                        @emp_id_01 						As emp_id,
                        @eff_date_01					As eff_date,
                        @pay_element_desc_06			As pay_element_id,
                        @pay_group_id_03				As msg_p1,
                        @emp_id_01						As msg_p2,
                        'Pay Group does not exists'		As msg_desc,
                        @p_activity_date				AS activity_date
                -- End of Historical Message for reporting purpose

                SELECT	@pay_group_id_03 = ' '

                SELECT  @w_fatal_error = '5'

            END

        --
        --	Check to see if pay element control group exists
        --
        IF NOT EXISTS(SELECT * FROM	[DBShrpn].[dbo].[pay_element_ctrl_grp] WHERE	pay_element_ctrl_grp_id = @pay_element_ctrl_grp_id_03)
            BEGIN

                UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                SET activity_status	=	'02'
                WHERE activity_date	=	@p_activity_date
                AND emp_id_01		=	@emp_id_01

                INSERT INTO DBShrpn.dbo.ghr_msg_tbl
                    SELECT 'U00021'					As msg_id,
                            @emp_id_01					As msg_p1,
                            @emp_id_01					As msg_p2,
                            'Pay Element Control Group does not exists'	As msg_desc

                -- Historical Message for reporting purpose
                INSERT INTO DBShrpn.dbo.ghr_historical_message
                SELECT  'U00021'						As msg_id,
                        '05'							As event_id,
                        @emp_id_01 						As emp_id,
                        @eff_date_01					As eff_date,
                        @pay_element_desc_06			As pay_element_id,
                        @emp_id_01						As msg_p1,
                        @emp_id_01						As msg_p2,
                        'Pay Element Control Group does not exists'	 As msg_desc,
                        @p_activity_date				AS activity_date
                -- End of Historical Message for reporting purpose

                SELECT	@pay_element_ctrl_grp_id_03 = ' '

                SELECT  @w_fatal_error = '5'

            END

        --
        --
        --  Make sure that frequency is semi monthly starting April 1 of 2023
        --
        --
        SELECT @pay_frequency_code	= pay_frequency_code
        FROM [DBShrpn].[dbo].[pay_group]
        WHERE [pay_group_id] = @pay_group_id_03

        IF @pay_frequency_code <> 'SEMI'
            BEGIN
                UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                SET activity_status	=	'02'
                WHERE activity_date	=	@p_activity_date
                AND emp_id_01		=	@emp_id_01
                AND event_id_01		=	'05'

                INSERT INTO DBShrpn.dbo.ghr_msg_tbl
                SELECT 'U00048'					As msg_id,
                        @pay_group_id_03			As msg_p1,
                        @emp_id_01              	As msg_p2,
                        'After April 1, 2023,Pay Group, ' + RTRIM(@pay_group_id_03) + ' , must be semi-monthly.'	As msg_desc

                -- Historical Message for reporting purpose
                INSERT INTO DBShrpn.dbo.ghr_historical_message
                SELECT  'U00048'					As msg_id,
                        '05'						As event_id,
                        @emp_id_01 					As emp_id,
                        @eff_date_01				As eff_date,
                        @pay_element_desc_06		As pay_element_id,
                        @pay_group_id_03			As msg_p1,
                        @emp_id_01              	As msg_p2,
                        'After April 1, 2023,Pay Group, ' + RTRIM(@pay_group_id_03) + ' , must be semi-monthly.'	As msg_desc,
                        @p_activity_date			AS activity_date
                -- End of Historical Message for reporting purpose

                IF (GETDATE() > '20230331' AND @emp_status_code_5 not in ('T','I')) SELECT	@w_fatal_error = '5'

            END

        --
        -- Validate the important fields in this section.
        --

        --
        --	Check to see if the rehire date is greater than the termination date. Reject the record
        --
        IF	@emp_status_code_5 = 'RH'
            BEGIN
                IF @w_curr_status = 'T' AND @w_eff_date_01 <= @w_status_change_date
                    BEGIN

                        UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                        SET activity_status	=	'02'
                        WHERE activity_date	=	@p_activity_date
                        AND emp_id_01		=	@emp_id_01

                        INSERT INTO DBShrpn.dbo.ghr_msg_tbl
                        SELECT 'U00032'					As msg_id,
                                @emp_id_01					As msg_p1,
                                @emp_id_01					As msg_p2,
                                'The rehire date must be greater than the termination date - By passing the employee.'	As msg_desc

                        -- Historical Message for reporting purpose
                        INSERT INTO DBShrpn.dbo.ghr_historical_message
                        SELECT  'U00032'						As msg_id,
                                '05'							As event_id,
                                @emp_id_01 						As emp_id,
                                @eff_date_01					As eff_date,
                                @pay_element_desc_06			As pay_element_id,
                                @emp_id_01						As msg_p1,
                                @emp_id_01						As msg_p2,
                                'The rehire date must be greater than the termination date - By passing the employee.'	 As msg_desc,
                                @p_activity_date				AS activity_date
                        -- End of Historical Message for reporting purpose

                        SELECT  @w_fatal_error = '5'

                        -- GOTO BYPASS_EMPLOYEE
                    END
            END

        --
        --	Check to see if the reactivation date is greater than the inactivation date. Reject the record
        --
        IF	@emp_status_code_5 = 'RA'
            BEGIN
                IF @w_curr_status = 'I' AND @w_eff_date_01 <= @w_status_change_date
                    BEGIN
                        UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                        SET activity_status	=	'02'
                        WHERE activity_date	=	@p_activity_date
                        AND emp_id_01		=	@emp_id_01

                        INSERT INTO DBShrpn.dbo.ghr_msg_tbl
                        SELECT 'U00033'					As msg_id,
                                @emp_id_01					As msg_p1,
                                @emp_id_01					As msg_p2,
                                'The Reactivation date must be greater than the inactivation date - By passing the employee.'	As msg_desc

                        -- Historical Message for reporting purpose
                        INSERT INTO DBShrpn.dbo.ghr_historical_message
                        SELECT  'U00033'						As msg_id,
                                '05'							As event_id,
                                @emp_id_01 						As emp_id,
                                @eff_date_01					As eff_date,
                                @pay_element_desc_06			As pay_element_id,
                                @emp_id_01						As msg_p1,
                                @emp_id_01						As msg_p2,
                                'The Reactivation date must be greater than the inactivation date - By passing the employee.'	 As msg_desc,
                                @p_activity_date				AS activity_date
                        -- End of Historical Message for reporting purpose

                        SELECT  @w_fatal_error = '5'

                        -- GOTO BYPASS_EMPLOYEE
                    END
            END

   	    IF  @w_fatal_error = '5'
            GOTO BYPASS_EMPLOYEE

        --
        --	Obtain the setup variables
        --

        --
        --	Default the correct job or possition code based on the type of employee
        --
        IF EXISTS(
                  SELECT *
                  FROM DBShrpn.dbo.employer
                  WHERE empl_id = @empl_id_01 AND name like 'Pen%'
                 )
            SELECT	@w_assigned_to_code		=	'J',
                    @w_job_or_pos_id		=	'PENSIONER',
                    @w_pd_salary_tm_pd_id	=	'SEMI'
        ELSE
            SELECT	@w_assigned_to_code		=	'P',
                    @w_job_or_pos_id		=	'99999',
                    @w_pd_salary_tm_pd_id	=	'SEMI'

        --
        -- Find the tax entity
        --
        SELECT @tax_entity_id = [tax_entity_id]
        FROM [DBShrpn].[dbo].[empl_tax_entity]
        WHERE [empl_id] = @empl_id_01


        --
        --	Find the Job_position end date and Assignment end date
        --
            SELECT	@w_position_end_date		=	'29991231'
            SELECT	@w_job_end_date				=	'29991231'
        /*
            SELECT	@w_position_end_date		=	ea.end_date
                    -- SELECT *
            FROM	[DBShrpn].[dbo].[emp_assignment] ea
            WHERE	ea.emp_id					=	'1002123'
            AND	ea.eff_date					=	(SELECT MAX(t.eff_date) FROM [DBShrpn].[dbo].[emp_assignment] t WHERE t.emp_id = ea.emp_id AND t.end_date >= CAST('Jan 1, 2021' AS DATE))
            AND	ea.prime_assignment_ind		=	'Y'
            AND   ea.assigned_to_code			=	'P'

            SELECT	@w_job_end_date				=	'29991231'

            SELECT	@w_job_end_date				=	ea.end_date
                    -- SELECT *
            FROM	[DBShrpn].[dbo].[emp_assignment] ea
            WHERE	ea.emp_id					=	@emp_id_01
            AND	ea.eff_date					=	(SELECT MAX(t.eff_date) FROM [DBShrpn].[dbo].[emp_assignment] t WHERE t.emp_id = ea.emp_id AND t.end_date >= CAST('Jan 1, 2021' AS DATE))
            AND	ea.prime_assignment_ind		=	'Y'
            AND   ea.assigned_to_code			=	'J'
        */

        --
        --	Obtain prior employee number
        SELECT @w_previous_emp_id = prior_emp_id
        FROM employee, emp_status
        WHERE employee.emp_id				=	@emp_id_01
          AND emp_status.emp_id				=	@emp_id_01
          AND emp_status.status_change_date	<=	@w_todays_date
          AND emp_status.next_change_date	>	@w_todays_date

        IF	@w_previous_emp_id = ' '
            SELECT	@w_previous_emp_id	=	@emp_id_01


        --
        --	e.taxing_country_code	AS new_taxing_country_code AND e.curr_code	AS new_curr_code,
        --
        SELECT	@w_taxing_country_code		=	e.taxing_country_code,
                @w_curr_code				=	e.curr_code
                -- SELECT e.taxing_country_code, e.curr_code
        FROM	[DBShrpn].[dbo].employer e
        WHERE  e.empl_id	=	@empl_id_01

        --
        --
        --
        SELECT	@w_eff_date_01 = CAST(@eff_date_01	As datetime)

        --
        --
        --	Perform the main logic
        --
        --
		IF	@emp_status_code_5 = 'RH'
		BEGIN

            IF @w_curr_status = 'T'
                BEGIN
                    SELECT	@annual_salary				=	annual_salary_amt,
                            @i_eff_date_02				=	eff_date,
                            @i_hourly_rate_amt			=	hourly_pay_rate,
                            @i_period_amt				=	pd_salary_amt,
                            @i_salary_change_type_code	=	'',
                            @i_work_tm_code				=	work_tm_code,
                            @i_base_rate_tbl_id			=	'',
                            @i_base_rate_tbl_entry_code	=	'',
                            @i_standard_work_pd_id		=	standard_work_pd_id,
                            @i_standard_work_hrs		=	standard_work_hrs,
                            @i_pd_salary_tm_pd_id		=	pd_salary_tm_pd_id
                    FROM	[DBShrpn].[dbo].[emp_assignment]	ea
                    WHERE	emp_id					=	@emp_id_01
                    AND  eff_date				=	(SELECT	MAX(eff_date) FROM	[DBShrpn].[dbo].[emp_assignment] t
                                                        WHERE	t.emp_id =	ea.emp_id AND  prime_assignment_ind	=	'Y')
                    AND  prime_assignment_ind	=	'Y'

                    /*
                                SELECT	@emp_id_01,
                                        @i_eff_date_02,
                                        @annual_salary,
                                        @i_hourly_rate_amt,
                                        @i_period_amt,
                                        @i_salary_change_type_code,
                                        @i_work_tm_code,
                                        @i_base_rate_tbl_id,
                                        @i_base_rate_tbl_entry_code,
                                        @i_standard_work_pd_id,
                                        @i_standard_work_hrs,
                                        @i_pd_salary_tm_pd_id
                    */

                    EXECUTE DBShrpn.dbo.usp_upd_hmpl_rehire
                        @p_emp_id                       =	@emp_id_01,
                        @p_previous_emp_id				=	@w_previous_emp_id,
                        @p_status_change_date			=	@w_status_change_date,
                        @p_new_empl_id					=	@empl_id_01,
                        @p_new_tax_entity_id			=	@tax_entity_id,
                        @p_new_hire_date				=	@w_eff_date_01,
                        @p_new_classn_cd				=	@emp_status_classn_code_01,
                        @p_new_reason_cd				=	' ',
                        @p_new_assigned_to_code			=	@w_assigned_to_code,
                        @p_new_job_or_pos_id			=   @w_job_or_pos_id,
                        @p_new_pay_group_id				=	@pay_group_id_03,
                        @p_new_time_reporting_meth		=	@time_reporting_meth_code_03,
                        @p_job_end_date					=	@w_job_end_date,							--	datetime,			--'29991231'
                        @p_position_end_date			=	@w_position_end_date,						--	datetime,			--'29991231'
                        @p_taxing_country              	=	@w_taxing_country_code,						--	char(2),			--'GD'
                        @p_new_pay_elem_ctrl_grp_id		=	@pay_element_ctrl_grp_id_03,				--	'MTH'
                        @p_allow_pay_updates_ind		=	'Y',
                        @p_old_chgstamp					=	@w_old_chgstamp								--	0

                    EXECUTE DBShrpn.dbo.usp_ins_hpcg_hepy
                        @p_emp_id                       =	@emp_id_01,
                        @p_empl_id                      =	@empl_id_01,
                        @p_new_pay_group_id             =	@pay_group_id_03,
                        @p_new_pecg_id					=	@pay_element_ctrl_grp_id_03,
                        @p_as_of_date					=	@w_eff_date_01


                    --
                    --	Obtain the current record for this employee assignment
                    --
                    --
                    --	Update the Salary in the Assignment Record
                    --

                    SELECT	@i_emp_id				=	emp_id,
                            @i_assigned_to_code		=	assigned_to_code,
                            @i_job_or_pos_id		=	job_or_pos_id,
                            @i_eff_date				=	eff_date,
                            @i_next_eff_date		=	next_eff_date,
                            @i_prior_eff_date		=	prior_eff_date
                    FROM [DBShrpn].[dbo].[emp_assignment]	ea
                    WHERE emp_id =	@emp_id_01
                    AND eff_date = (
                                    SELECT MAX(eff_date)
                                    FROM	[DBShrpn].[dbo].[emp_assignment] t
                                    WHERE	t.emp_id =	ea.emp_id
                                        AND prime_assignment_ind = 'Y'
                                    )
                    AND prime_assignment_ind	=	'Y'

                    --	 SELECT @pay_frequency_code	= pay_frequency_code
                    --     FROM [DBShrpn].[dbo].[pay_group] WHERE [pay_group_id] = @pay_group_id_03

                    --- If blank, then default: SEMI ---

                    IF @pay_frequency_code = ''	SELECT	@pay_frequency_code		=	'SEMI'

                    IF	@pay_frequency_code	= 'WEEK'	SELECT @i_yearly_std_work_hrs	=	@i_standard_work_hrs * 52
                    ELSE
                    IF	@pay_frequency_code	= 'BIWK'	SELECT @i_yearly_std_work_hrs	=	@i_standard_work_hrs * 26
                    ELSE
                    IF	@pay_frequency_code	= 'SEMI'	SELECT @i_yearly_std_work_hrs	=	@i_standard_work_hrs * 24
                    ELSE
                    IF	@pay_frequency_code	= 'MONTH'	SELECT @i_yearly_std_work_hrs	=	@i_standard_work_hrs * 12


                    SELECT	@i_hourly_rate_amt	=	CAST(@annual_salary_amt_01 AS MONEY) / @i_yearly_std_work_hrs


                    IF	@pay_frequency_code	= 'WEEK'	SELECT @i_period_amt		=	CAST(@annual_salary_amt_01 AS MONEY) / 52
                    ELSE
                    IF	@pay_frequency_code	= 'BIWK'	SELECT @i_period_amt		=	CAST(@annual_salary_amt_01 AS MONEY) / 26
                    ELSE
                    IF	@pay_frequency_code	= 'SEMI'	SELECT @i_period_amt		=	CAST(@annual_salary_amt_01 AS MONEY) / 24
                    ELSE
                    IF	@pay_frequency_code	= 'MONTH'	SELECT @i_period_amt		=	CAST(@annual_salary_amt_01 AS MONEY) / 12



                    UPDATE [DBShrpn].[dbo].[emp_assignment]
                    SET annual_salary_amt			=	CAST(@annual_salary_amt_01 AS MONEY),
                        hourly_pay_rate				=	@i_hourly_rate_amt,
                        pd_salary_amt				=	@i_period_amt,
                        salary_change_type_code		=	'',
                        work_tm_code				=	@i_work_tm_code,
                        base_rate_tbl_id			=	@i_base_rate_tbl_id,
                        base_rate_tbl_entry_code	=	@i_base_rate_tbl_entry_code,
                        pd_salary_tm_pd_id          =   @pay_frequency_code,
                        standard_work_pd_id         =   @i_standard_work_pd_id,
                        standard_work_hrs           =   @i_standard_work_hrs,
                        organization_group_id		=	CAST(@organization_group_id_01 AS INT),
                        organization_chart_name		=	@organization_chart_name_01,
                        organization_unit_name		=	@organization_unit_name_01
                    WHERE emp_id			=	@i_emp_id
                    AND assigned_to_code	=	@i_assigned_to_code
                    AND job_or_pos_id		=	@i_job_or_pos_id
                    AND eff_date			=	@i_eff_date
                    AND next_eff_date		=	@i_next_eff_date
                    AND prior_eff_date	=	@i_prior_eff_date

                END
            ELSE
                BEGIN

                    UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status	=	'02'
                    WHERE activity_date	=	@p_activity_date
                    AND emp_id_01		=	@emp_id_01

                    INSERT INTO DBShrpn.dbo.ghr_msg_tbl
                    SELECT 'U00022'					As msg_id,
                        @w_curr_status				As msg_p1,
                        @emp_id_01					As msg_p2,
                        'Cannot rehire an employee if the current status is not terminated.'	As msg_desc

                    -- Historical Message for reporting purpose
                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                    SELECT  'U00022'						As msg_id,
                            '05'							As event_id,
                            @emp_id_01 						As emp_id,
                            @eff_date_01					As eff_date,
                            @pay_element_desc_06			As pay_element_id,
                            @w_curr_status					As msg_p1,
                            @emp_id_01						As msg_p2,
                            'The current status is ' + RTRIM(@w_curr_status_value) + '.' + ' Cannot rehire an employee if the current status is not terminated.'	 As msg_desc,
                            @p_activity_date				AS activity_date
                    -- End of Historical Message for reporting purpose

                END
        END  -- End of RH Logic


		IF	@emp_status_code_5 = 'I'
		BEGIN

            IF @w_curr_status = 'A'
                BEGIN
                    EXECUTE DBShrpn.dbo.usp_upd_hmpl_inactivate	@p_emp_id	=	@emp_id_01,
                        @p_status_change_date			=	@w_status_change_date,
                        @p_inactivate_date				=	@w_eff_date_01,
                        @p_new_reason					=	' ',
                        @p_new_loa_expd_date			=	'29991231',
                        @p_new_classification_cd		=	@emp_status_classn_code_01,
                        @p_allow_emp_pay_updates_ind	=	'Y',
                        @p_pay_status_code				=	@pay_status_code_03,
                        @p_last_day_paid				=	'19000101',
                        @p_old_chgstamp				=	@w_old_chgstamp

                END
            ELSE
                BEGIN
                    UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status	=	'02'
                    WHERE activity_date	=	@p_activity_date
                    AND emp_id_01		=	@emp_id_01

                    INSERT INTO DBShrpn.dbo.ghr_msg_tbl
                    SELECT 'U00024'					As msg_id,
                        @w_curr_status				As msg_p1,
                        @emp_id_01					As msg_p2,
                        'Cannot inactivate an employee if the current status is not active.'	As msg_desc

                    -- Historical Message for reporting purpose
                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                    SELECT  'U00024'						As msg_id,
                            '05'							As event_id,
                            @emp_id_01 						As emp_id,
                            @eff_date_01					As eff_date,
                            @pay_element_desc_06			As pay_element_id,
                            @w_curr_status					As msg_p1,
                            @emp_id_01						As msg_p2,
                            'The current status is ' + RTRIM(@w_curr_status_value) + '.' + ' Cannot inactivate an employee if the current status is not active.'	 As msg_desc,
                            @p_activity_date				AS activity_date
                    -- End of Historical Message for reporting purpose

                END
        END  -- End of Inactivate Logic


		IF	@emp_status_code_5 = 'T'
		BEGIN

			IF @w_curr_status IN ('A','I')
                BEGIN
                    CREATE TABLE #temp1 (pay_element_id	char(10))

                    CREATE TABLE #temp2
                    (row_id				int,
                        emp_id 				char(15),
                        assigned_to_code 	char(1),
                        job_or_pos_id		char(10),
                        eff_date			datetime,
                        next_eff_date		datetime,
                        prior_eff_date		datetime,
                        end_date 			datetime)

                    SELECT @pay_status_code = pay_status_code,@old_eff_date = eff_date
                    FROM DBShrpn.dbo.emp_employment ee
                    WHERE emp_id = @emp_id_01
                    AND eff_date = (SELECT MAX(eff_date) FROM DBShrpn.dbo.emp_employment t WHERE t.emp_id = ee.emp_id)

                    EXECUTE DBShrpn.dbo.usp_upd_hmpl_terminate
                    @p_emp_id	=	@emp_id_01,
                    @p_status_change_date            =	@w_status_change_date,
                    @p_termination_date              =	@w_eff_date_01,
                    @p_new_classn_cd                 =	@emp_status_classn_code_01,
                    @p_date_of_death                 =	'29991231',
                    @p_new_reason_code               =	@reason_code_5,
                    @p_new_pay_through_date          =	@w_eff_date_01,
                    @p_new_rehire_conson             =	@consider_for_rehire_ind_5,
                    @p_pay_status_code               =	@pay_status_code_03,
                    @p_last_day_paid                 =	'19000101',
                    @p_old_chgstamp                  =	@w_old_chgstamp

                    DROP TABLE #temp1

                    DROP TABLE #temp2

                    --  New Record Update to resolve conflict with the rehire date
                    UPDATE DBShrpn.dbo.emp_employment
                    SET pay_status_code = @pay_status_code_03, eff_date = @w_eff_date_01
                    FROM DBShrpn.dbo.emp_employment ee
                    WHERE emp_id = @emp_id_01
                    AND eff_date = (SELECT MAX(eff_date) FROM DBShrpn.dbo.emp_employment t WHERE t.emp_id = ee.emp_id)

                    --  Update prior record to point to the new record.
                    UPDATE DBShrpn.dbo.emp_employment
                    SET next_eff_date = @w_eff_date_01
                    FROM DBShrpn.dbo.emp_employment ee
                    WHERE emp_id   = @emp_id_01
                    AND eff_date = @old_eff_date

                END
		    ELSE
                BEGIN
                    UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status	=	'02'
                    WHERE activity_date	=	@p_activity_date
                    AND emp_id_01		=	@emp_id_01

                    INSERT INTO DBShrpn.dbo.ghr_msg_tbl
                    SELECT 'U00042'					As msg_id,
                        @w_curr_status				As msg_p1,
                        @emp_id_01					As msg_p2,
                        'Cannot terminate an employee if the current status is not active or inactive.'	As msg_desc

                    -- Historical Message for reporting purpose
                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                    SELECT  'U00042'						As msg_id,
                            '05'							As event_id,
                            @emp_id_01 						As emp_id,
                            @eff_date_01					As eff_date,
                            @pay_element_desc_06			As pay_element_id,
                            @w_curr_status					As msg_p1,
                            @emp_id_01						As msg_p2,
                            'The current status is ' + RTRIM(@w_curr_status_value) + '.' + ' Cannot terminate an employee if the current status is not active or inactive.'	 As msg_desc,
                            @p_activity_date				AS activity_date
                    -- End of Historical Message for reporting purpose

                END

		END  -- End of Terminate Logic

		--
        -- Override the message if this cycle contains an employee rehire record
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
        --
        --

		IF	@emp_status_code_5 = 'RA'
		BEGIN --1

            IF @w_curr_status = 'I'
                BEGIN  --2
                    EXECUTE DBShrpn.dbo.usp_upd_hmpl_reactivate	@p_emp_id	=	@emp_id_01,
                        @p_status_change_date				=	@w_status_change_date,
                        @p_reactivate_date					=	@w_eff_date_01,
                        @p_new_reason						=	@reason_code_5,
                        @p_new_classification_cd			=	@emp_status_classn_code_01,
                        @p_allow_emp_pay_updates_ind		=	'Y',
                        @p_pay_status_code					=	@pay_status_code_03,
                        @p_old_chgstamp					=	@w_old_chgstamp

                END  --2
		    ELSE
			    BEGIN --3
				    IF @rehire_override = '0'
				        BEGIN  --4
                            UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                            SET activity_status	=	'02'
                            WHERE activity_date	=	@p_activity_date
                            AND emp_id_01		=	@emp_id_01

                            INSERT INTO DBShrpn.dbo.ghr_msg_tbl
                            SELECT 'U00025'					As msg_id,
                                @w_curr_status				As msg_p1,
                                @emp_id_01					As msg_p2,
                                'Cannot Reactivate an employee if the current status is not inactivate.'	As msg_desc

                            -- Historical Message for reporting purpose
                            INSERT INTO DBShrpn.dbo.ghr_historical_message
                            SELECT  'U00025'						As msg_id,
                                    '05'							As event_id,
                                    @emp_id_01 						As emp_id,
                                    @eff_date_01					As eff_date,
                                    @pay_element_desc_06			As pay_element_id,
                                    @w_curr_status					As msg_p1,
                                    @emp_id_01						As msg_p2,
                                    -- 'Cannot Reactivate an employee if the current status is not inactivate.'	 As msg_desc,
                                    'The current status is ' + RTRIM(@w_curr_status_value) + '.' + ' Cannot Reactivate an employee if the current status is not inactivate.'  As msg_desc,
                                    @p_activity_date				AS activity_date
                            -- End of Historical Message for reporting purpose
				        END	 --4
				    ELSE
				        BEGIN --5

		   					UPDATE DBShrpn.dbo.ghr_employee_events_aud
							   SET activity_status	=   '99'
							 WHERE activity_date	=	@p_activity_date
							   AND emp_id_01		=	@emp_id_01
							   AND event_id_01		=	'05'
							   AND emp_status_code_5=   'RA'
				        END  --5
			    END --3
	    END --1  -- End of Reactivate Logic

        --
        -- Update the position since could be a new position with a new salary
        --
		SELECT @individual_id = individual_id
        FROM [DBShrpn].[dbo].[employee]
        WHERE emp_id = @emp_id_01

		IF	@emp_status_code_5 = 'RH'
		BEGIN
			UPDATE	[DBShrpn].[dbo].[individual_personal]
			   SET	user_text_1		=	CAST(@position_title_01 AS CHAR(50))
			 WHERE individual_id	=	@individual_id
		 END

        /*
                    SELECT @emp_id_01,
                        @w_previous_emp_id,
                        @w_status_change_date,
                        @empl_id_01,
                        @tax_entity_id,
                        @w_eff_date_01,
                        @emp_status_classn_code_01,
                        ' ',
                        'P',
                        ' 75100-048',
                        @pay_group_id_03,
                        @time_reporting_meth_code_03,
                        @w_job_end_date,
                        @w_position_end_date,
                        @w_taxing_country_code,
                        @pay_element_ctrl_grp_id_03,
                        'Y',
                        @w_old_chgstamp


            END1
        */

	    BYPASS_EMPLOYEE:

	    SELECT @cnt = @cnt + 1

    END    -- End of main loop

    --
    -- Notify the users of all the issues
    --

    --
    -- Send notification of warning message U00023  -- < STATUS CHANGE SECTION (5) >
    --

    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00023'

    SELECT @max = COUNT(*)
    --  SELECT *
    FROM DBShrpn.dbo.ghr_employee_events
    WHERE [event_id_01] = '05'
    SELECT @maxx = CAST(@max As CHAR(06))
    SELECT @special_value_exists = 0
    SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)
    SELECT @msg_id = 'U00023'

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
    -- End of Sending notification of warning message U00023
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
    WHERE [event_id_01] = '05'
    SELECT @maxx = CAST(@max As CHAR(06))
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

    SELECT @maxx = CAST(@max As CHAR(06))
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
    -- Send notification of warning message U00019  -- Total Global HR Status Change:
    --

    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    --  SELECT *
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00019'

    SELECT @max = COUNT(*)
    --  SELECT COUNT(*)
    FROM DBShrpn.dbo.ghr_employee_events
    WHERE [event_id_01] = '05'

    SELECT @maxx = CAST(@max As CHAR(06))
    SELECT @special_value_exists = 0
    SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)
    SELECT @msg_id = 'U00019'

    IF @special_value_exists <> 0 SELECT @w_msg_text = REPLACE(@w_msg_text,'@1',RTRIM(@maxx))
    SELECT @w_msg_text_2 = ''

    IF	@max	> 0
    EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2 @p_userid,
        @p_batchname,
        @p_qualifier,
        @msg_id ,
        @w_severity_cd,
        @w_msg_text,
        @w_msg_text_2,
        @w_msg_text_3

    --JAG
    --
    -- Send notification of warning message U00005 -- Employer (@1) does not exist for employee: @2 - defaulting 99999'
    --

    IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_message_temp_5]') AND type in (N'U'))
        DROP TABLE [dbo].[ghr_message_temp_5]


    CREATE TABLE [dbo].[ghr_message_temp_5](
        [ID]							[int] IDENTITY(1,1) NOT NULL,
        [msg_id]						[char](15)	NOT NULL,
        [msg_p1]						[char](15)	NOT NULL,
        [msg_p2]						[char](15)	NOT NULL,
        [msg_desc]						[char](255) NOT NULL
    )


    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00005'

    INSERT INTO DBShrpn.dbo.ghr_message_temp_5
    SELECT *
    FROM DBShrpn.dbo.ghr_msg_tbl
    WHERE msg_id = 'U00005'

    SET @cnt = 1

    SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_5


    WHILE (@cnt <= @max)
    BEGIN

    SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_5 t5 WHERE t5.[ID] = @cnt

    SELECT @special_value_exists = 0
    SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)

    IF @special_value_exists <> 0 SELECT @w_msg_text = REPLACE(@w_msg_text,'@1',RTRIM(@msg_p2))


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
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00005'

    SELECT @cnt = @cnt + 1;

    END


    --JAG
    --
    -- Send notification of warning message U00012 -- Employee does not exists Message
    --

    IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_message_temp_5]') AND type in (N'U'))
        DROP TABLE [dbo].[ghr_message_temp_5]


    CREATE TABLE [dbo].[ghr_message_temp_5](
        [ID]							[int] IDENTITY(1,1) NOT NULL,
        [msg_id]						[char](15)	NOT NULL,
        [msg_p1]						[char](15)	NOT NULL,
        [msg_p2]						[char](15)	NOT NULL,
        [msg_desc]						[char](255) NOT NULL
    )


    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00012'

    INSERT INTO DBShrpn.dbo.ghr_message_temp_5
    SELECT *
    FROM DBShrpn.dbo.ghr_msg_tbl
    WHERE msg_id = 'U00012'

    SET @cnt = 1

    SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_5


    WHILE (@cnt <= @max)
    BEGIN

    SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_5 t5 WHERE t5.[ID] = @cnt

    SELECT @special_value_exists = 0
    SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)

    IF @special_value_exists <> 0 SELECT @w_msg_text = REPLACE(@w_msg_text,'@1',RTRIM(@msg_p2))


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
    -- Send notification of warning message U00024 -- 'The current status is @1. To inactivate an employee, @2, the current status must be activate'
    --

    IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_message_temp_5]') AND type in (N'U'))
        DROP TABLE [dbo].[ghr_message_temp_5]


    CREATE TABLE [dbo].[ghr_message_temp_5](
        [ID]							[int] IDENTITY(1,1) NOT NULL,
        [msg_id]						[char](15)	NOT NULL,
        [msg_p1]						[char](15)	NOT NULL,
        [msg_p2]						[char](15)	NOT NULL,
        [msg_desc]						[char](255) NOT NULL
    )


    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00024'

    INSERT INTO DBShrpn.dbo.ghr_message_temp_5
    SELECT *
    FROM DBShrpn.dbo.ghr_msg_tbl
    WHERE msg_id = 'U00024'

    SET @cnt = 1

    SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_5


    WHILE (@cnt <= @max)
    BEGIN

    SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_5 t5 WHERE t5.[ID] = @cnt

    SELECT @special_value_exists = 0
    SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)

    IF @special_value_exists <> 0 SELECT @w_msg_text = REPLACE(@w_msg_text,'@1',RTRIM(@msg_p2))


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
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00024'

    SELECT @cnt = @cnt + 1;

    END


    --
    -- Send notification of warning message U00025 -- 'Cannot Reactivate an employee, @1, if the current status is not inactive'
    --

    IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_message_temp_5]') AND type in (N'U'))
        DROP TABLE [dbo].[ghr_message_temp_5]


    CREATE TABLE [dbo].[ghr_message_temp_5](
        [ID]							[int] IDENTITY(1,1) NOT NULL,
        [msg_id]						[char](15)	NOT NULL,
        [msg_p1]						[char](15)	NOT NULL,
        [msg_p2]						[char](15)	NOT NULL,
        [msg_desc]						[char](255) NOT NULL
    )


    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00025'

    INSERT INTO DBShrpn.dbo.ghr_message_temp_5
    SELECT *
    FROM DBShrpn.dbo.ghr_msg_tbl
    WHERE msg_id = 'U00025'

    SET @cnt = 1

    SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_5


    WHILE (@cnt <= @max)
    BEGIN

    SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_5 t5 WHERE t5.[ID] = @cnt

    SELECT @special_value_exists = 0
    SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)

    IF @special_value_exists <> 0 SELECT @w_msg_text = REPLACE(@w_msg_text,'@1',RTRIM(@msg_p2))


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
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00025'

    SELECT @cnt = @cnt + 1;

    END

    --
    -- Send notification of warning message U00026 -- 'The current status is @1. To Reactivate an employee, @2, the current status must be inactivate'
    --

    IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_message_temp_5]') AND type in (N'U'))
        DROP TABLE [dbo].[ghr_message_temp_5]


    CREATE TABLE [dbo].[ghr_message_temp_5](
        [ID]							[int] IDENTITY(1,1) NOT NULL,
        [msg_id]						[char](15)	NOT NULL,
        [msg_p1]						[char](15)	NOT NULL,
        [msg_p2]						[char](15)	NOT NULL,
        [msg_desc]						[char](255) NOT NULL
    )


    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00026'

    INSERT INTO DBShrpn.dbo.ghr_message_temp_5
    SELECT *
    FROM DBShrpn.dbo.ghr_msg_tbl
    WHERE msg_id = 'U00026'

    SET @cnt = 1

    SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_5


    WHILE (@cnt <= @max)
    BEGIN

    SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_5 t5 WHERE t5.[ID] = @cnt

    SELECT @special_value_exists = 0
    SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)

    IF @special_value_exists <> 0 SELECT @w_msg_text = REPLACE(@w_msg_text,'@1',RTRIM(@msg_p2))


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
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00026'

    SELECT @cnt = @cnt + 1;

    END
    --
    --	End of warning message U00026
    --

    --
    -- Send notification of warning message U00032 -- 'The rehire date must be greater than the termination date - By passing the employee: @1'
    --

    IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_message_temp_5]') AND type in (N'U'))
        DROP TABLE [dbo].[ghr_message_temp_5]


    CREATE TABLE [dbo].[ghr_message_temp_5](
        [ID]							[int] IDENTITY(1,1) NOT NULL,
        [msg_id]						[char](15)	NOT NULL,
        [msg_p1]						[char](15)	NOT NULL,
        [msg_p2]						[char](15)	NOT NULL,
        [msg_desc]						[char](255) NOT NULL
    )


    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00032'

    INSERT INTO DBShrpn.dbo.ghr_message_temp_5
    SELECT *
    FROM DBShrpn.dbo.ghr_msg_tbl
    WHERE msg_id = 'U00032'

    SET @cnt = 1

    SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_5


    WHILE (@cnt <= @max)
    BEGIN

    SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_5 t5 WHERE t5.[ID] = @cnt

    SELECT @special_value_exists = 0
    SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)

    IF @special_value_exists <> 0 SELECT @w_msg_text = REPLACE(@w_msg_text,'@1',RTRIM(@msg_p2))


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
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00032'

    SELECT @cnt = @cnt + 1;

    END


    --
    -- Send notification of warning message U00033 -- 'The Reactivation date must be greater than the inactivation date - By passing the employee: @1'
    --

    IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_message_temp_5]') AND type in (N'U'))
        DROP TABLE [dbo].[ghr_message_temp_5]


    CREATE TABLE [dbo].[ghr_message_temp_5](
        [ID]							[int] IDENTITY(1,1) NOT NULL,
        [msg_id]						[char](15)	NOT NULL,
        [msg_p1]						[char](15)	NOT NULL,
        [msg_p2]						[char](15)	NOT NULL,
        [msg_desc]						[char](255) NOT NULL
    )


    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00033'

    INSERT INTO DBShrpn.dbo.ghr_message_temp_5
    SELECT *
    FROM DBShrpn.dbo.ghr_msg_tbl
    WHERE msg_id = 'U00033'

    SET @cnt = 1

    SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_5


    WHILE (@cnt <= @max)
    BEGIN

    SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_5 t5 WHERE t5.[ID] = @cnt

    SELECT @special_value_exists = 0
    SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)

    IF @special_value_exists <> 0 SELECT @w_msg_text = REPLACE(@w_msg_text,'@1',RTRIM(@msg_p2))


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
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00033'

    SELECT @cnt = @cnt + 1;

    END

    --
    -- Send notification of warning message U00036 -- Transfer date must be greater than default position effective date
    --

    IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_message_temp_3]') AND type in (N'U'))
        DROP TABLE [dbo].[ghr_message_temp_5]


    CREATE TABLE [dbo].[ghr_message_temp_5](
        [ID]							[int] IDENTITY(1,1) NOT NULL,
        [msg_id]						[char](15)	NOT NULL,
        [msg_p1]						[char](15)	NOT NULL,
        [msg_p2]						[char](15)	NOT NULL,
        [msg_desc]						[char](255) NOT NULL
    )


    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00036'

    INSERT INTO DBShrpn.dbo.ghr_message_temp_5
    SELECT *
    FROM DBShrpn.dbo.ghr_msg_tbl
    WHERE msg_id = 'U00036'

    SET @cnt = 1

    SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_5


    WHILE (@cnt <= @max)
    BEGIN

    SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_5 t5 WHERE t5.[ID] = @cnt

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
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00036'

    SELECT @cnt = @cnt + 1;

    END
    --
    --	End of warning message U00036
    --


    --
    -- Send notification of warning message U00037 -- 'The Reactivation date must be greater than the inactivation date - By passing the employee: @1'
    --

    IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_message_temp_5]') AND type in (N'U'))
        DROP TABLE [dbo].[ghr_message_temp_5]


    CREATE TABLE [dbo].[ghr_message_temp_5](
        [ID]							[int] IDENTITY(1,1) NOT NULL,
        [msg_id]						[char](15)	NOT NULL,
        [msg_p1]						[char](15)	NOT NULL,
        [msg_p2]						[char](15)	NOT NULL,
        [msg_desc]						[char](255) NOT NULL
    )


    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00037'

    INSERT INTO DBShrpn.dbo.ghr_message_temp_5
    SELECT *
    FROM DBShrpn.dbo.ghr_msg_tbl
    WHERE msg_id = 'U00037'

    SET @cnt = 1

    SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_5


    WHILE (@cnt <= @max)
    BEGIN

    SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_5 t5 WHERE t5.[ID] = @cnt

    SELECT @special_value_exists = 0
    SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)

    IF @special_value_exists <> 0 SELECT @w_msg_text = REPLACE(@w_msg_text,'@1',RTRIM(@msg_p2))


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
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00037'

    SELECT @cnt = @cnt + 1;

    END


    --
    -- Send notification of warning message U00042 -- 'Cannot terminate an employee, @1, if the current status is not active or inactive.'
    --

    IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_message_temp_5]') AND type in (N'U'))
        DROP TABLE [dbo].[ghr_message_temp_5]


    CREATE TABLE [dbo].[ghr_message_temp_5](
        [ID]							[int] IDENTITY(1,1) NOT NULL,
        [msg_id]						[char](15)	NOT NULL,
        [msg_p1]						[char](15)	NOT NULL,
        [msg_p2]						[char](15)	NOT NULL,
        [msg_desc]						[char](255) NOT NULL
    )


    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00042'

    INSERT INTO DBShrpn.dbo.ghr_message_temp_5
    SELECT *
    FROM DBShrpn.dbo.ghr_msg_tbl
    WHERE msg_id = 'U00042'

    SET @cnt = 1

    SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_5


    WHILE (@cnt <= @max)
    BEGIN

    SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_5 t5 WHERE t5.[ID] = @cnt

    SELECT @special_value_exists = 0
    SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)

    IF @special_value_exists <> 0 SELECT @w_msg_text = REPLACE(@w_msg_text,'@1',RTRIM(@msg_p2))


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
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00042'

    SELECT @cnt = @cnt + 1;

    END
    --JAG
    --
    -- Send notification of warning message U00043 -- 'Rehire date must be greater than current employee employment effective date for employee: @1'
    --

    IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_message_temp_5]') AND type in (N'U'))
        DROP TABLE [dbo].[ghr_message_temp_5]


    CREATE TABLE [dbo].[ghr_message_temp_5](
        [ID]							[int] IDENTITY(1,1) NOT NULL,
        [msg_id]						[char](15)	NOT NULL,
        [msg_p1]						[char](15)	NOT NULL,
        [msg_p2]						[char](15)	NOT NULL,
        [msg_desc]						[char](255) NOT NULL
    )


    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00043'

    INSERT INTO DBShrpn.dbo.ghr_message_temp_5
    SELECT *
    FROM DBShrpn.dbo.ghr_msg_tbl
    WHERE msg_id = 'U00043'

    SET @cnt = 1

    SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_5


    WHILE (@cnt <= @max)
    BEGIN

    SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_5 t5 WHERE t5.[ID] = @cnt

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
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00043'

    SELECT @cnt = @cnt + 1;

    END


    --JAG

    --
    -- Send notification of warning message U00011 -- Blank Line
    --

    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    --  SELECT *
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00011'

    SELECT @maxx = CAST(@max As CHAR(06))
    SELECT @special_value_exists = 0
    SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)
    SELECT @msg_id = 'U00011'

    SELECT @w_msg_text_2 = ''
    /*
    EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2 @p_userid,
        @p_batchname,
        @p_qualifier,
        @msg_id ,
        @w_severity_cd,
        @w_msg_text,
        @w_msg_text_2,
        @w_msg_text_3
        */

    --
    -- Send notification of warning message U00010 -- <ENDING OF WARNING MESSAGES: >
    --

    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    --  SELECT *
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00010'

    SELECT @maxx = CAST(@max As CHAR(06))
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

    SELECT @maxx = CAST(@max As CHAR(06))
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
    --0
END
GO

-- D7

ALTER AUTHORIZATION ON [dbo].[usp_ins_status_change] TO  SCHEMA OWNER
GO
