# /packages/intranet-translation/www/trans-tasks/upload-task.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Serve the user a form to upload a new file or URL

    @author frank.bergmann@project-open.com
    @creation-date 030909
} {
    project_id:integer
    task_id:integer
    return_url
}

set user_id [ad_maybe_redirect_for_registration]
set page_title "[_ intranet-translation.Upload_New_FileURL]"
set current_url [im_url_with_query]

set context_bar [im_context_bar [list "/intranet/projects/" "[_ intranet-translation.Projects]"]  [list "/intranet/projects/view?group_id=$project_id" "[_ intranet-translation.One_Project]"]  "[_ intranet-translation.Upload_File]"]

set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"

set filename [db_string get_filename "select task_name from im_trans_tasks where task_id=:task_id" -default ""]

# ---------------------------------------------------------------
# Notify the PM?
# ---------------------------------------------------------------

set default_notify_pm [ad_parameter -package_id [im_package_translation_id] DefaultNotifyPMAboutUploadP "" 0]
set notify_pm_checked ""
if {$default_notify_pm} { set notify_pm_checked " checked" }


# ---------------------------------------------------------------
# Notify next WF stage
# ---------------------------------------------------------------

# Shoud the translator notifiy the editor when he uploads a file?
set notify_next_wf_stage_p [ad_parameter -package_id [im_package_translation_id] NotifyNextWfStageP "" 0]
set notify_next_wf_stage_checked " checked"

set next_role_l10n [im_task_next_workflow_role $task_id]
set next_wf_stage_user_id [im_task_next_workflow_stage_user $task_id]


# ---------------------------------------------------------------
# Check if the user can rate the previous translator in the chain
# ---------------------------------------------------------------

set survey_exists_p [llength [info commands im_package_survsimp_id]]
set previous_wf_role [im_task_previous_workflow_role $task_id]
set previous_user_id [im_task_previous_workflow_stage_user $task_id]
regsub { } $previous_wf_role "_" previous_wf_role_mangled
set previous_wf_role_mangled [string tolower $previous_wf_role_mangled]

set survey_id 0
set previous_wf_stage_user_id 0

if {$survey_exists_p} {
    set survey_no [db_list trans_survey_no "
        select  count(*) from survsimp_surveys
    "]
}

if {$survey_exists_p && $previous_user_id != 0 && $survey_no != 0} {
    # Check if there is a survey associated with the specific stage
    set previous_role [im_task_previous_workflow_role $task_id]
    set previous_wf_stage_user_id [im_task_previous_workflow_stage_user $task_id]
    set survey_base_name [ad_parameter -package_id [im_package_translation_id] TranslationWorkflowSurveyBaseName "" "Translation Workflow Rating:"]
    set survey_name "$survey_base_name $previous_role"
    
    set survey_ids [db_list trans_survey "
	select	survey_id
	from	survsimp_surveys
	where	name = :survey_name
    "]
	
    if {[llength $survey_ids] == 1} {
	# Get the one and only survey found
	set survey_id [lindex $survey_ids 0]
    }

    # Check if there is already a survey for this project + Translator
    set exists_p [db_string survey_exists "
	select	count(*)
	from	survsimp_responses
	where	
		survey_id = :survey_id and
		related_object_id = :previous_wf_stage_user_id and
		related_context_id = :task_id
    "]

    # Only redirect if the survey doesn't exist yet.
    # Otherwise we'll get an infinite redirection loop
    if {!$exists_p} {
	set survey_url [export_vars -base "/simple-survey/one" {{return_url $current_url} survey_id project_id provider_id {related_object_id $previous_wf_stage_user_id} {related_context_id $task_id}}]
	ad_returnredirect $survey_url
    }

}

# ---------------------------------------------------------------
# Render the form
# ---------------------------------------------------------------

set page_content "
<form enctype=multipart/form-data method=POST action=upload-task-2.tcl>
[export_form_vars project_id task_id return_url]

                    <table border=0>
                      <tr> 
                        <td class=rowtitle align=center colspan=2>Upload a file</td>
                      </tr>
                      <tr $bgcolor(0)> 
                        <td align=right>[_ intranet-translation.Filename] </td>
                        <td>$filename</td>
                      </tr>
                      <tr $bgcolor(1)> 
                        <td align=right>[_ intranet-translation.File] </td>
                        <td>
                          <input type=file name=upload_file size=30>
                          [im_gif help "[_ intranet-translation.lt_Use_the_Browse_button]"]
                        </td>
                      </tr>
                      <tr $bgcolor(0)> 
                        <td valign=top align=right>
			[lang::message::lookup "" intranet-core.Comment "Comment"]
			<br>
			[_ intranet-translation.optional]
                        </td>
                        <td colspan=1>
                          <textarea rows=5 cols=50 name=comment_body wrap></textarea>
			  <br>Please let us know what you think about this task (max. 1000 characters).
                        </td>
                      </tr>

                      <tr $bgcolor(1)> 
                        <td align=right>[lang::message::lookup "" intranet-translation.Notify "Notify"] </td>
                        <td>
                          <input type=checkbox name=notify_project_manager_p value=1 $notify_pm_checked>
			  [lang::message::lookup "" intranet-translation.Send_Notification_to_PM "Send a notification to your Project Manager"]
                        </td>
                      </tr>
"

if {$notify_next_wf_stage_p} {
    append page_content "
                      <tr $bgcolor(1)> 
                        <td align=right>[lang::message::lookup "" intranet-translation.Notify "Notify"] </td>
                        <td>
                          <input type=checkbox name=notify_next_wf_stage_p value=1 $notify_next_wf_stage_checked>
			  [lang::message::lookup "" intranet-translation.Send_Notification_to_Next_WF_Stage "Send a notification to your %next_role_l10n%"]
			  ($next_wf_stage_user_id)
                        </td>
                      </tr>
    "
}


set ctr 0

# Commented out. Now the survey is accessed via redirection
if {0 && $survey_id} {

    append page_content "
                      <tr $bgcolor([expr $ctr%2])> 
                        <td align=right>[lang::message::lookup "" intranet-translation.Rate_your_$previous_wf_role_mangled "Rate the<br>$previous_wf_role"]</td>
                        <td> 
			    <a href=\"$survey_url\" xxxtarget=\"survey\">$survey_name</a>
                        </td>
                      </tr>
    "
    incr ctr
}

append page_content "
                      <tr $bgcolor([expr $ctr%2])> 
                        <td></td>
                        <td> 
                          <input type=submit value='[_ intranet-translation.Submit_and_Upload]'><br>
                        </td>
                      </tr>
                    </table>
<table width=70%>
<tr><td>
<blockquote>
[_ intranet-translation.lt_This_page_may_take_se]
</blockquote>
</td></tr>
</table>

</form>
"


set project_menu ""
if {0 != $project_id} {
    set menu_label "project_summary"
    set bind_vars [ns_set create]
    ns_set put $bind_vars project_id $project_id
    set parent_menu_id [db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]
    set project_menu [im_sub_navbar $parent_menu_id $bind_vars "" "pagedesriptionbar" $menu_label]
}
