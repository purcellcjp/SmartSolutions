USE DBShrpn
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'dbo.usp_ins_new_hire', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_ins_new_hire
    IF OBJECT_ID(N'dbo.usp_ins_new_hire') IS NOT NULL
        PRINT N'<<< FAILED DROPPING PROCEDURE dbo.usp_ins_new_hire >>>'
    ELSE
        PRINT N'<<< DROPPED PROCEDURE dbo.usp_ins_new_hire >>>'
END
GO

CREATE PROCEDURE dbo.usp_ins_new_hire
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

    DECLARE @v_step_position                         varchar(255) = 'Begin Procedure'

    DECLARE @ErrorMessage                            nvarchar(4000)
    DECLARE @ErrorSeverity                           int
    DECLARE @ErrorState                              int

    DECLARE @v_ret_val                      int = 0
    DECLARE @w_msg_text						varchar(255)
    DECLARE @w_msg_text_2					varchar(255)
    DECLARE @w_msg_text_3					varchar(255)
    DECLARE @w_severity_cd					tinyint
    DECLARE @w_fatal_error					char(01)
    DECLARE @w_trace_sw						char(01)

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

    DECLARE @ee_emp_id	char(15)
    DECLARE @ee_eff_date datetime
    DECLARE @ee_next_eff_date datetime
    DECLARE @ee_prior_eff_date	datetime

    --
    -- Disabled tracing logic since table doesn't exist - CJP 6/12/2025
    -- SELECT @w_trace_sw = 'N'

    -- IF @w_trace_sw = 'Y'
    --     INSERT INTO DBSosxp.dbo.msg SELECT CAST(GETDATE() AS CHAR (20)) AS msg_desc

    -- IF @w_trace_sw = 'Y'
    -- INSERT INTO DBSosxp.dbo.msg SELECT 'Start usp_ins_new_hire' AS msg_desc

    --
    -- Activate these fields when testing this program standalone.
    --
    /*
    SET @p_userid			=	'DBS'
    SET @p_batchname		=	'GHR'
    SET @p_qualifier		=	'INTERFACES'
    SET @p_activity_date	=	GETDATE()
    SET @p_user_id			=	'GHRUser'
    SET @p_activity_status	=	'00'
    SET @p_status			=	0
    */

    DECLARE @max			INT
    DECLARE @maxx			VARCHAR(06)
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
    DECLARE @pay_frequency_code		char(05)
    DECLARE @annualizing_factor float


    -- Fields required for new hire
    --DECLARE @w_employer_id                          char(10)        = ''
    -- DECLARE @w_employee_id                          char(15)        = ''
    -- DECLARE @w_individual_id                        char(10)        = ''--'566'    --This number must be obtained from the table
    -- DECLARE @w_original_hire_date                   datetime        = '29991231'
    -- DECLARE @w_first_name                           char(25)        = ''
    -- DECLARE @w_first_middle_name                    char(25)        = ''
    -- DECLARE @w_last_name                            char(30)        = ''
    DECLARE @w_preferred_name                       char(25)        = ''
    DECLARE @w_name_suffix                          char(10)        = ''
    DECLARE @w_emp_display_name                     char(45)        = ''
    DECLARE @w_birth_date                           datetime        = '29991231'
    DECLARE @w_sex_code                             char(01)        = ''
    DECLARE @w_marital_status_code_1                char(05)        = ''
    -- DECLARE @w_national_id_1_type_code              char(05)        = 'NIS'--'SSN'
    -- DECLARE @w_national_id_1                        char(20)        = ''
    DECLARE @w_addr_1_type_code                     char(05)        = ''
    DECLARE @w_addr_1_fmt_code                      char(06)        = 'EC1'--'US1'
    DECLARE @w_addr_1_line_1                        char(35)        = ''
    DECLARE @w_addr_1_line_2                        char(35)        = ''
    DECLARE @w_addr_1_line_3                        char(35)        = ''
    DECLARE @w_addr_1_line_4                        char(35)        = ''
    DECLARE @w_addr_1_line_5                        char(35)        = ''
    DECLARE @w_addr_1_street_or_pob_1               char(35)        = ''
    DECLARE @w_addr_1_street_or_pob_2               char(35)        = ''
    DECLARE @w_addr_1_street_or_pob_3               char(35)        = ''
    DECLARE @w_addr_1_city_name                     char(35)        = ''
    DECLARE @w_addr_1_ctry_sub_entity_code          char(09)        = ''
    DECLARE @w_addr_1_postal_code                   char(09)        = ''
    DECLARE @w_addr_1_country_code                  char(02)        = ''
    DECLARE @w_assigned_to_code                     char(01)        = 'P'
    DECLARE @w_job_or_pos_id                        char(10)        = ''
    DECLARE @w_organization_chart_name              char(64)        = 'HRGOSL'  -- not currently being used
    -- DECLARE @w_organization_unit_name               char(240)       = '99999'
    -- DECLARE @w_emp_status_classn_code               char(02)        = '01'
    DECLARE @w_active_reason_code                   char(05)        = ''
    -- DECLARE @w_employment_type_code                 char(05)        = ''
    DECLARE @w_professional_cat_code                char(05)        = ''
    DECLARE @w_labor_grp_code                       char(05)        = ''
    DECLARE @w_non_employee_indicator               char(01)        = 'N'
    DECLARE @w_excluded_from_payroll_ind            char(01)        = 'N'
    DECLARE @w_pensioner_indicator                  char(01)        = 'N'
    DECLARE @w_provided_i_9_ind                     char(01)        = 'N'
    DECLARE @w_base_rate_tbl_id                     char(10)        = ''
    DECLARE @w_base_rate_tbl_entry_code             char(08)        = ''
    DECLARE @w_exception_rate_ind                   char(01)        = 'N'

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
    DECLARE @w_work_shift_code                      char(05)        = ''
    DECLARE @w_tax_entity_id                        char(10)        = 'TE1-C01'
    -- DECLARE @w_time_reporting_meth_code             char(01)        = '1'
    -- DECLARE @w_pay_group_id                         char(10)        = 'ADMP'
    DECLARE @w_clock_nbr                            char(10)        = ''
    DECLARE @w_prim_disbursal_loc_code              char(10)        = ''
    DECLARE @w_alt_disbursal_loc_code               char(10)        = ''
    DECLARE @w_tax_marital_status_code              char(01)        = '1'
    DECLARE @w_fui_status_code                      char(01)        = '2'
    DECLARE @w_oasdi_status_code                    char(01)        = '2'
    DECLARE @w_medicare_status_code                 char(01)        = '2'
    DECLARE @w_income_tax_nbr_of_exemps             smallint        = 0
    DECLARE @w_tax_authority_id                     char(10)        = ''
    DECLARE @w_work_resident_status_code            char(01)        = ''
    DECLARE @w_income_tax_calc_meth_cd              char(02)        = ''
    DECLARE @w_tax_authority_2                      char(10)        = ''
    DECLARE @w_tax_authority_3                      char(10)        = ''
    DECLARE @w_tax_authority_4                      char(10)        = ''
    DECLARE @w_tax_authority_5                      char(10)        = ''
    DECLARE @w_work_resident_status_code_2          char(01)        = ''
    DECLARE @w_work_resident_status_code_3          char(01)        = ''
    DECLARE @w_work_resident_status_code_4          char(01)        = ''
    DECLARE @w_work_resident_status_code_5          char(01)        = ''
    DECLARE @w_user_amt_1                           float           = 0
    DECLARE @w_user_amt_2                           float           = 0
    DECLARE @w_user_code_1                          char(05)        = ''
    DECLARE @w_user_code_2                          char(05)        = ''
    DECLARE @w_user_date_1                          datetime        = '29991231'
    DECLARE @w_user_date_2                          datetime        = '29991231'
    DECLARE @w_user_ind_1                           char(01)        = ''
    DECLARE @w_user_ind_2                           char(01)        = ''
    DECLARE @w_user_monetary_amt_1                  money           = 0
    DECLARE @w_user_monetary_amt_2                  money           = 0
    DECLARE @w_user_monetary_curr_code              char(03)        = 'XCD'
    DECLARE @w_user_text_1                          char(50)        = ''
    DECLARE @w_user_text_2                          char(50)        = ''
    DECLARE @w_inc_tax_calc_method                  char(02)        = '2'
    DECLARE @w_ei_status_code                       char(01)        = '2'
    DECLARE @w_ppip_status_code                     char(01)        = '1'
    DECLARE @w_fed_pp_stat_code                     char(01)        = '2'
    DECLARE @w_provincial_pp_stat_code              char(01)        = '1'
    DECLARE @w_income_tax_stat_code                 char(01)        = '2'
    DECLARE @w_pit_stat_code                        char(01)        = '1'
    DECLARE @w_pay_element_ctrl_grp                 char(10)        = ''
    DECLARE @w_emp_workers_comp_class               char(01)        = ''
    DECLARE @w_empl_addr_fmt_code                   char(06)        = 'GN2'
    DECLARE @w_empl_phone_fmt_code                  char(06)        = 'L34'
    DECLARE @w_empl_phone_delimiter                 char(01)        = '-'
    DECLARE @w_empl_recruitment_zone_code           char(05)        = ''
    DECLARE @w_empl_cma_code                        char(02)        = ''
    DECLARE @w_empl_industry_sector_code            char(05)        = ''
    DECLARE @w_empl_province_terr_code              char(02)        = ''
    DECLARE @w_eeo_4_agency_function_code           char(02)        = '99'
    DECLARE @w_eeo_establishment_id                 char(8)         = '0714'
    DECLARE @w_assignment_end_date                  datetime        = '29991231'
    DECLARE @w_location_code                        char(10)        = ''
    DECLARE @w_salary_structure_id                  char(10)        = ''
    DECLARE @w_salary_incr_guideline_id             char(10)        = ''
    DECLARE @w_pay_grade_code                       char(06)        = 'E40'
    DECLARE @w_job_evaluation_points_nbr            smallint        = 0
    DECLARE @w_salary_step_nbr                      smallint        = 0
    DECLARE @w_employer_taxing_ctry_code            char(02)        = 'LC'--'Gd'
    -- DECLARE @w_organization_group_id                int             = 5
    DECLARE @w_wage_plan_code                       char(02)        = ''
    DECLARE @w_emp_health_insurance_cvg_cd          char(02)        = ''
    DECLARE @w_tax_auth_type_code                   char(01)        = ''
    DECLARE @w_tax_auth_type_code_2                 char(01)        = ''
    DECLARE @w_tax_auth_type_code_3                 char(01)        = ''
    DECLARE @w_tax_auth_type_code_4                 char(01)        = ''
    DECLARE @w_tax_auth_type_code_5                 char(01)        = ''
    DECLARE @w_reg_reporting_unit_code			    char(10)        = ''
    DECLARE @w_emp_workers_comp_cvg_cd			    char(01)        = ''


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
        WHERE (msg_id IN ('U00000'
                        ,'U00001'
                        ,'U00003'
                        ,'U00005'
                        ,'U00006'
                        ,'U00007'
                        ,'U00008'
                        ,'U00009'
                        ,'U00010'
                        ,'U00011'
                        ,'U00020'
                        ,'U00021'
                        ,'U00031'
                        ,'U00046'
                        ))

        -- ID Message templates that need to loop through errors to add to log table
        UPDATE #tbl_msg_master
        SET loop_flag = 'Y'
        WHERE (msg_id IN ('U00005'
                        ,'U00006'
                        ,'U00007'
                        ,'U00008'
                        ,'U00020'
                        ,'U00021'
                        ,'U00031'
                        ,'U00046'
                        ))


        SET @v_step_position = 'ghr_employee_events_temp'

        --INSERT INTO #ghr_employee_events_temp
        SELECT *
        FROM DBShrpn.dbo.ghr_employee_events
        WHERE (event_id_01 = '01')

select * from #ghr_employee_events_temp

        -- Set first loop number
        SELECT @cnt = MIN(ID)
        FROM #ghr_employee_events_temp
        WHERE (event_id_01 = '01')

        -- Set last ID number
        SELECT @max = COUNT(ID)
        FROM #ghr_employee_events_temp
        WHERE (event_id_01 = '01')

select @v_step_position as v_step_position
     , @cnt as cnt
     , @max as [max]


        -- Loop through tbl_ghr_msg to populate error message log entry
        DECLARE crsrHR CURSOR FAST_FORWARD FOR
        SELECT msg.msg_id
            , msg.severity_cd
            , ghr.msg_desc
            , msg.msg_text_2
            , msg.msg_text_3
        FROM #tbl_ghr_msg ghr
        JOIN #tbl_msg_master msg ON
            (ghr.msg_id = msg.msg_id)
        WHERE (msg.loop_flag = 'Y')

        OPEN crsrHR

        FETCH crsr
        INTO @msg_id
        , @w_severity_cd
        , @w_msg_text
        , @w_msg_text_2
        , @w_msg_text_3


        -- DELETE #tbl_ghr_msg

        WHILE (@cnt <= @max)
        BEGIN

            SET @v_step_position = 'Begin While Loop'

            SET @w_fatal_error = '0'

            SELECT @event_id_01						    = t.event_id_01
                , @emp_id_01							= t.emp_id_01
                , @eff_date_01						    = t.eff_date_01
                , @first_name_01						= t.first_name_01
                , @first_middle_name_01				= t.first_middle_name_01
                , @last_name_01						= t.last_name_01
                , @empl_id_01							= t.empl_id_01
                , @national_id_1_type_code_01			= 'NIS'--t.national_id_1_type_code_01
                , @national_id_1_01					= t.national_id_1_01
                , @organization_group_id_01			= t.organization_group_id_01
                , @organization_chart_name_01			= ''--t.organization_chart_name_01
                , @organization_unit_name_01			= ''--t.organization_unit_name_01
                , @emp_status_classn_code_01			= t.emp_status_classn_code_01
                , @position_title_01					= t.position_title_01
                , @employment_type_code_01			    = t.employment_type_code_01
                , @annual_salary_amt_01				= t.annual_salary_amt_01
                , @begin_date_02						= t.begin_date_02
                , @end_date_02						    = t.end_date_02
                , @pay_status_code_03					= t.pay_status_code_03
                , @pay_group_id_03					    = t.pay_group_id_03
                , @pay_element_ctrl_grp_id_03			= t.pay_element_ctrl_grp_id_03
                , @time_reporting_meth_code_03		    = t.time_reporting_meth_code_03
                , @employment_info_chg_reason_cd_03	= t.employment_info_chg_reason_cd_03
                , @emp_location_code_03				= t.emp_location_code_03
                , @emp_status_code_5					= t.emp_status_code_5
                , @reason_code_5						= t.reason_code_5
                , @emp_expected_return_date_5			= t.emp_expected_return_date_5
                , @pay_through_date_5					= t.pay_through_date_5
                , @emp_death_date_5					= t.emp_death_date_5
                , @consider_for_rehire_ind_5			= t.consider_for_rehire_ind_5
                , @pay_element_desc_06				    = t.pay_element_desc_06
                , @emp_calculation_06					= t.emp_calculation_06
                , @tax_flag                            = t.tax_flag
                , @nic_flag                            = t.nic_flag
                , @tax_ceiling_amt                     = t.tax_ceiling_amt
                , @labor_grp_code                      = t.labor_grp_code
                , @file_source                         = t.file_source
            FROM #ghr_employee_events_temp t
            WHERE (t.ID = @cnt)


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
                        WHERE empl_id = @empl_id_01
                            AND (name LIKE 'PEN%')
                        )
                    SET @w_job_or_pos_id = 'PEN-0001'

                ELSE
                    SET @w_job_or_pos_id = 'GEN-0001'
            ELSE   -- Ganymede FORTHCM
                SET @w_job_or_pos_id = 'FORT-0001'



            ---------------------------------------------------------------------------
            ---------------------------------------------------------------------------
            --	This section will validate the interface data
            ---------------------------------------------------------------------------
            ---------------------------------------------------------------------------
            SET @v_step_position = 'Begin Validation'

            ---------------------------------------------------------------------------
            -- Check to see if the employee exists
            ---------------------------------------------------------------------------
            IF  EXISTS (
                        SELECT 1
                        FROM DBShrpn.dbo.employee
                        WHERE emp_id = @emp_id_01
                    )
                BEGIN

                    SET @msg_id = 'U00003'
                    SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

                    UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                        SET activity_status	=	'01'
                    WHERE activity_date	=	@p_activity_date
                        AND emp_id_01		=	@emp_id_01
                        AND event_id_01		=	'01'

                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id					As msg_id,
                            @emp_id_01					As msg_p1,
                            ''							As msg_p2,
                            'Total nbr of employee already exists'	As msg_desc

                    -- Historical Message for reporting purpose
                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                    SELECT  @msg_id					As msg_id,
                            '01'						As event_id,
                            @emp_id_01 					As emp_id,
                            @eff_date_01				As eff_date,
                            @pay_element_desc_06		As pay_element_id,
                            @emp_id_01					As msg_p1,
                            ''							As msg_p2,
                            'Employee already exists'	As msg_desc,
                            @p_activity_date			AS activity_date
                    -- End of Historical Message for reporting purpose

                    SELECT  @w_fatal_error = '5'

                    -- GOTO BYPASS_EMPLOYEE
                END


            ---------------------------------------------------------------------------
            -- Check to see if the employer exists
            ---------------------------------------------------------------------------
            IF NOT EXISTS (
                            SELECT *
                            FROM DBShrpn.dbo.employer
                            WHERE empl_id = @empl_id_01
                            )
                BEGIN

                    SET @msg_id = 'U00005'
                    SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

                    IF EXISTS (
                                SELECT *
                                FROM DBShrpn.dbo.employer
                                WHERE empl_id = '0' + @empl_id_01
                                )
                        SELECT @empl_id_01	= '0' + @empl_id_01
                    ELSE
                        BEGIN
                            UPDATE DBShrpn.dbo.ghr_employee_events_aud
                            SET activity_status	= '02'
                            WHERE activity_date	= @p_activity_date
                            AND emp_id_01		= @emp_id_01
                            AND event_id_01		= '01'

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
                            SELECT  @msg_id					As msg_id,
                                    '01'						As event_id,
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


            ---------------------------------------------------------------------------
            -- Check for the exists of the national id
            ---------------------------------------------------------------------------
            IF	(@national_id_1_01 = '')
                BEGIN

                    SET @msg_id = 'U00046'
                    SET @v_step_position = 'Begin ' + @msg_id

                    UPDATE DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status	=	'02'
                    WHERE activity_date	=	@p_activity_date
                    AND emp_id_01		=	@emp_id_01
                    AND event_id_01		=	'01'

                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id						As msg_id
                        , @emp_id_01					As msg_p1
                        , @national_id_1_01			As msg_p2
                        , REPLACE(t.msg_text, '@1', @emp_id_01) AS msg_desc
                    FROM #tbl_msg_master t
                    WHERE (msg_id = @msg_id)

                    -- Historical Message for reporting purpose
                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                    SELECT  'U00046'					As msg_id,
                            '01'						As event_id,
                            @emp_id_01 					As emp_id,
                            @eff_date_01				As eff_date,
                            @pay_element_desc_06		As pay_element_id,
                            @emp_id_01					As msg_p1,
                            @national_id_1_01			As msg_p2,
                            'NIS nbr is blank - defaulting 99999'	As msg_desc,
                            @p_activity_date			AS activity_date
                    -- End of Historical Message for reporting purpose

                    SELECT  @national_id_1_01 = '99999'
                END
            ELSE
                IF	(@national_id_1_01 = '99999')
                    SELECT @national_id_1_01 = '99999'
                ELSE
                    BEGIN
                        IF  EXISTS (
                                    SELECT *
                                    FROM DBShrpn.dbo.individual_personal e
                                    WHERE e.national_id_1 = @national_id_1_01
                                )
                            BEGIN

                                SET @msg_id = 'U00006'
                                SET @v_step_position = 'Begin ' + @msg_id

                                UPDATE DBShrpn.dbo.ghr_employee_events_aud
                                SET activity_status	=	'02'
                                WHERE activity_date	=	@p_activity_date
                                AND emp_id_01		=	@emp_id_01
                                AND event_id_01		=	'01'

                                INSERT INTO #tbl_ghr_msg
                                SELECT @msg_id						As msg_id
                                    , @emp_id_01					As msg_p1
                                    , @national_id_1_01			As msg_p2
                                    , REPLACE(REPLACE(t.msg_text, '@1', @emp_id_01), '@2', @national_id_1_01) AS msg_desc
                                FROM #tbl_msg_master t
                                WHERE (msg_id = @msg_id)

                                -- Historical Message for reporting purpose
                                INSERT INTO DBShrpn.dbo.ghr_historical_message
                                SELECT  @msg_id					As msg_id,
                                        '01'						As event_id,
                                        @emp_id_01 					As emp_id,
                                        @eff_date_01				As eff_date,
                                        @pay_element_desc_06		As pay_element_id,
                                        @emp_id_01					As msg_p1,
                                        @national_id_1_01			As msg_p2,
                                        'NIS nbr already exists - defaulting 99999'	As msg_desc,
                                        @p_activity_date			AS activity_date
                                -- End of Historical Message for reporting purpose

                                SELECT @national_id_1_01 = '99999'
                            END
                    END

            ---------------------------------------------------------------------------
            -- Check to see if the national id is blank
            ---------------------------------------------------------------------------
            IF  (@national_id_1_01 = '' or @national_id_1_01 = NULL)
                BEGIN

                    SET @msg_id = 'U00007'
                    SET @v_step_position = 'Begin ' + @msg_id

                    UPDATE DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status	=	'02'
                    WHERE activity_date	=	@p_activity_date
                    AND emp_id_01		=	@emp_id_01
                    AND event_id_01		=	'01'

                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id					As msg_id
                            , @emp_id_01					As msg_p1
                            , ''							As msg_p2
                            , REPLACE(t.msg_text, '@1', @emp_id_01) AS msg_desc
                    FROM #tbl_msg_master t
                    WHERE (msg_id = @msg_id)

                    -- Historical Message for reporting purpose
                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                    SELECT  @msg_id					As msg_id,
                            '01'						As event_id,
                            @emp_id_01 					As emp_id,
                            @eff_date_01				As eff_date,
                            @pay_element_desc_06		As pay_element_id,
                            @emp_id_01					As msg_p1,
                            ''							As msg_p2,
                            'NIS nbr was blank - defaulting 99999'	As msg_desc,
                            @p_activity_date			AS activity_date
                    -- End of Historical Message for reporting purpose

                    SELECT @national_id_1_01 = '99999'
                END

            ---------------------------------------------------------------------------
            -- Check to see if the unit name exists in the structure table
            ---------------------------------------------------------------------------
            -- GOSL will not supply organization to SS
            /*
            IF NOT EXISTS (
                        SELECT p.NAME
                        FROM DBSosst.dbo.SRG_STRUCTURE s
                        INNER JOIN DBSosst.dbo.SRG_POINT p ON
                        p.GROUP_ID		= s.GROUP_ID AND
                        p.STRUCTURE_ID	= s.STRUCTURE_ID
                        WHERE s.NAME =  @organization_chart_name_01
                            AND p.NAME =	@organization_unit_name_01
                        )
                BEGIN

                    SET @msg_id = 'U00008'
                    SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

                    UPDATE DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status	=	'02'
                    WHERE activity_date	=	@p_activity_date
                    AND emp_id_01		=	@emp_id_01
                    AND event_id_01		=	'01'

					SET @v_step_position = @v_step_position + ' #tbl_ghr_msg'

                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id					As msg_id
                            , @emp_id_01					As msg_p1
                            , RTRIM(@organization_unit_name_01)	As msg_p2
                            , REPLACE(REPLACE(t.msg_text, '@1', RTRIM(@organization_unit_name_01)), '@2', @emp_id_01) AS msg_desc
                    FROM #tbl_msg_master t
                    WHERE (msg_id = @msg_id)

					SET @v_step_position = @v_step_position + ' ghr_historical_message'

                    -- Historical Message for reporting purpose
                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                    SELECT  @msg_id					As msg_id,
                            '01'						As event_id,
                            @emp_id_01 					As emp_id,
                            @eff_date_01				As eff_date,
                            @pay_element_desc_06		As pay_element_id,
                            @emp_id_01					As msg_p1,
                            ' ', --RTRIM(@organization_unit_name_01)	As msg_p2,
                            'Unit name was missing - defaulting 99999'	As msg_desc,
                            @p_activity_date			AS activity_date
                    -- End of Historical Message for reporting purpose

                    SELECT @organization_unit_name_01 = '99999'
                END
            */


            ---------------------------------------------------------------------------
            --	Check to see if pay group id exists
            ---------------------------------------------------------------------------
            IF NOT EXISTS(
                        SELECT *
                        FROM	DBShrpn.dbo.pay_group
                        WHERE	pay_group_id = @pay_group_id_03
                        )
                BEGIN

                    SET @msg_id = 'U00020'
                    SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

                    UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status	= '02'
                    WHERE activity_date	=	@p_activity_date
                    AND emp_id_01		=	@emp_id_01
                    AND event_id_01		=	'01'

                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id					As msg_id
                            , @emp_id_01					As msg_p1
                            , @pay_group_id_03			As msg_p2
                            , REPLACE(REPLACE(t.msg_text, '@1', @pay_group_id_03), '@2', @emp_id_01) AS msg_desc
                    FROM #tbl_msg_master t
                    WHERE (msg_id = @msg_id)


                    -- Historical Message for reporting purpose
                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                    SELECT  @msg_id					As msg_id,
                            '01'						As event_id,
                            @emp_id_01 					As emp_id,
                            @eff_date_01				As eff_date,
                            @pay_element_desc_06		As pay_element_id,
                            @emp_id_01					As msg_p1,
                            @pay_group_id_03			As msg_p2,
                            'Pay Group does not exists'	As msg_desc,
                            @p_activity_date			AS activity_date
                    -- End of Historical Message for reporting purpose

                    SET	@pay_group_id_03 = ' '

                    SET  @w_fatal_error = '5'

                END
/*
            ---------------------------------------------------------------------------
            -- Validate Employee Employment Type Code
            ---------------------------------------------------------------------------
            SET @msg_id = 'U00060'
            SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

            IF NOT EXISTS(
                          SELECT 1
                          FROM DBShrpn.dbo.code_entry_policy
                          WHERE (code_tbl_id = '10093')     -- Employment Types
                        )
                BEGIN

                    UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status	= '02'
                    WHERE activity_date	=	@p_activity_date
                    AND emp_id_01		=	@emp_id_01
                    AND event_id_01		=	'01'

                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id					As msg_id
                            , @emp_id_01					As msg_p1
                            , @pay_group_id_03			As msg_p2
                            , REPLACE(REPLACE(t.msg_text, '@1', @pay_group_id_03), '@2', @emp_id_01) AS msg_desc
                    FROM #tbl_msg_master t
                    WHERE (msg_id = @msg_id)


                    -- Historical Message for reporting purpose
                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                    SELECT  @msg_id					As msg_id,
                            '01'						As event_id,
                            @emp_id_01 					As emp_id,
                            @eff_date_01				As eff_date,
                            @pay_element_desc_06		As pay_element_id,
                            @emp_id_01					As msg_p1,
                            @pay_group_id_03			As msg_p2,
                            'Pay Group does not exists'	As msg_desc,
                            @p_activity_date			AS activity_date
                    -- End of Historical Message for reporting purpose

                    SET	@pay_group_id_03 = ' '

                    SET  @w_fatal_error = '5'

                END
*/


            ---------------------------------------------------------------------------
            -- Skip record if failed validation
            ---------------------------------------------------------------------------
            IF  @w_fatal_error = '5'
                GOTO BYPASS_EMPLOYEE


            ---------------------------------------------------------------------------
            -- Lookup tax entity
            ---------------------------------------------------------------------------
            SET @v_step_position = 'Lookup Tax Entity'
            SELECT @w_tax_entity_id = tax_entity_id
            FROM DBShrpn.dbo.empl_tax_entity
            WHERE (empl_id = @empl_id_01)


            ---------------------------------------------------------------------------
            -- Lookup next individual id
            ---------------------------------------------------------------------------
            SET @v_step_position = 'Lookup Individual ID'

            -- Needed for proc usp_ins_hemp
            SELECT @ind_idx = CONVERT(char(10),gen_indiv_id_last_nbr + 1)
            FROM DBSentp.dbo.entp_human_resources_plcy  with (holdlock)

            -- Set next individual id
            UPDATE DBSentp.dbo.entp_human_resources_plcy
            SET gen_indiv_id_last_nbr = CONVERT(float, @ind_idx)
            WHERE display_name_format = 'LNMCOMFNMFMNSMN'

            -- Derive employee display name
            SET @w_emp_display_name = RTRIM(@last_name_01) + ', ' + RTRIM(@first_name_01)



            ---------------------------------------------------------------------------
            -- Calculate Annual Salary from Pay rate
            ---------------------------------------------------------------------------
            SET @v_step_position = 'Calculate Annual Salary'

            -- GOSL will only provide hourly rate
            --SET @w_hourly_pay_rate = CAST(@annual_salary AS MONEY)
            -- GOSL does not use tm_pd_policy correctly
            -- Calculate Annual Salary = hourly rate * 2080
            --SET @w_annual_salary_amt = ROUND(@w_hourly_pay_rate * 2080.00, 2)


            ---------------------------------------------------------------------------
            -- Lookup Pay Frequency Code
            ---------------------------------------------------------------------------
            -- GOSL not using tm_pd_policy
            /*
            SELECT @pay_frequency_code	= pay_frequency_code
                , @annualizing_factor = annualizing_factor
            FROM DBShrpn.dbo.pay_group
            WHERE pay_group_id = @pay_group_id_03
            */

    /*  -- Disabling Salary Input for GOSL -- CJP 7/17/2025

            IF (@pay_frequency_code = 'MONTH')
                IF (@pay_group_id_03 = 'MONTHLY2')
                    SELECT @w_pd_salary_amt                 = 0.00
                        , @w_pd_salary_tm_pd_id            = ''
                        , @w_standard_work_pd_id           = @pay_frequency_code
                        , @w_standard_work_hrs             = 173.33     -- need a real default value
                        , @w_standard_daily_work_hrs       = 8.0
                ELSE
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
    */

            -- Not Sending Salary Data
            -- SS setup not compatible with HCM
            SELECT @w_pd_salary_amt                    = 0.00
                    , @w_pd_salary_tm_pd_id            = ''
                    , @w_standard_work_pd_id           = ''
                    , @w_standard_work_hrs             = 0.0
                    , @w_standard_daily_work_hrs       = 0.0

            ---------------------------------------------------------------------------
            -- Create New Hire
            ---------------------------------------------------------------------------
            SET @v_step_position = 'Create New Hire'

select @v_step_position                                                                AS v_step_position
, @empl_id_01                                                                          AS empl_id_01
, @emp_id_01                                                                           AS emp_id_01
, @ind_idx                                                                             AS ind_idx
, @eff_date_01                                                                         AS eff_date_01
, @first_name_01                                                                       AS first_name_01
, @first_middle_name_01                                                                AS first_middle_name_01
, @last_name_01                                                                        AS last_name_01
, @w_preferred_name                                                                    AS w_preferred_name
, @w_name_suffix                                                                       AS w_name_suffix
, @w_emp_display_name                                                                  AS w_emp_display_name
, @w_birth_date                                                                        AS w_birth_date
, @w_sex_code                                                                          AS w_sex_code
, @w_marital_status_code_1                                                             AS w_marital_status_code_1
, @national_id_1_type_code_01                                                          AS national_id_1_type_code_01
, @national_id_1_01                                                                    AS national_id_1_01
, @w_addr_1_type_code                                                                  AS w_addr_1_type_code
, @w_addr_1_fmt_code                                                                   AS w_addr_1_fmt_code
, @w_addr_1_line_1                                                                     AS w_addr_1_line_1
, @w_addr_1_line_2                                                                     AS w_addr_1_line_2
, @w_addr_1_line_3                                                                     AS w_addr_1_line_3
, @w_addr_1_line_4                                                                     AS w_addr_1_line_4
, @w_addr_1_line_5                                                                     AS w_addr_1_line_5
, @w_addr_1_street_or_pob_1                                                            AS w_addr_1_street_or_pob_1
, @w_addr_1_street_or_pob_2                                                            AS w_addr_1_street_or_pob_2
, @w_addr_1_street_or_pob_3                                                            AS w_addr_1_street_or_pob_3
, @w_addr_1_city_name                                                                  AS w_addr_1_city_name
, @w_addr_1_ctry_sub_entity_code                                                       AS w_addr_1_ctry_sub_entity_code
, @w_addr_1_postal_code                                                                AS w_addr_1_postal_code
, @w_addr_1_country_code                                                               AS w_addr_1_country_code
, @w_assigned_to_code                                                                  AS w_assigned_to_code
, @w_job_or_pos_id                                                                     AS w_job_or_pos_id
, @organization_chart_name_01                                                          AS organization_chart_name_01
, @organization_unit_name_01                                                           AS organization_unit_name_01
, @emp_status_classn_code_01                                                           AS emp_status_classn_code_01
, @w_active_reason_code                                                                AS w_active_reason_code
, @employment_type_code_01                                                             AS employment_type_code_01
, @w_professional_cat_code                                                             AS w_professional_cat_code
, @w_labor_grp_code                                                                    AS w_labor_grp_code
, @w_non_employee_indicator                                                            AS w_non_employee_indicator
, @w_excluded_from_payroll_ind                                                         AS w_excluded_from_payroll_ind
, @w_pensioner_indicator                                                               AS w_pensioner_indicator
, @w_provided_i_9_ind                                                                  AS w_provided_i_9_ind
, @w_base_rate_tbl_id                                                                  AS w_base_rate_tbl_id
, @w_base_rate_tbl_entry_code                                                          AS w_base_rate_tbl_entry_code
, @w_exception_rate_ind                                                                AS w_exception_rate_ind
, @w_hourly_pay_rate                                                                   AS w_hourly_pay_rate
, @w_pd_salary_amt                                                                     AS w_pd_salary_amt
, @w_pd_salary_tm_pd_id                                                                AS w_pd_salary_tm_pd_id
, @w_annual_salary_amt                                                                 AS w_annual_salary_amt
, @w_pay_basis_code                                                                    AS w_pay_basis_code
, @w_curr_code                                                                         AS w_curr_code
, @w_work_tm_code                                                                      AS w_work_tm_code
, @w_standard_daily_work_hrs                                                           AS w_standard_daily_work_hrs
, @w_standard_work_hrs                                                                 AS w_standard_work_hrs
, @w_standard_work_pd_id                                                               AS w_standard_work_pd_id
, @w_overtime_status_code                                                              AS w_overtime_status_code
, @w_pay_on_reported_hrs_ind                                                           AS w_pay_on_reported_hrs_ind
, @w_work_shift_code                                                                   AS w_work_shift_code
, @w_tax_entity_id                                                                     AS w_tax_entity_id
, @time_reporting_meth_code_03                                                         AS time_reporting_meth_code_03
, @pay_group_id_03                                                                     AS pay_group_id_03
, @w_clock_nbr                                                                         AS w_clock_nbr
, @w_prim_disbursal_loc_code                                                           AS w_prim_disbursal_loc_code
, @w_alt_disbursal_loc_code                                                            AS w_alt_disbursal_loc_code
, @w_tax_marital_status_code                                                           AS w_tax_marital_status_code
, @w_fui_status_code                                                                   AS w_fui_status_code
, @w_oasdi_status_code                                                                 AS w_oasdi_status_code
, @w_medicare_status_code                                                              AS w_medicare_status_code
, @w_income_tax_nbr_of_exemps                                                          AS w_income_tax_nbr_of_exemps
, @w_tax_authority_id                                                                  AS w_tax_authority_id
, @w_work_resident_status_code                                                         AS w_work_resident_status_code
, @w_income_tax_calc_meth_cd                                                           AS w_income_tax_calc_meth_cd
, @w_tax_authority_2                                                                   AS w_tax_authority_2
, @w_tax_authority_3                                                                   AS w_tax_authority_3
, @w_tax_authority_4                                                                   AS w_tax_authority_4
, @w_tax_authority_5                                                                   AS w_tax_authority_5
, @w_work_resident_status_code_2                                                       AS w_work_resident_status_code_2
, @w_work_resident_status_code_3                                                       AS w_work_resident_status_code_3
, @w_work_resident_status_code_4                                                       AS w_work_resident_status_code_4
, @w_work_resident_status_code_5                                                       AS w_work_resident_status_code_5
, @w_user_amt_1                                                                        AS w_user_amt_1
, @w_user_amt_2                                                                        AS w_user_amt_2
, @w_user_code_1                                                                       AS w_user_code_1
, @w_user_code_2                                                                       AS w_user_code_2
, @w_user_date_1                                                                       AS w_user_date_1
, @w_user_date_2                                                                       AS w_user_date_2
, @w_user_ind_1                                                                        AS w_user_ind_1
, @w_user_ind_2                                                                        AS w_user_ind_2
, @w_user_monetary_amt_1                                                               AS w_user_monetary_amt_1
, @w_user_monetary_amt_2                                                               AS w_user_monetary_amt_2
, @w_user_monetary_curr_code                                                           AS w_user_monetary_curr_code
, @w_user_text_1                                                                       AS w_user_text_1
, @position_title_01                                                                   AS position_title_01
, @w_inc_tax_calc_method                                                               AS w_inc_tax_calc_method
, @w_ei_status_code                                                                    AS w_ei_status_code
, @w_ppip_status_code                                                                  AS w_ppip_status_code
, @w_fed_pp_stat_code                                                                  AS w_fed_pp_stat_code
, @w_provincial_pp_stat_code                                                           AS w_provincial_pp_stat_code
, @w_income_tax_stat_code                                                              AS w_income_tax_stat_code
, @w_pit_stat_code                                                                     AS w_pit_stat_code
, @pay_element_ctrl_grp_id_03                                                          AS pay_element_ctrl_grp_id_03
, @w_emp_workers_comp_class                                                            AS w_emp_workers_comp_class
, @w_empl_addr_fmt_code                                                                AS w_empl_addr_fmt_code
, @w_empl_phone_fmt_code                                                               AS w_empl_phone_fmt_code
, @w_empl_phone_delimiter                                                              AS w_empl_phone_delimiter
, @w_empl_recruitment_zone_code                                                        AS w_empl_recruitment_zone_code
, @w_empl_cma_code                                                                     AS w_empl_cma_code
, @w_empl_industry_sector_code                                                         AS w_empl_industry_sector_code
, @w_empl_province_terr_code                                                           AS w_empl_province_terr_code
, @w_eeo_4_agency_function_code                                                        AS w_eeo_4_agency_function_code
, @w_eeo_establishment_id                                                              AS w_eeo_establishment_id
, @w_assignment_end_date                                                               AS w_assignment_end_date
, @w_location_code                                                                     AS w_location_code
, @w_salary_structure_id                                                               AS w_salary_structure_id
, @w_salary_incr_guideline_id                                                          AS w_salary_incr_guideline_id
, @w_pay_grade_code                                                                    AS w_pay_grade_code
, @w_job_evaluation_points_nbr                                                         AS w_job_evaluation_points_nbr
, @w_salary_step_nbr                                                                   AS w_salary_step_nbr
, @w_employer_taxing_ctry_code                                                         AS w_employer_taxing_ctry_code
, @organization_group_id_01                                                            AS organization_group_id_01
, @w_wage_plan_code                                                                    AS w_wage_plan_code
, @w_emp_health_insurance_cvg_cd                                                       AS w_emp_health_insurance_cvg_cd
, @w_tax_auth_type_code                                                                AS w_tax_auth_type_code
, @w_tax_auth_type_code_2                                                              AS w_tax_auth_type_code_2
, @w_tax_auth_type_code_3                                                              AS w_tax_auth_type_code_3
, @w_tax_auth_type_code_4                                                              AS w_tax_auth_type_code_4
, @w_tax_auth_type_code_5                                                              AS w_tax_auth_type_code_5
, @w_reg_reporting_unit_code                                                           AS w_reg_reporting_unit_code
, @w_emp_workers_comp_cvg_cd                                                           AS w_emp_workers_comp_cvg_cd

/*
            EXEC DBShrpn.dbo.usp_ins_hemp
                @p_employer_id                       = @empl_id_01
                , @p_employee_id                       = @emp_id_01
                , @p_individual_id                     = @ind_idx
                , @p_original_hire_date                = @eff_date_01
                , @p_first_name                        = @first_name_01
                , @p_first_middle_name                 = @first_middle_name_01
                , @p_last_name                         = @last_name_01
                , @p_preferred_name                    = @w_preferred_name
                , @p_name_suffix                       = @w_name_suffix
                , @p_emp_display_name                  = @w_emp_display_name
                , @p_birth_date                        = @w_birth_date
                , @p_sex_code                          = @w_sex_code
                , @p_marital_status_code_1             = @w_marital_status_code_1
                , @p_national_id_1_type_code           = @national_id_1_type_code_01
                , @p_national_id_1                     = @national_id_1_01
                , @p_addr_1_type_code                  = @w_addr_1_type_code
                , @p_addr_1_fmt_code                   = @w_addr_1_fmt_code
                , @p_addr_1_line_1                     = @w_addr_1_line_1
                , @p_addr_1_line_2                     = @w_addr_1_line_2
                , @p_addr_1_line_3                     = @w_addr_1_line_3
                , @p_addr_1_line_4                     = @w_addr_1_line_4
                , @p_addr_1_line_5                     = @w_addr_1_line_5
                , @p_addr_1_street_or_pob_1            = @w_addr_1_street_or_pob_1
                , @p_addr_1_street_or_pob_2            = @w_addr_1_street_or_pob_2
                , @p_addr_1_street_or_pob_3            = @w_addr_1_street_or_pob_3
                , @p_addr_1_city_name                  = @w_addr_1_city_name
                , @p_addr_1_ctry_sub_entity_code       = @w_addr_1_ctry_sub_entity_code
                , @p_addr_1_postal_code                = @w_addr_1_postal_code
                , @p_addr_1_country_code               = @w_addr_1_country_code
                , @p_assigned_to_code                  = @w_assigned_to_code
                , @p_job_or_pos_id                     = @w_job_or_pos_id       -- need real value
                , @p_organization_chart_name           = @organization_chart_name_01
                , @p_organization_unit_name            = @organization_unit_name_01
                , @p_emp_status_classn_code            = @emp_status_classn_code_01
                , @p_active_reason_code                = @w_active_reason_code
                , @p_employment_type_code              = @employment_type_code_01
                , @p_professional_cat_code             = @w_professional_cat_code
                , @p_labor_grp_code                    = @w_labor_grp_code
                , @p_non_employee_indicator            = @w_non_employee_indicator
                , @p_excluded_from_payroll_ind         = @w_excluded_from_payroll_ind
                , @p_pensioner_indicator               = @w_pensioner_indicator
                , @p_provided_i_9_ind                  = @w_provided_i_9_ind
                , @p_base_rate_tbl_id                  = @w_base_rate_tbl_id
                , @p_base_rate_tbl_entry_code          = @w_base_rate_tbl_entry_code
                , @p_exception_rate_ind                = @w_exception_rate_ind

                , @p_hourly_pay_rate                   = @w_hourly_pay_rate
                , @p_pd_salary_amt                     = @w_pd_salary_amt
                , @p_pd_salary_tm_pd_id                = @w_pd_salary_tm_pd_id
                , @p_annual_salary_amt                 = @w_annual_salary_amt

                , @p_pay_basis_code                    = @w_pay_basis_code
                , @p_curr_code                         = @w_curr_code
                , @p_work_tm_code                      = @w_work_tm_code
                , @p_standard_daily_work_hrs           = @w_standard_daily_work_hrs
                , @p_standard_work_hrs                 = @w_standard_work_hrs
                , @p_standard_work_pd_id               = @w_standard_work_pd_id
                , @p_overtime_status_code              = @w_overtime_status_code
                , @p_pay_on_reported_hrs_ind           = @w_pay_on_reported_hrs_ind
                , @p_work_shift_code                   = @w_work_shift_code
                , @p_tax_entity_id                     = @w_tax_entity_id
                , @p_time_reporting_meth_code          = @time_reporting_meth_code_03
                , @p_pay_group_id                      = @pay_group_id_03
                , @p_clock_nbr                         = @w_clock_nbr
                , @p_prim_disbursal_loc_code           = @w_prim_disbursal_loc_code
                , @p_alt_disbursal_loc_code            = @w_alt_disbursal_loc_code
                , @p_tax_marital_status_code           = @w_tax_marital_status_code
                , @p_fui_status_code                   = @w_fui_status_code
                , @p_oasdi_status_code                 = @w_oasdi_status_code
                , @p_medicare_status_code              = @w_medicare_status_code
                , @p_income_tax_nbr_of_exemps          = @w_income_tax_nbr_of_exemps
                , @p_tax_authority_id                  = @w_tax_authority_id
                , @p_work_resident_status_code         = @w_work_resident_status_code
                , @p_income_tax_calc_meth_cd           = @w_income_tax_calc_meth_cd
                , @p_tax_authority_2                   = @w_tax_authority_2
                , @p_tax_authority_3                   = @w_tax_authority_3
                , @p_tax_authority_4                   = @w_tax_authority_4
                , @p_tax_authority_5                   = @w_tax_authority_5
                , @p_work_resident_status_code_2       = @w_work_resident_status_code_2
                , @p_work_resident_status_code_3       = @w_work_resident_status_code_3
                , @p_work_resident_status_code_4       = @w_work_resident_status_code_4
                , @p_work_resident_status_code_5       = @w_work_resident_status_code_5
                , @p_user_amt_1                        = @w_user_amt_1
                , @p_user_amt_2                        = @w_user_amt_2
                , @p_user_code_1                       = @w_user_code_1
                , @p_user_code_2                       = @w_user_code_2
                , @p_user_date_1                       = @w_user_date_1
                , @p_user_date_2                       = @w_user_date_2
                , @p_user_ind_1                        = @w_user_ind_1
                , @p_user_ind_2                        = @w_user_ind_2
                , @p_user_monetary_amt_1               = @w_user_monetary_amt_1
                , @p_user_monetary_amt_2               = @w_user_monetary_amt_2
                , @p_user_monetary_curr_code           = @w_user_monetary_curr_code
                , @p_user_text_1                       = @w_user_text_1
                , @p_user_text_2                       = @position_title_01     -- CJP 7/8/2025 @w_user_text_2
                , @p_inc_tax_calc_method               = @w_inc_tax_calc_method
                , @p_ei_status_code                    = @w_ei_status_code
                , @p_ppip_status_code                  = @w_ppip_status_code
                , @p_fed_pp_stat_code                  = @w_fed_pp_stat_code
                , @p_provincial_pp_stat_code           = @w_provincial_pp_stat_code
                , @p_income_tax_stat_code              = @w_income_tax_stat_code
                , @p_pit_stat_code                     = @w_pit_stat_code
                , @p_pay_element_ctrl_grp              = @pay_element_ctrl_grp_id_03
                , @p_emp_workers_comp_class            = @w_emp_workers_comp_class
                , @p_empl_addr_fmt_code                = @w_empl_addr_fmt_code
                , @p_empl_phone_fmt_code               = @w_empl_phone_fmt_code
                , @p_empl_phone_delimiter              = @w_empl_phone_delimiter
                , @p_empl_recruitment_zone_code        = @w_empl_recruitment_zone_code
                , @p_empl_cma_code                     = @w_empl_cma_code
                , @p_empl_industry_sector_code         = @w_empl_industry_sector_code
                , @p_empl_province_terr_code           = @w_empl_province_terr_code
                , @p_eeo_4_agency_function_code        = @w_eeo_4_agency_function_code
                , @p_eeo_establishment_id              = @w_eeo_establishment_id
                , @p_assignment_end_date               = @w_assignment_end_date
                , @p_location_code                     = @w_location_code
                , @p_salary_structure_id               = @w_salary_structure_id
                , @p_salary_incr_guideline_id          = @w_salary_incr_guideline_id
                , @p_pay_grade_code                    = @w_pay_grade_code
                , @p_job_evaluation_points_nbr         = @w_job_evaluation_points_nbr
                , @p_salary_step_nbr                   = @w_salary_step_nbr
                , @p_employer_taxing_ctry_code         = @w_employer_taxing_ctry_code
                , @p_organization_group_id             = @organization_group_id_01
                , @p_wage_plan_code                    = @w_wage_plan_code
                , @p_emp_health_insurance_cvg_cd       = @w_emp_health_insurance_cvg_cd
                , @p_tax_auth_type_code                = @w_tax_auth_type_code
                , @p_tax_auth_type_code_2              = @w_tax_auth_type_code_2
                , @p_tax_auth_type_code_3              = @w_tax_auth_type_code_3
                , @p_tax_auth_type_code_4              = @w_tax_auth_type_code_4
                , @p_tax_auth_type_code_5              = @w_tax_auth_type_code_5
                , @p_reg_reporting_unit_code           = @w_reg_reporting_unit_code
                , @p_emp_workers_comp_cvg_cd           = @w_emp_workers_comp_cvg_cd
*/

            ---------------------------------------------------------------------------
            -- Lookup Employee Employment Details
            ---------------------------------------------------------------------------
            SET @v_step_position = 'Lookup emp_employment'

            SELECT @ee_emp_id         = emp_id
                , @ee_eff_date		  = eff_date
                , @ee_next_eff_date  = next_eff_date
                , @ee_prior_eff_date = prior_eff_date
            FROM DBShrpn.dbo.emp_employment ee
            WHERE emp_id   =	@emp_id_01
            AND eff_date =	(
                                SELECT	MAX(eff_date)
                                FROM DBShrpn.dbo.emp_employment t
                                WHERE	t.emp_id =	ee.emp_id
                                )

            -- Make sure new record end date = end of time date
            SET @v_step_position = 'Set emp_employment end date'

            IF	@ee_next_eff_date <> '29991231'
                UPDATE	DBShrpn.dbo.emp_employment
                SET  next_eff_date = '29991231'
                FROM	DBShrpn.dbo.emp_employment ee
                WHERE  emp_id		=	@ee_emp_id
                AND  eff_date	=	@ee_eff_date


            SELECT @individual_id = individual_id
            FROM DBShrpn.dbo.employee
            WHERE emp_id = @emp_id_01

            /* Grenada
            -- GOSL will store it on emp_assignment
            UPDATE	DBShrpn.dbo.individual_personal
            SET	user_text_1		=	CAST(@position_title_01 AS CHAR(50))
            WHERE individual_id	=	@individual_id
            */

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
            WHERE (emp_id = @emp_id_01)



            BYPASS_EMPLOYEE:

            SELECT @cnt = @cnt + 1

        END  -- Error Loop


        ---------------------------------------------------------------------------
        -- Log warning message U00000 -- < NEW HIRE SECTION (1) >
        ---------------------------------------------------------------------------

        SET @msg_id = 'U00000'
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
        -- Send notification of warning message U00001 -- Total Global HR New Hire: @1
        ---------------------------------------------------------------------------
        SET @msg_id = 'U00001'
        SET @v_step_position = 'Log ' + @msg_id

        SELECT @w_msg_text    = msg_text
            , @w_msg_text_2  = msg_text_2
            , @w_msg_text_3  = msg_text_3
            , @w_severity_cd = severity_cd
        FROM #tbl_msg_master
        WHERE (msg_id = @msg_id)

        -- Get total new hire records from HCM
        SELECT @maxx = CAST(COUNT(*) AS varchar(6))
        FROM DBShrpn.dbo.ghr_employee_events
        WHERE (event_id_01 = '01')

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
        SET @msg_id = 'U00003'
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

        -- Handle cursor
        IF (CURSOR_STATUS('local', 'crsrLog') > 0)
        BEGIN
            CLOSE crsrLog
            DEALLOCATE crsrLog
        END

        SELECT @v_step_position AS step_position
             , @ErrorMessage  AS err_msg
             , @ErrorSeverity AS err_sev
             , @ErrorState    AS err_state

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

ALTER AUTHORIZATION ON dbo.usp_ins_new_hire TO  SCHEMA OWNER
GO

IF OBJECT_ID(N'dbo.usp_ins_new_hire', N'P') IS NOT NULL
    PRINT N'<<< CREATED PROCEDURE dbo.usp_ins_new_hire >>>'
ELSE
    PRINT N'<<< FAILED CREATING PROCEDURE dbo.usp_ins_new_hire >>>'
GO
