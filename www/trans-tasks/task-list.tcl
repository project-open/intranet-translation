# /www/intranet/trans-tasks/task-list.tcl

ad_page_contract {
    Show the list of current task and allow the project
    manager to create new tasks.

    @author fraber@project-open.com
    @creation-date Nov 2003
} {
    project_id:integer
    { return_url "/intranet/projects/" }
}

set user_id [ad_maybe_redirect_for_registration]
set return_url [im_url_with_query]
set page_title "Project Tasks"
set context_bar [ad_context_bar [list /intranet/projects/ "Projects"] [list "/intranet/projects/view?project_id=$project_id" "One project"] $page_title]
set customer_view_page "/intranet/customers/view"


set task_component [im_task_component $user_id $project_id $return_url]
set task_new_component [im_new_task_component $user_id $project_id $return_url]

# Setup the subnavbar
set bind_vars [ns_set create]
ns_set put $bind_vars project_id $project_id
set parent_menu_id [db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]
set project_menu [im_sub_navbar $parent_menu_id $bind_vars]
