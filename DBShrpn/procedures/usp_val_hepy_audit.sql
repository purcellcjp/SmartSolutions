USE [DBShrpn]
GO
/****** Object:  StoredProcedure [dbo].[usp_val_hepy_audit]    Script Date: 4/1/2025 4:33:00 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO




CREATE procedure [dbo].[usp_val_hepy_audit] (
        @p_activity_action_code char(10),
        @p_user_id char(30),
        @p_action_date char(30),
        @p_b_emp_id char(15),
        @p_b_empl_id char(10),
        @p_b_pay_element_id char(10),
        @p_b_eff_date datetime,
        @p_a_emp_id char(15),
        @p_a_empl_id char(10),
        @p_a_pay_element_id char(10),
        @p_a_eff_date datetime)
as

begin

    declare @w_ret int

 --   execute @w_ret = sp_dbs_authenticate
 --   if @w_ret != 0
 --       return

    /*  See if audit table row already exists  */
    if exists (select *
        from emp_pay_element_aud
        where ACTION_CODE = @p_activity_action_code
            and ACTION_USER = @p_user_id
            and ACTION_DATETIME = @p_action_date
            and (B_emp_id = @p_b_emp_id
            or (B_emp_id IS NULL
            and @p_b_emp_id IS NULL))
            and (B_empl_id = @p_b_empl_id
            or (B_empl_id IS NULL
            and @p_b_empl_id IS NULL))
            and (B_pay_element_id = @p_b_pay_element_id
            or (B_pay_element_id IS NULL
            and @p_b_pay_element_id IS NULL))
            and (B_eff_date = @p_b_eff_date
            or (B_eff_date IS NULL
            and @p_b_eff_date IS NULL))
            and (A_emp_id = @p_a_emp_id
            or (A_emp_id IS NULL
            and @p_a_emp_id IS NULL))
            and (A_empl_id = @p_a_empl_id
            or (A_empl_id IS NULL
            and @p_a_empl_id IS NULL))
            and (A_pay_element_id = @p_a_pay_element_id
            or (A_pay_element_id IS NULL
            and @p_a_pay_element_id IS NULL))
            and (A_eff_date = @p_a_eff_date
            or (A_eff_date IS NULL
            and @p_a_eff_date IS NULL)))
        return 1
    else
        return 2
end
 

 
GO
ALTER AUTHORIZATION ON [dbo].[usp_val_hepy_audit] TO  SCHEMA OWNER 
GO
