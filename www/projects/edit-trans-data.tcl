# /packages/intranet-translation/www/projects/edit-trans-data.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Purpose: form to add a new project or edit an existing one
    
    @param project_id group id
    @param return_url the url to return to

    @author frank.bergmann@project-open.com
} {
    project_id:integer
    return_url
}

set user_id [ad_maybe_redirect_for_registration]
# set required_field "<font color=red size=+1><B>*</B></font>"
set required_field ""

set include_source_language_country_locale [ad_parameter -package_id [im_package_translation_id] SourceLanguageWithCountryLocaleP "" 0]

im_project_permissions $user_id $project_id view read write admin
if {!$write} {
    ad_return_complaint 1 "<li>[_ intranet-translation.lt_You_have_insufficient]"
    return
}

set target_language_ids [im_target_language_ids $project_id]

db_1row projects_info_query { 
select 
        p.*,
        p.company_project_nr
from
	im_projects p
where 
	p.project_id = :project_id 
}

set page_title "$project_nr - $project_name"
set context_bar [im_context_bar [list /intranet/projects/ "[_ intranet-translation.Projects]"] [list "/intranet/projects/view?[export_url_vars project_id]" "[_ intranet-translation.One_project]"] $page_title]


if {![db_0or1row "get company info" "select  c.company_name from im_companies c where c.company_id = :company_id"]} {
    set company_name ""
}

set submit_changes_l10n [lang::message::lookup "" intranet-translation.Submit_Changes "Submit Changes and Create Folder Structure"]
set create_language_subprojects_l10n [lang::message::lookup "" intranet-translation.Create_Language_Subprojects "Submit Changes and Create Language Subprojects"]


set page_body "
                <form action=edit-trans-data-2 method=post name=edit-trans-data>
[export_form_vars return_url project_id dp_ug.user_groups.creation_ip_address dp_ug.user_groups.creation_user]
                  <table border=0>
                    <tr> 
                      <td colspan=2 class=rowtitle align=middle>
                        [_ intranet-translation.Project_Details]
                      </td>
                    </tr>
                    <tr> 
                    <tr> 
                      <td>[_ intranet-translation.Client_project_]</td>
                      <td> 
                        <input type=text size=40 name=company_project_nr value='$company_project_nr'>
                         [im_gif help "An optional field specifying the project reference code of the client. Is used when printing the invoice. Example: 20030310A12478"]
                      </td>
                    </tr>
                    <tr> 
                      <td>[_ intranet-translation.Final_User] &nbsp;</td>
                      <td> 
                        <input type=text size=20 name=final_company value='$final_company'>
                         [im_gif help "Who is the final consumer (when working for an agency)? Examples: \"Shell\", \"UBS\", ..."]
                      </td>
                    </tr>

                    <tr> 
                      <td>[_ intranet-translation.Client_contact] &nbsp;</td>
                      <td>
[im_company_contact_select "company_contact_id" $company_contact_id $company_id]
                      </td>
                    </tr>

                   <tr>
                      <td>[_ intranet-translation.Source_Language] $required_field </td>
                      <td>
[im_trans_language_select -include_country_locale $include_source_language_country_locale source_language_id $source_language_id]
[im_admin_category_gif "Intranet Translation Language"]
[im_gif help "Translation source language"]
                      </td>
                    </tr>

                    <tr>
                      <td>[_ intranet-translation.Target_Languages] </td>
                      <td>
[im_category_select_multiple -translate_p 0 "Intranet Translation Language" target_language_ids $target_language_ids 12 multiple]
[im_admin_category_gif "Intranet Translation Language"]
[im_gif help "Translation target languages. Separate target folders will be created for every language that you select"]
                      </td>
                    </tr>

                    <tr>
                      <td>[_ intranet-translation.Subject_Area] </td>
                      <td>
[im_category_select "Intranet Translation Subject Area" subject_area_id $subject_area_id]
[im_admin_category_gif "Intranet Translation Subject Area"]
[im_gif help "Add a new subject area"]
                      </td>
                    </tr>

                    <tr> 
                      <td>[_ intranet-translation.Quality_Level]</td>
                      <td> 
[im_category_select "Intranet Quality" "expected_quality_id" $expected_quality_id]
[im_admin_category_gif "Intranet Quality"]
                      </td>
                    </tr>

                    <tr> 
                      <td valign=top></td>
                      <td>
		 	<p> 
                          <input type=submit value='$submit_changes_l10n' name=submit_changes>
                          [im_gif help "Create the new folder structure"] <br>
                          <input type=submit value='$create_language_subprojects_l10n' name=submit_subprojects>
                          [im_gif help "Create folder structure and create a subproject for each language that you have chosen."] <br>
                        </p>
                      </td>
                    </tr>
                  </table>
                </form>
"


# -------------------------------------------------------------------
# Project Subnavbar
# -------------------------------------------------------------------

set bind_vars [ns_set create]
ns_set put $bind_vars project_id $project_id
set parent_menu_id [db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]

