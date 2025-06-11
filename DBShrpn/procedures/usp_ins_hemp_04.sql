USE [DBShrpn]
GO
/****** Object:  StoredProcedure [dbo].[usp_ins_hemp_04]    Script Date: 4/1/2025 4:33:00 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO




CREATE procedure [dbo].[usp_ins_hemp_04]
(       
@p_tax_authority_id             char(10),
@p_tax_authority_2              char(10),
@p_tax_authority_3              char(10),
@p_tax_authority_4              char(10),
@p_tax_authority_5              char(10),
@p_tax_auth_type_code     		char(1),
@p_tax_auth_type_code_2   		char(1),
@p_tax_auth_type_code_3   		char(1),
@p_tax_auth_type_code_4   		char(1),
@p_tax_auth_type_code_5   		char(1),
@p_work_resident_status_code    char(1),
@p_work_resident_status_code_2  char(1),
@p_work_resident_status_code_3  char(1),
@p_work_resident_status_code_4  char(1),
@p_work_resident_status_code_5  char(1),
@w_complete_ind                 char(1) OUTPUT,
@w_sui_state_1_ind              char(1) OUTPUT,
@w_time_pct_1                   int     OUTPUT,
@w_sui_state_2_ind              char(1) OUTPUT,
@w_time_pct_2                   int     OUTPUT,
@w_sui_state_3_ind              char(1) OUTPUT,
@w_time_pct_3                   int     OUTPUT,
@w_sui_state_4_ind              char(1) OUTPUT,
@w_time_pct_4                   int     OUTPUT,
@w_sui_state_5_ind              char(1) OUTPUT,
@w_time_pct_5                   int     OUTPUT
)
as
/* -------------------------------- */
/* DOS.Name    :  hpnpii24.sp       */
/* -------------------------------- */
declare @ret int
--exec @ret = sp_dbs_authenticate if @ret != 0 return 
if (rtrim(@p_tax_authority_id) IS NOT NULL AND rtrim(@p_tax_authority_id)!="")    
    Begin
    if @p_tax_auth_type_code = "2" 
Begin
if (rtrim(@p_tax_authority_2) IS NULL OR rtrim(@p_tax_authority_2)="")   
and (rtrim(@p_tax_authority_3) IS NULL OR rtrim(@p_tax_authority_3)="")   
and (rtrim(@p_tax_authority_4) IS NULL OR rtrim(@p_tax_authority_4)="")   
and (rtrim(@p_tax_authority_5) IS NULL OR rtrim(@p_tax_authority_5)="")   
and @p_work_resident_status_code <> "2"
Begin
Select @w_complete_ind = "Y",
@w_sui_state_1_ind = "Y",
@w_time_pct_1 = 100
        End
else
if @p_tax_auth_type_code_2 <> "2" 
                and @p_tax_auth_type_code_2 <> "4"
and @p_tax_auth_type_code_3 <> "2"
and @p_tax_auth_type_code_3 <> "4"
                and @p_tax_auth_type_code_4 <> "2"
and @p_tax_auth_type_code_4 <> "4"
and @p_tax_auth_type_code_5 <> "2"
and @p_tax_auth_type_code_5 <> "4"
    Begin
Select @w_complete_ind = "Y",
@w_sui_state_1_ind = "Y",
@w_time_pct_1 = 100
End
        End
    else if @p_tax_auth_type_code = "4" 
        Begin
if (rtrim(@p_tax_authority_2) IS NULL OR rtrim(@p_tax_authority_2)="")   
and (rtrim(@p_tax_authority_3) IS NULL OR rtrim(@p_tax_authority_3)="")   
and (rtrim(@p_tax_authority_4) IS NULL OR rtrim(@p_tax_authority_4)="")   
and (rtrim(@p_tax_authority_5) IS NULL OR rtrim(@p_tax_authority_5)="")   
Begin
Select @w_complete_ind = "Y",@w_time_pct_1 = 100, @w_sui_state_1_ind = "Y"
End
else
if @p_tax_auth_type_code_2 <> "2" 
                and @p_tax_auth_type_code_2 <> "4"
and @p_tax_auth_type_code_3 <> "2"
and @p_tax_auth_type_code_3 <> "4"
                and @p_tax_auth_type_code_4 <> "2"
and @p_tax_auth_type_code_4 <> "4"
and @p_tax_auth_type_code_5 <> "2"
and @p_tax_auth_type_code_5 <> "4"
Begin
Select @w_complete_ind = "Y",@w_time_pct_1 = 100
End
        End
    else
        select @w_time_pct_1 = 100
End

if (rtrim(@p_tax_authority_2) IS NOT NULL AND rtrim(@p_tax_authority_2)!="")    
begin
if @p_tax_auth_type_code_2 = "2" 
Begin
if (rtrim(@p_tax_authority_id) IS NULL OR rtrim(@p_tax_authority_id)="")   
and (rtrim(@p_tax_authority_3) IS NULL OR rtrim(@p_tax_authority_3)="")   
and (rtrim(@p_tax_authority_4) IS NULL OR rtrim(@p_tax_authority_4)="")   
and (rtrim(@p_tax_authority_5) IS NULL OR rtrim(@p_tax_authority_5)="")   
and @p_work_resident_status_code_2 <> "2"
Begin
Select @w_complete_ind = "Y",
@w_sui_state_2_ind = "Y",
@w_time_pct_2 = 100
End
else
if @p_tax_auth_type_code <> "2" 
and @p_tax_auth_type_code   <> "4"
and @p_tax_auth_type_code_3 <> "2"
and @p_tax_auth_type_code_3 <> "4"
and @p_tax_auth_type_code_4 <> "2"
and @p_tax_auth_type_code_4 <> "4"
and @p_tax_auth_type_code_5 <> "2"
and @p_tax_auth_type_code_5 <> "4"
Begin
Select @w_complete_ind = "Y",
@w_sui_state_2_ind = "Y",
@w_time_pct_2 = 100
End
End
    else if @p_tax_auth_type_code_2 = "4 " 
Begin
if (rtrim(@p_tax_authority_id) IS NULL OR rtrim(@p_tax_authority_id)="")   
and (rtrim(@p_tax_authority_3) IS NULL OR rtrim(@p_tax_authority_3)="")   
and (rtrim(@p_tax_authority_4) IS NULL OR rtrim(@p_tax_authority_4)="")   
and (rtrim(@p_tax_authority_5) IS NULL OR rtrim(@p_tax_authority_5)="")   
Begin
Select @w_complete_ind = "Y",@w_time_pct_2 = 100, @w_sui_state_2_ind = "Y"
End
else
if @p_tax_auth_type_code <> "2" 
and @p_tax_auth_type_code   <> "4"
and @p_tax_auth_type_code_3 <> "2"
and @p_tax_auth_type_code_3 <> "4"
and @p_tax_auth_type_code_4 <> "2"
and @p_tax_auth_type_code_4 <> "4"
and @p_tax_auth_type_code_5 <> "2"
and @p_tax_auth_type_code_5 <> "4"
Begin
Select @w_complete_ind = "Y",@w_time_pct_2 = 100
End
End
    else
        select @w_time_pct_2 = 100
End

if (rtrim(@p_tax_authority_3) IS NOT NULL AND rtrim(@p_tax_authority_3)!="")    
begin
if @p_tax_auth_type_code_3 = "2" 
Begin
if (rtrim(@p_tax_authority_id) IS NULL OR rtrim(@p_tax_authority_id)="")   
and (rtrim(@p_tax_authority_2) IS NULL OR rtrim(@p_tax_authority_2)="")   
and (rtrim(@p_tax_authority_4) IS NULL OR rtrim(@p_tax_authority_4)="")   
and (rtrim(@p_tax_authority_5) IS NULL OR rtrim(@p_tax_authority_5)="")   
and @p_work_resident_status_code_3 <> "2"
Begin
Select @w_complete_ind = "Y",
@w_sui_state_3_ind = "Y",
@w_time_pct_3 = 100
End
else
if @p_tax_auth_type_code <> "2" 
and @p_tax_auth_type_code   <> "4"
and @p_tax_auth_type_code_2 <> "2"
and @p_tax_auth_type_code_2 <> "4"
and @p_tax_auth_type_code_4 <> "2"
and @p_tax_auth_type_code_4 <> "4"
and @p_tax_auth_type_code_5 <> "2"
and @p_tax_auth_type_code_5 <> "4"
Begin
Select @w_complete_ind = "Y",
@w_sui_state_3_ind = "Y",
@w_time_pct_3 = 100
End
End
    else if @p_tax_auth_type_code_3 = "4" 
Begin
if (rtrim(@p_tax_authority_id) IS NULL OR rtrim(@p_tax_authority_id)="")   
and (rtrim(@p_tax_authority_2) IS NULL OR rtrim(@p_tax_authority_2)="")   
and (rtrim(@p_tax_authority_4) IS NULL OR rtrim(@p_tax_authority_4)="")   
and (rtrim(@p_tax_authority_5) IS NULL OR rtrim(@p_tax_authority_5)="")   
Begin
Select @w_complete_ind = "Y",@w_time_pct_3 = 100, @w_sui_state_3_ind = "Y"
End
else
if @p_tax_auth_type_code <> "2" 
and @p_tax_auth_type_code   <> "4"
and @p_tax_auth_type_code_2 <> "2"
and @p_tax_auth_type_code_2 <> "4"
and @p_tax_auth_type_code_4 <> "2"
and @p_tax_auth_type_code_4 <> "4"
and @p_tax_auth_type_code_5 <> "2"
and @p_tax_auth_type_code_5 <> "4"
Begin
Select @w_complete_ind = "Y",@w_time_pct_3 = 100
End
End
    else
        select @w_time_pct_3 = 100
End

if (rtrim(@p_tax_authority_4) IS NOT NULL AND rtrim(@p_tax_authority_4)!="")    
begin
if @p_tax_auth_type_code_4 = "2" 
Begin
if (rtrim(@p_tax_authority_id) IS NULL OR rtrim(@p_tax_authority_id)="")   
and (rtrim(@p_tax_authority_2) IS NULL OR rtrim(@p_tax_authority_2)="")   
and (rtrim(@p_tax_authority_3) IS NULL OR rtrim(@p_tax_authority_3)="")   
and (rtrim(@p_tax_authority_5) IS NULL OR rtrim(@p_tax_authority_5)="")   
and @p_work_resident_status_code_4 <> "2"
Begin
Select @w_complete_ind = "Y",
@w_sui_state_4_ind = "Y",
@w_time_pct_4 = 100
End
else
if @p_tax_auth_type_code <> "2" 
                and @p_tax_auth_type_code   <> "4"
and @p_tax_auth_type_code_2 <> "2"
and @p_tax_auth_type_code_2 <> "4"
and @p_tax_auth_type_code_3 <> "2"
and @p_tax_auth_type_code_3 <> "4"
and @p_tax_auth_type_code_5 <> "2"
and @p_tax_auth_type_code_5 <> "4"
Begin
Select @w_complete_ind = "Y",
@w_sui_state_4_ind = "Y",
@w_time_pct_4 = 100
End
End
    else if @p_tax_auth_type_code_4 = "4" 
Begin
if (rtrim(@p_tax_authority_id) IS NULL OR rtrim(@p_tax_authority_id)="")   
and (rtrim(@p_tax_authority_2) IS NULL OR rtrim(@p_tax_authority_2)="")   
and (rtrim(@p_tax_authority_3) IS NULL OR rtrim(@p_tax_authority_3)="")   
and (rtrim(@p_tax_authority_5) IS NULL OR rtrim(@p_tax_authority_5)="")   
Begin
Select @w_complete_ind = "Y",@w_time_pct_4 = 100, @w_sui_state_4_ind = "Y"
End
else
if @p_tax_auth_type_code <> "2" 
                and @p_tax_auth_type_code   <> "4"
and @p_tax_auth_type_code_2 <> "2"
and @p_tax_auth_type_code_2 <> "4"
and @p_tax_auth_type_code_3 <> "2"
and @p_tax_auth_type_code_3 <> "4"
and @p_tax_auth_type_code_5 <> "2"
and @p_tax_auth_type_code_5 <> "4"
Begin
Select @w_complete_ind = "Y",@w_time_pct_4 = 100
End
End
    else
        select @w_time_pct_4 = 100
End

if (rtrim(@p_tax_authority_5) IS NOT NULL AND rtrim(@p_tax_authority_5)!="")    
begin
if @p_tax_auth_type_code_5 = "2" 
Begin
if (rtrim(@p_tax_authority_id) IS NULL OR rtrim(@p_tax_authority_id)="")   
and (rtrim(@p_tax_authority_2) IS NULL OR rtrim(@p_tax_authority_2)="")   
and (rtrim(@p_tax_authority_3) IS NULL OR rtrim(@p_tax_authority_3)="")   
and (rtrim(@p_tax_authority_4) IS NULL OR rtrim(@p_tax_authority_4)="")   
and @p_work_resident_status_code_5 <> "2"
Begin
Select @w_complete_ind = "Y",
@w_sui_state_5_ind = "Y",
@w_time_pct_5 = 100
End
else
if @p_tax_auth_type_code <> "2" 
and @p_tax_auth_type_code   <> "4"
and @p_tax_auth_type_code_2 <> "2"
and @p_tax_auth_type_code_2 <> "4"
and @p_tax_auth_type_code_3 <> "2"
and @p_tax_auth_type_code_3 <> "4"
and @p_tax_auth_type_code_4 <> "2"
and @p_tax_auth_type_code_4 <> "4"
Begin
Select @w_complete_ind = "Y",
@w_sui_state_5_ind = "Y",
@w_time_pct_5 = 100
End
End
    else if @p_tax_auth_type_code_5 = "4" 
Begin
if (rtrim(@p_tax_authority_id) IS NULL OR rtrim(@p_tax_authority_id)="")   
and (rtrim(@p_tax_authority_2) IS NULL OR rtrim(@p_tax_authority_2)="")   
and (rtrim(@p_tax_authority_3) IS NULL OR rtrim(@p_tax_authority_3)="")   
and (rtrim(@p_tax_authority_4) IS NULL OR rtrim(@p_tax_authority_4)="")   
and @p_work_resident_status_code <> "2"
Begin
Select @w_complete_ind = "Y",@w_time_pct_5 = 100, @w_sui_state_5_ind = "Y"
End
else
if @p_tax_auth_type_code <> "2" 
and @p_tax_auth_type_code   <> "4"
and @p_tax_auth_type_code_2 <> "2"
and @p_tax_auth_type_code_2 <> "4"
and @p_tax_auth_type_code_3 <> "2"
and @p_tax_auth_type_code_3 <> "4"
and @p_tax_auth_type_code_4 <> "2"
and @p_tax_auth_type_code_4 <> "4"
Begin
Select @w_complete_ind = "Y",@w_time_pct_5 = 100
End
End
    else
        select @w_time_pct_5 = 100
End
 

 
GO
ALTER AUTHORIZATION ON [dbo].[usp_ins_hemp_04] TO  SCHEMA OWNER 
GO
