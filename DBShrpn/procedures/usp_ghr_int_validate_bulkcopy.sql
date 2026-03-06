USE DBShrpn
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'dbo.usp_ghr_int_validate_bulkcopy', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_ghr_int_validate_bulkcopy
    IF OBJECT_ID(N'dbo.usp_ghr_int_validate_bulkcopy') IS NOT NULL
        PRINT N'<<< FAILED DROPPING PROCEDURE dbo.usp_ghr_int_validate_bulkcopy >>>'
    ELSE
        PRINT N'<<< DROPPED PROCEDURE dbo.usp_ghr_int_validate_bulkcopy >>>'
END
GO

/*************************************************************************************
    SP Name:        usp_ghr_int_validate_bulkcopy

    Description:    This procedure determines if there were any records imported into the
                    destination table of the bulkcopy job scheduler step of the GHR Interfaces job.

                    This procedure will be added as a connect stored procedure step after the
                    bulkcopy step.

                    If there are no records in the bulkcopy table, then an error is logged to table
                    DBShrpn.dbo.ghr_historical_message which will be reported in the verification report.

    Parameters:
        None

    Tables:
        DBShrpn.dbo.ghr_employee_events
        DBShrpn.dbo.ghr_historical_message

    Example:
        EXEC DBShrpn.dbo.usp_ghr_int_validate_bulkcopy

    Note:
        If you run this outside of the job scheduler, an error will be logged to the most recent
        activity date in the log table.

   Revision history:
   version  date        developer   SCR         description
   -------  ----------  ---------   -----       ------------------------------------
   1.0.00   03/04/2026  CJP                     - Created

************************************************************************************/

CREATE PROCEDURE dbo.usp_ghr_int_validate_bulkcopy

AS

BEGIN

    SET NOCOUNT ON

    DECLARE @v_step_position                varchar(255)        = 'Begin Procedure'

    DECLARE @v_END_OF_TIME_DATE             datetime            = '29991231'

    DECLARE @v_ACTIVITY_STATUS_BAD          char(2)             = '02'

    DECLARE @v_PSC_BATCHNAME                char(08)            = 'GHR'
    DECLARE @w_PSC_QUALIFIER                char(30)            = 'INTERFACES'
    DECLARE @w_PSC_PSC_PGM_PARMS            varchar(255)        = 'GHR_EMPLOYEE_EVENTS'

    DECLARE @v_EMPTY_SPACE                  char(01)            = ''


    DECLARE @ErrorNumber                    varchar(10)
    DECLARE @ErrorMessage                   nvarchar(4000)
    DECLARE @ErrorSeverity                  int
    DECLARE @ErrorState                     int

    DECLARE @w_activity_date	            datetime
    DECLARE @w_userid			            varchar(30)

    DECLARE @v_ret_val                      int = 0



    BEGIN TRY

        SET @v_step_position = 'Lookup Activity Date'

        -- Get the user id executing the job
        SET @w_userid = SYSTEM_USER

        -- Find the Batch name and qualifier for the job running the Bulk Copy
        SELECT @w_activity_date = psc_last_comp_date
        FROM DBSpscb.dbo.psc_step
        WHERE   (psc_userid    = @w_userid)
            AND (psc_batchname = @v_PSC_BATCHNAME)
            AND (psc_qualifier = @w_PSC_QUALIFIER)
            AND (psc_pgm_parms = @w_PSC_PSC_PGM_PARMS)     -- bulkcopy step


        -- Are there any records in the table
        SET @v_step_position = 'Check records exist'

        IF NOT EXISTS   (
                            SELECT 1 FROM DBShrpn.dbo.ghr_employee_events
                        )
        BEGIN

            -- Log Error
            SET @v_step_position = 'Log no record error'

            EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
                  @p_msg_id             = 'U00122'
                , @p_eff_date           = @w_activity_date
                , @p_msg_desc           = 'No records were imported in the bulkcopy step - ending job execution.'
                , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
                , @p_activity_date      = @w_activity_date

            -- Set error return code
            SET @v_ret_val = -1

        END


    END TRY
    BEGIN CATCH

        SELECT @ErrorNumber   = CAST(ERROR_NUMBER() AS varchar(10))
             , @ErrorMessage  = @v_step_position + ' - ' + ERROR_MESSAGE()
             , @ErrorSeverity = ERROR_SEVERITY()
             , @ErrorState    = ERROR_STATE()
             , @v_ret_val      = -1



        -- Historical Message for reporting purpose
        EXEC DBShrpn.dbo.usp_ins_ghr_historical_message
              @p_msg_id             = @ErrorNumber
            , @p_eff_date           = @w_activity_date
            , @p_msg_desc           = @ErrorMessage
            , @p_activity_status    = @v_ACTIVITY_STATUS_BAD
            , @p_activity_date      = @w_activity_date


    END CATCH


    RETURN @v_ret_val

END
GO

ALTER AUTHORIZATION ON dbo.usp_ghr_int_validate_bulkcopy TO  SCHEMA OWNER
GO

IF OBJECT_ID(N'dbo.usp_ghr_int_validate_bulkcopy', N'P') IS NOT NULL
    PRINT N'<<< CREATED PROCEDURE dbo.usp_ghr_int_validate_bulkcopy >>>'
ELSE
    PRINT N'<<< FAILED CREATING PROCEDURE dbo.usp_ghr_int_validate_bulkcopy >>>'
GO