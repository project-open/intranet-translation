# /packages/intranet-translation/www/trans-tasks/task-assignments.tcl
#
# Copyright (C) 2003-2009 ]project-open[
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

set project_nr [db_string project_nr "select project_nr from im_projects where project_id = :project_id" -default ""]
set page_title "$project_nr - [_ intranet-translation.lt_Translation_Assignmen]"
set context_bar [im_context_bar [list /intranet/projects/ "[_ intranet-translation.Projects]"] [list "/intranet/projects/view?project_id=$project_id" "[_ intranet-translation.One_project]"] $page_title]


set auto_assignment_component_p [parameter::get_from_package_key -package_key intranet-translation -parameter "EnableAutoAssignmentComponentP" -default 0]


if {"" == $return_url} { set return_url [im_url_with_query] }

set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"

# Workflow available?
set wf_installed_p [im_workflow_installed_p]

set date_format "YYYY-MM-DD"

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
# Get the list of available groups
# ---------------------------------------------------------------------

set groups_sql "
select
	g.group_id,
	g.group_name,
	0 as role
from
	groups g,
	im_profiles p
where
	g.group_id = p.profile_id
"


# Add all groups into a list
set group_list [list]
db_foreach group_select $groups_sql {
    lappend group_list [list $group_id $group_name $role]
}


# ---------------------------------------------------------------------
# Select and format the list of tasks
# ---------------------------------------------------------------------

set extra_where ""
if {$wf_installed_p} {
    set extra_where "and
	t.task_id not in (
		select	object_id
		from	wf_cases
	)
"
}

set task_sql "
select
	t.*,
	ptype_cat.aux_int1 as aux_task_type_id,
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
	im_trans_tasks t,
	im_categories ptype_cat
where
	t.project_id=:project_id and
	t.task_status_id <> 372 and
	ptype_cat.category_id = t.task_type_id
	$extra_where
order by
        t.task_name,
        t.target_language_id
"

# ToDo: Remove the DynamicWF tasks


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
set ctr 0

set task_list [array names tasks_id]

db_foreach select_tasks $task_sql {
    ns_log Notice "task_id=$task_id, status_id=$task_status_id"

    # Check if the task_type was set in categories
    if {"" != $aux_task_type_id} { set task_type_id $aux_task_type_id }

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
    set wf_list [db_string wf_list "select aux_string1 from im_categories where category_id = :task_type_id"]
    if {"" == $wf_list} { set wf_list "other" }
    foreach wf $wf_list {
	switch $wf {
	    trans { 
		set trans 1 
		incr n_trans
	    }
	    edit { 
		set edit 1 
		incr n_edit
	    }
	    proof { 
		set proof 1 
		incr n_proof
	    }
	    other { 
		set other 1 
		incr n_other
	    }
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
	append task_html [im_task_user_select -source_language_id $source_language_id -target_language_id $target_language_id task_trans.$task_id $project_resource_list $trans_id translator]
    } else {
	append task_html "<input type=hidden name='task_trans.$task_id' value=''>"
    }
    
    append task_html "</td><td>"

    if {$edit} {
	append task_html [im_task_user_select -source_language_id $source_language_id -target_language_id $target_language_id task_edit.$task_id $project_resource_list $edit_id editor]
    } else {
	append task_html "<input type=hidden name='task_edit.$task_id' value=''>"
    }

    append task_html "</td><td>"

    if {$proof} {
	append task_html [im_task_user_select -source_language_id $source_language_id -target_language_id $target_language_id task_proof.$task_id $project_resource_list $proof_id proofer]
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

# Don't show component if there are no tasks
if {$wf_installed_p && !$ctr} { set task_html "" }

# -------------------------------------------------------------------
# Extract the Headers
# for each of the different workflows that might occur in 
# the list of tasks of one project
# -------------------------------------------------------------------

# Determine the header fields for each workflow key
# Data Structures:
#	transitions(workflow_key) => [orderd list of transition-name tuples]
#
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
	        and wft.trigger_type not in ('automatic', 'message')
	order by
	        wfc.workflow_key,
	        wft.sort_order
"
db_foreach wf_header $wf_header_sql {
    set trans_key "$workflow_key $transition_key"
    set trans_list [list]
    if {[info exists transitions($workflow_key)]} { 
	set trans_list $transitions($workflow_key) 
    }
    lappend trans_list [list $transition_key $transition_name]
    ns_log Notice "task-assignments: header: wf=$workflow_key, trans=$transition_key: $trans_list"
    set transitions($workflow_key) $trans_list
}


# -------------------------------------------------------------------
# Build the assignments table
# 
# This query extracts all tasks and all of the task assignments and
# stores them in an two-dimensional matrix (implmented as a hash).
# -------------------------------------------------------------------

set wf_assignments_sql "
	select distinct
	        t.task_id,
		wfc.case_id,
	        wfc.workflow_key,
	        wft.transition_key,
	        wft.trigger_type,
	        wft.sort_order,
	        wfca.party_id,
		wfta.deadline,
		to_char(wfta.deadline, :date_format) as deadline_formatted
	from
	        im_trans_tasks t
	        LEFT OUTER JOIN wf_cases wfc ON (t.task_id = wfc.object_id)
	        LEFT OUTER JOIN wf_transitions wft ON (wfc.workflow_key = wft.workflow_key)
		LEFT OUTER JOIN wf_tasks wfta ON (
			wfta.case_id = wfc.case_id
			and wfc.workflow_key = wfta.workflow_key
			and wfta.transition_key = wfta.transition_key
		)
	        LEFT OUTER JOIN wf_case_assignments wfca ON (
	                wfca.case_id = wfc.case_id
			and wfca.role_key = wft.role_key
	        )
	where
	        t.project_id = :project_id
	        and wft.trigger_type not in ('automatic', 'message')
	order by
	        wfc.workflow_key,
	        wft.sort_order
"

db_foreach wf_assignment $wf_assignments_sql {
    set ass_key "$task_id $transition_key"
    set ass($ass_key) $party_id
    set deadl($ass_key) $deadline_formatted

    ns_log Notice "task-assignments: $workflow_key: '$ass_key' -> '$party_id'"
}


# -------------------------------------------------------------------
# Render the assignments table
# -------------------------------------------------------------------

set wf_assignments_render_sql "
	select
		t.*,
		to_char(t.end_date, :date_format) as end_date_formatted,
		wfc.workflow_key,
		im_category_from_id(t.task_uom_id) as task_uom,
		im_category_from_id(t.task_type_id) as task_type,
		im_category_from_id(t.task_status_id) as task_status,
		im_category_from_id(t.target_language_id) as target_language
	from
		im_trans_tasks t,
		wf_cases wfc
	where
		t.project_id = :project_id
		and t.task_id = wfc.object_id
	order by
		wfc.workflow_key,
		t.task_name
"

set ass_html "
<form method=POST action=task-assignments-wf-2>
[export_form_vars project_id return_url]
<table border=0>
"


set ctr 0
set last_workflow_key ""
db_foreach wf_assignment $wf_assignments_render_sql {
    ns_log Notice "task-assignments: ctr=$ctr, wf_key='$workflow_key', task_id=$task_id"

    # Render a new header line for evey type of Workflow
    if {$last_workflow_key != $workflow_key} {
	append ass_html "
	<tr>
	<td class=rowtitle align=center>[_ intranet-translation.Task_Name]</td>
	<td class=rowtitle align=center>[_ intranet-translation.Target_Lang]</td>
	<td class=rowtitle align=center>[_ intranet-translation.Task_Type]</td>
	<td class=rowtitle align=center>[_ intranet-translation.Size]</td>
	<td class=rowtitle align=center>[_ intranet-translation.UoM]</td>\n"

	set transition_list $transitions($workflow_key)
	foreach trans $transition_list {
	    set trans_key [lindex $trans 0]
	    set trans_name [lindex $trans 1]
	    set key "$workflow_key $trans_key"
	    append ass_html "<td class=rowtitle align=center
		>[lang::message::lookup "" intranet-translation.$trans_key $trans_name]</td>\n"
	}
	append ass_html "</tr>\n"
	set last_workflow_key $workflow_key
    }

    append ass_html "
	    <tr $bgcolor([expr $ctr % 2])>
	        <td>
		  $task_name $task_id
		  <input type=hidden name=task_id value=\"$task_id\">
		</td>
	        <td>$target_language</td>
	        <td>$task_type</td>
	        <td><nobr>$task_units</nobr></td>
	        <td><nobr>$task_uom</nobr></td>
    "
    foreach trans $transitions($workflow_key) {

	set trans_key [lindex $trans 0]
	set trans_name [lindex $trans 1]
	set ass_key "$task_id $trans_key"
	set ass_val $ass($ass_key)
	set deadl_val $deadl($ass_key)
	if {"" == $deadl_val} { set deadl_val "$end_date_formatted" }

	append ass_html "<td>\n"
	append ass_html [im_task_user_select -group_list $group_list "assignment.${trans_key}-$task_id" $project_resource_list $ass_val]
	append ass_html "\n"
	append ass_html "<input type=text size=10 name=deadline.${trans_key}-$task_id value=\"$deadl_val\">"
	append ass_html "\n"
    }
    append ass_html "</tr>\n"
    incr ctr
}

append ass_html "
</table>
<input type=submit value=Submit>
</form>
"

# Skip the dynamic workflow component completely if there was
# no dynamic WF task:
#
if {0 == $ctr} { set ass_html "" }


# -------------------------------------------------------------------
# Auto_Assign HTML Component
# -------------------------------------------------------------------

set auto_assignment_html_body ""
set auto_assignment_html_header ""

append auto_assignment_html_header "<td class=rowtitle>[_ intranet-translation.Num_Words]</td>\n"
append auto_assignment_html_body "<td><input type=text size=6 name=auto_assigned_words></td>\n"

if { $n_trans > 0 } {
    append auto_assignment_html_header "<td class=rowtitle>[_ intranet-translation.Trans]</td>\n"
    append auto_assignment_html_body "<td>[im_task_user_select trans_auto_id $project_resource_list "" translator]</td>\n"
}
if { $n_edit > 0 } {
    append auto_assignment_html_header "<td class=rowtitle>[_ intranet-translation.Edit]</td>\n"
    append auto_assignment_html_body "<td>[im_task_user_select edit_auto_id $project_resource_list "" editor]</td>\n"
}
if { $n_proof > 0} {
    append auto_assignment_html_header "<td class=rowtitle>[_ intranet-translation.Proof]</td>\n"
    append auto_assignment_html_body "<td>[im_task_user_select proof_auto_id $project_resource_list "" proof]</td>\n"
}
if { $n_other > 0 } {
    append auto_assignment_html_header "<td class=rowtitle>[_ intranet-translation.Other]</td\n>"
    append auto_assignment_html_body "<td>[im_task_user_select other_auto_id $project_resource_list ""]</td>\n"
}

set auto_assignment_html "
<form action=\"task-assignments\" method=POST>
[export_form_vars project_id return_url orderby]
<table>
<tr>
  <td colspan=5 class=rowtitle align=center>[_ intranet-translation.Auto_Assignment]</td>
</tr>
<tr align=center>
  $auto_assignment_html_header
</tr>
<tr>
  $auto_assignment_html_body
</tr>
<tr>
  <td align=left colspan=5>
    <input type=submit name='auto_assigment' value='[_ intranet-translation.Auto_Assign]'>
  </td>
</tr>
</table>
</form>
"

# No static tasks - no auto assignment...
if {"" == $task_html} { set auto_assignment_html "" }

# -------------------------------------------------------------------
# Project Subnavbar
# -------------------------------------------------------------------

set bind_vars [ns_set create]
ns_set put $bind_vars project_id $project_id
set parent_menu_id [db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]

set sub_navbar [im_sub_navbar \
    -components \
    -base_url "/intranet/projects/view?project_id=$project_id" \
    $parent_menu_id \
    $bind_vars "" "pagedesriptionbar" "project_trans_tasks_assignments"] 
