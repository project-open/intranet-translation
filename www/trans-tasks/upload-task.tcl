# /intranet/filestorage/upload-task.tcl

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
set page_title "Upload New File/URL"

set context_bar [ad_context_bar [list "/intranet/projects/" "Projects"]  [list "/intranet/projects/view?group_id=$project_id" "One Project"]  "Upload File"]

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
                        <td align=right>Filename </td>
                        <td>$filename</td>
                      </tr>
                      <tr $bgcolor(1)> 
                        <td align=right>File </td>
                        <td>
                          <input type=file name=upload_file size=30>
                          <img src=/images/help.gif width=16 height=16 alt='Use the &quot;Browse...&quot; button to locate your file, then click &quot;Open&quot;.'> 
                        </td>
                      </tr>
                      <tr $bgcolor(0)> 
                        <td valign=top align=right>Comment<br>
			<font size=-1>(optional)</font>
                        </td>
                        <td colspan=1>
                          <textarea rows=5 cols=50 name=description wrap></textarea>
                        </td>
                      </tr>
                      <tr $bgcolor(1)> 
                        <td></td>
                        <td> 
                          <input type=submit value='Submit and Upload'><br>
                        </td>
                      </tr>
                    </table>
<blockquote>
(This page may take several minutes to upload your file, depending on the
size of the file and your Internet connection. Please do not interrupt the 
system meanwhile.)
</blockquote>

</form>
"

db_release_unused_handles
doc_return  200 text/html [im_return_template]
