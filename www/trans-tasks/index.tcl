# /www/intranet/trans-tasks/task-list.tcl

ad_page_contract {
    Show the list of current task and allow the project
    manager to create new tasks.

    @author fraber@project-open.com
    @creation-date Nov 2003
} {
    group_id:integer
}

set user_id [ad_maybe_redirect_for_registration]
set return_url [im_url_with_query]
set page_title "Project Tasks"
set context_bar [ad_context_bar [list /intranet/projects/ "Projects"] [list "/intranet/projects/view?group_id=$group_id" "One project"] $page_title]
set task_return_url "/intranet/trans-tasks/task-list?[export_url_vars group_id return_url]"

set missing_task_list [im_task_missing_file_list $group_id]

set page_body "
[im_task_component $user_id $group_id $return_url]
<A HREF=/intranet/projects/view?group_id=$group_id>Return to Project Page</A>
<p>
[im_new_task_component $user_id $group_id $return_url]
<br>

[im_task_status_component $user_id $group_id $task_return_url]

[im_task_error_component $user_id $group_id $user_admin_p $user_is_employee_p $return_url $missing_task_list]

<a href=task-trados?[export_url_vars group_id return_url]>trados</a>
"

db_release_unused_handles
doc_return  200 text/html [im_return_template]



set sql_task "
select task_id, task_name
from im_tasks
where project_id = :group_id"

set list_task ""
set project_id $group_id

db_foreach tasks $sql_task {
    append list_task "<a href=\"download-task?[export_url_vars project_id task_id return_url=]\">$task_name</a> <br><br><p>"
}

append page_body "
<br><br>
$list_task
"

