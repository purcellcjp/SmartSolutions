USE DBSCOMMON
GO

DELETE FROM dbo.message_master
WHERE (msg_id LIKE 'U%')
GO


INSERT dbo.message_master (msg_id, severity_cd, user_def, msg_text, msg_text_2, msg_text_3, help_context, help_file_id, pscm_flag, CHGSTAMP)
VALUES
  (N'U00000', 1, 0, N'< NEW HIRE SECTION (1) >', N' ', N' ', 0, N'', 0, 0)
, (N'U00001', 1, 0, N'Total Global HR New Hire: @1', N' ', N' ', 0, N'', 0, 0)
, (N'U00002', 1, 0, N'< ENCOUNTERED THE FOLLOWING ERRORS: >', N' ', N' ', 0, N'', 0, 0)
, (N'U00003', 1, 0, N'Total number of employees that already exist: @1', N' ', N' ', 0, N'', 0, 0)
, (N'U00005', 1, 0, N'Employer (@1) does not exist for employee: @2 - bypassing record.', N'Y', N' ', 0, N'', 0, 0)
, (N'U00006', 1, 0, N'Employee, @1, National ID already exists - defaulting to 99999. National ID ID is: @2.', N'Y', N' ', 0, N'', 0, 0)
, (N'U00007', 1, 0, N'National ID was blank for employee, @1 - defaulting to ''99999''.', N'Y', N' ', 0, N'', 0, 0)
, (N'U00008', 1, 0, N'Unit name (@1) was missing for employee, @2 - defaulting to 999999.', N'Y', N' ', 0, N'', 0, 0)
, (N'U00009', 1, 0, N'< BEGINNING OF ERROR MESSAGES: >', N' ', N' ', 0, N'', 0, 0)
, (N'U00010', 1, 0, N'< ENDING OF ERROR MESSAGES: >', N' ', N' ', 0, N'', 0, 0)
, (N'U00011', 1, 0, N' ', N' ', N' ', 0, N'', 0, 0)
, (N'U00012', 1, 0, N'Employee, @1, does not exist.', N'Y', N' ', 0, N'', 0, 0)
, (N'U00013', 1, 0, N'< NAME CHANGE SECTION (4) >', N' ', N' ', 0, N'', 0, 0)
, (N'U00014', 1, 0, N'< SALARY CHANGE SECTION (2) >', N' ', N' ', 0, N'', 0, 0)
, (N'U00015', 1, 0, N'Total Global HR Salary Changes: @1', N' ', N' ', 0, N'', 0, 0)
, (N'U00016', 1, 0, N'Total Global HR Name Changes: @1', N' ', N' ', 0, N'', 0, 0)
, (N'U00017', 1, 0, N'< EMPLOYEE TRANSFER SECTION (3) >', N' ', N' ', 0, N'', 0, 0)
, (N'U00018', 1, 0, N'Total Global HR Employee Transfer: @1', N' ', N' ', 0, N'', 0, 0)
, (N'U00019', 1, 0, N'Total Global HR Status Changes: @1', N' ', N' ', 0, N'', 0, 0)
, (N'U00020', 1, 0, N'Invalid Pay Group ID, (@1), for employee, @2 - defaulting to 99999.', N'Y', N' ', 0, N'', 0, 0)
, (N'U00021', 1, 0, N'Pay Element Control Group, @1 does not exists for employee, @2 - defaulting to 99999.', N' ', N' ', 0, N'', 0, 0)
, (N'U00022', 1, 0, N'The current status is @1. Cannot rehire an employee, @2, without a current terminated status.', N'Y', N' ', 0, N'', 0, 0)
, (N'U00023', 1, 0, N'< STATUS CHANGE SECTION (5) >', N' ', N' ', 0, N'', 0, 0)
, (N'U00024', 1, 0, N'Cannot Inactivate an employee, @1, if the current status is not active.', N'Y', N' ', 0, N'', 0, 0)
, (N'U00025', 1, 0, N'Cannot Reactivate an employee, @1, if the current status is not inactive.', N'Y', N' ', 0, N'', 0, 0)
, (N'U00026', 1, 0, N'The current status is @1. To Reactivate an employee, @2, the current status must be inactive.', N'Y', N' ', 0, N'', 0, 0)
, (N'U00027', 1, 0, N'The new effective date, @1, for employee, @2, must be greater than the current effective date.', N'Y', N' ', 0, N'', 0, 0)
, (N'U00028', 1, 0, N'< PAY ELEMENT SECTION (6) >', N' ', N' ', 0, N'', 0, 0)
, (N'U00029', 1, 0, N'Total Global HR Pay Elements Read: @1', N'Y', N' ', 0, N'', 0, 0)
, (N'U00030', 1, 0, N'The Begin Date, @1, cannot be greater than the pay through date for employee, @2.', N'Y', N' ', 0, N'', 0, 0)
, (N'U00031', 1, 0, N'Pay Element Group was blank for employee, @1 - defaulting to 99999.', N'Y', N' ', 0, N'', 0, 0)
, (N'U00032', 1, 0, N'The rehire date must be greater than the termination date for employee, @1.', N'Y', N' ', 0, N'', 0, 0)
, (N'U00033', 1, 0, N'The Reactivation date must be greater than the inactivation date - By passing the employee: @1', N'Y', N' ', 0, N'', 0, 0)
, (N'U00034', 1, 0, N'Cannot transfer an employee to the same employer. New Employer is @1 - By passing this employee: @2', N'Y', N' ', 0, N'', 0, 0)
, (N'U00035', 1, 0, N'Salary cannot be blank for salary change record for employee, @1.', N'Y', N' ', 0, N'', 0, 0)
, (N'U00036', 1, 0, N'Transfer date must be greater than default position effective date for employee, @1.', N'Y', N' ', 0, N'', 0, 0)
, (N'U00037', 1, 0, N'New Status Effective date must be greater than current effective date for employee, @1.', N'Y', N' ', 0, N'', 0, 0)
, (N'U00038', 1, 0, N'Existing payments have not been updated into the accumulator for employee, @1.', N'Y', N' ', 0, N'', 0, 0)
, (N'U00039', 1, 0, N'Employer ID, @1, does not exist - bypassing record.', N'Y', N' ', 0, N'', 0, 0)
, (N'U00040', 1, 0, N'Pay Element Control Group cannot be blank for employee, @1, - defaulting to 99999.', N' ', N' ', 0, N'', 0, 0)
, (N'U00041', 1, 0, N'Salary cannot be zero for a Salary Change for employee: @1.', N'Y', N' ', 0, N'', 0, 0)
, (N'U00042', 1, 0, N'Cannot terminate employee, @1, if the current status is not active or inactive.', N'Y', N' ', 0, N'', 0, 0)
, (N'U00043', 1, 0, N'Rehire date must be greater than current employee employment effective date for employee: @1.', N'Y', N' ', 0, N'', 0, 0)
, (N'U00044', 1, 0, N'Cannot transfer employee, @1, to a pensioner employer.', N'Y', N' ', 0, N'', 0, 0)
, (N'U00045', 1, 0, N'Terminated employee, @1, cannot be transferred.', N'Y', N' ', 0, N'', 0, 0)
-- Is U00046 needed? Covered in U00007
, (N'U00046', 1, 0, N'National ID is blank - defaulting to ''99999'' for employee, @1.', N'Y', N' ', 0, N'', 0, 0)
, (N'U00047', 1, 0, N'The stop date, @1, must be equal or greater than the employee pay element effective date for employee, @2.', N'Y', N' ', 0, N'', 0, 0)
, (N'U00048', 1, 0, N'After April 1, 2023,Pay Group, @1, must be semi-monthly.', N' ', N' ', 0, N'', 0, 0)
, (N'U00049', 1, 0, N'Invalid pay element id, @2.', N' ', N' ', 0, N'', 0, 0)
, (N'U00050', 1, 0, N'Employer id, @2, does not match the current employer id.', N' ', N' ', 0, N'', 0, 0)
, (N'U00051', 1, 0, N'Pay element id, @2, has never been assigned to this employee.', N' ', N' ', 0, N'', 0, 0)
, (N'U00052', 1, 0, N'Bank ID, @2, does not exists.', N' ', N' ', 0, N'', 0, 0)
, (N'U00053', 1, 0, N'The interface effective date, @2  must be equal or greater current effective date.', N' ', N' ', 0, N'', 0, 0)
, (N'U00054', 1, 0, N'Must setup direct deposit (DD1) after: New Hire, Rehire, or Transfer to New Legal Entity', N' ', N' ', 0, N'', 0, 0)
, (N'U00055', 1, 0, N'To rehire, the current employee status must be terminated', N' ', N' ', 0, N'', 0, 0)
, (N'U00100', 1, 0, N'WARNING: Invalid Employment Type code, @1, for employee @2.', N'', N'', 0, N'', 0, 0)
, (N'U00101', 1, 0, N'Invalid pay element amount, @1, for employee, @2, and pay element id, @3.', N'Y', N'', 0, N'', 0, 0)
, (N'U00102', 1, 0, N'Invalid date value from HCM, ''@1'', for employee, @2, and event id, @3.', N'Y', N'', 0, N'', 0, 0)
, (N'U00103', 1, 0, N'Pay element id, @1, for employee, @2, is not a valid pay element in the system.', N'', N'', 0, N'', 0, 0)

, (N'U00104', 1, 0, N'<PAY GROUP SECTION (8)>', N'', N'', 0, N'', 0, 0)
, (N'U00105', 1, 0, N'Total Pay Group Changes: @1', N'', N'', 0, N'', 0, 0)
, (N'U00106', 1, 0, N'New pay group, (@1) is same as current pay group, for employee @2 - bypassing record.', N'Y', N'', 0, N'', 0, 0)

, (N'U00107', 1, 0, N'<LABOR GROUP SECTION (9)>', N'', N'', 0, N'', 0, 0)
, (N'U00108', 1, 0, N'Total Labor Group Changes: @1', N'', N'', 0, N'', 0, 0)
, (N'U00109', 1, 0, N'New labor group, (@1) is same as current labor group, for employee @2 - bypassing record.', N'Y', N'', 0, N'', 0, 0)
, (N'U00110', 1, 0, N'New labor group is blank, for employee @2 - bypassing record.', N'Y', N'', 0, N'', 0, 0)
, (N'U00111', 1, 0, N'Invalid Labor Group Code, (@1), for employee, @2 - bypassing record.', N'Y', N' ', 0, N'', 0, 0)

, (N'U00115', 1, 0, N'<POSITION TITLE SECTION (10)>', N'', N'', 0, N'', 0, 0)
, (N'U00116', 1, 0, N'Total Position Title Changes: @1', N'', N'', 0, N'', 0, 0)
, (N'U00117', 1, 0, N'New position title, (@1) is same as current position title, for employee @2 - bypassing record.', N'Y', N'', 0, N'', 0, 0)
, (N'U00118', 1, 0, N'New position title is blank, for employee @1 - bypassing record.', N'Y', N'', 0, N'', 0, 0)
-- U00119 @1 = 'position title' or 'pay group' or 'labor group'
, (N'U00119', 1, 0, N'@1 update, employee @2: New hire, transfer, or rehire status change event is present in this extract. Bypassing record since update would have occurred in one of those events.', N'Y', N'', 0, N'', 0, 0)

, (N'U00120', 1, 0, N'Bypassing @1 record since employee (@2) is terminated in SmartStream.', N'Y', N'', 0, N'', 0, 0)

, (N'U00121', 1, 0, N'Associate, @1, is currently terminated and has rehire record in current extract - bypassing transfer.', N'Y', N'', 0, N'', 0, 0)

, (N'U00122', 1, 0, N'No records were imported in the bulkcopy step - ending job execution.', N'', N'', 0, N'', 0, 0)

, (N'U00123', 1, 0, N'Interface Statistics', N'', N'', 0, N'', 0, 0)
, (N'U00124', 1, 0, N'Invalid annual hours per FTE value for employee, @1.', N'', N'', 0, N'', 0, 0)
, (N'U00125', 1, 0, N'Invalid annual rate value, for employee, @1.', N'', N'', 0, N'', 0, 0)

, (N'U00126', 1, 0, N'New hire update failed for employee, @1.', N'', N'', 0, N'', 0, 0)
GO

select *
from dbo.message_master
WHERE (msg_id LIKE 'U%')
GO