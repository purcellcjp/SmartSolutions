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
    DECLARE @v_ACTIVITY_STATUS_BAD          char(2)             = '02'

	DECLARE @v_EMPTY_SPACE                  char(01)            = ''

	DECLARE @w_activity_date	            datetime			= '2026-02-27 18:47:44.817'
	DECLARE @msg_id                         char(10)			= 'U00123'



        SELECT @msg_id AS msg_id
             , t.event_id AS event_id
             , @v_EMPTY_SPACE AS emp_id
             , @w_activity_date AS eff_date
             , @v_EMPTY_SPACE AS pay_element_id
             , @v_EMPTY_SPACE AS msg_p1
             , @v_EMPTY_SPACE AS msg_p2
             , CASE t.event_id
                 WHEN @v_EVENT_ID_NEW_HIRE       THEN 'New Hire Count: '
                 WHEN @v_EVENT_ID_SALARY_CHANGE  THEN 'Salary Change Count: '
                 WHEN @v_EVENT_ID_TRANSFER       THEN 'Transfer Count: '
                 WHEN @v_EVENT_ID_NAME_CHANGE    THEN 'Name Change Count: '
                 WHEN @v_EVENT_ID_STATUS_CHANGE  THEN 'Status Change Count: '
                 WHEN @v_EVENT_ID_PAY_ELE        THEN 'Pay Allowance Count: '
                 WHEN @v_EVENT_ID_PAY_GROUP      THEN 'Pay Group Count: '
                 WHEN @v_EVENT_ID_LABOR_GROUP    THEN 'Labor Group Count: '
                 WHEN @v_EVENT_ID_POSITION_TITLE THEN 'Position Title Count: '
                 ELSE ''
               END + CONVERT(varchar, count(*)) AS msg_desc
             , @v_ACTIVITY_STATUS_GOOD AS activity_status
             , @w_activity_date AS activity_date
             , 0 AS aud_id
        FROM DBShrpn.dbo.ghr_employee_events_aud t		--#ghr_employee_events_temp t
        GROUP BY t.event_id