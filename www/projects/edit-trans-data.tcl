# /packages/intranet-translation/www/projects/edit-trans-data.tcl
#
# Copyright (C) 2003-2004 Project/Open
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
set page_title "Edit Translation Details"
set context_bar [ad_context_bar [list /intranet/projects/ "Projects"] [list "/intranet/projects/view?[export_url_vars project_id]" "One project"] $page_title]

# set required_field "<font color=red size=+1><B>*</B></font>"
set required_field ""

im_project_permissions $user_id $project_id view read write admin
if {!$write} {
    ad_return_complaint 1 "<li>You have insufficient privileges to see this page"
    return
}

set target_language_ids [im_target_language_ids $project_id]

db_1row projects_info_query { 
select 
        p.*,
        p.customer_project_nr,
        c.customer_name
from
	im_projects p,
	im_customers c
where 
	p.project_id=:project_id 
        and p.project_id=c.customer_id(+)
}

set page_body "
                <form action=edit-trans-data-2 method=post name=edit-trans-data>
[export_form_vars return_url project_id dp_ug.user_groups.creation_ip_address dp_ug.user_groups.creation_user]
                  <table border=0>
                    <tr> 
                      <td colspan=2 class=rowtitle align=middle>
                        Project Details
                      </td>
                    </tr>
                    <tr> 
                    <tr> 
                      <td>Client project #</td>
                      <td> 
                        <input type=text size=40 name=customer_project_nr value='$customer_project_nr'>
                         [im_gif help "An optional field specifying the project reference code of the client. Is used when printing the invoice. Example: 20030310A12478"]
                      </td>
                    </tr>
                    <tr> 
                      <td>Final User &nbsp;</td>
                      <td> 
                        <input type=text size=20 name=final_customer value='$final_customer'>
                         [im_gif help "Who is the final consumer (when working for an agency)? Examples: \"Shell\", \"UBS\", ..."]
                      </td>
                    </tr>

                    <tr> 
                      <td>Client contact &nbsp;</td>
                      <td>
[im_customer_contact_select "customer_contact_id" $customer_contact_id $customer_id]
                      </td>
                    </tr>

                   <tr>
                      <td>Source Language $required_field </td>
                      <td>
[im_category_select "Intranet Translation Language" source_language_id $source_language_id]
[im_admin_category_gif "Intranet Translation Language"]
[im_gif help "Translation source language"]
                      </td>
                    </tr>

                    <tr>
                      <td>Target Language(s) </td>
                      <td>
[im_category_select_multiple "Intranet Translation Language" target_language_ids $target_language_ids 6 multiple]
[im_admin_category_gif "Intranet Translation Language"]
[im_gif help "Translation target languages. Searate target folders will be created for every language that you select"]
                      </td>
                    </tr>

                    <tr>
                      <td>Subject Area </td>
                      <td>
[im_category_select "Intranet Translation Subject Area" subject_area_id $subject_area_id]
[im_admin_category_gif "Intranet Translation Subject Area"]
[im_gif help "Add a new subject area"]
                      </td>
                    </tr>

                    <tr> 
                      <td>Quality Level</td>
                      <td> 
[im_category_select "Intranet Quality" "expected_quality_id" $expected_quality_id]
[im_admin_category_gif "Intranet Quality"]
                      </td>
                    </tr>

                    <tr> 
                      <td valign=top></td>
                      <td>
		 	<p> 
                          <input type=submit value='Submit changes' name=submit_changes>
                          [im_gif help "Create the new folder structure"] <br>
                          <input type=submit value='Create Language Subprojects' name=submit_subprojects>
                          [im_gif help "Create folder structure and create a subproject for each language that you have chosen."] <br>
                        </p>
                      </td>
                    </tr>
                  </table>
                </form>
"

doc_return  200 text/html [im_return_template]

