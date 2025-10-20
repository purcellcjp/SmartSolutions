USE DBShrpn
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'dbo.usp_verification_rpt_csv', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_verification_rpt_csv
    IF OBJECT_ID(N'dbo.usp_verification_rpt_csv') IS NOT NULL
        PRINT N'<<< FAILED DROPPING PROCEDURE dbo.usp_verification_rpt_csv >>>'
    ELSE
        PRINT N'<<< DROPPED PROCEDURE dbo.usp_verification_rpt_csv >>>'
END
GO

/*************************************************************************************
    SP Name:       usp_verification_rpt_csv

    Description:    HCM Interface Verification Report

                    Creates a csv report of the most recent execution
                    of the GHR Interfaces job scheduler job.




    Event                       ID
    -----------------------     ---
    Update New Hires            01
    Employee Salary Changes     02
    Employee Transfers          03
    Employee Name Change        04
    Employee Status Change      05
    Employee Pay Allowances     06
    Employee Pay Group          08
    Employee Labor Group        09
    Employee Position Title     10

    Parameters:
        None



    Example:
        EXEC DBShrpn.dbo.usp_verification_rpt_csv


   Revision history:
   version  date        developer   SCR         description
   -------  ----------  ---------   -----       ------------------------------------
   1.0.00   08/27/2025  CJP                     - Cloned from GOG version

************************************************************************************/
CREATE procedure dbo.usp_verification_rpt_csv
AS

BEGIN


    DECLARE @v_EVENT_ID_NEW_HIRE            char(2)             = '01'
    DECLARE @v_EVENT_ID_SALARY_CHANGE       char(2)             = '02'
    DECLARE @v_EVENT_ID_TRANSFER            char(2)             = '03'
    DECLARE @v_EVENT_ID_NAME_CHANGE         char(2)             = '04'
    DECLARE @v_EVENT_ID_STATUS_CHANGE       char(2)             = '05'
    DECLARE @v_EVENT_ID_PAY_ELE             char(2)             = '06'
    DECLARE @v_EVENT_ID_PAY_GROUP           char(2)             = '08'
    DECLARE @v_EVENT_ID_LABOR_GROUP         char(2)             = '09'
    DECLARE @v_EVENT_ID_POSITION_TITLE      char(2)             = '10'


    DECLARE @v_ACTIVITY_STATUS_GOOD         char(2)             = '00'
    DECLARE @v_ACTIVITY_STATUS_WARNING      char(2)             = '01'
    DECLARE @v_ACTIVITY_STATUS_BAD          char(2)             = '02'
    DECLARE @v_ACTIVITY_STATUS_UNPROCESSED  char(2)             = '99'

    DECLARE @v_PSC_BATCHNAME                char(08)            = 'GHR'
    DECLARE @w_PSC_QUALIFIER                char(30)            = 'INTERFACES'
    DECLARE @w_PSC_PSC_PGM_PARMS            varchar(255)        = 'GHR_EMPLOYEE_EVENTS'
    DECLARE @w_user_id                      char(30)			= 'DBS'
    DECLARE @w_activity_date                datetime
    DECLARE @w_activity_date_char           varchar(25)


    CREATE TABLE #tbl_vhcmrpt
    (
      row_id                                int	IDENTITY(1,1)   NOT NULL
    , activity_date                         varchar(255)            NOT NULL
    , event_id                              varchar(255)            NOT NULL
    , event_desc                            varchar(255)            NOT NULL
    , activity_status                       varchar(255)            NOT NULL
    , activity_status_desc                  varchar(255)            NOT NULL
    , emp_id                                varchar(255)            NOT NULL
    , eff_date                              varchar(255)            NOT NULL
    , first_name                            varchar(255)            NOT NULL
    , last_name                             varchar(255)            NOT NULL
    , empl_id                               varchar(255)            NOT NULL
    , pay_group_id                          varchar(255)            NOT NULL
    , position_title                        varchar(255)            NOT NULL
    , proc_flag                             varchar(255)            NOT NULL
    , msg_id                                varchar(255)            NOT NULL
    , msg_desc                              varchar(255)        NOT NULL
    )


    ---------------------------------------------------------------------------
    -- Lookup date of last job scheduler bulkcopy import
    ---------------------------------------------------------------------------
	SELECT @w_activity_date = psc_last_comp_date
    FROM DBSpscb.dbo.psc_step
    WHERE psc_userid = @w_user_id
      AND psc_batchname = @v_PSC_BATCHNAME
      AND psc_qualifier = @w_PSC_QUALIFIER
      AND psc_pgm_parms = @w_PSC_PSC_PGM_PARMS     -- bulkcopy step


	--SET @w_activity_date = '2025-10-13 10:18:14.127'


    ---------------------------------------------------------------------------
    -- Add column headers to dataset
    ---------------------------------------------------------------------------
    INSERT INTO #tbl_vhcmrpt
    VALUES (
             'Activity Date'
           , 'Event ID'
           , 'Event Description'
           , 'Activity Status'
           , 'Activity Status Description'
           , 'Emp ID'
           , 'Effective Date'
           , 'First Name'
           , 'Last Name'
           , 'Employer ID'
           , 'Pay Group ID'
           , 'Position Title'
           , 'Process Flag'
           , 'Error Message ID'
           , 'Error Message Description'
           )


    ---------------------------------------------------------------------------
    -- Retrieve records from error log that do not have a matching record in audit table
    ---------------------------------------------------------------------------
    INSERT INTO #tbl_vhcmrpt
    SELECT CONVERT(char, msg.activity_date, 121) AS activity_date
         , msg.event_id
         , '' AS event_desc
         , msg.activity_status
         , ''
         , msg.emp_id
         , msg.eff_date
         , ''
         , ''
         , ''
         , ''
         , ''
         , ''
         , msg.msg_id
         , msg.msg_desc
    FROM DBShrpn.dbo.ghr_historical_message msg
    LEFT JOIN DBShrpn.dbo.ghr_employee_events_aud aud ON
            (msg.activity_date = aud.activity_date) AND
            (msg.aud_id        = aud.aud_id)
    WHERE (msg.activity_date    = @w_activity_date)
	  AND (aud.aud_id IS NULL)


    ---------------------------------------------------------------------------
    -- Retireve imported records with errors
    ---------------------------------------------------------------------------
    INSERT INTO #tbl_vhcmrpt
    SELECT CONVERT(char, aud.activity_date, 121) AS activity_date
          , aud.event_id
          , CASE aud.event_id
                WHEN @v_EVENT_ID_NEW_HIRE       THEN 'New Hire'
                WHEN @v_EVENT_ID_TRANSFER       THEN 'Transfer'
                WHEN @v_EVENT_ID_NAME_CHANGE    THEN 'Name Change'
                WHEN @v_EVENT_ID_STATUS_CHANGE  THEN 'Status Change'
                WHEN @v_EVENT_ID_PAY_ELE        THEN 'Pay Allowance'
                WHEN @v_EVENT_ID_PAY_GROUP      THEN 'Pay Group'
                WHEN @v_EVENT_ID_LABOR_GROUP    THEN 'Labor Group'
                WHEN @v_EVENT_ID_POSITION_TITLE THEN 'Position Title'
                ELSE ''
            END event_desc
         , CASE WHEN (msg.activity_status IS NULL)
                  THEN CASE aud.proc_flag
                         WHEN 'Y' THEN @v_ACTIVITY_STATUS_GOOD
                         ELSE @v_ACTIVITY_STATUS_UNPROCESSED
                       END
             ELSE msg.activity_status
           END activity_status
         , CASE WHEN (msg.activity_status IS NULL)
                  THEN CASE aud.proc_flag
                         WHEN 'Y' THEN 'Good'
                         ELSE 'Unprocessed'
                       END
             ELSE CASE msg.activity_status
                    WHEN @v_ACTIVITY_STATUS_WARNING THEN 'Warning'
                    WHEN @v_ACTIVITY_STATUS_BAD THEN 'Bad'
                    ELSE 'None'
                  END
           END activity_status_desc

         , DBShrpn.dbo.unf_ret_ganymede_to_hcm_emp_id (aud.file_source, aud.emp_id) AS emp_id
         , CONVERT(char, aud.eff_date, 121) AS eff_date
         , aud.first_name
         , aud.last_name
         , aud.empl_id
         , aud.pay_group_id
         , aud.position_title
         , aud.proc_flag
         , ISNULL(msg.msg_id, '') AS msg_id
         , ISNULL(msg.msg_desc, '') AS msg_desc
    FROM DBShrpn.dbo.ghr_employee_events_aud aud
    LEFT JOIN DBShrpn.dbo.ghr_historical_message msg ON
            (aud.activity_date = msg.activity_date) AND
            (aud.aud_id        = msg.aud_id)
    WHERE (aud.activity_date    = @w_activity_date)
    ORDER BY aud.event_id
           , msg.emp_id


    ---------------------------------------------------------------------------
    -- Output results
    ---------------------------------------------------------------------------
    SELECT activity_date
         , event_id
         , event_desc
         , activity_status
         , activity_status_desc
         , emp_id
         , eff_date
         , first_name
         , last_name
         , empl_id
         , pay_group_id
         , position_title
         , proc_flag
         , msg_id
         , msg_desc
    FROM #tbl_vhcmrpt
    ORDER BY row_id

    DROP TABLE #tbl_vhcmrpt


END  -- End of SP

GO
ALTER AUTHORIZATION ON dbo.usp_verification_rpt_csv TO SCHEMA OWNER
GO


IF OBJECT_ID(N'dbo.usp_verification_rpt_csv', N'P') IS NOT NULL
    PRINT N'<<< CREATED PROCEDURE dbo.usp_verification_rpt_csv >>>'
ELSE
    PRINT N'<<< FAILED CREATING PROCEDURE dbo.usp_verification_rpt_csv >>>'
GO
