# /www/intranet/trans-tasks/task-list.tcl

ad_page_contract {
    Show the list of current task and allow the project
    manager to create new tasks.

    @author fraber@project-open.com
    @creation-date Nov 2003
} {
    project_id:integer
    return_url
}

set user_id [ad_maybe_redirect_for_registration]
set return_url [im_url_with_query]
set page_title "Project Tasks"
set context_bar [ad_context_bar [list /intranet/projects/ "Projects"] [list "/intranet/projects/view?project_id=$project_id" "One project"] $page_title]

set page_body "
<br>
<A HREF=/intranet/projects/view?project_id=$project_id>Return to Project Page</A>

[im_task_component $user_id $project_id $return_url]
<A HREF=/intranet/projects/view?project_id=$project_id>Return to Project Page</A>
<p>
[im_new_task_component $user_id $project_id $return_url]
"

db_release_unused_handles
doc_return  200 text/html [im_return_template]


