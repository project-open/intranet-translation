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
    return_url
    project_id:integer
    customer_project_nr
    final_customer
    customer_contact_id:integer 
    expected_quality_id:integer,optional
    source_language_id:integer
    target_language_ids:multiple
    subject_area_id:integer
    expected_quality_id:integer
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
# Now create the directory structure necessary for the project
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


ad_returnredirect $return_url

