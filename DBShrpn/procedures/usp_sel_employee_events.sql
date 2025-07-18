USE DBShrpn
GO


SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE OR ALTER PROCEDURE dbo.usp_sel_employee_events
(
    @USER_ID      char(30)
)
AS

BEGIN

    SET NOCOUNT ON

    DECLARE @w_activity_date	datetime
          , @w_inputfile		varchar(254)
          , @w_wflow_userid		varchar(30)
          , @w_activity_status	char(02)
          , @w_status			int
          , @w_userid			varchar(30)
          , @w_batchname		varchar(08)
          , @w_qualifier		varchar(30)


    CREATE TABLE #ghr_employee_events_temp
    (
      ID									    int	IDENTITY(11)    NOT NULL
    , event_id_01							    char(02)            NULL
    , emp_id_01							        char(15)            NULL
    , eff_date_01							    char(10)            NULL
    , first_name_01						        char(25)            NULL
    , first_middle_name_01				        char(25)            NULL
    , last_name_01						        char(30)            NULL
    , empl_id_01							    char(10)            NULL
    , national_id_1_type_code_01			    char(05)            NULL
    , national_id_1_01					        char(20)            NULL
    , organization_group_id_01			        char(05)            NULL
    , organization_chart_name_01			    varchar(64)         NULL
    , organization_unit_name_01			        varchar(240)        NULL
    , emp_status_classn_code_01			        char(02)            NULL
    , position_title_01					        char(60)            NULL
    , employment_type_code_01				    char(05)            NULL
    , annual_salary_amt_01				        char(15)            NULL
    , begin_date_02						        char(10)            NULL
    , end_date_02							    char(10)            NULL
    , pay_status_code_03					    char(01)            NULL
    , pay_group_id_03						    char(10)            NULL
    , pay_element_ctrl_grp_id_03			    char(10)            NULL
    , time_reporting_meth_code_03			    char(01)            NULL
    , employment_info_chg_reason_cd_03	        char(05)            NULL
    , emp_location_code_03				        char(10)            NULL
    , emp_status_code_5					        char(02)            NULL
    , reason_code_5						        char(02)            NULL
    , emp_expected_return_date_5			    char(10)            NULL
    , pay_through_date_5					    char(10)            NULL
    , emp_death_date_5					        char(10)            NULL
    , consider_for_rehire_ind_5			        char(01)            NULL
    , pay_element_desc_06					    char(20)            NULL
    , emp_calculation_06					    char(15)            NULL
    , tax_flag                                  char(1)             NULL    -- individual_personal.ind_2
    , nic_flag                                  char(1)             NULL    -- individual_personal.ind_1
    , tax_ceiling_amt                           char(15)            NULL    -- employee.user_monetary_amt_1
    , labor_grp_code                            char(50)            NULL    -- emp_assignment.user_text_1
    )

-- CJP declare in each event procedure???
CREATE TABLE #tbl_ghr_msg
    (
	  msg_id                                    char(15)            NOT NULL
	, msg_p1                                    char(15)            NOT NULL
    , msg_p1_spec_char                          char(2)             NOT NULL
    , msg_p1_field                              varchar(255)        NOT NULL
	, msg_p2                                    char(15)            NOT NULL
    , msg_p2_spec_char                          char(2)             NOT NULL
    , msg_p2_field                              varchar(255)        NOT NULL
    , msg_desc                                  char(255)           NOT NULL
    )


	-- Find the Batch name and qualifier for the job running the Bulk Copy
    SELECT @w_userid        =	psc_userid
		 , @w_batchname	    =	psc_batchname
		 , @w_qualifier	    =	psc_qualifier
    FROM DBSpscb.dbo.psc_step
    WHERE psc_userid		= @USER_ID
      AND psc_pgm_parms	= 'GHR_EMPLOYEE_EVENTS'


	SET @w_activity_status	= '00'
	SET @w_activity_date = CAST(CONVERT(CHAR(20),GETDATE(),120) as DATETIME)
	SET @w_wflow_userid = @USER_ID


	SELECT @w_inputfile	=	batch_parameter_3
	FROM DBSentp.dbo.batch_parameters
	WHERE batch_parameter_key = 'GHR_EMPLOYEE_EVENTS'


    INSERT INTO #ghr_employee_events_temp
    SELECT event_id_01
		 , emp_id_01
		 , eff_date_01
		 , first_name_01
		 , first_middle_name_01
		 , last_name_01
		 , empl_id_01
		 , national_id_1_type_code_01
		 , national_id_1_01
		 , organization_group_id_01
		 , organization_chart_name_01
		 , organization_unit_name_01
		 , emp_status_classn_code_01
		 , position_title_01
		 , employment_type_code_01
		 , annual_salary_amt_01
		 , begin_date_02
		 , end_date_02
		 , pay_status_code_03
		 , pay_group_id_03
		 , pay_element_ctrl_grp_id_03
		 , time_reporting_meth_code_03
		 , employment_info_chg_reason_cd_03
		 , emp_location_code_03
		 , emp_status_code_5
		 , reason_code_5
		 , emp_expected_return_date_5
		 , pay_through_date_5
		 , emp_death_date_5
		 , consider_for_rehire_ind_5
		 , pay_element_desc_06
		 , emp_calculation_06
         , tax_flag
         , nic_flag
         , tax_ceiling_amt
         , labor_grp_code
    FROM DBShrpn.dbo.ghr_employee_events
    ORDER BY event_id_01
           , emp_id_01


	INSERT INTO DBShrpn.dbo.ghr_employee_events_aud
    SELECT event_id_01
		 , emp_id_01
		 , eff_date_01
		 , first_name_01
		 , first_middle_name_01
		 , last_name_01
		 , empl_id_01
		 , national_id_1_type_code_01
		 , national_id_1_01
		 , organization_group_id_01
		 , organization_chart_name_01
		 , organization_unit_name_01
		 , emp_status_classn_code_01
		 , position_title_01
		 , employment_type_code_01
		 , annual_salary_amt_01
		 , begin_date_02
		 , end_date_02
		 , pay_status_code_03
		 , pay_group_id_03
		 , pay_element_ctrl_grp_id_03
		 , time_reporting_meth_code_03
		 , employment_info_chg_reason_cd_03
		 , emp_location_code_03
		 , emp_status_code_5
		 , reason_code_5
		 , emp_expected_return_date_5
		 , pay_through_date_5
		 , emp_death_date_5
		 , consider_for_rehire_ind_5
		 , pay_element_desc_06
		 , emp_calculation_06
         , tax_flag
         , nic_flag
         , tax_ceiling_amt
         , labor_grp_code
		 , @w_activity_date		    AS activity_date
		 , @w_wflow_userid		    AS activity_user
		 , @w_activity_status		AS activity_status
    FROM DBShrpn.dbo.ghr_employee_events ee
    WHERE NOT EXISTS (
                      SELECT 1
                      FROM DBShrpn.dbo.ghr_employee_events_aud t
                      WHERE t.event_id_01	=   ee.event_id_01
                        AND t.emp_id_01		=	ee.emp_id_01
                        AND t.activity_date	=	@w_activity_date
                     )


    ---------------------------------------------------------------------------
    -- New Hires
    ---------------------------------------------------------------------------
	IF  EXISTS (SELECT event_id_01 FROM DBShrpn.dbo.ghr_employee_events WHERE event_id_01 = '01' )
    BEGIN
        EXEC DBShrpn.dbo.usp_ins_new_hire
              @p_userid          = @w_userid
            , @p_batchname       = @w_batchname
            , @p_qualifier       = @w_qualifier
            , @p_activity_date   = @w_activity_date
            , @p_user_id         = @w_wflow_userid
            , @p_activity_status = @w_activity_status
            , @p_status          = @w_status
    END


    ---------------------------------------------------------------------------
    -- Salary Change
    ---------------------------------------------------------------------------
	IF  EXISTS (SELECT event_id_01 FROM DBShrpn.dbo.ghr_employee_events WHERE event_id_01 = '02' )
    BEGIN
        EXEC	DBShrpn.dbo.usp_ins_salary_change @w_userid,
                @w_batchname,
                @w_qualifier,
                @w_activity_date,
                @w_wflow_userid,
                @w_activity_status,
                @w_status
    END


    ---------------------------------------------------------------------------
    -- Employee Transfer
    ---------------------------------------------------------------------------
	IF  EXISTS (SELECT event_id_01 FROM DBShrpn.dbo.ghr_employee_events WHERE event_id_01 = '03' )
    BEGIN
        EXEC	DBShrpn.dbo.usp_perform_transfer @w_userid,
                @w_batchname,
                @w_qualifier,
                @w_activity_date,
                @w_wflow_userid,
                @w_activity_status,
                @w_status
    END


    ---------------------------------------------------------------------------
    -- Name Change
    ---------------------------------------------------------------------------
	IF  EXISTS (SELECT event_id_01 FROM DBShrpn.dbo.ghr_employee_events WHERE event_id_01 = '04' )
    BEGIN
        EXEC	DBShrpn.dbo.usp_ins_name_change @w_userid,
                @w_batchname,
                @w_qualifier,
                @w_activity_date,
                @w_wflow_userid,
                @w_activity_status,
                @w_status
    END


    ---------------------------------------------------------------------------
    -- Status Change
    ---------------------------------------------------------------------------
	IF  EXISTS (SELECT event_id_01 FROM DBShrpn.dbo.ghr_employee_events WHERE event_id_01 = '05' )
    BEGIN
        EXEC	DBShrpn.dbo.usp_ins_status_change @w_userid,
                @w_batchname,
                @w_qualifier,
                @w_activity_date,
                @w_wflow_userid,
                @w_activity_status,
                @w_status
    END


    ---------------------------------------------------------------------------
    -- Pay Element
    ---------------------------------------------------------------------------
	IF  EXISTS (SELECT event_id_01 FROM DBShrpn.dbo.ghr_employee_events WHERE event_id_01 = '06' )
    BEGIN
        EXEC DBShrpn.dbo.usp_ins_pay_element
                @w_userid,
                @w_batchname,
                @w_qualifier,
                @w_activity_date,
                @w_wflow_userid,
                @w_activity_status,
                @w_status
    END


	 TRUNCATE TABLE DBShrpn.dbo.ghr_employee_events;

    -- Clean up temp table
    DROP TABLE #ghr_employee_events_temp
    DROP TABLE #tbl_ghr_msg


END
GO


ALTER AUTHORIZATION ON dbo.usp_sel_employee_events TO  SCHEMA OWNER
GO
