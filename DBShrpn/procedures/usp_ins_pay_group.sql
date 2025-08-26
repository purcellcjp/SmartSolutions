USE DBShrpn
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'dbo.usp_ins_pay_group', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_ins_pay_group
    IF OBJECT_ID(N'dbo.usp_ins_pay_group') IS NOT NULL
        PRINT N'<<< FAILED DROPPING PROCEDURE dbo.usp_ins_pay_group >>>'
    ELSE
        PRINT N'<<< DROPPED PROCEDURE dbo.usp_ins_pay_group >>>'
END
GO

CREATE PROCEDURE dbo.usp_ins_pay_group
(
   @p_userid               varchar(30),
   @p_batchname            varchar(08),
   @p_qualifier            varchar(30),
    @p_activity_date        datetime,
    @p_user_id              varchar(30),
   @p_status            int         = 0 OUTPUT
)
AS


BEGIN

    SET NOCOUNT ON

    DECLARE @v_step_position                varchar(255)        = 'Begin Procedure'

    DECLARE @v_END_OF_TIME_DATE             datetime            = '29991231'

    DECLARE @v_EVENT_ID_SALARY_CHANGE       char(2)             = '02'
    DECLARE @v_EVENT_ID_TRANSFER            char(2)             = '03'
    DECLARE @v_EVENT_ID_NAME_CHANGE         char(2)             = '04'
    DECLARE @v_EVENT_ID_STATUS_CHANGE       char(2)             = '05'
    DECLARE @v_EVENT_ID_PAY_ELE             char(2)             = '06'
    DECLARE @v_EVENT_ID_PAY_GROUP           char(2)             = '08'
    DECLARE @v_EVENT_ID_LABOR_GROUP         char(2)             = '09'
    DECLARE @v_EVENT_ID_POSITION_TITLE      char(2)             = '10'

    DECLARE @v_ACTIVITY_STATUS_GOOD         char(2)             = '00'
    DECLARE @v_ACTIVITY_STATUS_WARNING      char(2)             = '01'
    DECLARE @v_ACTIVITY_STATUS_BAD          char(2)             = '02'


    DECLARE @ErrorMessage                   nvarchar(4000)
    DECLARE @ErrorSeverity                  int
    DECLARE @ErrorState                     int

    DECLARE @v_ret_val                      int = 0

    DECLARE @w_msg_text                  varchar(255)
    DECLARE @w_msg_text_2               varchar(255)
    DECLARE @w_msg_text_3               varchar(255)
    DECLARE @w_severity_cd               tinyint
    DECLARE @w_fatal_error               bit     = 0         --char(01)

    DECLARE @individual_id               char(10)
    DECLARE @prior_last_name            char(30)

    DECLARE @maxx         CHAR(06)
    DECLARE @msg_id         CHAR(10)

    DECLARE @cur_empl_id                                char(10)
    DECLARE @cur_eempl_eff_date                         datetime
    DECLARE @cur_tax_entity_id                          char(10)
    DECLARE @cur_pay_group_id           char(10)
    DECLARE @w_eff_date                 datetime


    CREATE TABLE #temp14
    (
      emp_id                      char(15)       not null
    , eff_date                       datetime       not null
    , next_eff_date                  datetime       not null
    , prior_eff_date                 datetime       not null
    ,   employment_type_code           char(5)       not null
    ,   work_tm_code                   char(1)       null
    ,   official_title_code            char(5)       not null
    ,   official_title_date            datetime       not null
    ,   mgr_ind                        char(1)       not null
    ,   recruiter_ind                  char(1)       not null
    ,   pensioner_indicator            char(1)       not null
    ,   payroll_company_code           char(5)       not null
    ,   pmt_ctrl_code                  char(5)       not null
    ,   us_federal_tax_meth_code       char(1)       not null
    ,   us_federal_tax_amt             money          not null
    ,   us_federal_tax_pct             money          not null
    ,   us_federal_marital_status_code char(1)       not null
    ,   us_federal_exemp_nbr           tinyint       not null
    ,   us_work_st_code                char(2)       not null
    ,   canadian_work_province_code    char(2)       not null
    ,   ipp_payroll_id                 char(5)       not null
    ,   ipp_max_pay_level_amt          money          not null
    ,   pay_through_date               datetime       not null
    ,   empl_id                        char(10)       not null
    ,   tax_entity_id                  char(10)       not null
    ,   pay_status_code                char(1)       not null
    ,   clock_nbr                      char(10)       not null
    ,   provided_i_9_ind               char(1)       not null
    ,   time_reporting_meth_code       char(1)       not null
    ,   regular_hrs_tracked_code       char(1)       not null
    ,   pay_element_ctrl_grp_id        char(10)       not null
    ,   pay_group_id                   char(10)       not null
    ,   us_pension_ind                 char(1)       not null
    ,   professional_cat_code          char(5)       not null
    ,   corporate_officer_ind          char(1)       not null
    ,   prim_disbursal_loc_code        char(10)       not null
    ,   alternate_disbursal_loc_code   char(10)       not null
    ,   labor_grp_code                 char(5)       not null
    ,   employment_info_chg_reason_cd  char(5)       not null
    ,   highly_compensated_emp_ind     char(1)       not null
    ,   nbr_of_dependent_children      tinyint       not null
    ,   canadian_federal_tax_meth_cd   char(1)       not null
    ,   canadian_federal_tax_amt       money          not null
    ,   canadian_federal_tax_pct       money          not null
    ,   canadian_federal_claim_amt     money          not null
    ,   canadian_province_claim_amt    money          not null
    ,   tax_unit_code                  char(5)       not null
    ,   requires_tm_card_ind           char(1)       not null
    ,   xfer_type_code                 char(1)       not null
    ,   tax_clear_code                 char(1)       not null
    ,   pay_type_code                  char(1)       not null
    ,   labor_distn_code               char(14)       not null
    ,   labor_distn_ext_code           char(30)       not null
    ,   us_fui_status_code             char(1)       not null
    ,   us_fica_status_code            char(1)       not null
    ,   payable_through_bank_id        char(11)       not null
    ,   disbursal_seq_nbr_1            char(30)       not null
    ,   disbursal_seq_nbr_2            char(30)       not null
    ,   non_employee_indicator         char(1)       not null
    ,   excluded_from_payroll_ind      char(1)       not null
    ,   emp_info_source_code           char(1)       not null
    ,   user_amt_1                     float          not null
    ,   user_amt_2                     float          not null
    ,   user_monetary_amt_1            money          not null
    ,   user_monetary_amt_2            money          not null
    ,   user_monetary_curr_code        char(3)       not null
    ,   user_code_1                    char(5)       not null
    ,   user_code_2                    char(5)       not null
    ,   user_date_1                    datetime       not null
    ,   user_date_2                    datetime       not null
    ,   user_ind_1                     char(1)       not null
    ,   user_ind_2                     char(1)       not null
    ,   user_text_1                    char(50)       not null
    ,   user_text_2                    char(50)       not null
    ,   t4_employ_code                 char(2)       not null
    ,   chgstamp                       smallint       not null
    )



    -- This section declares the interface values from Global HR
    DECLARE   @event_id                         char(02)
          , @emp_id                            char(15)
          , @eff_date                         char(10)
          , @first_name                         char(25)
          , @first_middle_name                   char(25)
          , @last_name                         char(30)
          , @empl_id                         char(10)
          , @national_id_type_code                char(05)
          , @national_id                      char(20)
          , @organization_group_id                char(05)
          , @organization_chart_name             varchar(64)
          , @organization_unit_name                varchar(240)
          , @emp_status_classn_code                char(02)
          , @position_title                      char(50)        -- DBShrpn..emp_assignment.user_text
          , @employment_type_code                varchar(70)     -- increased size to 70 from 5
          , @annual_salary_amt                   char(15)
          , @begin_date                         char(10)
          , @end_date                         char(10)
          , @pay_status_code                   char(01)
          , @pay_group_id                      char(10)
          , @pay_element_ctrl_grp_id             char(10)
          , @time_reporting_meth_code             char(01)
          , @employment_info_chg_reason_cd          char(05)
          , @emp_location_code                   char(10)
          , @emp_status_code                   char(02)
          , @reason_code                      char(02)
          , @emp_expected_return_date             char(10)
          , @pay_through_date                   char(10)
          , @emp_death_date                      char(10)
          , @consider_for_rehire_ind             char(01)
          , @pay_element_id                       char(10)
          , @emp_calculation                  char(15)
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
        WHERE (msg_id IN ('U00013'
                        ,'U00009'
                        ,'U00010'
                        ,'U00011'
                        ,'U00027'
                        ,'U00102'
                        ,'U00104'
                        ,'U00105'
                        ,'U00106'
                        ,'U00012'
                        ))

        -- ID Message templates that need to loop through errors to add to log table
        UPDATE #tbl_msg_master
        SET loop_flag = 'Y'
        WHERE (msg_id IN (
                          'U00012'
                         ,'U00020'
                         ,'U00027'
                         ,'U00105'
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
      WHERE (event_id = @v_EVENT_ID_NAME_CHANGE)

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
            ---------------------------------------------------------------------------
            --   This section will validate the interface data
            ---------------------------------------------------------------------------
            ---------------------------------------------------------------------------
            SET @v_step_position = 'Begin Validation'



            --Skip Record if associate also has New Hire, Transfer, Status Change
            IF EXISTS (
                SELECT 1
                FROM #ghr_employee_events_temp
                WHERE (emp_id = @emp_id)
                  AND (event_id IN (
                                     @v_EVENT_ID_NEW_HIRE
                                   , @v_EVENT_ID_TRANSFER
                                   , @v_EVENT_ID_STATUS_CHANGE
                                   ))
            )
            BEGIN

                UPDATE DBShrpn.dbo.ghr_employee_events_aud
                SET activity_status   = @v_ACTIVITY_STATUS_WARNING
                WHERE activity_date   = @p_activity_date
                  AND emp_id =   @emp_id
                  AND event_id = @v_EVENT_ID_PAY_GROUP

                -- Skip record and al other validations
                -- since pay group will be processed in the other events
                GOTO BYPASS_EMPLOYEE

            END


            ---------------------------------------------------------------------------
            -- Validate Effective Date
            ---------------------------------------------------------------------------
            -- Invalid date value from HCM, ''@1'', for employee, @2, and event id, @3.

            -- Effective Date
            IF (TRY_CONVERT(datetime, @eff_date) IS NULL)
                BEGIN

                    SET @msg_id = 'U00102'  -- New code
                    SET @v_step_position = 'Validation Effective Date - ' + RTRIM(@msg_id)

                    UPDATE DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status   = @v_ACTIVITY_STATUS_BAD
                    WHERE activity_date = @p_activity_date
                    AND event_id = @v_EVENT_ID_PAY_GROUP
                    AND emp_id = @emp_id

                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id      AS msg_id
                         , REPLACE(REPLACE(REPLACE(t.msg_text, '@1', @eff_date), '@2', @emp_id), '@3', @v_EVENT_ID_TRANSFER) AS msg_desc
                    FROM #tbl_msg_master t
                    WHERE (msg_id = @msg_id)

                    -- Historical Message for reporting purpose
                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                    SELECT  @msg_id                                      AS msg_id,
                            @v_EVENT_ID_PAY_GROUP AS event_id,
                            @emp_id                                   AS emp_id,
                            @eff_date                                 AS eff_date,
                            ''                         AS pay_element_id,
                            @emp_id                                   AS msg_p1,
                            @empl_id                                  AS msg_p2,
                            'Invalid Effective Date' AS msg_desc,
                            @p_activity_date                             AS activity_date

                    SET @w_fatal_error = 1

                END
            ELSE
                -- Convert amount to money data type
                SELECT @w_eff_date = CONVERT(datetime, @eff_date)




            ---------------------------------------------------------------------------
            -- Check to see if the employee exists
            ---------------------------------------------------------------------------
            SET @msg_id = 'U00012'
            SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

            SELECT @cur_empl_id                             = eempl.empl_id
                 , @cur_tax_entity_id                       = eempl.tax_entity_id
                 , @cur_eempl_eff_date                      = eempl.eff_date
                 , @cur_pay_group_id                        - eempl.pay_group_id
            FROM DBShrpn.dbo.employee emp
            JOIN DBShrpn.dbo.uvu_emp_employment_most_rec eempl ON
                 (emp.emp_id = eempl.emp_id)
            WHERE (emp.emp_id = @emp_id)

            IF (@@ROWCOUNT = 0)
                BEGIN

                    UPDATE DBShrpn.dbo.ghr_employee_events_aud
                        SET activity_status = @v_ACTIVITY_STATUS_BAD
                    WHERE activity_date = @p_activity_date
                        AND emp_id = @emp_id
                        AND event_id = @v_EVENT_ID_PAY_GROUP


                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id      As msg_id
                         , REPLACE(t.msg_text, '@1', @emp_id) AS msg_desc
                    FROM #tbl_msg_master t
                    WHERE (msg_id = @msg_id)


                    -- Historical Message for reporting purpose
                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                    VALUES
                    (
                      @msg_id                       -- msg_id
                    , @v_EVENT_ID_PAY_GROUP       -- event_id,
                    , @emp_id                    -- emp_id
                    , @eff_date                   -- eff_date
                    , @pay_element_id             -- pay_element_id
                    , @emp_id                   -- msg_p1
                    , ''                      -- msg_p2
                    , 'Employee does not exist'       -- msg_desc
                    , @p_activity_date             -- activity_date
                    )

                    SET @w_fatal_error = 1

                END


            ---------------------------------------------------------------------------
            -- Is new pay group same as old pay group?
            ---------------------------------------------------------------------------
            SET @msg_id = 'U00106'
            SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

            IF (@pay_group_id = @cur_pay_group_id)
                BEGIN

                    UPDATE DBShrpn.dbo.ghr_employee_events_aud
                        SET activity_status = @v_ACTIVITY_STATUS_BAD
                    WHERE activity_date = @p_activity_date
                        AND emp_id = @emp_id
                        AND event_id = @v_EVENT_ID_PAY_GROUP


                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id      As msg_id
                         , REPLACE(REPLACE(t.msg_text, '@1', @pay_group_id), '@2', @emp_id) AS msg_desc
                    FROM #tbl_msg_master t
                    WHERE (msg_id = @msg_id)


                    -- Historical Message for reporting purpose
                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                    VALUES
                    (
                      @msg_id                       -- msg_id
                    , @v_EVENT_ID_PAY_GROUP         -- event_id,
                    , @emp_id                       -- emp_id
                    , @eff_date                     -- eff_date
                    , ''                            -- pay_element_id
                    , @pay_group_id                 -- msg_p1
                    , @cur_pay_group_id             -- msg_p2
                    , 'New pay group is same as current pay group - bypassing record.'       -- msg_desc
                    , @p_activity_date              -- activity_date
                    )

                    SET @w_fatal_error = 1

                END



            ---------------------------------------------------------------------------
            --   Check to see if new pay group id exists
            ---------------------------------------------------------------------------
            SET @msg_id = 'U00020'
            SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

            IF NOT EXISTS(
                        SELECT 1
                        FROM   DBShrpn.dbo.pay_group
                        WHERE   pay_group_id = @pay_group_id
                        )
                BEGIN

                    UPDATE   DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status   = @v_ACTIVITY_STATUS_BAD
                    WHERE activity_date   =   @p_activity_date
                    AND emp_id      =   @emp_id
                    AND event_id      =   @v_EVENT_ID_PAY_GROUP

                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id As msg_id
                         , REPLACE(REPLACE(t.msg_text, '@1', @pay_group_id), '@2', @emp_id) AS msg_desc
                    FROM #tbl_msg_master t
                    WHERE (msg_id = @msg_id)


                    -- Historical Message for reporting purpose
                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                    SELECT  @msg_id               As msg_id,
                            @v_EVENT_ID_PAY_GROUP As event_id,
                            @emp_id                As emp_id,
                            @eff_date            As eff_date,
                            @pay_element_id      As pay_element_id,
                            @emp_id               As msg_p1,
                            @pay_group_id         As msg_p2,
                            'Invalid Pay Group ID'   As msg_desc,
                            @p_activity_date         AS activity_date

                    -- SET   @pay_group_id = ' '

                    SET  @w_fatal_error = 1

                END


            ---------------------------------------------------------------------------
            -- Effective date must be greater than current effective date
            ---------------------------------------------------------------------------
            SET @msg_id = 'U00027'
            SET @v_step_position = 'Begin ' + RTRIM(@msg_id)

            IF (@w_fatal_error = 0) AND
               (@w_eff_date <= @cur_eempl_eff_date)
                BEGIN

                    UPDATE DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status   = @v_ACTIVITY_STATUS_BAD
                    WHERE activity_date   =   @p_activity_date
                    AND emp_id      =   @emp_id
                    AND event_id      =   @v_EVENT_ID_PAY_GROUP

                    INSERT INTO #tbl_ghr_msg
                    SELECT @msg_id As msg_id
                         , REPLACE(REPLACE(t.msg_text, '@1', @w_eff_date), '@2', @emp_id) AS msg_desc
                    FROM #tbl_msg_master t
                    WHERE (msg_id = @msg_id)


                    -- Historical Message for reporting purpose
                    INSERT INTO DBShrpn.dbo.ghr_historical_message
                    SELECT  @msg_id               As msg_id,
                            @v_EVENT_ID_PAY_GROUP As event_id,
                            @emp_id                As emp_id,
                            @eff_date            As eff_date,
                            @pay_element_id      As pay_element_id,
                            @emp_id               As msg_p1,
                            @pay_group_id         As msg_p2,
                            'New effective date must be greater than current employee employment effective date.'   As msg_desc,
                            @p_activity_date         AS activity_date

                    -- SET   @pay_group_id = ' '

                    SET  @w_fatal_error = 1

                END




            IF (@w_fatal_error = 1)
                GOTO BYPASS_EMPLOYEE



            ---------------------------------------------------------------------------
            -- Update Employee Employment with new Pay Group
            ---------------------------------------------------------------------------

            -- Update current record date pointers
            UPDATE DBShrpn.dbo.emp_employment
            SET next_eff_date = @w_eff_date
            WHERE emp_id = @p_emp_id
              AND eff_date = @p_eff_date


            -- Create new record
            INSERT INTO #temp14
            SELECT emp_id
                 , @w_eff_date      -- eff_date
                 , @v_END_OF_TIME_DATE      -- next_eff_date
                 , @cur_eempl_eff_date      -- prior_eff_date
                 , employment_type_code
                 , work_tm_code
                 , official_title_code
                 , official_title_date
                 , mgr_ind
                 , recruiter_ind
                 , pensioner_indicator
                 , payroll_company_code
                 , pmt_ctrl_code
                 , us_federal_tax_meth_code
                 , us_federal_tax_amt
                 , us_federal_tax_pct
                 , us_federal_marital_status_code
                 , us_federal_exemp_nbr
                 , us_work_st_code
                 , canadian_work_province_code
                 , ipp_payroll_id
                 , ipp_max_pay_level_amt
                 , pay_through_date
                 , empl_id
                 , tax_entity_id
                 , pay_status_code
                 , clock_nbr
                 , provided_i_9_ind
                 , time_reporting_meth_code
                 , regular_hrs_tracked_code
                 , pay_element_ctrl_grp_id
                 , @pay_group_id        -- pay_group_id
                 , us_pension_ind
                 , professional_cat_code
                 , corporate_officer_ind
                 , prim_disbursal_loc_code
                 , alternate_disbursal_loc_code
                 , labor_grp_code
                 , employment_info_chg_reason_cd
                 , highly_compensated_emp_ind
                 , nbr_of_dependent_children
                 , canadian_federal_tax_meth_cd
                 , canadian_federal_tax_amt
                 , canadian_federal_tax_pct
                 , canadian_federal_claim_amt
                 , canadian_province_claim_amt
                 , tax_unit_code
                 , requires_tm_card_ind
                 , xfer_type_code
                 , tax_clear_code
                 , pay_type_code
                 , labor_distn_code
                 , labor_distn_ext_code
                 , us_fui_status_code
                 , us_fica_status_code
                 , payable_through_bank_id
                 , disbursal_seq_nbr_1
                 , disbursal_seq_nbr_2
                 , non_employee_indicator
                 , excluded_from_payroll_ind
                 , emp_info_source_code
                 , user_amt_1
                 , user_amt_2
                 , user_monetary_amt_1
                 , user_monetary_amt_2
                 , user_monetary_curr_code
                 , user_code_1
                 , user_code_2
                 , user_date_1
                 , user_date_2
                 , user_ind_1
                 , user_ind_2
                 , user_text_1
                 , user_text_2
                 , t4_employ_code
                 , chgstamp
            FROM DBShrpn.dbo.emp_employment
            WHERE (emp_id   = @p_emp_id)
              AND (eff_date = @cur_eempl_eff_date)


            INSERT INTO emp_employment
            SELECT emp_id
                , eff_date
                , next_eff_date
                , prior_eff_date
                , employment_type_code
                , work_tm_code
                , official_title_code
                , official_title_date
                , mgr_ind
                , recruiter_ind
                , pensioner_indicator
                , payroll_company_code
                , pmt_ctrl_code
                , us_federal_tax_meth_code
                , us_federal_tax_amt
                , us_federal_tax_pct
                , us_federal_marital_status_code
                , us_federal_exemp_nbr
                , us_work_st_code
                , canadian_work_province_code
                , ipp_payroll_id
                , ipp_max_pay_level_amt
                , pay_through_date
                , empl_id
                , tax_entity_id
                , pay_status_code
                , clock_nbr
                , provided_i_9_ind
                , time_reporting_meth_code
                , regular_hrs_tracked_code
                , pay_element_ctrl_grp_id
                , pay_group_id
                , us_pension_ind
                , professional_cat_code
                , corporate_officer_ind
                , prim_disbursal_loc_code
                , alternate_disbursal_loc_code
                , labor_grp_code
                , employment_info_chg_reason_cd
                , highly_compensated_emp_ind
                , nbr_of_dependent_children
                , canadian_federal_tax_meth_cd
                , canadian_federal_tax_amt
                , canadian_federal_tax_pct
                , canadian_federal_claim_amt
                , canadian_province_claim_amt
                , tax_unit_code
                , requires_tm_card_ind
                , xfer_type_code
                , tax_clear_code
                , pay_type_code
                , labor_distn_code
                , labor_distn_ext_code
                , us_fui_status_code
                , us_fica_status_code
                , payable_through_bank_id
                , disbursal_seq_nbr_1
                , disbursal_seq_nbr_2
                , non_employee_indicator
                , excluded_from_payroll_ind
                , emp_info_source_code
                , user_amt_1
                , user_amt_2
                , user_monetary_amt_1
                , user_monetary_amt_2
                , user_monetary_curr_code
                , user_code_1
                , user_code_2
                , user_date_1
                , user_date_2
                , user_ind_1
                , user_ind_2
                , user_text_1
                , user_text_2
                , t4_employ_code
                , chgstamp
            FROM #temp14 t14
            WHERE NOT EXISTS (
                              SELECT 1
                              FROM DBShrpn.dbo.emp_employment t2
                              WHERE (t2.emp_id = t14.emp_id)
                                AND (t2.eff_date = @p_transfer_date)
                             )



/*  DO WE NEED TO CREATE AN AUDIT RECORD?????
    -- WE'LL NEED AN ACTIVITY ACTION CODE

        INSERT INTO work_emp_employment_aud
            (user_id, activity_action_code, action_date, emp_id, eff_date,
            next_eff_date, prior_eff_date, new_eff_date, new_empl_id,
            new_tax_entity_id, xfer_date, pay_through_date)
        VALUES
            (@W_ACTION_USER, 'ERTRANSFER', @W_ACTION_DATETIME, @p_emp_id,
            @p_eff_date, '', '', @p_transfer_date, '', '', '', '')

        DELETE work_emp_employment_aud
        WHERE user_id = @W_ACTION_USER
        AND activity_action_code = 'ERTRANSFER'
        AND emp_id = @p_emp_id
*/



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


        END -- end of while loop

        -- Cleanup Cursor
        CLOSE crsrHR
        DEALLOCATE crsrHR



        ---------------------------------------------------------------------------
        -- Send notification of warning message U00013  -- < PAY GROUP SECTION (8) >
        ---------------------------------------------------------------------------
        SET @msg_id = 'U000104'
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
        -- Send notification of warning message U00105 - Total nbr of employees pay group changes
        ---------------------------------------------------------------------------
        SET @msg_id = 'U00016'
        SET @v_step_position = 'Log ' + @msg_id

        SELECT @msg_id        = msg_id
            , @w_msg_text    = msg_text
            , @w_msg_text_2  = msg_text_2
            , @w_msg_text_3  = msg_text_3
            , @w_severity_cd = severity_cd
        FROM #tbl_msg_master
        WHERE (msg_id = @msg_id)

        -- Get total name records from HCM
        SELECT @maxx = CAST(COUNT(*) AS varchar(6))
        FROM #ghr_employee_events_temp
        WHERE (event_id =   @v_EVENT_ID_PAY_GROUP)

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
        -- NOTE: log entries were created in validation section

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
    DROP TABLE #tbl_ghr_msg
    DROP TABLE #tbl_msg_master
    DROP TABLE #temp14


END
GO

ALTER AUTHORIZATION ON dbo.usp_ins_pay_group TO  SCHEMA OWNER
GO

IF OBJECT_ID(N'dbo.usp_ins_pay_group', N'P') IS NOT NULL
    PRINT N'<<< CREATED PROCEDURE dbo.usp_ins_pay_group >>>'
ELSE
    PRINT N'<<< FAILED CREATING PROCEDURE dbo.usp_ins_pay_group >>>'
GO