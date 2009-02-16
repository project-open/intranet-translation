# /packages/intranet-translation/www/trans-tasks/download-task.tcl
#
# Copyright (C) 2004 - 2009 ]project-open[
#
# All rights reserved (this is not GPLed software!).
# Please check http://www.project-open.com/ for licensing
# details.

ad_page_contract {
    See if this person is authorized to read the task file,
    guess the MIME type from the original client filename and
    write the binary file to the connection

    @author frank.bergmann@project-open.com
    @creation-date 030910
} {
    project_id:integer
    task_id:integer
    return_url
}  -errors {
    project_id:integer "[_ intranet-translation.lt_The_project_id_specif]"
    task_id:integer "[_ intranet-translation.lt_The_task_id_specified]"
}

set user_id [ad_maybe_redirect_for_registration]
set project_path [im_filestorage_project_path $project_id]

# get everything about the specified task
set task_sql "
select
	t.*,
	im_category_from_id(t.source_language_id) as source_language,
	im_category_from_id(t.target_language_id) as target_language
from
	im_trans_tasks t
where
	t.task_id = :task_id
	and t.project_id = :project_id"

if {![db_0or1row task_info_query $task_sql] } {
    ad_return_complaint 1 "<li>[_ intranet-translation.lt_Couldnt_find_the_spec]"
    return
}

# Get the overall permissions
im_translation_task_permissions $user_id $task_id view read write admin

set upload_list [im_task_component_upload $user_id $admin $task_status_id $source_language $target_language $trans_id $edit_id $proof_id $other_id]
set upload [lindex $upload_list 0]
set folder [lindex $upload_list 1]

if {!$read} {
    ad_return_complaint 1 "<li>[_ intranet-translation.lt_You_have_insufficient_1]"
    return
}

# Dangerous!?!

set file_name $task_name

set file "$project_path/$folder/$file_name"

ns_log notice "file_name=$file_name"
ns_log notice "file=$file"

if [file readable $file] {

    # Update the task to advance to the next status
    # Take advantage that from a "for Xxxx" to "Xxxxx-ing" status
    # there is a difference of 2 in the task_status_id. Ugly but fast!
    db_dml upate_task "
	update im_trans_tasks 
	set task_status_id=(task_status_id+2) 
	where task_id=1458
    "

    rp_serve_concrete_file $file
} else {
    ad_return_complaint 1 "<li>[_ intranet-translation.lt_The_specified_file_fi]"
}
