USE [FinTransform]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



/*************************************************************************************
   SP Name:       usp_ghr_error_logging

   Description:   Wrapper procedure that logs entries into SmartStream table DBSpscb.dbo.ssw_psc_messages_work

   Parameters:
        @p_batchname
        @p_qualifier
        @p_msg_id 
        @p_severity_cd
        @p_msg_text
        @p_msg_text_2
        @p_msg_text_3


   Example:
      exec dbo.usp_ghr_error_logging



   Revision history:
   version  date        developer   SCR         description
   -------  ----------  ---------   -----       ------------------------------------
   1.0.00   06/19/2025  CJP                     - Created


************************************************************************************/

    --JAG
    --
    -- Send notification of warning message U00005 -- Employer (@1) does not exist for employee: @2 - defaulting 99999'
    --

    IF  EXISTS (SELECT * FROM DBShrpn.sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ghr_message_temp_5]') AND type in (N'U'))
        DROP TABLE [dbo].[ghr_message_temp_5]


    CREATE TABLE #ghr_message_temp_5
    (
        [ID]            [int] IDENTITY(1,1) NOT NULL,
        [msg_id]        [char](15)   NOT NULL,
        [msg_p1]        [char](15)   NOT NULL,
        [msg_p2]        [char](15)   NOT NULL,
        [msg_desc]      [char](255) NOT NULL
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