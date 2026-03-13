select TOP 50
  stat.emp_id
, ind.first_name
, ind.first_middle_name
, ind.last_name

, stat.emp_status_code
, stat.status_change_date

, eempl.empl_id
, eempl.pay_element_ctrl_grp_id
, eempl.pay_group_id

, asgn.annual_salary_amt
, asgn.hourly_pay_rate

, ind.addr_1_line_1
, ind.addr_1_line_2
, ind.addr_1_street_or_pob_1
, ind.addr_1_street_or_pob_2
, ind.addr_1_city_name
, ind.addr_1_country_sub_entity_code
, ind.addr_1_postal_code
, ind.addr_1_country_code
, ind.addr_1_fmt_code
, ind.addr_1_type_code


from DBShrpn..uvu_emp_status_most_rec stat
join DBShrpn.dbo.employee emp ON
stat.emp_id = emp.emp_id
join DBShrpn.dbo.individual ind ON
emp.individual_id = ind.individual_id

join DBShrpn.dbo.uvu_emp_employment_most_rec eempl ON
stat.emp_id = eempl.emp_id

join DBShrpn.dbo.uvu_emp_assignment_most_rec asgn ON
stat.emp_id = asgn.emp_id

where emp_status_code = 'T'
order by status_change_date desc
