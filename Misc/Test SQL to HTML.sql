    DECLARE @v_PSC_BATCHNAME                char(08)            = 'GHR'
    DECLARE @w_PSC_QUALIFIER                char(30)            = 'INTERFACES'
    DECLARE @w_PSC_PSC_PGM_PARMS            varchar(255)        = 'GHR_EMPLOYEE_EVENTS'
	DECLARE @w_user_id                      char(30)			= 'DBS'
	DECLARE @v_sql							varchar(max)        = ''
    DECLARE @w_activity_date                datetime
    DECLARE @w_activity_date_char           varchar(255)

	SELECT @w_activity_date = psc_last_comp_date
    FROM DBSpscb.dbo.psc_step
    WHERE psc_userid = @w_user_id
      AND psc_batchname = @v_PSC_BATCHNAME
      AND psc_qualifier = @w_PSC_QUALIFIER
      AND psc_pgm_parms = @w_PSC_PSC_PGM_PARMS     -- bulkcopy step

	SET @w_activity_date_char = CONVERT(char, @w_activity_date, 121)

    SET @v_sql = 'SELECT msg.msg_id, msg.event_id, msg.msg_desc '
               + 'FROM DBShrpn.dbo.ghr_historical_message msg '
               + 'WHERE (CHARINDEX(''U'', msg.msg_id) = 0) '
               + 'AND (msg.activity_date = ''' + @w_activity_date_char + ''') '

select @v_sql as v_sql
EXEC(@v_sql)


    EXEC dbo.sp_ConvertQuery2HTMLTable
                @SQLQuery = @v_sql