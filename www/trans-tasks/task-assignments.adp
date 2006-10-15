<master src="../../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="main_navbar_label">projects</property>


<br>
<%= [im_sub_navbar $parent_menu_id $bind_vars "" "pagedesriptionbar" "project_trans_tasks_assignments"] %>


@autoassignment_html;noquote@

@task_html;noquote@

<p>

@ass_html;noquote@



