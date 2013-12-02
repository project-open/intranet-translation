<master src="../../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="main_navbar_label">projects</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>

<if @auto_assignment_component_p@>
@auto_assignment_html;noquote@
</if>

<if @task_html@ ne "">
@task_html;noquote@
</if>
<else>
<%=[lang::message::lookup "" intranet-translation.No_tasks_found "No tasks found"]%>
</else>

<p>

@ass_html;noquote@



