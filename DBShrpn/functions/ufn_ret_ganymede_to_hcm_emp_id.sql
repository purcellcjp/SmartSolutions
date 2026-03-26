USE DBShrpn
GO

IF OBJECT_ID('dbo.ufn_ret_ganymede_to_hcm_emp_id') IS NOT NULL
BEGIN
    DROP FUNCTION dbo.ufn_ret_ganymede_to_hcm_emp_id
    IF OBJECT_ID('dbo.ufn_ret_ganymede_to_hcm_emp_id') IS NOT NULL
        PRINT '<<< FAILED DROPPING FUNCTION dbo.ufn_ret_ganymede_to_hcm_emp_id >>>'
    ELSE
        PRINT '<<< DROPPED FUNCTION dbo.ufn_ret_ganymede_to_hcm_emp_id >>>'
END
GO

/****************************************************************************************

  Function:     ufn_ret_ganymede_to_hcm_emp_id
  Author:       Chris Purcell

  Description:  Converts ganymede employee id to HCM employee id
                Ganymede employee ids are prefixed with 'D'
                where they are prefixed with '4'

  Parameters:   @p_file_source = 'SS VENUS' or 'SS GANYMEDE'
                @p_emp_id      = Employee ID


   Example:
      SELECT dbo.ufn_ret_ganymede_to_hcm_emp_id ('SS GANYMEDE','D3929')

   Revision history:
      version  date        developer   SCR      description
      -------  ----------  ---------   -----    ------------------------------------
      1.0.00   10/13/2025  CJP                  - Created function

****************************************************************************************/


CREATE FUNCTION dbo.ufn_ret_ganymede_to_hcm_emp_id
(
  @p_file_source    varchar(50)
, @p_emp_id         char(15)
)

RETURNS char(15)
AS
BEGIN

    DECLARE @v_emp_id  char(15) = ''

    IF (@p_file_source = 'SS GANYMEDE')
        IF (CHARINDEX('D', @p_emp_id, 1) = 1)
            SET @v_emp_id = STUFF(@p_emp_id, 1, 1, '4')
        ELSE
            SET @v_emp_id = @p_emp_id
    ELSE
        SET @v_emp_id = @p_emp_id


    RETURN @v_emp_id

END
GO

ALTER AUTHORIZATION ON dbo.ufn_ret_ganymede_to_hcm_emp_id TO  SCHEMA OWNER
GO

GRANT  REFERENCES ,  EXECUTE  ON dbo.ufn_ret_ganymede_to_hcm_emp_id  TO [public];
GO

IF OBJECT_ID('dbo.ufn_ret_ganymede_to_hcm_emp_id') IS NOT NULL
    PRINT '<<< CREATED FUNCTION dbo.ufn_ret_ganymede_to_hcm_emp_id >>>'
ELSE
    PRINT '<<< FAILED CREATING FUNCTION dbo.ufn_ret_ganymede_to_hcm_emp_id >>>'
GO
