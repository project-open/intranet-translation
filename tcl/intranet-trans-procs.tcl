# /packages/intranet-translation/tcl/intranet-trans-procs.tcl
#
# Copyright (C) 2004 Project/Open
# All rights reserved (this is not GPLed software!).
# Please check http://www.project-open.com/ for licensing
# details.

ad_library {
    Bring together all "components" (=HTML + SQL code)
    related to the Translation sector

    @author frank.bergmann@project-open.com
    @author juanjoruizx@yahoo.es
}

# -------------------------------------------------------------------
# Additional constant functions
# -------------------------------------------------------------------

ad_proc -public im_project_type_trans_edit {} { return 87 }
ad_proc -public im_project_type_edit {} { return 88 }
ad_proc -public im_project_type_trans_edit_proof {} { return 89 }
ad_proc -public im_project_type_ling_validation {} { return 90 }
ad_proc -public im_project_type_localization {} { return 91 }
ad_proc -public im_project_type_technology {} { return 92 }
ad_proc -public im_project_type_trans {} { return 93 }
ad_proc -public im_project_type_trans_spot {} { return 94 }
ad_proc -public im_project_type_proof {} { return 95 }
ad_proc -public im_project_type_glossary_comp {} { return 96 }


ad_proc -public im_uom_page {} { return 323 }
ad_proc -public im_uom_s_word {} { return 324 }
ad_proc -public im_uom_t_word {} { return 325 }
ad_proc -public im_uom_s_line {} { return 326 }
ad_proc -public im_uom_t_line {} { return 327 }

ad_proc -public im_package_translation_id { } {
} {
    return [util_memoize "im_package_translation_id_helper"]
}

ad_proc -private im_package_translation_id_helper {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-translation'
    } -default 0]
}

# -------------------------------------------------------------------
# Serve the abstract URLs to download im_trans_tasks files and
# to advance the task status.
# -------------------------------------------------------------------

# Register the download procedure for a URL of type:
# /intranet-translation/download-task/<task_id>/<path for the browser but ignored here>
#
ad_register_proc GET /intranet-translation/download-task/* intranet_task_download

proc intranet_task_download {} {
    set user_id [ad_maybe_redirect_for_registration]

    set url "[ns_conn url]"
    ns_log Notice "intranet_task_download: url=$url"

    # Using the task_id as only reasonable identifier
    set path_list [split $url {/}]
    set len [expr [llength $path_list] - 1]

    # +0:/ +1:intranet-translation, +2:download-task, +3:<task_id>, +4:...
    set task_id [lindex $path_list 3]
    ns_log Notice "intranet_task_download: task_id=$task_id"

    # Make sure $task_id is a number and emit an error otherwise!!!

    # get everything about the specified task
    set task_sql "
select
	t.*,
	p.project_nr,
	im_name_from_user_id(p.project_lead_id) as project_lead_name,
	im_email_from_user_id(p.project_lead_id) as project_lead_email,
	im_category_from_id(t.source_language_id) as source_language,
	im_category_from_id(t.target_language_id) as target_language
from
	im_trans_tasks t,
	im_projects p
where
	t.task_id = :task_id
	and t.project_id = p.project_id"

    if {![db_0or1row task_info_query $task_sql] } {
	doc_return 403 text/html "[_ intranet-translation.lt_Task_task_id_doesnt_e]"
	return
    }

    # Now we can check if the user permissions on the project:
    #
    set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
    set user_is_group_admin_p [im_biz_object_admin_p $user_id $project_id]
    set user_is_employee_p [im_user_is_employee_p $user_id]
    set user_admin_p [expr $user_is_admin_p || $user_is_group_admin_p]

    # Dependency with Project/Open Filestorage module:
    # We need to know where the task-files are stored in the filesystem
    set project_path [im_filestorage_project_path $project_id]

    # Get the download/upload permission for this task:
    # #1: Download folder or "" if not allowed to download
    # #2: Upload folder or "" if not allowed to upload
    # #3: A message for the user (ignored here)
    set upload_list [im_task_component_upload $user_id $user_admin_p $task_status_id $source_language $target_language $trans_id $edit_id $proof_id $other_id]
    set download_folder [lindex $upload_list 0]
    set upload_folder [lindex $upload_list 1]
    ns_log Notice "intranet_task_download: download_folder=$download_folder, upload_folder=$upload_folder"

    # Allow to download the file if the user is an admin, a project admin
    # or an employee of the company. Or if the task is assigned to the user.
    #
    set allow 0
    if {$user_admin_p} { set allow 1}
    if {$user_is_employee_p} { set allow 1}
    if {$download_folder != ""} {set allow 1}
    if {!$allow} {
	doc_return 403 text/html "[_ intranet-translation.lt_You_are_not_allowed_t_1]"
    }

    # Use the task_name as file name (dirty, dangerous?)
    set file_name $task_name

    set file "$project_path/$download_folder/$file_name"
    set guessed_file_type [ns_guesstype $file]

    ns_log notice "intranet_task_download: file_name=$file_name"
    ns_log notice "intranet_task_download: file=$file"
    ns_log notice "intranet_task_download: file_type=$guessed_file_type"

    if [file readable $file] {

	# Update the task to advance to the next status
	im_trans_download_action $task_id $task_status_id $task_type_id $user_id

	ns_log Notice "intranet_task_download: rp_serve_concrete_file $file"
        rp_serve_concrete_file $file

    } else {
	ns_log notice "intranet_task_download: file '$file' not readable"

	set subject "[_ intranet-translation.lt_File_is_missing_in_pr]"
	set subject [ad_urlencode $subject]

	ad_return_complaint 1 "<li>[_ intranet-translation.lt_The_specified_file_do]<br>
        [_ intranet-translation.lt_Your_are_trying_to_do]<p>
        [_ intranet-translation.lt_The_most_probable_cau] 
	<A href=\"mailto:$project_lead_email?subject=$subject\">
	  $project_lead_name
	</a>."
	return
    }
}


ad_proc im_task_insert {project_id task_name task_filename task_units task_uom task_type target_language_ids} {
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
    
    if {"" == $source_language_id} {
	ad_return_complaint 1 "<li>[_ intranet-translation.lt_You_havent_defined_th]<br>[_ intranet-translation.lt_Please_edit_your_proj]"
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
	INSERT INTO im_trans_tasks (
		task_id, task_name, task_filename, project_id, task_type_id, 
		task_status_id, description, source_language_id, target_language_id, 
		task_units, billable_units, task_uom_id, match100, match95, match85, 
		match0
	) VALUES (
		:new_task_id, :task_name, :task_filename, :project_id, :task_type, 
 		:task_status_id, :task_description, :source_language_id, :target_language_id, 
 		:task_units, :task_units, :task_uom, :match100, :match95, :match85, :match0
 	)"


    # Add a new task for every project target language
    foreach target_language_id $target_language_ids {

	# Check for duplicated task names
	set task_name_count [db_string task_name_count "
		select count(*) 
		from im_trans_tasks 
		where 
			lower(task_name) = lower(:task_name)
			and project_id = :project_id
			and target_language_id = :target_language_id
	"]
	if {$task_name_count > 0} {
	    ad_return_complaint "[_ intranet-translation.Database_Error]" "[_ intranet-translation.lt_Did_you_enter_the_sam]"
	    return
	}

	set new_task_id [db_nextval im_trans_tasks_seq]

        if { [catch {
	    db_dml insert_tasks $sql
        } err_msg] } {
	    ad_return_complaint "[_ intranet-translation.Database_Error]" "[_ intranet-translation.lt_Did_you_enter_the_sam]<BR>
            Here is the error:<BR> <P>$err_msg"
        }
    }
}




# -------------------------------------------------------------------
# Trados Matrix
# -------------------------------------------------------------------


ad_proc -public im_trans_trados_matrix_component { user_id object_id return_url } {
    Return a formatted HTML table showing the trados matrix
    related to the current object
} {

    if {![im_permission $user_id view_costs]} {
        return ""
    }

    array set matrix [im_trans_trados_matrix $object_id]
    set header_html "
<td class=rowtitle align=center>[_ intranet-translation.XTr]</td>
<td class=rowtitle align=center>[_ intranet-translation.Rep]</td>
<td class=rowtitle align=center>100%</td>
<td class=rowtitle align=center>95%</td>
<td class=rowtitle align=center>85%</td>
<td class=rowtitle align=center>75%</td>
<td class=rowtitle align=center>50%</td>
<td class=rowtitle align=center>0%</td>
"

    set value_html "
<td align=right>[expr 100 * $matrix(x)]%</td>
<td align=right>[expr 100 * $matrix(rep)]%</td>
<td align=right>[expr 100 * $matrix(100)]%</td>
<td align=right>[expr 100 * $matrix(95)]%</td>
<td align=right>[expr 100 * $matrix(85)]%</td>
<td align=right>[expr 100 * $matrix(75)]%</td>
<td align=right>[expr 100 * $matrix(50)]%</td>
<td align=right>[expr 100 * $matrix(0)]%</td>
"

    set html "
<table border=0>
<tr class=rowtitle><td class=rowtitle colspan=99 align=center>[_ intranet-translation.Trados_Matrix] ($matrix(type))</td></tr>
<tr class=rowtitle>$header_html</tr>
<tr class=roweven>$value_html</tr>
<tr class=rowplain>
  <td colspan=99 align=right>
    <A href=/intranet-translation/matrix/new?[export_url_vars object_id return_url]>edit</a>
  </td>
</tr>
</table>\n"

    return $html
}



ad_proc -public im_trans_trados_matrix_calculate { object_id px_words prep_words p100_words p95_words p85_words p75_words p50_words p0_words } {
    Calculate the number of "effective" words based on
    a valuation of repetitions from the associated tradox
    matrix.<br>
    If object_id is an "im_project", first check if the project
    has a matrix associated and then fallback to the companies
    matrix.<br>
    If the company doesn't have a matrix, fall back to the 
    "Internal" company<br>
    If the "Internal" company doesn't have a matrix fall
    back to some default values.
} {
    return [im_trans_trados_matrix_calculate_helper $object_id $px_words $prep_words $p100_words $p95_words $p85_words $p75_words $p50_words $p0_words]
}


ad_proc -public im_trans_trados_matrix_calculate_helper { object_id px_words prep_words p100_words p95_words p85_words p75_words p50_words p0_words } {
    See im_trans_trados_matrix_calculate for comments...
} {
    array set matrix [im_trans_trados_matrix $object_id]
    set task_units [expr \
		    ($px_words * $matrix(x)) + \
		    ($prep_words * $matrix(rep)) + \
		    ($p100_words * $matrix(100)) + \
		    ($p95_words * $matrix(95)) + \
		    ($p85_words * $matrix(85)) + \
		    ($p75_words * $matrix(75)) + \
		    ($p50_words * $matrix(50)) + \
		    ($p0_words * $matrix(0))]
    return $task_units
}


ad_proc -public im_trans_trados_matrix { object_id } {
    Returns an array with the trados matrix values for an object.
} {
    set object_type [db_string get_object_type "select object_type from acs_objects where object_id=:object_id" -default none]

    switch $object_type {
	im_project {
	    array set matrix [im_trans_trados_matrix_project $object_id]
	}
	im_company {
	    array set matrix [im_trans_trados_matrix_company $object_id]
	}
	default {
	    array set matrix [im_trans_trados_matrix_default]
	}
    }

    return [array get matrix]

}


ad_proc -public im_trans_trados_matrix_project { project_id } {
    Returns an array with the trados matrix values for a project.
} {
    set count [db_string matrix_count "select count(*) from im_trans_trados_matrix where object_id=:project_id"]
    if {!$count} { 
	set company_id [db_string project_company "select company_id from im_projects project_id=:project_id"]
	return [im_trans_trados_matrix_company] 
    }

    # Get match100, match95, ...
db_1row matrix_select "
select
        m.*,
        acs_object.name(o.object_id) as object_name
from
        acs_objects o,
        im_trans_trados_matrix m
where
        o.object_id = :project_id
        and o.object_id = m.object_id(+)
"

    set matrix(x) $match_x
    set matrix(rep) $match_rep
    set matrix(100) $match100
    set matrix(95) $match95
    set matrix(85) $match85
    set matrix(75) $match75
    set matrix(50) $match50
    set matrix(0) $match0
    set matrix(type) im_company
    set matrix(object) $project_id

    return [array get matrix]
}


ad_proc -public im_trans_trados_matrix_company { company_id } {
    Returns an array with the trados matrix values for a company.
} {
    set count [db_string matrix_count "select count(*) from im_trans_trados_matrix where object_id=:company_id"]
    if {!$count} { return [im_trans_trados_matrix_internal] }

    # Get match100, match95, ...
db_1row matrix_select "
select
        m.*,
        acs_object.name(o.object_id) as object_name
from
        acs_objects o,
        im_trans_trados_matrix m
where
        o.object_id = :company_id
        and o.object_id = m.object_id(+)
"

    set matrix(x) $match_x
    set matrix(rep) $match_rep
    set matrix(100) $match100
    set matrix(95) $match95
    set matrix(85) $match85
    set matrix(75) $match75
    set matrix(50) $match50
    set matrix(0) $match0
    set matrix(type) im_company
    set matrix(object) $company_id

    return [array get matrix]
}

ad_proc -public im_trans_trados_matrix_internal { } {
    Returns an array with the trados matrix values for the "Internal" company.
} {
    set company_id [im_company_internal]
    
    set count [db_string matrix_count "select count(*) from im_trans_trados_matrix where object_id=:company_id"]
    if {!$count} { return [im_trans_trados_matrix_default] }

    # Get match100, match95, ...
db_1row matrix_select "
select
        m.*,
        acs_object.name(o.object_id) as object_name
from
        acs_objects o,
        im_trans_trados_matrix m
where
        o.object_id = :company_id
        and o.object_id = m.object_id(+)
"

    set matrix(x) $match_x
    set matrix(rep) $match_rep
    set matrix(100) $match100
    set matrix(95) $match95
    set matrix(85) $match85
    set matrix(75) $match75
    set matrix(50) $match50
    set matrix(0) $match0
    set matrix(type) internal
    set matrix(object) 0
    return [array get matrix]
}


ad_proc -public im_trans_trados_matrix_default { } {
    Returns an array with the trados matrix values for the "Internal" company.
} {
    set matrix(x) 0.25
    set matrix(rep) 0.25
    set matrix(100) 0.25
    set matrix(95) 0.3
    set matrix(85) 0.5
    set matrix(75) 1.0
    set matrix(50) 1.0
    set matrix(0) 1.0
    set matrix(type) default
    set matrix(object) 0

    return [array get matrix]
}


# -------------------------------------------------------------------
# Permissions
# -------------------------------------------------------------------


ad_proc -public im_translation_task_permissions {user_id task_id view_var read_var write_var admin_var} {
    Fill the "by-reference" variables read, write and admin
    with the permissions of $user_id on $project_id

    Allow to download the file if the user is an admin, a project admin
    or an employee of the company. Or if the user is an translator, editor,
    proofer or "other" of the specified task.
} {
    upvar $view_var view
    upvar $read_var read
    upvar $write_var write
    upvar $admin_var admin

    set view 0
    set read 0
    set write 0
    set admin 0

    set project_id [db_string project_id "select project_id from im_trans_tasks where task_id = :task_id"]

    set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
    set user_is_wheel_p [ad_user_group_member [im_wheel_group_id] $user_id]
    set user_is_group_member_p [ad_user_group_member $project_id $user_id]
    set user_is_employee_p [im_user_is_employee_p $user_id]

    if {$user_is_admin_p} { set admin 1}
    if {$user_is_wheel_p} { set admin 1}
    if {$user_is_group_member_p} { set read 1}

    if {$admin} {
	set read 1
	set write 1
    }
    if ($read) { set view 1 }
}


# -------------------------------------------------------------------
# Drop-Down Components
# -------------------------------------------------------------------

ad_proc im_task_user_select {select_name user_list default_user_id {role ""}} {
    Return a formatted HTML drop-down select component with the
    list of members of the current project.
} {
    ns_log Notice "default_user_id=$default_user_id"
    set select_html "<select name='$select_name'>\n"
    if {"" == $default_user_id} {
	append select_html "<option value='' selected>[_ intranet-translation.--_Please_Select_--]</option>\n"
    } else {
	append select_html "<option value=''>[_ intranet-translation.--_Please_Select_--]</option>\n"
    }

    foreach user_list_entry $user_list {
	set user_id [lindex $user_list_entry 0]
	set user_name [lindex $user_list_entry 1]
	set selected ""
	if {$default_user_id == $user_id} { set selected "selected"}
	append select_html "<option value='$user_id' $selected>$user_name</option>\n"
    }
    append select_html "</select>\n"
    return $select_html
}




ad_proc -public im_target_languages { project_id} {
    Returns a (possibly empty list) of target languages 
    (i.e. "en_ES", ...) used for a specific project or task
} {
    set result [list]
    set sql "
select
	im_category_from_id(l.language_id) as target_language
from 
	im_target_languages l
where 
	project_id=:project_id
"
    db_foreach select_target_languages $sql {
	lappend result $target_language
    }
    return $result
}


ad_proc -public im_target_language_ids { project_id} {
    Returns a (possibly empty list) of target language IDs used
} {
    set result [list]
    set sql "
select
	language_id
from 
	im_target_languages
where 
	project_id=:project_id
"
    db_foreach select_target_languages $sql {
	lappend result $language_id
    }
    return $result
}


ad_proc -public im_trans_project_details_component { user_id project_id return_url } {
    Return a formatted HTML widget showing the translation
    specific fields of a translation project.
} {
    # Is this a translation project?
    if {![im_project_has_type $project_id "Translation Project"]} {
	return ""
    }
 
    set query "
select
        p.*,
	im_name_from_user_id(p.company_contact_id) as company_contact_name
from
        im_projects p
where
        p.project_id=:project_id
"

    if { ![db_0or1row projects_info_query $query] } {
	ad_return_complaint 1 "[_ intranet-translation.lt_Cant_find_the_project_1]"
	return
    }

    set html "
<table cellpadding=0 cellspacing=2 border=0>
  <tr> 
    <td colspan=2 class=rowtitle align=middle>
      [_ intranet-translation.Project_Details]
    </td>
  </tr>
"
if {[im_permission $user_id view_trans_proj_detail]} {
    append html "
  <tr> 
    <td>[_ intranet-translation.Client_Project]</td>
    <td>$company_project_nr</td>
  </tr>
  <tr> 
    <td>[_ intranet-translation.Final_User]</td>
    <td>$final_company</td>
  </tr>
  <tr> 
    <td>[_ intranet-translation.Quality_Level]</td>
    <td>[im_category_from_id $expected_quality_id]</td>
  </tr>
"
}

set company_contact_html [im_render_user_id $company_contact_id $company_contact_name $user_id $project_id]
if {"" != $company_contact_html} {
    append html "
  <tr> 
    <td>[_ intranet-translation.Company_Contact]</td>
    <td>$company_contact_html</td>
  </tr>
"
}


append html "
  <tr> 
    <td>[_ intranet-translation.Subject_Area]</td>
    <td>[im_category_from_id $subject_area_id]</td>
  </tr>
  <tr> 
    <td>[_ intranet-translation.Source_Language]</td>
    <td>[im_category_from_id $source_language_id]</td>
  </tr>
  <tr> 
    <td>[_ intranet-translation.Target_Languages_1]</td>
    <td>[im_target_languages $project_id]</td>
  </tr>
  <tr> 
    <td></td>
    <td>
<form action=/intranet-translation/projects/edit-trans-data method=POST>
[export_form_vars project_id return_url]
<input type=submit name=edit value=\"[_ intranet-translation.Edit]\">
</form>
    </td>
  </tr>
</table>
"

    return $html
}


# -------------------------------------------------------------------
# Status Engine for im_trans_tasks
#
#    340 Created  
#    342 for Trans
#    344 Trans-ing 
#    346 for Edit  
#    348 Editing  
#    350 for Proof  
#    352 Proofing  
#    354 for QCing  
#    356 QCing  
#    358 for Deliv  
#    360 Delivered  
#    365 Invoiced  
#    370 Payed  
#    372 Deleted 
# -------------------------------------------------------------------

# Update the task to advance to the next status
# after a successful upload of the related file
ad_proc im_trans_upload_action {task_id task_status_id task_type_id user_id} {
} {
    set new_status_id $task_status_id

    # Task Types
    set trans_only 85
    set trans_ed 86
    set edit_only 87
    set trans_ed_proof 88
    set trans_spot 94
    set proof_only 95

    switch $task_status_id {
	340 { 
	    # Created: Maybe in the future there maybe a step between
	    # created and "for Trans", but today it's the same.

	    # there shouldn't be any upload...
	}
	342 { # for Trans: 
	}
	344 { # Translating: 
	    if {$task_type_id == $trans_only} {
		# we are done, because this task is translation only.
		set new_status_id 358
	    } else {
		set new_status_id 346
	    }
	}
	346 { # for Edit: 
	}
	348 { # Editing: 
	    if {$task_type_id == $edit_only || $task_type_id == $trans_ed || $task_type_id == $trans_spot} {
		# we are done, because this task is only until editing
		# (spotcheck = short editing)
		set new_status_id 358
	    } else {
		set new_status_id 350
	    }
	}
	350 { # for Proof: 
	}
	352 { # Proofing: 
	    # All types are done when proofed.
	    set new_status_id 358
	}
	default {
	}
    }

    ns_log Notice "im_trans_upload_action task_id=$task_id task_status_id=$task_status_id task_type_id=$task_type_id user_id=$user_id => $new_status_id"

    # only update if there was a change...
    if {$new_status_id != $task_status_id} {

	db_dml advance_status "
		update im_trans_tasks 
		set task_status_id=:new_status_id 
		where task_id=:task_id
	"
    }

    # Always register the user-action
    set upload_action_id [db_string upload_action_id "select category_id from im_categories where category_type='Intranet File Action Type' and lower(category)='upload'" -default ""]
    set action_id [db_nextval im_task_actions_seq]
    set sysdate [db_string sysdate "select sysdate from dual"]
    db_dml register_action "insert into im_task_actions (
	        action_id,
	        action_type_id,
	        user_id,
	        task_id,
	        action_date,
	        old_status_id,
	        new_status_id
	    ) values (
		:action_id,
		$upload_action_id,
		:user_id,
		:task_id,
		:sysdate,
		:task_status_id,
		:new_status_id
    )"
}


# Update the task to advance to the next status
# after a successful download of the related file
ad_proc im_trans_download_action {task_id task_status_id task_type_id user_id} {
} {
    set now [db_string now "select sysdate from dual"]
    set new_status_id $task_status_id
    switch $task_status_id {
	340 { 
	    # Created: Maybe in the future there maybe a step between
	    # created and "for Trans", but today it's the same.
	    set new_status_id 344
	}
	342 { # for Trans: 
	    set new_status_id 344
	}
	344 { # Translating: 
	}
	346 { # for Edit: 
	    set new_status_id 348
	}
	348 { # Editing: 
	}
	350 { # for Proof: 
	    set new_status_id 352
	}
	352 { # Proofing: 
	}
	default {
	}
    }

    ns_log Notice "im_trans_download_action task_id=$task_id task_status_id=$task_status_id task_type_id=$task_type_id user_id=$user_id => $new_status_id"

    # only update if there was a change...
    if {$new_status_id != $task_status_id} {

	db_dml advance_status "
		update im_trans_tasks 
		set task_status_id=:new_status_id 
		where task_id=:task_id
	"
    }

    # Always register the user-action
    set download_action_id [db_string upload_action_id "select category_id from im_categories where category_type='Intranet File Action Type' and lower(category)='download'" -default ""]
    set action_id [db_nextval im_task_actions_seq]
    db_dml register_action "insert into im_task_actions (
	        action_id,
	        action_type_id,
	        user_id,
	        task_id,
	        action_date,
	        old_status_id,
	        new_status_id
	    ) values (
		:action_id,
		$download_action_id,
		:user_id,
		:task_id,
		:now,
		:task_status_id,
		:new_status_id
    )"
}


ad_proc im_task_component_upload {user_id user_admin_p task_status_id source_language target_language trans_id edit_id proof_id other_id} {
    Determine if the user $user_id is allows to upload a file in the current
    status of a task.
    Returns a list composed by:
    1. the folder for download or ""
    2. the folder for upload or "" and
    3. a message for the user
} {
    ns_log Notice "im_task_component_upload(user_id=$user_id user_admin_p=$user_admin_p task_status_id=$task_status_id target_language=$target_language trans_id=$trans_id edit_id=$edit_id proof_id=$proof_id other_id=$other_id)"

    switch $task_status_id {
	340 { 
	    # The user is admin, so he may upload the file
	    if {$user_admin_p} {
		return [list "source_$source_language" "source_$source_language" "You are the administrator..."]
	    }

	    # Created: In the future there maybe a step between
	    # created and "for Trans", but today it's the same.
	    if {$user_id == $trans_id} {
		return [list "source_$source_language" "" "Please download the source file."]
	    } 

	    if {"" != $trans_id} {
		return [list "" "" "The file is ready to be translated by another person."]
	    }
	    return [list "" "" ""]

	}
	342 { # for Trans: 
	    if {$user_id == $trans_id} {
		return [list "source_$source_language" "" "Please download the source file."]
	    }
	    if {"" != $trans_id} {
		return [list "" "" "The file is ready to be translated by another person."]
	    }
	    return [list "" "" ""]
	}
	344 { # Translating: Allow to upload a file into the trans folder
	    if {$user_id == $trans_id} {
		return [list "source_$source_language" "trans_$target_language" "Please upload the translated file"]
	    } else {
		return [list "" "" "The file is being translated by another person"]
	    }
	}
	346 { # for Edit: 
	    if {$user_id == $edit_id} {
		return [list "trans_$target_language" "" "Please download the translated file."]
	    }
	    if {$user_id == $trans_id} {
		# The translator may upload the file again, while the Editor has not
		# downloaded the file yet.
		return [list "" "trans_$target_language" "You are allowed to upload the file again while the Editor has not started editing yet..."]
	    } else {
		return [list "" "" "The file is ready to be edited by another person"]
	    }
	}
	348 { # Editing: Allow to upload a file into the edit folder
	    if {$user_id == $edit_id} {
		return [list "trans_$target_language" "edit_$target_language" "Please upload the edited file"]
	    } else {
		return [list "" "" "The file is being edited by another person"]
	    }
	}
	350 { # for Proof: 
	    if {$user_id == $proof_id} {
		return [list "edit_$target_language" "" "Please download the edited file."]
	    }
	    if {$user_id == $edit_id} {
		# The editor may upload the file again, while the Proofer has not
		# downloaded the file yet.
		return [list "" "edit_$target_language" "You are allowed to upload the file again while the Proof Reader has not started editing yet..."]
	    } else {
		return [list "" "" "The file is ready to be proofed by another person"]
	    }
	}
	352 { # Proofing: Allow to upload a file into the proof folder
	    if {$user_id == $proof_id} {
		return [list "edit_$target_language" "proof_$target_language" "Please upload the proofed file"]
	    } else {
		return [list "" "" "The file is being proofed by another person"]
	    }
	}
	default {
	    return [list "" "" ""]
	}
    }
}

# -------------------------------------------------------------------
# Task Status Component
# -------------------------------------------------------------------

ad_proc im_task_status_component { user_id project_id return_url } {
    Returns a formatted HTML component, representing a summary of
    the current project.
    The table shows for each participating user how many files have
    been 1. assigned to the user, 2. downloaded by the user and
    3. uploaded by the user.
    File movements outside the translation workflow (moving files
    in the filesystem) are not reflected by this component (yet).
} {
    ns_log Notice "im_trans_status_component($user_id, $project_id)"
    # Is this a translation project?

    if {![im_project_has_type $project_id "Translation Project"]} {
	ns_log Notice "im_task_status_component: Project $project_id is not a translation project"
	return ""
    }

    im_project_permissions $user_id $project_id view read write admin
    if {![im_permission $user_id view_trans_task_status]} {
	return ""
    }

    set bgcolor(0) " class=roweven"
    set bgcolor(1) " class=rowodd"

    set up [db_string upload_action_id "select category_id from im_categories where category_type='Intranet File Action Type' and lower(category)='upload'" -default ""]
    set down [db_string download_action_id "select category_id from im_categories where category_type='Intranet File Action Type' and lower(category)='download'" -default ""]

    # ------------------Display the list of current tasks...-------------

    set task_status_html "
<form action=/intranet-translation/trans-tasks/task-action method=POST>
[export_form_vars project_id return_url]

<table cellpadding=0 cellspacing=2 border=0>
<tr>
  <td class=rowtitle align=center colspan=17>
    [_ intranet-translation.lt_Project_Workflow_Stat]
[im_gif help "Shows the status of all tasks\nAss: Assigned Files\nDn: Downloaded Files\nUp: Uploaded Files"]
  </td>
</tr>
<tr>
  <td class=rowtitle align=center rowspan=2>[_ intranet-translation.Name]</td>
  <td class=rowtitle align=center colspan=3>[_ intranet-translation.Translation]</td>
  <td class=rowtitle align=center colspan=3>[_ intranet-translation.Editing]</td>
  <td class=rowtitle align=center colspan=3>[_ intranet-translation.Proofing]</td>
  <td class=rowtitle align=center colspan=3>[_ intranet-translation.Other]</td>
  <td class=rowtitle align=center colspan=3>[_ intranet-translation.Wordcount]</td>
</tr>
<tr>
  <td class=rowtitle align=center>[_ intranet-translation.Ass]</td>
  <td class=rowtitle align=center>[_ intranet-translation.Dn]</td>
  <td class=rowtitle align=center>[_ intranet-translation.Up]</td>
  <td class=rowtitle align=center>[_ intranet-translation.Ass]</td>
  <td class=rowtitle align=center>[_ intranet-translation.Dn]</td>
  <td class=rowtitle align=center>[_ intranet-translation.Up]</td>
  <td class=rowtitle align=center>[_ intranet-translation.Ass]</td>
  <td class=rowtitle align=center>[_ intranet-translation.Dn]</td>
  <td class=rowtitle align=center>[_ intranet-translation.Up]</td>
  <td class=rowtitle align=center>[_ intranet-translation.Ass]</td>
  <td class=rowtitle align=center>[_ intranet-translation.Dn]</td>
  <td class=rowtitle align=center>[_ intranet-translation.Up]</td>

  <td class=rowtitle align=center>[_ intranet-translation.Trans]</td>
  <td class=rowtitle align=center>[_ intranet-translation.Edit]</td>
  <td class=rowtitle align=center>[_ intranet-translation.Proof]</td>
</tr>\n"

    # ------------------- Get the number of tasks to assign----------------
    # This SQL calculates the overall number of files/wordcounts to be
    # assigned. We are going to subtract the assigned files/wcs from it.

    set unassigned_files_sql "
select
	count(t.trans) as unassigned_trans,
	count(t.edit) as unassigned_edit,
	count(t.proof) as unassigned_proof,
	count(t.other) as unassigned_other,
	CASE WHEN sum(t.trans) is null THEN 0 ELSE sum(t.trans) END as unassigned_trans_wc,
	CASE WHEN sum(t.edit) is null THEN 0 ELSE sum(t.edit) END as unassigned_edit_wc,
	CASE WHEN sum(t.proof) is null THEN 0 ELSE sum(t.proof) END as unassigned_proof_wc,
	CASE WHEN sum(t.other) is null THEN 0 ELSE sum(t.other) END as unassigned_other_wc
from
	(select
		t.task_type_id,
		CASE WHEN t.task_type_id in (87,89,94) THEN t.task_units END as trans,
		CASE WHEN t.task_type_id in (87,88,89,94) THEN t.task_units  END as edit,
		CASE WHEN t.task_type_id in (89,95) THEN t.task_units  END as proof,
		CASE WHEN t.task_type_id in (85,86,90,91,92,96) THEN t.task_units END as other
	from
		im_trans_tasks t
	where
		t.project_id = :project_id
	) t
"

    db_1row unassigned_totals $unassigned_files_sql


    # ----------------------Get task status ------------------------------

    # Aggregate the information from the inner_sql and 
    # order it by user
    set task_status_sql "
select
	u.user_id,
	sum(trans_down) as trans_down,
	sum(trans_up) as trans_up,
	sum(edit_down) as edit_down,
	sum(edit_up) as edit_up,
	sum(proof_down) as proof_down,
	sum(proof_up) as proof_up,
	sum(other_down) as other_down,
	sum(other_up) as other_up
from
	users u,
	acs_rels r,
	(select distinct
		t.task_id,
		u.user_id,
		CASE WHEN u.user_id = t.trans_id and action_type_id=:down THEN 1 END as trans_down,
		CASE WHEN u.user_id = t.trans_id and action_type_id=:up THEN 1 END as trans_up,
		CASE WHEN u.user_id = t.edit_id and action_type_id=:down THEN 1 END as edit_down,
		CASE WHEN u.user_id = t.edit_id and action_type_id=:up THEN 1 END as edit_up,
		CASE WHEN u.user_id = t.proof_id and action_type_id=:down THEN 1 END as proof_down,
		CASE WHEN u.user_id = t.proof_id and action_type_id=:up THEN 1 END as proof_up,
		CASE WHEN u.user_id = t.other_id and action_type_id=:down THEN 1 END as other_down,
		CASE WHEN u.user_id = t.other_id and action_type_id=:up THEN 1 END as other_up
	from
		users u,
		acs_rels r,
		im_trans_tasks t,
		im_task_actions a
	where
		r.object_id_one = :project_id
		and r.object_id_one = t.project_id
		and u.user_id = r.object_id_two
		and (	u.user_id = t.trans_id 
			or u.user_id = t.edit_id 
			or u.user_id = t.proof_id 
			or u.user_id = t.other_id)
		and a.user_id = u.user_id
		and a.task_id = t.task_id
	) t
where
	r.object_id_one = :project_id
	and r.object_id_two = u.user_id
	and u.user_id = t.user_id
group by
	u.user_id
"

    # ----- Get the absolute number of tasks by project phase ---------------

    set task_filecount_sql "
select
	t.user_id,
	count(trans_ass) as trans_ass,
	count(edit_ass) as edit_ass,
	count(proof_ass) as proof_ass,
	count(other_ass) as other_ass,
	sum(trans_ass) as trans_words,
	sum(edit_ass) as edit_words,
	sum(proof_ass) as proof_words,
	sum(other_ass) as other_words
from
	(select
		u.user_id,
		t.task_id,
		CASE WHEN u.user_id = t.trans_id THEN t.task_units END as trans_ass,
		CASE WHEN u.user_id = t.edit_id THEN t.task_units END as edit_ass,
		CASE WHEN u.user_id = t.proof_id THEN t.task_units END as proof_ass,
		CASE WHEN u.user_id = t.other_id THEN t.task_units END as other_ass
	from
		users u,
		acs_rels r,
		im_trans_tasks t
	where
		r.object_id_one = :project_id
		and r.object_id_one = t.project_id
		and u.user_id = r.object_id_two
		and (
			u.user_id = t.trans_id 
			or u.user_id = t.edit_id 
			or u.user_id = t.proof_id 
			or u.user_id = t.other_id
		)
	) t
group by t.user_id
"

    set task_sql "
select
	u.user_id,
	im_name_from_user_id (u.user_id) as user_name,
	CASE WHEN c.trans_ass is null THEN 0 ELSE c.trans_ass END as trans_ass,
	CASE WHEN c.edit_ass is null THEN 0 ELSE c.edit_ass END as edit_ass,
	CASE WHEN c.proof_ass is null THEN 0 ELSE c.proof_ass END as proof_ass,
	CASE WHEN c.other_ass is null THEN 0 ELSE c.other_ass END as other_ass,
	CASE WHEN c.trans_words is null THEN 0 ELSE c.trans_words END as trans_words,
	CASE WHEN c.edit_words is null THEN 0 ELSE c.edit_words END as edit_words,
	CASE WHEN c.proof_words is null THEN 0 ELSE c.proof_words END as proof_words,
	CASE WHEN c.other_words is null THEN 0 ELSE c.other_words END as other_words,
	s.trans_down,
	s.trans_up,
	s.edit_down,
	s.edit_up,
	s.proof_down,
	s.proof_up,
	s.other_down,
	s.other_up
from
	users u,
	acs_rels r,
	($task_status_sql) s,
	($task_filecount_sql) c
where
	r.object_id_one = :project_id
	and r.object_id_two = u.user_id
	and u.user_id = s.user_id(+)
	and u.user_id = c.user_id(+)
"

    # --------------------- Display the results ----------------------

    set ctr 0
    db_foreach task_status_sql $task_sql {

	# subtract the assigned files from the unassigned
	set unassigned_trans [expr $unassigned_trans - $trans_ass]
	set unassigned_edit [expr $unassigned_edit - $edit_ass]
	set unassigned_proof [expr $unassigned_proof - $proof_ass]
	set unassigned_other [expr $unassigned_other - $other_ass]

	set unassigned_trans_wc [expr $unassigned_trans_wc - $trans_words]
	set unassigned_edit_wc [expr $unassigned_edit_wc - $edit_words]
	set unassigned_proof_wc [expr $unassigned_proof_wc - $proof_words]
	set unassigned_other_wc [expr $unassigned_other_wc - $other_words]

	if {0 == $trans_ass} { set trans_ass "&nbsp;" }
	if {0 == $edit_ass} { set edit_ass "&nbsp;" }
	if {0 == $proof_ass} { set proof_ass "&nbsp;" }
	if {0 == $other_ass} { set other_ass "&nbsp;" }

	append task_status_html "
<tr $bgcolor([expr $ctr % 2])>
  <td><A HREF=/intranet/users/view?user_id=$user_id>$user_name</A></td>

  <td>$trans_ass</td>
  <td>$trans_down</td>
  <td>$trans_up</td>

  <td>$edit_ass</td>
  <td>$edit_down</td>
  <td>$edit_up</td>

  <td>$proof_ass</td>
  <td>$proof_down</td>
  <td>$proof_up</td>

  <td>$other_ass</td>
  <td>$other_down</td>
  <td>$other_up</td>

  <td>$trans_words</td>
  <td>$edit_words</td>
  <td>$proof_words</td>
</tr>
"
        incr ctr
    }


    append task_status_html "
<tr $bgcolor([expr $ctr % 2])>
  <td>unassigned tasks</td>

  <td>$unassigned_trans</td>
  <td></td>
  <td></td>

  <td>$unassigned_edit</td>
  <td></td>
  <td></td>

  <td>$unassigned_proof</td>
  <td></td>
  <td></td>

  <td>$unassigned_other</td>
  <td></td>
  <td></td>

  <td>[expr round($unassigned_trans_wc)]</td>
  <td>[expr round($unassigned_edit_wc)]</td>
  <td>[expr round($unassigned_proof_wc)]</td>

</tr>
"


    append task_status_html "
<tr>
  <td colspan=12 align=left>
    <input type=submit value='[_ intranet-translation.View_Tasks]' name=submit_view>
    <input type=submit value='[_ intranet-translation.Assign_Tasks]' name=submit_assign>
  </td>
</tr>
"

    append task_status_html "\n</table>\n</form>\n\n"
    return $task_status_html
}


# -------------------------------------------------------------------
# Task Component
# Show the list of tasks for one project
# -------------------------------------------------------------------




ad_proc im_task_freelance_component { user_id project_id return_url } {
    Same as im_task_component, 
    except that this component is only shown to non-project
    administrators.
} {
    # Get the permissions for the current _project_
    im_project_permissions $user_id $project_id project_view project_read project_write project_admin

    if {$project_write} { return "" }
    return [im_task_component $user_id $project_id $return_url]
}


ad_proc im_task_component { user_id project_id return_url {view_name "trans_task_list"} } {
    Return a piece of HTML for the project view page,
    containing the list of tasks of a project.
} {
    # Is this a translation project?
    if {![im_project_has_type $project_id "Translation Project"]} {
	return ""
    }

    # Get the permissions for the current _project_
    im_project_permissions $user_id $project_id project_view project_read project_write project_admin

    set company_view_page "/intranet/companies/view"

    # -------------------- Column Selection ---------------------------------
    # Define the column headers and column contents that
    # we want to show:
    #
    set view_id [db_string get_view_id "select view_id from im_views where view_name=:view_name"]
    set column_headers [list]
    set column_vars [list]

    set column_sql "
select  column_name,
        column_render_tcl,
        visible_for
from    im_view_columns
where   view_id=:view_id
        and group_id is null
order by sort_order"

    db_foreach column_list_sql $column_sql {
	if {"" == $visible_for || [eval $visible_for]} {
	    lappend column_headers "$column_name"
	    lappend column_vars "$column_render_tcl"
	}
    }

    # -------------------- Header ---------------------------------
    set task_table "
<form action=/intranet-translation/trans-tasks/task-action method=POST>
[export_form_vars project_id return_url]
<table border=0>
<tr>\n"

foreach col $column_headers {
    set header ""
    set header_cmd "set header \"$col\""
    eval $header_cmd
    if { [regexp "im_gif" $col] } {
	set header_tr $header
    } else {
	set header_tr [_ intranet-translation.[lang::util::suggest_key $header]]
    }
    append task_table "<td class=rowtitle>$header_tr</td>\n"
}
append task_table "
</tr>\n"

    # -------------------- SQL -----------------------------------

    set sql "
select 
	t.*,
        im_category_from_id(t.source_language_id) as source_language,
        im_category_from_id(t.target_language_id) as target_language,
        im_category_from_id(t.task_status_id) as task_status,
	uom_c.category as uom_name,
	type_c.category as type_name,
        im_initials_from_user_id (t.trans_id) as trans_name,
        im_initials_from_user_id (t.edit_id) as edit_name,
        im_initials_from_user_id (t.proof_id) as proof_name,
        im_initials_from_user_id (t.other_id) as other_name
from 
	im_trans_tasks t,
	im_categories uom_c,
	im_categories type_c
where
	t.project_id=:project_id
and t.task_uom_id=uom_c.category_id(+)
and t.task_type_id=type_c.category_id(+)
    "

    set bgcolor(0) " class=roweven"
    set bgcolor(1) " class=rowodd"
    set trans_project_words 0
    set trans_project_hours 0
    set ctr 0
    set task_table_rows ""

    db_foreach select_tasks $sql {

	# Determine if $user_id is assigned to some phase of this task
	set user_assigned 0
        if {$trans_id == $user_id} { set user_assigned 1 }
        if {$edit_id == $user_id} { set user_assigned 1 }
        if {$proof_id == $user_id} { set user_assigned 1 }
        if {$other_id == $user_id} { set user_assigned 1 }

	# Freelancers shouldn't see tasks if they are not assigned to it.
        if {!$user_assigned && ![im_permission $user_id view_trans_tasks]} {
	        continue
        }

	# Build a string with the user short names for the assignations
        set assignments ""
        if {$trans_name != ""} { append assignments "T: <A HREF=/intranet/users/view?user_id=$trans_id>$trans_name</A> " }
        if {$edit_name != ""} { append assignments "E: <A HREF=/intranet/users/view?user_id=$edit_id>$edit_name</A> " }
        if {$proof_name != ""} { append assignments "P: <A HREF=/intranet/users/view?user_id=$proof_id>$proof_name</A> " }
        if {$other_name != ""} { append assignments "<A HREF=/intranet/users/view?user_id=$other_id>$other_name</A> " }

	# Replace "/" characters in the Task Name (filename) by "/ ",
	# to allow the line to break more smoothely
	set task_name_list [split $task_name "/"]
	set task_name_splitted [join $task_name_list "/ "]

	# Add a " " at the beginning of uom_name in order to separate
	# it from the number of units:
	set uom_name " $uom_name"

	# Billable Items 
	set billable_items_input "<input type=text size=3 name=billable_units.$task_id value=$billable_units>"

	# Status Select Box
	set status_select [im_category_select "Intranet Translation Task Status" task_status.$task_id $task_status_id]

	# Type Select Box
	# ToDo: Introduce its own "Intranet Translation Task Type".
	set type_select [im_category_select "Intranet Project Type" task_type.$task_id $task_type_id]

	# Message - Tell the freelancer what to do...
	# Check if the user is a freelance who is allowed to
	# upload a file for this task, depending on the task
	# status (engine) and the assignment to a specific phase.
	set upload_list [im_task_component_upload $user_id $project_admin $task_status_id $source_language $target_language $trans_id $edit_id $proof_id $other_id]
	set download_folder [lindex $upload_list 0]
	set upload_folder [lindex $upload_list 1]
	set message [lindex $upload_list 2]
	ns_log Notice "download_folder=$download_folder, upload_folder=$upload_folder"

	# Delete Checkbox
	set del_checkbox "<input type=checkbox name=delete_task value=$task_id>"

	# Download Link - where to get the task file
	set download_link ""
	if {$download_folder != ""} {
	    set download_link "
  <A HREF='/intranet-translation/download-task/$task_id/$download_folder/$task_name'>
    [im_gif save "Click right and choose \"Save target as\" to download the file"]
  </A>\n"
	}

	# Upload Link
	set upload_link ""
	if {$upload_folder != ""} {
	    set upload_link "
  <A HREF='/intranet-translation/trans-tasks/upload-task?[export_url_vars project_id task_id return_url]'>
    [im_gif open "Upload file"]
  </A>\n"
	}
	
	# Append together a line of data based on the "column_vars" parameter list
	append table_body_html "<tr$bgcolor([expr $ctr % 2])>\n"
	foreach column_var $column_vars {
	    append task_table "\t<td$bgcolor([expr $ctr % 2]) valign=top>"
	    set cmd "append task_table $column_var"
	    eval $cmd
	    append task_table "</td>\n"
	}
	append task_table "</tr>\n"

	incr ctr
	if {$task_uom_id == [im_uom_s_word]} { set trans_project_words [expr $trans_project_words + $task_units] }
	if {$task_uom_id == [im_uom_hour]} { set trans_project_hours [expr $trans_project_hours + $task_units] }
    }

    if {$ctr > 0} {
         append task_table $task_table_rows
    } else {
         append task_table "<tr><td colspan=7 align=center>[_ intranet-translation.No_tasks_found]</td></tr>"
    }

    # -------------------- Calculate the project size -------------------------------
    db_dml update_project_size "
	update im_projects set 
		trans_project_words = :trans_project_words,
		trans_project_hours = :trans_project_hours
	where project_id = :project_id
    "

    # -------------------- Action Row -------------------------------
    # End of the task-list loop.
    # Start formatting the the adding new tasks line etc.

    # Show "Save, Del, Assign" buttons only for admins and 
    # only if there is atleast one row to act upon.
    if {$project_admin && $ctr > 0} {
	append task_table "
<tr align=right> 
  <td align=left>
  </td>
  <td colspan=12 align=right>&nbsp;</td>
  <td align=center><input type=submit value=\"[_ intranet-translation.Save]\" name=submit></td>
  <td align=center><input type=submit value=\"[_ intranet-translation.Del]\" name=submit></td>
  <td align=center><input type=submit value=\"[_ intranet-translation.Assign]\" name=submit></td>
</tr>"
    }

    append task_table "
</table>
</form>\n"

    return $task_table
}


# -------------------------------------------------------------------
# Task Error Component
# -------------------------------------------------------------------

ad_proc im_task_error_component { user_id project_id return_url } {
    Return a piece of HTML for the project view page,
    containing the list of tasks that are not found in the filesystem.
} {
    # Is this a translation project?
    if {![im_project_has_type $project_id "Translation Project"]} {
	return ""
    }

    if {![im_permission $user_id view_trans_proj_detail]} { return "" }

    # Show the missing tasks only to people who can write on the
    # project
    im_project_permissions $user_id $project_id view read write admin
    if {!$write} { return "" }

    set err_count 0
    set task_table_rows ""
    
    # -------------------------------------------------------
    # Check that the path exists

    set project_path [im_filestorage_project_path $project_id]
    set source_language [db_string source_language "select im_category_from_id(source_language_id) from im_projects where project_id=:project_id" -default ""]
    if {![file isdirectory "$project_path/source_$source_language"]} {
	incr err_count
	append task_table_rows "<tr class=roweven><td colspan=99>'$project_path/source_$source_language' does not exist</td></tr>\n"
    }

    # -------------------------------------------------------
    # Get the list of tasks with missing files

    if {!$err_count} {
	set missing_task_list [im_task_missing_file_list $project_id]
	ns_log Notice "im_task_error_component: missing_task_list=$missing_task_list"
    }


    # -------------------- SQL -----------------------------------
    set sql "
select 
	min(t.task_id) as task_id,
	t.task_name,
	t.task_filename,
	t.task_units,
        im_category_from_id(t.source_language_id) as source_language,
	uom_c.category as uom_name,
	type_c.category as type_name
from 
	im_trans_tasks t,
	im_categories uom_c,
	im_categories type_c
where
	project_id=:project_id
	and t.task_status_id <> 372
	and t.task_uom_id=uom_c.category_id(+)
	and t.task_type_id=type_c.category_id(+)
group by
	t.task_name,
	t.task_filename,
	t.task_units,
	t.source_language_id,
	uom_c.category,
	type_c.category
"

    set bgcolor(0) " class=roweven"
    set bgcolor(1) " class=rowodd"
    set ctr 0

    db_foreach select_tasks $sql {

	if {$err_count} { continue }
        set upload_folder "source_$source_language"

	# only show the tasks that are in the "missing_task_list":
        if {[lsearch -exact $missing_task_list $task_id] < 0} {
            continue
	}

	# Replace "/" characters in the Task Name (filename) by "/ ",
	# to allow the line to break more smoothely
	set task_name_list [split $task_name "/"]
	set task_name_splitted [join $task_name_list "/ "]

        append task_table_rows "
<tr $bgcolor([expr $ctr % 2])> 
  <td align=left><font color=red>$task_name_splitted</font></td>
  <td align=right>$task_units $uom_name</td>
  <td align=center>
    <A HREF='/intranet-translation/trans-tasks/upload-task?[export_url_vars project_id task_id return_url]'>
      [im_gif open "Upload file"]
    </A>
  </td>
</tr>\n"
        incr ctr
    }
    
    # Return an empty string if there are no errors
    if {$ctr == 0 && !$err_count} {
#	return ""
	append task_table_rows "
<tr $bgcolor([expr $ctr % 2])>
  <td colspan=99 align=center>[_ intranet-translation.lt_No_missing_files_foun]</td>
</tr>
"
    }

    # ----------------- Put everything together -------------------------
    set task_table "
<form action=/intranet-translation/trans-tasks/task-action method=POST>
[export_form_vars project_id return_url]

<table border=0>
<tr>
  <td class=rowtitle align=center colspan=20>
    [_ intranet-translation.lt_Missing_Translation_F]
  </td>
</tr>
<tr> 
  <td class=rowtitle>[_ intranet-translation.Task_Name]</td>
  <td class=rowtitle>[_ intranet-translation.Units]</td>
  <td class=rowtitle>[im_gif open "Upload files"]</td>
</tr>

$task_table_rows

</table>
</form>\n"

    return $task_table
}


# -------------------------------------------------------------------
# New Tasks Component
# -------------------------------------------------------------------

ad_proc im_new_task_component { user_id project_id return_url } {
    Return a piece of HTML to allow to add new tasks
} {

    if {![im_permission $user_id view_trans_proj_detail]} { return "" }

    set bgcolor(0) " class=roweven"
    set bgcolor(1) " class=rowodd"

    # --------- Get a list of files "source_xx_XX" dir---------------
    # $file_list is a sorted list of all files in "source_xx_XX":
    set task_list [list]

    # Get the sorted list of files in the directory
    set files [lsort [im_filestorage_find_files $project_id]]

    set project_path [im_filestorage_project_path $project_id]
    set org_paths [split $project_path "/"]
    set org_paths_len [llength $org_paths]
    set start_index $org_paths_len

    foreach file $files {

	# Get the basic information about a file
	ns_log Notice "file=$file"
	set file_paths [split $file "/"]
	set file_paths_len [llength $file_paths]
	set body_index [expr $file_paths_len - 1]
	set file_body [lindex $file_paths $body_index]

	# The first folder of the project - contains access perms
	set top_folder [lindex $file_paths $start_index]
	ns_log Notice "top_folder=$top_folder"

	# Check if it is the toplevel directory
	if {[string equal $file $project_path]} { 
	    # Skip the path itself
	    continue 
	}

	# determine the part of the filename _after_ the base path
	set end_path ""
	for {set i [expr $start_index+1]} {$i < $file_paths_len} {incr i} {
	    append end_path [lindex $file_paths $i]
	    if {$i < [expr $file_paths_len - 1]} { append end_path "/" }
	}
	
	# add "source_xx_XX" folder contents to file_list
	if {[regexp source $top_folder]} {
	    # append twice: for right and left side of select box
	    lappend task_list $end_path
	    lappend task_list $end_path
	}
    }

    set ctr 0

    # -------------------- Add subheader for New Task  --------------------------
    set task_table "
<table border=0>
<tr>
  <td colspan=1 class=rowtitle align=center>
    [_ intranet-translation.Add_a_New_Task]
  </td>
  <td class=rowtitle align=center>
    [_ intranet-translation.Help]
  </td>
</tr>
"

    # -------------------- Add an Asp Wordcount -----------------------

    if {[ad_parameter -package_id [im_package_translation_id] EnableAspTradosImport "" 0]} {
	append task_table "
<tr $bgcolor(0)> 
  <td>
    <form enctype=multipart/form-data method=POST action=/intranet-translation/trans-tasks/trados-upload>
    [export_form_vars project_id return_url]
    <input type=file name=upload_file size=30 value='*.csv'>
    <input type=submit value='[_ intranet-translation.Add_Trados_Wordcount]' name=submit_trados>
    </form>
  </td>
  <td>
    [im_gif help "Use the 'Browse...' button to locate your file, then click 'Open'.\nThis file is used to define the tasks of the project, one task for each line of the wordcount file."]
  </td>
</tr>
"
    }


    # -------------------- Add an Intermediate Header -----------------------
    append task_table "
</table>
<table border=0>
<tr>
  <td class=rowtitle align=center>
    [_ intranet-translation.Task_Name]
  </td>
  <td class=rowtitle align=center>
    [_ intranet-translation.Units]
  </td>
  <td class=rowtitle align=center>
    [_ intranet-translation.UoM]
  </td>
  <td class=rowtitle align=center>
    [_ intranet-translation.Task_Type]
  </td>
  <td class=rowtitle align=center>
    [_ intranet-translation.Task_Action]
  </td>
</tr>
"


    # -------------------- Add a new File  --------------------------

    if {0 < [llength $task_list]} {
        append task_table "
<form action=/intranet-translation/trans-tasks/task-action method=POST>
[export_form_vars project_id return_url]
  <tr $bgcolor(0)> 

    <td>[im_select -translate_p 0 "task_name_file" $task_list]</td>
    <td><input type=text size=2 value=0 name=task_units_file></td>
    <td>[im_category_select "Intranet UoM" "task_uom_file" 324]</td>
    <td>[im_category_select "Intranet Project Type" task_type_file 86]</td>
    <td><input type=submit value=\"[_ intranet-translation.Add_File]\" name=submit_add_file></td>
    <td>[im_gif help "Add a new file to the list of tasks. \n New files need to be located in the \"source_xx\" folder to appear in the drop-down box on the left."]</td>
  </tr>
</form>
"
    }

    # -------------------- Add Task Manually --------------------------
    append task_table "
<form action=\"/intranet-translation/trans-tasks/task-action\" method=POST>
[export_form_vars project_id return_url]
  <tr $bgcolor(0)> 

    <td><input type=text size=20 value=\"\" name=task_name_manual></td>
    <td><input type=text size=2 value=0 name=task_units_manual></td>
    <td>[im_category_select "Intranet UoM" "task_uom_manual" 324]</td>
    <td>[im_category_select "Intranet Project Type" task_type_manual 86]</td>
    <td><input type=submit value=\"[_ intranet-translation.Add]\" name=submit_add_manual></td>
    <td>[im_gif help "Add a \"manual\" task to the project. \n This task is not going to controled by the translation workflow."]</td>
  </tr>
</form>"

    append task_table "
</table>
"
    return $task_table
}


# ---------------------------------------------------------------------
# Determine the list of missing files
# ---------------------------------------------------------------------

ad_proc im_task_missing_file_list { project_id } {
    Returns a list of task_ids that have not been found
    in the project folder.
    These task_ids can be used to display a list of 
    files that the user has to upload to make the project
    workflow work without problems.
    The algorithm works O(n*log(n)), using ns_set, so
    it should be a reasonably cheap operation.
} {
    set find_cmd [im_filestorage_find_cmd]

    set query "
select
        p.project_nr as project_short_name,
        c.company_name as company_short_name,
        p.source_language_id,
        im_category_from_id(p.source_language_id) as source_language,
        p.project_type_id
from
        im_projects p,
        im_companies c
where
        p.project_id=:project_id
        and p.company_id=c.company_id(+)"

    if { ![db_0or1row projects_info_query $query] } {
	ad_return_complaint 1 "[_ intranet-translation.lt_Cant_find_the_project]"
	return
    }

    # No source language defined yet - we can only return an empty list here
    if {"" == $source_language} {
	return ""
    }

    set project_path [im_filestorage_project_path $project_id]
    set source_folder "$project_path/source_$source_language"
    set org_paths [split $source_folder "/"]
    set org_paths_len [llength $org_paths]

    ns_log Notice "im_task_missing_file_list: source_folder=$source_folder"
    ns_log Notice "im_task_missing_file_list: org_paths=$org_paths"
    ns_log Notice "im_task_missing_file_list: org_paths_len=$org_paths_len"
    
    if { [catch {
	set find_cmd [im_filestorage_find_cmd]
	set file_list [exec $find_cmd $source_folder -type f]
    } err_msg] } {
	# The directory probably doesn't exist yet, so don't generate
	# an error !!!
	ad_return_complaint 1 "im_task_missing_file_list: directory $source_folder<br>
                       probably does not exist:<br>$err_msg"
	set file_list ""
    }

    # Get the sorted list of files in the directory
    set files [split $file_list "\n"]
    set file_set [ns_set create]

    foreach file $files {

	# Get the basic information about a file
	set file_paths [split $file "/"]
	set len [expr [llength $file_paths] - 1]
	set file_comps [lrange $file_paths $org_paths_len $len]
	set file_name [join $file_comps "/"]

	# Check if it is the toplevel directory
	if {[string equal $file $project_path]} { 
	    # Skip the path itself
	    continue 
	}

	ns_set put $file_set $file_name $file_name
	ns_log Notice "im_task_missing_file_list: file_name=$file_name"
    }

    # We've got now a list of all files in the source folder.
    # Let's go now through all the im_trans_tasks of this project and
    # check if the filename present in the $file_list
    # Attention!, this is an n^2 algorithm!
    # Any ideas how to speed this up?

    set task_sql "
select
	task_id,
	task_name,
	task_filename
from
	im_trans_tasks t
where
	t.project_id = :project_id
"

    set missing_file_list [list]
    db_foreach im_task_list $task_sql {

	if {"" != $task_filename} {
	    set res [ns_set get $file_set $task_filename]
	    if {"" == $res} {
		# We haven't found the file
		lappend missing_file_list $task_id
	    }
	}

    }

    ns_set free $file_set
    return $missing_file_list
}


