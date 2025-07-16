USE [DBShrpn]
GO
/****** Object:  StoredProcedure [dbo].[usp_perform_transfer]    Script Date: 4/1/2025 4:33:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[usp_perform_transfer]
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
    DECLARE @w_trace_sw						char(01)

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

    SELECT @w_trace_sw = 'Y'

    IF @w_trace_sw = 'Y'
    INSERT INTO DBSosxp.dbo.msg SELECT CAST(GETDATE() AS CHAR (20)) AS msg_desc

    IF @w_trace_sw = 'Y'
    INSERT INTO DBSosxp.dbo.msg SELECT 'Start usp_perform_transfer' AS msg_desc


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



    --exec @ret = sp_dbs_authenticate
    --if @ret != 0 return -1

    IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_employee_events_temp3]') AND type in (N'U'))
        DROP TABLE [dbo].[ghr_employee_events_temp3]


    CREATE TABLE [dbo].[ghr_employee_events_temp3](
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

    INSERT INTO DBShrpn.dbo.ghr_employee_events_temp3    ---#t0
    SELECT *
    FROM DBShrpn.dbo.ghr_employee_events
    WHERE [event_id_01] = '03'   --AND emp_id_01 = '1006971' AND [eff_date_01] = '20090601'

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

    DECLARE @o_empl_id						char(10)
    DECLARE	@emp_status_code				CHAR(1)
    DECLARE @pay_frequency_code		char(05)


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

    SET @cnt = 1

    SELECT @max = COUNT(ID)
    FROM DBShrpn.dbo.ghr_employee_events_temp3

    DELETE DBShrpn.dbo.ghr_msg_tbl

    WHILE (@cnt <= @max)
    BEGIN

        SELECT  @w_fatal_error = '0'

        --
        --	Read the Global HR values
        --
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
                --	SELECT *
        FROM DBShrpn.dbo.ghr_employee_events_temp3 t
        WHERE t.ID = @cnt

        IF @w_trace_sw = 'Y'
            INSERT INTO DBSosxp.dbo.msg SELECT 'Detail_Loop: ' + ' event_id: ' + @event_id_01 + ' emp_id: ' + @emp_id_01 + ' eff date: ' + @eff_date_01 + ' count: ' + CAST(@cnt AS CHAR(10))  AS msg_desc

        --
        --	Find missing values for the fields below
        --
        --
        -- Override the message if this cycle contains an employee rehire record
        --
        IF  EXISTS (SELECT * FROM DBShrpn.dbo.ghr_employee_events ee WHERE event_id_01 = '05' AND ee.emp_id_01 = @emp_id_01 AND emp_status_code_5 = 'RH')
            SELECT @rehire_override = '1'
        ELSE
            SELECT @rehire_override = '0'

        --
        -- Check to see if the employee current status is terminated and look ahead for Rehire record.
        --

        SELECT @emp_status_code	=  emp_status_code
        FROM DBShrpn.dbo.emp_status s
        WHERE s.emp_id = @emp_id_01
        AND s.status_change_date = (SELECT MAX(status_change_date) FROM DBShrpn.dbo.emp_status t WHERE t.emp_id = s.emp_id)

        IF	  @emp_status_code = 'T'
        BEGIN
            IF    @rehire_override = '1'
            BEGIN
                UPDATE DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status	= '99'
                    WHERE activity_date	=	@p_activity_date
                    AND emp_id_01		=	@emp_id_01
                    AND event_id_01		=	'03'

                SELECT  @w_fatal_error = '5'

            END
        END

        --
        --	Obtain the current record for this employee employment
        --
        SELECT	@i_emp_employment_exists	=	'N'

        SELECT	@i_emp_id					=	emp_id,
                @i_empl_id					=	empl_id,
                @i_eff_date					=	eff_date,
                @i_emp_employment_exists	=	'Y'
                --  SELECT *
        FROM	[DBShrpn].[dbo].[emp_employment]	ee
        WHERE	emp_id					=	@emp_id_01
        and  eff_date				=	(SELECT	MAX(eff_date) FROM	[DBShrpn].[dbo].[emp_employment] t
                                            WHERE	t.emp_id			=	ee.emp_id)

        IF @w_trace_sw = 'Y'
            INSERT INTO DBSosxp.dbo.msg SELECT 'Message_1: Beg ' + ' event_id: ' + @event_id_01 + ' emp_id: ' + @emp_id_01 + ' eff date: ' + @eff_date_01 + ' count: ' + CAST(@cnt AS CHAR(10))  AS msg_desc

        IF	@i_emp_employment_exists	=	'Y' AND @i_eff_date > CAST(@eff_date_01 AS datetime)
            BEGIN
                UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status	=	'02'
                WHERE activity_date	=	@p_activity_date
                    AND emp_id_01		=	@emp_id_01
                    AND event_id_01		=	'03'

                INSERT INTO DBShrpn.dbo.ghr_msg_tbl
                SELECT 'U00027'					As msg_id,
                        @eff_date_01				As msg_p1,
                        @emp_id_01					As msg_p2,
                        'The new effective date, @1 , for employee, @2, must be greater than the current effective date'	As msg_desc

                -- Historical Message for reporting purpose
                INSERT INTO DBShrpn.dbo.ghr_historical_message
                SELECT  'U00027'						As msg_id,
                        '03'							As event_id,
                        @emp_id_01 						As emp_id,
                        @eff_date_01					As eff_date,
                        @pay_element_desc_06			As pay_element_id,
                        @emp_id_01						As msg_p1,
                        CONVERT(char,@i_eff_date,112)	As msg_p2,
                        'The new effective date for employee must be greater than the current effective date'	As msg_desc,
                        @p_activity_date				AS activity_date
                -- End of Historical Message for reporting purpose

                SELECT  @w_fatal_error = '5'

                -- GOTO BYPASS_EMPLOYEE
            END

        IF @w_trace_sw = 'Y'
            INSERT INTO DBSosxp.dbo.msg SELECT 'Message_1: End ' + ' event_id: ' + @event_id_01 + ' emp_id: ' + @emp_id_01 + ' eff date: ' + @eff_date_01 + ' count: ' + CAST(@cnt AS CHAR(10))  AS msg_desc

        --
        -- Check to see if the employee does not exists
        --

        IF  NOT EXISTS (SELECT * FROM DBShrpn.dbo.emp_status WHERE emp_id = @emp_id_01)
            BEGIN
                UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status	=	'02'
                WHERE activity_date	=	@p_activity_date
                    AND emp_id_01		=	@emp_id_01
                    AND event_id_01		=	'03'

                INSERT INTO DBShrpn.dbo.ghr_msg_tbl
                SELECT 'U00012'					As msg_id,
                        @emp_id_01					As msg_p1,
                        @emp_id_01					As msg_p2,
                        'Employee does not exists'	As msg_desc

                -- Historical Message for reporting purpose
                INSERT INTO DBShrpn.dbo.ghr_historical_message
                SELECT  'U00012'						As msg_id,
                        '03'							As event_id,
                        @emp_id_01 						As emp_id,
                        @eff_date_01					As eff_date,
                        @pay_element_desc_06			As pay_element_id,
                        @emp_id_01						As msg_p1,
                        CONVERT(char,@eff_date_01,112)	As msg_p2,
                        'Employee does not exists'		As msg_desc,
                        @p_activity_date				AS activity_date
                -- End of Historical Message for reporting purpose

            SELECT  @w_fatal_error = '5'

                -- GOTO BYPASS_EMPLOYEE
            END

        --
        -- Existing payments have not been updated into the accumulator for this employee.
        --
        IF EXISTS (SELECT * FROM DBShrpy.dbo.emp_pmt WHERE	emp_id = @emp_id_01 AND	posted_accumulator_ind	= 'N' AND	seq_ctrl_yr		> 0)
            BEGIN

                UPDATE DBShrpn.dbo.ghr_employee_events_aud
                SET activity_status	= '02'
                WHERE activity_date	=	@p_activity_date
                AND emp_id_01		=	@emp_id_01
                AND event_id_01		=	'03'

                INSERT INTO DBShrpn.dbo.ghr_msg_tbl
                SELECT 'U00038'				As msg_id,
                        @emp_id_01			As msg_p1,
                        @empl_id_01			As msg_p2,
                'Existing payments have not been updated into the accumulator for this employee.'	As msg_desc

                -- Historical Message for reporting purpose
                INSERT INTO DBShrpn.dbo.ghr_historical_message
                SELECT  'U00038'						As msg_id,
                        '03'							As event_id,
                        @emp_id_01 						As emp_id,
                        @eff_date_01					As eff_date,
                        @pay_element_desc_06			As pay_element_id,
                        @emp_id_01						As msg_p1,
                        @empl_id_01						As msg_p2,
                        'Existing payments have not been updated into the accumulator for this employee.'		As msg_desc,
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
                    AND event_id_01		=	'03'

                    INSERT INTO DBShrpn.dbo.ghr_msg_tbl
                    SELECT 'U00039'					As msg_id,
                            @emp_id_01					As msg_p1,
                            @empl_id_01					As msg_p2,
                            'Employer does not exists - bypassing record'	As msg_desc

                    -- Historical Message for reporting purpose
                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                    SELECT  'U00039'					As msg_id,
                            '03'						As event_id,
                            @emp_id_01 					As emp_id,
                            @eff_date_01				As eff_date,
                            @pay_element_desc_06		As pay_element_id,
                            @emp_id_01					As msg_p1,
                            @empl_id_01					As msg_p2,
                            'Employer does not exists - bypassing record'	As msg_desc,
                            @p_activity_date			AS activity_date
                    -- End of Historical Message for reporting purpose

                    SELECT  @w_fatal_error = '5'

                    -- GOTO BYPASS_EMPLOYEE

                END
        END

        --
        -- Check to see if the new employer is not the same as the current employer
        --
        --	INSERT INTO [DBShrpn].[dbo].[ghr_msgtbl] SELECT 'Before 1' + @emp_id_01 + 'cnt: ' + CONVERT(CHAR,@cnt) + '@i_empl_id: ' + @i_empl_id + '@empl_id_01: ' + @empl_id_01 AS [msgdesc]
        IF @i_empl_id = @empl_id_01
        BEGIN
                IF EXISTS (SELECT emp_id_01 FROM DBShrpn.dbo.ghr_employee_events WHERE emp_id_01 = @emp_id_01 and event_id_01 = '02')
                    BEGIN
                        UPDATE DBShrpn.dbo.ghr_employee_events_aud
                        SET activity_status = '99'
                        WHERE emp_id_01 = @emp_id_01 AND activity_date = @p_activity_date AND event_id_01 = '03'

                        GOTO BYPASS_EMPLOYEE
                    END
                ELSE
                    BEGIN
                        UPDATE DBShrpn.dbo.ghr_employee_events_aud
                            SET activity_status	= '02'
                            WHERE activity_date	=	@p_activity_date
                            AND emp_id_01		=	@emp_id_01
                            AND event_id_01		=	'03'

                        INSERT INTO DBShrpn.dbo.ghr_msg_tbl
                        SELECT 'U00034'				As msg_id,
                                @emp_id_01			As msg_p1,
                                @empl_id_01			As msg_p2,
                                'Cannot transfer an employee to the same employer.'	As msg_desc

                            -- Historical Message for reporting purpose
                        INSERT INTO DBShrpn.dbo.ghr_historical_message
                        SELECT  'U00034'						As msg_id,
                                '03'							As event_id,
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

            -- GOTO BYPASS_EMPLOYEE

        END


        IF @w_trace_sw = 'Y'
            INSERT INTO DBSosxp.dbo.msg
            SELECT 'Message_5: End ' + ' event_id: ' + @event_id_01 + ' emp_id: ' + @emp_id_01 + ' eff date: ' + @eff_date_01 + ' count: ' + CAST(@cnt AS CHAR(10))  AS msg_desc


        --
        --	Check to see if pay element control group is blank
        --

        IF	@pay_element_ctrl_grp_id_03 = ''
        BEGIN

            UPDATE DBShrpn.dbo.ghr_employee_events_aud
                SET activity_status	=	'02'
                WHERE activity_date	=	@p_activity_date
                AND emp_id_01		=	@emp_id_01
                AND event_id_01		=	'03'

            INSERT INTO DBShrpn.dbo.ghr_msg_tbl
            SELECT	'U00040'				As msg_id,
                    @emp_id_01				As msg_p1,
                    @empl_id_01				As msg_p2,
                    'Pay Element Ctrl Grp cannot be blank'	As msg_desc

            -- Historical Message for reporting purpose
            INSERT INTO DBShrpn.dbo.ghr_historical_message
            SELECT  'U00040'						As msg_id,
                    '03'							As event_id,
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
                AND event_id_01		=	'03'

            INSERT INTO DBShrpn.dbo.ghr_msg_tbl
            SELECT 'U00036'				As msg_id,
                    @emp_id_01			As msg_p1,
                    @empl_id_01			As msg_p2,
            'Transfer date must be greater than default position effective date'	As msg_desc

            -- Historical Message for reporting purpose
            INSERT INTO DBShrpn.dbo.ghr_historical_message
            SELECT  'U00036'						As msg_id,
                '03'							As event_id,
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
        -- Check to see if the employee is getting transfer to pensioner employer.
        --

        SELECT @pos_eff_date = eff_date FROM DBShrpn.dbo.position WHERE pos_id = '99999'

        IF EXISTS(SELECT * FROM DBShrpn.dbo.employer WHERE empl_id = @empl_id_01 AND name like 'Pen%')
            BEGIN
                IF @rehire_override = '0'
                    BEGIN
                        UPDATE DBShrpn.dbo.ghr_employee_events_aud
                            SET activity_status	= '02'
                        WHERE activity_date	=	@p_activity_date
                            AND emp_id_01		=	@emp_id_01
                            AND event_id_01		=	'03'

                        INSERT INTO DBShrpn.dbo.ghr_msg_tbl
                        SELECT 'U00044'				As msg_id,
                                @emp_id_01			As msg_p1,
                                @empl_id_01			As msg_p2,
                        'Cannot transfer an employee to a pensioner employer'	As msg_desc

                    -- Historical Message for reporting purpose
                        INSERT INTO DBShrpn.dbo.ghr_historical_message
                        SELECT  'U00044'						As msg_id,
                                '03'							As event_id,
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
                            AND event_id_01		=	'03'
                    END

            -- GOTO BYPASS_EMPLOYEE

        END
        --
        -- Check to see if the employee current status is terminated.
        --

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
                            AND event_id_01		=	'03'

                        INSERT INTO DBShrpn.dbo.ghr_msg_tbl
                        SELECT 'U00045'				As msg_id,
                                @emp_id_01			As msg_p1,
                                @empl_id_01			As msg_p2,
                                'Terminated employee cannot be transferred'	As msg_desc

                        -- Historical Message for reporting purpose
                        INSERT INTO DBShrpn.dbo.ghr_historical_message
                        SELECT  'U00045'						As msg_id,
                                '03'							As event_id,
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
                                AND event_id_01		=	'03'

                                SELECT  @w_fatal_error = '5'
                    END

                -- GOTO BYPASS_EMPLOYEE

            END

        --
        --
        --  Make sure that frequency is semi monthly starting April 1 of 2023
        --
        --
            SELECT @pay_frequency_code	= pay_frequency_code
            FROM [DBShrpn].[dbo].[pay_group] WHERE [pay_group_id] = @pay_group_id_03
        --
        IF @pay_frequency_code <> 'SEMI'
            BEGIN
                UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                SET activity_status	=	'02'
                WHERE activity_date	=	@p_activity_date
                AND emp_id_01		=	@emp_id_01
                AND event_id_01		=	'03'

                INSERT INTO DBShrpn.dbo.ghr_msg_tbl
                    SELECT 'U00048'					As msg_id,
                            @emp_id_01					As msg_p1,
                            @pay_element_ctrl_grp_id_03	As msg_p2,
                            'After April 1, 2023,Pay Group, @1, must be semi-monthly.'	As msg_desc

                -- Historical Message for reporting purpose
                INSERT INTO DBShrpn.dbo.ghr_historical_message
                SELECT  'U00048'					As msg_id,
                        '03'						As event_id,
                        @emp_id_01 					As emp_id,
                        @eff_date_01				As eff_date,
                        @pay_element_desc_06		As pay_element_id,
                        @emp_id_01					As msg_p1,
                        @pay_element_ctrl_grp_id_03	As msg_p2,
                        'After April 1, 2023,Pay Group, ' + RTRIM(@pay_group_id_03) + ' , must be semi-monthly.'	As msg_desc,
                        @p_activity_date			AS activity_date
                -- End of Historical Message for reporting purpose

                IF GETDATE() > '20230331' SELECT	@w_fatal_error = '5'

            END

        IF @w_trace_sw = 'Y'
            INSERT INTO DBSosxp.dbo.msg SELECT 'Message_9: Beg of BYPASS ' + ' event_id: ' + @event_id_01 + ' emp_id: ' + @emp_id_01 + ' eff date: ' + @eff_date_01 + ' count: ' + CAST(@cnt AS CHAR(10))  AS msg_desc

   	    IF  @w_fatal_error = '5'
            GOTO BYPASS_EMPLOYEE

        IF @w_trace_sw = 'Y'
            INSERT INTO DBSosxp.dbo.msg SELECT 'Message_9: End of BYPASS ' + ' event_id: ' + @event_id_01 + ' emp_id: ' + @emp_id_01 + ' eff date: ' + @eff_date_01 + ' count: ' + CAST(@cnt AS CHAR(10))  AS msg_desc


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
        SELECT	@new_tax_entity	=	[tax_entity_id]
        FROM	[DBShrpn].[dbo].[empl_tax_entity]
        WHERE	[empl_id]		=	@empl_id_01

        --	Find the Job_position end date and Assignment end date limited to after Jan 1, 2021
        SELECT	@assignment_end_date		=	ea.end_date,
                @job_position_end_date		=	ea.end_date,
                @assigned_to_code			=	ea.assigned_to_code
        FROM	[DBShrpn].[dbo].[emp_assignment] ea
        WHERE	ea.emp_id					=	@emp_id_01
        AND	ea.eff_date					=	(SELECT MAX(t.eff_date) FROM [DBShrpn].[dbo].[emp_assignment] t WHERE t.emp_id = ea.emp_id AND t.end_date >= CAST('Jan 1, 2021' AS DATE))
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
                -- SELECT *
        FROM	[DBShrpn].[dbo].[emp_assignment]	ea
        WHERE	emp_id					=	@emp_id_01
        AND	prime_assignment_ind	=	'Y'
        AND  eff_date				=	(
                                         SELECT	MAX(eff_date)
                                         FROM	[DBShrpn].[dbo].[emp_assignment] t
                                         WHERE	t.emp_id =	ea.emp_id AND prime_assignment_ind	=	'Y'
                                        )


        --	e.taxing_country_code	AS new_taxing_country_code AND e.curr_code	AS new_curr_code,

        SELECT	@new_taxing_country_code	=	e.taxing_country_code,
                @new_curr_code				=	e.curr_code
        FROM	[DBShrpn].[dbo].employer e
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

        /*
            SELECT 		@p_emp_id,
                        @p_old_empl_id					AS	old_empl_id,
                        @old_entity						AS	old_entity,
                        @new_tax_entity					AS	new_tax_entity,
                        @p_new_empl_id					AS  new_empl_id,
                        @p_job_position_end_date		AS  end_date_1,
                        @p_assignment_end_date			AS  end_date_2,
                        @p_new_empl_curr_code			AS  curr_code,
                        @p_assign_to					AS 	assigned_to_code,
                        @new_taxing_country_code		AS  taxing_country_code,
                        @new_curr_code					AS	curr_code
        */

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

        /*
        SELECT			  @p_emp_id,
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
        */


        --                                             1023319   0801   080105   20210901	P	99999  5  GHR-HR   080010500	  080105T  	0801T   20210601          TRAN 	 29991231 	29991231   N   GD	XCD	  Y
        --EXECUTE DBShrpn.dbo.hsp_upd_hrpn_02 '1023319','0801','080105','20210901','P','99999',5,'GHR-HR','080010500','','080105T','0801T','20210601','PRWA','TRAN','29991231','29991231','N','GD','XCD','Y'

        IF @w_trace_sw = 'Y'
            INSERT INTO DBSosxp.dbo.msg SELECT 'Detail_Loop: Beg DBShrpn.dbo.usp_upd_hrpn_02_trn' + ' event_id: ' + @event_id_01 + ' emp_id: ' + @emp_id_01 + ' eff date: ' + @eff_date_01 + ' count: ' + CAST(@cnt AS CHAR(10))  AS msg_desc

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

        IF @w_trace_sw = 'Y'
            INSERT INTO DBSosxp.dbo.msg SELECT 'Detail_Loop: End DBShrpn.dbo.hsp_upd_hrpn_02_trn' + ' event_id: ' + @event_id_01 + ' emp_id: ' + @emp_id_01 + ' eff date: ' + @eff_date_01 + ' count: ' + CAST(@cnt AS CHAR(10))  AS msg_desc


		SELECT
				@p_calendar_year			=	LEFT(convert(varchar(10),@p_transfer_date,112),4),
				@p_curr_code				=	@p_new_empl_curr_code,
				@p_return_to_prior_empl		=	'N',
				@p_empl_adj_paymnt_run_type =	'#ADJUSTMNT',
				@p_system_user_id			=	'DBS',
				@p_pay_group_id				=	 @p_pay_group

        /*
        SELECT			  @p_emp_id,
                        @p_old_empl_id,
                        @p_new_empl_id,
                        @p_transfer_date,
                        @p_calendar_year,
                        @p_curr_code,
                        @p_return_to_prior_empl,
                        @p_empl_adj_paymnt_run_type,
                        @p_system_user_id,
                        @p_pay_group_id
        */

        --EXECUTE BAYLEAF.DBShrpy.dbo.hsp_ins_hpep_02 '000405 ','0911509','0101'  ,'20210801',2021,'XCD','N','#ADJUSTMNT','JGROSS','MTH'
        --EXECUTE BAYLEAF.DBShrpy.dbo.hsp_ins_hpep_02 '1023319','0801'   ,'080105','20210901',2021,'XCD','N','#ADJUSTMNT','DBS'   ,'PRWA'
        --											   1023319   0801      080105   20210901  2021	XCD	  N   #ADJUSTMNT   DBS

        IF @w_trace_sw = 'Y'
            INSERT INTO DBSosxp.dbo.msg SELECT 'Detail_Loop: Beg DBShrpy.dbo.usp_ins_hpep_02_trn' + ' event_id: ' + @event_id_01 + ' emp_id: ' + @emp_id_01 + ' eff date: ' + @eff_date_01 + ' count: ' + CAST(@cnt AS CHAR(10))  AS msg_desc

        EXECUTE DBShrpy.dbo.usp_ins_hpep_02_trn @p_emp_id,
                        @p_old_empl_id,
                        @p_new_empl_id,
                        @p_transfer_date,
                        @p_calendar_year,
                        @p_curr_code,
                        @p_return_to_prior_empl,
                        @p_empl_adj_paymnt_run_type,
                        @p_system_user_id,
                        @p_pay_group_id

        IF @w_trace_sw = 'Y'
            INSERT INTO DBSosxp.dbo.msg SELECT 'Detail_Loop: End DBShrpy.dbo.usp_ins_hpep_02_trn' + ' event_id: ' + @event_id_01 + ' emp_id: ' + @emp_id_01 + ' eff date: ' + @eff_date_01 + ' count: ' + CAST(@cnt AS CHAR(10))  AS msg_desc


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

        --
        --	Update the Salary in the Assignment Record
        --

        SELECT	@i_emp_id				=	emp_id,
                @i_assigned_to_code		=	assigned_to_code,
                @i_job_or_pos_id		=	job_or_pos_id,
                @i_eff_date				=	eff_date,
                @i_next_eff_date		=	next_eff_date,
                @i_prior_eff_date		=	prior_eff_date
        FROM	[DBShrpn].[dbo].[emp_assignment]	ea
        WHERE	emp_id					=	@emp_id_01
        AND  eff_date				=	(
                                         SELECT	MAX(eff_date)
                                         FROM [DBShrpn].[dbo].[emp_assignment] t
                                         WHERE t.emp_id =	ea.emp_id
                                           AND prime_assignment_ind	=	'Y')
                                           AND prime_assignment_ind	=	'Y'


        --	SELECT @pay_frequency_code	= pay_frequency_code
        --    FROM [DBShrpn].[dbo].[pay_group] WHERE [pay_group_id] = @pay_group_id_03

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
        SELECT @individual_id = individual_id FROM [DBShrpn].[dbo].[employee] WHERE emp_id = @emp_id_01

        UPDATE	[DBShrpn].[dbo].[individual_personal]
            SET	user_text_1		=	CAST(@position_title_01 AS CHAR(50))
        WHERE individual_id	=	@individual_id


	    BYPASS_EMPLOYEE:

        SELECT @cnt = @cnt + 1
    END

    IF @w_trace_sw = 'Y'
        INSERT INTO DBSosxp.dbo.msg SELECT 'Detail_Loop: End of Loop' + ' event_id: ' + @event_id_01 + ' emp_id: ' + @emp_id_01 + ' eff date: ' + @eff_date_01 + ' count: ' + CAST(@cnt AS CHAR(10))  AS msg_desc

    --
    -- Notify the users of all the issues
    --

    --
    -- Send notification of warning message U00017  -- < Employee Transfer Section (3) >
    --

    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00017'

    SELECT @max = COUNT(*)
    --  SELECT *
    FROM DBShrpn.dbo.ghr_employee_events
    WHERE [event_id_01] = '04'
    SELECT @maxx = CAST(@max As CHAR(06))
    SELECT @special_value_exists = 0
    SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)
    SELECT @msg_id = 'U00017'

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
    -- End of Sending notification of warning message U00000
    --

    --
    -- Send notification of warning message U00009  -- < BEGINING OF WARNING MESSAGES: >
    --

    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00009'

    SELECT @max = COUNT(*)
    --  SELECT *
    FROM DBShrpn.dbo.ghr_employee_events
    WHERE [event_id_01] = '04'
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
    -- Send notification of warning message U00018  -- Total Global HR Employee Transfer:
    --

    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    --  SELECT *
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00018'

    SELECT @max = COUNT(*)
    --  SELECT *
    FROM DBShrpn.dbo.ghr_employee_events
    WHERE [event_id_01] = '03'
    SELECT @maxx = CAST(@max As CHAR(06))
    SELECT @special_value_exists = 0
    SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)
    SELECT @msg_id = 'U00018'

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


    -- CJP 6/19/2025 - Section incorrectly used U00013 should be U00012
    --
    -- Send notification of warning message U00012 -- Employee does not exists Message
    --

    IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_message_temp_3]') AND type in (N'U'))
        DROP TABLE [dbo].[ghr_message_temp_3]


    CREATE TABLE [dbo].[ghr_message_temp_3](
        [ID]							[int] IDENTITY(1,1) NOT NULL,
        [msg_id]						[char](15)	NOT NULL,
        [msg_p1]						[char](15)	NOT NULL,
        [msg_p2]						[char](15)	NOT NULL,
        [msg_desc]						[char](255) NOT NULL
    )


    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00012'

    INSERT INTO DBShrpn.dbo.ghr_message_temp_3
    SELECT *
    FROM DBShrpn.dbo.ghr_msg_tbl
    WHERE msg_id = 'U00012'

    SET @cnt = 1

    SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_3


    WHILE (@cnt <= @max)
    BEGIN

    SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_3 t3 WHERE t3.[ID] = @cnt

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
    --	End of warning message U00012
    --

    --
    -- Send notification of warning message U00036 -- Transfer date must be greater than default position effective date
    --

    IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_message_temp_3]') AND type in (N'U'))
        DROP TABLE [dbo].[ghr_message_temp_3]


    CREATE TABLE [dbo].[ghr_message_temp_3](
        [ID]							[int] IDENTITY(1,1) NOT NULL,
        [msg_id]						[char](15)	NOT NULL,
        [msg_p1]						[char](15)	NOT NULL,
        [msg_p2]						[char](15)	NOT NULL,
        [msg_desc]						[char](255) NOT NULL
    )


    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00036'

    INSERT INTO DBShrpn.dbo.ghr_message_temp_3
    SELECT *
    FROM DBShrpn.dbo.ghr_msg_tbl
    WHERE msg_id = 'U00036'

    SET @cnt = 1

    SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_3


    WHILE (@cnt <= @max)
    BEGIN

    SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_3 t3 WHERE t3.[ID] = @cnt

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
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00036'

    SELECT @cnt = @cnt + 1;

    END
    --
    --	End of warning message U00036
    --

    --
    -- Send notification of warning message U00034 -- Cannot transfer an employee to the same employer. New Employer is @1 - By passing this employee: @2
    --

    IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_message_temp_3]') AND type in (N'U'))
        DROP TABLE [dbo].[ghr_message_temp_3]


    CREATE TABLE [dbo].[ghr_message_temp_3](
        [ID]							[int] IDENTITY(1,1) NOT NULL,
        [msg_id]						[char](15)	NOT NULL,
        [msg_p1]						[char](15)	NOT NULL,
        [msg_p2]						[char](15)	NOT NULL,
        [msg_desc]						[char](255) NOT NULL
    )


    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00034'

    INSERT INTO DBShrpn.dbo.ghr_message_temp_3
    SELECT *
    FROM DBShrpn.dbo.ghr_msg_tbl
    WHERE msg_id = 'U00034'

    SET @cnt = 1

    SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_3


    WHILE (@cnt <= @max)
    BEGIN

    SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_3 t3 WHERE t3.[ID] = @cnt

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
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00034'

    SELECT @cnt = @cnt + 1;

    END

    --
    -- Send notification of warning message U00038 -- Existing payment have not been updated into the accoumulator for this employee: @1
    --

    IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_message_temp_3]') AND type in (N'U'))
        DROP TABLE [dbo].[ghr_message_temp_3]


    CREATE TABLE [dbo].[ghr_message_temp_3](
        [ID]							[int] IDENTITY(1,1) NOT NULL,
        [msg_id]						[char](15)	NOT NULL,
        [msg_p1]						[char](15)	NOT NULL,
        [msg_p2]						[char](15)	NOT NULL,
        [msg_desc]						[char](255) NOT NULL
    )


    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00038'

    INSERT INTO DBShrpn.dbo.ghr_message_temp_3
    SELECT *
    FROM DBShrpn.dbo.ghr_msg_tbl
    WHERE msg_id = 'U00038'

    SET @cnt = 1

    SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_3


    WHILE (@cnt <= @max)
    BEGIN

    SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_3 t3 WHERE t3.[ID] = @cnt

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
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00038'

    SELECT @cnt = @cnt + 1;

    END

    --
    -- Send notification of warning message U00044 -- Cannot transfer an employee, @1, to a pensioner employer
    --

    IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_message_temp_3]') AND type in (N'U'))
        DROP TABLE [dbo].[ghr_message_temp_3]


    CREATE TABLE [dbo].[ghr_message_temp_3](
        [ID]							[int] IDENTITY(1,1) NOT NULL,
        [msg_id]						[char](15)	NOT NULL,
        [msg_p1]						[char](15)	NOT NULL,
        [msg_p2]						[char](15)	NOT NULL,
        [msg_desc]						[char](255) NOT NULL
    )


    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00044'

    INSERT INTO DBShrpn.dbo.ghr_message_temp_3
    SELECT *
    FROM DBShrpn.dbo.ghr_msg_tbl
    WHERE msg_id = 'U00044'

    SET @cnt = 1

    SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_3


    WHILE (@cnt <= @max)
    BEGIN

    SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_3 t3 WHERE t3.[ID] = @cnt

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
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00044'

    SELECT @cnt = @cnt + 1;

    END

    --JAG
    --
    -- Send notification of warning message U00045 -- Terminated employee, @1, cannot be transferred
    --

    IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_message_temp_3]') AND type in (N'U'))
        DROP TABLE [dbo].[ghr_message_temp_3]


    CREATE TABLE [dbo].[ghr_message_temp_3](
        [ID]							[int] IDENTITY(1,1) NOT NULL,
        [msg_id]						[char](15)	NOT NULL,
        [msg_p1]						[char](15)	NOT NULL,
        [msg_p2]						[char](15)	NOT NULL,
        [msg_desc]						[char](255) NOT NULL
    )


    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00045'

    INSERT INTO DBShrpn.dbo.ghr_message_temp_3
    SELECT *
    FROM DBShrpn.dbo.ghr_msg_tbl
    WHERE msg_id = 'U00045'

    SET @cnt = 1

    SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_3


    WHILE (@cnt <= @max)
    BEGIN

    SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_3 t3 WHERE t3.[ID] = @cnt

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
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00045'

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

    IF @w_trace_sw = 'Y'
    INSERT INTO DBSosxp.dbo.msg SELECT 'End usp_perform_transfer' AS msg_desc

    /*

    SELECT @p_status = 0

    */

END
GO

ALTER AUTHORIZATION ON [dbo].[usp_perform_transfer] TO  SCHEMA OWNER
GO
