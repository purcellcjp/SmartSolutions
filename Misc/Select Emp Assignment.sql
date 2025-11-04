declare @v_emp_id char(15) = '11035'--'19686'
/*
update DBShrpn.dbo.emp_assignment
set next_job_or_pos_id = ''
, end_date = '29991231'
where emp_id = '10077'
and eff_date = '20240401'
and next_eff_date = '29991231'

*/

select *
from DBShrpn..emp_assignment
where emp_id = @v_emp_id
order by eff_date

select * 
from DBShrpn..emp_status
where emp_id = @v_emp_id

