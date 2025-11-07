USE DBShrpn;
GO

SET ANSI_NULLS OFF;
GO
SET QUOTED_IDENTIFIER OFF;
GO

IF OBJECT_ID(N'dbo.usp_cleanup_tbl', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_cleanup_tbl
    IF OBJECT_ID(N'dbo.usp_cleanup_tbl') IS NOT NULL
        PRINT N'<<< FAILED DROPPING PROCEDURE dbo.usp_cleanup_tbl >>>'
    ELSE
        PRINT N'<<< DROPPED PROCEDURE dbo.usp_cleanup_tbl >>>'
END
GO

/*************************************************************************************
    SP Name:       usp_cleanup_tbl

    Description:    Used in Job Scheduler Bulk Copy step GHR_EMPLOYEE_EVENTS in
                    Before Stored Procedure setting.

                    Procedure deletes all entries in table DBShrpn.dbo.ghr_employee_events
                    prior to importing data.


    Parameters:
        None



    Example:
        EXEC DBShrpn.dbo.usp_ins_new_hire


   Revision history:
   version  date        developer   SCR         description
   -------  ----------  ---------   -----       ------------------------------------
   1.0.00                                       - Cloned from GOG version
													1) Removed parameter @USER_ID - not used

************************************************************************************/

CREATE procedure dbo.usp_cleanup_tbl


AS
BEGIN

    DELETE FROM DBShrpn.dbo.ghr_employee_events

END

GRANT EXECUTE ON dbo.usp_cleanup_tbl TO PUBLIC
GO

ALTER AUTHORIZATION ON dbo.usp_cleanup_tbl TO  SCHEMA OWNER
GO

IF OBJECT_ID(N'dbo.usp_cleanup_tbl', N'P') IS NOT NULL
    PRINT N'<<< CREATED PROCEDURE dbo.usp_cleanup_tbl >>>'
ELSE
    PRINT N'<<< FAILED CREATING PROCEDURE dbo.usp_cleanup_tbl >>>'
GO
