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

/*************************************************************************************
    SP Name:       usp_ins_new_hire

    Description:


    Parameters:
        @p_user_id       =  User ID (i.e. 'DBS')
        @p_batchname     = Job Scheduler Batch Name (i.e. 'GHR')
        @p_qualifier     = Job Scheduler Qualifier (i.e. 'INTERFACES')
        @p_activity_date = Current System Date


    Example:
        EXEC DBShrpn.dbo.usp_ins_new_hire
              @p_user_id          = @w_userid
            , @p_batchname       = @v_PSC_BATCHNAME
            , @p_qualifier       = @w_PSC_QUALIFIER
            , @p_activity_date   = @w_activity_date


   Revision history:
   version  date        developer   SCR         description
   -------  ----------  ---------   -----       ------------------------------------
   1.0.00   08/27/2025  CJP                     - Cloned from GOG version

************************************************************************************/

CREATE PROCEDURE dbo.usp_ins_new_hire
    (
      @p_user_id              varchar(30)
    , @p_batchname            varchar(08)
    , @p_qualifier            varchar(30)
    , @p_activity_date        datetime
    )
AS

BEGIN

    SET NOCOUNT ON

    DECLARE @v_step_position                        varchar(255)        = 'Begin usp_ins_new_hire'

    DECLARE @v_date_time_stamp                      datetime            = GETDATE()
    DECLARE @v_DISPLAY_NAME_FORMAT                  char(33)            = 'LNMCOMSFXFNMFMNSMI'  -- Unique to client
    DECLARE @v_END_OF_TIME_DATE                     datetime            = '29991231'
    DECLARE @v_BAD_DATE_INDICATOR                   datetime            = '99991231'    -- value used to populate datetime column with value from HCM that is not a valid date after conversion

    DECLARE @v_EMPTY_SPACE                          char(01)            = ''

    DECLARE @v_EVENT_ID_NEW_HIRE                    char(2)             = '01'

    DECLARE @v_ACTIVITY_STATUS_GOOD                 char(2)             = '00'
    DECLARE @v_ACTIVITY_STATUS_WARNING              char(2)             = '01'
    DECLARE @v_ACTIVITY_STATUS_BAD                  char(2)             = '02'

    DECLARE @ErrorNumber                            varchar(10)
    DECLARE @ErrorMessage                           nvarchar(4000)
    DECLARE @ErrorSeverity                          int
    DECLARE @ErrorState                             int

    DECLARE @v_ret_val                              int                 = 0
    DECLARE @w_msg_text                             varchar(255)
    DECLARE @w_msg_text_2                           varchar(255)
    DECLARE @w_msg_text_3                           varchar(255)
    DECLARE @w_severity_cd                          tinyint
    DECLARE @w_fatal_error                          bit     = 0         --char(01)
    DECLARE @w_trace_sw                             char(01)

    DECLARE @ee_eff_date                            datetime
    DECLARE @ee_next_eff_date                       datetime
    DECLARE @ee_prior_eff_date                      datetime

    DECLARE @maxx                                   varchar(06)
    DECLARE @ind_idx                                char(10)
    DECLARE @annual_salary                          money
    DECLARE @tax_entity_id                          char(10)
    DECLARE @msg_id                                 char(10)
    DECLARE @individual_id                          char(10)

    DECLARE @w_preferred_name                       char(25)        = @v_EMPTY_SPACE
    DECLARE @w_name_suffix                          char(10)        = @v_EMPTY_SPACE
    DECLARE @w_emp_display_name                     char(45)        = @v_EMPTY_SPACE
    DECLARE @w_marital_status_code_1                char(05)        = @v_EMPTY_SPACE
    DECLARE @w_addr_1_type_code                     char(05)        = '1'   -- Home
    DECLARE @w_assigned_to_code                     char(01)        = 'P'
    DECLARE @w_job_or_pos_id                        char(10)        = @v_EMPTY_SPACE
    DECLARE @w_organization_chart_name              char(64)        = 'HRGOSL'  -- not currently being used
    DECLARE @w_active_reason_code                   char(05)        = @v_EMPTY_SPACE
    DECLARE @w_professional_cat_code                char(05)        = @v_EMPTY_SPACE
    DECLARE @w_non_employee_indicator               char(01)        = 'N'
    DECLARE @w_excluded_from_payroll_ind            char(01)        = 'N'
    DECLARE @w_pensioner_indicator                  char(01)        = 'N'
    DECLARE @w_provided_i_9_ind                     char(01)        = 'N'
    DECLARE @w_base_rate_tbl_id                     char(10)        = @v_EMPTY_SPACE
    DECLARE @w_base_rate_tbl_entry_code             char(08)        = @v_EMPTY_SPACE
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
    DECLARE @w_work_shift_code                      char(05)        = @v_EMPTY_SPACE
    DECLARE @w_tax_entity_id                        char(10)        = @v_EMPTY_SPACE
    DECLARE @w_clock_nbr                            char(10)        = @v_EMPTY_SPACE
    DECLARE @w_prim_disbursal_loc_code              char(10)        = @v_EMPTY_SPACE
    DECLARE @w_alt_disbursal_loc_code               char(10)        = @v_EMPTY_SPACE
    DECLARE @w_tax_marital_status_code              char(01)        = '1'
    DECLARE @w_fui_status_code                      char(01)        = '2'
    DECLARE @w_oasdi_status_code                    char(01)        = '2'
    DECLARE @w_medicare_status_code                 char(01)        = '2'
    DECLARE @w_income_tax_nbr_of_exemps             smallint        = 0
    DECLARE @w_tax_authority_id                     char(10)        = @v_EMPTY_SPACE
    DECLARE @w_work_resident_status_code            char(01)        = @v_EMPTY_SPACE
    DECLARE @w_income_tax_calc_meth_cd              char(02)        = @v_EMPTY_SPACE
    DECLARE @w_tax_authority_2                      char(10)        = @v_EMPTY_SPACE
    DECLARE @w_tax_authority_3                      char(10)        = @v_EMPTY_SPACE
    DECLARE @w_tax_authority_4                      char(10)        = @v_EMPTY_SPACE
    DECLARE @w_tax_authority_5                      char(10)        = @v_EMPTY_SPACE
    DECLARE @w_work_resident_status_code_2          char(01)        = @v_EMPTY_SPACE
    DECLARE @w_work_resident_status_code_3          char(01)        = @v_EMPTY_SPACE
    DECLARE @w_work_resident_status_code_4          char(01)        = @v_EMPTY_SPACE
    DECLARE @w_work_resident_status_code_5          char(01)        = @v_EMPTY_SPACE
    DECLARE @w_user_amt_1                           float           = 0
    DECLARE @w_user_amt_2                           float           = 0
    DECLARE @w_user_code_1                          char(05)        = @v_EMPTY_SPACE
    DECLARE @w_user_code_2                          char(05)        = @v_EMPTY_SPACE
    DECLARE @w_user_date_1                          datetime        = @v_END_OF_TIME_DATE
    DECLARE @w_user_date_2                          datetime        = @v_END_OF_TIME_DATE
    DECLARE @w_user_ind_1                           char(01)        = @v_EMPTY_SPACE
    DECLARE @w_user_ind_2                           char(01)        = @v_EMPTY_SPACE
    DECLARE @w_user_monetary_amt_1                  money           = 0
    DECLARE @w_user_monetary_amt_2                  money           = 0
    DECLARE @w_user_monetary_curr_code              char(03)        = 'XCD'
    DECLARE @w_user_text_1                          char(50)        = @v_EMPTY_SPACE
    DECLARE @w_user_text_2                          char(50)        = @v_EMPTY_SPACE
    DECLARE @w_inc_tax_calc_method                  char(02)        = '2'
    DECLARE @w_ei_status_code                       char(01)        = '2'
    DECLARE @w_ppip_status_code                     char(01)        = '1'
    DECLARE @w_fed_pp_stat_code                     char(01)        = '2'
    DECLARE @w_provincial_pp_stat_code              char(01)        = '1'
    DECLARE @w_income_tax_stat_code                 char(01)        = '2'
    DECLARE @w_pit_stat_code                        char(01)        = '1'
    DECLARE @w_pay_element_ctrl_grp                 char(10)        = @v_EMPTY_SPACE
    DECLARE @w_emp_workers_comp_class               char(01)        = @v_EMPTY_SPACE
    DECLARE @w_empl_addr_fmt_code                   char(06)        = 'GN2'
    DECLARE @w_empl_phone_fmt_code                  char(06)        = 'L34'
    DECLARE @w_empl_phone_delimiter                 char(01)        = '-'
    DECLARE @w_empl_recruitment_zone_code           char(05)        = @v_EMPTY_SPACE
    DECLARE @w_empl_cma_code                        char(02)        = @v_EMPTY_SPACE
    DECLARE @w_empl_industry_sector_code            char(05)        = @v_EMPTY_SPACE
    DECLARE @w_empl_province_terr_code              char(02)        = @v_EMPTY_SPACE
    DECLARE @w_eeo_4_agency_function_code           char(02)        = '99'
    DECLARE @w_eeo_establishment_id                 char(8)         = '0714'
    DECLARE @w_assignment_end_date                  datetime        = @v_END_OF_TIME_DATE
    DECLARE @w_location_code                        char(10)        = @v_EMPTY_SPACE
    DECLARE @w_salary_structure_id                  char(10)        = @v_EMPTY_SPACE
    DECLARE @w_salary_incr_guideline_id             char(10)        = @v_EMPTY_SPACE
    DECLARE @w_pay_grade_code                       char(06)        = 'E40'
    DECLARE @w_job_evaluation_points_nbr            smallint        = 0
    DECLARE @w_salary_step_nbr                      smallint        = 0
    DECLARE @w_employer_taxing_ctry_code            char(02)        = 'LC'--'Gd'
    DECLARE @w_wage_plan_code                       char(02)        = @v_EMPTY_SPACE
    DECLARE @w_emp_health_insurance_cvg_cd          char(02)        = @v_EMPTY_SPACE
    DECLARE @w_tax_auth_type_code                   char(01)        = @v_EMPTY_SPACE
    DECLARE @w_tax_auth_type_code_2                 char(01)        = @v_EMPTY_SPACE
    DECLARE @w_tax_auth_type_code_3                 char(01)        = @v_EMPTY_SPACE
    DECLARE @w_tax_auth_type_code_4                 char(01)        = @v_EMPTY_SPACE
    DECLARE @w_tax_auth_type_code_5                 char(01)        = @v_EMPTY_SPACE
    DECLARE @w_reg_reporting_unit_code              char(10)        = @v_EMPTY_SPACE
    DECLARE @w_emp_workers_comp_cvg_cd              char(01)        = @v_EMPTY_SPACE
    DECLARE @w_conv_employment_type_code            char(05)


    -- This section declares the interface column variables
    DECLARE @aud_id                                 int             = 0
    DECLARE @emp_id                                 char(15)        = @v_EMPTY_SPACE
    DECLARE @eff_date                               datetime
    DECLARE @first_name                             char(25)
    DECLARE @first_middle_name                      char(25)
    DECLARE @last_name                              char(30)
    DECLARE @empl_id                                char(10)
    DECLARE @national_id_type_code                  char(05)
    DECLARE @national_id                            char(20)
    DECLARE @organization_group_id                  int
    DECLARE @organization_chart_name                varchar(64)
    DECLARE @organization_unit_name                 varchar(240)
    DECLARE @emp_status_classn_code                 char(02)
    DECLARE @position_title                         char(50)        -- DBShrpn..emp_assignment.user_text_2
    DECLARE @employment_type_code                   varchar(70)     -- increased size to 70 from 5
    DECLARE @pay_rate                               money
    DECLARE @begin_date                             datetime
    DECLARE @end_date                               datetime
    DECLARE @pay_status_code                        char(01)
    DECLARE @pay_group_id                           char(10)
    DECLARE @pay_element_ctrl_grp_id                char(10)
    DECLARE @time_reporting_meth_code               char(01)
    DECLARE @employment_info_chg_reason_cd          char(05)
    DECLARE @emp_location_code                      char(10)
    DECLARE @emp_status_code                        char(02)
    DECLARE @reason_code                            char(02)
    DECLARE @emp_expected_return_date               char(10)
    DECLARE @pay_through_date                       datetime
    DECLARE @emp_death_date                         datetime
    DECLARE @consider_for_rehire_ind                char(01)
    DECLARE @pay_element_id                         char(10)
    DECLARE @emp_calculation                        money
    DECLARE @tax_flag                               char(1)         -- individual_personal.ind_2
    DECLARE @nic_flag                               char(1)         -- individual_personal.ind_1
    DECLARE @tax_ceiling_amt                        money           -- employee.user_monetary_amt_1
    DECLARE @labor_grp_code                         char(5)         -- DBShrpn..emp_employment.labor_grp_code
    DECLARE @file_source                            char(50)        -- 'SS VENUS' or 'SS GANYMEDE'

    DECLARE @annual_hrs_per_fte                     money
    DECLARE @annual_rate                            money
    DECLARE @birth_date                             datetime
    DECLARE @gender                                 varchar(255)
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



    CREATE TABLE #tbl_ghr_msg
        (
          msg_id                                    char(15)            NOT NULL
        , msg_desc                                  varchar(255)        NOT NULL
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
             , t.organization_chart_name
             , t.organization_unit_name
             , t.emp_status_classn_code
             , LEFT(t.position_title, 50) AS position_title
             , t.employment_type_code
             , t.annual_salary_amt
             , t.pay_group_id
             , t.pay_element_ctrl_grp_id
             , t.time_reporting_meth_code
             , t.emp_status_code
             , t.tax_flag
             , t.nic_flag
             , t.tax_ceiling_amt
             , LEFT(t.labor_grp_code, 5) AS labor_grp_code
             , t.file_source
             , t.annual_hrs_per_fte
             , t.annual_rate
             , t.birth_date
             , t.gender
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
             , t.job_or_pos_id
        FROM #ghr_employee_events_temp t
        WHERE (event_id = @v_EVENT_ID_NEW_HIRE)

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
            , @pay_group_id
            , @pay_element_ctrl_grp_id
            , @time_reporting_meth_code
            , @emp_status_code
            , @tax_flag
            , @nic_flag
            , @tax_ceiling_amt
            , @labor_grp_code
            , @file_source
            , @annual_hrs_per_fte
            , @annual_rate
            , @birth_date
            , @gender
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
            , @w_job_or_pos_id


        WHILE (@@FETCH_STATUS = 0)
        BEGIN

            BEGIN TRY

                SET @v_step_position = 'Begin crsrHR While Loop'

                SET @w_fatal_error = 0

                BEGIN TRAN


                ---------------------------------------------------------------------------
                ---------------------------------------------------------------------------
                -- This section will validate the interface data
                ---------------------------------------------------------------------------
                ---------------------------------------------------------------------------
                SET @v_step_position = 'Validation'

                ---------------------------------------------------------------------------
                -- Check to see if the employee id already exists
                ---------------------------------------------------------------------------
                IF  EXISTS (
                            SELECT 1
                            FROM DBShrpn.dbo.employee
                            WHERE emp_id = @emp_id
                        )
                    BEGIN

                        SET @msg_id = 'U00003'
                        SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id As msg_id
                            , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master t     --#tbl_msg_master t
                        WHERE (t.msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_NEW_HIRE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @v_EMPTY_SPACE
                            , @p_msg_p1             = @v_EMPTY_SPACE
                            , @p_msg_p2             = @v_EMPTY_SPACE
                            , @p_msg_desc           = 'Employee id already exists'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id

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

                                INSERT INTO #tbl_ghr_msg
                                SELECT @msg_id         As msg_id
                                    , REPLACE(REPLACE(t.msg_text, '@1', @empl_id), '@2', @emp_id) AS msg_desc
                                FROM DBSCOMMON.dbo.message_master t     --#tbl_msg_master t
                                WHERE (t.msg_id = @msg_id)


                                -- Historical Message for reporting purpose
                                EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                                    @p_msg_id             = @msg_id
                                    , @p_event_id           = @v_EVENT_ID_NEW_HIRE
                                    , @p_emp_id             = @emp_id
                                    , @p_eff_date           = @eff_date
                                    , @p_pay_element_id     = @v_EMPTY_SPACE
                                    , @p_msg_p1             = @v_EMPTY_SPACE
                                    , @p_msg_p2             = @v_EMPTY_SPACE
                                    , @p_msg_desc           = 'Invalid Employer id - defaulting to 99999'
                                    , @p_activity_status    = @v_ACTIVITY_STATUS_WARNING
                                    , @p_activity_date      = @p_activity_date
                                    , @p_audit_id           = @aud_id

                                SELECT @empl_id = '99999'

                            END
                    END

                ---------------------------------------------------------------------------
                -- Check to see if the national id is blank
                ---------------------------------------------------------------------------
                IF  (@national_id = @v_EMPTY_SPACE) OR
                    (@national_id = NULL)
                    BEGIN

                        SET @msg_id = 'U00007'
                        SET @v_step_position = 'Begin ' + @msg_id

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id     As msg_id
                            , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master t     --#tbl_msg_master t
                        WHERE (t.msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_NEW_HIRE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @v_EMPTY_SPACE
                            , @p_msg_p1             = @v_EMPTY_SPACE
                            , @p_msg_p2             = @v_EMPTY_SPACE
                            , @p_msg_desc           = 'National ID is blank - defaulting to '''''
                            , @p_activity_status    = @v_ACTIVITY_STATUS_WARNING
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id

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

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id     As msg_id
                            , REPLACE(REPLACE(t.msg_text, '@1', @pay_group_id), '@2', @emp_id) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master t     --#tbl_msg_master t
                        WHERE (t.msg_id = @msg_id)


                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_NEW_HIRE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @v_EMPTY_SPACE
                            , @p_msg_p1             = @pay_group_id
                            , @p_msg_p2             = @v_EMPTY_SPACE
                            , @p_msg_desc           = 'Invalid pay group id'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id


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

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id As msg_id
                            , REPLACE(REPLACE(t.msg_text, '@1', @employment_type_code), '@2', @emp_id) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master t     --#tbl_msg_master t
                        WHERE (t.msg_id = @msg_id)

                        SET @w_msg_text = RTRIM(@employment_type_code) + ' (' + RTRIM(@w_conv_employment_type_code) + ')'

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_NEW_HIRE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @v_EMPTY_SPACE
                            , @p_msg_p1             = @w_msg_text
                            , @p_msg_p2             = @v_EMPTY_SPACE
                            , @p_msg_desc           = 'Invalid Employment Type Code'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_WARNING
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id

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

                            INSERT INTO #tbl_ghr_msg
                            SELECT @msg_id             As msg_id
                                    , REPLACE(REPLACE(t.msg_text, '@1', @w_conv_employment_type_code), '@2', @emp_id) AS msg_desc
                            FROM DBSCOMMON.dbo.message_master t     --#tbl_msg_master t
                            WHERE (t.msg_id = @msg_id)

                            SET @w_msg_text = RTRIM(@employment_type_code) + ' (' + RTRIM(@w_conv_employment_type_code) + ')'

                            -- Historical Message for reporting purpose
                            EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                                @p_msg_id             = @msg_id
                                , @p_event_id           = @v_EVENT_ID_NEW_HIRE
                                , @p_emp_id             = @emp_id
                                , @p_eff_date           = @eff_date
                                , @p_pay_element_id     = @v_EMPTY_SPACE
                                , @p_msg_p1             = @w_msg_text
                                , @p_msg_p2             = @v_EMPTY_SPACE
                                , @p_msg_desc           = 'Invalid Employment Type Code'
                                , @p_activity_status    = @v_ACTIVITY_STATUS_WARNING
                                , @p_activity_date      = @p_activity_date
                                , @p_audit_id           = @aud_id

                        END


                ---------------------------------------------------------------------------
                -- Validate Salary Amount
                ---------------------------------------------------------------------------
                SET @v_step_position = 'Validate Annual Salary (PayRate)'

                IF (@pay_rate = 0.00)
                    BEGIN

                        SET @msg_id = 'U00041'
                        SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id AS msg_id
                            , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master t
                        WHERE (t.msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_NEW_HIRE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @v_EMPTY_SPACE
                            , @p_msg_p1             = @pay_rate
                            , @p_msg_p2             = @v_EMPTY_SPACE
                            , @p_msg_desc           = 'Annual salary amount (PayRate) cannot be zero.'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id

                        SET @w_fatal_error = 1

                    END



                ---------------------------------------------------------------------------
                -- Validate Annual Hours Per FTE
                ---------------------------------------------------------------------------
                SET @v_step_position = 'Validate Annual Hours per FTE'

                IF (@annual_hrs_per_fte = 0.00)
                    BEGIN

                        SET @msg_id = 'U00124'
                        SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id AS msg_id
                            , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master t
                        WHERE (msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_NEW_HIRE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @v_EMPTY_SPACE
                            , @p_msg_p1             = @annual_hrs_per_fte
                            , @p_msg_p2             = @v_EMPTY_SPACE
                            , @p_msg_desc           = 'Invalid annual hours per FTE.'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id

                        SET @w_fatal_error = 1

                    END

                -- Log warning if annual hours are less than 2080
                IF (@annual_hrs_per_fte > 0.00) AND
                   (@annual_hrs_per_fte < 2080.00)
                    BEGIN

                        SET @msg_id = 'U00124'
                        SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id AS msg_id
                            , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master t
                        WHERE (msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_NEW_HIRE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @v_EMPTY_SPACE
                            , @p_msg_p1             = @annual_hrs_per_fte
                            , @p_msg_p2             = @v_EMPTY_SPACE
                            , @p_msg_desc           = 'Warning - annual hours per FTE less than 2080 hours.'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_WARNING
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id

                    END


                ---------------------------------------------------------------------------
                -- Validate Annual Rate
                ---------------------------------------------------------------------------
                SET @v_step_position = 'Validate Annual Rate'

                IF (@annual_rate = 0.00)
                    BEGIN

                        SET @msg_id = 'U00125'
                        SET @v_step_position = 'Validation - ' + RTRIM(@msg_id)

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id AS msg_id
                            , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master t
                        WHERE (msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_NEW_HIRE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @v_EMPTY_SPACE
                            , @p_msg_p1             = @annual_rate
                            , @p_msg_p2             = @v_EMPTY_SPACE
                            , @p_msg_desc           = 'Invalid annual hours per FTE.'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id

                        SET @w_fatal_error = 1

                    END


                ---------------------------------------------------------------------------
                -- Validate Effective Date
                ---------------------------------------------------------------------------
                IF (@eff_date = @v_BAD_DATE_INDICATOR)
                    BEGIN

                        SET @msg_id = 'U00102'  -- New code
                        SET @v_step_position = 'Validation Effective Date - ' + RTRIM(@msg_id)

                        INSERT INTO #tbl_ghr_msg
                        SELECT @msg_id AS msg_id
                            , REPLACE(REPLACE(REPLACE(t.msg_text, '@1', CONVERT(char(8), @eff_date, 112)), '@2', @emp_id), '@3', @v_EVENT_ID_NEW_HIRE) AS msg_desc
                        FROM DBSCOMMON.dbo.message_master t
                        WHERE (msg_id = @msg_id)

                        -- Historical Message for reporting purpose
                        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                            @p_msg_id             = @msg_id
                            , @p_event_id           = @v_EVENT_ID_NEW_HIRE
                            , @p_emp_id             = @emp_id
                            , @p_eff_date           = @eff_date
                            , @p_pay_element_id     = @v_EMPTY_SPACE
                            , @p_msg_p1             = @emp_calculation
                            , @p_msg_p2             = ''
                            , @p_msg_desc           = 'Invalid Effective Date'
                            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                            , @p_activity_date      = @p_activity_date
                            , @p_audit_id           = @aud_id

                        SET @w_fatal_error = 1

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
                -- Lookup Next individual id
                ---------------------------------------------------------------------------
                SET @v_step_position = 'Lookup Individual ID'

                -- Needed for proc usp_ins_hemp
                SELECT @ind_idx = CONVERT(char(10),gen_indiv_id_last_nbr + 1)
                FROM DBSentp.dbo.entp_human_resources_plcy  with (holdlock)
                WHERE (display_name_format = @v_DISPLAY_NAME_FORMAT)    -- Unique value for client

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
                SET @v_step_position = 'Configure New Hire Salary'


                ---------------------------------------------------------------------------
                -- Salary Setup
                ---------------------------------------------------------------------------
                -- Universally setup all associates as monthly; 8 hrs/day; 40 hrs/week
                -- Indicates that the associate is setup as annually
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
                    , @p_birth_date                        = @birth_date
                    , @p_sex_code                          = @gender
                    , @p_marital_status_code_1             = @w_marital_status_code_1
                    , @p_national_id_1_type_code           = @national_id_type_code
                    , @p_national_id_1                     = @national_id

                    , @p_addr_1_type_code                  = @w_addr_1_type_code
                    , @p_addr_1_fmt_code                   = @addr_fmt_code
                    , @p_addr_1_line_1                     = @addr_line_1
                    , @p_addr_1_line_2                     = @addr_line_2
                    , @p_addr_1_line_3                     = @v_EMPTY_SPACE
                    , @p_addr_1_line_4                     = @v_EMPTY_SPACE
                    , @p_addr_1_line_5                     = @v_EMPTY_SPACE
                    , @p_addr_1_street_or_pob_1            = @addr_line_3
                    , @p_addr_1_street_or_pob_2            = @addr_line_4
                    , @p_addr_1_street_or_pob_3            = @v_EMPTY_SPACE
                    , @p_addr_1_city_name                  = @city_name
                    , @p_addr_1_ctry_sub_entity_code       = @v_EMPTY_SPACE     -- @state_prov  -- Parrish Drop Down is not being used by St Lucia
                    , @p_addr_1_postal_code                = @postal_code
                    , @p_addr_1_country_code               = @country_code

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

                SELECT @ee_eff_date = eempl.eff_date
                    , @ee_next_eff_date = eempl.next_eff_date
                    , @ee_prior_eff_date = eempl.prior_eff_date
                FROM DBShrpn.dbo.uvu_emp_employment_most_rec eempl
                WHERE (emp_id = @emp_id)

                IF (@@ROWCOUNT = 0)
                -- New hire update failed
                BEGIN

                    SET @msg_id = 'U00126'
                    SET @v_step_position = 'Validation Effective Date - ' + RTRIM(@msg_id)

                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id AS msg_id
                        , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                    FROM DBSCOMMON.dbo.message_master t
                    WHERE (msg_id = @msg_id)

                    -- Historical Message for reporting purpose
                    EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                        @p_msg_id             = @msg_id
                        , @p_event_id           = @v_EVENT_ID_NEW_HIRE
                        , @p_emp_id             = @emp_id
                        , @p_eff_date           = @eff_date
                        , @p_pay_element_id     = @v_EMPTY_SPACE
                        , @p_msg_p1             = @emp_calculation
                        , @p_msg_p2             = ''
                        , @p_msg_desc           = 'New hire update failed.'
                        , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                        , @p_activity_date      = @p_activity_date
                        , @p_audit_id           = @aud_id

                END


                -- Make sure new record end date = end of time date
                SET @v_step_position = 'Set emp_employment end date'

                IF (@ee_next_eff_date <> @v_END_OF_TIME_DATE)
                    UPDATE DBShrpn.dbo.emp_employment
                    SET  next_eff_date = @v_END_OF_TIME_DATE
                    WHERE (emp_id = @emp_id)
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
                    , @p_event_id           = @v_EVENT_ID_NEW_HIRE
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
            -- Commit records before next record in order to maintain log entries
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
                , @pay_group_id
                , @pay_element_ctrl_grp_id
                , @time_reporting_meth_code
                , @emp_status_code
                , @tax_flag
                , @nic_flag
                , @tax_ceiling_amt
                , @labor_grp_code
                , @file_source
                , @annual_hrs_per_fte
                , @annual_rate
                , @birth_date
                , @gender
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
                , @w_job_or_pos_id

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
        -- Send notification of warning message U00001 -- Total Global HR New Hire: @1
        ---------------------------------------------------------------------------
        SET @msg_id = 'U00001'
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
        WHERE (event_id = @v_EVENT_ID_NEW_HIRE)

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
        -- Send notification of warning message U00003 - Total nbr of employees that already exist: @1
        ---------------------------------------------------------------------------
        SET @msg_id = 'U00003'
        SET @v_step_position = 'Log ' + @msg_id

        SELECT @msg_id        = msg_id
            , @w_msg_text    = msg_text
            , @w_msg_text_2  = msg_text_2
            , @w_msg_text_3  = msg_text_3
            , @w_severity_cd = severity_cd
        FROM DBSCOMMON.dbo.message_master
        WHERE (msg_id = @msg_id)

        -- Get total new hire records from HCM
        SELECT @maxx = CAST(COUNT(*) AS varchar(6))
        FROM #tbl_ghr_msg
        WHERE (msg_id = @msg_id)

        SET @w_msg_text = REPLACE(@w_msg_text, '@1', @maxx)

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
             , @v_ret_val     = -1

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
            , @p_eff_date           = @v_date_time_stamp
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
    DROP TABLE #tbl_ghr_msg

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
