# /www/intranet/trans-tasks/task-list.tcl

ad_page_contract {
    Show the list of current task and allow the project
    manager to create new tasks.

    @author fraber@project-open.com
    @creation-date Nov 2003
} {
    group_id:integer
    return_url
}

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set user_is_wheel_p [ad_user_group_member [im_wheel_group_id] $user_id]
set user_is_group_admin_p [im_can_user_administer_group $group_id $user_id]
set user_is_employee_p [im_user_is_employee_p $user_id]
set user_admin_p [expr $user_is_admin_p || $user_is_group_admin_p]
set user_admin_p [expr $user_admin_p || $user_is_wheel_p]


set return_url [im_url_with_query]

set page_title "Project Tasks"
set context_bar [ad_context_bar [list /intranet/projects/ "Projects"] [list "/intranet/projects/view?group_id=$group_id" "One project"] $page_title]

set page_body "
<br>
<A HREF=/intranet/projects/view?group_id=$group_id>Return to Project Page</A>

[im_task_component $user_id $group_id $user_admin_p $user_is_employee_p $return_url]
<A HREF=/intranet/projects/view?group_id=$group_id>Return to Project Page</A>
<p>
[im_new_task_component $user_id $group_id $user_admin_p $user_is_employee_p $return_url]
"

db_release_unused_handles
doc_return  200 text/html [im_return_template]


