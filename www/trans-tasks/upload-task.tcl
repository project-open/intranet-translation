# /packages/intranet-translation/www/trans-tasks/upload-task.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Serve the user a form to upload a new file or URL

    @author fraber@fraber.de
    @creation-date 030909
} {
    project_id:integer
    task_id:integer
    return_url
}

set user_id [ad_maybe_redirect_for_registration]
set page_title "[_ intranet-translation.Upload_New_FileURL]"

set context_bar [im_context_bar [list "/intranet/projects/" "[_ intranet-translation.Projects]"]  [list "/intranet/projects/view?group_id=$project_id" "[_ intranet-translation.One_Project]"]  "[_ intranet-translation.Upload_File]"]

set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"

set filename [db_string get_filename "select task_name from im_trans_tasks where task_id=:task_id"]

set page_content "
<form enctype=multipart/form-data method=POST action=upload-task-2.tcl>
[export_form_vars project_id task_id return_url]

                    <table border=0>
                      <tr> 
                        <td class=rowtitle align=center colspan=2>Upload a file</td>
                      </tr>
                      <tr $bgcolor(0)> 
                        <td align=right>[_ intranet-translation.Filename] </td>
                        <td>$filename</td>
                      </tr>
                      <tr $bgcolor(1)> 
                        <td align=right>[_ intranet-translation.File] </td>
                        <td>
                          <input type=file name=upload_file size=30>
                          [im_gif help "[_ intranet-translation.lt_Use_the_Browse_button]"]
                        </td>
                      </tr>
                      <tr $bgcolor(0)> 
                        <td valign=top align=right>[_ intranet-translation.Comment]<br>
			<font size=-1>[_ intranet-translation.optional]</font>
                        </td>
                        <td colspan=1>
                          <textarea rows=5 cols=50 name=description wrap></textarea>
                        </td>
                      </tr>
                      <tr $bgcolor(1)> 
                        <td></td>
                        <td> 
                          <input type=submit value='[_ intranet-translation.Submit_and_Upload]'><br>
                        </td>
                      </tr>
                    </table>
<blockquote>
[_ intranet-translation.lt_This_page_may_take_se]
</blockquote>

</form>
"

db_release_unused_handles
ad_return_template
