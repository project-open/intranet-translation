# /packages/intranet-translation/projects/edit-customer-data-2.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Purpose: verifies and stores project information to db

    @param return_url the url to return to
    @param project_id group id
} {
    project_id:integer
    customer_project_nr
    final_customer
    customer_contact_id:integer 
    expected_quality_id:integer,optional
    source_language_id:integer
    target_language_ids:multiple,optional
    subject_area_id:integer
    expected_quality_id:integer
    submit_subprojects:optional
    return_url
}

set user_id [ad_maybe_redirect_for_registration]

# Allow for empty target languages(?)
if {![info exists target_language_ids]} {
    set target_language_ids [list]
}


set sql "
update im_projects set
"
if {[exists_and_not_null final_customer]} {
    append sql "final_customer=:final_customer,\n"
}
if {[exists_and_not_null customer_project_nr]} {
    append sql "customer_project_nr=:customer_project_nr,\n"
}
if {[exists_and_not_null customer_contact_id]} {
    append sql "customer_contact_id=:customer_contact_id,\n"
}
if {[exists_and_not_null expected_quality_id]} {
    append sql "expected_quality_id=:expected_quality_id,\n"
}
if {[exists_and_not_null subject_area_id]} {
    append sql "subject_area_id=:subject_area_id,\n"
}
if {[exists_and_not_null source_language_id]} {
    append sql "source_language_id=:source_language_id,\n"
}

append sql "project_id=:project_id
where project_id=:project_id
"

db_transaction {
    db_dml update_im_projects $sql
}
db_release_unused_handles

if { ![exists_and_not_null return_url] } {
    set return_url "[im_url_stub]/projects/view?[export_url_vars project_id]"
}


# Save the information about the project target languages
# in the im_target_languages table
#
db_transaction {
    db_dml delete_im_target_language "delete from im_target_languages where project_id=:project_id"
    
    foreach lang $target_language_ids {
	ns_log Notice "target_language=$lang"
	set sql "insert into im_target_languages values ($project_id, $lang)"
        db_dml insert_im_target_language $sql
    }
}


# ---------------------------------------------------------------------
# Create the directory structure necessary for the project
# ---------------------------------------------------------------------

set create_err ""
set err_msg ""
if { [catch {
    set create_err [im_filestorage_create_directories $project_id]
} err_msg] } {
    # Nothing - Filestorage may not be enabled...
}
ns_log Notice "/project/edit-trans-data-2: err_msg=$err_msg"
ns_log Notice "/project/edit-trans-data-2: create_err=$create_err"

if {"" != $create_err || "" != $err_msg} {
    ad_return_complaint 1 "<li>err_msg: $err_msg<br>create_err: $create_err<br>"
    return
}



# ---------------------------------------------------------------------
# Create Subprojects - one for each language
# - Create subprojects with a name = "$project_name - $lang"
# - Copy the contents of the project filestorage to the
#   subprojects
# ---------------------------------------------------------------------

db_1row project_info "
select
	*
from
	im_projects
where
	project_id=:project_id
"


if {[exists_and_not_null submit_subprojects]} {
    
    foreach lang $target_language_ids {
	set lang_name [db_string get_language "select category from im_categories where category_id=:lang"]

        ns_log Notice "target_language=$lang_name"
	set sub_project_name "${project_name} - $lang_name"
	set sub_project_nr "${project_nr}_$lang_name"
	set sub_project_path "${project_path}_$lang_name"

	# -------------------------------------------
	# Create a new Project if it didn't exist yet
	set sub_project_id [db_string sub_project_id "select project_id from im_projects where project_nr=:sub_project_nr" -default 0]
	if {!$sub_project_id} {

	    set sub_project_id [project::new \
        -project_name           $sub_project_name \
        -project_nr             $sub_project_nr \
        -project_path           $sub_project_path \
        -customer_id            $customer_id \
        -parent_id              $project_id \
        -project_type_id        $project_type_id \
	-project_status_id      $project_status_id]

	    # add users to the project as PMs (1301):
	    # - current_user (creator/owner)
	    # - project_leader
	    # - supervisor
	    set role_id 1301
	    im_biz_object_add_role $user_id $sub_project_id $role_id
	    if {"" != $project_lead_id} {
		im_biz_object_add_role $project_lead_id $sub_project_id $role_id
	    }
	    if {"" != $supervisor_id} {
		im_biz_object_add_role $supervisor_id $sub_project_id $role_id
	    }
	}

	# -----------------------------------------------------------------
	# Update the Project

	set project_update_sql "
update im_projects set
        requires_report_p =	:requires_report_p,
	parent_id =		:project_id,
	project_status_id =	:project_status_id,
	source_language_id = 	:source_language_id,
	subject_area_id = 	:subject_area_id,
	expected_quality_id =	:expected_quality_id,
        start_date =    	:start_date,
        end_date =      	:end_date
where
        project_id = :sub_project_id"

	db_dml project_update $project_update_sql


	# -----------------------------------------------------------------
	# Set the target language of the subproject
	db_dml delete_target_languages "delete from im_target_languages where project_id=:sub_project_id"
	db_dml set_target_language "
		insert into im_target_languages
		(project_id, language_id) values
		(:sub_project_id, :lang)
	"	


    }
}

ad_returnredirect $return_url
