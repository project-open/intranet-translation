# /packages/intranet-translation/www/trans-tasks/task-action-list.tcl
#
# Copyright (c) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

if {![info exists project_id]} {
    ad_page_contract {
	Show the list of all activities around trans tasks

	@author frank.bergmann@project-open.com
    } {
	{ project_id 0 }
	{ return_url "" }
    }
}

# ---------------------------------------------------------------------
# Permissions & Defaults
# ---------------------------------------------------------------------

if {![info exists project_id] || 0 == $project_id} { ad_return_complaint 1 "Trans Task Action Log: No project_id specified" }
if {![info exists return_url]} { ad_return_complaint 1 "Trans Task Action Log: No return_url specified" }

set task_action_ctr 0

set user_id [ad_maybe_redirect_for_registration]
im_project_permissions $user_id $project_id view read write admin
if {!$write} { return "" }

set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"

set project_url "/intranet/projects/view"
set user_url "/intranet/users/view"

set colspan 3

# ----------------------------------------------------
# "Multirow" to show a list of actions
# ----------------------------------------------------

list::create \
    -name task_actions \
    -multirow task_actions \
    -key task_action \
    -row_pretty_plural "Object Types" \
    -checkbox_name checkbox \
    -selected_format "normal" \
    -class "list" \
    -main_class "list" \
    -sub_class "narrow" \
    -actions {
    } -bulk_actions {
    } -elements {
	action_date {
	    label "Date"
	}
	action_type {
	    label "Action"
	}
	user_name {
	    label "User"
	    link_url_eval $user_url
	}
        task_name {
            display_col task_name_ext
            label "Task"
            link_url_eval $task_url
        }
	old_status {
	    label "From<br>Status"
	}
	new_status {
	    label "To<br>Status"
	}
	task_end_date {
	    label "Deadline"
	}
    }


multirow create task_actions task_action_type task_action task_action_formatted
set task_actions_sql "
	select	im_category_from_id(action_type_id) as action_type,
		to_char(action_date, 'YYYY-MM-DD HH24:MI') as action_date,
		ta.user_id,
		im_name_from_user_id(ta.user_id) as user_name,
		im_category_from_id(old_status_id) as old_status,
		im_category_from_id(new_status_id) as new_status,
		tt.task_name,
		im_category_from_id(tt.task_type_id) as task_type,
		to_char(tt.end_date, 'YYYY-MM-DD HH24:MI') as task_end_date,
		im_category_from_id(tt.source_language_id) as source_lang,
		im_category_from_id(tt.target_language_id) as target_lang
	from
		im_task_actions ta,
		im_trans_tasks tt
	where
		ta.task_id = tt.task_id
		and tt.project_id = :project_id
	order by
		action_date DESC
"

db_multirow -extend { task_url user_url task_name_ext } task_actions task_actions_query $task_actions_sql { 
    set task_url ""
    set user_url "/intranet/users/view?user_id=$user_id"
    set task_name_ext "$task_name ($source_lang -> $target_lang)"
    
    incr task_action_ctr
}
