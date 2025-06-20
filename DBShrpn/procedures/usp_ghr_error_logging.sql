USE [FinTransform]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



/*************************************************************************************
   SP Name:       usp_ghr_error_logging

   Description:

   Parameters:
      @p_batch_id          = Batch ID
      @p_procedure_id      = Procedure ID
      @p_source_id         = Source ID
      @p_created_date      = Current date time stamp
      @p_start_date        = Start Date (1st of the month)
      @p_as_of_date        = As of Date (End of month date of current period)
      @p_end_date          = End Date

   Example:
      exec dbo.spRetReconBalanceIntercompanyDBCashClearing
         @p_batch_id        = 1
        ,@p_procedure_id    = 100
        ,@p_source_id       = 50001
        ,@p_created_date    = '2021-01-01 13:10:11:000'
        ,@p_start_date      = '2021-01-01 12:00:00:000'
        ,@p_as_of_date      = '2021-01-31 00:00:00:000'
        ,@p_end_date        = '2021-01-31 23:59:59:999'


   Revision history:
   version  date        developer   SCR         description
   -------  ----------  ---------   -----       ------------------------------------
   1.0.00   06/19/2025  CJP                     - Wrapper procedure that logs entries into SmartStream table DBSpscb.dbo.ssw_psc_messages_work


************************************************************************************/

    --JAG  
    --
    -- Send notification of warning message U00005 -- Employer (@1) does not exist for employee: @2 - defaulting 99999'
    --

    IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_message_temp_5]') AND type in (N'U'))
        DROP TABLE [dbo].[ghr_message_temp_5]


    CREATE TABLE [dbo].[ghr_message_temp_5](
        [ID]							[int] IDENTITY(1,1) NOT NULL,
        [msg_id]						[char](15)	NOT NULL,
        [msg_p1]						[char](15)	NOT NULL,
        [msg_p2]						[char](15)	NOT NULL,
        [msg_desc]						[char](255) NOT NULL
    )


    SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd 
    FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00005'

    INSERT INTO DBShrpn.dbo.ghr_message_temp_5	
    SELECT * 
    FROM DBShrpn.dbo.ghr_msg_tbl
    WHERE msg_id = 'U00005'
    
    SET @cnt = 1

    SELECT @max = COUNT(ID) FROM DBShrpn.dbo.ghr_message_temp_5
    

    WHILE (@cnt <= @max)
    BEGIN

    SELECT @msg_id = msg_id, @msg_p1 = msg_p1, @msg_p2 = msg_p2 FROM DBShrpn.dbo.ghr_message_temp_5 t5 WHERE t5.[ID] = @cnt

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