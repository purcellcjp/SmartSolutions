USE DBShrpn
GO

BEGIN

   DECLARE @tbl_pay_ele TABLE 
   (
    pay_element_id      char(10)    NOT NULL
   )

   INSERT INTO @tbl_pay_ele (pay_element_id)
   VALUES
     ('EENTERTN')
   , ('EENTERTN1')
   , ('EGOVLIVALL')
   , ('EHEAT')
   , ('EHEAT1')
   , ('EHOUSE1')
   , ('EHOUSE2')
   , ('EINLIEU')
   , ('ELNDRY')
   , ('ELNDRY1')
   , ('ELODG')
   , ('ELODG1')
   , ('EMEAL')
   , ('ENTMA')
   , ('EPHONE')
   , ('EPHONE1')
   , ('EPLAINCTH')
   , ('EPLAINCTH1')
   , ('ERELO')
   , ('ESPECIAL')
   , ('ETRANSPORT')
   , ('ETRAVEL')
   , ('ETRAVEL1')
   , ('ETRAVEL2')
   , ('EUNFRM')
   , ('EUNFRM1')
   , ('EUNIFRM')
   , ('EWMEAL')
   , ('EWMEAL1')
   , ('EWUNI')
   , ('INCONVEN')
   , ('PEN-ANGU')
   , ('PEN-ANT')
   , ('PEN-BVI')
   , ('PEN-DOM')
   , ('PEN-GREN')
   , ('PEN-MONT')
   , ('PEN-SKITT')
   , ('PEN-SVIN')
   , ('TA&EROOM')
   , ('TA&EROOM1')
   , ('TACTNG')
   , ('TANESFEE')
   , ('TBAND')
   , ('TBAND1')
   , ('TCALLOUT')
   , ('TDETECTV')
   , ('TDETECTV1')
   , ('TDUTYALW')
   , ('TDUTYALW1')
   , ('TDUTYFIRE')
   , ('TDUTYFIRE1')
   , ('TDUTYPRIS')
   , ('TDUTYPRIS1')
   , ('TEXCESS')
   , ('TEXCESS1')
   , ('THAZARD')
   , ('THAZARD1')
   , ('THNRIUM')
   , ('TINCON')
   , ('TLEGALOF')
   , ('TLEGALOF1')
   , ('TLEGALOFF')
   , ('TLEGALOFF1')
   , ('TMIDWIFE')
   , ('TMIDWIFE1')
   , ('TMILITARY')
   , ('TMILITARY1')
   , ('TNNIGHT')
   , ('TNNIGHT1')
   , ('TONCALL')
   , ('TPNIGHT')
   , ('TPNIGHT1')
   , ('TPROJALL')
   , ('TPROSCUTE1')
   , ('TPROSECUTE')
   , ('TRECLASS')
   , ('TRISK')
   , ('TRISK1')
   , ('TSHIFT')
   , ('TSHIFT1')
   , ('TSKILLS')
   , ('TSKILLS1')
   , ('TSNIGHT')
   , ('TSNIGHT1')
   , ('TSPECIAL')
   , ('TSPECIAL1')
   , ('TSPECLIST')
   , ('TSPECLIST1')
   , ('TWSHIFT')
   , ('TWSHIFT1')
   , ('TWSPECIAL')

/*
   select t.pay_element_id
   from @tbl_pay_ele t
   left join dbo.pay_element pe ON
		t.pay_element_id = pe.pay_element_id and
		pe.next_eff_date = '12/31/2999'
	where pe.pay_element_id is null
*/


   SELECT pe.pay_element_id
        , pe.calc_meth_code
        , CASE calc_meth_code
			WHEN '01' THEN 'Fixed Amount'
			WHEN '02' THEN 'Percentage * Basis Amount'
			WHEN '03' THEN 'Rate * Hours'
			WHEN '04' THEN 'Rate * Basis Hours'
			WHEN '05' THEN 'Rate * Number of Units'
			WHEN '06' THEN 'Rate * Basis Number of Units'
			WHEN '07' THEN 'Rate Table Fixed Amount'
			WHEN '08' THEN 'Rate Table Percentage * Basis Amount'
			WHEN '09' THEN 'Rate Table Rate * Hours'
			WHEN '10' THEN 'Rate Table Rate * Basis Hours'
			WHEN '11' THEN 'Rate Table Rate * Number of Units'
			WHEN '12' THEN 'Rate Table Rate * Basis Number of Units'
			WHEN '13' THEN 'Percentage of Employee''s Annual Salary'
			WHEN '14' THEN 'Percentage of Employee''s Pay Period Salary'
			WHEN '15' THEN 'Rate Table Percentage of Employee''s Annual Salary'
			WHEN '16' THEN 'Rate Table Percentage of Employee''s Pay Period Salary'
			WHEN '17' THEN '(Basis Earnings Average Hourly Rate * Factor) * Hours'
			WHEN '18' THEN '(Basis Earnings Average Hourly Rate * Factor) * Basis Hours'
			WHEN '19' THEN 'Percentage of Employee''s Available Net Pay'
			WHEN '20' THEN 'Rate Table Percentage of Employee''s Available Net Pay'
			WHEN '21' THEN 'Base Rate * Hours'
			WHEN '22' THEN '(Base Rate + Shift Rate) * Hours'
			WHEN '23' THEN '(Base Rate * Factor) * Hours'
			WHEN '24' THEN '((Base Rate + Shift Rate) * Factor) * Hours'
			WHEN '25' THEN 'Fixed Amount not to Exceed Basis Amount'
			WHEN '99' THEN'Special Calculation'
			ELSE ''
		  END calc_meth_code_desc
        , pe.eff_date
		, pe.start_date
		, pe.stop_date
		, pe.rate_tbl_id
		, *

   FROM dbo.pay_element pe
   WHERE (pe.next_eff_date = '12/31/2999')
     AND (pe.pay_element_id IN (
	                            SELECT t.pay_element_id 
				   			    FROM @tbl_pay_ele t 
							    WHERE 1=1
							      --AND (CHARINDEX('1',t.pay_element_id) = 0)
							   ))
   


END