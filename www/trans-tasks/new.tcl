# /packages/intranet-translation/www/trans-tasks/new.tcl
#
# Copyright (C) 2003 - 2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    @param form_mode edit or display
    @author frank.bergmann@project-open.com
} {
    task_id:integer,optional
    project_id:integer,optional
    { return_url "" }
    edit_p:optional
    message:optional
    { form_mode "display" }
}


# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set action_url "/intranet-translation/trans-tasks/new"
set focus "task.var_name"
if {[info exists task_id]} { 
    set page_title [lang::message::lookup "" intranet-translation.Edit_Translation_Task "Edit Translation Task"] 
} else {
    set page_title [lang::message::lookup "" intranet-translation.New_Translation_Task "New Translation Task"]
}
set context [im_context_bar $page_title]

set user_id [ad_maybe_redirect_for_registration]
if {![info exists task_id]} { set form_mode "edit" }

# Either the task_id or the project_id must be there
if {![info exists task_id] && ![info exists project_id_id]} {
    ad_return_complaint 1 "Either project_id or task_id need to be provided"
    ad_script_abort
}
if {[info exists task_id]} { set project_id [db_string pid "select project_id from im_trans_tasks where task_id = :task_id" -default ""] }

im_project_permissions $user_id $project_id view read write admin

if {"display" == $form_mode} {
    if {!$read} {
	ad_return_complaint 1 "You have insufficient privileges to see tasks"
	return
    }
} else {
    if {!$write} {
	ad_return_complaint 1 "You have insufficient privileges to add/modify tasks"
	return
    }
}

set button_pressed [template::form get_action task]
if {"delete" == $button_pressed} {
    if {[catch {
	db_transaction {
	    db_dml del_prices "delete from im_timesheet_prices where task_id=:task_id"
	    db_exec_plsql task_delete {}
	}
    } err_msg]} {
	set task_names [db_list mat_tasks "select acs_object__name(task_id) from im_timesheet_tasks where task_id = :task_id"]
	set price_names [db_list_of_lists prices "select acs_object__name(company_id), im_category_from_id(task_type_id), * from im_timesheet_prices where task_id = :task_id"]
	ad_return_complaint 1 "<b>Error deleting Task</b>:<p>
	This error is probably due to the fact there there are still 
	'Timesheet Tasks' referencing this task:<p>
	Timesheet Tasks:<br>
	<pre>[join $task_names "\n>"]</pre><p>
	Timesheet Prices:<br>
	<pre>[join $price_names "\n>"]</pre><p>
	Please change these items to remove the task you want to delete\n"
	return
    }
    ad_returnredirect $return_url
}


# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

set type_options [im_trans_task_type_options]
set status_options [db_list_of_lists status "select category, category_id from im_categories where category_type = 'Intranet Translation Task Status'"]
set uom_options [im_cost_uom_options 0]
set language_options [db_list_of_lists status "select category, category_id from im_categories where category_type = 'Intranet Translation Language'"]
set assignee_options [im_user_options]
set tm_integration_type_options [db_list_of_lists status "select category, category_id from im_categories where category_type = 'Intranet TM Integration Type'"]

set actions [list {"Editt" editt} ]
set actions [list]

if {[im_permission $user_id add_tasks]} {
    lappend actions {"Delete" delete}
}

ad_form \
    -name task \
    -cancel_url $return_url \
    -action $action_url \
    -actions $actions \
    -mode $form_mode \
    -has_edit 1 \
    -export {return_url} \
    -form {
	task_id:key
	{project_id:text(hidden)}
	{invoice_id:text(hidden)}
	{quote_id:text(hidden)}
	{task_name:text(text) {label "[lang::message::lookup {} intranet-translation.Name Name]"} {html {size 50}}}
	{task_filename:text(text) {label "[lang::message::lookup {} intranet-translation.Filename Filename]"} {html {size 50}}}
	{task_type_id:text(select) {label "[lang::message::lookup {} intranet-translation.Type Type]"} {options $type_options} }
	{task_status_id:text(select) {label "[lang::message::lookup {} intranet-translation.Status Status]"} {options $status_options} }
	{source_language_id:text(select) {label "[lang::message::lookup {} intranet-translation.Source_Language {Source Language}]"} {options $language_options} }
	{target_language_id:text(select) {label "[lang::message::lookup {} intranet-translation.Target_Language {Target Language}]"} {options $language_options} }

	{end_date:date(date),optional {label "[_ intranet-timesheet2.End_Date]"} {format "DD MM YYYY"}}

	{task_units:float(text) {label "[lang::message::lookup {} intranet-translation.Units Units]"} {html {size 10}} }
	{billable_units:float(text) {label "[lang::message::lookup {} intranet-translation.Billable_Units {Billable Units}]"} {html {size 10}} }
	{billable_units_interco:float(text) {label "[lang::message::lookup {} intranet-translation.Billable_Units_Interco {Billable Units Interco}]"} {html {size 10}} }
	{task_uom_id:text(select) {label "UoM<br>(Unit of Measure)"} {options $uom_options} }

	{match_x:float(text) {label "[lang::message::lookup {} intranet-translation.X_Translated {X-Translated}]"} {html {size 10}} }
	{match_rep:float(text) {label "[lang::message::lookup {} intranet-translation.Repetitions {Repetitions}]"} {html {size 10}} }
	{match_100:float(text) {label "[lang::message::lookup {} intranet-translation.Match_100 {100% Matches}]"} {html {size 10}} }
	{match_95:float(text) {label "[lang::message::lookup {} intranet-translation.Match_95 {95% Matches}]"} {html {size 10}} }
	{match_85:float(text) {label "[lang::message::lookup {} intranet-translation.Match_85 {85% Matches}]"} {html {size 10}} }
	{match_75:float(text) {label "[lang::message::lookup {} intranet-translation.Match_75 {75% Matches}]"} {html {size 10}} }
	{match_50:float(text) {label "[lang::message::lookup {} intranet-translation.Match_50 {50% Matches}]"} {html {size 10}} }
	{match_0:float(text) {label "[lang::message::lookup {} intranet-translation.Match_0 { 0% matches}]"} {html {size 10}} }

	{trans_id:text(select) {label "[lang::message::lookup {} intranet-translation.Assignee_Trans {Assignee: Trans}]"} {options $assignee_options} }
	{edit_id:text(select) {label "[lang::message::lookup {} intranet-translation.Assignee_Edit {Assignee: Edit}]"} {options $assignee_options} }
	{proof_id:text(select) {label "[lang::message::lookup {} intranet-translation.Assignee_Proof {Assignee: Proof}]"} {options $assignee_options} }
	{other_id:text(select) {label "[lang::message::lookup {} intranet-translation.Assignee_Other {Assignee: Other}]"} {options $assignee_options} }

	{tm_integration_type_id:text(select) {label "[lang::message::lookup {} intranet-translation.TM_Integration_Type {TM Integration Type}]"} {options $tm_integration_type_options} }

	{description:text(textarea),optional {label Description} {html {cols 40}}}
    }


ad_form -extend -name task -on_request {
    # Populate elements from local variables

} -select_query {

	select	t.*
	from	im_trans_tasks t
	where	t.task_id = :task_id

} -new_data {

    db_exec_plsql task_insert {}
    db_dml task_update {}

} -edit_data {

    db_dml task_update {}

} -on_submit {

	ns_log Notice "new: on_submit"

} -after_submit {

	ad_returnredirect $return_url
	ad_script_abort
}



# ---------------------------------------------------------------
# Project Menu
# ---------------------------------------------------------------

# Setup the subnavbar
set bind_vars [ns_set create]
ns_set put $bind_vars project_id $project_id
set project_menu_id [db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]
set sub_navbar [im_sub_navbar \
    -components \
    -base_url "/intranet/projects/view?project_id=$project_id" \
    $project_menu_id \
    $bind_vars "" "pagedesriptionbar" "project_timesheet_task"] 


