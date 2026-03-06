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
        @p_msg_id           = Message Master ID
        @p_event_id         = Event ID
        @p_emp_id           = Employee ID
        @p_eff_date         = Effective Date
        @p_pay_element_id   = Pay Element ID
        @p_msg_p1           = Message Part I
        @p_msg_p2           = Message Part 2
        @p_msg_desc         = Message Description
        @p_activity_status  = Activity Status
        @p_activity_date    = Activity Date
        @p_audit_id         = Audit ID


    Example:
        exec dbo.usp_ins_ghr_historical_message
              @p_msg_id         = 'U00003'
            , @p_event_id       = '01'
            , @p_emp_id         = 'L694'
            , @p_eff_date       = '10/01/2025'
            , @p_pay_element_id = ''
            , @p_msg_p1         = ''
            , @p_msg_p2         = ''
            , @p_msg_desc       = 'Employee id already exists'
            , @p_activity_status  = '02'
            , @p_activity_date  = 20251001
            , @p_audit_id       = 1


   Revision history:
   version  date        developer   SCR         description
   -------  ----------  ---------   -----       ------------------------------------
   1.0.00   08/27/2025  CJP                     - Created
            01/20/2026                          - Changed param @p_eff_date to datetime from char(10)
            03/04/2026                          - Made the parameters with default blank value optional

************************************************************************************/

CREATE PROCEDURE dbo.usp_ins_ghr_historical_message
    (
      @p_msg_id             char(15)
    , @p_event_id           char(02)        = ''
    , @p_emp_id             char(15)        = ''
    , @p_eff_date           datetime        = ''
    , @p_pay_element_id     char(10)        = ''
    , @p_msg_p1             varchar(255)    = ''
    , @p_msg_p2             varchar(255)    = ''
    , @p_msg_desc           varchar(4000)
	, @p_activity_status	char(02)
    , @p_activity_date      datetime
    , @p_audit_id           char(02)        = 0
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
    , @p_activity_status
    , @p_activity_date
    , @p_audit_id
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