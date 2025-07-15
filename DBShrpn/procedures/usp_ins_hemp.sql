USE [DBShrpn]
GO

SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO


CREATE procedure [dbo].[usp_ins_hemp]
(  @p_employer_id                          char(10),
   @p_employee_id                          char(15),
   @p_individual_id                        char(10),
   @p_original_hire_date                   datetime,
   @p_first_name                           char(25),
   @p_first_middle_name                    char(25),
   @p_last_name                            char(30),
   @p_preferred_name                       char(25),
   @p_name_suffix                          char(10),
   @p_emp_display_name                     char(45),
   @p_birth_date                           datetime,
   @p_sex_code                             char(1),
   @p_marital_status_code_1                char(5),
   @p_national_id_1_type_code              char(5),
   @p_national_id_1                        char(20),
   @p_addr_1_type_code                     char(5),
   @p_addr_1_fmt_code                      char(6),
   @p_addr_1_line_1                        char(35),
   @p_addr_1_line_2                        char(35),
   @p_addr_1_line_3                        char(35),
   @p_addr_1_line_4                        char(35),
   @p_addr_1_line_5                        char(35),
   @p_addr_1_street_or_pob_1               char(35),
   @p_addr_1_street_or_pob_2               char(35),
   @p_addr_1_street_or_pob_3               char(35),
   @p_addr_1_city_name                     char(35),
   @p_addr_1_ctry_sub_entity_code          char(9),
   @p_addr_1_postal_code                   char(9),
   @p_addr_1_country_code                  char(2),
   @p_assigned_to_code                     char(1),
   @p_job_or_pos_id                        char(10),
   @p_organization_chart_name              char(64),
   @p_organization_unit_name               char(240),
   @p_emp_status_classn_code               char(2),
   @p_active_reason_code                   char(5),
   @p_employment_type_code                 char(5),
   @p_professional_cat_code                char(5),
   @p_labor_grp_code                       char(5),
   @p_non_employee_indicator               char(1),
   @p_excluded_from_payroll_ind            char(1),
   @p_pensioner_indicator                  char(1),
   @p_provided_i_9_ind                     char(1),
   @p_base_rate_tbl_id                     char(10),
   @p_base_rate_tbl_entry_code             char(8),
   @p_exception_rate_ind                   char(1),
   @p_hourly_pay_rate                      float,
   @p_pd_salary_amt                        money,
   @p_pd_salary_tm_pd_id                   char(5),
   @p_annual_salary_amt                    money,
   @p_pay_basis_code                       char(1),
   @p_curr_code                            char(3),
   @p_work_tm_code                         char(1),
   @p_standard_daily_work_hrs              float,
   @p_standard_work_hrs                    float,
   @p_standard_work_pd_id                  char(5),
   @p_overtime_status_code                 char(2),
   @p_pay_on_reported_hrs_ind              char(1),
   @p_work_shift_code                      char(5),
   @p_tax_entity_id                        char(10),
   @p_time_reporting_meth_code             char(1),
   @p_pay_group_id                         char(10),
   @p_clock_nbr                            char(10),
   @p_prim_disbursal_loc_code              char(10),
   @p_alt_disbursal_loc_code               char(10),
   @p_tax_marital_status_code              char(1),
   @p_fui_status_code                      char(1),
   @p_oasdi_status_code                    char(1),
   @p_medicare_status_code                 char(1),
   @p_income_tax_nbr_of_exemps             smallint,
   @p_tax_authority_id                     char(10),
   @p_work_resident_status_code            char(1),
   @p_income_tax_calc_meth_cd              char(2),
   @p_tax_authority_2                      char(10),
   @p_tax_authority_3                      char(10),
   @p_tax_authority_4                      char(10),
   @p_tax_authority_5                      char(10),
   @p_work_resident_status_code_2          char(1),
   @p_work_resident_status_code_3          char(1),
   @p_work_resident_status_code_4          char(1),
   @p_work_resident_status_code_5          char(1),
   @p_user_amt_1                           float,
   @p_user_amt_2                           float,
   @p_user_code_1                          char(5),
   @p_user_code_2                          char(5),
   @p_user_date_1                          datetime,
   @p_user_date_2                          datetime,
   @p_user_ind_1                           char(1),
   @p_user_ind_2                           char(1),
   @p_user_monetary_amt_1                  money,
   @p_user_monetary_amt_2                  money,
   @p_user_monetary_curr_code              char(3),
   @p_user_text_1                          char(50),
   @p_user_text_2                          char(50),
   @p_inc_tax_calc_method                  char(2),
   @p_ei_status_code                       char(1),
   @p_ppip_status_code                     char(1),  /* 566986 */
   @p_fed_pp_stat_code                     char(1),
   @p_provincial_pp_stat_code              char(1),
   @p_income_tax_stat_code                 char(1),
   @p_pit_stat_code                        char(1),  /* R6.0 SSA 165213 */
   @p_pay_element_ctrl_grp                 char(10),
   @p_emp_workers_comp_class               char(1),     /* 719749-719473 */
   @p_empl_addr_fmt_code                   char(6),
   @p_empl_phone_fmt_code                  char(6),
   @p_empl_phone_delimiter                 char(1),
   @p_empl_recruitment_zone_code           char(5),
   @p_empl_cma_code                        char(2),
   @p_empl_industry_sector_code            char(5),
   @p_empl_province_terr_code              char(2),
   @p_eeo_4_agency_function_code           char(2),
   @p_eeo_establishment_id                 char(8),
   @p_assignment_end_date                  datetime,
   @p_location_code                        char(10),
   @p_salary_structure_id                  char(10),
   @p_salary_incr_guideline_id             char(10),
   @p_pay_grade_code                       char(6),
   @p_job_evaluation_points_nbr            smallint,
   @p_salary_step_nbr                      smallint,
   @p_employer_taxing_ctry_code            char(2),
   @p_organization_group_id                int,
   @p_wage_plan_code                       char(2),
   @p_emp_health_insurance_cvg_cd          char(2),
   @p_tax_auth_type_code                   char(1),
   @p_tax_auth_type_code_2                 char(1),
   @p_tax_auth_type_code_3                 char(1),
   @p_tax_auth_type_code_4                 char(1),
   @p_tax_auth_type_code_5                 char(1),
   @p_reg_reporting_unit_code              char(10),
   @p_emp_workers_comp_cvg_cd              char(1)
)
as

declare @ret int,
    @W_ACTION_DATETIME  char(30)

 -- exec @ret = sp_dbs_authenticate if @ret != 0 return

/* =================================== */
/*   ** Insert the INDIVIDUAL data    */
/* =================================== */
declare @w_return_code                          int,
   @w_autopay_rtn                          int,
   @w_autopay_pay_element_id               char(10),
   @w_start_date                           datetime,
   @w_stop_date                            datetime,
   @w_next_eff_date                        datetime,
   @w_occupancy_code         char(01),
   @w_pd_salary_tm_pd                      char(05),
   @w_date_in_grade                        datetime,
   @w_date_in_step                         datetime,
   @w_complete_ind                         char(01),
   @w_sui_state_1_ind                      char(01),
   @w_time_pct_1                           int,
   @w_sui_state_2_ind                      char(01),
   @w_time_pct_2                           int,
   @w_sui_state_3_ind                      char(01),
   @w_time_pct_3                           int,
   @w_sui_state_4_ind                      char(01),
   @w_time_pct_4                           int,
   @w_sui_state_5_ind                      char(01),
   @w_time_pct_5                           int,
   @w_inact_by_pay_element_ind             char(01),
   @w_sdi_status_code                  char(1),
   @w_can_tax_auth_complete                char(1),
   @w_language_code                        char(2),
   @w_auto_rt_tbl_id                       char(10)

declare    @W_ACTION_USER      char(30)

select @W_ACTION_USER = suser_sname()   /*jhess - changed for 8.0*/
declare @W_MS             char(3)
select @W_MS = convert (char(3), datepart(millisecond,getdate()))

if datalength(rtrim(@W_MS)) = 1
   begin
     select @W_MS = '00'+substring(@W_MS,1,1)
   end
else
   begin
     if datalength(rtrim(@W_MS)) = 2
        begin
          select @W_MS = '0'+substring(@W_MS,1,2)
        end
   end

select @W_ACTION_DATETIME = convert(char(10), getdate(), 111) + '-' +
                            convert(char(8), getdate(), 108) + ':' + @W_MS

if exists (select * from individual where individual_id = @p_individual_id)
   Begin
--SYBSQL      raiserror 26182 'individual id already exists'
          raiserror ('26182 individual id already exists',16,0)
     return
   end

select  @w_return_code = 0, @w_autopay_rtn = 0

if @p_time_reporting_meth_code = '1' and @p_pay_group_id <> ''
   begin
     Select @w_autopay_pay_element_id = pay_group.regular_earn_pay_element_id
       FROM pay_group
      where pay_group.pay_group_id = @p_pay_group_id

     SELECT @w_stop_date      = pay_element.stop_date,
            @w_start_date     = pay_element.start_date,
            @w_next_eff_date  = pay_element.next_eff_date,
            @w_auto_rt_tbl_id = rate_tbl_id
       FROM pay_element
      where pay_element.pay_element_id  = @w_autopay_pay_element_id and
            pay_element.stop_date       > @p_original_hire_date and
            (pay_element.eff_date      <= @p_original_hire_date and
             pay_element.next_eff_date  > @p_original_hire_date)

     if @@rowcount = 0
        begin
          if not exists (Select *
                           from pay_element
                          where pay_element.pay_element_id = @w_autopay_pay_element_id)
             begin
--SYBSQL                Raiserror 49717 'Database corrupt'
          raiserror ('49717 Database corrupt ',16,0)
               Return
             end
          else
            begin
              select @w_autopay_rtn = 49718
            end
        end

     if @w_stop_date = '12/31/2999'
        begin
          if @w_next_eff_date <> '12/31/2999'
             begin
               select @w_stop_date = pay_element.stop_date
                 from pay_element
                where pay_element.pay_element_id = @w_autopay_pay_element_id
                  and pay_element.next_eff_date  = '12/31/2999'
             end
        end

     if @w_stop_date = '12/31/2999'
        select @w_inact_by_pay_element_ind = 'N'
     else
        select @w_inact_by_pay_element_ind = 'Y'
   end
else
   select @w_autopay_pay_element_id = ''

select    @w_complete_ind    = 'N',
   @w_sui_state_1_ind = 'N',
   @w_time_pct_1       = 0,
   @w_sui_state_2_ind = 'N',
   @w_time_pct_2       = 0,
   @w_sui_state_3_ind = 'N',
   @w_time_pct_3       = 0,
   @w_sui_state_4_ind = 'N',
   @w_time_pct_4       = 0,
   @w_sui_state_5_ind = 'N',
   @w_time_pct_5       = 0

Select @w_can_tax_auth_complete = ' '

Select @w_language_code = default_language_code
  From employer
 where empl_id = @p_employer_id

if @p_employer_taxing_ctry_code = 'US'
   Execute usp_ins_hemp_04 @p_tax_authority_id,
                           @p_tax_authority_2,
                           @p_tax_authority_3,
                           @p_tax_authority_4,
                           @p_tax_authority_5,
                           @p_tax_auth_type_code,
                           @p_tax_auth_type_code_2,
                           @p_tax_auth_type_code_3,
                           @p_tax_auth_type_code_4,
                           @p_tax_auth_type_code_5,
                           @p_work_resident_status_code,
                           @p_work_resident_status_code_2,
                           @p_work_resident_status_code_3,
                           @p_work_resident_status_code_4,
                           @p_work_resident_status_code_5,
                           @w_complete_ind      OUTPUT,
                           @w_sui_state_1_ind   OUTPUT,
                           @w_time_pct_1        OUTPUT,
                           @w_sui_state_2_ind   OUTPUT,
                           @w_time_pct_2        OUTPUT,
                           @w_sui_state_3_ind   OUTPUT,
                           @w_time_pct_3        OUTPUT,
                           @w_sui_state_4_ind   OUTPUT,
                           @w_time_pct_4        OUTPUT,
                           @w_sui_state_5_ind   OUTPUT,
                           @w_time_pct_5        OUTPUT

if @p_employer_taxing_ctry_code = 'CA'
    if (rtrim(@p_tax_authority_id) IS NOT NULL AND rtrim(@p_tax_authority_id)!='')
        Select @w_can_tax_auth_complete = 'Y'
    else
        Select @w_can_tax_auth_complete = 'N'

begin transaction

/* ================================== */
/*   **  Insert the individual  data  */
/* ================================== */
insert into individual
       (individual_id,
   first_name,
   first_middle_name,
   second_middle_name,
   last_name,
   preferred_name,
   maiden_name,
   name_prefix,
   name_suffix,
   prior_last_name,
   pay_to_name,
   addr_1_line_1,
   addr_1_line_2,
   addr_1_line_3,
   addr_1_line_4,
   addr_1_line_5,
   addr_1_street_or_pob_1,
   addr_1_street_or_pob_2,
   addr_1_street_or_pob_3,
   addr_1_city_name,
   addr_1_country_sub_entity_code,
   addr_1_postal_code,
   addr_1_country_code,
   addr_1_fmt_code,
   addr_1_type_code,
   phone_fmt_delimiter,
   phone_1_intl_code,
   phone_1_country_code,
   phone_1_area_city_code,
   phone_1_nbr,
   phone_1_extension_nbr,
   phone_1_fmt_code,
   addr_2_line_1,
   addr_2_line_2,
   addr_2_line_3,
   addr_2_line_4,
   addr_2_line_5,
   addr_2_street_or_pob_1,
   addr_2_street_or_pob_2,
   addr_2_street_or_pob_3,
   addr_2_city_name,
   addr_2_country_sub_entity_code,
   addr_2_postal_code,
   addr_2_country_code,
   addr_2_fmt_code,
   addr_2_type_code,
   phone_2_intl_code,
   phone_2_country_code,
   phone_2_area_city_code,
   phone_2_nbr,
   phone_2_extension_nbr,
   phone_2_fmt_code,
   addr_3_line_1,
   addr_3_line_2,
   addr_3_line_3,
   addr_3_line_4,
   addr_3_line_5,
   addr_3_street_or_pob_1,
   addr_3_street_or_pob_2,
   addr_3_street_or_pob_3,
   addr_3_city_name,
   addr_3_country_sub_entity_code,
   addr_3_postal_code,
   addr_3_country_code,
   addr_3_fmt_code,
   addr_3_type_code,
   phone_3_intl_code,
   phone_3_country_code,
   phone_3_area_city_code,
   phone_3_nbr,
   phone_3_extension_nbr,
   phone_3_fmt_code,
   soundex_code,
   phone_1_unlisted_ind,
   phone_2_unlisted_ind,
   phone_3_unlisted_ind,
   phone_1_type_code,
   phone_2_type_code,
   phone_3_type_code,
   chgstamp)
values (@p_individual_id,
   @p_first_name,
   @p_first_middle_name,
   ' ',
   @p_last_name,
   @p_preferred_name,
   ' ',' ',
   @p_name_suffix,
   ' ',
   @p_emp_display_name,
   @p_addr_1_line_1,
   @p_addr_1_line_2,
   @p_addr_1_line_3,
   @p_addr_1_line_4,
   @p_addr_1_line_5,
   @p_addr_1_street_or_pob_1,
   @p_addr_1_street_or_pob_2,
   @p_addr_1_street_or_pob_3,
   @p_addr_1_city_name,
   @p_addr_1_ctry_sub_entity_code,
   @p_addr_1_postal_code,
   @p_addr_1_country_code,
   @p_addr_1_fmt_code,
   @p_addr_1_type_code,
   @p_empl_phone_delimiter,
   ' ',' ',' ',' ',' ',
   @p_empl_phone_fmt_code,
   ' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
   @p_empl_addr_fmt_code,
   ' ',' ',' ',' ',' ',' ',
   @p_empl_phone_fmt_code,
   ' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
   @p_empl_addr_fmt_code,
   ' ',' ',' ',' ',' ',' ',
   @p_empl_phone_fmt_code,
   ' ',
   'N',
   'N',
   'N',
   ' ',
   ' ',
   ' ',
   0)

if @@error <> 0
   begin
--SYBSQL      Raiserror 500001 'Error on Individual'
          raiserror ('500001 Error on Individual',16,0)
     rollback transaction
     return
   end

/* ==================================================================== */
/*   **  Insert the INDIVIDUAL_PERSONAL data                            */
/* ==================================================================== */
insert into individual_personal
  (individual_id,
   sex_code,
   birth_date,
   birth_country_code,
   native_language_code,
   preferred_language_code,
   ethnic_background_code,
   marital_status_code_1,
   marital_status_1_begin_date,
   marital_status_1_end_date,
   marital_status_code_2,
   marital_status_2_begin_date,
   marital_status_2_end_date,
   marital_status_code_3,
   marital_status_3_begin_date,
   marital_status_3_end_date,
   marital_status_code_4,
   marital_status_4_begin_date,
   marital_status_4_end_date,
   marital_status_code_5,
   marital_status_5_begin_date,
   marital_status_5_end_date,
   citizenship_country_code_1,
   citizenship_country_code_2,
   national_id_1,
   national_id_1_type_code,
   national_id_2,
   national_id_2_type_code,
   national_id_3,
   national_id_3_type_code,
   disabled_ind,
   disability_type_code,
   height,
   weight,
   vision_code,
   hair_color_code,
   eye_color_code,
   blood_type_code,
   blood_donor_ind,
   willing_to_travel_tm_pct,
   willing_to_relocate_ind,
   preferred_loc_code,
   military_status_code,
   military_branch_code,
   military_rank_code,
   military_discharge_date,
   military_comnt_text,
   reserve_status_code,
   reserve_branch_code ,
   reserve_rank_code,
   reserve_discharge_date,
   eea_aboriginal_ind,
   eea_aboriginal_type_code,
   eea_visible_minority_ind,
   eea_visible_minority_code,
   eea_disability_ind,
   eea_disability_code,
   eea_recruitment_zone_code,
   eea_cma_code,
   eea_industry_sector_code,
   eea_province_terr_code,
   eeo_race_code,
   eeo_veteran_status_code,
   exempt_from_eeo_reporting_ind,
   eeo_4_agency_function_code,
   eeo_establishment_id,
   education_1_institution_code,
   education_1_degree_code_1,
   unused_col_1,
   education_1_beginning_mon,
   education_1_beginning_yr,
   education_1_ending_mon,
   education_1_ending_yr,
   education_1_in_progress_ind,
   education_1_study_area_code_1,
   education_1_study_area_code_2,
   education_1_grade_point_avg,
   education_1_comnt_text,
   education_2_institution_code,
   education_2_degree_code_1,
   unused_col_2,
   education_2_beginning_mon,
   education_2_beginning_yr,
   education_2_ending_mon,
   education_2_ending_yr,
   education_2_in_progress_ind,
   education_2_study_area_code_1,
   education_2_study_area_code_2,
   education_2_grade_point_avg,
   education_2_comnt_text,
   ref_nbr,
   death_date,
   student_status_code,
   user_amt_1,
   user_amt_2,
   user_monetary_amt_1,
   user_monetary_amt_2,
   user_monetary_curr_code,
   user_code_1,
   user_code_2,
   user_date_1,
   user_date_2,
   user_ind_1,
   user_ind_2,
   user_text_1,
   user_text_2,
   smoker_ind,   /* A R6.5.02MC SOL520600 gmlls 01/20/2003 */
   chgstamp,             /* 1020838 */
   geo_code,             /* 1020838 */
   vets_100A_status_code /* 1020838 */)
values (
    @p_individual_id,   /*  individual_id, */
    @p_sex_code,        /*  sex_code, */
    @p_birth_date,      /*  birth_date, */
    ' ',                /*  birth_country_code, */
    ' ',                /*  native_language_code, */
    @w_language_code,   /*  preferred_language_code, */
    ' ',                /*  ethnic_background_code, */
    @p_marital_status_code_1,    /*  marital_status_code_1, */
    '12/31/2999',       /*  marital_status_1_begin_date, */
    '12/31/2999',       /*  marital_status_1_end_date, */
    ' ',                /*  marital_status_code_2, */
    '12/31/2999',       /*  marital_status_2_begin_date, */
    '12/31/2999',       /*  marital_status_2_end_date, */
    ' ',                /*  marital_status_code_3, */
    '12/31/2999',       /*  marital_status_3_begin_date, */
    '12/31/2999',       /*  marital_status_3_end_date, */
    ' ',                /*  marital_status_code_4, */
    '12/31/2999',       /*  marital_status_4_begin_date, */
    '12/31/2999',       /*  marital_status_4_end_date, */
    ' ',                /*  marital_status_code_5, */
    '12/31/2999',       /*  marital_status_5_begin_date, */
    '12/31/2999',       /*  marital_status_5_end_date, */
    ' ',                /*  citizenship_country_code_1, */
    ' ',                /*  citizenship_country_code_2, */
    @p_national_id_1,   /*  national_id_1, */
    @p_national_id_1_type_code,    /*  national_id_1_type_code, */
    ' ',                /*  national_id_2, */
    ' ',                /*  national_id_2_type_code, */
    ' ',                /*  national_id_3, */
    ' ',                /*  national_id_3_type_code, */
    'N',                /*  disabled_ind, */
    ' ',                /*  disability_type_code, */
    ' ',                /*  height, */
    ' ',                /*  weight, */
    ' ',                /*  vision_code, */
    ' ',                /*  hair_color_code, */
    ' ',                /*  eye_color_code, */
    'UN',               /*  blood_type_code, */
    'N',                /*  blood_donor_ind, */
    0,                  /*  willing_to_travel_tm_pct, */
    ' ',                /*  willing_to_relocate_ind, */
    ' ',                /*  preferred_loc_code, */
    ' ',                /*  military_status_code, */
    ' ',                /*  military_branch_code, */
    ' ',                /*  military_rank_code, */
    '12/31/2999',       /*  military_discharge_date, */
    ' ',                /*  military_comnt_text, */
    ' ',                /*  reserve_status_code, */
    ' ',                /*  reserve_branch_code , */
    ' ',                /*  reserve_rank_code, */
    '12/31/2999',       /*  reserve_discharge_date, */
    'N',                /*  eea_aboriginal_ind, */
    ' ',                /*  eea_aboriginal_type_code, */
    'N',                /*  eea_visible_minority_ind, */
    ' ',                /*  eea_visible_minority_code, */
    'N',                /*  eea_disability_ind, */
    ' ',                /*  eea_disability_code, */
    @p_empl_recruitment_zone_code,  /*  eea_recruitment_zone_code, */
    @p_empl_cma_code,               /*  eea_cma_code, */
    @p_empl_industry_sector_code,   /*  eea_industry_sector_code, */
    @p_empl_province_terr_code,     /*  eea_province_terr_code, */
    ' ',                /*  eeo_race_code, */
    '0',                /*  eeo_veteran_status_code, 1437601  */
    'N',                /*  exempt_from_eeo_reporting_ind, */
    @p_eeo_4_agency_function_code,  /*  eeo_4_agency_function_code, */
    @p_eeo_establishment_id,        /*  eeo_establishment_id, */
    ' ',                /*  education_1_institution_code, */
    ' ',                /*  education_1_degree_code_1, */
    ' ',                /*  unused_col_1, */
    0,                  /*  education_1_beginning_mon, */
    0,                  /*  education_1_beginning_yr, */
    0,                  /*  education_1_ending_mon, */
    0,                  /*  education_1_ending_yr, */
    'N',                /*  education_1_in_progress_ind, */
    ' ',                /*  education_1_study_area_code_1, */
    ' ',                /*  education_1_study_area_code_2, */
    0,                  /*  education_1_grade_point_avg, */
    ' ',                /*  education_1_comnt_text, */
    ' ',                /*  education_2_institution_code, */
    ' ',                /*  education_2_degree_code_1, */
    ' ',                /*  unused_col_2, */
    0,                  /*  education_2_beginning_mon, */
    0,                  /*  education_2_beginning_yr, */
    0,                  /*  education_2_ending_mon, */
    0,                  /*  education_2_ending_yr, */
    'N',                /*  education_2_in_progress_ind, */
    ' ',                /*  education_2_study_area_code_1, */
    ' ',                /*  education_2_study_area_code_2, */
    0,                  /*  education_2_grade_point_avg, */
    ' ',                /*  education_2_comnt_text, */
    ' ',                /*  ref_nbr, */
    '12/31/2999',       /*  death_date, */
    ' ',                /*  student_status_code, */
    0,                  /*  user_amt_1, */
    0,                  /*  user_amt_2, */
    0,                  /*  user_monetary_amt_1, */
    0,                  /*  user_monetary_amt_2, */
    ' ',                /*  user_monetary_curr_code, */
    ' ',                /*  user_code_1, */
    ' ',                /*  user_code_2, */
    '12/31/2999',       /*  user_date_1, */
    '12/31/2999',       /*  user_date_2, */
    'N',                /*  user_ind_1, */
    'N',                /*  user_ind_2, */
    ' ',                /*  user_text_1, */
    ' ',                /*  user_text_2, */
    'N',                /*  smoker_ind, */
    0,                  /*  chgstamp, */
    ' ',                /*  geo_code, */
    '0'                 /*  vets_100A_status_code 1437601  */
   )

if @@error <> 0
   begin
--SYBSQL      Raiserror 500002 'Error on Individual_personal'
          raiserror ('500002 Error on Individual_personal',16,0)
     rollback transaction
     return
   end

/* ==================================================================== */
/*   **  Insert the EMPLOYEE data                                       */
/* ==================================================================== */
insert into employee
   (emp_id,
   maintain_own_skills_ind,
   maintain_own_trng_rqst_ind,
   maintain_own_payroll_info_ind,
   requires_system_access_ind,
   system_user_id,
   electronic_mail_id,
   emp_display_name,
   individual_id,
   original_hire_date,
   adjusted_service_date,
   entp_hire_date,
   prior_emp_id,
   us_tax_auths_compl_ind,
   last_yr_paid,
   first_date_worked,
   last_date_for_which_paid,
   canadian_tax_auth_compl_ind,
   user_amt_1,
   user_amt_2,
   user_monetary_amt_1,
   user_monetary_amt_2,
   user_monetary_curr_code,
   user_code_1,
   user_code_2,
   user_date_1,
   user_date_2,
   user_ind_1,
   user_ind_2,
   user_text_1,
   user_text_2,
   chgstamp)
values (@p_employee_id,
   'N','N','N','N',
   ' ',' ',
   @p_emp_display_name,
   @p_individual_id,
   @p_original_hire_date,
   '12/31/2999',
   @p_original_hire_date,
   ' ',
   @w_complete_ind,
   0,
   @p_original_hire_date,
   '12/31/2999',
   @w_can_tax_auth_complete,
   0,0,0,0,
   ' ',' ',' ',
   '12/31/2999','12/31/2999',
   'N','N',
   ' ',' ',
   0)

if @@error <> 0
   begin
--SYBSQL      Raiserror 500003 'Error on Employee'
          raiserror ('500003 Error on Employee',16,0)
     rollback transaction
     return
   end

/*   Insert the emp_employment data  */
insert into emp_employment
   (emp_id,
   eff_date,
   next_eff_date,
   prior_eff_date,
   employment_type_code,
   work_tm_code,
   official_title_code,
   official_title_date,
   mgr_ind,
   recruiter_ind,
   pensioner_indicator,
   payroll_company_code,
   pmt_ctrl_code,
   us_federal_tax_meth_code,
   us_federal_tax_amt,
   us_federal_tax_pct,
   us_federal_marital_status_code,
   us_federal_exemp_nbr,
   us_work_st_code,
   canadian_work_province_code,
   ipp_payroll_id,
   ipp_max_pay_level_amt,
   pay_through_date,
   empl_id,
   tax_entity_id,
   pay_status_code,
   clock_nbr,
   provided_i_9_ind,
   time_reporting_meth_code,
   regular_hrs_tracked_code,
   pay_element_ctrl_grp_id,
   pay_group_id,
   us_pension_ind,
   professional_cat_code,
   corporate_officer_ind,
   prim_disbursal_loc_code,
   alternate_disbursal_loc_code,
   labor_grp_code,
   employment_info_chg_reason_cd,
   highly_compensated_emp_ind,
   nbr_of_dependent_children,
   canadian_federal_tax_meth_cd,
   canadian_federal_tax_amt,
   canadian_federal_tax_pct,
   canadian_federal_claim_amt,
   canadian_province_claim_amt,
   tax_unit_code,
   requires_tm_card_ind,
   xfer_type_code,
   tax_clear_code,
   pay_type_code,
   labor_distn_code,
   labor_distn_ext_code,
   us_fui_status_code,
   us_fica_status_code,
   payable_through_bank_id,
   disbursal_seq_nbr_1,
   disbursal_seq_nbr_2,
   non_employee_indicator,
   excluded_from_payroll_ind,
   emp_info_source_code,
   user_amt_1,
   user_amt_2,
   user_monetary_amt_1,
   user_monetary_amt_2,
   user_monetary_curr_code,
   user_code_1,
   user_code_2,
   user_date_1,
   user_date_2,
   user_ind_1,
   user_ind_2,
   user_text_1,
   user_text_2,
   t4_employ_code,         /* R6.0M - SSA# 23771 */
   chgstamp)
values (@p_employee_id,
   @p_original_hire_date,
   '12/31/2999','12/31/2999',
   @p_employment_type_code,
   @p_work_tm_code,
   ' ',
   '12/31/2999',
   'N','N',
   @p_pensioner_indicator,
   ' ',' ',' ',
   0,0,
   ' ',
   0,
   ' ',' ',' ',
   0,
   '12/31/2999',
   @p_employer_id,
   @p_tax_entity_id,
   '1',
   @p_clock_nbr,
   @p_provided_i_9_ind,
   @p_time_reporting_meth_code,
   '1',
   @p_pay_element_ctrl_grp,
   @p_pay_group_id,
   'N',
   @p_professional_cat_code,
   'N',
   @p_prim_disbursal_loc_code,
   @p_alt_disbursal_loc_code,
   @p_labor_grp_code,
   ' ',
   'N',
   0,
   ' ',
   0,0,0,0,
   ' ',
   'Y',
   ' ',' ',
   '1',
   ' ',' ',' ',' ',' ',' ',' ',
   @p_non_employee_indicator,
   @p_excluded_from_payroll_ind,
   '1',
   0,0,0,0,
   ' ',' ',' ',
   '12/31/2999','12/31/2999',
   'N','N',
   ' ',' ',
   ' ',         /* R6.0M - SSA# 23771 */
   0)

if @@error <> 0
   begin
--SYBSQL      Raiserror 500004 'Error on Emp_employment'
          raiserror ('500004 Error on Emp_employment',16,0)
     rollback transaction
     return
   end

/*   **  Insert the EMP_STATUS data   */
insert into emp_status
       (emp_id,
   status_change_date,
   prior_change_date,
   next_change_date,
   emp_status_code,
   emp_status_classn_code,
   inactive_reason_code,
   hire_date,
   loa_expected_return_date,
   consider_for_rehire_ind,
   active_reason_code,
   termination_reason_code,
   last_action_code,
   chgstamp)
values (@p_employee_id,
   @p_original_hire_date,
   '12/31/2999','12/31/2999',
   'A',
   @p_emp_status_classn_code,
   ' ',
   @p_original_hire_date,
   '12/31/2999',
   ' ',
   @p_active_reason_code,
   ' ',
   'HI',
   0)

if @@error <> 0
   begin
--SYBSQL      Raiserror 500005 'Error on Emp_status'
          raiserror ('500005 Error on Emp_status',16,0)
     rollback transaction
     return
   end

if (rtrim(@p_pay_grade_code) IS NOT NULL AND rtrim(@p_pay_grade_code)!='') or @p_job_evaluation_points_nbr <> 0
   select @w_date_in_grade = @p_original_hire_date
else
   select @w_date_in_grade = '12/31/2999'

if @p_salary_step_nbr <> 0
   select @w_date_in_step = @p_original_hire_date
else
   select @w_date_in_step = '12/31/2999'

/* ==================================================================== */
/*   **  Insert the emp_assignment data                                 */
/* ==================================================================== */
insert into emp_assignment
   (emp_id,
   assigned_to_code,
   job_or_pos_id,
   eff_date,
   next_eff_date,
   prior_eff_date,
   next_assigned_to_code,
   next_job_or_pos_id,
   prior_assigned_to_code,
   prior_job_or_pos_id,
   begin_date,
   end_date,
   assignment_reason_code,
   organization_chart_name,
   organization_unit_name,
   organization_group_id,
   organization_change_reason_cd,
   loc_code,
   mgr_emp_id,
   official_title_code,
   official_title_date,
   salary_change_date,
   annual_salary_amt,
   pd_salary_amt,
   pd_salary_tm_pd_id,
   hourly_pay_rate,
   curr_code,
   pay_on_reported_hrs_ind,
   salary_change_type_code,
   standard_work_pd_id,
   standard_work_hrs,
   work_tm_code,
   work_shift_code,
   salary_structure_id,
   salary_increase_guideline_id,
   pay_grade_code,
   pay_grade_date,
   job_evaluation_points_nbr,
   salary_step_nbr,
   salary_step_date,
   phone_1_type_code,
   phone_1_fmt_code,
   phone_1_fmt_delimiter,
   phone_1_intl_code,
   phone_1_country_code,
   phone_1_area_city_code,
   phone_1_nbr,
   phone_1_extension_nbr,
   phone_2_type_code,
   phone_2_fmt_code,
   phone_2_fmt_delimiter,
   phone_2_intl_code,
   phone_2_country_code,
   phone_2_area_city_code,
   phone_2_nbr,
   phone_2_extension_nbr,
   prime_assignment_ind,
   pay_basis_code,
   occupancy_code,
   regulatory_reporting_unit_code,
   base_rate_tbl_id,
   base_rate_tbl_entry_code,
   shift_differential_rate_tbl_id,
   ref_annual_salary_amt,
   ref_pd_salary_amt,
   ref_pd_salary_tm_pd_id,
   ref_hourly_pay_rate,
   guaranteed_annual_salary_amt,
   guaranteed_pd_salary_amt,
   guaranteed_pd_salary_tm_pd_id,
   guaranteed_hourly_pay_rate,
   exception_rate_ind,
   overtime_status_code,
   shift_differential_status_code,
   standard_daily_work_hrs,
   user_amt_1,
   user_amt_2,
   user_code_1,
   user_code_2,
   user_date_1,
   user_date_2,
   user_ind_1,
   user_ind_2,
   user_monetary_amt_1,
   user_monetary_amt_2,
   user_monetary_curr_code,
   user_text_1,
   user_text_2,
   unemployment_loc_code,
   include_salary_in_autopay_ind,
   chgstamp)
values (@p_employee_id,
   @p_assigned_to_code,
   @p_job_or_pos_id,
   @p_original_hire_date,
   '12/31/2999',
   '12/31/2999',
   ' ',
   ' ',
   ' ',
   ' ',
   @p_original_hire_date,
   @p_assignment_end_date,
   ' ',
   @p_organization_chart_name,
   @p_organization_unit_name,
   @p_organization_group_id,
   ' ',
   @p_location_code,
   ' ',
   ' ',
   '12/31/2999',
   '12/31/2999',
   @p_annual_salary_amt,
   @p_pd_salary_amt,
   @p_pd_salary_tm_pd_id,
   @p_hourly_pay_rate,
   @p_curr_code,
   @p_pay_on_reported_hrs_ind,
   ' ',
   @p_standard_work_pd_id,
   @p_standard_work_hrs,
   @p_work_tm_code,
   @p_work_shift_code,
   @p_salary_structure_id,
   @p_salary_incr_guideline_id,
   @p_pay_grade_code,
   @w_date_in_grade,
   @p_job_evaluation_points_nbr,
   @p_salary_step_nbr,
   @w_date_in_step,
   ' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
   'Y',
   @p_pay_basis_code,
   '3',
   @p_reg_reporting_unit_code,
   @p_base_rate_tbl_id,
   @p_base_rate_tbl_entry_code,
   ' ',
   0,0,
   ' ',
   0,0,0,
   ' ',
   0,
   @p_exception_rate_ind,
   @p_overtime_status_code,
   '99',
   @p_standard_daily_work_hrs,
   @p_user_amt_1,
   @p_user_amt_2,
   @p_user_code_1,
   @p_user_code_2,
   @p_user_date_1,
   @p_user_date_2,
   @p_user_ind_1,
   @p_user_ind_2,
   @p_user_monetary_amt_1,
   @p_user_monetary_amt_2,
   @p_user_monetary_curr_code,
   @p_user_text_1,
   @p_user_text_2,
   ' ', 'N',
   0)

if @@error <> 0
   begin
--SYBSQL      Raiserror 500006 'Error on Emp_assignment'
          raiserror ('500006 Error on Emp_assignment',16,0)
     rollback transaction
     return
   end

if @p_employer_taxing_ctry_code = 'US'
   if not exists (Select tax_authority_id
                    From empl_tax_entity_us_tax_auth
                   Where empl_id          = @p_employer_id   and
                         tax_entity_id    = @p_tax_entity_id and
                         tax_authority_id = 'USFED' and
                         tax_entity_us_tax_auth_stat_cd = '1')
      Select @w_autopay_rtn = 50437  /* 'USFED not established for employer tax entity' */
   else
      begin  /* 'USFED established for employer tax entity' */
        /* ==================================================================== */
        /*   **  Insert the emp_us_tax_authority data                           */
        /* ==================================================================== */
      insert into emp_us_tax_authority
      (emp_id,
      tax_entity_id,
      tax_authority_id,
      emp_us_tax_authority_status_cd,
      tax_marital_status_code,
      tm_worked_pct,
      work_resident_status_code,
      reciprocal_tax_authority_id,
      income_tax_calc_meth_cd,
      earned_income_cr_calc_meth_cd,
      income_tax_adj_code,
      income_tax_adj_amt,
      income_tax_adj_pct,
      income_tax_nbr_of_exemps,
      income_tax_nbr_of_pers_exemps,
      income_tax_nbr_of_depn_exemps,
      income_tax_nbr_exemps_over_65,
      income_tax_nbr_of_allowances,
      use_inc_tax_low_inc_tbls_ind,
      income_tax_blind_crs,
      income_tax_personal_exemp_amt,
      income_tax_senior_citizen_cr,
      oasdi_status_code,
      medicare_status_code,
      fui_status_code,
      sui_st_ind,
      resident_county_code,
      work_county_code,
      sui_status_code,
      sdi_status_code,
      other_st_tax_1_status_code,
      other_st_tax_2_status_code,
      other_st_tax_3_status_code,
      other_st_tax_4_status_code,
      other_st_tax_5_status_code,
      wage_plan_code,
      emp_health_insurance_cvrg_cd,
      user_amt_1,
      user_amt_2,
      user_monetary_amt_1,
      user_monetary_amt_2,
      user_monetary_curr_code,
      user_code_1,
      user_code_2,
      user_date_1,
      user_date_2,
      user_ind_1,
      user_ind_2,
      user_text_1,
      user_text_2,
      emp_workers_comp_cvrg_cd,
      puerto_rico_resident_status_cd,
      allowances_based_on_ded_amt,
      az_income_tax_ovrd_opt_cd,
      chgstamp,
      us_resident_status_cd,  /* R7.0M-ALS#571102 */
      other_st_tax_1a_status_code,  /*593964-591400*/
      eic_nbr_of_children,          /*651802-614209*/
      hire_act_status_code           /* hire_act_status_code 703950 */
     ,visa_type                     /* 1545169 */
     )
      values (@p_employee_id,
      @p_tax_entity_id,
      'USFED',
      '1',
      @p_tax_marital_status_code,
      0,
      ' ',' ',
      @p_income_tax_calc_meth_cd,
      '0',
      '1',
      0,0,
      @p_income_tax_nbr_of_exemps,
      0,0,0,0,
      ' ',
      0,0,0,
      @p_oasdi_status_code,
      @p_medicare_status_code,
      @p_fui_status_code,
      ' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
           ' ',' ',
      0,0,0,0,
      ' ',' ',' ',
      '12/31/2999','12/31/2999',
      'N','N',
      ' ',' ',
      ' ',' ',
      0,'9',0,
      '0','1',   /*593964-591400*/ /* us_resident_status_cd */ /* R7.0M-ALS#571102 */
      0,         /*651802-614209*/
     '0'  /* hire_act_status_code 703950 */
    ,'0'  /* visa_type 1545169 */
    )


   if @@error <> 0
           begin
--SYBSQL              Raiserror 500007 'Error on emp_us_tax_authority for FED'
          raiserror ('500007 Error on emp_us_tax_authority for FED',16,0)
             rollback transaction
             return
           end

        declare @w_tax_marital_status_code    char(1),
           @w_wage_plan_code               char(2),
           @w_emp_health_ins_cvg_cd        char(2),
           @w_emp_workers_comp_cvg_cd      char(1),
           @w_emp_workers_comp_class       char(1), /* 719749-719473 */
           @w_other_st_tax_1_status_cd     char(1),
           @w_other_st_tax_1a_status_cd    char(1), /*593964-591400*/
           @w_other_st_tax_2_status_cd     char(1),
           @w_other_st_tax_3_status_cd     char(1),
           @w_other_st_tax_4_status_cd     char(1),
           @w_pr_resident_status_cd        char(1),
           @w_allow_based_on_ded_amt       money

    if (rtrim(@p_tax_authority_id) IS NOT NULL AND rtrim(@p_tax_authority_id)!='')
         begin
            select @w_tax_marital_status_code = @p_tax_marital_status_code
            if @w_tax_marital_status_code = '2'
           begin
             if @p_tax_authority_id = 'GA' or
                @p_tax_authority_id = 'DC' or
                @p_tax_authority_id = 'DE'
                  select @w_tax_marital_status_code = '4'
                  else if @p_tax_authority_id = 'WV'                 /* r71m-sol#582345 */
                  select @w_tax_marital_status_code = '6'      /* r71m-sol#582345 */
           end
             else                                                    /* r71m-sol#582345 */
              begin                                                  /* r71m-sol#582345 */
               if @p_tax_authority_id = 'WV'                         /* r71m-sol#582345 */
                  select @w_tax_marital_status_code = '6'            /* r71m-sol#582345 */
              end                                                    /* r71m-sol#582345 */

            IF @p_tax_authority_id = 'CA' or
           @p_tax_authority_id = 'HI' or
           @p_tax_authority_id = 'NY' or
           @p_tax_authority_id = 'RI' or
           @p_tax_authority_id = 'NJ'
             select @w_sdi_status_code = '2'
          ELSE
                select @w_sdi_status_code = '1'

            if @p_tax_authority_id = 'NJ'
             begin
             select @w_other_st_tax_1_status_cd  = '2'
                  select @w_other_st_tax_1a_status_cd = '2' /*593964-591400*/
            select @w_other_st_tax_2_status_cd = '2'
             select @w_other_st_tax_3_status_cd = '2'
             select @w_other_st_tax_4_status_cd = '2'
             end
            else
             if @p_tax_authority_id = 'MT'
               begin
                  select @w_other_st_tax_1_status_cd = '2'
                     select @w_other_st_tax_1a_status_cd = '1' /*593964-591400*/
               select @w_other_st_tax_2_status_cd = '2'
                  select @w_other_st_tax_3_status_cd = ' '
                  select @w_other_st_tax_4_status_cd = ' '
               end
              else
           if @p_tax_authority_id = 'MA'
                 begin
           select @w_other_st_tax_1_status_cd = ' '
                     select @w_other_st_tax_1a_status_cd = '1' /*593964-591400*/
               select @w_other_st_tax_2_status_cd = '2'
                    select @w_other_st_tax_3_status_cd = ' '
                    select @w_other_st_tax_4_status_cd = ' '
                 end
             else
              begin
                 select @w_other_st_tax_1_status_cd = ' '
                  select @w_other_st_tax_1a_status_cd = '1' /*593964-591400*/
             select @w_other_st_tax_2_status_cd = ' '
                 select @w_other_st_tax_3_status_cd = ' '
                 select @w_other_st_tax_4_status_cd = ' '
              end

             select @p_income_tax_calc_meth_cd = '01' /* 1055162 */
             if @p_tax_authority_id = 'PR'
			  begin                                   /* 1055162 */
               Select @w_pr_resident_status_cd = '1'  /* 1055162,  @p_income_tax_calc_meth_cd = '11' */
			  end                                     /* 1055162 */
             else
			  begin                                   /* 1055162 */
			   Select @w_pr_resident_status_cd = ' '  /* 1055162, @p_income_tax_calc_meth_cd = '01' */
              end                                     /* 1055162 */

             /* 1017861 begin */
             if substring(@p_tax_authority_id, 1, 3) = 'PAL' or
                substring(@p_tax_authority_id, 1, 3) = 'PLS'
             begin
              select @p_income_tax_calc_meth_cd = '03'
             end
             /* 1017861 end */

             Select @w_allow_based_on_ded_amt = 0

             if @p_tax_authority_id = 'CA'
               select @w_wage_plan_code = @p_wage_plan_code
             else
              select @w_wage_plan_code = ' '

             if @p_tax_authority_id = 'OR' or @p_tax_authority_id = 'VT'   /* 583778 added VT */
               select @w_emp_health_ins_cvg_cd = @p_emp_health_insurance_cvg_cd
             else
               select @w_emp_health_ins_cvg_cd = ' '

             if @p_tax_authority_id = 'WY'
               begin
                 select @w_emp_workers_comp_cvg_cd = @p_emp_workers_comp_cvg_cd
                 select @w_emp_workers_comp_class  = @p_emp_workers_comp_class    /* 719749-719473 */
               end
             else
               begin
                 select @w_emp_workers_comp_cvg_cd = ' '
                 select @w_emp_workers_comp_class  = ' '                          /* 719749-719473 */
               end

        /*********************************************************************
            529378 - Add Employee Indiana Advance Earned Income Credit
        **********************************************************************/
      if @p_tax_authority_id = 'IN' or @p_tax_authority_id = 'WI' /*651802*/
       begin
            select @w_other_st_tax_1_status_cd = '1'
       end
      /*1545139 begin*/
	  else if @p_tax_authority_id = 'MI'
       begin
            select @w_other_st_tax_2_status_cd = '1'
       end
      /*1545139 end*/

         insert into emp_us_tax_authority
         (emp_id,
         tax_entity_id,
         tax_authority_id,
         emp_us_tax_authority_status_cd,
         tax_marital_status_code,
         tm_worked_pct,
         work_resident_status_code,
         reciprocal_tax_authority_id,
         income_tax_calc_meth_cd,
         earned_income_cr_calc_meth_cd,
         income_tax_adj_code,
         income_tax_adj_amt,
         income_tax_adj_pct,
         income_tax_nbr_of_exemps,
         income_tax_nbr_of_pers_exemps,
         income_tax_nbr_of_depn_exemps,
         income_tax_nbr_exemps_over_65,
         income_tax_nbr_of_allowances,
         use_inc_tax_low_inc_tbls_ind,
         income_tax_blind_crs,
         income_tax_personal_exemp_amt,
         income_tax_senior_citizen_cr,
         oasdi_status_code,
         medicare_status_code,
         fui_status_code,
         sui_st_ind,
         resident_county_code,
         work_county_code,
         sui_status_code,
         sdi_status_code,
         other_st_tax_1_status_code,
         other_st_tax_2_status_code,
         other_st_tax_3_status_code,
         other_st_tax_4_status_code,
         other_st_tax_5_status_code,
         wage_plan_code,
         emp_health_insurance_cvrg_cd,
         user_amt_1,
         user_amt_2,
         user_monetary_amt_1,
         user_monetary_amt_2,
         user_monetary_curr_code,
         user_code_1,
         user_code_2,
         user_date_1,
         user_date_2,
         user_ind_1,
         user_ind_2,
         user_text_1,
         user_text_2,
         emp_workers_comp_cvrg_cd,
         puerto_rico_resident_status_cd,
         allowances_based_on_ded_amt,
         az_income_tax_ovrd_opt_cd,
         chgstamp,
         us_resident_status_cd,  /* R7.0M-ALS#571102 */
         other_st_tax_1a_status_code,  /*593964-591400*/
         eic_nbr_of_children,          /*651802-614209*/
         hire_act_status_code,         /* hire_act_status_code 703950 */
         emp_workers_comp_class,       /* 719749-719473 */
         resident_psd,                  /* 1017861 - PA */
 		 add_vet_pers_exemps,	         /* 1055162 - PR */
         income_tax_nbr_joint_dep_exemp, /* 1055162 - PR */
         allowance_based_on_special_ded, /* 1055162 - PR */
         allowance_based_on_deds,	     /* 1055162 - PR */
		 rec_chg_ind                     /* 1024762 */
        ,visa_type                     /* 1545169 */
		 )
         values (@p_employee_id,
         @p_tax_entity_id,
         @p_tax_authority_id,
         '1',
         @w_tax_marital_status_code,
         @w_time_pct_1,
         @p_work_resident_status_code,
         ' ',
         @p_income_tax_calc_meth_cd,'0',
         '1',
         0,0,
         0,
         0,0,0,0,
         ' ',
         0,0,0,
         ' ',' ',' ',
         @w_sui_state_1_ind,
         ' ',' ',
         '2',
         @w_sdi_status_code,
         @w_other_st_tax_1_status_cd,
         @w_other_st_tax_2_status_cd,
         @w_other_st_tax_3_status_cd,
         @w_other_st_tax_4_status_cd,
         ' ',
         @w_wage_plan_code,
         @w_emp_health_ins_cvg_cd,
         0,0,0,0,
         ' ',' ',' ',
         '12/31/2999','12/31/2999',
         'N','N',
         ' ',' ',
         @w_emp_workers_comp_cvg_cd,
         @w_pr_resident_status_cd,
         0,'9',0,
         '0',                          /* us_resident_status_cd */ /* R7.0M-ALS#571102 */
         @w_other_st_tax_1a_status_cd, /*593964-591400*/
         0,                            /*651802-614209*/
         '',                           /* hire_act_status_code 703950 */
         @w_emp_workers_comp_class, ' ', 0,0,0,0,'N'  /* 719749-719473 */  /* 1017861 - PA */ /* 1055162 - PR added 4 0's */ /* 1024762 added 'N' */
        ,'0'                            /* visa_type  1545169 */
         )

        if @@error <> 0
      begin
--SYBSQL             Raiserror 500008 'Error on emp_us_tax_authority for auth 1'
          raiserror ('500008 Error on emp_us_tax_authority for auth 1',16,0)
        rollback transaction
        return
      end
      end /* if (rtrim(@p_tax_authority_id) IS NOT NULL AND rtrim(@p_tax_authority_id)!='') */

   if (rtrim(@p_tax_authority_2) IS NOT NULL AND rtrim(@p_tax_authority_2)!='')
         begin
          select @w_tax_marital_status_code = @p_tax_marital_status_code
          if @w_tax_marital_status_code = '2'
              begin
                if @p_tax_authority_2 = 'GA' or
                   @p_tax_authority_2 = 'DC' or
                   @p_tax_authority_2 = 'DE'
                     select @w_tax_marital_status_code = '4'
                     else if @p_tax_authority_2 = 'WV'                /* r71m-sol#582345 */
                       select @w_tax_marital_status_code = '6'    /* r71m-sol#582345 */
              end
                else                                                  /* r71m-sol#582345 */
                 begin                                                /* r71m-sol#582345 */
                  if @p_tax_authority_2 = 'WV'                        /* r71m-sol#582345 */
                     select @w_tax_marital_status_code = '6'         /* r71m-sol#582345 */
                  end                                                 /* r71m-sol#582345 */

          IF @p_tax_authority_2 = 'CA' or
              @p_tax_authority_2 = 'HI' or
              @p_tax_authority_2 = 'NY' or
              @p_tax_authority_2 = 'RI' or
              @p_tax_authority_2 = 'NJ'
                select @w_sdi_status_code = '2'
          ELSE
                   select @w_sdi_status_code = '1'

         if @p_tax_authority_2 = 'NJ'
                begin
                select @w_other_st_tax_1_status_cd = '2'
               select @w_other_st_tax_2_status_cd = '2'
                select @w_other_st_tax_3_status_cd = '2'
                select @w_other_st_tax_4_status_cd = '2'
                end
          else
               IF @p_tax_authority_2 = 'MT'
                  begin
                select @w_other_st_tax_1_status_cd = '2'
             select @w_other_st_tax_2_status_cd = '2'
                select @w_other_st_tax_3_status_cd = ' '
                select @w_other_st_tax_4_status_cd = ' '
                  end
            else
              if @p_tax_authority_2 = 'MA'
                 begin
                  select @w_other_st_tax_1_status_cd = ' '
         select @w_other_st_tax_2_status_cd = '2'
                  select @w_other_st_tax_3_status_cd = ' '
                  select @w_other_st_tax_4_status_cd = ' '
                    end
           else
                 begin
                    select @w_other_st_tax_1_status_cd = ' '
               select @w_other_st_tax_2_status_cd = ' '
                    select @w_other_st_tax_3_status_cd = ' '
                    select @w_other_st_tax_4_status_cd = ' '
                  end

           select @p_income_tax_calc_meth_cd = '01'   /* 1055162 */
           if @p_tax_authority_2 = 'PR'
			  begin                                   /* 1055162 */
               Select @w_pr_resident_status_cd = '1'  /* 1055162,  @p_income_tax_calc_meth_cd = '11' */
			  end                                     /* 1055162 */
           else
			  begin                                   /* 1055162 */
			   Select @w_pr_resident_status_cd = ' '  /* 1055162, @p_income_tax_calc_meth_cd = '01' */
              end                                     /* 1055162 */

           /* 1017861 begin */
           if substring(@p_tax_authority_2, 1, 3) = 'PAL' or
                substring(@p_tax_authority_2, 1, 3) = 'PLS'
           begin
              select @p_income_tax_calc_meth_cd = '03'
           end
           /* 1017861 end */

      Select @w_allow_based_on_ded_amt = 0

           if @p_tax_authority_2 = 'CA'
                  select @w_wage_plan_code = @p_wage_plan_code
           else
                  select @w_wage_plan_code = ' '

           if @p_tax_authority_2 = 'OR' or @p_tax_authority_2 = 'VT'   /* 583778 added VT */
                  select @w_emp_health_ins_cvg_cd = @p_emp_health_insurance_cvg_cd
           else
                  select @w_emp_health_ins_cvg_cd = ' '

           if @p_tax_authority_2 = 'WY'
              begin
                  select @w_emp_workers_comp_cvg_cd = @p_emp_workers_comp_cvg_cd
                  select @w_emp_workers_comp_class  = @p_emp_workers_comp_class    /* 719749-719473 */
              end
           else
              begin
                  select @w_emp_workers_comp_cvg_cd = ' '
                  select @w_emp_workers_comp_class  = ' '                          /* 719749-719473 */
              end

      /*********************************************************************
          529378 - Add Employee Indiana Advance Earned Income Credit
      **********************************************************************/
      if @p_tax_authority_2 = 'IN' or @p_tax_authority_2 = 'WI' /*651802*/
         begin
               select @w_other_st_tax_1_status_cd = '1'
         end
      /*1545139 begin */
	  else if @p_tax_authority_2 = 'MI'
       begin
            select @w_other_st_tax_2_status_cd = '1'
       end
      /*1545139 end */

      insert into emp_us_tax_authority
        (emp_id,
         tax_entity_id,
         tax_authority_id,
         emp_us_tax_authority_status_cd,
         tax_marital_status_code,
         tm_worked_pct,
         work_resident_status_code,
         reciprocal_tax_authority_id,
         income_tax_calc_meth_cd,
         earned_income_cr_calc_meth_cd,
         income_tax_adj_code,
         income_tax_adj_amt,
         income_tax_adj_pct,
         income_tax_nbr_of_exemps,
         income_tax_nbr_of_pers_exemps,
         income_tax_nbr_of_depn_exemps,
         income_tax_nbr_exemps_over_65,
         income_tax_nbr_of_allowances,
         use_inc_tax_low_inc_tbls_ind,
         income_tax_blind_crs,
         income_tax_personal_exemp_amt,
         income_tax_senior_citizen_cr,
         oasdi_status_code,
         medicare_status_code,
         fui_status_code,
         sui_st_ind,
         resident_county_code,
         work_county_code,
         sui_status_code,
         sdi_status_code,
         other_st_tax_1_status_code,
         other_st_tax_2_status_code,
         other_st_tax_3_status_code,
         other_st_tax_4_status_code,
         other_st_tax_5_status_code,
         wage_plan_code,
         emp_health_insurance_cvrg_cd,
         user_amt_1,
         user_amt_2,
         user_monetary_amt_1,
         user_monetary_amt_2,
         user_monetary_curr_code,
         user_code_1,
         user_code_2,
         user_date_1,
         user_date_2,
         user_ind_1,
         user_ind_2,
         user_text_1,
         user_text_2,
         emp_workers_comp_cvrg_cd,
         puerto_rico_resident_status_cd,
         allowances_based_on_ded_amt,
         az_income_tax_ovrd_opt_cd,
         chgstamp,
         us_resident_status_cd,        /* R7.0M-ALS#571102 */
         other_st_tax_1a_status_code, /*593964-591400*/
         eic_nbr_of_children,          /*651802-614209*/
         hire_act_status_code,         /* hire_act_status_code 703950 */
         emp_workers_comp_class,       /* 719749-719473 */
         resident_psd,                 /* 1017861 - PA */
 		 add_vet_pers_exemps,	         /* 1055162 - PR */
         income_tax_nbr_joint_dep_exemp, /* 1055162 - PR */
         allowance_based_on_special_ded, /* 1055162 - PR */
         allowance_based_on_deds,	     /* 1055162 - PR */
         rec_chg_ind                     /* 1024762 */
		 )

         values (@p_employee_id,
         @p_tax_entity_id,
         @p_tax_authority_2,
         '1',
         @w_tax_marital_status_code,
         @w_time_pct_2,
         @p_work_resident_status_code_2,
         ' ',
         @p_income_tax_calc_meth_cd,'0',
         '1',
         0,0,
         0,
         0,0,0,0,
         ' ',
         0,0,0,
         ' ',' ',' ',
         @w_sui_state_2_ind,
         ' ',' ',
         '2',
         @w_sdi_status_code,
         @w_other_st_tax_1_status_cd,
         @w_other_st_tax_2_status_cd,
         @w_other_st_tax_3_status_cd,
         @w_other_st_tax_4_status_cd,
         ' ',
         @w_wage_plan_code,
         @w_emp_health_ins_cvg_cd,
         0,0,0,0,
         ' ',' ',' ',
         '12/31/2999','12/31/2999',
         'N','N',
         ' ',' ',
         @w_emp_workers_comp_cvg_cd,
         @w_pr_resident_status_cd,
         0,'9',0,
         '0',                    /* us_resident_status_cd */ /* R7.0M-ALS#571102 */
         @w_other_st_tax_1a_status_cd,  /*593964-591400*/
         0,                             /*651802-614209*/
         '',                            /* hire_act_status_code 703950 */
         @w_emp_workers_comp_class, ' ', 0,0,0,0,'N')    /* 719749-719473 */  /* 1017861 - PA */ /* 1055162 - PR added 4 0's */ /* 1024762 added 'N' */

      if @@error <> 0
        begin
--SYBSQL           Raiserror 500009 'Error on emp_us_tax_authority for auth 2'
          raiserror ('500009 Error on emp_us_tax_authority for auth 2',16,0)
          rollback transaction
                    return
                  end
      end /* if (rtrim(@p_tax_authority_2) IS NOT NULL AND rtrim(@p_tax_authority_2)!='') */

   if (rtrim(@p_tax_authority_3) IS NOT NULL AND rtrim(@p_tax_authority_3)!='')
      begin
            select @w_tax_marital_status_code = @p_tax_marital_status_code
            if @w_tax_marital_status_code = '2'
            begin
             if @p_tax_authority_3 = 'GA' or
                 @p_tax_authority_3 = 'DC' or
                 @p_tax_authority_3 = 'DE'
                  select @w_tax_marital_status_code = '4'
                  else if @p_tax_authority_3 = 'WV'              /* r71m-sol#582345 */
                    select @w_tax_marital_status_code = '6'  /* r71m-sol#582345 */
           end
             else                                                /* r71m-sol#582345 */
              begin                                              /* r71m-sol#582345 */
               if @p_tax_authority_3 = 'WV'                      /* r71m-sol#582345 */
                select @w_tax_marital_status_code = '6'       /* r71m-sol#582345 */
               end                                               /* r71m-sol#582345 */

            IF @p_tax_authority_3 = 'CA' or
           @p_tax_authority_3 = 'HI' or
           @p_tax_authority_3 = 'NY' or
           @p_tax_authority_3 = 'RI' or
           @p_tax_authority_3 = 'NJ'
             select @w_sdi_status_code = '2'
            ELSE
                select @w_sdi_status_code = '1'

            if @p_tax_authority_3 = 'NJ'
             begin
             select @w_other_st_tax_1_status_cd = '2'
            select @w_other_st_tax_2_status_cd = '2'
             select @w_other_st_tax_3_status_cd = '2'
             select @w_other_st_tax_4_status_cd = '2'
             end
            else
            if @p_tax_authority_3 = 'MT'
               begin
                  select @w_other_st_tax_1_status_cd = '2'
               select @w_other_st_tax_2_status_cd = '2'
                  select @w_other_st_tax_3_status_cd = ' '
                  select @w_other_st_tax_4_status_cd = ' '
               end
              else
           if @p_tax_authority_3 = 'MA'
                 begin
                select @w_other_st_tax_1_status_cd = ' '
           select @w_other_st_tax_2_status_cd = '2'
                    select @w_other_st_tax_3_status_cd = ' '
                    select @w_other_st_tax_4_status_cd = ' '
                 end
             else
              begin
                 select @w_other_st_tax_1_status_cd = ' '
            select @w_other_st_tax_2_status_cd = ' '
                 select @w_other_st_tax_3_status_cd = ' '
                 select @w_other_st_tax_4_status_cd = ' '
              end

             select @p_income_tax_calc_meth_cd = '01' /* 1055162 */
             if @p_tax_authority_3 = 'PR'
			  begin                                   /* 1055162 */
               Select @w_pr_resident_status_cd = '1'  /* 1055162,  @p_income_tax_calc_meth_cd = '11' */
			  end                                     /* 1055162 */
             else
			  begin                                   /* 1055162 */
			   Select @w_pr_resident_status_cd = ' '  /* 1055162, @p_income_tax_calc_meth_cd = '01' */
              end                                     /* 1055162 */

             /* 1017861 begin */
             if substring(@p_tax_authority_3, 1, 3) = 'PAL' or
                substring(@p_tax_authority_3, 1, 3) = 'PLS'
             begin
              select @p_income_tax_calc_meth_cd = '03'
             end
             /* 1017861 end */

             Select @w_allow_based_on_ded_amt = 0

             if @p_tax_authority_3 = 'CA'
                select @w_wage_plan_code = @p_wage_plan_code
             else
                select @w_wage_plan_code = ' '

             if @p_tax_authority_3 = 'OR' or @p_tax_authority_3 = 'VT'    /* 583778 added VT */
                select @w_emp_health_ins_cvg_cd = @p_emp_health_insurance_cvg_cd
             else
                select @w_emp_health_ins_cvg_cd = ' '

             if @p_tax_authority_3 = 'WY'
                begin
                  select @w_emp_workers_comp_cvg_cd = @p_emp_workers_comp_cvg_cd
                  select @w_emp_workers_comp_class  = @p_emp_workers_comp_class    /* 719749-719473 */
                end
             else
                begin
                  select @w_emp_workers_comp_cvg_cd = ' '
                  select @w_emp_workers_comp_class  = ' '                          /* 719749-719473 */
                end

        /*********************************************************************
         529378 - Add Employee Indiana Advance Earned Income Credit
        **********************************************************************/
      if @p_tax_authority_3 = 'IN' or @p_tax_authority_3 = 'WI' /*651802*/
       begin
            select @w_other_st_tax_1_status_cd = '1'
       end
      /*1545139 begin */
	  else if @p_tax_authority_3 = 'MI'
       begin
            select @w_other_st_tax_2_status_cd = '1'
       end
      /*1545139 end */

         insert into emp_us_tax_authority
         (emp_id,
         tax_entity_id,
         tax_authority_id,
         emp_us_tax_authority_status_cd,
         tax_marital_status_code,
         tm_worked_pct,
         work_resident_status_code,
         reciprocal_tax_authority_id,
         income_tax_calc_meth_cd,
         earned_income_cr_calc_meth_cd,
         income_tax_adj_code,
         income_tax_adj_amt,
         income_tax_adj_pct,
         income_tax_nbr_of_exemps,
         income_tax_nbr_of_pers_exemps,
         income_tax_nbr_of_depn_exemps,
         income_tax_nbr_exemps_over_65,
         income_tax_nbr_of_allowances,
         use_inc_tax_low_inc_tbls_ind,
         income_tax_blind_crs,
         income_tax_personal_exemp_amt,
         income_tax_senior_citizen_cr,
         oasdi_status_code,
         medicare_status_code,
         fui_status_code,
         sui_st_ind,
         resident_county_code,
         work_county_code,
         sui_status_code,
         sdi_status_code,
         other_st_tax_1_status_code,
         other_st_tax_2_status_code,
         other_st_tax_3_status_code,
         other_st_tax_4_status_code,
         other_st_tax_5_status_code,
         wage_plan_code,
         emp_health_insurance_cvrg_cd,
         user_amt_1,
         user_amt_2,
         user_monetary_amt_1,
         user_monetary_amt_2,
         user_monetary_curr_code,
         user_code_1,
         user_code_2,
         user_date_1,
         user_date_2,
         user_ind_1,
         user_ind_2,
         user_text_1,
         user_text_2,
         emp_workers_comp_cvrg_cd,
         puerto_rico_resident_status_cd,
         allowances_based_on_ded_amt,
         az_income_tax_ovrd_opt_cd,
         chgstamp,
         us_resident_status_cd,       /* R7.0M-ALS#571102 */
         other_st_tax_1a_status_code, /*593964-591400*/
         eic_nbr_of_children,         /*651802-614209*/
         hire_act_status_code,        /* hire_act_status_code 703950 */
         emp_workers_comp_class,      /* 719749-719473 */
         resident_psd,                 /* 1017861 - PA */
 		 add_vet_pers_exemps,	         /* 1055162 - PR */
         income_tax_nbr_joint_dep_exemp, /* 1055162 - PR */
         allowance_based_on_special_ded, /* 1055162 - PR */
         allowance_based_on_deds,	     /* 1055162 - PR */
         rec_chg_ind                     /* 1024762 */
		 )

         values (@p_employee_id,
         @p_tax_entity_id,
         @p_tax_authority_3,
         '1',
         @w_tax_marital_status_code,
         @w_time_pct_3,
         @p_work_resident_status_code_3,
         ' ',
         @p_income_tax_calc_meth_cd,'0',
         '1',
         0,0,
         0,
         0,0,0,0,
         ' ',
         0,0,0,
         ' ',' ',' ',
         @w_sui_state_3_ind,
         ' ',' ',
         '2',
         @w_sdi_status_code,
         @w_other_st_tax_1_status_cd,
         @w_other_st_tax_2_status_cd,
         @w_other_st_tax_3_status_cd,
         @w_other_st_tax_4_status_cd,
         ' ',
         @w_wage_plan_code,
         @w_emp_health_ins_cvg_cd,
         0,0,0,0,
         ' ',' ',' ',
         '12/31/2999','12/31/2999',
         'N','N',
         ' ',' ',
         @w_emp_workers_comp_cvg_cd,
         @w_pr_resident_status_cd,
         0,'9',0,
         '0',                          /* us_resident_status_cd */ /* R7.0M-ALS#571102 */
         @w_other_st_tax_1a_status_cd, /*593964-591400*/
         0,                            /*651802-614209*/
         '',                           /* hire_act_status_code 703950 */
         @w_emp_workers_comp_class, ' ', 0,0,0,0,'N')     /* 719749-719473 */ /* 1017861 - PA */ /* 1055162 - PR added 4 0's */ /*1024762 added 'N'*/

        if @@error <> 0
      begin
--SYBSQL         Raiserror 500010 'Error on emp_us_tax_authority for auth 3'
          raiserror ('500010 Error on emp_us_tax_authority for auth 3',16,0)
            rollback transaction
        return
      end
      end /* if (rtrim(@p_tax_authority_3) IS NOT NULL AND rtrim(@p_tax_authority_3)!='') */

   if (rtrim(@p_tax_authority_4) IS NOT NULL AND rtrim(@p_tax_authority_4)!='')
      begin
            select @w_tax_marital_status_code = @p_tax_marital_status_code
            if @w_tax_marital_status_code = '2'
           begin
             if @p_tax_authority_4 = 'GA' or
                @p_tax_authority_4 = 'DC' or
                @p_tax_authority_4 = 'DE'
                  select @w_tax_marital_status_code = '4'
                  else if @p_tax_authority_4 = 'WV'                 /* r71m-sol#582345 */
                  select @w_tax_marital_status_code = '6'     /* r71m-sol#582345 */
           end
             else                                                   /* r71m-sol#582345 */
              begin                                                 /* r71m-sol#582345 */
               if @p_tax_authority_4 = 'WV'                         /* r71m-sol#582345 */
                 select @w_tax_marital_status_code = '6'           /* r71m-sol#582345 */
              end                                                   /* r71m-sol#582345 */

            IF @p_tax_authority_4 = 'CA' or
           @p_tax_authority_4 = 'HI' or
           @p_tax_authority_4 = 'NY' or
           @p_tax_authority_4 = 'RI' or
           @p_tax_authority_4 = 'NJ'
             select @w_sdi_status_code = '2'
            ELSE
         select @w_sdi_status_code = '1'

            if @p_tax_authority_4 = 'NJ'
             begin
             select @w_other_st_tax_1_status_cd = '2'
             select @w_other_st_tax_1a_status_cd = '2' /*593964-591400*/
             select @w_other_st_tax_2_status_cd = '2'
             select @w_other_st_tax_3_status_cd = '2'
             select @w_other_st_tax_4_status_cd = '2'
             end
            else
            if @p_tax_authority_4 = 'MT'
               begin
                  select @w_other_st_tax_1_status_cd = '2'
                select @w_other_st_tax_1a_status_cd = '1' /*593964-591400*/
                     select @w_other_st_tax_2_status_cd = '2'
                  select @w_other_st_tax_3_status_cd = ' '
                  select @w_other_st_tax_4_status_cd = ' '
               end
              else
           if @p_tax_authority_4 = 'MA'
                 begin
                    select @w_other_st_tax_1_status_cd = ' '
                select @w_other_st_tax_1a_status_cd = '1' /*593964-591400*/
           select @w_other_st_tax_2_status_cd = '2'
                    select @w_other_st_tax_3_status_cd = ' '
                    select @w_other_st_tax_4_status_cd = ' '
                   end
             else
               begin
                 select @w_other_st_tax_1_status_cd = ' '
            select @w_other_st_tax_1a_status_cd = '1' /*593964-591400*/
           select @w_other_st_tax_2_status_cd = ' '
                select @w_other_st_tax_3_status_cd = ' '
                select @w_other_st_tax_4_status_cd = ' '
               end

             select @p_income_tax_calc_meth_cd = '01' /* 1055162 */
             if @p_tax_authority_4 = 'PR'
			  begin                                   /* 1055162 */
               Select @w_pr_resident_status_cd = '1'  /* 1055162,  @p_income_tax_calc_meth_cd = '11' */
			  end                                     /* 1055162 */
             else
			  begin                                   /* 1055162 */
			   Select @w_pr_resident_status_cd = ' '  /* 1055162, @p_income_tax_calc_meth_cd = '01' */
              end                                     /* 1055162 */

             /* 1017861 begin */
             if substring(@p_tax_authority_4, 1, 3) = 'PAL' or
                substring(@p_tax_authority_4, 1, 3) = 'PLS'
             begin
              select @p_income_tax_calc_meth_cd = '03'
             end
             /* 1017861 end */

             Select @w_allow_based_on_ded_amt = 0

             if @p_tax_authority_4 = 'CA'
                select @w_wage_plan_code = @p_wage_plan_code
             else
                select @w_wage_plan_code = ' '

             if @p_tax_authority_4 = 'OR' or @p_tax_authority_4 = 'VT'    /* 583778 added VT */
                select @w_emp_health_ins_cvg_cd = @p_emp_health_insurance_cvg_cd
             else
                select @w_emp_health_ins_cvg_cd = ' '

             if @p_tax_authority_4 = 'WY'
                begin
                  select @w_emp_workers_comp_cvg_cd = @p_emp_workers_comp_cvg_cd
                  select @w_emp_workers_comp_class  = @p_emp_workers_comp_class    /* 719749-719473 */
                end
             else
                begin
                  select @w_emp_workers_comp_cvg_cd = ' '
                  select @w_emp_workers_comp_class  = ' '                          /* 719749-719473 */
                end

        /*********************************************************************
         529378 - Add Employee Indiana Advance Earned Income Credit
        **********************************************************************/
      if @p_tax_authority_4 = 'IN' or @p_tax_authority_4 = 'WI' /*651802*/
       begin
            select @w_other_st_tax_1_status_cd = '1'
       end
      /*1545139 beging*/
	  else if @p_tax_authority_4 = 'MI'
	   begin
            select @w_other_st_tax_2_status_cd = '1'
       end
      /*1545139 end*/

        insert into emp_us_tax_authority
         (emp_id,
         tax_entity_id,
         tax_authority_id,
         emp_us_tax_authority_status_cd,
         tax_marital_status_code,
         tm_worked_pct,
         work_resident_status_code,
         reciprocal_tax_authority_id,
         income_tax_calc_meth_cd,
         earned_income_cr_calc_meth_cd,
         income_tax_adj_code,
         income_tax_adj_amt,
         income_tax_adj_pct,
         income_tax_nbr_of_exemps,
         income_tax_nbr_of_pers_exemps,
         income_tax_nbr_of_depn_exemps,
         income_tax_nbr_exemps_over_65,
         income_tax_nbr_of_allowances,
         use_inc_tax_low_inc_tbls_ind,
         income_tax_blind_crs,
         income_tax_personal_exemp_amt,
         income_tax_senior_citizen_cr,
         oasdi_status_code,
         medicare_status_code,
         fui_status_code,
         sui_st_ind,
         resident_county_code,
         work_county_code,
         sui_status_code,
         sdi_status_code,
         other_st_tax_1_status_code,
         other_st_tax_2_status_code,
         other_st_tax_3_status_code,
         other_st_tax_4_status_code,
         other_st_tax_5_status_code,
         wage_plan_code,
         emp_health_insurance_cvrg_cd,
         user_amt_1,
         user_amt_2,
         user_monetary_amt_1,
         user_monetary_amt_2,
         user_monetary_curr_code,
         user_code_1,
         user_code_2,
         user_date_1,
         user_date_2,
         user_ind_1,
         user_ind_2,
         user_text_1,
         user_text_2,
         emp_workers_comp_cvrg_cd,
         puerto_rico_resident_status_cd,
         allowances_based_on_ded_amt,
         az_income_tax_ovrd_opt_cd,
         chgstamp,
         us_resident_status_cd,  /* R7.0M-ALS#571102 */
         other_st_tax_1a_status_code, /*593964-591400*/
         eic_nbr_of_children,          /*651802-614209*/
         hire_act_status_code,         /* hire_act_status_code 703950 */
         emp_workers_comp_class,       /* 719749-719473 */
         resident_psd,                 /* 1017861 - PA */
 		 add_vet_pers_exemps,	         /* 1055162 - PR */
         income_tax_nbr_joint_dep_exemp, /* 1055162 - PR */
         allowance_based_on_special_ded, /* 1055162 - PR */
         allowance_based_on_deds,	     /* 1055162 - PR */
         rec_chg_ind                     /* 1024762 */
         )

         values (@p_employee_id,
         @p_tax_entity_id,
         @p_tax_authority_4,
         '1',
         @w_tax_marital_status_code,
         @w_time_pct_4,
         @p_work_resident_status_code_4,
         ' ',
         @p_income_tax_calc_meth_cd,'0',
         '1',
         0,0,
         0,
         0,0,0,0,
         ' ',
         0,0,0,
         ' ',' ',' ',
         @w_sui_state_4_ind,
         ' ',' ',
         '2',
         @w_sdi_status_code,
         @w_other_st_tax_1_status_cd,
         @w_other_st_tax_2_status_cd,
         @w_other_st_tax_3_status_cd,
         @w_other_st_tax_4_status_cd,
         ' ',
         @w_wage_plan_code,
         @w_emp_health_ins_cvg_cd,
         0,0,0,0,
         ' ',' ',' ',
         '12/31/2999','12/31/2999',
         'N','N',
         ' ',' ',
         @w_emp_workers_comp_cvg_cd,
         @w_pr_resident_status_cd,
         0,'9',0,
         '0',                          /* us_resident_status_cd */ /* R7.0M-ALS#571102 */
         @w_other_st_tax_1a_status_cd, /*593964-591400*/
         0,                            /*651802-614209*/
         '',                           /* hire_act_status_code 703950 */
         @w_emp_workers_comp_class, ' ',0,0,0,0,'N')    /* 719749-719473 */ /* 1017861 - PA */ /* 1055162 - PR added 4 0's */ /*1024762 added 'N'*/

        if @@error <> 0
      begin
--SYBSQL         Raiserror 500011 'Error on emp_us_tax_authority for auth 4'
          raiserror ('500011 Error on emp_us_tax_authority for auth 4',16,0)
        rollback transaction
        return
      end
      end /* if (rtrim(@p_tax_authority_4) IS NOT NULL AND rtrim(@p_tax_authority_4)!='') */

   if (rtrim(@p_tax_authority_5) IS NOT NULL AND rtrim(@p_tax_authority_5)!='')
      begin
            select @w_tax_marital_status_code = @p_tax_marital_status_code
            if @w_tax_marital_status_code = '2'
      begin
             if @p_tax_authority_5 = 'GA' or
                 @p_tax_authority_5 = 'DC' or
                 @p_tax_authority_5 = 'DE'
                  select @w_tax_marital_status_code = '4'
                  else if @p_tax_authority_5 = 'WV'                 /* r71m-sol#582345 */
                  select @w_tax_marital_status_code = '6'     /* r71m-sol#582345 */
           end
             else                                                   /* r71m-sol#582345 */
              begin                                                 /* r71m-sol#582345 */
               if @p_tax_authority_5 = 'WV'                         /* r71m-sol#582345 */
                 select @w_tax_marital_status_code = '6'           /* r71m-sol#582345 */
              end                                                   /* r71m-sol#582345 */

            IF @p_tax_authority_5 = 'CA' or
           @p_tax_authority_5 = 'HI' or
           @p_tax_authority_5 = 'NY' or
           @p_tax_authority_5 = 'RI' or
           @p_tax_authority_5 = 'NJ'
             select @w_sdi_status_code = '2'
            ELSE
         select @w_sdi_status_code = '1'

            if @p_tax_authority_5 = 'NJ'
             begin
             select @w_other_st_tax_1_status_cd = '2'
                    select @w_other_st_tax_1a_status_cd ='2'  /*593964-591400*/
            select @w_other_st_tax_2_status_cd = '2'
             select @w_other_st_tax_3_status_cd = '2'
             select @w_other_st_tax_4_status_cd = '2'
             end
            else
            if @p_tax_authority_5 = 'MT'
               begin
                    select @w_other_st_tax_1_status_cd = '2'
                       select @w_other_st_tax_1a_status_cd ='1'  /*593964-591400*/
           select @w_other_st_tax_2_status_cd = '2'
                     select @w_other_st_tax_3_status_cd = ' '
                    select @w_other_st_tax_4_status_cd = ' '
               end
              else
           if @p_tax_authority_5 = 'MA'
                 begin
                select @w_other_st_tax_1_status_cd = ' '
                       select @w_other_st_tax_1a_status_cd ='1'  /*593964-591400*/
           select @w_other_st_tax_2_status_cd = '2'
                    select @w_other_st_tax_3_status_cd = ' '
                    select @w_other_st_tax_4_status_cd = ' '
                 end
             else
              begin
                 select @w_other_st_tax_1_status_cd = ' '
                  select @w_other_st_tax_1a_status_cd ='1'  /*593964-591400*/
        select @w_other_st_tax_2_status_cd = ' '
                 select @w_other_st_tax_3_status_cd = ' '
                 select @w_other_st_tax_4_status_cd = ' '
              end

             select @p_income_tax_calc_meth_cd = '01' /* 1055162 */
             if @p_tax_authority_5 = 'PR'
			  begin                                   /* 1055162 */
               Select @w_pr_resident_status_cd = '1'  /* 1055162,  @p_income_tax_calc_meth_cd = '11' */
			  end                                     /* 1055162 */
             else
			  begin                                   /* 1055162 */
			   Select @w_pr_resident_status_cd = ' '  /* 1055162, @p_income_tax_calc_meth_cd = '01' */
              end                                     /* 1055162 */

             /* 1017861 begin */
             if substring(@p_tax_authority_5, 1, 3) = 'PAL' or
                substring(@p_tax_authority_5, 1, 3) = 'PLS'
             begin
              select @p_income_tax_calc_meth_cd = '03'
             end
             /* 1017861 end */

             Select @w_allow_based_on_ded_amt = 0

             if @p_tax_authority_5 = 'CA'
                select @w_wage_plan_code = @p_wage_plan_code
             else
                select @w_wage_plan_code = ' '

             if @p_tax_authority_5 = 'OR' or @p_tax_authority_5 = 'VT'    /* 583778 added VT */
                select @w_emp_health_ins_cvg_cd = @p_emp_health_insurance_cvg_cd
             else
                select @w_emp_health_ins_cvg_cd = ' '

             if @p_tax_authority_5 = 'WY'
                begin
                  select @w_emp_workers_comp_cvg_cd = @p_emp_workers_comp_cvg_cd
                  select @w_emp_workers_comp_class  = @p_emp_workers_comp_class    /* 719749-719473 */
                end
             else
                begin
                  select @w_emp_workers_comp_cvg_cd = ' '
                  select @w_emp_workers_comp_class  = ' '                          /* 719749-719473 */
                end

        /*********************************************************************
         529378 - Add Employee Indiana Advance Earned Income Credit
        **********************************************************************/
      if @p_tax_authority_5 = 'IN' or @p_tax_authority_5 = 'WI' /*651802*/
       begin
            select @w_other_st_tax_1_status_cd = '1'
       end
      /*1545139 beging*/
	  else if @p_tax_authority_5 = 'MI'
	   begin
            select @w_other_st_tax_2_status_cd = '1'
       end
      /*1545139 end*/

         insert into emp_us_tax_authority
         (emp_id,
         tax_entity_id,
         tax_authority_id,
         emp_us_tax_authority_status_cd,
         tax_marital_status_code,
         tm_worked_pct,
         work_resident_status_code,
         reciprocal_tax_authority_id,
         income_tax_calc_meth_cd,
         earned_income_cr_calc_meth_cd,
         income_tax_adj_code,
         income_tax_adj_amt,
         income_tax_adj_pct,
         income_tax_nbr_of_exemps,
         income_tax_nbr_of_pers_exemps,
         income_tax_nbr_of_depn_exemps,
         income_tax_nbr_exemps_over_65,
         income_tax_nbr_of_allowances,
         use_inc_tax_low_inc_tbls_ind,
         income_tax_blind_crs,
         income_tax_personal_exemp_amt,
         income_tax_senior_citizen_cr,
         oasdi_status_code,
         medicare_status_code,
         fui_status_code,
         sui_st_ind,
         resident_county_code,
         work_county_code,
         sui_status_code,
         sdi_status_code,
         other_st_tax_1_status_code,
         other_st_tax_2_status_code,
         other_st_tax_3_status_code,
         other_st_tax_4_status_code,
         other_st_tax_5_status_code,
         wage_plan_code,
         emp_health_insurance_cvrg_cd,
         user_amt_1,
         user_amt_2,
         user_monetary_amt_1,
         user_monetary_amt_2,
         user_monetary_curr_code,
         user_code_1,
         user_code_2,
         user_date_1,
         user_date_2,
         user_ind_1,
         user_ind_2,
         user_text_1,
         user_text_2,
         emp_workers_comp_cvrg_cd,
         puerto_rico_resident_status_cd,
         allowances_based_on_ded_amt,
         az_income_tax_ovrd_opt_cd,
         chgstamp,
         us_resident_status_cd,        /* R7.0M-ALS#571102 */
         other_st_tax_1a_status_code,  /*593964-591400*/
         eic_nbr_of_children,          /*651802-614209*/
         hire_act_status_code,         /* hire_act_status_code 703950 */
         emp_workers_comp_class,       /* 719749-719473 */
         resident_psd,                 /* 1017861 - PA */
		 add_vet_pers_exemps,	         /* 1055162 - PR */
         income_tax_nbr_joint_dep_exemp, /* 1055162 - PR */
         allowance_based_on_special_ded, /* 1055162 - PR */
         allowance_based_on_deds,	     /* 1055162 - PR */
		 rec_chg_ind                     /* 1024762 */
		 )

      values (@p_employee_id,
         @p_tax_entity_id,
         @p_tax_authority_5,
         '1',
         @w_tax_marital_status_code,
         @w_time_pct_5,
         @p_work_resident_status_code_5,
         ' ',
         @p_income_tax_calc_meth_cd,'0',
         '1',
         0,0,
         0,
         0,0,0,0,
         ' ',
         0,0,0,
         ' ',' ',' ',
         @w_sui_state_5_ind,
         ' ',' ',
         '2',
         @w_sdi_status_code,
         @w_other_st_tax_1_status_cd,
         @w_other_st_tax_2_status_cd,
         @w_other_st_tax_3_status_cd,
         @w_other_st_tax_4_status_cd,
         ' ',
         @w_wage_plan_code,
         @w_emp_health_ins_cvg_cd,
         0,0,0,0,
         ' ',' ',' ',
         '12/31/2999','12/31/2999',
         'N','N',
         ' ',' ',
         @w_emp_workers_comp_cvg_cd,
         @w_pr_resident_status_cd,
         0,'9',0,
         '0',                           /* us_resident_status_cd */ /* R7.0M-ALS#571102 */
         @w_other_st_tax_1a_status_cd,  /*593964-591400*/
         0,                             /*651802-614209*/
         '',                            /* hire_act_status_code 703950 */
         @w_emp_workers_comp_class, ' ',0,0,0,0,'N')    /* 719749-719473 */ /* 1017861 - PA */ /* 1055162 - PR added 4 0's */ /*1024762 added 'N'*/

        if @@error <> 0
         begin
--SYBSQL              Raiserror 500012 'Error on emp_us_tax_authority for auth 5'
          raiserror ('500012 Error on emp_us_tax_authority for auth 5',16,0)
             rollback transaction
           return
      end
      end /* if (rtrim(@p_tax_authority_5) IS NOT NULL AND rtrim(@p_tax_authority_5)!='') */
      end  /* 'USFED established for employer tax entity' */

Declare @p_rc       int,
        @p_ret_mess varchar(50)

Execute usp_ins_hemp_02     @p_employer_taxing_ctry_code,
                            @p_employer_id,
                            @p_employee_id,
                            @p_income_tax_stat_code,
                            @p_ei_status_code,
                            @p_ppip_status_code, /* 566986 */
                            @p_fed_pp_stat_code,
                            @p_tax_authority_id,
                            @p_pit_stat_code, /* R6.0 SSA 165213 */
                            @p_provincial_pp_stat_code,
                            @w_autopay_pay_element_id,
                            @w_autopay_rtn,
                            @p_original_hire_date,
                            @w_inact_by_pay_element_ind,
                            @w_stop_date,
                            @p_pay_element_ctrl_grp,
                            @p_pensioner_indicator,
                            @w_auto_rt_tbl_id,
                            @p_rc   OUTPUT,
                            @p_ret_mess OUTPUT

if @p_rc > 500000
    Begin
--SYBSQL         Raiserror @p_rc @p_ret_mess
         select @p_ret_mess = @p_rc + ' ' + @p_ret_mess
          raiserror (@p_ret_mess,16,0)
        rollback transaction
        return
    End

/* AUDIT SECTION ==============================================*/
/* Set up the work employee pay element audit table            */
/* ============================================================*/
insert into work_emp_pay_element_aud
   (user_id, activity_action_code, action_date, emp_id, empl_id,
         pay_element_id, eff_date, prior_eff_date, next_eff_date,
         new_eff_date, new_start_date, new_stop_date)
values
   (@W_ACTION_USER, 'HIREEMP', @W_ACTION_DATETIME,
    @p_employee_id, @p_employer_id, @w_autopay_pay_element_id,
    @p_original_hire_date, '', '', '', '', '')

Delete work_emp_pay_element_aud
 Where user_id              = @W_ACTION_USER
   and action_date          = @W_ACTION_DATETIME
   and activity_action_code = 'HIREEMP'
   and emp_id               = @p_employee_id
   and empl_id              = @p_employer_id
   and pay_element_id       = @w_autopay_pay_element_id
   and eff_date             = @p_original_hire_date
/* END AUDIT SECTION ==========================================*/
/* Set up the work employee pay element audit table            */
/* ============================================================*/

select @w_return_code = 0

/* AUDIT SECTION ==============================================*/
/* Set up the work audit tables                                */
/* ============================================================*/
insert into work_emp_employment_aud
   (user_id, activity_action_code, action_date, emp_id, eff_date,
         next_eff_date, prior_eff_date, new_eff_date, new_empl_id,
         new_tax_entity_id,  xfer_date, pay_through_date)
values
   (@W_ACTION_USER, 'HIREEMP', @W_ACTION_DATETIME,
    @p_employee_id, @p_original_hire_date, '', '', '', '', '','', '')

Delete work_emp_employment_aud
 Where user_id              = @W_ACTION_USER
   and action_date          = @W_ACTION_DATETIME
   and activity_action_code = 'HIREEMP'
   and emp_id               = @p_employee_id
   and eff_date             = @p_original_hire_date

insert into work_emp_assignment_aud
   (user_id,activity_action_code,action_date,emp_id,assigned_to_code,job_or_pos_id,
         eff_date,next_eff_date,prior_eff_date,new_eff_date,new_begin_date,new_end_date,
         new_assigned_to_code, new_job_or_pos_id,new_assigned_to_begin_date)
values
   (@W_ACTION_USER, 'HIREEMP', @W_ACTION_DATETIME, @p_employee_id, @p_assigned_to_code,
    @p_job_or_pos_id, @p_original_hire_date, '','','','','','','','')

Delete work_emp_assignment_aud
 Where user_id              = @W_ACTION_USER
   and activity_action_code = 'HIREEMP'
   and action_date          = @W_ACTION_DATETIME
   and emp_id               = @p_employee_id
   and assigned_to_code     = @p_assigned_to_code
   and job_or_pos_id        = @p_job_or_pos_id
   and eff_date             = @p_original_hire_date

insert into work_emp_status_aud
   (user_id, activity_action_code, action_date, emp_id,status_change_date,
         prior_change_date, prior_emp_id)
values
   (@W_ACTION_USER, 'HIREEMP', @W_ACTION_DATETIME,
    @p_employee_id, @p_original_hire_date, '', '')

Delete work_emp_status_aud
 Where user_id              = @W_ACTION_USER
   and action_date          = @W_ACTION_DATETIME
   and activity_action_code = 'HIREEMP'
   and emp_id               = @p_employee_id
   and status_change_date   = @p_original_hire_date
/* END AUDIT SECTION ==========================================*/
/* Set up the work audit tables                            */
/* ============================================================*/

commit transaction

/******************************************************************
*   sol# 172180 - moved following code from before audit section  *
*******************************************************************/
--if @p_rc > 1
--    Select @p_rc, @w_complete_ind, @w_can_tax_auth_complete
--else
--    Select @w_autopay_rtn, @w_complete_ind, @w_can_tax_auth_complete
/******************************************************************/




GO
ALTER AUTHORIZATION ON [dbo].[usp_ins_hemp] TO  SCHEMA OWNER
GO
