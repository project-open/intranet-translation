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

set page_title "Assignments"
set context_bar [ad_context_bar [list /intranet/projects/ "Projects"] [list "/intranet/projects/view?project_id=$project_id" "One project"] $page_title]

if {"" == $return_url} { set return_url "/intranet/projects/view?project_id=$project_id" }

set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"

# ----------------- Security for auto assign ----------------------
set error 0

# Check that there is only a single role being assigned
set assigned_roles 0
if {$trans_auto_id > 0} { incr assigned_roles }
if {$edit_auto_id > 0} { incr assigned_roles }
if {$proof_auto_id > 0} { incr assigned_roles }
if {$other_auto_id > 0} { incr assigned_roles }
if {$assigned_roles > 1} {
    incr error
    append errors "<LI>Please choose only a single role for assignment"
}

if {$auto_assigned_words > 0 && $assigned_roles == 0} {
    incr error
    append errors "<LI>You haven't selected a user for auto assignation"
}

if { $error > 0 } {
    ad_return_complaint "Input Error" "$errors"
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
set users [list]
db_foreach resource_select $resource_sql {
    lappend users [list $user_id $user_name $role]
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

set task_colspan 8
set task_html "
<form method=POST action=task-assignments-2>
[export_form_vars project_id return_url]
	<table border=0>
	  <tr>
	    <td colspan=$task_colspan class=rowtitle align=center>
	      Task Assignments
	    </td>
	  </tr>
	  <tr>
	    <td class=rowtitle align=center>Task Name</td>
	    <td class=rowtitle align=center>Target Lang</td>
	    <td class=rowtitle align=center>Task Type</td>
	    <td class=rowtitle align=center>Size</td>
	    <td class=rowtitle align=center>UoM</td>
	    <td class=rowtitle align=center>Trans</td>
	    <td class=rowtitle align=center>Edit</td>
	    <td class=rowtitle align=center>Proof</td>
	    <td class=rowtitle align=center>Other</td>
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

    # determine if this task is auto-assignable or not,
    # depending on whether the unit of measure (UoM) is
    # Source-Word or Target-Word.
    # ToDo: Is this reasonable, or could we also assign Lines etc?
    #
    if {324 == $task_uom_id || 325 == $task_uom_id} {
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
	append task_html [im_task_user_select task_trans.$task_id $users $trans_id translator]
    } else {
	append task_html "<input type=hidden name='task_trans.$task_id' value=''>"
    }
    
    append task_html "</td><td>"

    if {$edit} {
	append task_html [im_task_user_select task_edit.$task_id $users $edit_id editor]
    } else {
	append task_html "<input type=hidden name='task_edit.$task_id' value=''>"
    }

    append task_html "</td><td>"

    if {$proof} {
	append task_html [im_task_user_select task_proof.$task_id $users $proof_id proofer]
    } else {
	append task_html "<input type=hidden name='task_proof.$task_id' value=''>"
    }

    append task_html "</td><td>"

    if {$other} {
	append task_html [im_task_user_select task_other.$task_id $users $other_id]
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
# Autoassign HTML Component
# -------------------------------------------------------------------

set autoassignment_html_body ""
set autoassignment_html "
<table>
<tr><td colspan=4 class=rowtitle align=center>Auto Assignment</td></tr>\n<tr align=center>"
if { $n_trans > 0 } {
    append autoassignment_html "<td class=rowtitle>Trans</td>"
    append autoassignment_html_body "<td>[im_task_user_select trans_auto_id $users "" translator]</td>\n"
}
if { $n_edit > 0 } {
    append autoassignment_html "<td class=rowtitle>Edit</td>"
    append autoassignment_html_body "<td>[im_task_user_select edit_auto_id $users "" editor]</td>\n"
}
if { $n_proof > 0} {
    append autoassignment_html "<td class=rowtitle>Proof</td>"
    append autoassignment_html_body "<td>[im_task_user_select proof_auto_id $users "" proof]</td>\n"
}
if { $n_other > 0 } {
    append autoassignment_html "<td class=rowtitle>Other</td>"
    append autoassignment_html_body "<td>[im_task_user_select other_auto_id $users ""]</td>\n"
}

append autoassignment_html "</tr>\n
<tr>$autoassignment_html_body<td>
<input type=text size=6 name=auto_assigned_words>
<input type=submit name='auto_assigment' value='Auto Assigment'></td>
</tr>\n
</table>\n"


# -------------------------------------------------------------------
# Project Subnavbar
# -------------------------------------------------------------------

set bind_vars [ns_set create]
ns_set put $bind_vars project_id $project_id
set parent_menu_id [db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]
set project_menu [im_sub_navbar $parent_menu_id $bind_vars]

