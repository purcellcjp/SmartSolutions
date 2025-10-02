USE DBShrpn
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'dbo.usp_verification_rpt', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_verification_rpt
    IF OBJECT_ID(N'dbo.usp_verification_rpt') IS NOT NULL
        PRINT N'<<< FAILED DROPPING PROCEDURE dbo.usp_verification_rpt >>>'
    ELSE
        PRINT N'<<< DROPPED PROCEDURE dbo.usp_verification_rpt >>>'
END
GO

/*************************************************************************************
    SP Name:       usp_verification_rpt

    Description:    HCM Interface Verification Report


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
        EXEC DBShrpn.dbo.usp_verification_rpt


   Revision history:
   version  date        developer   SCR         description
   -------  ----------  ---------   -----       ------------------------------------
   1.0.00   08/27/2025  CJP                     - Cloned from GOG version

************************************************************************************/
CREATE procedure dbo.usp_verification_rpt
AS

BEGIN

    SET NOCOUNT ON

    DECLARE @v_PSC_BATCHNAME                char(08)            = 'GHR'
    DECLARE @w_PSC_QUALIFIER                char(30)            = 'INTERFACES'
    DECLARE @w_PSC_PSC_PGM_PARMS            varchar(255)        = 'GHR_EMPLOYEE_EVENTS'

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

    DECLARE @v_SPACES_30                    char(30)            = SPACE(30)
    DECLARE @v_SPACES_50                    char(50)            = SPACE(50)

    DECLARE @w_activity_date                datetime
    DECLARE @w_distribution_id              varchar(255)

    DECLARE @w_user_id                      char(30)


    DECLARE @w_activity_status	            char(02)


    DECLARE @v_header_base                  varchar(255)
    DECLARE @v_header_err                   varchar(255)
    DECLARE @v_header_pay_ele               varchar(255)
    DECLARE @v_header_pay_ele_err           varchar(255)

    DECLARE @v_header_labor_group           varchar(255)
    DECLARE @v_header_labor_group_err       varchar(255)
    DECLARE @v_header_position_title        varchar(255)
    DECLARE @v_header_position_title_err    varchar(255)


    -- Get user executing job
    SET @w_user_id = SYSTEM_USER


    ---------------------------------------------------------------------------
    -- Lookup email(s)
    ---------------------------------------------------------------------------
    SELECT @w_distribution_id = psc_distribution_id
    FROM DBSpscb.dbo.psc_batch
    WHERE psc_userid = @w_user_id
      AND psc_batchname = @v_PSC_BATCHNAME
      AND psc_qualifier = @w_PSC_QUALIFIER


    ---------------------------------------------------------------------------
    -- Get date timestamp Batch name and qualifier for the job running the Bulk Copy
    ---------------------------------------------------------------------------
    -- This will enable the interface procedures and the verification report using the same date

	SELECT @w_activity_date = psc_last_comp_date
    FROM DBSpscb.dbo.psc_step
    WHERE psc_userid = @w_user_id
      AND psc_batchname = @v_PSC_BATCHNAME
      AND psc_qualifier = @w_PSC_QUALIFIER
      AND psc_pgm_parms = @w_PSC_PSC_PGM_PARMS     -- bulkcopy step


	-- SET @w_activity_date = '2025-08-14 16:09:31.000'


    ---------------------------------------------------------------------------
    -- Set static heading variables
    ---------------------------------------------------------------------------
    SET @v_header_base        = LEFT('Employee' + @v_SPACES_30, 20)
                              + LEFT('Effective Date' + @v_SPACES_30, 20)
                              + LEFT('First Name' + @v_SPACES_30, 20)
                              + LEFT('Last Name' + @v_SPACES_30, 20)
                              + LEFT('Employer' + @v_SPACES_30, 15)
                              + LEFT('Pay Group' + @v_SPACES_30, 15)

    SET @v_header_err         = @v_header_base
                              + LEFT('Message ID' + @v_SPACES_30, 15)
                              + 'Error Message'

    SET @v_header_pay_ele     = @v_header_base
                              + LEFT('Pay Element ID' + @v_SPACES_30, 20)
                              + LEFT('Start Date' + @v_SPACES_30, 15)
                              + LEFT('End Date' + @v_SPACES_30, 15)
                              + LEFT('Amount' + @v_SPACES_30, 20)

    SET @v_header_pay_ele_err = @v_header_pay_ele
                              + LEFT('Message ID' + @v_SPACES_30, 15)
                              + 'Error Message'

    SET @v_header_labor_group = @v_header_base
                              + LEFT('Labor Group' + @v_SPACES_30, 15)

    SET @v_header_labor_group_err = @v_header_labor_group
                                  + LEFT('Message ID' + @v_SPACES_30, 15)
                                  + 'Error Message'

    SET @v_header_position_title = @v_header_base
                              + LEFT('Position Title' + @v_SPACES_50, 50)

    SET @v_header_position_title_err = @v_header_position_title
                              + LEFT('Message ID' + @v_SPACES_30, 15)
                              + 'Error Message'



    ---------------------------------------------------------------------------
    -- Email Header
    ---------------------------------------------------------------------------
    SELECT @v_SPACES_30 + 'HCM - SS Interface Transaction Report'
    SELECT @v_SPACES_50 + 'All Entities'
    SELECT 'Extract Run Date: ' + CONVERT(char, @w_activity_date, 120)	+ SPACE(10)
    SELECT @v_SPACES_50


    ---------------------------------------------------------------------------
    -- System Error Section
    ---------------------------------------------------------------------------
    SELECT @v_SPACES_30
    SELECT 'System Errors:'
    SELECT @v_SPACES_30

    -- headers
    SELECT LEFT('Message ID' + @v_SPACES_30, 15) +
           LEFT('Event ID' + @v_SPACES_30, 15) +
           'Error Message ID'

    SELECT LEFT(msg.msg_id + @v_SPACES_30, 15) +
           LEFT(msg.event_id + @v_SPACES_30, 15) +
           RTRIM(msg.msg_desc)
    FROM DBShrpn.dbo.ghr_historical_message msg
    WHERE (CHARINDEX('U', msg.msg_id) = 0)    -- exclude message master message ids
      AND (msg.activity_date	= @w_activity_date)

    -- No records then not applicable
    IF (@@ROWCOUNT = 0)
        SELECT 'N/A'



    ---------------------------------------------------------------------------
    -- New Hire Section
    ---------------------------------------------------------------------------
    SELECT @v_SPACES_30
    SELECT	'New Hire Section:'
    SELECT @v_SPACES_30

    -- Headers
    SELECT @v_header_base

    -- Detail
    SELECT LEFT(aud.emp_id + @v_SPACES_30, 20) +
           LEFT(aud.eff_date + @v_SPACES_30, 20) +
           LEFT(aud.first_name + @v_SPACES_30, 20) +
           LEFT(aud.last_name + @v_SPACES_30, 20) +
           LEFT(aud.empl_id + @v_SPACES_30, 15) +
           LEFT(aud.pay_group_id + @v_SPACES_30, 15)
    FROM DBShrpn.dbo.ghr_employee_events_aud aud
    WHERE (aud.activity_date = @w_activity_date)
      AND (aud.event_id = @v_EVENT_ID_NEW_HIRE)
      AND (aud.proc_flag = 'Y')

    -- No records then not applicable
    IF (@@ROWCOUNT = 0)
        SELECT 'N/A'



    ---------------------------------------------------------------------------
    -- New Hire Warnings Section
    ---------------------------------------------------------------------------
    SELECT @v_SPACES_30
    SELECT 'New Hire Warnings:'
    SELECT @v_SPACES_30

    -- headers
    SELECT @v_header_err

    -- Detail
    SELECT LEFT(aud.emp_id + @v_SPACES_30, 20) +
        LEFT(aud.eff_date + @v_SPACES_30, 20) +
        LEFT(aud.first_name + @v_SPACES_30, 20) +
        LEFT(aud.last_name + @v_SPACES_30, 20) +
        LEFT(aud.empl_id + @v_SPACES_30, 15) +
        LEFT(aud.pay_group_id + @v_SPACES_30, 15) +
        LEFT(msg.msg_id + @v_SPACES_30, 15) +
        RTRIM(msg.msg_desc)
    FROM DBShrpn.dbo.ghr_historical_message msg
    JOIN DBShrpn.dbo.ghr_employee_events_aud aud ON
            (msg.activity_date = aud.activity_date) AND
            (msg.aud_id        = aud.aud_id)
    WHERE (msg.event_id        = @v_EVENT_ID_NEW_HIRE)
      AND (msg.activity_status = @v_ACTIVITY_STATUS_WARNING)
      AND (msg.activity_date   = @w_activity_date)
    ORDER BY aud.emp_id

    -- No records then not applicable
    IF (@@ROWCOUNT = 0)
        SELECT 'N/A'


    ---------------------------------------------------------------------------
    -- New Hire Error Section
    ---------------------------------------------------------------------------
    SELECT @v_SPACES_30
    SELECT 'New Hire Errors:'
    SELECT @v_SPACES_30

    -- headers
    SELECT @v_header_err

    -- Detail
    SELECT LEFT(aud.emp_id + @v_SPACES_30, 20) +
        LEFT(aud.eff_date + @v_SPACES_30, 20) +
        LEFT(aud.first_name + @v_SPACES_30, 20) +
        LEFT(aud.last_name + @v_SPACES_30, 20) +
        LEFT(aud.empl_id + @v_SPACES_30, 15) +
        LEFT(aud.pay_group_id + @v_SPACES_30, 15) +
        LEFT(msg.msg_id + @v_SPACES_30, 15) +
        RTRIM(msg.msg_desc)
    FROM DBShrpn.dbo.ghr_employee_events_aud aud
    JOIN DBShrpn.dbo.ghr_historical_message msg ON
            (msg.activity_date = aud.activity_date) AND
            (msg.aud_id        = aud.aud_id)
    WHERE (aud.activity_date   = @w_activity_date)
      AND (aud.event_id        = @v_EVENT_ID_NEW_HIRE)
      AND (msg.activity_status = @v_ACTIVITY_STATUS_BAD)
    ORDER BY aud.emp_id

    -- No records then not applicable
    IF (@@ROWCOUNT = 0)
        SELECT 'N/A'



    ---------------------------------------------------------------------------
    -- Transfer Section
    ---------------------------------------------------------------------------
    SELECT @v_SPACES_30
    SELECT	'Transfer Section:'
    SELECT @v_SPACES_30

    -- Headers
    SELECT @v_header_base

    -- Detail GOOD
    SELECT LEFT(aud.emp_id + @v_SPACES_30, 20) +
           LEFT(aud.eff_date + @v_SPACES_30, 20) +
           LEFT(aud.first_name + @v_SPACES_30, 20) +
           LEFT(aud.last_name + @v_SPACES_30, 20) +
           LEFT(aud.empl_id + @v_SPACES_30, 15) +
           LEFT(aud.pay_group_id + @v_SPACES_30, 15)
    FROM DBShrpn.dbo.ghr_employee_events_aud aud
    WHERE (aud.activity_date = @w_activity_date)
      AND (aud.event_id = @v_EVENT_ID_TRANSFER)
      AND (aud.proc_flag = 'Y')
    ORDER BY aud.emp_id

    -- No records then not applicable
    IF (@@ROWCOUNT = 0)
        SELECT 'N/A'



    ---------------------------------------------------------------------------
    -- Transfer Warnings Section
    ---------------------------------------------------------------------------
    SELECT @v_SPACES_30
    SELECT 'Transfer Warnings:'
    SELECT @v_SPACES_30

    -- headers
    SELECT @v_header_err

    -- Warnings Detail
    SELECT LEFT(aud.emp_id + @v_SPACES_30, 20) +
        LEFT(aud.eff_date + @v_SPACES_30, 20) +
        LEFT(aud.first_name + @v_SPACES_30, 20) +
        LEFT(aud.last_name + @v_SPACES_30, 20) +
        LEFT(aud.empl_id + @v_SPACES_30, 15) +
        LEFT(aud.pay_group_id + @v_SPACES_30, 15) +
        LEFT(msg.msg_id + @v_SPACES_30, 15) +
        RTRIM(msg.msg_desc)
    FROM DBShrpn.dbo.ghr_historical_message msg
    JOIN DBShrpn.dbo.ghr_employee_events_aud aud ON
            (msg.activity_date = aud.activity_date) AND
            (msg.aud_id        = aud.aud_id)
    WHERE (aud.event_id      = @v_EVENT_ID_TRANSFER)
        AND (msg.activity_status = @v_ACTIVITY_STATUS_WARNING)
        AND (aud.activity_date    = @w_activity_date)
    ORDER BY aud.emp_id

    -- No records then not applicable
    IF (@@ROWCOUNT = 0)
        SELECT 'N/A'


    ---------------------------------------------------------------------------
    -- Transfer Error Section
    ---------------------------------------------------------------------------
    SELECT @v_SPACES_30
    SELECT 'Transfer Errors:'
    SELECT @v_SPACES_30

    -- headers
    SELECT @v_header_err

    -- Error Detail
    SELECT LEFT(aud.emp_id + @v_SPACES_30, 20) +
        LEFT(aud.eff_date + @v_SPACES_30, 20) +
        LEFT(aud.first_name + @v_SPACES_30, 20) +
        LEFT(aud.last_name + @v_SPACES_30, 20) +
        LEFT(aud.empl_id + @v_SPACES_30, 15) +
        LEFT(aud.pay_group_id + @v_SPACES_30, 15) +
        LEFT(msg.msg_id + @v_SPACES_30, 15) +
        RTRIM(msg.msg_desc)
    FROM DBShrpn.dbo.ghr_historical_message msg
    JOIN DBShrpn.dbo.ghr_employee_events_aud aud ON
            (msg.activity_date = aud.activity_date) AND
            (msg.aud_id        = aud.aud_id)
    WHERE (aud.event_id        = @v_EVENT_ID_TRANSFER)
      AND (msg.activity_status = @v_ACTIVITY_STATUS_BAD)
      AND (aud.activity_date    = @w_activity_date)
    ORDER BY aud.emp_id

    -- No records then not applicable
    IF (@@ROWCOUNT = 0)
        SELECT 'N/A'



    ---------------------------------------------------------------------------
    -- Name Change Section
    ---------------------------------------------------------------------------
    SELECT @v_SPACES_30
    SELECT	'Name Change Section:'
    SELECT @v_SPACES_30

    -- Headers
    SELECT @v_header_base

    -- Detail GOOD
    SELECT LEFT(aud.emp_id + @v_SPACES_30, 20) +
           LEFT(aud.eff_date + @v_SPACES_30, 20) +
           LEFT(aud.first_name + @v_SPACES_30, 20) +
           LEFT(aud.last_name + @v_SPACES_30, 20) +
           LEFT(aud.empl_id + @v_SPACES_30, 15) +
           LEFT(aud.pay_group_id + @v_SPACES_30, 15)
    FROM DBShrpn.dbo.ghr_employee_events_aud aud
    WHERE (aud.activity_date = @w_activity_date)
      AND (aud.event_id = @v_EVENT_ID_NAME_CHANGE)
      AND (aud.proc_flag = 'Y')
    ORDER BY aud.emp_id

    -- No records then not applicable
    IF (@@ROWCOUNT = 0)
        SELECT 'N/A'


    ---------------------------------------------------------------------------
    -- Name Change Error Section
    ---------------------------------------------------------------------------
    SELECT @v_SPACES_30
    SELECT 'Name Change Errors:'
    SELECT @v_SPACES_30

    -- headers
    SELECT @v_header_err

    -- Error Detail
    SELECT LEFT(aud.emp_id + @v_SPACES_30, 20) +
        LEFT(aud.eff_date + @v_SPACES_30, 20) +
        LEFT(aud.first_name + @v_SPACES_30, 20) +
        LEFT(aud.last_name + @v_SPACES_30, 20) +
        LEFT(aud.empl_id + @v_SPACES_30, 15) +
        LEFT(aud.pay_group_id + @v_SPACES_30, 15) +
        LEFT(msg.msg_id + @v_SPACES_30, 15) +
        RTRIM(msg.msg_desc)
    FROM DBShrpn.dbo.ghr_historical_message msg
    JOIN DBShrpn.dbo.ghr_employee_events_aud aud ON
            (msg.activity_date = aud.activity_date) AND
            (msg.aud_id        = aud.aud_id)
    WHERE (aud.event_id        = @v_EVENT_ID_NAME_CHANGE)
        AND (msg.activity_status = @v_ACTIVITY_STATUS_BAD)
        AND (aud.activity_date    = @w_activity_date)
    ORDER BY aud.emp_id

    -- No records then not applicable
    IF (@@ROWCOUNT = 0)
        SELECT 'N/A'



    ---------------------------------------------------------------------------
    -- Status Change Section
    ---------------------------------------------------------------------------
    SELECT @v_SPACES_30
    SELECT	'Status Change Section:'
    SELECT @v_SPACES_30

    -- Headers
    SELECT @v_header_base

    -- Detail GOOD
    SELECT LEFT(aud.emp_id + @v_SPACES_30, 20) +
           LEFT(aud.eff_date + @v_SPACES_30, 20) +
           LEFT(aud.first_name + @v_SPACES_30, 20) +
           LEFT(aud.last_name + @v_SPACES_30, 20) +
           LEFT(aud.empl_id + @v_SPACES_30, 15) +
           LEFT(aud.pay_group_id + @v_SPACES_30, 15)
    FROM DBShrpn.dbo.ghr_employee_events_aud aud
    WHERE (aud.activity_date = @w_activity_date)
      AND (aud.event_id = @v_EVENT_ID_STATUS_CHANGE)
      AND (aud.proc_flag = 'Y')
    ORDER BY aud.emp_id

    -- No records then not applicable
    IF (@@ROWCOUNT = 0)
        SELECT 'N/A'



    ---------------------------------------------------------------------------
    -- Status Change Warnings Section
    ---------------------------------------------------------------------------
    SELECT @v_SPACES_30
    SELECT 'Status Change Warnings:'
    SELECT @v_SPACES_30

    -- headers
    SELECT @v_header_err

    -- Warnings Detail
    SELECT LEFT(aud.emp_id + @v_SPACES_30, 20) +
        LEFT(aud.eff_date + @v_SPACES_30, 20) +
        LEFT(aud.first_name + @v_SPACES_30, 20) +
        LEFT(aud.last_name + @v_SPACES_30, 20) +
        LEFT(aud.empl_id + @v_SPACES_30, 15) +
        LEFT(aud.pay_group_id + @v_SPACES_30, 15) +
        LEFT(msg.msg_id + @v_SPACES_30, 15) +
        RTRIM(msg.msg_desc)
    FROM DBShrpn.dbo.ghr_historical_message msg
    JOIN DBShrpn.dbo.ghr_employee_events_aud aud ON
            (msg.activity_date = aud.activity_date) AND
            (msg.aud_id        = aud.aud_id)
    WHERE (aud.event_id      = @v_EVENT_ID_STATUS_CHANGE)
        AND (msg.activity_status = @v_ACTIVITY_STATUS_WARNING)
        AND (aud.activity_date    = @w_activity_date)
    ORDER BY aud.emp_id

    -- No records then not applicable
    IF (@@ROWCOUNT = 0)
        SELECT 'N/A'


    ---------------------------------------------------------------------------
    -- Status Change Error Section
    ---------------------------------------------------------------------------
    SELECT @v_SPACES_30
    SELECT 'Status Change Errors:'
    SELECT @v_SPACES_30

    -- headers
    SELECT @v_header_err

    -- Error Detail
    SELECT LEFT(aud.emp_id + @v_SPACES_30, 20) +
        LEFT(aud.eff_date + @v_SPACES_30, 20) +
        LEFT(aud.first_name + @v_SPACES_30, 20) +
        LEFT(aud.last_name + @v_SPACES_30, 20) +
        LEFT(aud.empl_id + @v_SPACES_30, 15) +
        LEFT(aud.pay_group_id + @v_SPACES_30, 15) +
        LEFT(msg.msg_id + @v_SPACES_30, 15) +
        RTRIM(msg.msg_desc)
    FROM DBShrpn.dbo.ghr_historical_message msg
    JOIN DBShrpn.dbo.ghr_employee_events_aud aud ON
            (msg.activity_date = aud.activity_date) AND
            (msg.aud_id        = aud.aud_id)
    WHERE (aud.event_id        = @v_EVENT_ID_STATUS_CHANGE)
        AND (msg.activity_status = @v_ACTIVITY_STATUS_BAD)
        AND (aud.activity_date    = @w_activity_date)
    ORDER BY aud.emp_id

    -- No records then not applicable
    IF (@@ROWCOUNT = 0)
        SELECT 'N/A'



    ---------------------------------------------------------------------------
    -- Pay Allowances Section
    ---------------------------------------------------------------------------
    SELECT @v_SPACES_30
    SELECT	'Pay Allowances Section:'
    SELECT @v_SPACES_30

    -- Headers
    SELECT @v_header_pay_ele

    -- Detail GOOD
    SELECT LEFT(aud.emp_id + @v_SPACES_30, 20) +
           LEFT(aud.eff_date + @v_SPACES_30, 20) +
           LEFT(aud.first_name + @v_SPACES_30, 20) +
           LEFT(aud.last_name + @v_SPACES_30, 20) +
           LEFT(aud.empl_id + @v_SPACES_30, 15) +
           LEFT(aud.pay_group_id + @v_SPACES_30, 15) +
           LEFT(aud.pay_element_id + @v_SPACES_30, 20) +
           LEFT(aud.begin_date + @v_SPACES_30, 15) +
           LEFT(aud.end_date + @v_SPACES_30, 15) +
           LEFT(aud.emp_calculation + @v_SPACES_30, 20)
    FROM DBShrpn.dbo.ghr_employee_events_aud aud
    WHERE (aud.activity_date = @w_activity_date)
      AND (aud.event_id = @v_EVENT_ID_PAY_ELE)
      AND (aud.proc_flag = 'Y')
    ORDER BY aud.emp_id

    -- No records then not applicable
    IF (@@ROWCOUNT = 0)
        SELECT 'N/A'



    ---------------------------------------------------------------------------
    -- Pay Allowances Error Section
    ---------------------------------------------------------------------------
    SELECT @v_SPACES_30
    SELECT 'Pay Allowances Errors:'
    SELECT @v_SPACES_30

    -- headers
    SELECT @v_header_pay_ele_err

    -- Error Detail
    SELECT LEFT(aud.emp_id + @v_SPACES_30, 20) +
           LEFT(aud.eff_date + @v_SPACES_30, 20) +
           LEFT(aud.first_name + @v_SPACES_30, 20) +
           LEFT(aud.last_name + @v_SPACES_30, 20) +
           LEFT(aud.empl_id + @v_SPACES_30, 15) +
           LEFT(aud.pay_group_id + @v_SPACES_30, 15) +
           LEFT(aud.pay_element_id + @v_SPACES_30, 20) +
           LEFT(aud.begin_date + @v_SPACES_30, 15) +
           LEFT(aud.end_date + @v_SPACES_30, 15) +
           LEFT(aud.emp_calculation + @v_SPACES_30, 20) +
           LEFT(msg.msg_id + @v_SPACES_30, 15) +
           RTRIM(msg.msg_desc)
    FROM DBShrpn.dbo.ghr_historical_message msg
    JOIN DBShrpn.dbo.ghr_employee_events_aud aud ON
            (msg.activity_date = aud.activity_date) AND
            (msg.aud_id        = aud.aud_id)
    WHERE (aud.event_id        = @v_EVENT_ID_PAY_ELE)
        AND (msg.activity_status = @v_ACTIVITY_STATUS_BAD)
        AND (aud.activity_date    = @w_activity_date)
    ORDER BY aud.emp_id

    -- No records then not applicable
    IF (@@ROWCOUNT = 0)
        SELECT 'N/A'


    ---------------------------------------------------------------------------
    -- Pay Group Section
    ---------------------------------------------------------------------------
    SELECT @v_SPACES_30
    SELECT	'Pay Group Update Section:'
    SELECT @v_SPACES_30

    -- Headers
    SELECT @v_header_base

    -- Detail GOOD
    SELECT LEFT(aud.emp_id + @v_SPACES_30, 20) +
           LEFT(aud.eff_date + @v_SPACES_30, 20) +
           LEFT(aud.first_name + @v_SPACES_30, 20) +
           LEFT(aud.last_name + @v_SPACES_30, 20) +
           LEFT(aud.empl_id + @v_SPACES_30, 15) +
           LEFT(aud.pay_group_id + @v_SPACES_30, 15)
    FROM DBShrpn.dbo.ghr_employee_events_aud aud
    WHERE (aud.activity_date = @w_activity_date)
      AND (aud.event_id = @v_EVENT_ID_PAY_GROUP)
      AND (aud.proc_flag = 'Y')
    ORDER BY aud.emp_id

    -- No records then not applicable
    IF (@@ROWCOUNT = 0)
        SELECT 'N/A'


    ---------------------------------------------------------------------------
    -- Pay Group Warning Section
    ---------------------------------------------------------------------------
    SELECT @v_SPACES_30
    SELECT	'Pay Group Update Warning Section:'
    SELECT @v_SPACES_30

    -- Headers
    SELECT @v_header_err

    -- Detail warning
    SELECT LEFT(aud.emp_id + @v_SPACES_30, 20) +
           LEFT(aud.eff_date + @v_SPACES_30, 20) +
           LEFT(aud.first_name + @v_SPACES_30, 20) +
           LEFT(aud.last_name + @v_SPACES_30, 20) +
           LEFT(aud.empl_id + @v_SPACES_30, 15) +
           LEFT(aud.pay_group_id + @v_SPACES_30, 15) +
           LEFT(msg.msg_id + @v_SPACES_30, 15) +
           RTRIM(msg.msg_desc)
    FROM DBShrpn.dbo.ghr_historical_message msg
    JOIN DBShrpn.dbo.ghr_employee_events_aud aud ON
            (msg.activity_date = aud.activity_date) AND
            (msg.aud_id        = aud.aud_id)
    WHERE (aud.event_id        = @v_EVENT_ID_PAY_GROUP)
        AND (msg.activity_status = @v_ACTIVITY_STATUS_WARNING)
        AND (aud.activity_date    = @w_activity_date)
    ORDER BY aud.emp_id

    -- No records then not applicable
    IF (@@ROWCOUNT = 0)
        SELECT 'N/A'


    ---------------------------------------------------------------------------
    -- Pay Group Error Section
    ---------------------------------------------------------------------------
    SELECT @v_SPACES_30
    SELECT 'Pay Group Update Errors:'
    SELECT @v_SPACES_30

    -- headers
    SELECT @v_header_err

    -- Error Detail
    SELECT LEFT(aud.emp_id + @v_SPACES_30, 20) +
        LEFT(aud.eff_date + @v_SPACES_30, 20) +
        LEFT(aud.first_name + @v_SPACES_30, 20) +
        LEFT(aud.last_name + @v_SPACES_30, 20) +
        LEFT(aud.empl_id + @v_SPACES_30, 15) +
        LEFT(aud.pay_group_id + @v_SPACES_30, 15) +
        LEFT(msg.msg_id + @v_SPACES_30, 15) +
        RTRIM(msg.msg_desc)
    FROM DBShrpn.dbo.ghr_historical_message msg
    JOIN DBShrpn.dbo.ghr_employee_events_aud aud ON
            (msg.activity_date = aud.activity_date) AND
            (msg.aud_id        = aud.aud_id)
    WHERE (aud.event_id        = @v_EVENT_ID_PAY_GROUP)
        AND (msg.activity_status = @v_ACTIVITY_STATUS_BAD)
        AND (aud.activity_date    = @w_activity_date)
    ORDER BY aud.emp_id

    -- No records then not applicable
    IF (@@ROWCOUNT = 0)
        SELECT 'N/A'


    ---------------------------------------------------------------------------
    -- Labor Group Section
    ---------------------------------------------------------------------------
    SELECT @v_SPACES_30
    SELECT	'Labor Group Update Section:'
    SELECT @v_SPACES_30

    -- Headers
    SELECT @v_header_labor_group

    -- Detail GOOD
    SELECT LEFT(aud.emp_id + @v_SPACES_30, 20) +
           LEFT(aud.eff_date + @v_SPACES_30, 20) +
           LEFT(aud.first_name + @v_SPACES_30, 20) +
           LEFT(aud.last_name + @v_SPACES_30, 20) +
           LEFT(aud.empl_id + @v_SPACES_30, 15) +
           LEFT(aud.pay_group_id + @v_SPACES_30, 15) +
           LEFT(aud.labor_grp_code + @v_SPACES_30, 15)
    FROM DBShrpn.dbo.ghr_employee_events_aud aud
    WHERE (aud.activity_date = @w_activity_date)
      AND (aud.event_id = @v_EVENT_ID_LABOR_GROUP)
      AND (aud.proc_flag = 'Y')
    ORDER BY aud.emp_id

    -- No records then not applicable
    IF (@@ROWCOUNT = 0)
        SELECT 'N/A'


    ---------------------------------------------------------------------------
    -- Labor Group Warning Section
    ---------------------------------------------------------------------------
    SELECT @v_SPACES_30
    SELECT 'Labor Group Update Warning Section:'
    SELECT @v_SPACES_30

    -- Headers
    SELECT @v_header_labor_group_err

    -- Detail
    SELECT LEFT(aud.emp_id + @v_SPACES_30, 20) +
           LEFT(aud.eff_date + @v_SPACES_30, 20) +
           LEFT(aud.first_name + @v_SPACES_30, 20) +
           LEFT(aud.last_name + @v_SPACES_30, 20) +
           LEFT(aud.empl_id + @v_SPACES_30, 15) +
           LEFT(aud.pay_group_id + @v_SPACES_30, 15) +
           LEFT(aud.labor_grp_code + @v_SPACES_30, 15) +
           LEFT(msg.msg_id + @v_SPACES_30, 15) +
           RTRIM(msg.msg_desc)
    FROM DBShrpn.dbo.ghr_historical_message msg
    JOIN DBShrpn.dbo.ghr_employee_events_aud aud ON
            (msg.activity_date = aud.activity_date) AND
            (msg.aud_id        = aud.aud_id)
    WHERE (aud.event_id = @v_EVENT_ID_LABOR_GROUP)
      AND (msg.activity_status = @v_ACTIVITY_STATUS_WARNING)
      AND (aud.activity_date	= @w_activity_date)
    ORDER BY aud.emp_id

    -- No records then not applicable
    IF (@@ROWCOUNT = 0)
        SELECT 'N/A'


    ---------------------------------------------------------------------------
    -- Labor Group Error Section
    ---------------------------------------------------------------------------
    SELECT @v_SPACES_30
    SELECT 'Labor Group Update Errors:'
    SELECT @v_SPACES_30

    -- headers
    SELECT @v_header_labor_group_err

    -- Error Detail
    SELECT LEFT(aud.emp_id + @v_SPACES_30, 20) +
        LEFT(aud.eff_date + @v_SPACES_30, 20) +
        LEFT(aud.first_name + @v_SPACES_30, 20) +
        LEFT(aud.last_name + @v_SPACES_30, 20) +
        LEFT(aud.empl_id + @v_SPACES_30, 15) +
        LEFT(aud.pay_group_id + @v_SPACES_30, 15) +
        LEFT(aud.labor_grp_code + @v_SPACES_30, 15) +
        LEFT(msg.msg_id + @v_SPACES_30, 15) +
        RTRIM(msg.msg_desc)
    FROM DBShrpn.dbo.ghr_historical_message msg
    JOIN DBShrpn.dbo.ghr_employee_events_aud aud ON
            (msg.activity_date = aud.activity_date) AND
            (msg.aud_id        = aud.aud_id)
    WHERE (aud.event_id        = @v_EVENT_ID_LABOR_GROUP)
        AND (msg.activity_status = @v_ACTIVITY_STATUS_BAD)
        AND (aud.activity_date    = @w_activity_date)
    ORDER BY aud.emp_id

    -- No records then not applicable
    IF (@@ROWCOUNT = 0)
        SELECT 'N/A'


    ---------------------------------------------------------------------------
    -- Position Title Section
    ---------------------------------------------------------------------------
    SELECT @v_SPACES_30
    SELECT	'Position Title Update Section:'
    SELECT @v_SPACES_30

    -- Headers
    SELECT @v_header_position_title

    -- Detail GOOD
    SELECT LEFT(aud.emp_id + @v_SPACES_30, 20) +
           LEFT(aud.eff_date + @v_SPACES_30, 20) +
           LEFT(aud.first_name + @v_SPACES_30, 20) +
           LEFT(aud.last_name + @v_SPACES_30, 20) +
           LEFT(aud.empl_id + @v_SPACES_30, 15) +
           LEFT(aud.pay_group_id + @v_SPACES_30, 15) +
           LEFT(aud.position_title + @v_SPACES_50, 50)
    FROM DBShrpn.dbo.ghr_employee_events_aud aud
    WHERE (aud.activity_date = @w_activity_date)
      AND (aud.event_id = @v_EVENT_ID_POSITION_TITLE)
      AND (aud.proc_flag = 'Y')
    ORDER BY aud.emp_id

    -- No records then not applicable
    IF (@@ROWCOUNT = 0)
        SELECT 'N/A'


    ---------------------------------------------------------------------------
    -- Position Title Warning Section
    ---------------------------------------------------------------------------
    SELECT @v_SPACES_30
    SELECT	'Position Title Update Warning Section:'
    SELECT @v_SPACES_30

    -- Headers
    SELECT @v_header_position_title_err

    -- Detail warning
    SELECT LEFT(aud.emp_id + @v_SPACES_30, 20) +
           LEFT(aud.eff_date + @v_SPACES_30, 20) +
           LEFT(aud.first_name + @v_SPACES_30, 20) +
           LEFT(aud.last_name + @v_SPACES_30, 20) +
           LEFT(aud.empl_id + @v_SPACES_30, 15) +
           LEFT(aud.pay_group_id + @v_SPACES_30, 15) +
           LEFT(aud.position_title + @v_SPACES_50, 50) +
           LEFT(msg.msg_id + @v_SPACES_30, 15) +
           RTRIM(msg.msg_desc)
    FROM DBShrpn.dbo.ghr_historical_message msg
    JOIN DBShrpn.dbo.ghr_employee_events_aud aud ON
            (msg.activity_date = aud.activity_date) AND
            (msg.aud_id        = aud.aud_id)
    WHERE (aud.event_id        = @v_EVENT_ID_POSITION_TITLE)
        AND (msg.activity_status = @v_ACTIVITY_STATUS_WARNING)
        AND (aud.activity_date    = @w_activity_date)
    ORDER BY aud.emp_id

    -- No records then not applicable
    IF (@@ROWCOUNT = 0)
        SELECT 'N/A'


    ---------------------------------------------------------------------------
    -- Position Title Error Section
    ---------------------------------------------------------------------------
    SELECT @v_SPACES_30
    SELECT 'Position Title Update Errors:'
    SELECT @v_SPACES_30

    -- headers
    SELECT @v_header_position_title_err

    -- Error Detail
    SELECT LEFT(aud.emp_id + @v_SPACES_30, 20) +
        LEFT(aud.eff_date + @v_SPACES_30, 20) +
        LEFT(aud.first_name + @v_SPACES_30, 20) +
        LEFT(aud.last_name + @v_SPACES_30, 20) +
        LEFT(aud.empl_id + @v_SPACES_30, 15) +
        LEFT(aud.pay_group_id + @v_SPACES_30, 15) +
        LEFT(aud.position_title + @v_SPACES_50, 50) +
        LEFT(msg.msg_id + @v_SPACES_30, 15) +
        RTRIM(msg.msg_desc)
    FROM DBShrpn.dbo.ghr_historical_message msg
    JOIN DBShrpn.dbo.ghr_employee_events_aud aud ON
            (msg.activity_date = aud.activity_date) AND
            (msg.aud_id        = aud.aud_id)
    WHERE (aud.event_id        = @v_EVENT_ID_POSITION_TITLE)
        AND (msg.activity_status = @v_ACTIVITY_STATUS_BAD)
        AND (aud.activity_date    = @w_activity_date)
    ORDER BY aud.emp_id

    -- No records then not applicable
    IF (@@ROWCOUNT = 0)
        SELECT 'N/A'

END  -- End of SP

GO
ALTER AUTHORIZATION ON dbo.usp_verification_rpt TO SCHEMA OWNER
GO


IF OBJECT_ID(N'dbo.usp_verification_rpt', N'P') IS NOT NULL
    PRINT N'<<< CREATED PROCEDURE dbo.usp_verification_rpt >>>'
ELSE
    PRINT N'<<< FAILED CREATING PROCEDURE dbo.usp_verification_rpt >>>'
GO
