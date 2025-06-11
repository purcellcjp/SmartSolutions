USE DBShrpn
GO
/****** Object:  StoredProcedure dbo.usp_pay_slip_interface    Script Date: 4/1/2025 4:33:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*
(
   @p_userid                  varchar(30)
)
*/

CREATE OR ALTER PROCEDURE dbo.usp_pay_slip_interface

AS


BEGIN

   DECLARE @ret                        INT
   DECLARE @w_msg_text                 VARCHAR(255)
   DECLARE @w_msg_text_2               VARCHAR(255)
   DECLARE @w_msg_text_3               VARCHAR(255)
   DECLARE @w_severity_cd              TINYINT
   DECLARE @special_value_exists       INT
   DECLARE @individual_id              CHAR(10)
   DECLARE @prior_last_name            CHAR(30) 
   DECLARE @max                        INT
   DECLARE @maxx                       CHAR(06)
   DECLARE @cnt                        INT
   DECLARE @current_year               INT
   DECLARE @pay_pd_id                  CHAR(10)
   DECLARE @skey                       INT

   --
   --   Determine the current year
   --
   SELECT @current_year   =   ep.seq_ctrl_yr
   FROM DBShrpy.dbo.emp_pmt ep
   WHERE ep.pmt_type_code = '01'
     AND ep.payroll_run_type_id = 'FORTNIGHT'   -- CJP 5/22//2025 was like '%MONTHLY%'
   AND ep.check_date = (
                        SELECT MAX(ep2.check_date)
                        FROM DBShrpy.dbo.emp_pmt ep2
                        WHERE ep2.pmt_type_code = '01'
                          AND ep2.payroll_run_type_id = ep.payroll_run_type_id
                       )
   GROUP BY ep.seq_ctrl_yr
   
   
   --
   -- ESTABLISHED EMPLOYEE
   --
   IF OBJECT_ID(N'DBShrpy.dbo.ghr_payment_temp', N'U')  IS NOT NULL
   --IF  EXISTS (SELECT * FROM DBShrpy.dbo.sysobjects WHERE name = 'ghr_payment_temp' AND type in (N'U'))
      DROP TABLE DBShrpy.dbo.ghr_payment_temp


   CREATE TABLE DBShrpy.dbo.ghr_payment_temp(
      ID                int   IDENTITY(1,1) NOT NULL,
      empl_id           char(10),
      pay_pd_id         char(10),
      check_date        datetime
   )


   INSERT INTO DBShrpy.dbo.ghr_payment_temp
   SELECT ep.empl_id
        , ep.pay_pd_id
        , ep.check_date
   FROM DBShrpy.dbo.emp_pmt ep
   WHERE ep.seq_ctrl_yr = @current_year   -- CJP 5/22/2025 removed hardcode value 2021
     AND ep.pmt_type_code = '01'
     AND ep.payroll_run_type_id = 'FORTNIGHT'   -- CJP 5/22//2025 was like '%MONTHLY%'
     AND ep.check_date = (
                          SELECT MAX(check_date) 
                          FROM DBShrpy..emp_pmt t 
                          WHERE t.emp_id=ep.emp_id 
                            AND t.payroll_run_type_id = ep.payroll_run_type_id   -- CJP 5/22/2025 replaced  like '%MONTHLY%'
                            AND t.pmt_type_code = '01'
                         )
                         
   IF OBJECT_ID(N'DBShrpy.dbo.ghr_pay_period_temp', N'U')  IS NOT NULL
   --IF EXISTS (SELECT * FROM DBShrpy.dbo.sysobjects WHERE name = 'ghr_pay_period_temp' AND type in (N'U'))
      DROP TABLE DBShrpy.dbo.ghr_pay_period_temp

   CREATE TABLE DBShrpy.dbo.ghr_pay_period_temp(
      ID             int   IDENTITY(1,1) NOT NULL,
      pay_pd_id      char(10) NULL
   )

   INSERT INTO DBShrpy.dbo.ghr_pay_period_temp
   SELECT DISTINCT pay_pd_id
   FROM DBShrpy.dbo.ghr_payment_temp
   WHERE check_date = (
                       SELECT MAX(check_date)
                       FROM DBShrpy.dbo.ghr_payment_temp
                      )

   --
   -- UNESTABLISHED EMPLOYEE
   --
   IF OBJECT_ID(N'DBShrpy.dbo.ghr_payment_temp', N'U')  IS NOT NULL
   --IF  EXISTS (SELECT * FROM DBShrpy.dbo.sysobjects WHERE name = 'ghr_payment_temp' AND type in (N'U'))
      DROP TABLE DBShrpy.dbo.ghr_payment_temp


   CREATE TABLE DBShrpy.dbo.ghr_payment_temp(
      ID             int   IDENTITY(1,1) NOT NULL,
      empl_id        char(10),
      pay_pd_id      char(10),
      check_date     datetime
   )

   INSERT INTO DBShrpy.dbo.ghr_payment_temp
   SELECT ep.empl_id
        , ep.pay_pd_id
        , ep.check_date
   FROM DBShrpy.dbo.emp_pmt ep
   WHERE ep.seq_ctrl_yr = @current_year      -- CJP 5/22/2025 removed hardcode value 2021
     AND ep.pmt_type_code = '01'
     AND ep.payroll_run_type_id = 'FORTNIGHT'      -- CJP 5/22/2025 replaced like '%UNESMONTH%'
     AND ep.check_date = (
                          SELECT MAX(check_date)
                          FROM DBShrpy..emp_pmt t
                          WHERE t.emp_id=ep.emp_id
                            AND t.payroll_run_type_id = ep.payroll_run_type_id   -- CJP 5/22/2025 replaced  like '%MONTHLY%'
                            AND t.pmt_type_code = '01'
                         )
                         

   INSERT INTO DBShrpy.dbo.ghr_pay_period_temp
   SELECT DISTINCT pay_pd_id
   FROM DBShrpy.dbo.ghr_payment_temp
   WHERE check_date = (
                       SELECT MAX(check_date)
                  FROM DBShrpy.dbo.ghr_payment_temp
               )

   --
   --   EMPLOYEE ALLOWANCE
   --
   IF OBJECT_ID(N'DBShrpy.dbo.ghr_payment_temp', N'U')  IS NOT NULL
   --IF  EXISTS (SELECT * FROM DBShrpy.dbo.sysobjects WHERE name = 'ghr_payment_temp' AND type in (N'U'))
      DROP TABLE DBShrpy.dbo.ghr_payment_temp


   CREATE TABLE DBShrpy.dbo.ghr_payment_temp(
      ID             int   IDENTITY(1,1) NOT NULL,
      empl_id        char(10),
      pay_pd_id      char(10),
      check_date     datetime
   )

   INSERT INTO DBShrpy.dbo.ghr_payment_temp
   SELECT empl_id,pay_pd_id,check_date
   FROM DBShrpy.dbo.emp_pmt ep
   WHERE ep.seq_ctrl_yr = @current_year      -- CJP 5/22/2025 removed hardcoded value 2021
     AND ep.pmt_type_code = '01'
     AND ep.payroll_run_type_id like '%ALLOW%'
     AND ep.check_date = (
                          SELECT MAX(check_date)
                          FROM DBShrpy..emp_pmt t
                          WHERE t.emp_id=ep.emp_id
                            AND t.payroll_run_type_id = 'ALLOW'
                            AND t.pmt_type_code = '01'
                    )

   INSERT INTO DBShrpy.dbo.ghr_pay_period_temp
   SELECT DISTINCT pay_pd_id
   FROM DBShrpy.dbo.ghr_payment_temp
   WHERE check_date = (
                       SELECT MAX(check_date)
                       FROM DBShrpy.dbo.ghr_payment_temp
                      )

   IF OBJECT_ID(N'DBShrpy.dbo.ghr_emp_pmt_sum', N'U')  IS NOT NULL
   --IF  EXISTS (SELECT * FROM DBShrpy.dbo.sysobjects WHERE name = 'ghr_emp_pmt_sum' AND type in (N'U'))
      DROP TABLE DBShrpy.dbo.ghr_emp_pmt_sum

   IF OBJECT_ID(N'DBShrpy.dbo.ghr_emp_pmt_pay_element_detail_sum', N'U')  IS NOT NULL
   --IF  EXISTS (SELECT * FROM DBShrpy.dbo.sysobjects WHERE name = 'ghr_emp_pmt_pay_element_detail_sum' AND type in (N'U'))
      DROP TABLE DBShrpy.dbo.ghr_emp_pmt_pay_element_detail_sum


   SET @cnt = 1

   SELECT @max = COUNT(ID) 
   FROM DBShrpy.dbo.ghr_pay_period_temp
   

   DELETE DBShrpn.dbo.ghr_msg_tbl

   WHILE (@cnt <= @max)
   BEGIN
   
      SELECT @pay_pd_id = pay_pd_id
           , @skey      = ID
      FROM DBShrpy.dbo.ghr_pay_period_temp t
      WHERE t.ID = @cnt


      EXEC DBShrpy.dbo.usp_payslip_ext 
           @p_pay_period_id = @pay_pd_id
         , @p_check_nbr     = '000000'

   --
   --   Summarize all the types of payment into one file
   --

      IF @skey = 1
      BEGIN
      --
      -- ESTABLISHED EMPLOYEE
      --
         SELECT 'ESTABLISHED EMPLOYEE'

         SELECT *
         INTO DBShrpy.dbo.ghr_emp_pmt_sum
         FROM DBShrpy.dbo.ghr_emp_pmt_ext

         SELECT *
         INTO DBShrpy.dbo.ghr_emp_pmt_pay_element_detail_sum
         FROM DBShrpy.dbo.ghr_emp_pmt_pay_element_detail_ext

         DELETE DBShrpy.dbo.ghr_emp_pmt_ext
         DELETE DBShrpy.dbo.ghr_emp_pmt_pay_element_detail_ext
      END

      IF @skey = 2
      BEGIN
      --
      -- UNESTABLISHED EMPLOYEE
      --
         SELECT 'UNESTABLISHED EMPLOYEE'

         INSERT INTO DBShrpy.dbo.ghr_emp_pmt_sum
         SELECT *
         FROM DBShrpy.dbo.ghr_emp_pmt_ext

         INSERT INTO DBShrpy.dbo.ghr_emp_pmt_pay_element_detail_sum
         SELECT *
         FROM DBShrpy.dbo.ghr_emp_pmt_pay_element_detail_ext

         DELETE DBShrpy.dbo.ghr_emp_pmt_ext
         DELETE DBShrpy.dbo.ghr_emp_pmt_pay_element_detail_ext
      END

      IF @skey = 3
      BEGIN
      --
      -- EMPLOYEE ALLOWANCE
      --
         SELECT 'EMPLOYEE ALLOWANCE'

         INSERT INTO DBShrpy.dbo.ghr_emp_pmt_sum
         SELECT *
         FROM DBShrpy.dbo.ghr_emp_pmt_ext

         INSERT INTO DBShrpy.dbo.ghr_emp_pmt_pay_element_detail_sum
         SELECT *
         FROM DBShrpy.dbo.ghr_emp_pmt_pay_element_detail_ext

         DELETE DBShrpy.dbo.ghr_emp_pmt_ext
         DELETE DBShrpy.dbo.ghr_emp_pmt_pay_element_detail_ext
      END
      
      
      SELECT @cnt = @cnt + 1
   END

   --
   -- Notify the users of all the issues
   --

   --
   -- Send notification of warning message U00013  -- < Name Change Section (4) >
   --
   /*
   SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
     FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00013'

   SELECT @max = COUNT(*)
   --  SELECT *
     FROM DBShrpn.dbo.ghr_employee_events
    WHERE event_id_01 = '04'
   SELECT @maxx = CAST(@max As CHAR(06))
   SELECT @special_value_exists = 0
   SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)
   SELECT @msg_id = 'U00013'

   SELECT @w_msg_text_2 = ''

   EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2 @p_userid,
      @p_batchname,
      @p_qualifier,
      @msg_id ,
      @w_severity_cd,
      @w_msg_text,
      @w_msg_text_2,
      @w_msg_text_3

   --
   -- End of Sending notification of warning message U00000
   --

   --
   -- Send notification of warning message U00009  -- < BEGINING OF WARNING MESSAGES: >
   --

   SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
   --  SELECT *
     FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00009'

   SELECT @max = COUNT(*)
   --  SELECT *
     FROM DBShrpn.dbo.ghr_employee_events
    WHERE event_id_01 = '04'
   SELECT @maxx = CAST(@max As CHAR(06))
   SELECT @special_value_exists = 0
   SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)
   SELECT @msg_id = 'U00009'

   SELECT @w_msg_text_2 = ''

   EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2 @p_userid,
      @p_batchname,
      @p_qualifier,
      @msg_id ,
      @w_severity_cd,
      @w_msg_text,
      @w_msg_text_2,
      @w_msg_text_3

   --
   -- End of Sending notification of warning message U00009
   --

   --
   -- Send notification of warning message U00011 -- Blank Line
   --

   SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
   --  SELECT *
     FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00011'

   SELECT @maxx = CAST(@max As CHAR(06))
   SELECT @special_value_exists = 0
   SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)
   SELECT @msg_id = 'U00011'

   SELECT @w_msg_text_2 = ''

   EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2 @p_userid,
      @p_batchname,
      @p_qualifier,
      @msg_id ,
      @w_severity_cd,
      @w_msg_text,
      @w_msg_text_2,
      @w_msg_text_3

   --
   -- Send notification of warning message U00016  -- Total Global HR Salary Change:
   --

   SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
   --  SELECT *
     FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00016'

   SELECT @max = COUNT(*)
   --  SELECT *
     FROM DBShrpn.dbo.ghr_employee_events
    WHERE event_id_01 = '04'
   SELECT @maxx = CAST(@max As CHAR(06))
   SELECT @special_value_exists = 0
   SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)
   SELECT @msg_id = 'U00016'

   IF @special_value_exists <> 0 SELECT @w_msg_text = REPLACE(@w_msg_text,'@1',RTRIM(@maxx))
   SELECT @w_msg_text_2 = ''

   EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2 @p_userid,
      @p_batchname,
      @p_qualifier,
      @msg_id ,
      @w_severity_cd,
      @w_msg_text,
      @w_msg_text_2,
      @w_msg_text_3


   --
   -- Send notification of warning message U00011 -- Blank Line
   --

   SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
   --  SELECT *
     FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00011'

   SELECT @maxx = CAST(@max As CHAR(06))
   SELECT @special_value_exists = 0
   SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)
   SELECT @msg_id = 'U00011'

   SELECT @w_msg_text_2 = ''

   EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2 @p_userid,
      @p_batchname,
      @p_qualifier,
      @msg_id ,
      @w_severity_cd,
      @w_msg_text,
      @w_msg_text_2,
      @w_msg_text_3

   --
   -- Send notification of warning message U00010 -- <ENDING OF WARNING MESSAGES: >
   --

   SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
   --  SELECT *
     FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00010'

   SELECT @maxx = CAST(@max As CHAR(06))
   SELECT @special_value_exists = 0
   SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)
   SELECT @msg_id = 'U00010'

   SELECT @w_msg_text_2 = ''

   EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2 @p_userid,
      @p_batchname,
      @p_qualifier,
      @msg_id ,
      @w_severity_cd,
      @w_msg_text,
      @w_msg_text_2,
      @w_msg_text_3


   --
   -- Send notification of warning message U00011 -- Blank Line
   --

   SELECT @w_msg_text = msg_text,@w_msg_text_2= msg_text_2,@w_msg_text_3 = msg_text_3,@w_severity_cd = severity_cd
   --  SELECT *
     FROM DBSCOMMON.dbo.message_master WHERE msg_id = 'U00011'

   SELECT @maxx = CAST(@max As CHAR(06))
   SELECT @special_value_exists = 0
   SELECT @special_value_exists = CHARINDEX('@1',@w_msg_text,1)
   SELECT @msg_id = 'U00011'

   SELECT @w_msg_text_2 = ''

   EXEC DBSpscb.dbo.psp_ins_psc_putmsg_2 @p_userid,
      @p_batchname,
      @p_qualifier,
      @msg_id ,
      @w_severity_cd,
      @w_msg_text,
      @w_msg_text_2,
      @w_msg_text_3

   */

END




GO
ALTER AUTHORIZATION ON dbo.usp_pay_slip_interface TO  SCHEMA OWNER
GO
