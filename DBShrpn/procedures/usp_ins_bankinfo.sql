USE [DBShrpn]
GO
/****** Object:  StoredProcedure [dbo].[usp_ins_bankinfo]    Script Date: 4/1/2025 4:33:00 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE procedure [dbo].[usp_ins_bankinfo]
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
-- SELECT * FROM DBShrpn.dbo.ghr_historical_message WHERE event_id = '07'

DECLARE @ret int

--DECLARE @p_userid						varchar(30)
--DECLARE @p_batchname					varchar(08)
--DECLARE @p_qualifier					varchar(30)
--DECLARE @p_activity_date				datetime
--DECLARE @p_user_id					varchar(30)
--DECLARE @p_activity_status			char(02)
--DECLARE @p_status						int
DECLARE @w_msg_text						varchar(255)
DECLARE @w_msg_text_2					varchar(255)
DECLARE @w_msg_text_3					varchar(255)
DECLARE @w_severity_cd					tinyint	
DECLARE @w_fatal_error					char(01)

DECLARE @special_value_exists			int
DECLARE @individual_id					char(10)
DECLARE @prior_last_name				char(30)
DECLARE @pay_element_id_exists          char(1)
DECLARE @record_exists					char(1)
DECLARE @end_of_time                    datetime

DECLARE  @curr_emp_id					char(15),
         @curr_empl_id					char(10),
         @curr_pay_element_id			char(11),
         @curr_eff_date					datetime
         
--
-- Activate these fields when testing this program standalone.
--
/*
SET @p_userid			=	'DBS'
SET @p_batchname		=	'GHR'
SET @p_qualifier		=	'BANK INTERFACE'
SET @p_activity_date	=	GETDATE()
SET @p_user_id			=	'DBS'
SET @p_activity_status	=	'00'
SET @p_status			=	0
*/



SELECT @end_of_time = '2999-12-31 00:00:00.000'

IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_bankinfo_events_temp7]') AND type in (N'U'))
	DROP TABLE [dbo].[ghr_bankinfo_events_temp7]


CREATE TABLE [dbo].[ghr_bankinfo_events_temp7](
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
	[emp_calculation_06]					[char](15) NULL,
	[bank_id_07]							[char](11) NULL,
	[direct_deposit_bank_acct_nbr_07]		[char](17) NULL,
	[bank_acct_type_code_07]				[char](1)  NULL
)

INSERT INTO DBShrpn.dbo.ghr_bankinfo_events_temp7    ---#t0
SELECT * 
  FROM DBShrpn.dbo.ghr_bankinfo_events
 WHERE [event_id_01] = '07' 
 
 

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
--DECLARE @curr_empl_id   CHAR(10)

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
			@emp_calculation_06						char(15),
			@bank_id_07							    char(11),
	        @direct_deposit_bank_acct_nbr_07	    char(17),
			@bank_acct_type_code_07				    char(1)
			
SET @cnt = 1

SELECT @max = COUNT(ID) 
FROM DBShrpn.dbo.ghr_bankinfo_events_temp7

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
			@emp_calculation_06					=	emp_calculation_06,
			@bank_id_07							=   bank_id_07,
	        @direct_deposit_bank_acct_nbr_07	=   direct_deposit_bank_acct_nbr_07,
			@bank_acct_type_code_07				=   bank_acct_type_code_07
	  FROM DBShrpn.dbo.ghr_bankinfo_events_temp7 t WHERE t.ID = @cnt
	  
--
--	This section will validate the interface data
-- 

--
-- Check to see if the user has been setup with direct deposit for the current entity
--

IF NOT EXISTS (SELECT * FROM [DBShrpn].[dbo].[emp_pay_element] WHERE [emp_id] =	@emp_id_01 AND [empl_id]	= @empl_id_01 AND [pay_element_id] = @pay_element_desc_06)
   BEGIN   
--   INSERT INTO DBSosxp.dbo.msg SELECT 'Bankinfo_Loop: Inside ' + ' event_id: ' 
   		UPDATE	DBShrpn.dbo.ghr_bankinfo_events_aud
		   SET activity_status	=	'02'					
		 WHERE activity_date	=	@p_activity_date
		   AND emp_id_01		=	@emp_id_01
		   AND event_id_01		=	'07'			    
			 		 
		INSERT INTO DBShrpn.dbo.ghr_msg_tbl
		SELECT 'U00054'					    As msg_id,
				@emp_id_01					As msg_p1,
				@emp_id_01					As msg_p2,
				'Must setup direct deposit (DD1) after: New Hire, Rehire, or Transfer to New Legal Entity'	As msg_desc
					
		-- Historical Message for reporting purpose	
		INSERT INTO DBShrpn.dbo.ghr_historical_message	
		SELECT  'U00054'						As msg_id,
				'07'							As event_id,
				@emp_id_01 						As emp_id,
				@eff_date_01					As eff_date,
				@pay_element_desc_06			As pay_element_id,					
				@emp_id_01						As msg_p1,
				@emp_id_01						As msg_p2,
				'Must setup direct deposit (DD1) after: New Hire, Rehire, or transfer to New Legal Entity'	As msg_desc,
				@p_activity_date				AS activity_date
				
		-- End of Historical Message for reporting purpose						
					
		SELECT  @w_fatal_error = '5'
			 
          GOTO BYPASS_EMPLOYEE 
   END
 
--
--	This section will validate the interface data
-- 
 
SELECT @curr_emp_id         = emp_id,
       @curr_empl_id        = empl_id,
       @curr_pay_element_id = pay_element_id,
       @curr_eff_date       = eff_date
  FROM [DBShrpn].[dbo].[emp_pay_element] pe
WHERE [emp_id]			=	@emp_id_01
  AND [empl_id]			=	@empl_id_01
  AND [pay_element_id]  =   @pay_element_desc_06
  AND [eff_date]        =   (SELECT MAX(eff_date) FROM [DBShrpn].[dbo].[emp_pay_element] t 
                              WHERE t.emp_id = pe.emp_id AND t.empl_id = pe.empl_id AND t.pay_element_id = pe.pay_element_id)
--
-- Since the correct effective date for the bank interface is not avaialble, we will use the most current date as the default
--
--    SELECT @eff_date_01 = CAST(@curr_eff_date AS char(10))

--
                              
--
-- Check to see if the employee does not exists
--	 
--    SELECT 'Step1'
	IF  NOT EXISTS (SELECT * FROM DBShrpn.dbo.employee WHERE emp_id = @emp_id_01)
		BEGIN
			 UPDATE	DBShrpn.dbo.ghr_bankinfo_events_aud
			    SET activity_status	=	'02'					
			  WHERE activity_date	=	@p_activity_date
			    AND emp_id_01		=	@emp_id_01
			    AND event_id_01		=	'07'			    
			 		 
			 INSERT INTO DBShrpn.dbo.ghr_msg_tbl
			 SELECT 'U00012'					As msg_id,
					@emp_id_01					As msg_p1,
					@emp_id_01					As msg_p2,
					'Employee does not exists'	As msg_desc
					
			 -- Historical Message for reporting purpose	
			INSERT INTO DBShrpn.dbo.ghr_historical_message	
			SELECT  'U00012'						As msg_id,
					'07'							As event_id,
					@emp_id_01 						As emp_id,
					@eff_date_01					As eff_date,
					@pay_element_desc_06			As pay_element_id,					
					@emp_id_01						As msg_p1,
					@emp_id_01						As msg_p2,
					'Employee does not exists'		As msg_desc,
					@p_activity_date				AS activity_date
			-- End of Historical Message for reporting purpose						
					
		   SELECT  @w_fatal_error = '5'
			 
          GOTO BYPASS_EMPLOYEE 
		END

--
-- Check to see if the record that HCM is asking to be updated with banking info actually exists.
--
--    SELECT 'Step2'
	IF  EXISTS (SELECT * FROM [DBShrpn].[dbo].[emp_pay_element] pe
                     WHERE [emp_id]	=	@emp_id_01 AND empl_id = @empl_id_01 AND [pay_element_id]  =   @pay_element_desc_06)
    BEGIN
        SELECT @record_exists = 'Y'
    END
    ELSE
        SELECT @record_exists = 'N'
        
--     SELECT @record_exists, @emp_id_01, @empl_id_01, @pay_element_desc_06

--
-- Check to see if the employer id from HCM is the same as the current record.
--
--    SELECT 'Step3'
   IF @record_exists = 'N'
   BEGIN
      SELECT @curr_empl_id = [empl_id]
        FROM [DBShrpn].[dbo].[emp_pay_element] pe
       WHERE [emp_id]			=	@emp_id_01
       --AND [empl_id]			=	@empl_id_01
         AND [pay_element_id]   =   @pay_element_desc_06
         AND [eff_date]         =  (SELECT MAX(eff_date) FROM [DBShrpn].[dbo].[emp_pay_element] t 
                                 WHERE t.emp_id = pe.emp_id AND t.empl_id = pe.empl_id AND t.pay_element_id = pe.pay_element_id)
--
-- Check to see f the employer id is blank or null, if it is then we have an invalid pay element id.
--          
        IF @curr_empl_id = '' or @curr_empl_id is NULL SELECT @curr_empl_id = '9999999999'                         
    
--         SELECT 'Step3.1', @curr_empl_id, @empl_id_01         
        
        IF ( @curr_empl_id = '9999999999' )
		BEGIN
--		SELECT 'Step3.1.0'
			 UPDATE	DBShrpn.dbo.ghr_bankinfo_events_aud
			    SET activity_status	=	'02'					
			  WHERE activity_date	=	@p_activity_date
			    AND emp_id_01		=	@emp_id_01
			    AND event_id_01		=	'07'			    
			 		 
			 INSERT INTO DBShrpn.dbo.ghr_msg_tbl
			 SELECT 'U00049'					As msg_id, 
					@emp_id_01					As msg_p1,
					@empl_id_01					As msg_p2,
					'The pay element id was invalid thus causing the employer to be blank.'	As msg_desc
					
			 -- Historical Message for reporting purpose	
			INSERT INTO DBShrpn.dbo.ghr_historical_message	
			SELECT  'U00049'						As msg_id,
					'07'							As event_id,
					@emp_id_01 						As emp_id,
					@eff_date_01					As eff_date,
					@pay_element_desc_06			As pay_element_id,					
					@emp_id_01						As msg_p1,
					RTRIM(@pay_element_desc_06)		As msg_p2,
					'The pay element id, ' + RTRIM(@pay_element_desc_06) + ', is invalid.' As msg_desc,
					@p_activity_date				AS activity_date
			-- End of Historical Message for reporting purpose
			
			SELECT  @w_fatal_error = '5'						
		
		END  
		ELSE                             
		IF ( @curr_empl_id <> @empl_id_01 )
		BEGIN
--		SELECT 'Step3.1.1'
			 UPDATE	DBShrpn.dbo.ghr_bankinfo_events_aud
			    SET activity_status	=	'02'					
			  WHERE activity_date	=	@p_activity_date
			    AND emp_id_01		=	@emp_id_01
			    AND event_id_01		=	'07'			    
			 		 
			 INSERT INTO DBShrpn.dbo.ghr_msg_tbl
			 SELECT 'U00050'					As msg_id, 
					@emp_id_01					As msg_p1,
					@empl_id_01					As msg_p2,
					'Employer id does not match the current employer id.'	As msg_desc
					
			 -- Historical Message for reporting purpose	
			INSERT INTO DBShrpn.dbo.ghr_historical_message	
			SELECT  'U00050'						As msg_id,
					'07'							As event_id,
					@emp_id_01 						As emp_id,
					@eff_date_01					As eff_date,
					@pay_element_desc_06			As pay_element_id,					
					@emp_id_01						As msg_p1,
					@empl_id_01						As msg_p2,
					'Employer id, ' + RTRIM(@empl_id_01) + ', does not match the current record employer id,'  + @curr_empl_id + '.'		As msg_desc,
					@p_activity_date				AS activity_date
			-- End of Historical Message for reporting purpose
			
			SELECT  @w_fatal_error = '5'						

		END
		
		--
-- Check to see if the pay element id interfaced from HCM is assigned to this employee.
--
--    SELECT 'Step3.2', @emp_id_01, @pay_element_desc_06
    
		IF  EXISTS (SELECT * FROM [DBShrpn].[dbo].[emp_pay_element] pe
                     WHERE [emp_id]	=	@emp_id_01 AND [pay_element_id]  =   @pay_element_desc_06)
		BEGIN
            SELECT @pay_element_id_exists = 'Y'
		END
		ELSE
            SELECT @pay_element_id_exists = 'N'
            
--SELECT '@pay_element_id_exists', @pay_element_id_exists          

--
-- Check to see if the employee has been assigned this pay element.
--	
        SELECT @pay_element_id_exists

		IF  @pay_element_id_exists = 'N'
		BEGIN  
		     SELECT 'Step3.3'
 			 UPDATE	DBShrpn.dbo.ghr_bankinfo_events_aud
			    SET activity_status	=	'02'					
			  WHERE activity_date	=	@p_activity_date
			    AND emp_id_01		=	@emp_id_01
			    AND event_id_01		=	'07'			    
			 		 
			 INSERT INTO DBShrpn.dbo.ghr_msg_tbl
			 SELECT 'U00051'					As msg_id,
					@emp_id_01					As msg_p1,
					@pay_element_desc_06		As msg_p2,
					'This pay element has never been assigned to this employee'	As msg_desc
					
			 -- Historical Message for reporting purpose	
			 INSERT INTO DBShrpn.dbo.ghr_historical_message	
			 SELECT  'U00051'						As msg_id,
			 		 '07'							As event_id,
			 		 @emp_id_01 					As emp_id,
					 @eff_date_01					As eff_date,
					 @pay_element_desc_06			As pay_element_id,					
					 @emp_id_01						As msg_p1,
					 @pay_element_desc_06			As msg_p2,
					 'This pay element id, ' + RTRIM(@pay_element_desc_06) + ', has never been assigned to this employee'	As msg_desc,
					 @p_activity_date				AS activity_date
			-- End of Historical Message for reporting purpose		
							
					
		     SELECT  @w_fatal_error = '5'
		END	   
		
	END	

--
-- Make sure that the interface eff date is equal or greater than the current eff date.
--
/*
   IF @curr_eff_date  >  CONVERT(datetime,RTRIM(@eff_date_01)) 
   BEGIN
  --          SELECT 'Generated Error'
   
       		 UPDATE	DBShrpn.dbo.ghr_bankinfo_events_aud
			    SET activity_status	=	'02'					
			  WHERE activity_date	=	@p_activity_date
			    AND emp_id_01		=	@emp_id_01
			    AND event_id_01		=	'07'			    
			 		 
			 INSERT INTO DBShrpn.dbo.ghr_msg_tbl
			 SELECT 'U00053'					As msg_id, 
					@emp_id_01					As msg_p1,
					@bank_id_07					As msg_p2,
					'The interface eff date must be equal or greater current eff date.'	As msg_desc
					
			 -- Historical Message for reporting purpose	
			INSERT INTO DBShrpn.dbo.ghr_historical_message	
			SELECT  'U00053'						As msg_id,
					'07'							As event_id,
					@emp_id_01 						As emp_id,
					@eff_date_01					As eff_date,
					@pay_element_desc_06			As pay_element_id,					
					@emp_id_01						As msg_p1,
					@eff_date_01					As msg_p2,
					'The interface eff date, ' + RTRIM(@eff_date_01) + ',  must be equal or greater current eff date, ' + CONVERT(char,@curr_eff_date,112) + '.' 	As msg_desc,
					@p_activity_date				AS activity_date
			-- End of Historical Message for reporting purpose						
					
		   SELECT  @w_fatal_error = '5'
			 
--			 GOTO BYPASS_EMPLOYEE
   END
   */

--
-- Check to see if the bank id exists
--	           
--    SELECT 'Step5',@bank_id_07
	IF  NOT EXISTS (SELECT * FROM [DBSbank].[dbo].[bank_branch] WHERE bank_id  = RTRIM(@bank_id_07))
		BEGIN
--       SELECT 'Step5.1'
			 UPDATE	DBShrpn.dbo.ghr_bankinfo_events_aud
			    SET activity_status	=	'02'					
			  WHERE activity_date	=	@p_activity_date
			    AND emp_id_01		=	@emp_id_01
			    AND event_id_01		=	'07'			    
			 		 
			 INSERT INTO DBShrpn.dbo.ghr_msg_tbl
			 SELECT 'U00052'					As msg_id, 
					@emp_id_01					As msg_p1,
					@bank_id_07					As msg_p2,
					'Bank id does not exists.'	As msg_desc
					
			 -- Historical Message for reporting purpose	
			INSERT INTO DBShrpn.dbo.ghr_historical_message	
			SELECT  'U00052'						As msg_id,
					'07'							As event_id,
					@emp_id_01 						As emp_id,
					@eff_date_01					As eff_date,
					@pay_element_desc_06			As pay_element_id,					
					@emp_id_01						As msg_p1,
					@bank_id_07						As msg_p2,
					'Bank id, ' + RTRIM(@bank_id_07) + ', does not exist.'		As msg_desc,
					@p_activity_date				AS activity_date
			-- End of Historical Message for reporting purpose						
					
		   SELECT  @w_fatal_error = '5'
			 
--			 GOTO BYPASS_EMPLOYEE 
		END


   	IF  @w_fatal_error = '5' GOTO BYPASS_EMPLOYEE
		

-- Beginning of Main Logic

IF EXISTS (SELECT * FROM tempdb.dbo.sysobjects WHERE name like '#t0%')
   DROP TABLE #t0

SELECT [emp_id]
      ,[empl_id]
      ,[pay_element_id] 
      ,[eff_date]
      ,[eff_date]      AS [new_eff_date]
      ,[eff_date]      AS [prior_eff_date]     -- update the new current record with this date. This will like the new record back to the old record.
      ,[next_eff_date]
      ,@eff_date_01    AS new_next_eff_date      -- update the old current record with this date. This will point the old record to the new record  
      ,[inactivated_by_pay_element_ind]
      ,[start_date] 
      ,[stop_date]
      ,@eff_date_01    AS [new_start_date]
      ,@end_of_time    AS [new_stop_date]
      ,[change_reason_code]
      ,[pay_element_pay_pd_sched_code]
      ,[calc_meth_code]
      ,[standard_calc_factor_1]
      ,[standard_calc_factor_2]
      ,[special_calc_factor_1]
      ,[special_calc_factor_2]
      ,[special_calc_factor_3]
      ,[special_calc_factor_4]
      ,[rate_tbl_id]
      ,[rate_code]
      ,[payee_name]
      ,[payee_pmt_sched_code]
      ,[payee_bank_transit_nbr]
      ,[payee_bank_acct_nbr]
      ,[pmt_ref_nbr]
      ,[pmt_ref_name]
      ,[vendor_id]
      ,[limit_amt]
      ,[guaranteed_net_pay_amt]
      ,[start_after_pay_element_id]
      ,[indiv_addr_type_to_print_code]
      ,@bank_id_07   AS [bank_id]
      ,@direct_deposit_bank_acct_nbr_07 AS  [direct_deposit_bank_acct_nbr]
      ,@bank_acct_type_code_07 AS [bank_acct_type_code]
      ,[pay_pd_arrears_rec_fixed_amt]
      ,[pay_pd_arrears_rec_fixed_pct]
      ,[min_pay_pd_recovery_amt]
      ,[user_amt_1]
      ,[user_amt_2]
      ,[user_monetary_amt_1]
      ,[user_monetary_amt_2]
      ,[user_monetary_curr_code]
      ,[user_code_1]
      ,[user_code_2]
      ,[user_date_1]
      ,[user_date_2]
      ,[user_ind_1]
      ,[user_ind_2]
      ,[user_text_1]
      ,[user_text_2]
      ,[pension_tot_distn_ind]
      ,[pension_distn_code_1]
      ,[pension_distn_code_2]
      ,[pre_1990_rpp_ctrb_type_cd]
      ,[chgstamp]
      ,[first_roth_ctrb]
      ,[ira_sep_simple_ind]
      ,[taxable_amt_not_determined_ind]
  INTO #t0
  FROM [DBShrpn].[dbo].[emp_pay_element] pe
WHERE [emp_id]			=	@emp_id_01
--  AND [empl_id]			=	@empl_id_01
  AND [pay_element_id]  =   @pay_element_desc_06
  AND [eff_date]        =   (SELECT MAX(eff_date) FROM [DBShrpn].[dbo].[emp_pay_element] t 
                              WHERE t.emp_id = pe.emp_id AND t.pay_element_id = pe.pay_element_id) 
-- SELECT * FROM #t0                             
--
--
--

/*
   
SELECT [emp_id]
      ,[empl_id]
      ,[pay_element_id] 
      ,@eff_date_01 AS [eff_date]
      ,[prior_eff_date]
      ,[next_eff_date]
      ,[inactivated_by_pay_element_ind]
      ,[start_date]
      ,[stop_date]
      ,[change_reason_code]
      ,[pay_element_pay_pd_sched_code]
      ,[calc_meth_code]
      ,[standard_calc_factor_1]
      ,[standard_calc_factor_2]
      ,[special_calc_factor_1]
      ,[special_calc_factor_2]
      ,[special_calc_factor_3]
      ,[special_calc_factor_4]
      ,[rate_tbl_id]
      ,[rate_code]
      ,[payee_name]
      ,[payee_pmt_sched_code]
      ,[payee_bank_transit_nbr]
      ,[payee_bank_acct_nbr]
      ,[pmt_ref_nbr]
      ,[pmt_ref_name]
      ,[vendor_id]
      ,[limit_amt]
      ,[guaranteed_net_pay_amt]
      ,[start_after_pay_element_id]
      ,[indiv_addr_type_to_print_code]
      ,@bank_id_07   AS [bank_id]
      ,@direct_deposit_bank_acct_nbr_07 AS  [direct_deposit_bank_acct_nbr]
      ,@bank_acct_type_code_07 AS [bank_acct_type_code]
      ,[pay_pd_arrears_rec_fixed_amt]
      ,[pay_pd_arrears_rec_fixed_pct]
      ,[min_pay_pd_recovery_amt]
      ,[user_amt_1]
      ,[user_amt_2]
      ,[user_monetary_amt_1]
      ,[user_monetary_amt_2]
      ,[user_monetary_curr_code]
      ,[user_code_1]
      ,[user_code_2]
      ,[user_date_1]
      ,[user_date_2]
      ,[user_ind_1]
      ,[user_ind_2]
      ,[user_text_1]
      ,[user_text_2]
      ,[pension_tot_distn_ind]
      ,[pension_distn_code_1]
      ,[pension_distn_code_2]
      ,[pre_1990_rpp_ctrb_type_cd]
      ,[chgstamp]
      ,[first_roth_ctrb]
      ,[ira_sep_simple_ind]
      ,[taxable_amt_not_determined_ind]
  INTO #t0
  FROM [DBShrpn].[dbo].[emp_pay_element] pe
WHERE [emp_id]			=	@emp_id_01
  AND [empl_id]			=	@empl_id_01
  AND [pay_element_id]  =   @pay_element_desc_06
  AND [eff_date]        =   (SELECT MAX(eff_date) FROM [DBShrpn].[dbo].[emp_pay_element] t 
                             WHERE t.emp_id = pe.emp_id AND t.empl_id = pe.empl_id AND t.pay_element_id = pe.pay_element_id)
 */
--          Select '6.0'                
IF EXISTS (	SELECT * 
              FROM [DBShrpn].[dbo].[emp_pay_element] pe
            INNER JOIN #t0 t 
                    ON t.[emp_id]			=	pe.emp_id
                   AND t.[empl_id]		    =	pe.empl_id
                   AND t.[pay_element_id]   =   pe.pay_element_id
                   AND t.[new_eff_date]     =   pe.eff_date)
    BEGIN
    -- This logic updates the existing version of the employee pay element --
--          Select '6.1'
		   UPDATE [DBShrpn].[dbo].[emp_pay_element]
		      SET [bank_id]						 = t.[bank_id], 	
				  [direct_deposit_bank_acct_nbr] = t.[direct_deposit_bank_acct_nbr],
                  [bank_acct_type_code]          = t.[bank_acct_type_code]
             FROM [DBShrpn].[dbo].[emp_pay_element] pe
       INNER JOIN #t0 t
               ON t.emp_id = pe.emp_id AND t.empl_id = pe.empl_id AND t.pay_element_id = pe.pay_element_id AND t.eff_date = pe.eff_date
    END
    /*
ELSE
    BEGIN
    -- This logic creates an new version of the employee pay element --
           INSERT INTO [DBShrpn].[dbo].[emp_pay_element]
           SELECT [emp_id]
                 ,[empl_id]
                 ,[pay_element_id] 
                 ,[new_eff_date]   AS [eff_date]
                 ,[prior_eff_date] AS [prior_eff_date]
                 ,[new_stop_date]  AS [next_eff_date]
                 ,[inactivated_by_pay_element_ind]
                 ,[new_start_date] AS [start_date]
                 ,[new_stop_date]  AS [stop_date]
                 ,[change_reason_code]
                 ,[pay_element_pay_pd_sched_code]
                 ,[calc_meth_code]
                 ,[standard_calc_factor_1]
                 ,[standard_calc_factor_2]
                 ,[special_calc_factor_1]
                 ,[special_calc_factor_2]
                 ,[special_calc_factor_3]
                 ,[special_calc_factor_4]
                 ,[rate_tbl_id]
                 ,[rate_code]
                 ,[payee_name]
                 ,[payee_pmt_sched_code]
                 ,[payee_bank_transit_nbr]
                 ,[payee_bank_acct_nbr]
                 ,[pmt_ref_nbr]
                 ,[pmt_ref_name]
                 ,[vendor_id]
                 ,[limit_amt]
                 ,[guaranteed_net_pay_amt]
                 ,[start_after_pay_element_id]
                 ,[indiv_addr_type_to_print_code]
                 ,[bank_id]
                 ,[direct_deposit_bank_acct_nbr]
                 ,[bank_acct_type_code]
                 ,[pay_pd_arrears_rec_fixed_amt]
                 ,[pay_pd_arrears_rec_fixed_pct]
                 ,[min_pay_pd_recovery_amt]
                 ,[user_amt_1]
                 ,[user_amt_2]
                 ,[user_monetary_amt_1]
                 ,[user_monetary_amt_2]
                 ,[user_monetary_curr_code]
                 ,[user_code_1]
                 ,[user_code_2]
                 ,[user_date_1]
                 ,[user_date_2]
                 ,[user_ind_1]
                 ,[user_ind_2]
                 ,[user_text_1]
                 ,[user_text_2]
                 ,[pension_tot_distn_ind]
                 ,[pension_distn_code_1]
                 ,[pension_distn_code_2]
                 ,[pre_1990_rpp_ctrb_type_cd]
                 ,[chgstamp]
                 ,[first_roth_ctrb]
                 ,[ira_sep_simple_ind]
                 ,[taxable_amt_not_determined_ind]
       FROM #t0
 --
 --  Update the old record to point to the new record.
 --      
       UPDATE [DBShrpn].[dbo].[emp_pay_element]
          SET next_eff_date  =  new_eff_date,
                  stop_date  = DATEADD(day,-1,CONVERT(datetime,new_start_date))
         FROM [DBShrpn].[dbo].[emp_pay_element] pe
   INNER JOIN #t0 t
           ON t.[emp_id]		   =   pe.[emp_id]
          AND t.[empl_id]		   =   pe.[empl_id]
          AND t.[pay_element_id]   =   pe.[pay_element_id]
          AND t.[eff_date]         =   pe.[eff_date] 
          
--
-- If the records do not exist, then create them: emp_pay_element_non_dtd
--
       INSERT INTO [DBShrpn].[dbo].[emp_pay_element_non_dtd]
       SELECT t.[emp_id]
             ,t.[empl_id]
             ,t.[pay_element_id]
             ,CAST(0.00				AS money)	As [arrears_bal_amt]
             ,CAST(0				AS tinyint)	AS [recover_over_nbr_of_pay_pds]
             ,CAST('9'				AS char(1))	AS [wh_status_code]
             ,CAST('N'				AS char(1))	AS [calc_last_pay_pd_ind]
             ,CAST('2999-12-31 00:00:00.000'    AS datetime)	AS [prenotification_check_date]
             ,CAST('4'				AS char(1))	AS [prenotification_code]
             ,CAST(0				AS smallint)	AS [chgstamp]
       FROM #t0  t
       WHERE t.emp_id + t.empl_id + t.pay_element_id not in 
             (SELECT emp_id + empl_id + pay_element_id 
                FROM [DBShrpn].[dbo].[emp_pay_element_non_dtd])

    END 
    
 */	
	BYPASS_EMPLOYEE:
				 
--	SELECT 'Step9' 
	
	SELECT @cnt = @cnt + 1
	
END    
-- End of Main Logic
--
-- Notify the users of all the issues
--

--
-- Send notification of warning message U00013  -- < Name Change Section (4) >
--

SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd 
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00013'

SELECT @max = COUNT(*)  
--  SELECT *
  FROM DBShrpn.dbo.ghr_employee_events
 WHERE [event_id_01] = '04'
SELECT @maxx = CAST(@max As CHAR(06))
SELECT @special_value_exists = 0
SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)
SELECT @msg_id = 'U00013'

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
-- Send notification of warning message U00016  -- Total Global HR Salary Change:
--

SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd 
--  SELECT *
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00016'

SELECT @max = COUNT(*)  
--  SELECT *
  FROM DBShrpn.dbo.ghr_employee_events
 WHERE [event_id_01] = '04'
SELECT @maxx = CAST(@max As CHAR(06))
SELECT @special_value_exists = 0
SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)
SELECT @msg_id = 'U00016'

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
-- Send notification of warning message U00013 -- Employee does not exists Message
--

IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_message_temp_4]') AND type in (N'U'))
	DROP TABLE [dbo].[ghr_message_temp_4]


CREATE TABLE [dbo].[ghr_message_temp_4](
	[ID]							[int] IDENTITY(1,1) NOT NULL,
	[msg_id]						[char](15)	NOT NULL,
	[msg_p1]						[char](15)	NOT NULL,
	[msg_p2]						[char](15)	NOT NULL,
	[msg_desc]						[char](255) NOT NULL
)


SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd 
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00013'

INSERT INTO DBShrpn.dbo.ghr_message_temp_4	
SELECT * 
  FROM DBShrpn.dbo.ghr_msg_tbl
 WHERE msg_id = 'U00013'
  
SET @cnt = 1

SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_4
 

WHILE (@cnt <= @max)
BEGIN

SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_4 t4 WHERE t4.[ID] = @cnt

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
  FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00013'
    
SELECT @cnt = @cnt + 1;

END
--
--	End of warning message U00003 
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
END

--D2

 
/****** Object:  StoredProcedure [dbo].[usp_ins_name_change]    Script Date: 8/26/2024 8:01:27 PM ******/
IF EXISTS (SELECT * FROM DBShrpn.dbo.sysobjects WHERE name = 'usp_ins_name_change')
   DROP PROCEDURE [dbo].[usp_ins_name_change]
 
GO
ALTER AUTHORIZATION ON [dbo].[usp_ins_bankinfo] TO  SCHEMA OWNER 
GO
