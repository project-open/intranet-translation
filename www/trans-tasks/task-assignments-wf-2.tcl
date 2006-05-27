# /packages/intranet-translation/www/trans-tasks/task-assignments-wf-2.tcl
#
# Copyright (C) 2003-2006 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Takes a workflow assignments page and assigns the specified
    users to the wf_case_assignments.

    @param return_url the url to return to
    @param project_id group id

    @param task_id The list of dynamic WF tasks in the project
    @param assignments Array of assignments mapping transition_key-task_id -> user_id
} {
    return_url
    project_id:integer
    task_id:integer,multiple
    assignment:array
}

set user_id [ad_maybe_redirect_for_registration]

set ass [list]
foreach assig [array names assignment] {
    
    if {[regexp {([a-z0-9_]*)\-([a-z0-9_]*)} $assig match transition_key task_id]} {

    	db_1row case_info "
		select	case_id,
			workflow_key
		from	wf_cases 
		where	object_id = :task_id
	"

    set asignee_id [string trim $assignment($assig)]
	ns_log Notice "task-assignments-wf-2: $transition_key, $task_id -> $asignee_id"

	# Delete the assignment
	db_dml unassign "
		delete from wf_case_assignments
		where
			case_id = :case_id
			and role_key = :transition_key
	"	    

	if {"" != $asignee_id} {
	    # Assign the dude
	    db_dml assign "
		insert into wf_case_assignments (
			case_id, workflow_key,
			role_key, party_id
		) values (
			:case_id, :workflow_key,
			:transition_key, :asignee_id
		)
	    "
	}
    }
}


db_release_unused_handles
ad_returnredirect $return_url

