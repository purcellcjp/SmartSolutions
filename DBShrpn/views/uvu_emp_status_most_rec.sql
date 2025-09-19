USE DBShrpn
GO


IF OBJECT_ID('dbo.uvu_emp_status_most_rec') IS NOT NULL
BEGIN
    DROP VIEW dbo.uvu_emp_status_most_rec
    IF OBJECT_ID('dbo.uvu_emp_status_most_rec') IS NOT NULL
        PRINT '<<< FAILED DROPPING VIEW dbo.uvu_emp_status_most_rec >>>'
    ELSE
        PRINT '<<< DROPPED VIEW dbo.uvu_emp_status_most_rec >>>'
END
GO

/****************************************************************************************

   View Name:     uvu_emp_status_most_rec

   Description:   Used to obtain the most recent employee assignment information.

   Table_Name(s):   INPUT:    DBShrpn..emp_status

   Revision history:
      version  date        developer   description
      -------  ----------  ---------   --------------------------------------------------
      1.0.00   08/06/2025  cjp         - Created view

****************************************************************************************/

CREATE VIEW dbo.uvu_emp_status_most_rec

AS

SELECT stat1.emp_id
     , stat1.status_change_date
     , stat1.prior_change_date
     , stat1.next_change_date
     , stat1.emp_status_code
     , stat1.emp_status_classn_code
     , stat1.inactive_reason_code
     , stat1.hire_date
     , stat1.loa_expected_return_date
     , stat1.consider_for_rehire_ind
     , stat1.active_reason_code
     , stat1.termination_reason_code
     , stat1.last_action_code
     , stat1.chgstamp
FROM DBShrpn.dbo.emp_status stat1
WHERE (stat1.next_change_date = '12/31/2999')
  AND (stat1.status_change_date = (
                                    SELECT MAX(stat2.status_change_date)
                                    FROM DBShrpn..emp_status stat2
                                    WHERE (stat2.emp_id           = stat1.emp_id)
                                      AND (stat2.next_change_date = stat1.next_change_date)
                                   ))

GO

ALTER AUTHORIZATION ON dbo.uvu_emp_status_most_rec TO  SCHEMA OWNER
GO


IF OBJECT_ID('dbo.uvu_emp_status_most_rec') IS NOT NULL
    PRINT '<<< CREATED VIEW dbo.uvu_emp_status_most_rec >>>'
ELSE
    PRINT '<<< FAILED CREATING VIEW dbo.uvu_emp_status_most_rec >>>'
GO
