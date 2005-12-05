# /packages/intranet-translation/www/trans-tasks/task-save.tcl
#
# Copyright (C) 2003-2004 Project/Open
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
    task_status:array,optional
    task_type:array,optional
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
    { submit_assign "" }
    { submit_trados "" }
    { submit_add_manual "" }
    { submit_add_file "" }
}

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

if {"" != $submit_view} { set submit "View Tasks" }
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
	    append page_body "task_status($task_id)=$task_status($task_id)\n"
	    append page_body "task_type($task_id)=$task_type($task_id)\n"
	    append page_body "b._units($task_id)=$billable_units($task_id)\n"
	    set sql "
                update im_trans_tasks set
                	task_status_id= '$task_status($task_id)',
                	task_type_id= '$task_type($task_id)'
                where project_id=:project_id
                and task_id=:task_id"
	    db_dml update_task_status $sql

	    set sql "
                update im_trans_tasks
                set billable_units = '$billable_units($task_id)'
                where project_id=:project_id
                and task_id=:task_id"
	    db_dml update_billable_units $sql
	}
	
	ad_returnredirect $return_url
	return
    }

    "Del" {
	# "Del" button pressed: delete the marked tasks
	#
	foreach task_id $delete_task {
	    ns_log Notice "delete task: $task_id"
	    ns_log Notice "delete from im_trans_tasks where task_id = $task_id and project_id=$project_id"

	    set delete_task_actions_sql "
		delete	from im_task_actions
		where	task_id=:task_id"

	    set delete_tasks_sql "
		delete	from im_trans_tasks
		where	task_id = :task_id
			and project_id=:project_id"

	    if { [catch {

		db_dml delete_task_actions $delete_task_actions_sql
		db_dml delete_tasks $delete_tasks_sql

	    } err_msg] } {
		ad_return_complaint 1 "<b>[_ intranet-translation.Database_Error]</b><br>
                [lang::message::lookup "" intranet-translation.Dependent_objects_exist "We have found 'dependent objects' for the translation task '%task_id%'. Such dependant objects may include quality reports etc. Please remove these dependant objects first."]
                <br>&nbsp;<br>
                [lang::message::lookup "" intranet-translation.Here_is_the_error "Here is the error. You may copy this text and send it to your system administrator for reference."]
                <br><pre>$err_msg</pre>"
	    }

       }
       ad_returnredirect $return_url
       return
    }


    "Add File" {
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

