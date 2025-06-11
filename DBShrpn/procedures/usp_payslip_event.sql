USE [DBShrpn]
GO
/****** Object:  StoredProcedure [dbo].[usp_payslip_event]    Script Date: 4/1/2025 4:33:00 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE procedure [dbo].[usp_payslip_event]
As
BEGIN  
--
--  EXEC [dbo].[usp_payslip_event]
--
INSERT INTO DBShrpn.dbo.ghr_events 
SELECT CAST('UP' AS char(255))   As [desc], 'U' As status_flag;

DECLARE	@w_psc_userid            char(30), 
		@w_psc_batchname         char(8), 
		@w_psc_qualifier         char(30), 
		@w_psc_batchtype         char(1), 
		@w_psc_description       char(40), 
		@w_psc_security_profile  char(30), 
		@w_psc_interval_spec     varchar(255), 
		@w_psc_nxt_run_date      datetime, 
		@w_psc_last_run_date     datetime, 
		@w_psc_last_updt_date    datetime, 
		@w_psc_last_comp_date    datetime, 
		@w_psc_last_comp_rc      smallint,
		@w_psc_last_low_rc       smallint, 
		@w_psc_lang_code         char(2), 
		@w_psc_lang_code_dialect char(2), 
		@w_psc_status            char(1), 
		@w_psc_first_step        char(8), 
		@w_psc_last_step         char(8), 
		@w_psc_distribution_id   varchar(255),
		@w_psc_dist_status       char(1),
		@w_psc_dist_condx_test   char(1),
		@w_psc_dist_condx_code   smallint, 
		@w_psc_run_now           char(1), 
		@w_psc_last_run_now      char(1), 
		@w_psc_abort_flag        char(1), 
		@w_psc_del_on_end        char(1),
		@w_psc_public            char(1),
		@w_psc_read_only         char(1),
		@w_psc_event_name        char(22), 
		@w_psc_first_run_date    datetime, 
		@w_old_chgstamp          smallint

DECLARE	@max					 int
DECLARE	@cnt					 int
DECLARE @event					 char(255)
--
--	Setup the default value
--
SELECT	@w_psc_userid            =	'JGROSS', 
		@w_psc_batchname         =	'GHR', 
		@w_psc_qualifier         =	'PAYSLIP_INTERFACE', 
		@w_psc_batchtype         =	'I', 
		@w_psc_description       =	'Pay Slip Interface to the Global HR', 
		@w_psc_security_profile  =	'DBS', 
		@w_psc_interval_spec     =	'', 
		@w_psc_nxt_run_date      =	'', 
		@w_psc_last_run_date     =	'29991231 23:59:59', 
		@w_psc_last_updt_date    =	'20210822 00:09:38', 
		@w_psc_last_comp_date    =	'20210822 00:10:02', 
		@w_psc_last_comp_rc		 =	CAST(0 AS smallint),
		@w_psc_last_low_rc       =	CAST(0 AS smallint), 
		@w_psc_lang_code         =	'EN', 
		@w_psc_lang_code_dialect =	'', 
		@w_psc_status            =	'', 
		@w_psc_first_step        =	'EXT', 
		@w_psc_last_step         =	'SENDFILE', 
		@w_psc_distribution_id   =	'TO:jgross@smartsi.com + SMTP:jgross@smartsi.com',
		@w_psc_dist_status       =	'A',
		@w_psc_dist_condx_test   =	'',
		@w_psc_dist_condx_code   =	CAST(0 AS smallint), 
		@w_psc_run_now           =	'Y', 
		@w_psc_last_run_now      =	'Y', 
		@w_psc_abort_flag        =	'N', 
		@w_psc_del_on_end        =	'N',
		@w_psc_public            =	'N',
		@w_psc_read_only         =	'N',
		@w_psc_event_name        =	'', 
		@w_psc_first_run_date    =	'', 
		@w_old_chgstamp          =	CAST(0 AS smallint)		

	SELECT	@w_psc_nxt_run_date			=	'',			
			@w_psc_last_run_date		=	psc_last_run_date,			
			@w_psc_last_updt_date		=	psc_last_updt_date,			
			@w_psc_last_comp_date		=	psc_last_comp_date,	
			@w_old_chgstamp				=	chgstamp 
	  FROM [DBSpscb].[dbo].[psc_batch]
	 WHERE [psc_userid] = 'JGROSS' AND	[psc_batchname]	=	'GHR'  AND [psc_qualifier] = 'PAYSLIP_INTERFACE'		
/*
	SELECT 		 @w_psc_userid, 
                 @w_psc_batchname, 
                 @w_psc_qualifier, 
                 @w_psc_batchtype, 
                 @w_psc_description, 
                 @w_psc_security_profile, 
                 @w_psc_interval_spec, 
                 @w_psc_nxt_run_date, 
                 @w_psc_last_run_date, 
                 @w_psc_last_updt_date, 
                 @w_psc_last_comp_date, 
                 @w_psc_last_comp_rc,
                 @w_psc_last_low_rc, 
                 @w_psc_lang_code, 
                 @w_psc_lang_code_dialect, 
                 @w_psc_status, 
                 @w_psc_first_step, 
                 @w_psc_last_step, 
                 @w_psc_distribution_id,
                 @w_psc_dist_status,
                 @w_psc_dist_condx_test,
                 @w_psc_dist_condx_code, 
                 @w_psc_run_now, 
                 @w_psc_last_run_now, 
                 @w_psc_abort_flag, 
                 @w_psc_del_on_end,
                 @w_psc_public,
                 @w_psc_read_only,
                 @w_psc_event_name, 
				 @w_psc_first_run_date, 
				 @w_old_chgstamp
*/				 
				 
EXEC [DBSpscb].[dbo].[usp_upd_pscb_win1]	@p_psc_userid =	@w_psc_userid, 
                 @p_psc_batchname			=	@w_psc_batchname, 
                 @p_psc_qualifier			=	@w_psc_qualifier, 
                 @p_psc_batchtype			=	@w_psc_batchtype, 
                 @p_psc_description			=	@w_psc_description, 
                 @p_psc_security_profile	=	@w_psc_security_profile, 
                 @p_psc_interval_spec		=	@w_psc_interval_spec, 
                 @p_psc_nxt_run_date		=	@w_psc_nxt_run_date, 
                 @p_psc_last_run_date		=	@w_psc_last_run_date, 
                 @p_psc_last_updt_date		=	@w_psc_last_updt_date, 
                 @p_psc_last_comp_date		=	@w_psc_last_comp_date, 
                 @p_psc_last_comp_rc		=	@w_psc_last_comp_rc,
                 @p_psc_last_low_rc			=	@w_psc_last_low_rc, 
                 @p_psc_lang_code			=	@w_psc_lang_code, 
                 @p_psc_lang_code_dialect	=	@w_psc_lang_code_dialect, 
                 @p_psc_status				=	@w_psc_status, 
                 @p_psc_first_step			=	@w_psc_first_step, 
                 @p_psc_last_step			=	@w_psc_last_step, 
                 @p_psc_distribution_id		=	@w_psc_distribution_id,
                 @p_psc_dist_status			=	@w_psc_dist_status,
                 @p_psc_dist_condx_test		=	@w_psc_dist_condx_test,
                 @p_psc_dist_condx_code		=	@w_psc_dist_condx_code, 
                 @p_psc_run_now				=	@w_psc_run_now, 
                 @p_psc_last_run_now		=	@w_psc_last_run_now, 
                 @p_psc_abort_flag			=	@w_psc_abort_flag, 
                 @p_psc_del_on_end			=	@w_psc_del_on_end,
                 @p_psc_public				=	@w_psc_public,
                 @p_psc_read_only			=	@w_psc_read_only,
                 @p_psc_event_name			=	@w_psc_event_name, 
                 @p_psc_first_run_date		=	@w_psc_first_run_date, 
                 @p_old_chgstamp			=	@w_old_chgstamp
                     

END; -- End of Proc--


 
GO
ALTER AUTHORIZATION ON [dbo].[usp_payslip_event] TO  SCHEMA OWNER 
GO
