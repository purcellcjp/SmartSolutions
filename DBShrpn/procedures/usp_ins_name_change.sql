USE [DBShrpn]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[usp_ins_name_change]
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
    --DECLARE @p_user_id						varchar(30)
    --DECLARE @p_activity_status				char(02)
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

    --
    -- Activate these fields when testing this program standalone.
    --

    --SET @p_userid			=	'DBS'
    --SET @p_batchname		=	'GHR'
    --SET @p_qualifier		=	'INTERFACES'
    --SET @p_activity_date	=	GETDATE()
    --SET @p_user_id			=	'GHRUser'
    --SET @p_activity_status	=	'00'
    --SET @p_status			=	0



    --exec @ret = sp_dbs_authenticate
    --if @ret != 0 return -1

    SELECT @w_trace_sw = 'N'

    IF @w_trace_sw = 'Y'
    INSERT INTO DBSosxp.dbo.msg SELECT CAST(GETDATE() AS CHAR (20)) AS msg_desc

    IF @w_trace_sw = 'Y'
    INSERT INTO DBSosxp.dbo.msg SELECT 'Start usp_ins_name_change' AS msg_desc

    IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_employee_events_temp4]') AND type in (N'U'))
        DROP TABLE [dbo].[ghr_employee_events_temp4]


    CREATE TABLE [dbo].[ghr_employee_events_temp4](
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

    INSERT INTO DBShrpn.dbo.ghr_employee_events_temp4    ---#t0
    SELECT * 
    FROM DBShrpn.dbo.ghr_employee_events
    WHERE [event_id_01] = '04' 

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
			
    SET @cnt = 1

    SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_employee_events_temp4

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
        FROM DBShrpn.dbo.ghr_employee_events_temp4 t WHERE t.ID = @cnt
	  
        --
        --	This section will validate the interface data
        -- 

        --
        -- Check to see if the employee does not exists
        --	 
 
        IF  NOT EXISTS (SELECT * FROM DBShrpn.dbo.employee WHERE emp_id = @emp_id_01)
            BEGIN
                UPDATE	DBShrpn.dbo.ghr_employee_events_aud
                    SET activity_status	=	'02'					
                WHERE activity_date	=	@p_activity_date
                    AND emp_id_01		=	@emp_id_01
                    AND event_id_01		=	'04'			    
                        
                INSERT INTO DBShrpn.dbo.ghr_msg_tbl
                SELECT 'U00012'					As msg_id,
                        @emp_id_01					As msg_p1,
                        @emp_id_01					As msg_p2,
                        'Employee does not exists'	As msg_desc
                        
                -- Historical Message for reporting purpose	
                INSERT INTO DBShrpn.dbo.ghr_historical_message	
                SELECT  'U00012'						As msg_id,
                        '04'							As event_id,
                        @emp_id_01 						As emp_id,
                        @eff_date_01					As eff_date,
                        @pay_element_desc_06			As pay_element_id,					
                        @emp_id_01						As msg_p1,
                        @emp_id_01						As msg_p2,
                        'Employee does not exists'		As msg_desc,
                        @p_activity_date				AS activity_date
                -- End of Historical Message for reporting purpose						
                        
                SELECT  @w_fatal_error = '5'
                
                -- GOTO BYPASS_EMPLOYEE 
            END

   	    IF  @w_fatal_error = '5' GOTO BYPASS_EMPLOYEE
		
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
                    @employment_info_chg_reason_cd_03
                    @emp_location_code_03,
                    @emp_status_code_5,
                    @reason_code_5,
                    @emp_expected_return_date_5,
                    @pay_through_date_5,
                    @emp_death_date_5,	
                    @consider_for_rehire_ind_5,	
                    @pay_element_desc_06,
                    @emp_calculation_06
                    
            SELECT @last_name_01
        */	

        SELECT @individual_id = individual_id FROM [DBShrpn].[dbo].[employee] WHERE emp_id = @emp_id_01

        SELECT @prior_last_name = last_name FROM [DBShrpn].[dbo].[individual] WHERE individual_id = @individual_id        
        
        UPDATE	[DBShrpn].[dbo].[individual]
        SET	first_name			=	RTRIM(@first_name_01),
                first_middle_name   =   RTRIM(@first_middle_name_01),
                last_name			=	RTRIM(@last_name_01),
                prior_last_name		=	RTRIM(@prior_last_name), 
                pay_to_name			=	RTRIM(@last_name_01) + ', ' + RTRIM(@first_name_01)
                WHERE individual_id = @individual_id 
        
        UPDATE	[DBShrpn].[dbo].[employee]
            SET	emp_display_name	=	RTRIM(@last_name_01) + ', ' + RTRIM(@first_name_01)  
        WHERE emp_id = @emp_id_01 
	  
        --
        -- Update the title of the employee
        --
	
		UPDATE	[DBShrpn].[dbo].[individual_personal]
		   SET	user_text_1		=	CAST(@position_title_01 AS CHAR(50))
		 WHERE individual_id	=	@individual_id 	  

	
	    BYPASS_EMPLOYEE:
				  
	    SELECT @cnt = @cnt + 1

    END -- end of while loop

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

    -- IF @w_trace_sw = 'Y'
    --    INSERT INTO DBSosxp.dbo.msg SELECT 'End usp_ins_name_change' AS msg_desc    

    -- SELECT @p_status = 0

END
GO

ALTER AUTHORIZATION ON [dbo].[usp_ins_name_change] TO  SCHEMA OWNER 
GO
