# /www/intranet/projects/task-save.tcl

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
    { task_name_file "" }
    { task_units_file ""}
    { task_uom_file "" }
    { task_type_file "" }
    { task_name_manual "" }
    { task_units_manual ""}
    { task_uom_manual "" }
    { task_type_manual "" }
    submit
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


ad_proc im_task_insert {project_id task_name task_units task_uom task_type target_language_ids} {
    Add a new task into the DB
} {

    # Get some variable of the project:
    set query "
		select p.source_language_id
		from im_projects p
		where p.project_id=:project_id"

    if { ![db_0or1row projects_info_query $query] } {
	append page_body "Can't find the project $project_id"
	doc_return  200 text/html [im_return_template]
	return
    }


    # Task just _created_
    set task_status_id 340
    set task_description ""
    set invoice_id ""
    set match100 ""
    set match95 ""
    set match85 ""
    set match0 ""

    set sql "
INSERT INTO im_trans_tasks 
(task_id, task_name, project_id, task_type_id, task_status_id, 
 description, source_language_id, target_language_id, task_units, 
 billable_units, task_uom_id, match100, match95, match85, match0)
VALUES
(im_trans_tasks_seq.nextval, :task_name, :project_id, :task_type, :task_status_id, 
:task_description, :source_language_id, :target_language_id, :task_units, 
 :task_units, :task_uom, :match100, :match95, :match85, :match0)"

    # Add a new task for every project target language
    foreach target_language_id $target_language_ids {

        if { [catch {
	    db_dml insert_tasks $sql
        } err_msg] } {
	    ad_return_complaint "Database Error" "Did you enter the same task name twice?<BR>
            Here is the error:<BR> <P>$err_msg"
        }
    }
}


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

	set error "Unknown submit command: '$submit'"
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
	    regsub {\,} $billable_units($task_id) {.} billable_units($task_id)
	    append page_body "task_status($task_id)=$task_status($task_id)\n"
	    append page_body "b._units($task_id)=$billable_units($task_id)\n"
	    set sql "
                update im_trans_tasks
                set task_status_id= '$task_status($task_id)'
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
	
#	doc_return  200 text/html "[im_return_template]"
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

            db_dml delete_task_actions $delete_task_actions_sql
            db_dml delete_tasks $delete_tasks_sql
       }
       ad_returnredirect $return_url
       return
    }


    "Add File" {
	im_task_insert $project_id [ns_urldecode $task_name_file] $task_units_file $task_uom_file $task_type_file $target_language_ids
	ad_returnredirect $return_url
	return
    }

    "Add" {
	im_task_insert $project_id [ns_urldecode $task_name_manual] $task_units_manual $task_uom_manual $task_type_manual $target_language_ids
	ad_returnredirect $return_url
	return
    }

    default {
	ad_return_complaint 1 "<li>Unknown submit command: '$submit'"
    }
}

