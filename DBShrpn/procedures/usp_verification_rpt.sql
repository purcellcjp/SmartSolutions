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

    DECLARE @w_activity_date                datetime
    DECLARE @w_distribution_id              varchar(255)

    DECLARE @w_user_id                      char(30)


    DECLARE @w_activity_status	            char(02)


    DECLARE @v_header_base                  varchar(255)
    DECLARE @v_header_err                   varchar(255)
    DECLARE @v_header_pay_ele               varchar(255)
    DECLARE @v_header_pay_ele_err           varchar(255)




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
                              + 'Error Message'

    SET @v_header_pay_ele     = @v_header_base
                              + LEFT('Pay Element ID' + @v_SPACES_30, 20)
                              + LEFT('Start Date' + @v_SPACES_30, 15)
                              + LEFT('End Date' + @v_SPACES_30, 15)
                              + LEFT('Amount' + @v_SPACES_30, 20)

    SET @v_header_pay_ele_err = @v_header_pay_ele
                              + 'Error Message'


    ---------------------------------------------------------------------------
    -- Email Header
    ---------------------------------------------------------------------------
    SELECT	SPACE(35) + 'HCM - SS Interface Transaction Report'
    SELECT  SPACE(50) + 'All Entities'
    SELECT	'Run Date: ' + CONVERT(char,GETDATE(),120)	+ SPACE(10)
    SELECT	SPACE(50)


    ---------------------------------------------------------------------------
    -- New Hire Section
    ---------------------------------------------------------------------------
    SELECT @v_SPACES_30
    SELECT	'New Hire Section:'
    SELECT @v_SPACES_30

    -- Headers
    SELECT @v_header_base

    -- Detail
    SELECT LEFT(ev.emp_id + @v_SPACES_30, 20) +
           LEFT(ev.eff_date + @v_SPACES_30, 20) +
           LEFT(ev.first_name + @v_SPACES_30, 20) +
           LEFT(ev.last_name + @v_SPACES_30, 20) +
           LEFT(ev.empl_id + @v_SPACES_30, 15) +
           LEFT(ev.pay_group_id + @v_SPACES_30, 15)
    FROM DBShrpn.dbo.ghr_employee_events_aud ev
    WHERE (ev.event_id = @v_EVENT_ID_NEW_HIRE)
      AND (ev.activity_status = @v_ACTIVITY_STATUS_GOOD)
      AND (ev.activity_date	= @w_activity_date)

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
    SELECT LEFT(ev.emp_id + @v_SPACES_30, 20) +
        LEFT(ev.eff_date + @v_SPACES_30, 20) +
        LEFT(ev.first_name + @v_SPACES_30, 20) +
        LEFT(ev.last_name + @v_SPACES_30, 20) +
        LEFT(ev.empl_id + @v_SPACES_30, 15) +
        LEFT(ev.pay_group_id + @v_SPACES_30, 15) +
        RTRIM(m.msg_desc)
    FROM DBShrpn.dbo.ghr_employee_events_aud ev
    JOIN DBShrpn.dbo.ghr_historical_message m ON
            (m.event_id = ev.event_id) AND
            (m.emp_id   = ev.emp_id) AND
            (m.eff_date = ev.eff_date)
    WHERE (ev.event_id      = @v_EVENT_ID_NEW_HIRE)
        AND (ev.activity_status <> @v_ACTIVITY_STATUS_WARNING)
        AND (ev.activity_date    = @w_activity_date)
    ORDER BY ev.emp_id

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
    SELECT LEFT(ev.emp_id + @v_SPACES_30, 20) +
        LEFT(ev.eff_date + @v_SPACES_30, 15) +
        LEFT(ev.first_name + @v_SPACES_30, 20) +
        LEFT(ev.last_name + @v_SPACES_30, 20) +
        LEFT(ev.empl_id + @v_SPACES_30, 15) +
        RTRIM(m.msg_desc)
    FROM DBShrpn.dbo.ghr_employee_events_aud ev
    JOIN DBShrpn.dbo.ghr_historical_message m ON
            (m.event_id = ev.event_id) AND
            (m.emp_id   = ev.emp_id) AND
            (m.eff_date = ev.eff_date)
    WHERE (ev.event_id      = @v_EVENT_ID_NEW_HIRE)
        AND (ev.activity_status <> @v_ACTIVITY_STATUS_BAD)
        AND (ev.activity_date    = @w_activity_date)
    ORDER BY ev.emp_id

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
    SELECT LEFT(ev.emp_id + @v_SPACES_30, 20) +
           LEFT(ev.eff_date + @v_SPACES_30, 20) +
           LEFT(ev.first_name + @v_SPACES_30, 20) +
           LEFT(ev.last_name + @v_SPACES_30, 20) +
           LEFT(ev.empl_id + @v_SPACES_30, 15) +
           LEFT(ev.pay_group_id + @v_SPACES_30, 15)
    FROM DBShrpn.dbo.ghr_employee_events_aud ev
    WHERE (ev.event_id = @v_EVENT_ID_TRANSFER)
      AND (ev.activity_status = @v_ACTIVITY_STATUS_GOOD)
      AND (ev.activity_date	= @w_activity_date)
    ORDER BY ev.emp_id

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
    SELECT LEFT(ev.emp_id + @v_SPACES_30, 20) +
        LEFT(ev.eff_date + @v_SPACES_30, 20) +
        LEFT(ev.first_name + @v_SPACES_30, 20) +
        LEFT(ev.last_name + @v_SPACES_30, 20) +
        LEFT(ev.empl_id + @v_SPACES_30, 15) +
        LEFT(ev.pay_group_id + @v_SPACES_30, 15) +
        RTRIM(m.msg_desc)
    FROM DBShrpn.dbo.ghr_employee_events_aud ev
    JOIN DBShrpn.dbo.ghr_historical_message m ON
            (m.event_id = ev.event_id) AND
            (m.emp_id   = ev.emp_id) AND
            (m.eff_date = ev.eff_date)
    WHERE (ev.event_id      = @v_EVENT_ID_TRANSFER)
        AND (ev.activity_status <> @v_ACTIVITY_STATUS_WARNING)
        AND (ev.activity_date    = @w_activity_date)
    ORDER BY ev.emp_id

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
    SELECT LEFT(ev.emp_id + @v_SPACES_30, 20) +
        LEFT(ev.eff_date + @v_SPACES_30, 20) +
        LEFT(ev.first_name + @v_SPACES_30, 20) +
        LEFT(ev.last_name + @v_SPACES_30, 20) +
        LEFT(ev.empl_id + @v_SPACES_30, 15) +
        LEFT(ev.pay_group_id + @v_SPACES_30, 15) +
        RTRIM(m.msg_desc)
    FROM DBShrpn.dbo.ghr_employee_events_aud ev
    JOIN DBShrpn.dbo.ghr_historical_message m ON
            (m.event_id = ev.event_id) AND
            (m.emp_id   = ev.emp_id) AND
            (m.eff_date = ev.eff_date)
    WHERE (ev.event_id        = @v_EVENT_ID_TRANSFER)
        AND (ev.activity_status <> @v_ACTIVITY_STATUS_BAD)
        AND (ev.activity_date    = @w_activity_date)
    ORDER BY ev.emp_id

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
    SELECT LEFT(ev.emp_id + @v_SPACES_30, 20) +
           LEFT(ev.eff_date + @v_SPACES_30, 20) +
           LEFT(ev.first_name + @v_SPACES_30, 20) +
           LEFT(ev.last_name + @v_SPACES_30, 20) +
           LEFT(ev.empl_id + @v_SPACES_30, 15) +
           LEFT(ev.pay_group_id + @v_SPACES_30, 15)
    FROM DBShrpn.dbo.ghr_employee_events_aud ev
    WHERE (event_id = @v_EVENT_ID_NAME_CHANGE)
      AND (activity_status = @v_ACTIVITY_STATUS_GOOD)
      AND (activity_date	= @w_activity_date)
    ORDER BY ev.emp_id

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
    SELECT LEFT(ev.emp_id + @v_SPACES_30, 20) +
        LEFT(ev.eff_date + @v_SPACES_30, 20) +
        LEFT(ev.first_name + @v_SPACES_30, 20) +
        LEFT(ev.last_name + @v_SPACES_30, 20) +
        LEFT(ev.empl_id + @v_SPACES_30, 15) +
        LEFT(ev.pay_group_id + @v_SPACES_30, 15) +
        RTRIM(m.msg_desc)
    FROM DBShrpn.dbo.ghr_employee_events_aud ev
    JOIN DBShrpn.dbo.ghr_historical_message m ON
            (m.event_id = ev.event_id) AND
            (m.emp_id   = ev.emp_id) AND
            (m.eff_date = ev.eff_date)
    WHERE (ev.event_id        = @v_EVENT_ID_NAME_CHANGE)
        AND (ev.activity_status <> @v_ACTIVITY_STATUS_BAD)
        AND (ev.activity_date    = @w_activity_date)
    ORDER BY ev.emp_id

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
    SELECT LEFT(ev.emp_id + @v_SPACES_30, 20) +
           LEFT(ev.eff_date + @v_SPACES_30, 20) +
           LEFT(ev.first_name + @v_SPACES_30, 20) +
           LEFT(ev.last_name + @v_SPACES_30, 20) +
           LEFT(ev.empl_id + @v_SPACES_30, 15) +
           LEFT(ev.pay_group_id + @v_SPACES_30, 15)
    FROM DBShrpn.dbo.ghr_employee_events_aud ev
    WHERE (ev.event_id = @v_EVENT_ID_STATUS_CHANGE)
      AND (ev.activity_status = @v_ACTIVITY_STATUS_GOOD)
      AND (ev.activity_date	= @w_activity_date)
    ORDER BY ev.emp_id

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
    SELECT LEFT(ev.emp_id + @v_SPACES_30, 20) +
        LEFT(ev.eff_date + @v_SPACES_30, 20) +
        LEFT(ev.first_name + @v_SPACES_30, 20) +
        LEFT(ev.last_name + @v_SPACES_30, 20) +
        LEFT(ev.empl_id + @v_SPACES_30, 15) +
        LEFT(ev.pay_group_id + @v_SPACES_30, 15) +
        RTRIM(m.msg_desc)
    FROM DBShrpn.dbo.ghr_employee_events_aud ev
    JOIN DBShrpn.dbo.ghr_historical_message m ON
            (m.event_id = ev.event_id) AND
            (m.emp_id   = ev.emp_id) AND
            (m.eff_date = ev.eff_date)
    WHERE (ev.event_id      = @v_EVENT_ID_STATUS_CHANGE)
        AND (ev.activity_status <> @v_ACTIVITY_STATUS_WARNING)
        AND (ev.activity_date    = @w_activity_date)
    ORDER BY ev.emp_id

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
    SELECT LEFT(ev.emp_id + @v_SPACES_30, 20) +
        LEFT(ev.eff_date + @v_SPACES_30, 20) +
        LEFT(ev.first_name + @v_SPACES_30, 20) +
        LEFT(ev.last_name + @v_SPACES_30, 20) +
        LEFT(ev.empl_id + @v_SPACES_30, 15) +
        LEFT(ev.pay_group_id + @v_SPACES_30, 15) +
        RTRIM(m.msg_desc)
    FROM DBShrpn.dbo.ghr_employee_events_aud ev
    JOIN DBShrpn.dbo.ghr_historical_message m ON
            (m.event_id = ev.event_id) AND
            (m.emp_id   = ev.emp_id) AND
            (m.eff_date = ev.eff_date)
    WHERE (ev.event_id        = @v_EVENT_ID_STATUS_CHANGE)
        AND (ev.activity_status <> @v_ACTIVITY_STATUS_BAD)
        AND (ev.activity_date    = @w_activity_date)
    ORDER BY ev.emp_id

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
    SELECT LEFT(ev.emp_id + @v_SPACES_30, 20) +
           LEFT(ev.eff_date + @v_SPACES_30, 20) +
           LEFT(ev.first_name + @v_SPACES_30, 20) +
           LEFT(ev.last_name + @v_SPACES_30, 20) +
           LEFT(ev.empl_id + @v_SPACES_30, 15) +
           LEFT(ev.pay_group_id + @v_SPACES_30, 15) +
           LEFT(ev.pay_element_id + @v_SPACES_30, 20) +
           LEFT(ev.begin_date + @v_SPACES_30, 15) +
           LEFT(ev.end_date + @v_SPACES_30, 15) +
           LEFT(ev.emp_calculation + @v_SPACES_30, 20)
    FROM DBShrpn.dbo.ghr_employee_events_aud ev
    WHERE (ev.event_id = @v_EVENT_ID_PAY_ELE)
      AND (ev.activity_status = @v_ACTIVITY_STATUS_GOOD)
      AND (ev.activity_date	= @w_activity_date)
    ORDER BY ev.emp_id

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
    SELECT LEFT(ev.emp_id + @v_SPACES_30, 20) +
           LEFT(ev.eff_date + @v_SPACES_30, 20) +
           LEFT(ev.first_name + @v_SPACES_30, 20) +
           LEFT(ev.last_name + @v_SPACES_30, 20) +
           LEFT(ev.empl_id + @v_SPACES_30, 15) +
           LEFT(ev.pay_group_id + @v_SPACES_30, 15) +
           LEFT(ev.pay_element_id + @v_SPACES_30, 20) +
           LEFT(ev.begin_date + @v_SPACES_30, 15) +
           LEFT(ev.end_date + @v_SPACES_30, 15) +
           LEFT(ev.emp_calculation + @v_SPACES_30, 20) +
           RTRIM(m.msg_desc)
    FROM DBShrpn.dbo.ghr_employee_events_aud ev
    JOIN DBShrpn.dbo.ghr_historical_message m ON
            (m.event_id = ev.event_id) AND
            (m.emp_id   = ev.emp_id) AND
            (m.eff_date = ev.eff_date) AND   -- just in case more than one pay element id with different effective dates - should not happen
            (m.activity_date = ev.activity_date) AND
            (m.pay_element_id = ev.pay_element_id)
    WHERE (ev.event_id        = @v_EVENT_ID_PAY_ELE)
        AND (ev.activity_status = @v_ACTIVITY_STATUS_BAD)
        AND (ev.activity_date    = @w_activity_date)
    ORDER BY ev.emp_id

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
    SELECT LEFT(ev.emp_id + @v_SPACES_30, 20) +
           LEFT(ev.eff_date + @v_SPACES_30, 20) +
           LEFT(ev.first_name + @v_SPACES_30, 20) +
           LEFT(ev.last_name + @v_SPACES_30, 20) +
           LEFT(ev.empl_id + @v_SPACES_30, 15) +
           LEFT(ev.pay_group_id + @v_SPACES_30, 15)
    FROM DBShrpn.dbo.ghr_employee_events_aud ev
    WHERE (ev.event_id = @v_EVENT_ID_PAY_GROUP)
      AND (ev.activity_status = @v_ACTIVITY_STATUS_GOOD)
      AND (ev.activity_date	= @w_activity_date)
    ORDER BY ev.emp_id

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

    -- Detail
    SELECT LEFT(ev.emp_id + @v_SPACES_30, 20) +
           LEFT(ev.eff_date + @v_SPACES_30, 20) +
           LEFT(ev.first_name + @v_SPACES_30, 20) +
           LEFT(ev.last_name + @v_SPACES_30, 20) +
           LEFT(ev.empl_id + @v_SPACES_30, 15) +
           LEFT(ev.pay_group_id + @v_SPACES_30, 15) +
           RTRIM(m.msg_desc)
    FROM DBShrpn.dbo.ghr_employee_events_aud ev
    JOIN DBShrpn.dbo.ghr_historical_message m ON
            (m.event_id = ev.event_id) AND
            (m.emp_id   = ev.emp_id) AND
            (m.eff_date = ev.eff_date)
    WHERE (ev.event_id = @v_EVENT_ID_PAY_GROUP)
      AND (ev.activity_status = @v_ACTIVITY_STATUS_WARNING)
      AND (ev.activity_date	= @w_activity_date)
    ORDER BY ev.emp_id

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
    SELECT LEFT(ev.emp_id + @v_SPACES_30, 20) +
        LEFT(ev.eff_date + @v_SPACES_30, 20) +
        LEFT(ev.first_name + @v_SPACES_30, 20) +
        LEFT(ev.last_name + @v_SPACES_30, 20) +
        LEFT(ev.empl_id + @v_SPACES_30, 15) +
        LEFT(ev.pay_group_id + @v_SPACES_30, 15) +
        RTRIM(m.msg_desc)
    FROM DBShrpn.dbo.ghr_employee_events_aud ev
    JOIN DBShrpn.dbo.ghr_historical_message m ON
            (m.event_id = ev.event_id) AND
            (m.emp_id   = ev.emp_id) AND
            (m.eff_date = ev.eff_date)
    WHERE (ev.event_id        = @v_EVENT_ID_PAY_GROUP)
        AND (ev.activity_status <> @v_ACTIVITY_STATUS_BAD)
        AND (ev.activity_date    = @w_activity_date)
    ORDER BY ev.emp_id

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
    SELECT @v_header_base

    -- Detail GOOD
    SELECT LEFT(ev.emp_id + @v_SPACES_30, 20) +
           LEFT(ev.eff_date + @v_SPACES_30, 20) +
           LEFT(ev.first_name + @v_SPACES_30, 20) +
           LEFT(ev.last_name + @v_SPACES_30, 20) +
           LEFT(ev.empl_id + @v_SPACES_30, 15) +
           LEFT(ev.pay_group_id + @v_SPACES_30, 15)
    FROM DBShrpn.dbo.ghr_employee_events_aud ev
    WHERE (ev.event_id = @v_EVENT_ID_LABOR_GROUP)
      AND (ev.activity_status = @v_ACTIVITY_STATUS_GOOD)
      AND (ev.activity_date	= @w_activity_date)
    ORDER BY ev.emp_id

    -- No records then not applicable
    IF (@@ROWCOUNT = 0)
        SELECT 'N/A'


    ---------------------------------------------------------------------------
    -- Labor Group Warning Section
    ---------------------------------------------------------------------------
    SELECT @v_SPACES_30
    SELECT	'Labor Group Update Warning Section:'
    SELECT @v_SPACES_30

    -- Headers
    SELECT @v_header_err

    -- Detail warning
    SELECT LEFT(ev.emp_id + @v_SPACES_30, 20) +
           LEFT(ev.eff_date + @v_SPACES_30, 20) +
           LEFT(ev.first_name + @v_SPACES_30, 20) +
           LEFT(ev.last_name + @v_SPACES_30, 20) +
           LEFT(ev.empl_id + @v_SPACES_30, 15) +
           LEFT(ev.pay_group_id + @v_SPACES_30, 15) +
           RTRIM(m.msg_desc)
    FROM DBShrpn.dbo.ghr_employee_events_aud ev
    JOIN DBShrpn.dbo.ghr_historical_message m ON
            (m.event_id = ev.event_id) AND
            (m.emp_id   = ev.emp_id) AND
            (m.eff_date = ev.eff_date)
    WHERE (ev.event_id        = @v_EVENT_ID_LABOR_GROUP)
        AND (ev.activity_status <> @v_ACTIVITY_STATUS_BAD)
        AND (ev.activity_date    = @w_activity_date)
    ORDER BY ev.emp_id

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
    SELECT @v_header_err

    -- Error Detail
    SELECT LEFT(ev.emp_id + @v_SPACES_30, 20) +
        LEFT(ev.eff_date + @v_SPACES_30, 20) +
        LEFT(ev.first_name + @v_SPACES_30, 20) +
        LEFT(ev.last_name + @v_SPACES_30, 20) +
        LEFT(ev.empl_id + @v_SPACES_30, 15) +
        LEFT(ev.pay_group_id + @v_SPACES_30, 15) +
        RTRIM(m.msg_desc)
    FROM DBShrpn.dbo.ghr_employee_events_aud ev
    JOIN DBShrpn.dbo.ghr_historical_message m ON
            (m.event_id = ev.event_id) AND
            (m.emp_id   = ev.emp_id) AND
            (m.eff_date = ev.eff_date)
    WHERE (ev.event_id        = @v_EVENT_ID_LABOR_GROUP)
        AND (ev.activity_status <> @v_ACTIVITY_STATUS_BAD)
        AND (ev.activity_date    = @w_activity_date)
    ORDER BY ev.emp_id

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
    SELECT @v_header_base

    -- Detail GOOD
    SELECT LEFT(ev.emp_id + @v_SPACES_30, 20) +
           LEFT(ev.eff_date + @v_SPACES_30, 20) +
           LEFT(ev.first_name + @v_SPACES_30, 20) +
           LEFT(ev.last_name + @v_SPACES_30, 20) +
           LEFT(ev.empl_id + @v_SPACES_30, 15) +
           LEFT(ev.pay_group_id + @v_SPACES_30, 15)
    FROM DBShrpn.dbo.ghr_employee_events_aud ev
    WHERE (ev.event_id = @v_EVENT_ID_POSITION_TITLE)
      AND (ev.activity_status = @v_ACTIVITY_STATUS_GOOD)
      AND (ev.activity_date	= @w_activity_date)
    ORDER BY ev.emp_id

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
    SELECT @v_header_err

    -- Detail warning
    SELECT LEFT(ev.emp_id + @v_SPACES_30, 20) +
           LEFT(ev.eff_date + @v_SPACES_30, 20) +
           LEFT(ev.first_name + @v_SPACES_30, 20) +
           LEFT(ev.last_name + @v_SPACES_30, 20) +
           LEFT(ev.empl_id + @v_SPACES_30, 15) +
           LEFT(ev.pay_group_id + @v_SPACES_30, 15) +
           RTRIM(m.msg_desc)
    FROM DBShrpn.dbo.ghr_employee_events_aud ev
    JOIN DBShrpn.dbo.ghr_historical_message m ON
            (m.event_id = ev.event_id) AND
            (m.emp_id   = ev.emp_id) AND
            (m.eff_date = ev.eff_date)
    WHERE (ev.event_id        = @v_EVENT_ID_POSITION_TITLE)
        AND (ev.activity_status <> @v_ACTIVITY_STATUS_BAD)
        AND (ev.activity_date    = @w_activity_date)
    ORDER BY ev.emp_id

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
    SELECT @v_header_err

    -- Error Detail
    SELECT LEFT(ev.emp_id + @v_SPACES_30, 20) +
        LEFT(ev.eff_date + @v_SPACES_30, 20) +
        LEFT(ev.first_name + @v_SPACES_30, 20) +
        LEFT(ev.last_name + @v_SPACES_30, 20) +
        LEFT(ev.empl_id + @v_SPACES_30, 15) +
        LEFT(ev.pay_group_id + @v_SPACES_30, 15) +
        RTRIM(m.msg_desc)
    FROM DBShrpn.dbo.ghr_employee_events_aud ev
    JOIN DBShrpn.dbo.ghr_historical_message m ON
            (m.event_id = ev.event_id) AND
            (m.emp_id   = ev.emp_id) AND
            (m.eff_date = ev.eff_date)
    WHERE (ev.event_id        = @v_EVENT_ID_POSITION_TITLE)
        AND (ev.activity_status <> @v_ACTIVITY_STATUS_BAD)
        AND (ev.activity_date    = @w_activity_date)
    ORDER BY ev.emp_id

    -- No records then not applicable
    IF (@@ROWCOUNT = 0)
        SELECT 'N/A'



    SELECT SPACE(1)
    SELECT SPACE(0)
    SELECT 'End of mail message.'
    SELECT '    '
    SELECT 'IPM.MICROSOFT'
    SELECT 'GHR'

    SELECT @w_distribution_id

END  -- End of SP

GO
ALTER AUTHORIZATION ON dbo.usp_verification_rpt TO SCHEMA OWNER
GO


IF OBJECT_ID(N'dbo.usp_verification_rpt', N'P') IS NOT NULL
    PRINT N'<<< CREATED PROCEDURE dbo.usp_verification_rpt >>>'
ELSE
    PRINT N'<<< FAILED CREATING PROCEDURE dbo.usp_verification_rpt >>>'
GO
