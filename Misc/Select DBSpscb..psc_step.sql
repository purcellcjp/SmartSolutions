USE DBSpscb
GO


DECLARE @v_PSC_BATCHNAME                char(08)            = 'GHR'
DECLARE @w_PSC_QUALIFIER                char(30)            = 'INTERFACES'
DECLARE @w_PSC_PSC_PGM_PARMS            varchar(255)        = 'GHR_EMPLOYEE_EVENTS'	-- bulk copy
DECLARE @w_userid			            varchar(30)         = 'DBS'


SELECT *
FROM DBSpscb.dbo.psc_step
WHERE   (psc_userid    = @w_userid)
    AND (psc_batchname = @v_PSC_BATCHNAME)
    AND (psc_qualifier = @w_PSC_QUALIFIER)
    --AND (psc_pgm_parms = @w_PSC_PSC_PGM_PARMS)     -- bulkcopy step
ORDER BY psc_step_number