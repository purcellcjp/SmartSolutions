USE [DBShrpn]
GO
/****** Object:  StoredProcedure [dbo].[usp_ins_new_hire]    Script Date: 4/1/2025 4:33:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[usp_ins_new_hire]
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

DECLARE @ret int
--DECLARE @p_activity_date				datetime
--DECLARE @p_userid						varchar(30)
--DECLARE @p_batchname					varchar(08)
--DECLARE @p_qualifier					varchar(30)
--DECLARE @p_status						int
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


SELECT @w_trace_sw = 'N'

IF @w_trace_sw = 'Y'
INSERT INTO DBSosxp.dbo.msg SELECT CAST(GETDATE() AS CHAR (20)) AS msg_desc

IF @w_trace_sw = 'Y'
INSERT INTO DBSosxp.dbo.msg SELECT 'Start usp_ins_new_hire' AS msg_desc

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


--exec @ret = sp_dbs_authenticate
--if @ret != 0 return -1

IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_employee_events_temp1]') AND type in (N'U'))
	DROP TABLE [dbo].[ghr_employee_events_temp1]


CREATE TABLE [dbo].[ghr_employee_events_temp1](
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

INSERT INTO DBShrpn.dbo.ghr_employee_events_temp1    ---#t0
SELECT * 
  FROM DBShrpn.dbo.ghr_employee_events
 WHERE [event_id_01] = '01' 

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
DECLARE @pay_frequency_code		char(05)




-- Fields required for new hire
   DECLARE @w_employer_id                          char(10)
   DECLARE @w_employee_id                          char(15)
   DECLARE @w_individual_id                        char(10)
   DECLARE @w_original_hire_date                   datetime
   DECLARE @w_first_name                           char(25)
   DECLARE @w_first_middle_name                    char(25)
   DECLARE @w_last_name                            char(30)
   DECLARE @w_preferred_name                       char(25)
   DECLARE @w_name_suffix                          char(10)
   DECLARE @w_emp_display_name                     char(45)
   DECLARE @w_birth_date                           datetime
   DECLARE @w_sex_code                             char(01)
   DECLARE @w_marital_status_code_1                char(05)
   DECLARE @w_national_id_1_type_code              char(05)
   DECLARE @w_national_id_1                        char(20)
   DECLARE @w_addr_1_type_code                     char(05)
   DECLARE @w_addr_1_fmt_code                      char(06)
   DECLARE @w_addr_1_line_1                        char(35)
   DECLARE @w_addr_1_line_2                        char(35)
   DECLARE @w_addr_1_line_3                        char(35)
   DECLARE @w_addr_1_line_4                        char(35)
   DECLARE @w_addr_1_line_5                        char(35)
   DECLARE @w_addr_1_street_or_pob_1               char(35)
   DECLARE @w_addr_1_street_or_pob_2               char(35)
   DECLARE @w_addr_1_street_or_pob_3               char(35)
   DECLARE @w_addr_1_city_name                     char(35)
   DECLARE @w_addr_1_ctry_sub_entity_code          char(09)
   DECLARE @w_addr_1_postal_code                   char(09)
   DECLARE @w_addr_1_country_code                  char(02)
   DECLARE @w_assigned_to_code                     char(01)
   DECLARE @w_job_or_pos_id                        char(10)
   DECLARE @w_organization_chart_name              char(64)
   DECLARE @w_organization_unit_name               char(240)
   DECLARE @w_emp_status_classn_code               char(02)
   DECLARE @w_active_reason_code                   char(05)
   DECLARE @w_employment_type_code                 char(05)
   DECLARE @w_professional_cat_code                char(05)
   DECLARE @w_labor_grp_code                       char(05)
   DECLARE @w_non_employee_indicator               char(01)
   DECLARE @w_excluded_from_payroll_ind            char(01)
   DECLARE @w_pensioner_indicator                  char(01)
   DECLARE @w_provided_i_9_ind                     char(01)
   DECLARE @w_base_rate_tbl_id                     char(10)
   DECLARE @w_base_rate_tbl_entry_code             char(08)
   DECLARE @w_exception_rate_ind                   char(01)
   DECLARE @w_hourly_pay_rate                      float
   DECLARE @w_pd_salary_amt                        money
   DECLARE @w_pd_salary_tm_pd_id                   char(05)
   DECLARE @w_annual_salary_amt                    money
   DECLARE @w_pay_basis_code                       char(01)
   DECLARE @w_curr_code                            char(03)
   DECLARE @w_work_tm_code                         char(01)
   DECLARE @w_standard_daily_work_hrs              float
   DECLARE @w_standard_work_hrs                    float
   DECLARE @w_standard_work_pd_id                  char(05)
   DECLARE @w_overtime_status_code                 char(02)
   DECLARE @w_pay_on_reported_hrs_ind              char(01)
   DECLARE @w_work_shift_code                      char(05) 
   DECLARE @w_tax_entity_id                        char(10)
   DECLARE @w_time_reporting_meth_code             char(01)
   DECLARE @w_pay_group_id                         char(10)
   DECLARE @w_clock_nbr                            char(10)
   DECLARE @w_prim_disbursal_loc_code              char(10)
   DECLARE @w_alt_disbursal_loc_code               char(10)
   DECLARE @w_tax_marital_status_code              char(01)
   DECLARE @w_fui_status_code                      char(01)
   DECLARE @w_oasdi_status_code                    char(01)
   DECLARE @w_medicare_status_code                 char(01)
   DECLARE @w_income_tax_nbr_of_exemps             smallint
   DECLARE @w_tax_authority_id                     char(10)
   DECLARE @w_work_resident_status_code            char(01)
   DECLARE @w_income_tax_calc_meth_cd              char(02)
   DECLARE @w_tax_authority_2                      char(10)
   DECLARE @w_tax_authority_3                      char(10)
   DECLARE @w_tax_authority_4                      char(10)
   DECLARE @w_tax_authority_5                      char(10)
   DECLARE @w_work_resident_status_code_2          char(01)
   DECLARE @w_work_resident_status_code_3          char(01)
   DECLARE @w_work_resident_status_code_4          char(01)
   DECLARE @w_work_resident_status_code_5          char(01)
   DECLARE @w_user_amt_1                           float
   DECLARE @w_user_amt_2                           float
   DECLARE @w_user_code_1                          char(05)
   DECLARE @w_user_code_2                          char(05)
   DECLARE @w_user_date_1                          datetime
   DECLARE @w_user_date_2                          datetime
   DECLARE @w_user_ind_1                           char(01)
   DECLARE @w_user_ind_2                           char(01)
   DECLARE @w_user_monetary_amt_1                  money
   DECLARE @w_user_monetary_amt_2                  money
   DECLARE @w_user_monetary_curr_code              char(03)
   DECLARE @w_user_text_1                          char(50)
   DECLARE @w_user_text_2                          char(50)
   DECLARE @w_inc_tax_calc_method                  char(02)
   DECLARE @w_ei_status_code                       char(01)
   DECLARE @w_ppip_status_code                     char(01)
   DECLARE @w_fed_pp_stat_code                     char(01)
   DECLARE @w_provincial_pp_stat_code              char(01)
   DECLARE @w_income_tax_stat_code                 char(01)
   DECLARE @w_pit_stat_code                        char(01)
   DECLARE @w_pay_element_ctrl_grp                 char(10)
   DECLARE @w_emp_workers_comp_class               char(01) 
   DECLARE @w_empl_addr_fmt_code                   char(06)
   DECLARE @w_empl_phone_fmt_code                  char(06)
   DECLARE @w_empl_phone_delimiter                 char(01)
   DECLARE @w_empl_recruitment_zone_code           char(05)
   DECLARE @w_empl_cma_code                        char(02)
   DECLARE @w_empl_industry_sector_code            char(05)
   DECLARE @w_empl_province_terr_code              char(02)
   DECLARE @w_eeo_4_agency_function_code           char(02)
   DECLARE @w_eeo_establishment_id                 char(8)
   DECLARE @w_assignment_end_date                  datetime
   DECLARE @w_location_code                        char(10)
   DECLARE @w_salary_structure_id                  char(10)
   DECLARE @w_salary_incr_guideline_id             char(10)
   DECLARE @w_pay_grade_code                       char(06)
   DECLARE @w_job_evaluation_points_nbr            smallint
   DECLARE @w_salary_step_nbr                      smallint
   DECLARE @w_employer_taxing_ctry_code            char(02)
   DECLARE @w_organization_group_id                int
   DECLARE @w_wage_plan_code                       char(02)
   DECLARE @w_emp_health_insurance_cvg_cd          char(02)
   DECLARE @w_tax_auth_type_code                   char(01)
   DECLARE @w_tax_auth_type_code_2                 char(01)
   DECLARE @w_tax_auth_type_code_3                 char(01)
   DECLARE @w_tax_auth_type_code_4                 char(01)
   DECLARE @w_tax_auth_type_code_5                 char(01)
   DECLARE @w_reg_reporting_unit_code			   char(10)
   DECLARE @w_emp_workers_comp_cvg_cd			   char(01) 

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
			
-- This section setup the default values   
   SELECT	@w_employer_id   =  'USA-CO1',
			@w_employee_id   =  '123456789',
			@w_individual_id   =  '566',				--This number must be obtained from the table
			@w_original_hire_date   =  '20210628',
			@w_first_name   =  'Maria',   
			@w_first_middle_name   =  'Jose',
			@w_last_name   =  'Gross',
			@w_preferred_name   =  '',
			@w_name_suffix   =  '',
			@w_emp_display_name   =  'Gross, Maria W',
			@w_birth_date   =  '20000426',
			@w_sex_code   =  'F',
			@w_marital_status_code_1   =  '',
			@w_national_id_1_type_code   =  'SSN',
			@w_national_id_1   =  '332561137',
   			@w_addr_1_type_code   =  '',
   			@w_addr_1_fmt_code   =  'US1',
   			@w_addr_1_line_1   =  '',
   			@w_addr_1_line_2   =  '',
   			@w_addr_1_line_3   =  '',
   			@w_addr_1_line_4   =  '',
   			@w_addr_1_line_5   =  '',
   			@w_addr_1_street_or_pob_1   =  '',
   			@w_addr_1_street_or_pob_2   =  '',
   			@w_addr_1_street_or_pob_3   =  '',
   			@w_addr_1_city_name   =  '',
   			@w_addr_1_ctry_sub_entity_code   =  '',
   			@w_addr_1_postal_code   =  '',
   			@w_addr_1_country_code   =  '',
   			@w_assigned_to_code   =  'P',
   			@w_job_or_pos_id   =  '00000-001',
   			@w_organization_chart_name   =  'GHR-HR',
   			@w_organization_unit_name   =  '999999',
   			@w_emp_status_classn_code   =  '01',
   			@w_active_reason_code   =  '',
   			@w_employment_type_code   =  '',
   			@w_professional_cat_code   =  '',
   			@w_labor_grp_code   =  '',
   			@w_non_employee_indicator   =  'N',
   			@w_excluded_from_payroll_ind   =  'N',
   			@w_pensioner_indicator   =  N'',
   			@w_provided_i_9_ind   =  'N',
   			@w_base_rate_tbl_id   =  '',
   			@w_base_rate_tbl_entry_code   =  '',
   			@w_exception_rate_ind   =  'N',
   			@w_hourly_pay_rate   =  '0',
   			@w_pd_salary_amt   =  '0',
   			@w_pd_salary_tm_pd_id   =  'MONTH',
   			@w_annual_salary_amt   =  '0',
   			@w_pay_basis_code   =  '9',
   			@w_curr_code   =  'XCD',
   			@w_work_tm_code   =  'F',
   			@w_standard_daily_work_hrs   =  '8',
			@w_standard_work_hrs   =  '40',
   			@w_standard_work_pd_id   =  'WEEK',
   			@w_overtime_status_code   =  '99',
   			@w_pay_on_reported_hrs_ind   =  'N',
   			@w_work_shift_code   =  '', 
   			@w_tax_entity_id   =  'TE1-CO1',
   			@w_time_reporting_meth_code   =  '1',
   			@w_pay_group_id   =  'ADMP',
   			@w_clock_nbr   =  '',
   			@w_prim_disbursal_loc_code   =  '',
   			@w_alt_disbursal_loc_code   =  '',
   			@w_tax_marital_status_code   =  '1',
   			@w_fui_status_code   =  '2',
   			@w_oasdi_status_code   =  '2',
   			@w_medicare_status_code   =  '2',
   			@w_income_tax_nbr_of_exemps   =  '0',
   			@w_tax_authority_id   =  '',
   			@w_work_resident_status_code   =  '',
   			@w_income_tax_calc_meth_cd   =  '01',
   			@w_tax_authority_2   =  '',
   			@w_tax_authority_3   =  '',
   			@w_tax_authority_4   =  '',
   			@w_tax_authority_5   =  '',
   			@w_work_resident_status_code_2   =  '',
   			@w_work_resident_status_code_3   =  '',
   			@w_work_resident_status_code_4   =  '',
   			@w_work_resident_status_code_5   =  '',
   			@w_user_amt_1   =  '0',
   			@w_user_amt_2   =  '0',
   			@w_user_code_1   =  '',
   			@w_user_code_2   =  '',
   			@w_user_date_1   =  '29991231',
   			@w_user_date_2   =  '29991231',
   			@w_user_ind_1   =  'N',
   			@w_user_ind_2   =  'N',
   			@w_user_monetary_amt_1   =  '0',
   			@w_user_monetary_amt_2   =  '0',
   			@w_user_monetary_curr_code   =  'XCD',
   			@w_user_text_1   =  '',
   			@w_user_text_2   =  '',
   			@w_inc_tax_calc_method   =  '2',
   			@w_ei_status_code   =  '2',
   			@w_ppip_status_code   =  '1',
   			@w_fed_pp_stat_code   =  '2',
   			@w_provincial_pp_stat_code   =  '1',
   			@w_income_tax_stat_code   =  '2',
   			@w_pit_stat_code   =  '1',
   			@w_pay_element_ctrl_grp   =  '',
   			@w_emp_workers_comp_class   =  '',
   			@w_empl_addr_fmt_code   =  'GN2',
   			@w_empl_phone_fmt_code   =  'L34',
   			@w_empl_phone_delimiter   =  '-',
   			@w_empl_recruitment_zone_code   =  '',
   			@w_empl_cma_code   =  '',
   			@w_empl_industry_sector_code   =  '',
   			@w_empl_province_terr_code   =  '',
   			@w_eeo_4_agency_function_code   =  '99',
   			@w_eeo_establishment_id   =  '0714',
   			@w_assignment_end_date   =  '12/31/2999',
   			@w_location_code   =  '',
   			@w_salary_structure_id   =  '',
   			@w_salary_incr_guideline_id   =  '',
   			@w_pay_grade_code   =  'E40',
   			@w_job_evaluation_points_nbr   =  '0',
   			@w_salary_step_nbr   =  '0',
   			@w_employer_taxing_ctry_code   =  'GD',
   			@w_organization_group_id   =  '5',
   			@w_wage_plan_code   =  '',
   			@w_emp_health_insurance_cvg_cd   =  '',
   			@w_tax_auth_type_code   =  '',
   			@w_tax_auth_type_code_2   =  '',
   			@w_tax_auth_type_code_3   =  '',
   			@w_tax_auth_type_code_4   =  '',
   			@w_tax_auth_type_code_5   =  '',
   			@w_reg_reporting_unit_code   =  '',
   			@w_emp_workers_comp_cvg_cd		=  ''
   			     

SET @cnt = 1

SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_employee_events_temp1

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
	  FROM DBShrpn.dbo.ghr_employee_events_temp1 t WHERE t.ID = @cnt
	  
--
--	This section will validate the interface data
-- 
  
--
-- Check to see if the employee exists
--	 
 
	IF  EXISTS (SELECT * FROM DBShrpn.dbo.employee WHERE emp_id = @emp_id_01)
		BEGIN
			 UPDATE	DBShrpn.dbo.ghr_employee_events_aud
			    SET activity_status	=	'01'					
			  WHERE activity_date	=	@p_activity_date
			    AND emp_id_01		=	@emp_id_01
			    AND event_id_01		=	'01'
			 		 
			 INSERT INTO DBShrpn.dbo.ghr_msg_tbl
			 SELECT 'U00003'					As msg_id,
					@emp_id_01					As msg_p1,
					''							As msg_p2,
					'Total nbr of employee already exists'	As msg_desc
			
			-- Historical Message for reporting purpose	
			INSERT INTO DBShrpn.dbo.ghr_historical_message	
			SELECT  'U00003'					As msg_id,
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
			 
--			 GOTO BYPASS_EMPLOYEE 
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
			   AND event_id_01		=	'01'			   
			 
			 INSERT INTO DBShrpn.dbo.ghr_msg_tbl
			 SELECT 'U00005'					As msg_id,
					@emp_id_01					As msg_p1,
					@empl_id_01					As msg_p2,
					'Employer does not exists - defaulting 99999'	As msg_desc
			 
			 -- Historical Message for reporting purpose	
			INSERT INTO DBShrpn.dbo.ghr_historical_message	
			SELECT  'U00005'					As msg_id,
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
   		
--
-- Check for the exists of the national id
--

IF	(@national_id_1_01 = '')
	BEGIN
		UPDATE DBShrpn.dbo.ghr_employee_events_aud
		SET activity_status	=	'02'					
		WHERE activity_date	=	@p_activity_date
		AND emp_id_01		=	@emp_id_01
		AND event_id_01		=	'01'			   
			 
		INSERT INTO DBShrpn.dbo.ghr_msg_tbl
		SELECT 'U00046'						As msg_id,
				@emp_id_01					As msg_p1,
				@national_id_1_01			As msg_p2,
				'NIS nbr is blank - defaulting 99999'  As msg_desc
					
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
			IF  EXISTS (SELECT * FROM [DBShrpn].[dbo].individual_personal e
						WHERE e.national_id_1 = @national_id_1_01)
				BEGIN
					UPDATE DBShrpn.dbo.ghr_employee_events_aud
					SET activity_status	=	'02'					
					WHERE activity_date	=	@p_activity_date
					AND emp_id_01		=	@emp_id_01
					AND event_id_01		=	'01'			   
			 
					INSERT INTO DBShrpn.dbo.ghr_msg_tbl
					SELECT 'U00006'						As msg_id,
							@emp_id_01					As msg_p1,
							@national_id_1_01			As msg_p2,
							'NIS nbr already exists - defaulting 99999'  As msg_desc
					
					-- Historical Message for reporting purpose	
					INSERT INTO DBShrpn.dbo.ghr_historical_message	
					SELECT  'U00006'					As msg_id,
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
/*
	IF	(@national_id_1_01 <> '' OR @national_id_1_01 <> '99999')
		BEGIN
			IF  EXISTS (SELECT * FROM [DBShrpn].[dbo].individual_personal e
						WHERE e.national_id_1 = @national_id_1_01)
				BEGIN
					UPDATE DBShrpn.dbo.ghr_employee_events_aud
					SET activity_status	=	'02'					
					WHERE activity_date	=	@p_activity_date
					AND emp_id_01		=	@emp_id_01
					AND event_id_01		=	'01'			   
			 
					INSERT INTO DBShrpn.dbo.ghr_msg_tbl
					SELECT 'U00006'						As msg_id,
							@emp_id_01					As msg_p1,
							@national_id_1_01			As msg_p2,
							'NIS nbr already exists - defaulting 99999'  As msg_desc
					
					-- Historical Message for reporting purpose	
					INSERT INTO DBShrpn.dbo.ghr_historical_message	
					SELECT  'U00006'					As msg_id,
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
		ELSE
			SELECT @national_id_1_01 = '99999'
		END
*/
--
-- Check to see if the national id is blank
--
		
	IF  (@national_id_1_01 = '' or @national_id_1_01 = NULL)
		BEGIN
			UPDATE DBShrpn.dbo.ghr_employee_events_aud
			   SET activity_status	=	'02'					
			 WHERE activity_date	=	@p_activity_date
			   AND emp_id_01		=	@emp_id_01
			   AND event_id_01		=	'01'			   
			 
			 INSERT INTO DBShrpn.dbo.ghr_msg_tbl
			 SELECT 'U00007'					As msg_id,
					@emp_id_01					As msg_p1,
					''							As msg_p2,
					'NIS nbr was blank - defaulting 99999'  As msg_desc
					
			-- Historical Message for reporting purpose	
			INSERT INTO DBShrpn.dbo.ghr_historical_message	
			SELECT  'U00007'					As msg_id,
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
		
--
-- Check to see if the unit name exists in the structure table
--


	IF NOT EXISTS (SELECT p.NAME FROM [DBSosst].[dbo].[SRG_STRUCTURE] s
				 INNER JOIN [DBSosst].[dbo].[SRG_POINT] p
					ON p.[GROUP_ID]		= s.[GROUP_ID]
				   AND p.[STRUCTURE_ID]	= s.[STRUCTURE_ID]
					  WHERE s.[NAME] =  @organization_chart_name_01
						AND p.[NAME] =	@organization_unit_name_01)
		BEGIN
			UPDATE DBShrpn.dbo.ghr_employee_events_aud
			   SET activity_status	=	'02'					
			 WHERE activity_date	=	@p_activity_date
			   AND emp_id_01		=	@emp_id_01
			   AND event_id_01		=	'01'			   
			 
			 INSERT INTO DBShrpn.dbo.ghr_msg_tbl
			 SELECT 'U00008'					As msg_id,
					@emp_id_01					As msg_p1,
					@organization_unit_name_01	As msg_p2,
					'Unit name was missing - defaulting 99999'  As msg_desc
					
			-- Historical Message for reporting purpose	
			INSERT INTO DBShrpn.dbo.ghr_historical_message	
			SELECT  'U00008'					As msg_id,
					'01'						As event_id,
					@emp_id_01 					As emp_id,
					@eff_date_01				As eff_date,
					@pay_element_desc_06		As pay_element_id,						
					@emp_id_01					As msg_p1,
					@organization_unit_name_01	As msg_p2,
					'Unit name was missing - defaulting 99999'	As msg_desc,
					@p_activity_date			AS activity_date
			-- End of Historical Message for reporting purpose						
					
			SELECT @organization_unit_name_01 = '99999'					
		END
--
--	Check to see if pay group id exists
--
	IF NOT EXISTS(SELECT * FROM	[DBShrpn].[dbo].[pay_group] WHERE	pay_group_id   = @pay_group_id_03)
	BEGIN
				
		UPDATE	DBShrpn.dbo.ghr_employee_events_aud
		   SET activity_status	=	'02'					
		 WHERE activity_date	=	@p_activity_date
		   AND emp_id_01		=	@emp_id_01
		   AND event_id_01		=	'01'		   
			 		 
		INSERT INTO DBShrpn.dbo.ghr_msg_tbl
			 SELECT 'U00020'					As msg_id,
					@emp_id_01					As msg_p1,
					@pay_group_id_03			As msg_p2,
					'Pay Group does not exists'	As msg_desc
					
			-- Historical Message for reporting purpose	
			INSERT INTO DBShrpn.dbo.ghr_historical_message	
			SELECT  'U00020'					As msg_id,
					'01'						As event_id,
					@emp_id_01 					As emp_id,
					@eff_date_01				As eff_date,
					@pay_element_desc_06		As pay_element_id,						
					@emp_id_01					As msg_p1,
					@pay_group_id_03			As msg_p2,
					'Pay Group does not exists'	As msg_desc,
					@p_activity_date			AS activity_date
			-- End of Historical Message for reporting purpose										
					
		SELECT	@pay_group_id_03 = ' '
		
		SELECT  @w_fatal_error = '5'
	END
			
--
--	Check to see if the pay element control group is blank, If blank add 99999
--	
	
	IF  (@pay_element_ctrl_grp_id_03 = '' or @pay_element_ctrl_grp_id_03 = NULL or @pay_element_ctrl_grp_id_03 = ' ')
		BEGIN
				
			UPDATE DBShrpn.dbo.ghr_employee_events_aud 
			   SET activity_status	=	'02'					
			 WHERE activity_date	=	@p_activity_date
			   AND emp_id_01		=	@emp_id_01
			   AND event_id_01		=	'01'			   
			 
			 INSERT INTO DBShrpn.dbo.ghr_msg_tbl
			 SELECT 'U00031'					As msg_id,
					@emp_id_01					As msg_p1,
					@emp_id_01					As msg_p2,
					'Pay Element Group Control was blank for employee'  As msg_desc
					
			-- Historical Message for reporting purpose	
			INSERT INTO DBShrpn.dbo.ghr_historical_message	
			SELECT  'U00031'					As msg_id,
					'01'						As event_id,
					@emp_id_01 					As emp_id,
					@eff_date_01				As eff_date,
					@pay_element_desc_06		As pay_element_id,						
					@emp_id_01					As msg_p1,
					@pay_element_ctrl_grp_id_03	As msg_p2,
					'Pay Element Group Control was blank for employee'	As msg_desc,
					@p_activity_date			AS activity_date
			-- End of Historical Message for reporting purpose					
					
			SELECT @pay_element_ctrl_grp_id_03 = ' '					
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
		   AND event_id_01		=	'01'		   
			 		 
		INSERT INTO DBShrpn.dbo.ghr_msg_tbl
			 SELECT 'U00021'					As msg_id,
					@emp_id_01					As msg_p1,
					@pay_element_ctrl_grp_id_03	As msg_p2,
					'Pay Element Control Group does not exists'	As msg_desc
					
			-- Historical Message for reporting purpose	
			INSERT INTO DBShrpn.dbo.ghr_historical_message	
			SELECT  'U00021'					As msg_id,
					'01'						As event_id,
					@emp_id_01 					As emp_id,
					@eff_date_01				As eff_date,
					@pay_element_desc_06		As pay_element_id,						
					@emp_id_01					As msg_p1,
					@pay_element_ctrl_grp_id_03	As msg_p2,
					'Pay Element Control Group does not exists'	As msg_desc,
					@p_activity_date			AS activity_date
			-- End of Historical Message for reporting purpose						
					
		SELECT	@pay_element_ctrl_grp_id_03 = ' '
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
		   AND event_id_01		=	'01'		   
			 		 
		INSERT INTO DBShrpn.dbo.ghr_msg_tbl
			 SELECT 'U00048'					As msg_id,
					@pay_group_id_03			As msg_p1,
					@emp_id_01              	As msg_p2,
					'After April 1, 2023,Pay Group, @1, must be semi-monthly.'	As msg_desc
					
			-- Historical Message for reporting purpose	
			INSERT INTO DBShrpn.dbo.ghr_historical_message	
			SELECT  'U00048'					As msg_id,
					'01'						As event_id,
					@emp_id_01 					As emp_id,
					@eff_date_01				As eff_date,
					@pay_element_desc_06		As pay_element_id,						
					@pay_group_id_03			As msg_p1,
					@emp_id_01              	As msg_p2,
					'After April 1, 2023,Pay Group, ' + RTRIM(@pay_group_id_03) + ' , must be semi-monthly.'	As msg_desc,
					@p_activity_date			AS activity_date
			-- End of Historical Message for reporting purpose						
					
		IF GETDATE() > '20230331' SELECT	@w_fatal_error = '5'
		
	END
	
	
   	IF  @w_fatal_error = '5' GOTO BYPASS_EMPLOYEE

	
--
--	Setup Section
--

--
--	Default the correct job or possition code based on the type of employee
--
	IF EXISTS(SELECT * FROM DBShrpn.dbo.employer WHERE empl_id = @empl_id_01 AND name like 'Pen%')
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
  FROM [DBShrpn].[dbo].[empl_tax_entity] WHERE [empl_id] = @empl_id_01
  
--
-- Check to see if the person is over 16 years of age
--
				
--
-- Opbtain the next individual number
--

	SELECT @ind_idx = CONVERT(char(10),gen_indiv_id_last_nbr + 1) FROM DBSentp.dbo.entp_human_resources_plcy  with (holdlock)
  
	UPDATE DBSentp.dbo.entp_human_resources_plcy
	   SET gen_indiv_id_last_nbr = CONVERT(float,@ind_idx)
	 WHERE display_name_format = 'LNMCOMFNMFMNSMN'
			
SELECT @annual_salary = CAST(@annual_salary_amt_01 As Money)
SELECT @display_name = RTRIM(@last_name_01) + ', ' + RTRIM(@first_name_01)
					 
EXEC [DBShrpn].[dbo].[usp_ins_hemp] @empl_id_01,
   @emp_id_01,
   @ind_idx,
   @eff_date_01,
   @first_name_01,
   @first_middle_name_01,
   @last_name_01,
   @w_preferred_name,
   @w_name_suffix,
   @display_name,
   @w_birth_date,
   @w_sex_code,
   @w_marital_status_code_1,
   @national_id_1_type_code_01,
   @national_id_1_01,
   @w_addr_1_type_code,
   @w_addr_1_fmt_code,
   @w_addr_1_line_1,
   @w_addr_1_line_2,
   @w_addr_1_line_3,
   @w_addr_1_line_4,
   @w_addr_1_line_5,
   @w_addr_1_street_or_pob_1,
   @w_addr_1_street_or_pob_2,
   @w_addr_1_street_or_pob_3,
   @w_addr_1_city_name,
   @w_addr_1_ctry_sub_entity_code,
   @w_addr_1_postal_code,
   @w_addr_1_country_code,
   @w_assigned_to_code,
   @w_job_or_pos_id,
   @organization_chart_name_01,
   @organization_unit_name_01,
   @emp_status_classn_code_01,
   @w_active_reason_code,
   @employment_type_code_01,
   @w_professional_cat_code,
   @w_labor_grp_code,
   @w_non_employee_indicator,
   @w_excluded_from_payroll_ind,
   @w_pensioner_indicator,
   @w_provided_i_9_ind,
   @w_base_rate_tbl_id,
   @w_base_rate_tbl_entry_code,
   @w_exception_rate_ind,
   @w_hourly_pay_rate,
   @w_pd_salary_amt,
   @w_pd_salary_tm_pd_id,
   @annual_salary,
   @w_pay_basis_code,
   @w_curr_code,
   @w_work_tm_code,
   @w_standard_daily_work_hrs,
   @w_standard_work_hrs,
   @w_standard_work_pd_id,
   @w_overtime_status_code,
   @w_pay_on_reported_hrs_ind,
   @w_work_shift_code, 
   @tax_entity_id,
   @time_reporting_meth_code_03,
   @pay_group_id_03,
   @w_clock_nbr,
   @w_prim_disbursal_loc_code,
   @w_alt_disbursal_loc_code,
   @w_tax_marital_status_code,
   @w_fui_status_code,
   @w_oasdi_status_code,
   @w_medicare_status_code,
   @w_income_tax_nbr_of_exemps,
   @w_tax_authority_id,
   @w_work_resident_status_code,
   @w_income_tax_calc_meth_cd,
   @w_tax_authority_2,
   @w_tax_authority_3,
   @w_tax_authority_4,
   @w_tax_authority_5,
   @w_work_resident_status_code_2,
   @w_work_resident_status_code_3,
   @w_work_resident_status_code_4,
   @w_work_resident_status_code_5,
   @w_user_amt_1,
   @w_user_amt_2,
   @w_user_code_1,
   @w_user_code_2,
   @w_user_date_1,
   @w_user_date_2,
   @w_user_ind_1,
   @w_user_ind_2,
   @w_user_monetary_amt_1,
   @w_user_monetary_amt_2,
   @w_user_monetary_curr_code,
   @w_user_text_1,
   @w_user_text_2,
   @w_inc_tax_calc_method,
   @w_ei_status_code,
   @w_ppip_status_code,
   @w_fed_pp_stat_code,
   @w_provincial_pp_stat_code,
   @w_income_tax_stat_code,
   @w_pit_stat_code,
   @pay_element_ctrl_grp_id_03,
   @w_emp_workers_comp_class,
   @w_empl_addr_fmt_code,
   @w_empl_phone_fmt_code,
   @w_empl_phone_delimiter,
   @w_empl_recruitment_zone_code,
   @w_empl_cma_code,
   @w_empl_industry_sector_code,
   @w_empl_province_terr_code,
   @w_eeo_4_agency_function_code,
   @w_eeo_establishment_id,
   @w_assignment_end_date,
   @w_location_code,
   @w_salary_structure_id,
   @w_salary_incr_guideline_id,
   @w_pay_grade_code,
   @w_job_evaluation_points_nbr,
   @w_salary_step_nbr,
   @w_employer_taxing_ctry_code,
   @organization_group_id_01,
   @w_wage_plan_code,
   @w_emp_health_insurance_cvg_cd,
   @w_tax_auth_type_code,
   @w_tax_auth_type_code_2,
   @w_tax_auth_type_code_3,
   @w_tax_auth_type_code_4,
   @w_tax_auth_type_code_5,
   @w_reg_reporting_unit_code,
   @w_emp_workers_comp_cvg_cd       

--

	SELECT	@i_emp_id				=	emp_id,
			@i_assigned_to_code		=	assigned_to_code,
			@i_job_or_pos_id		=	job_or_pos_id,
      		@i_eff_date				=	eff_date,
			@i_next_eff_date		=	next_eff_date,
			@i_prior_eff_date		=	prior_eff_date,
			@i_standard_work_pd_id	=	standard_work_pd_id,
			@i_standard_work_hrs	=	standard_work_hrs	
	  FROM	[DBShrpn].[dbo].[emp_assignment]	ea
	 WHERE	emp_id					=	@emp_id_01
	   and  eff_date				=	(SELECT	MAX(eff_date) FROM	[DBShrpn].[dbo].[emp_assignment] t
										  WHERE	t.emp_id =	ea.emp_id)
 
--	SELECT @pay_frequency_code	= pay_frequency_code
--      FROM [DBShrpn].[dbo].[pay_group] WHERE [pay_group_id] = @pay_group_id_03
       
      	 --- If blank, then default: SEMI ---
	 
	 IF @pay_frequency_code = ''	SELECT	@pay_frequency_code		=	'SEMI'      
 	  
	 IF	@pay_frequency_code	= 'WEEK'	SELECT @i_yearly_std_work_hrs	=	@i_standard_work_hrs * 52 
	 ELSE
	 IF	@pay_frequency_code	= 'BIWK'	SELECT @i_yearly_std_work_hrs	=	@i_standard_work_hrs * 26
	 ELSE
	 IF	@pay_frequency_code	= 'SEMI'	SELECT @i_yearly_std_work_hrs	=	@i_standard_work_hrs * 24	
	 ELSE 
	 IF	@pay_frequency_code	= 'MONTH'	SELECT @i_yearly_std_work_hrs	=	@i_standard_work_hrs * 12

	 SELECT	@i_hourly_rate_amt	=	CAST(@annual_salary AS MONEY) / @i_yearly_std_work_hrs
	 
	 IF	@pay_frequency_code	= 'WEEK'	SELECT @i_period_amt		=	CAST(@annual_salary_amt_01 AS MONEY) / 52
	 ELSE
	 IF	@pay_frequency_code	= 'BIWK'	SELECT @i_period_amt		=	CAST(@annual_salary_amt_01 AS MONEY) / 26
	 ELSE
	 IF	@pay_frequency_code	= 'SEMI'	SELECT @i_period_amt		=	CAST(@annual_salary_amt_01 AS MONEY) / 24
	 ELSE
	 IF	@pay_frequency_code	= 'MONTH'	SELECT @i_period_amt		=	CAST(@annual_salary_amt_01 AS MONEY) / 12
	 
	 UPDATE	[DBShrpn].[dbo].[emp_assignment]
		SET	annual_salary_amt	=	CAST(@annual_salary_amt_01 AS MONEY),
			hourly_pay_rate		=	@i_hourly_rate_amt,
			pd_salary_amt		=	@i_period_amt,
			pd_salary_tm_pd_id  = 	@pay_frequency_code
	  WHERE	emp_id				=	@i_emp_id
		AND	assigned_to_code	=	@i_assigned_to_code
		AND	job_or_pos_id		=	@i_job_or_pos_id	
		AND	eff_date			=	@i_eff_date 
		AND	next_eff_date		=	@i_next_eff_date
		AND	prior_eff_date		=	@i_prior_eff_date
		

	
	SELECT 	 @ee_emp_id			= [emp_id]
			,@ee_eff_date		= [eff_date]
			,@ee_next_eff_date	= [next_eff_date]
			,@ee_prior_eff_date = [prior_eff_date]
	  FROM	[DBShrpn].[dbo].[emp_employment] ee
     WHERE  emp_id		=	@emp_id_01
	   AND	eff_date	=	(SELECT	MAX(eff_date) FROM	[DBShrpn].[dbo].[emp_employment] t
										  WHERE	t.emp_id =	ee.emp_id)
--JAG										  
--    INSERT INTO DBShrpn.dbo.msgtbl SELECT '022 ' + @ee_emp_id + ' ' + CONVERT(CHAR(10), @ee_eff_date,112) + ' ' + CONVERT(CHAR(10), @ee_next_eff_date,112) + ' ' + CONVERT(CHAR(10), @ee_prior_eff_date,112)  AS  msg_text 										  
										  
	IF	@ee_next_eff_date <> '29991231'
		UPDATE	[DBShrpn].[dbo].[emp_employment]
		   SET  next_eff_date = '29991231'
		  FROM	[DBShrpn].[dbo].[emp_employment] ee
		WHERE  emp_id		=	@ee_emp_id
		  AND  eff_date	=	@ee_eff_date
		  
--
-- Update the position since could be a new position with a new hire
--
									  
	 SELECT @individual_id = individual_id FROM [DBShrpn].[dbo].[employee] WHERE emp_id = @emp_id_01
	 
	 UPDATE	[DBShrpn].[dbo].[individual_personal]
		SET	user_text_1		=	CAST(@position_title_01 AS CHAR(50))
	  WHERE individual_id	=	@individual_id 			

--

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
	
	BYPASS_EMPLOYEE:
				  
	SELECT @cnt = @cnt + 1
END  -- Error Loop

--
-- Notify the users of all the issues
--



--
-- Send notification of warning message U00000  -- < TOTAL TRANSACTIONS READ: >
--

SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd 
--  SELECT *
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00000'

SELECT @max = COUNT(*)  
--  SELECT *
  FROM DBShrpn.dbo.ghr_employee_events
 WHERE [event_id_01] = '01'
SELECT @maxx = CAST(@max As CHAR(06))
SELECT @special_value_exists = 0
SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)
SELECT @msg_id = 'U00000'

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
-- End of Sending notification of warning message U00000
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
 WHERE [event_id_01] = '01'
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
-- Send notification of warning message U00000  -- Total Global HR New Hire:
--

SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd 
--  SELECT *
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00001'
  
   SET @max = 0
SELECT @max = COUNT(*)  
--  SELECT *
  FROM DBShrpn.dbo.ghr_employee_events
 WHERE [event_id_01] = '01'
 
SELECT @maxx = CAST(@max As CHAR(06))
SELECT @special_value_exists = 0
SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)
SELECT @msg_id = 'U00001'

IF @special_value_exists <> 0 SELECT @w_msg_text = REPLACE(@w_msg_text,'@1',RTRIM(@maxx))  
SELECT @w_msg_text_2 = ''

IF @max <> 0
EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2 @p_userid,
    @p_batchname,
    @p_qualifier,
    @msg_id ,
    @w_severity_cd,
    @w_msg_text, 
    @w_msg_text_2,
    @w_msg_text_3  


--
-- Send notification of warning message U00003
--

SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd 
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00003'
  
SELECT @max		= 0
SELECT @max		= COUNT(*) FROM DBShrpn.dbo.ghr_msg_tbl WHERE msg_id = 'U00003'
SELECT @maxx	= CAST(@max AS CHAR(6))
 

SELECT @special_value_exists = 0
SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)

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
  
SELECT @cnt = @cnt + 1;

--
--	End of warning message U00003 
-- 

--
-- Send notification of warning message U00005
--
IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_message_temp_1]') AND type in (N'U'))
	DROP TABLE [dbo].[ghr_message_temp_1]


CREATE TABLE [dbo].[ghr_message_temp_1](
	[ID]							[int] IDENTITY(1,1) NOT NULL,
	[msg_id]						[char](15)	NOT NULL,
	[msg_p1]						[char](15)	NOT NULL,
	[msg_p2]						[char](15)	NOT NULL,
	[msg_desc]						[char](255) NOT NULL
)


SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
--  SELECT * 
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00005'

INSERT INTO DBShrpn.dbo.ghr_message_temp_1	
SELECT * 
  FROM DBShrpn.dbo.ghr_msg_tbl
 WHERE msg_id = 'U00005'
  
SET @cnt = 1

SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_1
 

WHILE (@cnt <= @max)
BEGIN

SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_1 t1 WHERE t1.[ID] = @cnt

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
--
-- Ending warning message U00005
--

--
-- Send notification of warning message U00006
--
IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_message_temp_1]') AND type in (N'U'))
	DROP TABLE [dbo].[ghr_message_temp_1]


CREATE TABLE [dbo].[ghr_message_temp_1](
	[ID]							[int] IDENTITY(1,1) NOT NULL,
	[msg_id]						[char](15)	NOT NULL,
	[msg_p1]						[char](15)	NOT NULL,
	[msg_p2]						[char](15)	NOT NULL,
	[msg_desc]						[char](255) NOT NULL
)

SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd 
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00006'

INSERT INTO DBShrpn.dbo.ghr_message_temp_1	
SELECT * 
  FROM DBShrpn.dbo.ghr_msg_tbl
 WHERE msg_id = 'U00006'
  
SET @cnt = 1

SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_1
 

WHILE (@cnt <= @max)
BEGIN

SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_1 t1 WHERE t1.[ID] = @cnt

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
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00006'
    
SELECT @cnt = @cnt + 1;

END
--
-- Ending warning message U00006
--

--
-- Send notification of warning message U00007
--
IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_message_temp_1]') AND type in (N'U'))
	DROP TABLE [dbo].[ghr_message_temp_1]


CREATE TABLE [dbo].[ghr_message_temp_1](
	[ID]							[int] IDENTITY(1,1) NOT NULL,
	[msg_id]						[char](15)	NOT NULL,
	[msg_p1]						[char](15)	NOT NULL,
	[msg_p2]						[char](15)	NOT NULL,
	[msg_desc]						[char](255) NOT NULL
)

SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd 
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00007'

INSERT INTO DBShrpn.dbo.ghr_message_temp_1	
SELECT * 
  FROM DBShrpn.dbo.ghr_msg_tbl
 WHERE msg_id = 'U00007'
  
SET @cnt = 1

SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_1
 

WHILE (@cnt <= @max)
BEGIN

SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_1 t1 WHERE t1.[ID] = @cnt

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
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00007'
    
SELECT @cnt = @cnt + 1;

END
--
-- Ending warning message U00007
--

--
-- Send notification of warning message U00008
--
IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_message_temp_1]') AND type in (N'U'))
	DROP TABLE [dbo].[ghr_message_temp_1]


CREATE TABLE [dbo].[ghr_message_temp_1](
	[ID]							[int] IDENTITY(1,1) NOT NULL,
	[msg_id]						[char](15)	NOT NULL,
	[msg_p1]						[char](15)	NOT NULL,
	[msg_p2]						[char](15)	NOT NULL,
	[msg_desc]						[char](255) NOT NULL
)

SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd 
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00008'

INSERT INTO DBShrpn.dbo.ghr_message_temp_1	
SELECT * 
  FROM DBShrpn.dbo.ghr_msg_tbl
 WHERE msg_id = 'U00008'
  
SET @cnt = 1

SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_1
 

WHILE (@cnt <= @max)
BEGIN

SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_1 t1 WHERE t1.[ID] = @cnt

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
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00008'
  
SELECT @cnt = @cnt + 1;

END -- End of Message Loop

--
-- Send notification of warning message U00031 -- Pay Element Group was blank for employee,@1 - defaulting 99999
--
IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_message_temp_1]') AND type in (N'U'))
	DROP TABLE [dbo].[ghr_message_temp_1]


CREATE TABLE [dbo].[ghr_message_temp_1](
	[ID]							[int] IDENTITY(1,1) NOT NULL,
	[msg_id]						[char](15)	NOT NULL,
	[msg_p1]						[char](15)	NOT NULL,
	[msg_p2]						[char](15)	NOT NULL,
	[msg_desc]						[char](255) NOT NULL
)

SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd 
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00031'

INSERT INTO DBShrpn.dbo.ghr_message_temp_1	
SELECT * 
  FROM DBShrpn.dbo.ghr_msg_tbl
 WHERE msg_id = 'U00031'
  
SET @cnt = 1

SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_1
 

WHILE (@cnt <= @max)
BEGIN

SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_1 t1 WHERE t1.[ID] = @cnt

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
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00031'
  
SELECT @cnt = @cnt + 1;

END -- End of Message Loop


--
-- Send notification of warning message U00020 -- Pay Group, @1, does not exists for employee, @2 - defaulting 99999
--
IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_message_temp_1]') AND type in (N'U'))
	DROP TABLE [dbo].[ghr_message_temp_1]


CREATE TABLE [dbo].[ghr_message_temp_1](
	[ID]							[int] IDENTITY(1,1) NOT NULL,
	[msg_id]						[char](15)	NOT NULL,
	[msg_p1]						[char](15)	NOT NULL,
	[msg_p2]						[char](15)	NOT NULL,
	[msg_desc]						[char](255) NOT NULL
)

SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd 
--	SELECT *
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00020'

INSERT INTO DBShrpn.dbo.ghr_message_temp_1	
SELECT * 
  FROM DBShrpn.dbo.ghr_msg_tbl
 WHERE msg_id = 'U00020'
  
SET @cnt = 1

SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_1
 

WHILE (@cnt <= @max)
BEGIN

SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_1 t1 WHERE t1.[ID] = @cnt

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
-- Send notification of warning message U00021 - Pay Element Control Group does not exists -defaulting 99999
--
IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_message_temp_1]') AND type in (N'U'))
	DROP TABLE [dbo].[ghr_message_temp_1]


CREATE TABLE [dbo].[ghr_message_temp_1](
	[ID]							[int] IDENTITY(1,1) NOT NULL,
	[msg_id]						[char](15)	NOT NULL,
	[msg_p1]						[char](15)	NOT NULL,
	[msg_p2]						[char](15)	NOT NULL,
	[msg_desc]						[char](255) NOT NULL
)

SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd 
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00021'

INSERT INTO DBShrpn.dbo.ghr_message_temp_1	
SELECT * 
  FROM DBShrpn.dbo.ghr_msg_tbl
 WHERE msg_id = 'U00021'
  
SET @cnt = 1

SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_1
 

WHILE (@cnt <= @max)
BEGIN

SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_1 t1 WHERE t1.[ID] = @cnt

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
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00021'
  
SELECT @cnt = @cnt + 1;

END -- End of Message Loop



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
INSERT INTO DBSosxp.dbo.msg SELECT 'End usp_ins_new_hire' AS msg_desc

/*

SELECT @p_status = 0

*/
END


--D4


/****** Object:  StoredProcedure [dbo].[usp_ins_pay_element]    Script Date: 8/26/2024 9:28:01 PM ******/
IF EXISTS (SELECT * FROM DBShrpn.dbo.sysobjects WHERE name = 'usp_ins_pay_element')
   DROP PROCEDURE [dbo].[usp_ins_pay_element]
 
GO
ALTER AUTHORIZATION ON [dbo].[usp_ins_new_hire] TO  SCHEMA OWNER 
GO
