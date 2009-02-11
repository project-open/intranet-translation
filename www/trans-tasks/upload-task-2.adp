<!-- packages/intranet-translation/www/trans-tasks/upload-task-2.adp -->
<!-- @author Juanjo Ruiz (juanjoruizx@yahoo.es) -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="../../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">projects</property>


<H2>#intranet-translation.Upload_Successful#</H2>

<%
      # Ugly: show the upload_file instead of the org task name in the msg
      set task_name $upload_file_body
%>

#intranet-translation.lt_Your_have_successfull#

@comment_html;noquote@

<P>
<A href="@return_url@">#intranet-translation.lt_Return_to_Project_Pag#</a>
</p>



