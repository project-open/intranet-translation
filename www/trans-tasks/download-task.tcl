# /file-storage/download-task.tcl

ad_page_contract {
    See if this person is authorized to read the task file,
    guess the MIME type from the original client filename and
    write the binary file to the connection

    @author fraber@fraber.de
    @creation-date 030910
} {
    project_id:integer
    task_id:integer
    return_url
}  -errors {
    project_id:integer {The project_id specified doesn't look like an integer.}
    task_id:integer {The task_id specified doesn't look like an integer.}
}

set user_id [ad_maybe_redirect_for_registration]

set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set user_is_group_admin_p [im_can_user_administer_group $project_id $user_id]
set user_is_employee_p [im_user_is_employee_p $user_id]
set user_admin_p [expr $user_is_admin_p || $user_is_group_admin_p]

set project_path [im_filestorage_project_path $project_id]

# get everything about the specified task
set task_sql "
select
	t.*,
	im_category_from_id(t.source_language_id) as source_language,
	im_category_from_id(t.target_language_id) as target_language
from
	im_tasks t
where
	t.task_id = :task_id
	and t.project_id = :project_id"

if {![db_0or1row task_info_query $task_sql] } {
    ad_return_complaint 1 "<li>Couldn't find the specified task #$task_id"
    return
}

set upload_list [im_task_component_upload $user_id $user_admin_p $task_status_id $source_language $target_language $trans_id $edit_id $proof_id $other_id]
set upload [lindex $upload_list 0]
set folder [lindex $upload_list 1]

# Allow to download the file if the user is an admin, a project admin
# or an employee of the company. Or if the user is an translator, editor,
# proofer or "other" of the specified task.
set allow 0
if {$user_admin_p} { set allow 1}
if {$user_is_employee_p} { set allow 1}
if {$upload == 2} {set allow 1}

if {!$allow} {
    ad_return_complaint 1 "<li>You have insufficient access rights to download this file."
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
	update im_tasks 
	set task_status_id=(task_status_id+2) 
	where task_id=1458
    "

    rp_serve_concrete_file $file
} else {
    ad_return_complaint 1 "<li>The specified file $file is not available."
}
