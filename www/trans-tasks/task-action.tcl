# /packages/intranet-translation/www/trans-tasks/task-save.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Purpose: Takes commands from the /intranet/projects/view
    page and saves changes, deletes tasks and scans for Trados
    files.

    @param return_url the url to return to
    @param project_id
} {
    return_url:optional
    project_id:integer
    { delete_task:multiple "" }
    billable_units:array,optional
    billable_units_interco:array,optional
    end_date:array,optional
    task_status:array,optional
    task_type:array,optional
    task_wf_status:array,optional
    { task_name_file "" }
    { task_units_file ""}
    { task_uom_file "" }
    { task_type_file "" }
    { task_name_manual "" }
    { task_units_manual ""}
    { task_uom_manual "" }
    { task_type_manual "" }
    { submit "" }
    { submit_view ""}
    { submit_del ""}
    { submit_save ""}
    { submit_assign "" }
    { submit_trados "" }
    { submit_add_manual "" }
    { submit_add_file "" }
}

set date_format [parameter::get_from_package_key -package_key intranet-translation -parameter "TaskListEndDateFormat" -default "YYYY-MM-DD"]


# Get the list of target languages of the current project.
# We will need this list if a new task is added, because we
# will have to add the task for each of the target languages...
set target_language_ids [im_target_language_ids $project_id]

if {0 == [llength $target_language_ids]} {
    # No target languages defined -
    # This could be a non-language project, so don't throw
    # an error but gracefully add an empty empty target language
    # so that the task is added (=> foreach $target_language_ids...)
    set target_language_ids [list ""]
}

# Check if translation module has been installed
set trans_quality_exists_p [db_table_exists "im_trans_quality_reports"]

# Is the dynamic WorkFlow module installed?
set wf_installed_p [im_workflow_installed_p]


# Compatibility with code before L10n.
# ToDo: Remove this and replace by cleaner code
if {"" != $submit_view} { set submit "View Tasks" }
if {"" != $submit_del} { set submit "Del" }
if {"" != $submit_save} { set submit "Save" }
if {"" != $submit_assign} { set submit "Assign Tasks" }
if {"" != $submit_trados} { set submit "Trados Import" }
if {"" != $submit_add_manual} { set submit "Add" }
if {"" != $submit_add_file} { set submit "Add File" }

set user_id [ad_maybe_redirect_for_registration]
set page_body "<PRE>\n"

switch -glob $submit {

    "" {
	# Currently only "Upload" has an empty "submit" string,
	# because the button needs to caryy the task_id.

	set task_list [array names upload_file]
	set task_id [lindex $task_list 0]
	if {$task_id != ""} {
	    ad_returnredirect $return_url
	}

	set error "[_ intranet-translation.lt_Unknown_submit_comman]: '$submit'"
	ad_returnredirect "/error?error=$error"
    }

    "Trados Import" {
	ad_returnredirect "task-trados?[export_url_vars project_id return_url]"
    }

    "Assign" {
	ad_returnredirect "task-assignments?[export_url_vars project_id return_url]"
    }

    "Assign Tasks" {
	ad_returnredirect "task-assignments?[export_url_vars project_id return_url]"
    }

    "View Tasks" {
	ad_returnredirect "task-list?[export_url_vars project_id return_url]"
    }

    "Save" {
	# Save the changes in billable_units and task_status
	#
	set task_list [array names task_status]
        append page_body "task_list=$task_list\n"

	foreach task_id $task_list {

	    regsub {\,} $task_status($task_id) {.} task_status($task_id)
	    regsub {\,} $task_type($task_id) {.} task_type($task_id)
	    regsub {\,} $billable_units($task_id) {.} billable_units($task_id)
	    regsub {\,} $billable_units_interco($task_id) {.} billable_units_interco($task_id)
	    append page_body "task_status($task_id)=$task_status($task_id)\n"
	    append page_body "task_type($task_id)=$task_type($task_id)\n"
	    append page_body "b._units($task_id)=$billable_units($task_id)\n"
	    append page_body "b._units_interco($task_id)=$billable_units_interco($task_id)\n"

	    # Static Workflow - just save the values
	    # The values for status and type are irrelevant
	    # for the dynamic WF, but they are there for
	    # compatibility reasons.

            # Fixed error from SAP 080503: Deal with empty billable units
            set billable_value $billable_units($task_id)
            if {"" == $billable_value} { set billable_value 0 }

            set billable_value_interco $billable_units_interco($task_id)
            if {"" == $billable_value_interco} { set billable_value_interco 0 }

	    set sql "
                    update im_trans_tasks set
                	task_status_id= '$task_status($task_id)',
                	task_type_id= '$task_type($task_id)',
			billable_units = :billable_value,
			billable_units_interco = :billable_value_interco
                    where project_id=:project_id
                    and task_id=:task_id"
	    db_dml update_task_status $sql

	    # Dynamic Workflow
	    set task_with_workflow_p 0
	    if {$wf_installed_p} {
		set task_with_workflow_p [db_string workflow_p "
			select count(*) 
			from wf_cases wfc 
			where wfc.object_id = :task_id
		"]
	    }
	    ns_log Notice "task-action: wf_installed_p=$wf_installed_p, task_with_workflow_p=$task_with_workflow_p"

	    # There is a WF associated with this task - go and set
	    # the workflow status/token
	    if {$task_with_workflow_p} {
		# - Abort any currently active transitions
		# - Delete tokens for this case (only: free, locked)
		# - Create a new token in the target location with type "free"

		set case_id [db_string wf_key "select case_id from wf_cases where object_id = :task_id" -default 0]
		ns_log Notice "task-action: case_id=$case_id"
		set journal_id ""
		set tasks_sql "
			select task_id as transition_task_id
			from wf_tasks 
			where case_id = :case_id
			      and state in ('started')
		"
		db_foreach tasks $tasks_sql {
		    ns_log Notice "task-action: canceling task $transition_task_id"
		    set journal_id [wf_task_action $transition_task_id cancel]
		}

		db_dml delete_tokens "
			delete from wf_tokens
			where case_id = :case_id
			and state in ('free', 'locked')
		"

		set place_key $task_wf_status($task_id)
		ns_log Notice "task-action: adding a token to place=$place_key"
		im_exec_dml add_token "workflow_case__add_token (:case_id, :place_key, :journal_id)"

	    } 


	    # Check whether there is a end-date...
	    if {[info exists end_date($task_id)]} {
		if {[regexp {^[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]$} $end_date($task_id)]} {

		    # Store deadline in with the task
		    set update_sql "
			update im_trans_tasks set 
				end_date = '$end_date($task_id)'::timestamptz
			where	project_id = :project_id
				and task_id = :task_id"
                    if {[catch {
			db_dml update_task_deadline $update_sql
		    } err_msg]} {
                        ad_return_complaint 1 "<b>[lang::message::lookup "" intranet-translation.Date_conversion_error "Error converting date string into a database date."]</b><br>&nbsp;<br>
                                [lang::message::lookup "" intranet-translation.Here_is_the_error "Here is the error. You may copy this text and send it to your system administrator for reference."]<br><pre>$err_msg</pre>
                        "
                        ad_script_abort
                    }
		    
		    if {[regexp {^[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]$} $end_date($task_id)]} {
		    }

		}
	    }
	    
	    # Successfully updated translation task
	    # Call user_exit to let TM know about the event
	    im_user_exit_call trans_task_update $task_id

	}
	
	ad_returnredirect $return_url
	return
    }

    "Del" {
	# "Del" button pressed: delete the marked tasks
	#
	foreach task_id $delete_task {
	    ns_log Notice "delete task: $task_id"

	    if { [catch {

                if {$trans_quality_exists_p} {
                    db_dml del_q_report_entries "delete from im_trans_quality_entries where report_id in (select report_id from im_trans_quality_reports where task_id = :task_id)"
                    db_dml del_q_reports "delete from im_trans_quality_reports where task_id = :task_id"
                }

		im_exec_dml new_task "im_trans_task__delete(:task_id)"

	    } err_msg] } {
		ad_return_complaint 1 "<b>[_ intranet-translation.Database_Error]</b><br>
		[lang::message::lookup "" intranet-translation.Dependent_objects_exist "We have found 'dependent objects' for the translation task '%task_id%'. Such dependant objects may include quality reports etc. Please remove these dependant objects first."]
		<br>&nbsp;<br>
		[lang::message::lookup "" intranet-translation.Here_is_the_error "Here is the error. You may copy this text and send it to your system administrator for reference."]
		<br><pre>$err_msg</pre>"
	    } else {

		# Successfully deleted translation task
		# Call user_exit to let TM know about the event
		im_user_exit_call trans_task_delete $task_id

	    }

       }
       ad_returnredirect $return_url
       return
    }


    "Add File" {

	# Decode the task_name_file
	set task_filename [ns_urldecode $task_name_file]

	im_task_insert $project_id $task_filename $task_filename $task_units_file $task_uom_file $task_type_file $target_language_ids
	ad_returnredirect $return_url
	return
    }

    "Add" {
	# Add the task WITHOUT filename.
	# This means that the task does not require to
	# have a file associated in the filestorage.
	set task_filename ""

	ns_log Notice "task-action: Add manual task: im_task_insert $project_id [ns_urldecode $task_name_manual] $task_filename $task_units_manual $task_uom_manual $task_type_manual $target_language_ids"

	im_task_insert $project_id [ns_urldecode $task_name_manual] $task_filename $task_units_manual $task_uom_manual $task_type_manual $target_language_ids
	ad_returnredirect $return_url
	return
    }

    default {
	ad_return_complaint 1 "<li>[_ intranet-translation.lt_Unknown_submit_comman]: '$submit'"
    }
}

