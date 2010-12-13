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
    
    match_x:array,optional
    match_rep:array,optional
    match100:array,optional
    match95:array,optional
    match85:array,optional
    match75:array,optional
    match50:array,optional
    match0:array,optional

    { target_language_id:multiple {}}
    { task_name_file "" }
    { task_units_file ""}
    { task_uom_file "" }
    { task_type_file "" }
    { task_name_manual "" }
    { task_units_manual ""}
    { task_uom_manual "" }
    { task_type_manual "" }
    { submit_view ""}
    { submit_submit ""}
    { submit_assign "" }
    { submit_trados "" }
    { submit_add_manual "" }
    { submit_add_file "" }
    { submit_submit "" }
    { action "" }
}

set date_format [parameter::get_from_package_key -package_key intranet-translation -parameter "TaskListEndDateFormat" -default "YYYY-MM-DD"]
set org_project_id $project_id

# Get the list of target languages of the current project.
# We will need this list if a new task is added, because we
# will have to add the task for each of the target languages...
set target_language_ids $target_language_id
if {"" == $target_language_id} {
    set target_language_ids [im_target_language_ids $project_id]
}

if {0 == [llength $target_language_ids]} {
    # No target languages defined -
    # This could be a non-language project, so don't throw
    # an error but gracefully add an empty empty target language
    # so that the task is added (=> foreach $target_language_ids...)
    set target_language_ids [list ""]
}

# Check if translation module has been installed
set trans_quality_exists_p [im_table_exists "im_trans_quality_reports"]

# Is the dynamic WorkFlow module installed?
set wf_installed_p [im_workflow_installed_p]


# Compatibility with code before L10n.
# ToDo: Remove this and replace by cleaner code
if {"" != $submit_view} { set action "View Tasks" }
if {"" != $submit_assign} { set action "Assign Tasks" }
if {"" != $submit_trados} { set action "Trados Import" }
if {"" != $submit_add_manual} { set action "Add" }
if {"" != $submit_add_file} { set action "Add File" }

set user_id [ad_maybe_redirect_for_registration]

switch -glob $action {

    "" {
	ad_return_complaint 1 empty
	# Currently only "Upload" has an empty "submit" string,
	# because the button needs to caryy the task_id.

	set task_list [array names upload_file]
	set task_id [lindex $task_list 0]
	if {$task_id != ""} {
	    ad_returnredirect $return_url
	}

	set error "[_ intranet-translation.lt_Unknown_submit_comman]: '$action'"
	ad_returnredirect "/error?error=$error"
    }

    "Trados Import" {
	ad_return_complaint 1 trados_import
	ad_returnredirect "task-trados?[export_url_vars project_id return_url]"
    }

    "Assign" {
	ad_return_complaint 1 assign
	ad_returnredirect "task-assignments?[export_url_vars project_id return_url]"
    }

    "Assign Tasks" {
	ad_return_complaint 1 assign-tasks
	ad_returnredirect "task-assignments?[export_url_vars project_id return_url]"
    }

    "View Tasks" {
	ad_return_complaint 1 view_tasks
	ad_returnredirect "task-list?[export_url_vars project_id return_url]"
    }

    "save" {
	# Save the changes in billable_units and task_status
	#
	set task_list [array names task_status]

#	ad_return_complaint 1 "$task_list - [array get match_x]"


	foreach task_id $task_list {

	    # Use default values if no InterCo values are available:
	    if {![info exists billable_units_interco($task_id)]} { 
		set billable_units_interco($task_id) $billable_units($task_id) 
	    }

	    regsub {\,} $task_status($task_id) {.} task_status($task_id)
	    regsub {\,} $task_type($task_id) {.} task_type($task_id)
	    regsub {\,} $billable_units($task_id) {.} billable_units($task_id)
	    regsub {\,} $billable_units_interco($task_id) {.} billable_units_interco($task_id)

	    # Static Workflow - just save the values
	    # The values for status and type are irrelevant
	    # for the dynamic WF, but they are there for
	    # compatibility reasons.

            # Fixed error from SAP 080503: Deal with empty billable units
            set billable_value $billable_units($task_id)
            if {"" == $billable_value} { set billable_value 0 }

            set billable_value_interco $billable_units_interco($task_id)
            if {"" == $billable_value_interco} { set billable_value_interco 0 }

	    set trados_reuse_update ""
	    if {[info exists match_x($task_id)]} {
		
		set p_match_x $match_x($task_id)
		set p_match_rep $match_rep($task_id)
		set p_match100 $match100($task_id)
		set p_match95 $match95($task_id)
		set p_match85 $match85($task_id)
		set p_match75 $match75($task_id)
		set p_match50 $match50($task_id)
		set p_match0 $match0($task_id)
		set task_units [im_trans_trados_matrix_calculate [im_company_freelance] $p_match_x $p_match_rep $p_match100 $p_match95 $p_match85 $p_match75 $p_match50 $p_match0]

		set trados_reuse_update ",
			match_x = :p_match_x,
			match_rep = :p_match_rep,
			match100 = :p_match100,
			match95 = :p_match95,
			match85 = :p_match85,
			match75 = :p_match75,
			match50 = :p_match50,
			match0 = :p_match0,
			task_units = :task_units
		"

	    }

	    set sql "
                    update im_trans_tasks set
                	task_status_id= '$task_status($task_id)',
                	task_type_id= '$task_type($task_id)',
			billable_units = :billable_value,
			billable_units_interco = :billable_value_interco
			$trados_reuse_update
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

		set task_end_date $end_date($task_id)

		# Disabled check for end_date in order to allow adding time
		if {[regexp {^[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]$} $end_date($task_id)]} {
		}

		# Store deadline in with the task
		set update_sql "
			update im_trans_tasks set 
				end_date = :task_end_date::timestamptz
			where	project_id = :project_id
				and task_id = :task_id"
		if {[catch {
		    db_dml update_task_deadline $update_sql
		} err_msg]} {
		    ad_return_complaint 1 "<b>[lang::message::lookup "" intranet-translation.Date_conversion_error "Error converting date string into a database date."]</b><br>&nbsp;<br>
                    [lang::message::lookup "" intranet-translation.Here_is_the_error "Here is the error. You may copy this text and send it to your system administrator for reference."]<br><pre>$err_msg</pre>
                    "

		    # Does this smell fishy?
		    if {[string length $task_end_date] > 40} {
			im_security_alert \
			    -location "intranet-translation/www/trans-tasks/task-action: Save" \
			    -message "Date string too long?" \
			    -value $task_end_date \
			    -severity "Normal"
		    }

		    ad_script_abort
		}
		
	    }
	    
	    # Successfully updated translation task
	    # Call user_exit to let TM know about the event
	    im_user_exit_call trans_task_update $task_id
	    im_audit -object_type "im_trans_task" -object_id $task_id -action "after_update" -status_id $task_status($task_id) -type_id $task_type($task_id)
	}
    }

    "delete" {
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
		im_audit -object_type "im_trans_task" -object_id $task_id -action after_delete

	    }
       }
    }

    "batch" {
	# "Batch Files" button pressed: Group the files into a single batch .zip file
	#
	
	#checking of the batch
	if {[llength $delete_task] <= 1} {
	    ad_return_complaint 1 "<p>[lang::message::lookup "" intranet-translation.Less_then_two_files_selected "Less then two files selected"]</b>:<br>
		[lang::message::lookup "" intranet-translation.No_need_for_batching_msg "
			There is no need for batching for less then two file.
		"]
	    "
	    ad_script_abort
	}

#	im_translation_batching_check_tasks $delete_task

	# Base path to files in the filestorage
	db_1row projects_info "
		select project_name, project_nr, im_category_from_id(source_language_id) as project_source_language 
		from im_projects where project_id = :project_id
	"
	set server_path [im_filestorage_project_path_helper $project_id]
	set locale "en_US"
	set source_dir [lang::message::lookup $locale intranet-translation.Workflow_source_directory "source"]
	append server_path "/" $source_dir "_" $project_source_language

	# Initialize fiels for summing up tasks
	set task_description ""
	set summed_task_units 0
	set summed_billable_units 0
	set summed_match_x 0
	set summed_match_rep 0
	set summed_match100 0
	set summed_match95 0
	set summed_match85 0
	set summed_match75 0
	set summed_match50 0
	set summed_match0 0
	set summed_billable_units_interco 0

	set comp_source_language_id ""
	set comp_target_language_id ""
	set comp_task_type_id ""
	set comp_task_status_id ""
	set comp_task_uom_id ""
	set comp_trans_id ""
	set comp_edit_id ""
	set comp_proof_id ""
	set comp_other_id ""
	set comp_end_date ""
 
	set sql_query "
		select	task_filename, task_units, billable_units as bill_units, match_x, match_rep, 
			match100, match95, match85, match75, match50, match0, billable_units_interco, 
			task_type_id, task_status_id, source_language_id, target_language_id, task_uom_id,
			trans_id, edit_id, proof_id, other_id, project_id
		from	im_trans_tasks
		where	task_id in ([join $delete_task ", "])
	"
  
	db_foreach task_duplicate $sql_query { 
	    set full_task_filename ""
	    append full_task_filename $server_path "/" $task_filename
	    lappend task_filenames $full_task_filename 
	    set summed_task_units [expr $task_units+0 + $summed_task_units] 
	    set summed_billable_units [expr $bill_units+0 + $summed_billable_units] 
	    set summed_match_x [expr $match_x+0 + $summed_match_x] 
	    set summed_match_rep [expr $match_rep+0 + $summed_match_rep] 
	    set summed_match100 [expr $match100+0 + $summed_match100] 
	    set summed_match95 [expr $match95+0 + $summed_match95] 
	    set summed_match85 [expr $match85+0 + $summed_match85] 
	    set summed_match75 [expr $match75+0 + $summed_match75] 
	    set summed_match50 [expr $match50+0 + $summed_match50] 
	    set summed_match0 [expr $match0+0 + $summed_match0] 
	    set summed_billable_units_interco [expr $billable_units_interco+0 + $summed_billable_units_interco]      

	    # Check the parameters of the task.
	    # We can not batch together tasks of different languages or types.
	    set err ""
	    if {"" != $comp_source_language_id && $comp_source_language_id != $source_language_id} { set err "Source language" }
	    if {"" != $comp_target_language_id && $comp_target_language_id != $target_language_id} { set err "Target language" }
	    if {"" != $comp_task_type_id && $comp_task_type_id != $task_type_id} { set err "Task type" }
	    if {"" != $comp_task_uom_id && $comp_task_uom_id != $task_uom_id} { set err "Task UoM" }
	    if {"" != $trans_id || "" != $edit_id || "" != $proof_id || "" != $other_id} { set err "Already Assigned" }
#	    if {"" != $comp_ && $comp_ != $} { set err "" }
	    if {"" != $err} {
		ad_return_complaint 1 "[lang::message::lookup "" intranet-translation.Invalid_Batching "Invalid Batching"]: $err"
		ad_script_abort
	    }
	    set comp_source_language_id $source_language_id
	    set comp_target_language_id $target_language_id
	    set comp_task_type_id $task_type_id
	    set comp_task_uom_id $task_uom_id
	}

	# Check that all files are present before we actually start zipping
	foreach file $task_filenames {
	     if {![file readable $file]} {
		ad_return_complaint 1 "[lang::message::lookup "" intranet-translation.Batch_file_not_found "Didn't find batch file '%file%'"]"
		ad_script_abort
	     }
	}

	# Building the batch file name
	set batch_filename "${project_nr}_batch_"
  
	set last_filename ""
	append batch_filename_query $batch_filename "%"
	set sql_query "
		select	task_name as last_filename 
		from	im_trans_tasks 
		where	task_name like :batch_filename_query
		order by length(task_name) desc, task_name desc
		limit 1
	"
	db_0or1row projects_info_query $sql_query 
    
	if {$last_filename == ""} {
	    append batch_filename "0"
	} else {
	    # fish out the last order number
	    set last_underscore [expr [string last "_" $last_filename] + 1]
	    set last_point_zip [expr [string last "." $last_filename] - 1]
	    set order_nr [string range $last_filename $last_underscore $last_point_zip]
	    set order_nr [expr $order_nr + 1]
	    append batch_filename $order_nr    
	}
	append batch_filename ".zip"    

	# Create a new translation task for the batch file
	set ip_address [ad_conn peeraddr]
	
	set new_task_id [im_exec_dml new_task "im_trans_task__new (
		null,				-- task_id
		'im_trans_task',		-- object_type
		now(),				-- creation_date
		:user_id,			-- creation_user
		:ip_address,			-- creation_ip	
		null,				-- context_id	
		:project_id,			-- project_id	
		:task_type_id,			-- task_type_id	
		:task_status_id,		-- task_status_id
		:source_language_id,		-- source_language_id
		:target_language_id,		-- target_language_id
		:task_uom_id			-- task_uom_id 
	)"]
	
	db_dml update_task "
		UPDATE im_trans_tasks SET
			tm_integration_type_id = [im_trans_tm_integration_type_none],
			task_name = :batch_filename,
			task_filename = :batch_filename,
			task_units = :summed_task_units,
			billable_units = :summed_billable_units,
			billable_units_interco = :summed_billable_units_interco,
			match_x = :summed_match_x,
			match_rep = :summed_match_rep,
			match100 = :summed_match100, 
			match95 = :summed_match95,
			match85 = :summed_match85,
			match75 = :summed_match75, 
			match50 = :summed_match50,
			match0 = :summed_match0
		WHERE 
			task_id = :new_task_id
	"  
      
	# Zip all batched files into a single new ZIP
	set full_batch_filename "$server_path/$batch_filename"
	set zip_command "zip -j $full_batch_filename $task_filenames"
	exec /bin/bash -c "$zip_command"
    
	# Delete the original tasks
  	foreach task_id $delete_task {
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
		im_audit -object_type "im_trans_task" -object_id $task_id -action "after_delete"
	    }
       }
    }

    "Add File" {
	# Decode the task_name_file
	set task_filename [ns_urldecode $task_name_file]

	im_task_insert $project_id $task_filename $task_filename $task_units_file $task_uom_file $task_type_file $target_language_ids
    }

    "Add" {
	# Add the task WITHOUT filename.
	# This means that the task does not require to
	# have a file associated in the filestorage.
	set task_filename ""

	ns_log Notice "task-action: Add manual task: im_task_insert $project_id [ns_urldecode $task_name_manual] $task_filename $task_units_manual $task_uom_manual $task_type_manual $target_language_ids"

	im_task_insert $project_id [ns_urldecode $task_name_manual] $task_filename $task_units_manual $task_uom_manual $task_type_manual $target_language_ids
    }

    default {
	ad_return_complaint 1 "<li>[_ intranet-translation.lt_Unknown_submit_comman]: '$action'"
    }
}


im_trans_task_project_advance $org_project_id

ad_returnredirect $return_url

