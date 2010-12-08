# /packages/intranet-translation/projects/edit-trans-data-2.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Purpose: verifies and stores project information to db

    @param return_url the url to return to
    @param project_id group id
} {
    project_id:integer
    company_project_nr
    final_company
    company_contact_id:integer 
    expected_quality_id:integer,optional
    source_language_id:integer
    target_language_ids:multiple,optional
    subject_area_id:integer
    expected_quality_id:integer
    submit_subprojects:optional
    return_url
}

# ---------------------------------------------------------------------
# Permissions
# ---------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]

# get the current users permissions for this project
im_project_permissions $user_id $project_id view read write admin

if {!$write} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_6]"
    return
}

# ---------------------------------------------------------------------
# Defaults & Checks
# ---------------------------------------------------------------------

# Allow for empty target languages(?)
if {![info exists target_language_ids]} {
    set target_language_ids [list]
}

set fs_installed_p [im_table_exists im_fs_folders]

# ---------------------------------------------------------------------
# 
# ---------------------------------------------------------------------

set sql "
update im_projects set
"
if {[info exists final_company]} {
    append sql "final_company=:final_company,\n"
}
if {[info exists company_project_nr]} {
    append sql "company_project_nr=:company_project_nr,\n"
}
if {[info exists company_contact_id]} {
    append sql "company_contact_id=:company_contact_id,\n"
}
if {[info exists expected_quality_id]} {
    append sql "expected_quality_id=:expected_quality_id,\n"
}
if {[info exists subject_area_id]} {
    append sql "subject_area_id=:subject_area_id,\n"
}
if {[info exists source_language_id]} {
    append sql "source_language_id=:source_language_id,\n"
}

append sql "project_id=:project_id
where project_id=:project_id
"

db_transaction {
    db_dml update_im_projects $sql
}

if { ![exists_and_not_null return_url] } {
    set return_url "[im_url_stub]/projects/view?[export_url_vars project_id]"
}

# Write audit trail
im_project_audit -project_id $project_id


# Write the source + target language and subject area to freelance skills
if {[im_table_exists im_freelancers]} {
    im_freelance_add_required_skills -object_id $project_id -skill_type_id [im_freelance_skill_type_source_language] -skill_ids $source_language_id
    im_freelance_add_required_skills -object_id $project_id -skill_type_id [im_freelance_skill_type_subject_area] -skill_ids $subject_area_id
    im_freelance_add_required_skills -object_id $project_id -skill_type_id [im_freelance_skill_type_expected_quality] -skill_ids $expected_quality_id
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

	if {[im_table_exists im_freelancers]} {
	    im_freelance_add_required_skills -object_id $project_id -skill_type_id [im_freelance_skill_type_target_language] -skill_ids $lang
	}
    }
}


# ---------------------------------------------------------------------
# Create the directory structure necessary for the project
# ---------------------------------------------------------------------

# If the filestorage module is installed...
if {$fs_installed_p} {

	set create_err ""
	if { [catch {
	    set create_err [im_filestorage_create_directories $project_id]
	} err_msg] } {
	    ad_return_complaint 1 "<li>err_msg: $err_msg<br>create_err: $create_err<br>"
	    return
	}
	
    }

# ---------------------------------------------------------------------
# Create Subprojects - one for each language
# - Create subprojects with a name = "$project_name - $lang"
# - Copy the contents of the project filestorage to the
#   subprojects
# ---------------------------------------------------------------------

db_1row project_info "
	select	*
	from	im_projects
	where	project_id=:project_id
"


if {[exists_and_not_null submit_subprojects]} {
    
    foreach lang $target_language_ids {

	set lang_name [db_string get_language "
		select category 
		from im_categories 
		where category_id=:lang
	"]

        ns_log Notice "target_language=$lang_name"
	set sub_project_name "${project_name} - $lang_name"
	set sub_project_nr "${project_nr}_$lang_name"
	set sub_project_path "${project_path}_$lang_name"

	# -------------------------------------------
	# Create a new Project if it didn't exist yet
	set sub_project_id [db_string sub_project_id "
		select project_id 
		from im_projects 
		where project_nr=:sub_project_nr
	" -default 0]

	if {!$sub_project_id} {

	    set sub_project_id [project::new \
	        -project_name           $sub_project_name \
	        -project_nr             $sub_project_nr \
	        -project_path           $sub_project_path \
	        -company_id            $company_id \
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
		        project_id = :sub_project_id
	"
	db_dml project_update $project_update_sql

	# Write audit trail
	catch { im_project_audit $sub_project_id} err_msg

	# Write the source + target language and subject area to freelance skills
	if {[im_table_exists im_freelancers]} {
	    im_freelance_add_required_skills -object_id $sub_project_id -skill_type_id [im_freelance_skill_type_source_language] -skill_ids $source_language_id
	    im_freelance_add_required_skills -object_id $sub_project_id -skill_type_id [im_freelance_skill_type_target_language] -skill_ids $lang
	    im_freelance_add_required_skills -object_id $sub_project_id -skill_type_id [im_freelance_skill_type_subject_area] -skill_ids $subject_area_id
	    im_freelance_add_required_skills -object_id $sub_project_id -skill_type_id [im_freelance_skill_type_expected_quality] -skill_ids $expected_quality_id
	}

	# -----------------------------------------------------------------
	# Add main project's members to the subproject
	set main_project_members_sql "
		select	p.person_id,
			m.object_role_id
		from	acs_rels r,
			im_biz_object_members m,
			persons p
		where	r.object_id_two = p.person_id
			and r.rel_id = m.rel_id
			and r.object_id_one = :project_id
	"
	db_foreach main_project_members $main_project_members_sql {
	    im_biz_object_add_role -propagate_superproject_p 0 $person_id $sub_project_id $object_role_id
	}


	# -----------------------------------------------------------------
	# Set the target language of the subproject
	db_dml delete_target_languages "
		delete from im_target_languages 
		where project_id=:sub_project_id
	"
	db_dml set_target_language "
		insert into im_target_languages
		(project_id, language_id) values
		(:sub_project_id, :lang)
	"	

	# -----------------------------------------------------------------
	# Create Folder structure for the new project
	set err_msg ""
	if { [catch {
	    set err_msg [im_filestorage_create_directories $sub_project_id]
	} err_msg] } {
	    #
	}
	if {"" != $err_msg} {

	    ad_return_complaint 1 "<li>Unable to create folder structure for subproject: 
	    <pre>$err_msg</pre>"
	    return
	}	


	# -----------------------------------------------------------------
	# Copy files from the "source_xx" folder of the current
	# project to the target project
	if { [catch {
	    set err_msg [im_filestorage_copy_source_directory $project_id $sub_project_id]
	} err_msg] } {
	    # Pass-on err_msg
	}

	if {"" != $err_msg} {
	    ad_return_complaint 1 "<li>Unable to copy 'source'-folder: 
	    <pre>$err_msg</pre"
	    return
	}

    }


    # -----------------------------------------------------------------
    # Call the "project_update" user_exit

    im_user_exit_call project_update $project_id
    im_audit -object_type im_project -action after_update -object_id $project_id

}

ad_returnredirect $return_url

