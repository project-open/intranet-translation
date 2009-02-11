# /packages/intranet-translation/www/tandem-partners.tcl
#
# Copyright (c) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

if {![info exists project_id]} {
    ad_page_contract {
	Show the list of all "tandem partners" for the translators
	who are currently a member of the project.

	@author frank.bergmann@project-open.com
    } {
	{ project_id 0 }
	{ return_url "" }
    }
}

# ---------------------------------------------------------------------
# Permissions & Defaults
# ---------------------------------------------------------------------

if {![info exists project_id] || 0 == $project_id} { ad_return_complaint 1 "Tandem-Partners: No project_id specified" }
if {![info exists return_url] || "" == $return_url} { ad_return_complaint 1 "Tandem-Partners: No return_url specified" }

set user_id [ad_maybe_redirect_for_registration]
im_project_permissions $user_id $project_id view read write admin
if {!$write} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_6]"
    ad_script_abort
}

set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"

set project_url "/intranet/projects/view"
set user_url "/intranet/users/view"

set default_role_id [im_biz_object_role_full_member]

set object_id $project_id
set colspan 3

# ------------------------------------------------------------------------------------------------
# Call-To-Quote Worklfow
# ------------------------------------------------------------------------------------------------

set html "
        <tr class=rowtitle>
          <td class=rowtitle colspan=$colspan align=center>
		[lang::message::lookup "" intranet-translation.Tandem_Partners "Tandem Partners"]
	</tr>
        <tr class=rowtitle>
<!--          <td class=rowtitle>
		[lang::message::lookup "" intranet-translation.Tandem_Translator "Translator"]
	  </td>
-->
          <td class=rowtitle>
		[lang::message::lookup "" intranet-translation.Tandem_Partner "Tandem Partner"]
	  </td>
          <td class=rowtitle>
		[lang::message::lookup "" intranet-translation.Num_Times "#Times"]
	  </td>
          <td class=rowtitle>
		[lang::message::lookup "" intranet-translation.Sel "Sel"]
	  </td>
	</tr>
"

# Go through the entire translation history, check for instances where 
# one of the project's members acted as a translator and pull out the
# respective editor. 
# Then sum this up and sort, so that the most frequent editor (=tandem
# partner) comes first.
#
set inner_tandem_sql "
	select
		count(*) as cnt,
		t.trans_id,
		t.edit_id
	from
		im_trans_tasks t,
		acs_rels r,
		persons p
	where
		r.object_id_two = p.person_id and
		r.object_id_one = :project_id and
		p.person_id = t.trans_id and
		t.trans_id is not null and
		t.edit_id is not null
	group by
		t.trans_id,
		t.edit_id
"

set tandem_sql "
	select	*,
		im_name_from_user_id(trans_id) as translator,
		im_name_from_user_id(edit_id) as editor
	from	($inner_tandem_sql) t
	order by
		t.trans_id,
		t.cnt DESC
"

set old_trans_id 0
set rowcount 0
db_foreach tandem $tandem_sql {

    set translator_link "<a href='[export_vars -base $user_url {{user_id $trans_id}}]'>$translator</a>"
    set editor_link "<a href='[export_vars -base $user_url {{user_id $edit_id}}]'>$editor</a>"

    if {$trans_id != $old_trans_id} {
	    append html "
	      <tr class=rowplain></tr>
	      <tr class=rowtitle>
		<td class=rowtitle colspan=4>
	[lang::message::lookup "" intranet-translation.Tandem_Partners_of "Tandem Partners of %translator_link%"]
		</td>
	      </tr>
            "
	set old_trans_id $trans_id
    }

    append html "
	      <tr $bgcolor([expr $rowcount%2])>
		<td>$editor_link</td>
		<td>[lang::message::lookup "" intranet-translation.N_times "%cnt% times"]</td>
		<td><input type=radio name=user_id_from_search value=$edit_id></td>
	      </tr>
    "

    incr rowcount
}
