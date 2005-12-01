# /packages/intranet-translation/www/trans-tasks/task-list.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Show the list of current task and allow the project
    manager to create new tasks.

    @author frank.bergmann@project-open.com
} {
    project_id:integer
    { return_url "/intranet/projects/" }
}

set user_id [ad_maybe_redirect_for_registration]
set return_url [im_url_with_query]
set page_title "[_ intranet-translation.Project_Tasks]"
set context_bar [im_context_bar [list /intranet/projects/ "[_ intranet-translation.Projects]"] [list "/intranet/projects/view?project_id=$project_id" "[_ intranet-translation.One_project]"] $page_title]
set company_view_page "/intranet/companies/view"

set task_component [im_task_component $user_id $project_id $return_url]
set task_new_component [im_new_task_component $user_id $project_id $return_url]
set task_comments_component [im_task_trans_comments_component $project_id]

# Setup the subnavbar
set bind_vars [ns_set create]
ns_set put $bind_vars project_id $project_id
set parent_menu_id [db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]

set menu_label "project_trans_tasks"
set project_menu [im_sub_navbar $parent_menu_id $bind_vars "" "pagedesriptionbar" $menu_label]
