# /www/intranet/trans-tasks/task-assignments.tcl

ad_page_contract {
    Assign translators, editors and proof readers to every task

    @param project_id the project_id
    @param orderby the display order
    @param show_all_comments whether to show all comments

    @author Guillermo Belcic
    @creation-date 2003/11/17

} {
    project_id:integer
    return_url
    {orderby "subproject_name"}

    {auto_assigment ""}
    {auto_assigned_words 0}

    {trans_auto_id 0}
    {edit_auto_id 0}
    {proof_auto_id 0}
    {other_auto_id 0}
}


# -------------------------------------------------------------------------
# Security & Default
# -------------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
# set user_in_project_group_p [db_string user_belongs_to_project "select decode ( ad_group_member_p ( :user_id, $project_id ), 'f', 0, 1 ) from dual" ]

set page_title "Assignments"
set context_bar [ad_context_bar [list /intranet/projects/ "Projects"] [list "/intranet/projects/view?project_id=$project_id" "One project"] $page_title]

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
	u.*,
	im_name_from_user_id (u.user_id) as user_name,
	m.rel_type as role
from
	users u,
	group_member_map m
where
	m.group_id=:project_id
	and m.member_id=u.user_id
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
	im_email_from_user_id (t.trans_id) as trans_email,
	im_name_from_user_id (t.trans_id) as trans_name,
	im_email_from_user_id (t.edit_id) as edit_email,
	im_name_from_user_id (t.edit_id) as edit_name,
	im_email_from_user_id (t.proof_id) as proof_email,
	im_name_from_user_id (t.proof_id) as proof_name,
	im_email_from_user_id (t.other_id) as other_email,
	im_name_from_user_id (t.other_id) as other_name
from
	im_tasks t
where
	t.project_id=:project_id
        and t.task_status_id <> 372
"

set task_colspan 8
set task_html "
	<table border=0>
	  <tr>
	    <td colspan=$task_colspan class=rowtitle align=center>
	      Task Assignments
	    </td>
	  </tr>
	  <tr>
	    <td class=rowtitle align=center>Task Name</td>
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
	85 { # Trans Only
	    set trans 1
	    incr n_trans
	}
	86 { # Trans + Edit  
	    set trans 1 
	    set edit 1
	    incr n_trans
	    incr n_edit
	}
	87 { # Edit Only  
	    set edit 1
	    incr n_edit
	}
	88 { # Trans + Edit + Proof  
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
</table>"

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
# Join the components together
# -------------------------------------------------------------------

set page_body "
<form action=task-assignments method=POST>
[export_form_vars project_id return_url]
$autoassignment_html<br>
</form>

<form action=task-assignments-2 method=POST>
[export_form_vars project_id return_url]
$task_html
<input type=submit value='Save Assigments'>
</form>
"

db_release_unused_handles
doc_return  200 text/html [im_return_template]

