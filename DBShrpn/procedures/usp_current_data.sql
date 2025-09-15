USE DBShrpn
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'dbo.usp_current_data', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.usp_current_data
    IF OBJECT_ID(N'dbo.usp_current_data') IS NOT NULL
        PRINT N'<<< FAILED DROPPING PROCEDURE dbo.usp_current_data >>>'
    ELSE
        PRINT N'<<< DROPPED PROCEDURE dbo.usp_current_data >>>'
END
GO


CREATE procedure dbo.usp_current_data
AS
BEGIN

    SET NOCOUNT ON

    CREATE TABLE #ghr_current_temp1
    (
      Employee_Number                   char(15)        NOT NULL
    , First_Name                        char(25)        NOT NULL
    , Middle_Name                       char(25)        NOT NULL
    , Last_Name                         char(30)        NOT NULL
    , Employer                          char(10)        NOT NULL
    , National_Id_Type                  char(05)        NOT NULL
    , National_Id_Nbr                   char(20)        NOT NULL
    , Position_Title                    char(50)        NOT NULL
    , Organization_Unit_name            varchar(240)    NOT NULL
    , Annual_Salary                     money           NOT NULL
    , Time_Reporting_Method             char(01)        NOT NULL
    , Pay_Element_Ctrl_Group            char(10)        NOT NULL
    , Pay_Group                         char(10)        NOT NULL
    , Pay_Status                        char(01)        NOT NULL
    , Pay_Through_Date                  datetime        NOT NULL
    , Hire_Date                         datetime        NOT NULL
    , Original_Job_Position_Title       char(80)        NOT NULL    -- need to handle null values
    , Employee_Status                   char(01)        NOT NULL
    , Labor_Group_Code                  char(05)        NOT NULL
    )

	CREATE NONCLUSTERED INDEX idx_ghr_current_temp1 ON #ghr_current_temp1
	(Employee_Number)

    ---------------------------------------------------------------------------
    -- First insert emp assignment end date > system date
    ---------------------------------------------------------------------------
    INSERT INTO #ghr_current_temp1
    SELECT e.emp_id
         , i.first_name
         , i.first_middle_name
         , i.last_name
         , ee.empl_id
         , p.national_id_1_type_code
         , p.national_id_1
         , p.user_text_1
         , ea.organization_unit_name
         , ea.annual_salary_amt
         , ee.time_reporting_meth_code
         , ee.pay_element_ctrl_grp_id
         , ee.pay_group_id
         , ee.pay_status_code
         , ee.pay_through_date
         , es.hire_date
         , CASE WHEN pt.title IS NOT NULL THEN pt.title ELSE ISNULL(jt.title, '') END
         , es.emp_status_code
         , ee.labor_grp_code
    FROM DBShrpn.dbo.employee e
    JOIN DBShrpn.dbo.individual i ON
        (i.individual_id = e.individual_id)
    JOIN DBShrpn.dbo.individual_personal p ON
        (p.individual_id = e.individual_id)
    JOIN DBShrpn.dbo.emp_employment ee ON
        (ee.emp_id = e.emp_id) AND
        (ee.eff_date = (
                        SELECT MAX(ee2.eff_date)
                        FROM DBShrpn.dbo.emp_employment ee2
                        WHERE ee2.emp_id = ee.emp_id
                        AND ee2.eff_date <= GETDATE()
                       ))
    JOIN DBShrpn.dbo.emp_assignment ea ON
        (ea.emp_id = e.emp_id) AND
        (ea.eff_date = (
                        SELECT MAX(ea2.eff_date)
                        FROM DBShrpn.dbo.emp_assignment ea2
                        WHERE ea2.emp_id = ea.emp_id
                        AND ea2.prime_assignment_ind = 'Y'
                        AND ea2.eff_date <= GETDATE()
                       )) AND
        (ea.prime_assignment_ind = 'Y') AND
        (ea.end_date > GETDATE())
    JOIN DBShrpn.dbo.emp_status es ON
        (es.emp_id = e.emp_id) AND
        (es.status_change_date = (
                                    SELECT MAX(es2.status_change_date)
                                    FROM DBShrpn.dbo.emp_status es2
                                    WHERE es2.emp_id = es.emp_id
                                    AND es2.status_change_date <= GETDATE()
                                    ))
    LEFT JOIN DBShrpn.dbo.pos_title pt ON
        (pt.pos_id = ea.job_or_pos_id) AND
        (pt.eff_date = (
                        SELECT MAX(pt2.eff_date)
                        FROM DBShrpn.dbo.pos_title pt2
                        WHERE pt2.pos_id = pt.pos_id
                        AND pt2.eff_date <= GETDATE()
                       ))
    LEFT JOIN DBShrpn.dbo.job_title jt ON
        (jt.job_id = ea.job_or_pos_id) AND
        (jt.eff_date = (
                        SELECT MAX(jt2.eff_date)
                        FROM DBShrpn.dbo.job_title jt2
                        WHERE jt2.job_id = jt.job_id
                        AND jt2.eff_date <= GETDATE()
                       ))


    ---------------------------------------------------------------------------
    -- Second Insert emp assignment end date < system date
    ---------------------------------------------------------------------------
    INSERT INTO #ghr_current_temp1
    SELECT e.emp_id
         , i.first_name
         , i.first_middle_name
         , i.last_name
         , ee.empl_id
         , p.national_id_1_type_code
         , p.national_id_1
         , p.user_text_1
         , ea.organization_unit_name
         , ea.annual_salary_amt
         , ee.time_reporting_meth_code
         , ee.pay_element_ctrl_grp_id
         , ee.pay_group_id
         , ee.pay_status_code
         , ee.pay_through_date
         , es.hire_date
         , CASE WHEN pt.title IS NOT NULL THEN pt.title ELSE ISNULL(jt.title, '') END
         , es.emp_status_code
         , ee.labor_grp_code
    FROM DBShrpn.dbo.employee e
    JOIN DBShrpn.dbo.individual i ON
        (i.individual_id = e.individual_id)
    JOIN DBShrpn.dbo.individual_personal p ON
        (p.individual_id = e.individual_id)
    JOIN DBShrpn.dbo.emp_employment ee ON
        (ee.emp_id = e.emp_id) AND
        (ee.eff_date = (
                        SELECT MAX(eff_date)
                        FROM DBShrpn.dbo.emp_employment t
                        WHERE t.emp_id = ee.emp_id
                        AND t.eff_date <= GETDATE()
                       ))
    JOIN DBShrpn.dbo.emp_assignment ea ON
        (ea.emp_id = e.emp_id) AND
        (ea.eff_date = (
                        SELECT MAX(ea2.eff_date)
                        FROM DBShrpn.dbo.emp_assignment ea2
                        WHERE ea2.emp_id = ea.emp_id
                        AND ea2.prime_assignment_ind = 'Y'
                        AND ea2.eff_date <= GETDATE()
                       )) AND
        (ea.prime_assignment_ind = 'Y') AND
        (ea.end_date < GETDATE())
    JOIN DBShrpn.dbo.emp_status es ON
        (es.emp_id = e.emp_id) AND
        (es.status_change_date = (
                                    SELECT MAX(es2.status_change_date)
                                    FROM DBShrpn.dbo.emp_status es2
                                    WHERE es2.emp_id = es.emp_id
                                      AND es2.status_change_date <= GETDATE()
                                    ))
    LEFT JOIN DBShrpn.dbo.pos_title pt ON
        (pt.pos_id = ea.job_or_pos_id) AND
        (pt.eff_date = (
                        SELECT MAX(pt2.eff_date)
                        FROM DBShrpn.dbo.pos_title pt2
                        WHERE pt2.pos_id = pt.pos_id
                        AND pt2.eff_date <= GETDATE()
                       ))
    LEFT JOIN DBShrpn.dbo.job_title jt ON
        (jt.job_id = ea.job_or_pos_id) AND
        (jt.eff_date = (
                        SELECT MAX(jt2.eff_date)
                        FROM DBShrpn.dbo.job_title jt2
                        WHERE jt2.job_id = jt.job_id
                        AND jt2.eff_date <= GETDATE()
                       ))
    WHERE (e.emp_id NOT IN (
                            SELECT t.Employee_Number
                            FROM #ghr_current_temp1 t
                           ))


    -- Output records
    SELECT CASE
             WHEN LEFT(Employee_Number, 1) = 'D' THEN '4' + SUBSTRING(Employee_Number, 2, 14)
             ELSE Employee_Number
           END Employee_Number
         , First_Name
         , Middle_Name
         , Last_Name
         , Employer
         , National_Id_Type
         , National_Id_Nbr
         , Position_Title
         , Organization_Unit_name
         , Annual_Salary
         , Time_Reporting_Method
         , Pay_Element_Ctrl_Group
         , Pay_Group
         , Pay_Status
         , Pay_Through_Date
         , Hire_Date
         , Original_Job_Position_Title
         , Employee_Status
         , Labor_Group_Code
    FROM #ghr_current_temp1


    DROP TABLE #ghr_current_temp1


END  --End of Proc

ALTER AUTHORIZATION ON dbo.usp_current_data TO  SCHEMA OWNER
GO

IF OBJECT_ID(N'dbo.usp_current_data', N'P') IS NOT NULL
    PRINT N'<<< CREATED PROCEDURE dbo.usp_current_data >>>'
ELSE
    PRINT N'<<< FAILED CREATING PROCEDURE dbo.usp_current_data >>>'
GO
