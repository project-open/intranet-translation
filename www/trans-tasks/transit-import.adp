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

<form action=transit-import-2 method=POST>

<h3>
	<input type=radio name=transit_batch_import value=1 <if 1 eq @transit_batch_default_p@>checked</if>>
	Import as a Single "Batch" File
</h3>
<p>
<table width="600">
<tr>
    <td colspan=2>
	This option allows you to import the contents of the Transit analysis as a single "batch" file into 
	<span class=brandsec>&\#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&\#91;</span>.
	Please specify the name of the batch file. Please make sure to create this file in the project's filestorage.<br>
    </td>
</tr>
<tr>
    <td>Batch file name:</td>
    <td>
	<input type=text size=40 value="transit.zip">
    </td>
</tr>
</table>
</p><p>&nbsp;</p>


<h3>
	<input type=radio name=transit_batch_import value=0 <if 0 eq @transit_batch_default_p@>checked</if>>
	Import as Multiple Lines
</h3>

<table width="600">
<tr>
    <td colspan=2>
	This option allows you to import the contents of the Transit analysis file-by-file into
        <span class=brandsec>&\#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&\#91;</span>.
	This import will create the following translation tasks:
    </td>
</tr>
</table>

<p>
@task_html;noquote@

<p>&nbsp;</p>

<input type=submit value="<%= [lang::message::lookup "" intranet-translation.Upload_Transit_Analysis "Upload Transit Analysis"]%>">


</form>


<!--
<P>
<A HREF=@return_url@><%= [_ intranet-translation.lt_Return_to_previous_pa] %></A>
</P>
-->

