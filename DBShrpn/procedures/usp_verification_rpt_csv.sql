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
        @p_activity_date = Activity Date (i.e. '2026-02-25 12:01:09.467')
        @p_emp_id        = Employee ID (i.e. '10242')

    Tables:
        DBShrpn.dbo.ghr_historical_message
        DBShrpn.dbo.ghr_employee_events_aud


    Example:
        EXEC DBShrpn.dbo.usp_verification_rpt_csv
		'Debug Examples
		EXEC DBShrpn.dbo.usp_verification_rpt_csv
			  @p_activity_date = '2026-02-27 18:47:44.817'
			, @p_emp_id        = '82000'

   Revision history:
   version  date        developer   SCR         description
   -------  ----------  ---------   -----       ------------------------------------
   1.0.00   08/27/2025  CJP                     - Created 10/10/2025

************************************************************************************/
CREATE procedure dbo.usp_verification_rpt_csv
    (
        @p_activity_date    datetime    = NULL
    ,   @p_emp_id           char(15)    = NULL
    )
AS

BEGIN

    SET NOCOUNT ON


    DECLARE @v_ACTIVITY_STATUS_GOOD         char(2)             = '00'
    DECLARE @v_ACTIVITY_STATUS_WARNING      char(2)             = '01'
    DECLARE @v_ACTIVITY_STATUS_BAD          char(2)             = '02'
    DECLARE @v_ACTIVITY_STATUS_UNPROCESSED  char(2)             = '99'

    DECLARE @v_END_OF_TIME_DATE             datetime            = '29991231'
    DECLARE @v_END_OF_TIME_STR              varchar(255)        = CONVERT(varchar, @v_END_OF_TIME_DATE, 121)

    DECLARE @v_PSC_BATCHNAME                char(08)            = 'GHR'
    DECLARE @w_PSC_QUALIFIER                char(30)            = 'INTERFACES'
    DECLARE @w_PSC_PSC_PGM_PARMS            varchar(255)        = 'GHR_EMPLOYEE_EVENTS'
    DECLARE @w_user_id                      char(30)			--= 'DBS'
    DECLARE @w_activity_date                datetime


    CREATE TABLE #tbl_vhcmrpt
    (
      row_id                                int	IDENTITY(1,1)       NOT NULL
    , activity_date                         varchar(255)            NOT NULL
    , event_id                              varchar(255)            NOT NULL
    , event_desc                            varchar(255)            NOT NULL
    , activity_status                       varchar(255)            NOT NULL
    , activity_status_desc                  varchar(255)            NOT NULL
    , emp_id                                varchar(255)            NOT NULL
    , aud_id                                varchar(255)            NOT NULL
    , eff_date                              varchar(255)            NOT NULL
    , first_name                            varchar(255)            NOT NULL
    , last_name                             varchar(255)            NOT NULL
    , empl_id                               varchar(255)            NOT NULL
    , pay_group_id                          varchar(255)            NOT NULL
    , job_or_pos_id                         varchar(255)            NOT NULL
    , position_title                        varchar(255)            NOT NULL
    , emp_status_code                       varchar(255)            NOT NULL
    , pay_element_id                        varchar(255)            NOT NULL
    , emp_calculation                       varchar(255)            NOT NULL
    , begin_date                            varchar(255)            NOT NULL
    , end_date                              varchar(255)            NOT NULL
    , proc_flag                             varchar(255)            NOT NULL
    , msg_id                                varchar(255)            NOT NULL
    , msg_desc                              varchar(255)            NOT NULL
    )

    -- Table used to translate event ids and return event counts for all events
    -- even if event id is not present
    CREATE TABLE #tbl_event
    (
      event_id                              char(02)                NOT NULL
    , event_desc                            varchar(14)             NOT NULL
    , event_seq_id                          smallint                NOT NULL
    )

    -- Load event translation table
    INSERT INTO #tbl_event
    VALUES
      ('01', 'New Hire', 1)
    , ('02', 'Salary Change', 2)
    , ('03', 'Transfer', 3)
    , ('04', 'Name Change', 4)
    , ('05', 'Status Change', 5)
    , ('06', 'Pay Allowance', 6)
    , ('08', 'Pay Group',8)
    , ('09', 'Labor Group', 9)
    , ('10', 'Position Title', 10)


    ---------------------------------------------------------------------------
    -- Get the user id executing the job
    ---------------------------------------------------------------------------
    SET @w_user_id = SYSTEM_USER


    ---------------------------------------------------------------------------
    -- Lookup date of last job scheduler bulkcopy import
    ---------------------------------------------------------------------------
    IF (@p_activity_date IS NULL)
        SELECT @w_activity_date = psc_last_comp_date
        FROM DBSpscb.dbo.psc_step
        WHERE psc_userid = @w_user_id
        AND psc_batchname = @v_PSC_BATCHNAME
        AND psc_qualifier = @w_PSC_QUALIFIER
        AND psc_pgm_parms = @w_PSC_PSC_PGM_PARMS     -- bulkcopy step
    ELSE
        SET @w_activity_date = @p_activity_date

	--SET @w_activity_date = '2025-10-13 10:18:14.127'


    ---------------------------------------------------------------------------
    -- Add column headers to dataset
    ---------------------------------------------------------------------------
    INSERT INTO #tbl_vhcmrpt
    VALUES (
             'Activity Date'                                            -- activity_date
           , 'Event ID'                                                 -- event_id
           , 'Event Description'                                        -- event_desc
           , 'Activity Status'                                          -- activity_status
           , 'Activity Status Description'                              -- activity_status_desc
           , 'Emp ID'                                                   -- emp_id
           , 'Audit ID'                                                 -- aud_id
           , 'Effective Date'                                           -- eff_date
           , 'First Name'                                               -- first_name
           , 'Last Name'                                                -- last_name
           , 'Employer ID'                                              -- empl_id
           , 'Pay Group ID'                                             -- pay_group_id
           , 'Job/Position ID'                                          -- job_or_pos_id
           , 'Position Title'                                           -- position_title
           , 'Employee Status Code'                                     -- emp_status_code
           , 'Pay Element ID'                                           -- pay_element_id
           , 'Pay Element Amount'                                       -- emp_calculation
           , 'Begin Date'                                               -- begin_date
           , 'End Date'                                                 -- end_date
           , 'Process Flag'                                             -- proc_flag
           , 'Error Message ID'                                         -- msg_id
           , 'Error Message Description'                                -- msg_desc
           )


    ---------------------------------------------------------------------------
    -- Retrieve records from error log that do not have a matching record in audit table
    ---------------------------------------------------------------------------
    INSERT INTO #tbl_vhcmrpt
    SELECT CONVERT(char, msg.activity_date, 121)                        -- activity_date
         , msg.event_id                                                 -- event_id
         , '' AS event_desc                                             -- event_desc
         , msg.activity_status                                          -- activity_status
         , ''                                                           -- activity_status_desc
         , msg.emp_id                                                   -- emp_id
         , msg.aud_id                                                   -- aud_id
         , CONVERT(char, msg.eff_date, 121)                             -- eff_date
         , ''                                                           -- first_name
         , ''                                                           -- last_name
         , ''                                                           -- empl_id
         , ''                                                           -- pay_group_id
         , ''                                                           -- job_or_pos_id
         , ''                                                           -- position_title
         , ''                                                           -- emp_status_code
         , ''                                                           -- pay_element_id
         , '0.00'                                                       -- emp_calculation
         , @v_END_OF_TIME_STR                                           -- begin_date
         , @v_END_OF_TIME_STR                                           -- end_date
         , ''                                                           -- proc_flag
         , msg.msg_id                                                   -- msg_id
         , msg.msg_desc                                                 -- msg_desc
    FROM DBShrpn.dbo.ghr_historical_message msg
    LEFT JOIN DBShrpn.dbo.ghr_employee_events_aud aud ON
            (msg.activity_date = aud.activity_date) AND
            (msg.aud_id        = aud.aud_id)
    WHERE (msg.activity_date    = @w_activity_date)
	  AND (aud.aud_id IS NULL)


    ---------------------------------------------------------------------------
    -- Retrieve imported records with errors
    ---------------------------------------------------------------------------
    INSERT INTO #tbl_vhcmrpt
    SELECT CONVERT(char, aud.activity_date, 121) AS activity_date
         , aud.event_id
         , evt.event_desc
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
         , DBShrpn.dbo.ufn_ret_ganymede_to_hcm_emp_id (aud.file_source, aud.emp_id) AS emp_id
         , aud.aud_id
         , CONVERT(char, aud.eff_date, 121) AS eff_date
         , aud.first_name
         , aud.last_name
         , aud.empl_id
         , aud.pay_group_id
         , aud.job_or_pos_id
         , aud.position_title
         , aud.emp_status_code
         , aud.pay_element_id
         , CONVERT(varchar(20), CAST(aud.emp_calculation AS money), 1) AS emp_calculation
         , CONVERT(char, aud.begin_date, 121) AS begin_date
         , CONVERT(char, aud.end_date, 121) AS end_date
		 , aud.proc_flag
         , ISNULL(msg.msg_id, '') AS msg_id
         , ISNULL(msg.msg_desc, '') AS msg_desc
    FROM DBShrpn.dbo.ghr_employee_events_aud aud
    JOIN #tbl_event evt ON
            (aud.event_id = evt.event_id)
    LEFT JOIN DBShrpn.dbo.ghr_historical_message msg ON
            (aud.activity_date = msg.activity_date) AND
            (aud.aud_id        = msg.aud_id)
    WHERE (aud.activity_date    = @w_activity_date)
     AND (  -- employee id
          (@p_emp_id IS NULL) OR
          (
           (@p_emp_id IS NOT NULL) AND
           (aud.emp_id = @p_emp_id)
          )
         )
    ORDER BY aud.event_id
           , aud.emp_id


    ---------------------------------------------------------------------------
    -- Log Interface Statistics (i.e. event type counts)
    ---------------------------------------------------------------------------
    INSERT INTO #tbl_vhcmrpt
    SELECT CONVERT(char, @w_activity_date, 121)                            -- activity_date
            , evt.event_id                                                 -- event_id
            , evt.event_desc + ' Statistics'                            -- event_desc
            , ''                                                           -- activity_status
            , ''                                                           -- activity_status_desc
            , ''                                                           -- emp_id
            , ''                                                           -- aud_id
            , CONVERT(char, @w_activity_date, 121)                         -- eff_date
            , ''                                                           -- first_name
            , ''                                                           -- last_name
            , ''                                                           -- empl_id
            , ''                                                           -- pay_group_id
            , ''                                                           -- job_or_pos_id
            , ''                                                           -- position_title
            , ''                                                           -- emp_status_code
            , ''                                                           -- pay_element_id
            , '0.00'                                                       -- emp_calculation
            , @v_END_OF_TIME_STR                                           -- begin_date
            , @v_END_OF_TIME_STR                                           -- end_date
            , ''                                                           -- proc_flag
            , 'U00123'                                                     -- msg_id
            , evt.event_desc + ' Import Count: ' + CONVERT(varchar, count(laud.event_id)) -- msg_desc
    FROM #tbl_event evt
    LEFT JOIN (
               SELECT aud.event_id
	           FROM DBShrpn.dbo.ghr_employee_events_aud aud
			   WHERE (aud.activity_date = @w_activity_date)
			  ) laud ON
        (evt.event_id = laud.event_id)
    GROUP BY evt.event_seq_id
           , evt.event_id
           , evt.event_desc
    ORDER BY evt.event_seq_id


    ---------------------------------------------------------------------------
    -- Log total records imported
    ---------------------------------------------------------------------------
    INSERT INTO #tbl_vhcmrpt
    SELECT CONVERT(char, @w_activity_date, 121)                            -- activity_date
            , ''                                                           -- event_id
            , 'Statistics'                                                 -- event_desc
            , ''                                                           -- activity_status
            , ''                                                           -- activity_status_desc
            , ''                                                           -- emp_id
            , ''                                                           -- aud_id
            , CONVERT(char, @w_activity_date, 121)                         -- eff_date
            , ''                                                           -- first_name
            , ''                                                           -- last_name
            , ''                                                           -- empl_id
            , ''                                                           -- pay_group_id
            , ''                                                           -- job_or_pos_id
            , ''                                                           -- position_title
            , ''                                                           -- emp_status_code
            , ''                                                           -- pay_element_id
            , '0.00'                                                       -- emp_calculation
            , @v_END_OF_TIME_STR                                           -- begin_date
            , @v_END_OF_TIME_STR                                           -- end_date
            , ''                                                           -- proc_flag
            , 'U00123'                                                     -- msg_id
            , 'Total Records Imported: ' + CONVERT(varchar, count(*))      -- msg_desc
    FROM DBShrpn.dbo.ghr_employee_events_aud aud
    WHERE (aud.activity_date = @w_activity_date)


    ---------------------------------------------------------------------------
    -- Output results
    ---------------------------------------------------------------------------
    SELECT activity_date
         , event_id
         , event_desc
         , activity_status
         , activity_status_desc
         , emp_id
         , aud_id
         , eff_date
         , first_name
         , last_name
         , empl_id
         , pay_group_id
         , job_or_pos_id
         , position_title
         , emp_status_code
         , pay_element_id
         , emp_calculation
         , begin_date
         , end_date
         , proc_flag
         , msg_id
         , msg_desc
    FROM #tbl_vhcmrpt
    ORDER BY row_id

    DROP TABLE #tbl_event
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
