# /packages/intranet-translation/www/upload-task-2.tcl
#
# Copyright (C) 2004 - 2009 ]project-open[
#
# All rights reserved (this is not GPLed software!).
# Please check http://www.project-open.com/ for licensing
# details.

ad_page_contract {
    insert a file into the file system
} {
    project_id:integer
    task_id:integer
    return_url
    upload_file
    {notify_project_manager_p ""}
    {notify_next_wf_stage_p ""}
    {file_title:trim ""}
    {comment_body:trim "" }
}

# ---------------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set project_path [im_filestorage_project_path $project_id]

set page_title "[_ intranet-translation.Upload_Successful]"
# Set the context bar as a function on whether this is a subproject or not:
if {[im_permission $user_id view_projects]} {
    set context_bar [im_context_bar [list /intranet/projects/ "[_ intranet-translation.Projects]"] [list "/intranet/projects/view?group_id=$project_id" "[_ intranet-translation.One_project]"] $page_title]
} else {
    set context_bar [im_context_bar [list /intranet/projects/ "[_ intranet-translation.Projects]"] $page_title]
}

# ---------------------------------------------------------------------
# SQL
# ---------------------------------------------------------------------

# get everything about the specified task
set task_sql "
select
	t.*,
	p.project_name,
	p.project_nr,
	im_category_from_id(t.task_status_id) as task_status,
	im_category_from_id(t.source_language_id) as source_language,
	im_category_from_id(t.target_language_id) as target_language
from
	im_trans_tasks t,
	im_projects p
where
	t.task_id=:task_id
	and t.project_id = p.project_id 
	and p.project_id = :project_id"

# ProjectURL
set system_url [ad_parameter -package_id [ad_acs_kernel_id] SystemURL ""]
set project_rel_url [db_string p_url "select url from im_biz_object_urls where object_type = 'im_project' and url_type = 'display'" -default "/intranet/projects/view?project_id="]
if {[regexp {^\/(.*)$} $project_rel_url match rest]} { set project_rel_url $rest }
set project_url "$system_url$project_rel_url$project_id"

if {![db_0or1row task_info_query $task_sql] } {
    ad_return_complaint 1 "<li>[_ intranet-translation.lt_Couldnt_find_the_spec]"
    return
}

# Get the overall permissions
im_translation_task_permissions $user_id $task_id view read write admin

# Check for permissions according to the im_trans_tasks state engine:
# Check if the user is a freelance who is allowed to
# upload a file for this task, depending on the task
# status (engine) and the assignment to a specific phase.
#
set upload_list [im_task_component_upload $user_id $admin $task_status_id $source_language $target_language $trans_id $edit_id $proof_id $other_id]
set download_folder [lindex $upload_list 0]
set upload_folder [lindex $upload_list 1]
if {"" == $upload_folder} {
    ad_return_complaint 1 "
	<li>[_ intranet-translation.lt_You_are_not_allowed_t]"
    return
}


# -----------------------------------------------------------------
# Notify the Project Manager(s) about the upload
# -----------------------------------------------------------------

if {"" != $notify_project_manager_p} {

    set subject [lang::message::lookup "" intranet-translation.Notify_PM_About_Task_Upload_Subject]
    set message [lang::message::lookup "" intranet-translation.Notify_PM_About_Task_Upload_Message]

    set project_managers_sql "
	select
		r.object_id_two as pm_id
	from
		acs_rels r,
		im_biz_object_members m
	where
		r.rel_id = m.rel_id
		and r.object_id_one = :project_id
		and m.object_role_id = [im_biz_object_role_project_manager]
    UNION
	select	project_lead_id
	from	im_projects p
	where	project_id = :project_id
    "

    set project_url [export_vars -base "/intranet/projects/view" {project_id}]

    db_foreach notify_project_managers $project_managers_sql {
        set auto_login [im_generate_auto_login -user_id $pm_id]
        set msg_url "[ad_parameter -package_id [ad_acs_kernel_id] SystemURL "" ""][export_vars -base "intranet/auto-login" {{user_id $pm_id} {url $project_url} {auto_login $auto_login}}]"

        im_send_alert $pm_id "hourly" $subject "$msg_url\n$message"
    }
}

if {"" != $notify_next_wf_stage_p} {

    set subject [lang::message::lookup "" intranet-translation.Notify_Next_WF_Stage_About_Task_Upload_Subject "A New Task has Become Ready: $task_name"]
    set message [lang::message::lookup "" intranet-translation.Notify_Next_WF_Stage_About_Task_Upload_Message "A new task has become ready for you in project %project_nr% - %project_name%."]

    set next_wf_stage_user_id [im_task_next_workflow_stage_user $task_id]
    set project_url [export_vars -base "/intranet/projects/view" {project_id}]

    set auto_login [im_generate_auto_login -user_id $next_wf_stage_user_id]
    set msg_url "[ad_parameter -package_id [ad_acs_kernel_id] SystemURL "" ""][export_vars -base "intranet/auto-login" {{user_id $next_wf_stage_user_id} {url $project_url} {auto_login $auto_login}}]"

    im_send_alert $next_wf_stage_user_id "hourly" $subject "$msg_url\n$message"

}


# -------------------------------------------------------------------
# Get the file from the user.
# number_of_bytes is the upper-limit
# -------------------------------------------------------------------

set max_n_bytes [ad_parameter -package_id [im_package_filestorage_id] MaxNumberOfBytes "" 0]
set tmp_filename [ns_queryget upload_file.tmpfile]
im_security_alert_check_tmpnam -location "trados-task-2.tcl" -value $tmp_filename
set filesize [file size $tmp_filename]

if { $max_n_bytes && ($filesize > $max_n_bytes) } {
    set util_commify_number_max_n_bytes [util_commify_number $max_n_bytes]
    ad_return_complaint 1 "[_ intranet-translation.lt_Your_file_is_larger_t_1]"
    return 0
}

# -------------------------------------------------------------------
# Check the the $upload_file is the same filename as the $task_name
# -------------------------------------------------------------------

ns_log Notice "upload_file=$upload_file"
ns_log Notice "task_name=$task_name"

set upload_file_pathes [split $upload_file "\\"]
set upload_file_len [expr [llength $upload_file_pathes]-1]
set task_name_pathes [split $task_name "/"]
set task_name_len [expr [llength $task_name_pathes]-1]

set upload_file_body [lindex $upload_file_pathes $upload_file_len]
set task_name_body [lindex $task_name_pathes $task_name_len]

ns_log Notice "upload_file_body=$upload_file_body"
ns_log Notice "task_name_body=$task_name_body"


# Check that filenames coincide to avoid translators errors
#
set check_filename_equal_p [ad_parameter -package_id [im_package_translation_id] CheckTaskUploadFilenamesEqualP "" 1]
if {$check_filename_equal_p} {

    # Filenames should be exactly equal
    if {![string equal $upload_file_body $task_name_body]} {
	set error "<li>[_ intranet-translation.lt_Your_file_doesnt_coin]<br>
	    [_ intranet-translation.lt_Your_file_upload_file]<br>
	    [_ intranet-translation.lt_Expected_file_task_na]<br>
	    [_ intranet-translation.lt_Please_check_your_inp]"
        ad_return_complaint "[_ intranet-translation.User_Error]" $error
        return
    }

} else {

    # Filenames can differ, but the extension should be the same
    # so that a translator cant upload a ".doc" file if the task
    # consisted of a ".zip" file:

    set upload_parts [split $upload_file_body "."]
    set upload_ext [string tolower [lindex $upload_parts [expr [llength $upload_parts] - 1]]]

    set task_parts [split $task_name_body "."]
    set task_ext [string tolower [lindex $task_parts [expr [llength $task_parts] - 1]]]

    # Check if extensions are equal
    set check_extensions_equal_p [ad_parameter -package_id [im_package_translation_id] CheckTaskUploadFileExtensionsEqualP "" 0]

    if {![string equal $upload_ext $task_ext] && $check_extensions_equal_p} {
	set error "<li>
	    [lang::message::lookup "" intranet-translation.File_extensions_dont_match "Your file extensions don't match.:"]<br>
	    [_ intranet-translation.lt_Your_file_upload_file]<br>
	    [_ intranet-translation.lt_Expected_file_task_na]<br>
	    [_ intranet-translation.lt_Please_check_your_inp]"
        ad_return_complaint "[_ intranet-translation.User_Error]" $error
        return
    }

}

# -------------------------------------------------------------------
# Let's copy the file into the FS
# -------------------------------------------------------------------


set path "$project_path/$upload_folder"
if {![file isdirectory $path]} {
    if { [catch {
            ns_log Notice "/bin/mkdir $path"
            exec /bin/mkdir "$path"
    } err_msg] } {
            # Probably some permission errors
	ad_return_complaint "[_ intranet-translation.lt_Error_creating_subfol]" $err_msg
            return
    }
}


# First make sure that subdirectories exist
set subfolders [split $task_name "/"]
set subfolder_len [expr [llength $subfolders]-1]
set subfolder_path ""
for {set i 0} {$i < $subfolder_len} {incr i} {
    set subfolder [lindex $subfolders $i]
    append subfolder_path "$subfolder/"

    set path "$project_path/$upload_folder/$subfolder_path"
    ns_log Notice "upload-tasks-2.tcl: path=$path"

    if {![file isdirectory $path]} {
	if { [catch {
	    ns_log Notice "/bin/mkdir $path"
	    exec /bin/mkdir "$path"
	} err_msg] } {
	    # Probably some permission errors
	    ad_return_complaint "[_ intranet-translation.lt_Error_creating_subfol]" $err_msg
	    return
	}
    }
}


# Move the file
#
if { [catch {
    ns_log Notice "/bin/mv $tmp_filename $project_path/$upload_folder/$upload_file_body"
    exec /bin/cp $tmp_filename "$project_path/$upload_folder/$upload_file_body"
    ns_log Notice "/bin/chmod ug+w $project_path/$upload_folder/$upload_file_body"
    exec /bin/chmod ug+w $project_path/$upload_folder/$upload_file_body

} err_msg] } {
    # Probably some permission errors
    ad_return_complaint 1 "[_ intranet-translation.lt_Error_writing_upload_]:<br>
	<pre>$err_msg</pre>during command:
	<pre>exec /bin/cp $tmp_filename $project_path/$upload_folder/$upload_file_body</pre>
    "
    return
}

# Advance the status of the respective im_task.
#
im_trans_upload_action -upload_file $upload_file_body $task_id $task_status_id $task_type_id $user_id


# -----------------------------------------------------------------
# Create an Forum Topic if there was atleast a subject
# -----------------------------------------------------------------

set upload_html ""
set comment_html ""

if {"" != $comment_body} {

    set topic_id [db_nextval "im_forum_topics_seq"]
    set parent_id ""
    set owner_id $user_id
    # This comment is only visible to members of the company
    set scope "staff"
    set subject $upload_file_body
    set message "$comment_body"

    # Limit Subject and message to their field sizes
    set subject [string_truncate -len 200 $subject]
    set message [string_truncate -len 4000 $message]

    set priority 3

    # 1102 is "Incident"
    # 1108 is "Note"
    set topic_type_id 1108
    
    # 1202 is "Open"
    set topic_status_id 1202


    db_transaction {

        db_dml topic_insert "
	INSERT INTO im_forum_topics (
	        topic_id, object_id, parent_id, topic_type_id, topic_status_id,
	        posting_date, owner_id, scope, subject, message, priority,
	        asignee_id, due_date
	) VALUES (
	        :topic_id, :project_id, :parent_id, :topic_type_id, :topic_status_id,
	        now(), :owner_id, :scope, :subject, :message, null,
	        null, null
	)"

    } on_error {
	ad_return_error "Error adding a new topic" "
        <LI>There was an error adding your ticket to our system.<br>
        Please send an email to <A href=\"mailto:[ad_parameter "SystemOwner" "" ""]\">
        our webmaster</a>, thanks."
    }

    set comment_html "<p>[lang::message::lookup "" intranet-translation.Your_comment_has_been_accepted "Your comment is appreciated.."]</p>"
}


