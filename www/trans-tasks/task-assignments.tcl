# /packages/intranet-translation/www/trans-tasks/task-assignments.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Assign translators, editors and proof readers to every task

    @param project_id the project_id
    @param orderby the display order
    @param show_all_comments whether to show all comments

    @author Guillermo Belcic
    @author frank.bergmann@project-open.com
} {
    project_id:integer
    { return_url "" }
    { orderby "subproject_name" }
    { auto_assigment "" }
    { auto_assigned_words 0 }
    { trans_auto_id 0 }
    { edit_auto_id 0 }
    { proof_auto_id 0 }
    { other_auto_id 0 }
}


# -------------------------------------------------------------------------
# Security & Default
# -------------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
if {![im_permission $user_id view_trans_proj_detail]} { 
    ad_return_complaint 1 "<li>You don't have sufficient privileges to view this page"
    return
}

set page_title "[_ intranet-translation.Assignments]"
set context_bar [im_context_bar [list /intranet/projects/ "[_ intranet-translation.Projects]"] [list "/intranet/projects/view?project_id=$project_id" "[_ intranet-translation.One_project]"] $page_title]

if {"" == $return_url} { set return_url [im_url_with_query] }

set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"


# -------------------------------------------------------------------------
# Auto assign
# -------------------------------------------------------------------------

set error 0

# Check that there is only a single role being assigned
set assigned_roles 0
if {$trans_auto_id > 0} { incr assigned_roles }
if {$edit_auto_id > 0} { incr assigned_roles }
if {$proof_auto_id > 0} { incr assigned_roles }
if {$other_auto_id > 0} { incr assigned_roles }
if {$assigned_roles > 1} {
    incr error
    append errors "<LI>[_ intranet-translation.lt_Please_choose_only_a_]"
}

if {$auto_assigned_words > 0 && $assigned_roles == 0} {
    incr error
    append errors "<LI>[_ intranet-translation.lt_You_havent_selected_a]"
}

if { $error > 0 } {
    ad_return_complaint "[_ intranet-translation.Input_Error]" "$errors"
}

# ---------------------------------------------------------------------
# Get the list of available resources and their roles
# to format the drop-down select boxes
# ---------------------------------------------------------------------

set resource_sql "
select
	r.object_id_two as user_id,
	im_name_from_user_id (r.object_id_two) as user_name,
	im_category_from_id(m.object_role_id) as role
from
	acs_rels r,
	im_biz_object_members m
where
	r.object_id_one=:project_id
	and r.rel_id = m.rel_id
"


# Add all users into a list
set project_resource_list [list]
db_foreach resource_select $resource_sql {
    lappend project_resource_list [list $user_id $user_name $role]
}

# ---------------------------------------------------------------------
# Select and format the list of tasks
# ---------------------------------------------------------------------

set task_sql "
select
	t.*,
	im_category_from_id(t.task_uom_id) as task_uom,
	im_category_from_id(t.task_type_id) as task_type,
	im_category_from_id(t.task_status_id) as task_status,
	im_category_from_id(t.target_language_id) as target_language,
	im_email_from_user_id (t.trans_id) as trans_email,
	im_name_from_user_id (t.trans_id) as trans_name,
	im_email_from_user_id (t.edit_id) as edit_email,
	im_name_from_user_id (t.edit_id) as edit_name,
	im_email_from_user_id (t.proof_id) as proof_email,
	im_name_from_user_id (t.proof_id) as proof_name,
	im_email_from_user_id (t.other_id) as other_email,
	im_name_from_user_id (t.other_id) as other_name
from
	im_trans_tasks t
where
	t.project_id=:project_id
        and t.task_status_id <> 372
"

set task_colspan 9
set task_html "
<form method=POST action=task-assignments-2>
[export_form_vars project_id return_url]
	<table border=0>
	  <tr>
	    <td colspan=$task_colspan class=rowtitle align=center>
	      [_ intranet-translation.Task_Assignments]
	    </td>
	  </tr>
	  <tr>
	    <td class=rowtitle align=center>[_ intranet-translation.Task_Name]</td>
	    <td class=rowtitle align=center>[_ intranet-translation.Target_Lang]</td>
	    <td class=rowtitle align=center>[_ intranet-translation.Task_Type]</td>
	    <td class=rowtitle align=center>[_ intranet-translation.Size]</td>
	    <td class=rowtitle align=center>[_ intranet-translation.UoM]</td>
	    <td class=rowtitle align=center>[_ intranet-translation.Trans]</td>
	    <td class=rowtitle align=center>[_ intranet-translation.Edit]</td>
	    <td class=rowtitle align=center>[_ intranet-translation.Proof]</td>
	    <td class=rowtitle align=center>[_ intranet-translation.Other]</td>
	  </tr>
"

# We only need to render an Auto-Assign drop-down box for those
# workflow roles with occur in the project.
# So we define a set of counters for each role, that are evaluated
# later in the Auto-Assign-Component.
#
set n_trans 0
set n_edit 0
set n_proof 0
set n_other 0
set ctr 1

set task_list [array names tasks_id]

db_foreach select_tasks $task_sql {
    ns_log Notice "task_id=$task_id, status_id=$task_status_id"

    # Determine if this task is auto-assignable or not,
    # depending on the unit of measure (UoM). We currently
    # only exclude Units and Days.
    #
    # 320 Hour  
    # 321 Day 
    # 322 Unit 
    # 323 Page 
    # 324 S-Word 
    # 325 T-Word 
    # 326 S-Line 
    # 327 T-Line
    #
    if {320 == $task_uom_id || 323 == $task_uom_id || 324 == $task_uom_id || 325 == $task_uom_id || 326 == $task_uom_id || 327 == $task_uom_id } {
	set auto_assignable_task 1
    } else {
	set auto_assignable_task 0
    }

    # Determine the fields necessary for each task type
    set trans 0
    set edit 0
    set proof 0
    set other 0
    switch $task_type_id {
	93 { # Trans Only
	    set trans 1
	    incr n_trans
	}
	87 { # Trans + Edit  
	    set trans 1 
	    set edit 1
	    incr n_trans
	    incr n_edit
	}
	88 { # Edit Only  
	    set edit 1
	    incr n_edit
	}
	89 { # Trans + Edit + Proof  
	    set trans 1 
	    set edit 1 
	    set proof 1
	    incr n_trans
	    incr n_edit
	    incr n_proof
	}
	94 { # Trans + Int. Spotcheck 
	    set trans 1 
	    set edit 1
	    incr n_trans
	    incr n_edit
	}
	95 { # Proof Only
	    set proof 1 
	    incr n_proof
	}
	default { 
	    set other 1
	    incr n_other
	}
    }

    # introduce spaces after "/" (by "/ ") to allow for graceful rendering
    regsub {/} $task_name "/ " task_name

    append task_html "
	<tr $bgcolor([expr $ctr % 2])>
	<input type=hidden name=task_status_id.$task_id value=$task_status_id>
	<td>$task_name</td>
	<td>$target_language</td>
	<td>$task_type</td>
	<td>$task_units</td>
	<td>$task_uom</td>
	<td>\n"

    # here we compare the assigned words, if the task isn't assigned and if
    # the task's words can be assigned to the translator.:

    # Auto-Assign the task/role if the translator_id is NULL (""),
    # and if there are words left to assign
    if {$auto_assignable_task && $trans_id == "" && $trans_auto_id > 0 && $trans && $auto_assigned_words > $task_units} {
	set trans_id $trans_auto_id
	set auto_assigned_words [expr $auto_assigned_words - $task_units]
    }

    if {$auto_assignable_task && $edit_id == "" && $edit_auto_id > 0 && $edit && $auto_assigned_words > $task_units} {
	set edit_id $edit_auto_id
	set auto_assigned_words [expr $auto_assigned_words - $task_units]
    }

    if {$auto_assignable_task && $proof_id == "" && $proof_auto_id > 0 && $proof && $auto_assigned_words > $task_units} {
	set proof_id $proof_auto_id
	set auto_assigned_words [expr $auto_assigned_words - $task_units]
    }

    if {$auto_assignable_task && $other_id == "" && $other_auto_id > 0 && $other && $auto_assigned_words > $task_units} {
	set other_id $other_auto_id
	set auto_assigned_words [expr $auto_assigned_words - $task_units]
    }

    # Render the 4 possible workflow roles to assign
    if {$trans} {
	append task_html [im_task_user_select task_trans.$task_id $project_resource_list $trans_id translator]
    } else {
	append task_html "<input type=hidden name='task_trans.$task_id' value=''>"
    }
    
    append task_html "</td><td>"

    if {$edit} {
	append task_html [im_task_user_select task_edit.$task_id $project_resource_list $edit_id editor]
    } else {
	append task_html "<input type=hidden name='task_edit.$task_id' value=''>"
    }

    append task_html "</td><td>"

    if {$proof} {
	append task_html [im_task_user_select task_proof.$task_id $project_resource_list $proof_id proofer]
    } else {
	append task_html "<input type=hidden name='task_proof.$task_id' value=''>"
    }

    append task_html "</td><td>"

    if {$other} {
	append task_html [im_task_user_select task_other.$task_id $project_resource_list $other_id]
    } else {
	append task_html "<input type=hidden name='task_other.$task_id' value=''>"
    }

    append task_html "</td></tr>"
    
    incr ctr    
}

append task_html "
</table>
<input type=submit value=Submit>
</form>
"


# -------------------------------------------------------------------
# Extract the Headers
# for each of the different workflows that might occur in 
# the list of tasks of one project
# -------------------------------------------------------------------

set wf_header_sql "
	select distinct
	        wfc.workflow_key,
	        wft.transition_key,
		wft.transition_name,
	        wft.sort_order
	from
	        im_trans_tasks t
	        LEFT OUTER JOIN wf_cases wfc ON (t.task_id = wfc.object_id)
	        LEFT OUTER JOIN wf_transitions wft ON (wfc.workflow_key = wft.workflow_key)
	where
	        t.project_id = :project_id
	        and wft.trigger_type != 'automatic'
	order by
	        wfc.workflow_key,
	        wft.sort_order
"

# Determine the header fields for each workflow key
# Data Structures:
#	transitions(workflow_key) => [orderd list of transition_keys]
#	name(transition_key) => transition_name
#
db_foreach wf_header $wf_header_sql {

    ns_log Notice "task-assignments: header: wf=$workflow_key, trans=$transition_key"

    set trans_key "$workflow_key $transition_key"
    set name($trans_key) $transition_name

    set trans_list [list]
    if {[info exists transitions($workflow_key)]} { 
	set trans_list $transitions($workflow_key) 
    }
    lappend trans_list $transition_key
    set transitions($workflow_key) $trans_list
}


# -------------------------------------------------------------------
# Render the assignments table
# -------------------------------------------------------------------

set wf_assignments_sql "
	select distinct
	        t.*,
		wfc.case_id,
	        wfc.workflow_key,
	        wft.transition_key,
	        wft.trigger_type,
	        wft.sort_order,
	        wfca.party_id
	from
	        im_trans_tasks t
	        LEFT OUTER JOIN wf_cases wfc ON (t.task_id = wfc.object_id)
	        LEFT OUTER JOIN wf_transitions wft ON (wfc.workflow_key = wft.workflow_key)
	        LEFT OUTER JOIN wf_case_assignments wfca ON (
	                wfca.case_id = wfc.case_id
			and wfca.role_key = wft.role_key
	        )
	where
	        t.project_id = :project_id
	        and wft.trigger_type != 'automatic'
	order by
	        wfc.workflow_key,
	        wft.sort_order
"

set ass_html "
<form method=POST action=task-assignments-2>
[export_form_vars project_id return_url]
<table border=0>
"

set last_task_id 0
set last_wf_key ""
set ctr 0
db_foreach wf_assignment $wf_assignments_sql {
    incr ctr

    # Write out the assignments after the task_id has changed.
    # This must happen _before_ drawing a new header line in
    # case that the workflow_key has changed as well.
    if {$task_id != $last_task_id} {
	if {0 != $last_task_id} {
	    append ass_html "<tr><td colspan=5>asdf</td></tr>\n"
	}
	set last_task_id $task_id
    }

    # Render a new header line for evey type of Workflow
    if {$last_wf_key != $workflow_key} {
	append ass_html "
	<tr>
	<td class=rowtitle align=center>[_ intranet-translation.Task_Name]</td>
	<td class=rowtitle align=center>[_ intranet-translation.Target_Lang]</td>
	<td class=rowtitle align=center>[_ intranet-translation.Task_Type]</td>
	<td class=rowtitle align=center>[_ intranet-translation.Size]</td>
	<td class=rowtitle align=center>[_ intranet-translation.UoM]</td>\n"

	set transition_list $transitions($workflow_key)
	foreach trans $transition_list {
	    set trans_key "$workflow_key $trans"
	    append ass_html "<td class=rowtitle align=center
		>[lang::message::lookup "" intranet-translation.$trans $name($trans_key)]</td>\n"
	}
	append ass_html "</tr>\n"
	set last_wf_key $workflow_key
    }

    # Process the assignments
    set ass_key "$task_id $transition_key"
    set ass($ass_key) $party_id
    ns_log Notice "task-assignments: '$ass_key' -> '$party_id'"
    # Writing out these values is done at the top of this routines...
}

append ass_html "
<tr $bgcolor([expr $ctr % 2])>
        <td>$task_name $task_id</td>
        <td>$target_language</td>
        <td>$task_type</td>
        <td>$task_units</td>
        <td>$task_uom</td>
"
foreach trans $transition_list {
    set ass_key "$task_id $trans"
    set ass_val $ass($ass_key)
    append ass_html "
	<td>
	[im_task_user_select wf_task.$case_id $project_resource_list $ass_val]
	$party_id
	</td>
    "
}
append ass_html "</tr>\n"


append ass_html "
</table>
<input type=submit value=Submit>
</form>
"


# -------------------------------------------------------------------
# Autoassign HTML Component
# -------------------------------------------------------------------

set autoassignment_html_body ""
set autoassignment_html_header ""

append autoassignment_html_header "<td class=rowtitle>[_ intranet-translation.Num_Words]</td>\n"
append autoassignment_html_body "<td><input type=text size=6 name=auto_assigned_words></td>\n"

if { $n_trans > 0 } {
    append autoassignment_html_header "<td class=rowtitle>[_ intranet-translation.Trans]</td>\n"
    append autoassignment_html_body "<td>[im_task_user_select trans_auto_id $project_resource_list "" translator]</td>\n"
}
if { $n_edit > 0 } {
    append autoassignment_html_header "<td class=rowtitle>[_ intranet-translation.Edit]</td>\n"
    append autoassignment_html_body "<td>[im_task_user_select edit_auto_id $project_resource_list "" editor]</td>\n"
}
if { $n_proof > 0} {
    append autoassignment_html_header "<td class=rowtitle>[_ intranet-translation.Proof]</td>\n"
    append autoassignment_html_body "<td>[im_task_user_select proof_auto_id $project_resource_list "" proof]</td>\n"
}
if { $n_other > 0 } {
    append autoassignment_html_header "<td class=rowtitle>[_ intranet-translation.Other]</td\n>"
    append autoassignment_html_body "<td>[im_task_user_select other_auto_id $project_resource_list ""]</td>\n"
}

set autoassignment_html "
<form action=\"task-assignments\" method=POST>
[export_form_vars project_id return_url orderby]
<table>
<tr>
  <td colspan=5 class=rowtitle align=center>[_ intranet-translation.Auto_Assignment]</td>
</tr>
<tr align=center>
  $autoassignment_html_header
</tr>
<tr>
  $autoassignment_html_body
</tr>
<tr>
  <td align=left colspan=5>
    <input type=submit name='auto_assigment' value='[_ intranet-translation.Auto_Assign]'>
  </td>
</tr>
</table>
</form>
"


# -------------------------------------------------------------------
# Project Subnavbar
# -------------------------------------------------------------------

set bind_vars [ns_set create]
ns_set put $bind_vars project_id $project_id
set parent_menu_id [db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]


