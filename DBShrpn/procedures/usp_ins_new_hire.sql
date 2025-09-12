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
 @p_userid      varchar(30),
 @p_batchname     varchar(08),
 @p_qualifier     varchar(30),
    @p_activity_date    datetime,
    @p_user_id      varchar(30),
 @p_status      int         = 0 OUTPUT
)
AS


BEGIN

    SET NOCOUNT ON

    DECLARE @v_step_position                varchar(255)        = 'Begin usp_ins_new_hire'
    DECLARE @v_DISPLAY_NAME_FORMAT          char(33)            = 'LNMCOMSFXFNMFMNSMI'  -- Unique to client
    DECLARE @v_END_OF_TIME_DATE             datetime            = '29991231'

    DECLARE @v_EVENT_ID_NEW_HIRE            char(2)             = '01'


    DECLARE @v_ACTIVITY_STATUS_GOOD         char(2)             = '00'
    DECLARE @v_ACTIVITY_STATUS_WARNING      char(2)             = '01'
    DECLARE @v_ACTIVITY_STATUS_BAD          char(2)             = '02'

    DECLARE @ErrorNumber                    varchar(10)
    DECLARE @ErrorMessage                   nvarchar(4000)
    DECLARE @ErrorSeverity                  int
    DECLARE @ErrorState                     int

    DECLARE @v_ret_val                      int = 0
    DECLARE @w_msg_text      varchar(255)
    DECLARE @w_msg_text_2     varchar(255)
    DECLARE @w_msg_text_3     varchar(255)
    DECLARE @w_severity_cd     tinyint
    DECLARE @w_fatal_error     bit     = 0         --char(01)
    DECLARE @w_trace_sw      char(01)

    DECLARE @special_value_exists   int
    DECLARE @i_emp_id      char(15)
    DECLARE @i_assigned_to_code    char(01)
    DECLARE @i_job_or_pos_id    char(10)
    DECLARE @i_eff_date      datetime
    DECLARE @i_next_eff_date    datetime
    DECLARE @i_prior_eff_date    datetime
    DECLARE @i_standard_work_pd_id   char(5)
    DECLARE @i_standard_work_hrs   float
    DECLARE @i_yearly_std_work_hrs   float
    DECLARE @i_hourly_rate_amt    money
    DECLARE @i_period_amt     money

    DECLARE @ee_emp_id char(15)
    DECLARE @ee_eff_date datetime
    DECLARE @ee_next_eff_date datetime
    DECLARE @ee_prior_eff_date datetime




    DECLARE @maxx   VARCHAR(06)
    DECLARE @ind_idx  CHAR(10)
    DECLARE @annual_salary MONEY
    DECLARE @tax_entity_id CHAR(10)
    DECLARE @msg_id   CHAR(10)
    DECLARE @individual_id CHAR(10)
    DECLARE @pay_frequency_code  char(05)
    DECLARE @annualizing_factor float



    DECLARE @w_preferred_name                       char(25)        = ''
    DECLARE @w_name_suffix                          char(10)        = ''
    DECLARE @w_emp_display_name                     char(45)        = ''
    DECLARE @w_birth_date                           datetime        = @v_END_OF_TIME_DATE
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
    DECLARE @w_user_date_1                          datetime        = @v_END_OF_TIME_DATE
    DECLARE @w_user_date_2                          datetime        = @v_END_OF_TIME_DATE
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
    DECLARE @w_assignment_end_date                  datetime        = @v_END_OF_TIME_DATE
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
    DECLARE @w_reg_reporting_unit_code              char(10)        = ''
    DECLARE @w_emp_workers_comp_cvg_cd              char(01)        = ''

    DECLARE @w_conv_employment_type_code            char(05)
    DECLARE @w_eff_date                             datetime
    DECLARE @w_begin_date                           datetime
    DECLARE @w_end_date                             datetime

    -- This section declares the interface values from Global HR
    DECLARE @event_id                               char(02)
    DECLARE @emp_id                                 char(15)
    DECLARE @eff_date                               char(10)
    DECLARE @first_name                             char(25)
    DECLARE @first_middle_name                      char(25)
    DECLARE @last_name                              char(30)
    DECLARE @empl_id                                char(10)
    DECLARE @national_id_type_code                  char(05)
    DECLARE @national_id                            char(20)
    DECLARE @organization_group_id                  char(05)
    DECLARE @organization_chart_name                varchar(64)
    DECLARE @organization_unit_name                 varchar(240)
    DECLARE @emp_status_classn_code                 char(02)
    DECLARE @position_title                         char(50)        -- DBShrpn..emp_assignment.user_text_2
    DECLARE @employment_type_code                   varchar(70)     -- increased size to 70 from 5
    DECLARE @annual_salary_amt                      char(15)
    DECLARE @begin_date                             char(10)
    DECLARE @end_date                               char(10)
    DECLARE @pay_status_code                        char(01)
    DECLARE @pay_group_id                           char(10)
    DECLARE @pay_element_ctrl_grp_id                char(10)
    DECLARE @time_reporting_meth_code               char(01)
    DECLARE @employment_info_chg_reason_cd          char(05)
    DECLARE @emp_location_code                      char(10)
    DECLARE @emp_status_code                        char(02)
    DECLARE @reason_code                            char(02)
    DECLARE @emp_expected_return_date               char(10)
    DECLARE @pay_through_date                       char(10)
    DECLARE @emp_death_date                         char(10)
    DECLARE @consider_for_rehire_ind                char(01)
    DECLARE @pay_element_id                         char(10)
    DECLARE @emp_calculation                        char(15)
    DECLARE @tax_flag                               char(1)         -- individual_personal.ind_2
    DECLARE @nic_flag                               char(1)         -- individual_personal.ind_1
    DECLARE @tax_ceiling_amt                        char(15)        -- employee.user_monetary_amt_1
    DECLARE @labor_grp_code                         char(5)         -- DBShrpn..emp_employment.labor_grp_code
    DECLARE @file_source                            char(50)        -- 'SS VENUS' or 'SS GANYMEDE'



    CREATE TABLE #tbl_ghr_msg
        (
          msg_id                                    char(15)            NOT NULL
        , msg_desc                                  varchar(255)        NOT NULL
        )


    CREATE TABLE #tbl_msg_master
        (
          msg_id                                    char(15)            NOT NULL
        , severity_cd                               tinyint             NOT NULL
        , msg_text                                  varchar(255)        NOT NULL
        , msg_text_2                                varchar(255)        NOT NULL
        , msg_text_3                                varchar(255)        NOT NULL
        , loop_flag                                 char(1)             NOT NULL
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
                        ,'U00100'
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
                        ,'U00100'
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
             , t.organization_chart_name
             , t.organization_unit_name
             , t.emp_status_classn_code
             , LEFT(t.position_title, 50) AS position_title
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
             , LEFT(t.labor_grp_code, 5) AS labor_grp_code
             , t.file_source
        FROM #ghr_employee_events_temp t
  WHERE (event_id = @v_EVENT_ID_NEW_HIRE)

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

            BEGIN TRY

                SET @v_step_position = 'Begin crsrHR While Loop'

                SET @w_fatal_error = 0

                BEGIN TRAN


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
                                AND (name LIKE 'Pen%')
                            )
                        SET @w_job_or_pos_id = 'PEN-0001'

                    ELSE
                        SET @w_job_or_pos_id = 'GEN-0001'
                ELSE   -- Ganymede FORTHCM
                    SET @w_job_or_pos_id = 'FORT-0001'



                ---------------------------------------------------------------------------
                ---------------------------------------------------------------------------
                -- This section will validate the interface data
                ---------------------------------------------------------------------------
                ---------------------------------------------------------------------------
                SET @v_step_position = 'Validation'

                ---------------------------------------------------------------------------
                -- Check to see if the employee exists
                ---------------------------------------------------------------------------


                IF  EXISTS (
                            SELECT 1
                            FROM DBShrpn.dbo.employee
                            WHERE emp_id = @emp_id
                        )
                    BEGIN

                        SET @msg_id = 'U00003'
                        SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

                        UPDATE DBShrpn.dbo.ghr_employee_events_aud
                            SET activity_status = @v_ACTIVITY_STATUS_BAD
                        WHERE activity_date = @p_activity_date
                            AND emp_id  = @emp_id
                            AND event_id  = @v_EVENT_ID_NEW_HIRE

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id As msg_id
                            , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                        FROM #tbl_msg_master t
                        WHERE (msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_NEW_HIRE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = ''
                            , @p_msg_p1             = ''
                            , @p_msg_p2             = ''
                            , @p_msg_desc           = 'Employee id already exists'
                            , @p_activity_date      = @p_activity_date

                        SET  @w_fatal_error = 1

                    END


                ---------------------------------------------------------------------------
                -- Check to see if the employer exists
                ---------------------------------------------------------------------------

                IF NOT EXISTS (
                                SELECT *
                                FROM DBShrpn.dbo.employer
                                WHERE empl_id = @empl_id
                                )
                    BEGIN

                        SET @msg_id = 'U00005'
                        SET @v_step_position = 'Validation -  ' + RTRIM(@msg_id)

                        IF EXISTS (
                                    SELECT *
                                    FROM DBShrpn.dbo.employer
                                    WHERE empl_id = '0' + @empl_id
                                    )
                            SELECT @empl_id = '0' + @empl_id
                        ELSE
                            BEGIN
                                UPDATE DBShrpn.dbo.ghr_employee_events_aud
                                SET activity_status = @v_ACTIVITY_STATUS_WARNING
                                WHERE activity_date = @p_activity_date
                                AND emp_id  = @emp_id
                                AND event_id  = @v_EVENT_ID_NEW_HIRE

                                INSERT INTO #tbl_ghr_msg
                                SELECT @msg_id         As msg_id
                                    , REPLACE(REPLACE(t.msg_text, '@1', @empl_id), '@2', @emp_id) AS msg_desc
                                FROM #tbl_msg_master t
                                WHERE (msg_id = @msg_id)

                                -- Historical Message for reporting purpose
                                EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                                    @p_msg_id             = @msg_id
                                    , @p_event_id           = @v_EVENT_ID_NEW_HIRE
                                    , @p_emp_id             = @emp_id
                                    , @p_eff_date           = @eff_date
                                    , @p_pay_element_id     = ''
                                    , @p_msg_p1             = ''
                                    , @p_msg_p2             = ''
                                    , @p_msg_desc           = 'Invalid Employer id - defaulting to 99999'
                                    , @p_activity_date      = @p_activity_date

                                SELECT @empl_id = '99999'

                            END
                    END


                ---------------------------------------------------------------------------
                -- Check for the exists of the national id
                ---------------------------------------------------------------------------
                IF (@national_id = '')
                    BEGIN

                        SET @msg_id = 'U00046'
                        SET @v_step_position = 'Validation - ' + @msg_id

                        UPDATE DBShrpn.dbo.ghr_employee_events_aud
                        SET activity_status = @v_ACTIVITY_STATUS_BAD
                        WHERE activity_date = @p_activity_date
                        AND emp_id  = @emp_id
                        AND event_id  = @v_EVENT_ID_NEW_HIRE

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id      As msg_id
                            , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                        FROM #tbl_msg_master t
                        WHERE (msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_NEW_HIRE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = ''
                            , @p_msg_p1             = ''
                            , @p_msg_p2             = ''
                            , @p_msg_desc           = 'NIS number is blank - defaulting to 99999'
                            , @p_activity_date      = @p_activity_date

                        SET  @national_id = '99999'
                    END
                ELSE
                    IF (@national_id <> '99999')
                        BEGIN
                            IF  EXISTS (
                                        SELECT *
                                        FROM DBShrpn.dbo.individual_personal e
                                        WHERE e.national_id_1 = @national_id
                                    )
                                BEGIN

                                    SET @msg_id = 'U00006'
                                    SET @v_step_position = 'Begin ' + @msg_id

                                    UPDATE DBShrpn.dbo.ghr_employee_events_aud
                                    SET activity_status = @v_ACTIVITY_STATUS_WARNING
                                    WHERE activity_date = @p_activity_date
                                    AND emp_id  = @emp_id
                                    AND event_id  = @v_EVENT_ID_NEW_HIRE

                                    INSERT INTO #tbl_ghr_msg
                                    SELECT @msg_id      As msg_id
                                        , REPLACE(REPLACE(t.msg_text, '@1', @emp_id), '@2', @national_id) AS msg_desc
                                    FROM #tbl_msg_master t
                                    WHERE (msg_id = @msg_id)

                                    -- Historical Message for reporting purpose
                                    EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                                        @p_msg_id             = @msg_id
                                        , @p_event_id           = @v_EVENT_ID_NEW_HIRE
                                        , @p_emp_id             = @emp_id
                                        , @p_eff_date           = @eff_date
                                        , @p_pay_element_id     = ''
                                        , @p_msg_p1             = @national_id
                                        , @p_msg_p2             = ''
                                        , @p_msg_desc           = 'NIS number already in use - defaulting to 99999'
                                        , @p_activity_date      = @p_activity_date

                                    SET @national_id = '99999'
                                END
                        END

                ---------------------------------------------------------------------------
                -- Check to see if the national id is blank
                ---------------------------------------------------------------------------
                IF  (@national_id = '' or @national_id = NULL)
                    BEGIN

                        SET @msg_id = 'U00007'
                        SET @v_step_position = 'Begin ' + @msg_id

                        UPDATE DBShrpn.dbo.ghr_employee_events_aud
                        SET activity_status = @v_ACTIVITY_STATUS_WARNING
                        WHERE activity_date = @p_activity_date
                        AND emp_id  = @emp_id
                        AND event_id  = @v_EVENT_ID_NEW_HIRE

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id     As msg_id
                            , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                        FROM #tbl_msg_master t
                        WHERE (msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_NEW_HIRE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = ''
                            , @p_msg_p1             = ''
                            , @p_msg_p2             = ''
                            , @p_msg_desc           = 'NIS number is blank - defaulting to 99999'
                            , @p_activity_date      = @p_activity_date

                        SET @national_id = '99999'
                    END


                ---------------------------------------------------------------------------
                -- Check to see if pay group id exists
                ---------------------------------------------------------------------------
                SET @msg_id = 'U00020'
                SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

                IF NOT EXISTS(
                            SELECT *
                            FROM DBShrpn.dbo.pay_group
                            WHERE pay_group_id = @pay_group_id
                            )
                    BEGIN

                        UPDATE DBShrpn.dbo.ghr_employee_events_aud
                        SET activity_status = @v_ACTIVITY_STATUS_BAD
                        WHERE activity_date = @p_activity_date
                        AND emp_id  = @emp_id
                        AND event_id  = @v_EVENT_ID_NEW_HIRE

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id     As msg_id
                            , REPLACE(REPLACE(t.msg_text, '@1', @pay_group_id), '@2', @emp_id) AS msg_desc
                        FROM #tbl_msg_master t
                        WHERE (msg_id = @msg_id)


                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_NEW_HIRE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = ''
                            , @p_msg_p1             = @pay_group_id
                            , @p_msg_p2             = ''
                            , @p_msg_desc           = 'Invalid pay group id'
                            , @p_activity_date      = @p_activity_date


                        SET @pay_group_id = ' '

                        SET  @w_fatal_error = 1

                    END


                ---------------------------------------------------------------------------
                -- Validate Employee Employment Type Code
                ---------------------------------------------------------------------------
                -- Translate HCM code to SS - conversions stored in code table
                SELECT @w_conv_employment_type_code = code_value
                FROM DBShrpn.dbo.code_entry_policy
                WHERE (code_tbl_id = '50001')
                AND (short_descp = @employment_type_code)

                IF (@@ROWCOUNT = 0)
                    BEGIN

                        -- Warning only - no record found - Will not skip record
                        SET @msg_id = 'U00100'
                        SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

                        -- Use default employee type value
                        --SET @w_conv_employment_type_code = 'XXXXX'

                        UPDATE DBShrpn.dbo.ghr_employee_events_aud
                        SET activity_status = @v_ACTIVITY_STATUS_WARNING
                        WHERE activity_date = @p_activity_date
                        AND emp_id  = @emp_id
                        AND event_id  = @v_EVENT_ID_NEW_HIRE

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id             As msg_id
                            , REPLACE(REPLACE(t.msg_text, '@1', @employment_type_code), '@2', @emp_id) AS msg_desc
                        FROM #tbl_msg_master t
                        WHERE (msg_id = @msg_id)

                        SET @w_msg_text = RTRIM(@employment_type_code) + ' (' + RTRIM(@w_conv_employment_type_code) + ')'

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_NEW_HIRE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = ''
                            , @p_msg_p1             = @w_msg_text
                            , @p_msg_p2             = ''
                            , @p_msg_desc           = 'Invalid Employment Type Code'
                            , @p_activity_date      = @p_activity_date

                    END
                ELSE
                    IF NOT EXISTS(
                                SELECT 1
                                FROM DBShrpn.dbo.code_entry_policy
                                WHERE (code_tbl_id = '10093')     -- Employment Types
                                    AND (code_value = @w_conv_employment_type_code)
                                )
                        BEGIN
                            -- Converted employee type is not correct
                            -- Warning only - no record found - Will not skip record
                            SET @msg_id = 'U00100'
                            SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

                            -- Use default employee type value
                            --SET @w_conv_employment_type_code = 'XXXXX'

                            UPDATE DBShrpn.dbo.ghr_employee_events_aud
                            SET activity_status = @v_ACTIVITY_STATUS_WARNING
                            WHERE activity_date = @p_activity_date
                            AND emp_id  = @emp_id
                            AND event_id  = @v_EVENT_ID_NEW_HIRE

                            INSERT INTO #tbl_ghr_msg
                            SELECT @msg_id             As msg_id
                                    , REPLACE(REPLACE(t.msg_text, '@1', @w_conv_employment_type_code), '@2', @emp_id) AS msg_desc
                            FROM #tbl_msg_master t
                            WHERE (msg_id = @msg_id)

                            SET @w_msg_text = RTRIM(@employment_type_code) + ' (' + RTRIM(@w_conv_employment_type_code) + ')'

                            -- Historical Message for reporting purpose
                            EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                                @p_msg_id             = @msg_id
                                , @p_event_id           = @v_EVENT_ID_NEW_HIRE
                                , @p_emp_id             = @emp_id
                                , @p_eff_date           = @eff_date
                                , @p_pay_element_id     = ''
                                , @p_msg_p1             = @w_msg_text
                                , @p_msg_p2             = ''
                                , @p_msg_desc           = 'Invalid Employment Type Code'
                                , @p_activity_date      = @p_activity_date

                        END


                ---------------------------------------------------------------------------
                -- Skip record if failed validation
                ---------------------------------------------------------------------------
                IF (@w_fatal_error = 1)
                    GOTO BYPASS_EMPLOYEE


                ---------------------------------------------------------------------------
                -- Lookup tax entity
                ---------------------------------------------------------------------------
                SET @v_step_position = 'Lookup Tax Entity'
                SELECT @w_tax_entity_id = tax_entity_id
                FROM DBShrpn.dbo.empl_tax_entity
                WHERE (empl_id = @empl_id)


                ---------------------------------------------------------------------------
                -- Lookup next individual id
                ---------------------------------------------------------------------------
                SET @v_step_position = 'Lookup Individual ID'

                -- Needed for proc usp_ins_hemp
                SELECT @ind_idx = CONVERT(char(10),gen_indiv_id_last_nbr + 1)
                FROM DBSentp.dbo.entp_human_resources_plcy  with (holdlock)

    --select @ind_idx as ind_idx

                -- Set next individual id
                UPDATE DBSentp.dbo.entp_human_resources_plcy
                SET gen_indiv_id_last_nbr = CONVERT(float, @ind_idx)
                WHERE (display_name_format = @v_DISPLAY_NAME_FORMAT)    -- Unique value for client

                -- Derive employee display name
                SET @w_emp_display_name = RTRIM(@last_name) + ', ' + RTRIM(@first_name)



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
                SELECT @pay_frequency_code = pay_frequency_code
                    , @annualizing_factor = annualizing_factor
                FROM DBShrpn.dbo.pay_group
                WHERE pay_group_id = @pay_group_id
                */

        /*  -- Disabling Salary Input for GOSL -- CJP 7/17/2025

                IF (@pay_frequency_code = 'MONTH')
                    IF (@pay_group_id = 'MONTHLY2')
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
                SET @v_step_position = 'Execute DBShrpn.dbo.usp_ins_hemp'

                EXEC DBShrpn.dbo.usp_ins_hemp
                    @p_employer_id                       = @empl_id
                    , @p_employee_id                       = @emp_id
                    , @p_individual_id                     = @ind_idx
                    , @p_original_hire_date                = @eff_date
                    , @p_first_name                        = @first_name
                    , @p_first_middle_name                 = @first_middle_name
                    , @p_last_name                         = @last_name
                    , @p_preferred_name                    = @w_preferred_name
                    , @p_name_suffix                       = @w_name_suffix
                    , @p_emp_display_name                  = @w_emp_display_name
                    , @p_birth_date                        = @w_birth_date
                    , @p_sex_code                          = @w_sex_code
                    , @p_marital_status_code_1             = @w_marital_status_code_1
                    , @p_national_id_1_type_code           = @national_id_type_code
                    , @p_national_id_1                     = @national_id
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
                    , @p_organization_chart_name           = @organization_chart_name
                    , @p_organization_unit_name            = @organization_unit_name
                    , @p_emp_status_classn_code            = @emp_status_classn_code
                    , @p_active_reason_code                = @w_active_reason_code
                    , @p_employment_type_code              = @w_conv_employment_type_code    --@employment_type_code
                    , @p_professional_cat_code             = @w_professional_cat_code
                    , @p_labor_grp_code                    = @labor_grp_code
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
                    , @p_time_reporting_meth_code          = @time_reporting_meth_code
                    , @p_pay_group_id                      = @pay_group_id
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
                    , @p_user_text_2                       = @position_title     -- CJP 7/8/2025 DBShrpn..emp_assignment.user_text_2     @w_user_text_2
                    , @p_inc_tax_calc_method               = @w_inc_tax_calc_method
                    , @p_ei_status_code                    = @w_ei_status_code
                    , @p_ppip_status_code                  = @w_ppip_status_code
                    , @p_fed_pp_stat_code                  = @w_fed_pp_stat_code
                    , @p_provincial_pp_stat_code           = @w_provincial_pp_stat_code
                    , @p_income_tax_stat_code              = @w_income_tax_stat_code
                    , @p_pit_stat_code                     = @w_pit_stat_code
                    , @p_pay_element_ctrl_grp              = @pay_element_ctrl_grp_id
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
                    , @p_organization_group_id             = @organization_group_id
                    , @p_wage_plan_code                    = @w_wage_plan_code
                    , @p_emp_health_insurance_cvg_cd       = @w_emp_health_insurance_cvg_cd
                    , @p_tax_auth_type_code                = @w_tax_auth_type_code
                    , @p_tax_auth_type_code_2              = @w_tax_auth_type_code_2
                    , @p_tax_auth_type_code_3              = @w_tax_auth_type_code_3
                    , @p_tax_auth_type_code_4              = @w_tax_auth_type_code_4
                    , @p_tax_auth_type_code_5              = @w_tax_auth_type_code_5
                    , @p_reg_reporting_unit_code           = @w_reg_reporting_unit_code
                    , @p_emp_workers_comp_cvg_cd           = @w_emp_workers_comp_cvg_cd


                ---------------------------------------------------------------------------
                -- Lookup Employee Employment Details
                ---------------------------------------------------------------------------
                SET @v_step_position = 'Lookup emp_employment'

                SELECT @ee_emp_id = eempl.emp_id
                    , @ee_eff_date = eempl.eff_date
                    , @ee_next_eff_date = eempl.next_eff_date
                    , @ee_prior_eff_date = eempl.prior_eff_date
                FROM DBShrpn.dbo.uvu_emp_employment_most_rec eempl
                WHERE (emp_id = @emp_id)


                -- Make sure new record end date = end of time date
                SET @v_step_position = 'Set emp_employment end date'

                IF (@ee_next_eff_date <> @v_END_OF_TIME_DATE)
                    UPDATE DBShrpn.dbo.emp_employment
                    SET  next_eff_date = @v_END_OF_TIME_DATE
                    WHERE (emp_id = @ee_emp_id)
                    AND (eff_date = @ee_eff_date)


                SELECT @individual_id = individual_id
                FROM DBShrpn.dbo.employee
                WHERE emp_id = @emp_id


                ---------------------------------------------------------------------------
                -- GOSL update NIC and Tax Code
                ---------------------------------------------------------------------------
                -- CJP 7/7/2025
                SET @v_step_position = 'Update NIC/Tax Code'

                UPDATE DBShrpn.dbo.individual_personal
                SET user_ind_1 = @nic_flag
                , user_ind_2 = @tax_flag
                WHERE (individual_id = @individual_id)

                ---------------------------------------------------------------------------
                -- GOSL update Tax Ceiling Amount
                ---------------------------------------------------------------------------
                SET @v_step_position = 'Update Tax Ceiling'

                UPDATE DBShrpn.dbo.employee
                SET user_monetary_amt_1 = @tax_ceiling_amt
                WHERE (emp_id = @emp_id)

            END TRY
            BEGIN CATCH

                SELECT @ErrorNumber   = CAST(ERROR_NUMBER() AS varchar(10))
                    , @ErrorMessage  = @v_step_position + ' - ' + LEFT(ERROR_MESSAGE(), 1024)
                    , @ErrorSeverity = ERROR_SEVERITY()
                    , @ErrorState    = ERROR_STATE()

                IF (@@TRANCOUNT > 0)
                    ROLLBACK TRAN

                BEGIN TRAN

                -- Log error
                EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                      @p_msg_id             = @ErrorNumber
                    , @p_event_id           = @v_EVENT_ID_NEW_HIRE
                    , @p_emp_id             = @emp_id
                    , @p_eff_date           = @eff_date
                    , @p_pay_element_id     = ''
                    , @p_msg_p1             = ''
                    , @p_msg_p2             = ''
                    , @p_msg_desc           = @ErrorMessage
                    , @p_activity_date      = @p_activity_date

            END CATCH

BYPASS_EMPLOYEE:
            -- committ records before next record in order to maintain log entries
            IF (@@TRANCOUNT > 0)
                COMMIT TRAN

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

        -- commit after every record
        IF (@@TRANCOUNT > 0)
            COMMIT TRAN


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
        WHERE (event_id = @v_EVENT_ID_NEW_HIRE)

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

        SET @w_msg_text = REPLACE(@w_msg_text, '@1', @maxx)

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

        SELECT @ErrorNumber   = CAST(ERROR_NUMBER() AS varchar(10))
             , @ErrorMessage  = @v_step_position + ' - ' + LEFT(ERROR_MESSAGE(), 1024)
             , @ErrorSeverity = ERROR_SEVERITY()
             , @ErrorState    = ERROR_STATE()
             , @p_status      = -1

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

        -- Historical Message for reporting purpose
        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
              @p_msg_id             = @ErrorNumber
            , @p_event_id           = @v_EVENT_ID_NEW_HIRE
            , @p_emp_id             = @emp_id
            , @p_eff_date           = @eff_date
            , @p_pay_element_id     = ''
            , @p_msg_p1             = ''
            , @p_msg_p2             = ''
            , @p_msg_desc           = @ErrorMessage
            , @p_activity_date      = @p_activity_date


        -- send error back to calling procedure
        RAISERROR(
                   @ErrorMessage
                 , @ErrorSeverity
                 , @ErrorState
                 );

    END CATCH


    -- Cleanup temp tables
    DROP TABLE #tbl_ghr_msg
    DROP TABLE #tbl_msg_master


END
GO

ALTER AUTHORIZATION ON dbo.usp_ins_new_hire TO  SCHEMA OWNER
GO

IF OBJECT_ID(N'dbo.usp_ins_new_hire', N'P') IS NOT NULL
    PRINT N'<<< CREATED PROCEDURE dbo.usp_ins_new_hire >>>'
ELSE
    PRINT N'<<< FAILED CREATING PROCEDURE dbo.usp_ins_new_hire >>>'
GO
