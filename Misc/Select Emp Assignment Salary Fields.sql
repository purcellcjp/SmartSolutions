select stat.emp_status_code
     , ea.*
     , ee.pay_group_id
     , pg.pay_frequency_code
     , tm.annualizing_factor
     , tm.tm_pd_hrs

from DBShrpn.dbo.uvu_emp_assignment_most_rec ea
join DBShrpn..uvu_emp_status_most_rec stat ON
	(ea.emp_id = stat.emp_id)
join DBShrpn.dbo.uvu_emp_employment_most_rec ee on
	(ea.emp_id = ee.emp_id)
join DBShrpn.dbo.pay_group pg ON
	(ee.pay_group_id = pg.pay_group_id)
join DBShrpn.dbo.tm_pd_policy tm ON
	(pg.pay_frequency_code = tm.tm_pd_id)

WHERE 1=1
  --and (stat.emp_status_code =  'A')
--and ea.standard_work_pd_id <> 'MONTH'
and ea.emp_id IN (
'30447',
'34003',
'35453',
'35035',
'32977'
)

