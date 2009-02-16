# /packages/intranet-translation/www/trans-tasks/task-assignments-wf-2.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
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
    deadline:array
}

set user_id [ad_maybe_redirect_for_registration]

set ass [list]
foreach assig [array names assignment] {
    
    if {[regexp {([a-z0-9_]*)\-([a-z0-9_]*)} $assig match transition_key trans_task_id]} {
	ns_log Notice "task-assignments-wf-2: transition_key=$transition_key, trans_task_id=$trans_task_id"

    	db_1row case_info "
		select	case_id,
			workflow_key
		from	wf_cases 
		where	object_id = :trans_task_id
	"

	set asignee_id [string trim $assignment($assig)]
	set deadl $deadline($assig)
	ns_log Notice "task-assignments-wf-2: $transition_key, $trans_task_id -> $asignee_id ($deadl)"
	
	# Delete the case assignment
	db_dml unassign_case "
		delete from wf_case_assignments
		where
			case_id = :case_id
			and role_key = :transition_key
	"	    

	set tasks_sql "
		select  task_id
		from    wf_tasks
		where   case_id = :case_id
			and transition_key = :transition_key
	"

	# Delete the task assignment
	db_dml unassign_tasks "
		delete from wf_task_assignments
		where task_id in ($tasks_sql)
	"

	if {"" != $asignee_id} {

	    # Assign the dude to the Transition
	    db_dml assign_case "
		insert into wf_case_assignments (
			case_id, workflow_key,
			role_key, party_id
		) values (
			:case_id, :workflow_key,
			:transition_key, :asignee_id
		)
	    "

	    # Assign the dude to the given task (task_id = f(case_id, transition_key)).
	    # There should be exactly one task for each case/transition, but
	    # we do a foreach just in case...
	    db_foreach task_to_be_assigned $tasks_sql {
		db_dml assign_task "
			insert into wf_task_assignments (
				task_id, party_id
			) values (
				:task_id, :asignee_id
			)
		"
	    }
	}

	# Set the deadline
	wf_case_set_case_deadline \
		-case_id $case_id \
		-transition_key $transition_key \
		-deadline $deadl

    }
}


db_release_unused_handles
ad_returnredirect $return_url

