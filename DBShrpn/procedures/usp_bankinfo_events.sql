USE DBShrpn
GO
/****** Object:  StoredProcedure dbo.usp_bankinfo_events    Script Date: 4/1/2025 4:33:00 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

--(@USER_ID      char(30))

CREATE procedure dbo.usp_bankinfo_events

(@USER_ID      char(30))

As
 Begin

    --DECLARE @ret int EXEC @ret = sp_dbs_authenticate if @ret != 0 RETURN
	-- Exec dbo.usp_bankinfo_events 'DBS'
	--WAITFOR DELAY '00:01';  
   -- DECLARE @USER_ID			char(30)
   -- SELECT * FROM DBShrpn.dbo.ghr_historical_message WHERE event_id = '07'
   -- SELECT * FROM DBShrpn.dbo.ghr_bankinfo_events_aud t WHERE t.event_id_01	=  '07'
	DECLARE @w_activity_date	datetime
	DECLARE @w_inputfile		varchar(254)
	DECLARE @w_wflow_userid		varchar(30)
	DECLARE @w_activity_status	char(02)
	DECLARE @w_status			int
	DECLARE @w_userid			varchar(30)
	DECLARE @w_batchname		varchar(08)
	DECLARE @w_qualifier		varchar(30)
 
	--SET @USER_ID = 'JGROSS'
	-- Find the Batch name and qualifer for the job running the Bulk Copy
	SELECT	@w_userid		=	psc_userid
		   ,@w_batchname	=	psc_batchname
		   ,@w_qualifier	=	psc_qualifier
      FROM DBSpscb.dbo.psc_step 
     WHERE psc_userid		= @USER_ID 
       AND psc_pgm_parms	= 'ghr_BANKINFO_EVENTS'
	
	SET		@w_activity_status	= '00'
	SET		@w_activity_date = CAST(CONVERT(CHAR(20),GETDATE(),120) as DATETIME)
	
	SELECT  @w_wflow_userid = @USER_ID
	
	SELECT  @w_inputfile	=	batch_parameter_3
     --       @w_wflow_userid		=	batch_parameter_7	
	FROM	DBSentp.dbo.batch_parameters
	WHERE   batch_parameter_key = 'ghr_EMPLOYEE_EVENTS'
	
	--SELECT @w_inputfile,@w_wflow_userid,@activity_status
	
	INSERT INTO DBShrpn.dbo.ghr_bankinfo_events_aud
    SELECT	
		 event_id_01
		,emp_id_01 
		,eff_date_01
		,first_name_01
		,first_middle_name_01
		,last_name_01
		,empl_id_01
		,national_id_1_type_code_01
		,national_id_1_01
		,organization_group_id_01
		,organization_chart_name_01
		,organization_unit_name_01
		,emp_status_classn_code_01
		,position_title_01
		,employment_type_code_01
		,annual_salary_amt_01
		,begin_date_02
		,end_date_02
		,pay_status_code_03
		,pay_group_id_03
		,pay_element_ctrl_grp_id_03
		,time_reporting_meth_code_03
		,employment_info_chg_reason_cd_03
		,emp_location_code_03
		,emp_status_code_5
		,reason_code_5	
		,emp_expected_return_date_5	
		,pay_through_date_5	
		,emp_death_date_5	
		,consider_for_rehire_ind_5	
		,pay_element_desc_06	
		,emp_calculation_06
		,bank_id_07
		,direct_deposit_bank_acct_nbr_07
		,bank_acct_type_code_07
    	,@w_activity_date		As activity_date
		,@w_wflow_userid		As activity_user
		,@w_activity_status		As activity_status 

    FROM DBShrpn.dbo.ghr_bankinfo_events bi
   WHERE NOT EXISTS (SELECT * FROM DBShrpn.dbo.ghr_bankinfo_events_aud t
                       WHERE t.event_id_01	=   bi.event_id_01
                         AND t.emp_id_01		=	bi.emp_id_01
                         AND t.activity_date	=	@w_activity_date)
                         
					
	IF  EXISTS (SELECT event_id_01 FROM DBShrpn.dbo.ghr_bankinfo_events WHERE event_id_01 = '07' )
		BEGIN
			EXEC	DBShrpn.dbo.usp_ins_bankinfo @w_userid,
					@w_batchname,
					@w_qualifier,
					@w_activity_date,
					@w_wflow_userid,
					@w_activity_status,
					@w_status
		END 


	DELETE DBShrpn.dbo.ghr_bankinfo_events
    
End



 
 
GO
ALTER AUTHORIZATION ON dbo.usp_bankinfo_events TO  SCHEMA OWNER 
GO
