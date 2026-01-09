select ea.emp_id
, stat.emp_status_code
, ea.eff_date
, ea.annual_salary_amt
, ea.pd_salary_amt
, ea.pd_salary_tm_pd_id
, ea.hourly_pay_rate
, ea.standard_work_pd_id
, ea.standard_work_hrs
, ea.work_tm_code
, ee.pay_group_id
, pg.pay_frequency_code
, tm.annualizing_factor
, tm.tm_pd_hrs

from dbo.uvu_emp_assignment_most_rec ea
join DBShrpn..uvu_emp_status_most_rec stat ON
	(ea.emp_id = stat.emp_id)
join dbo.uvu_emp_employment_most_rec ee on
	(ea.emp_id = ee.emp_id)
join DBShrpn..pay_group pg ON
	(ee.pay_group_id = pg.pay_group_id)
join DBShrpn.dbo.tm_pd_policy tm ON
	(pg.pay_frequency_code = tm.tm_pd_id)

WHERE (stat.emp_status_code =  'A')
and ea.standard_work_pd_id <> 'MONTH'
