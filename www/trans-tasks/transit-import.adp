<!-- packages/intranet-translation/www/trans-tasks/transit-import.adp -->
<!-- @author Juanjo Ruiz (juanjo.ruiz@project-open.com) -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="../../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">projects</property>


<!-- <h2><%= [lang::message::lookup "" intranet-translation.Import_Method "Import Method"] %></h2> -->
<h1>@page_title@</h1>

<!--
<p>
<A HREF=@return_url@><%= [_ intranet-translation.lt_Return_to_previous_pa] %></A>
</P>

<table cellpadding=0 cellspacing=2 border=0>
    <tr class=rowtitle>
	<td colspan=2 class=rowtitle align=center><%= [_ intranet-translation.Wordcount_Import] %></td>
    </tr>
    <tr class=roweven>
	<td class=roweven>Transit-Version</td><td>@transit_version@</td>
    </tr>
    <tr class=rowodd>
	<td class=rowodd>Project Path</td><td>@project_path@</td>
    </tr>
</table>
<p>
-->

<!-- -------------------------------------------------------------------- -->
<form action=transit-import-2 method=POST>
<%= [export_form_vars return_url project_id task_type_id target_language_id import_method] %>
<h3>Import as Multiple Lines</h3>
<p>
<table width="600">
<tr>
    <td colspan=2>
	This option allows you to import the contents of the Transit analysis file-by-file into
        <span class=brandsec>&\#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&\#91;</span>.
	This import will create the following translation tasks:
    </td>
</tr>
<tr>
    <td>
<input type=submit value="<%= [lang::message::lookup "" intranet-translation.Add_Transit_Analysis_Lines "Add Transit Analysis as Multiple Lines"]%>">
    </td>
</tr>
</table>
<p>
@task_html;noquote@
</form>

<p>&nbsp;</p>

<!-- -------------------------------------------------------------------- -->
<form action=transit-import-2 method=POST>
<%= [export_form_vars return_url project_id task_type_id target_language_id import_method] %>
%>




<h3>Import as a Single "Batch" File</h3>
<p>
<table width="600">
<tr>
    <td colspan=2>
	This option allows you to import the contents of the Transit analysis as a single "batch" file into 
	<span class=brandsec>&\#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&\#91;</span>.
	Please specify the name of the batch file. Please make sure to create
	this file in the project's filestorage.<br>
        This batch file included all default files (check in the list
	above). There is NO WAY to include/exclude files in this batch.

    </td>
</tr>
<tr>
    <td>Batch file name:</td>
    <td>
        <input type=hidden name=import_p.1 value=1>
	<input type=text name=filename_list.1 size=40 value="@upload_file_body@.pxf">
	<input type=hidden name=task_type_list.1 value="@org_task_type_id@">
	<input type=hidden name=px_words_list.1 value="@sum_px_words@">
	<input type=hidden name=prep_words_list.1 value="@sum_prep_words@">
	<input type=hidden name=p100_words_list.1 value="@sum_p100_words@">
	<input type=hidden name=p95_words_list.1 value="@sum_p95_words@">
	<input type=hidden name=p85_words_list.1 value="@sum_p85_words@">
	<input type=hidden name=p75_words_list.1 value="@sum_p75_words@">
	<input type=hidden name=p50_words_list.1 value="@sum_p50_words@">
	<input type=hidden name=p0_words_list.1 value="@sum_p0_words@">
	<input type=hidden name=repetitions.1 value="@repetitions@">
    </td>
</tr>
<tr>
    <td colspan=2>
	<input type=submit value="<%= [lang::message::lookup "" intranet-translation.Add_Transit_Batch "Add Transit Batch"]%>">
    </td>
</tr>
</table>
</form>

</p><p>&nbsp;</p>



<!--
<P>
<A HREF=@return_url@><%= [_ intranet-translation.lt_Return_to_previous_pa] %></A>
</P>
-->

