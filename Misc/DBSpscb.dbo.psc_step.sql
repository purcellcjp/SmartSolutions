/****** Script for SelectTopNRows command from SSMS  ******/
SELECT *
FROM DBSpscb.dbo.psc_step
where psc_userid = 'DBS'
order by psc_batchname
       , psc_qualifier
       , psc_step_number

