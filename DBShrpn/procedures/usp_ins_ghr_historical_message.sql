USE DBShrpn
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'dbo.usp_ins_ghr_historical_message', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_ins_ghr_historical_message
    IF OBJECT_ID(N'dbo.usp_ins_ghr_historical_message') IS NOT NULL
        PRINT N'<<< FAILED DROPPING PROCEDURE dbo.usp_ins_ghr_historical_message >>>'
    ELSE
        PRINT N'<<< DROPPED PROCEDURE dbo.usp_ins_ghr_historical_message >>>'
END
GO

/*************************************************************************************
   SP Name:       usp_ins_ghr_historical_message

   Description:   Wrapper procedure that inserts records into table DBShrpn.dbo.ghr_historical_message

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
   1.0.00   08/27/2025  CJP                     - Created


************************************************************************************/

CREATE PROCEDURE dbo.usp_ins_ghr_historical_message
    (
      @p_msg_id             char(15)
    , @p_event_id           char(02)
    , @p_emp_id             char(15)
    , @p_eff_date           char(10)
    , @p_pay_element_id     char(10)
    , @p_msg_p1             varchar(255)
    , @p_msg_p2             varchar(255)
    , @p_msg_desc           varchar(4000)
    , @p_activity_date      datetime
    )
AS


BEGIN

    INSERT INTO DBShrpn.dbo.ghr_historical_message
    VALUES
    (
      @p_msg_id
    , @p_event_id
    , @p_emp_id
    , @p_eff_date
    , @p_pay_element_id
    , @p_msg_p1
    , @p_msg_p2
    , @p_msg_desc
    , @p_activity_date
    )

END
GO

ALTER AUTHORIZATION ON dbo.usp_ins_ghr_historical_message TO  SCHEMA OWNER
GO

IF OBJECT_ID(N'dbo.usp_ins_ghr_historical_message', N'P') IS NOT NULL
    PRINT N'<<< CREATED PROCEDURE dbo.usp_ins_ghr_historical_message >>>'
ELSE
    PRINT N'<<< FAILED CREATING PROCEDURE dbo.usp_ins_ghr_historical_message >>>'
GO