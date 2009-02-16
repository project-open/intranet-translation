# /packages/intranet-translation/www/trans-tasks/task-trados.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Purpose: Determines the exact filename of the 
    wordcount.cvs file and passes on to uploading
    the content of the wordcount.cvs file.

    @param return_url the url to return to
    @param project_id group id
} {
    return_url:optional
    project_id:integer
}

# ---------------------------------------------------------------------
# Defaults & security
# ---------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
im_project_permissions $user_id $project_id view read write admin
if {!$write} {
    ad_return_complaint 1 "[_ intranet-translation.lt_You_have_insufficient_2]"
    return
}

set target_language_ids [im_target_language_ids $project_id im_projects]

if { ![exists_and_not_null return_url] } {
    set return_url "[im_url_stub]/projects/view?[export_url_vars project_id]"
}


# ---------------------------------------------------------------------
# Find a "wordcount.csv" in the project folder
# ---------------------------------------------------------------------

set query "
select
        p.project_nr as project_short_name,
        c.company_name as company_short_name,
        p.source_language_id,
        im_category_from_id(p.source_language_id) as source_language,
        p.project_type_id
from
        im_projects p,
        im_companies c
where
        p.project_id=:project_id
        and p.company_id=c.company_id(+)"


if { ![db_0or1row projects_info_query $query] } {
    ad_return_complaint 1 "[_ intranet-translation.lt_Cant_find_the_project]"
    return
}

set project_path [im_filestorage_project_path $project_id]
set find_cmd [parameter::get -package_id [im_package_core_id] -parameter "FindCmd" -default "/bin/find"]

if { [catch {
    set file_list [exec $find_cmd $project_path -name wordcount.csv]
} err_msg] } {
    # No "wordcount.csv" present or permission error
    ns_log Notice "trados-upload: $err_msg"
}
ns_log Notice "file_list=$file_list\n"
    
set files [split $file_list "\n"]
if {[llength $files] > 1} {
    # Too many files
    ad_return_complaint 1 "<li>
    [_ intranet-translation.lt_We_have_found_more_th] 
    [_ intranet-translation.lt_Please_determine_the_]"
    return
}
    
if {[llength $files] == 0} {
    # No file found
    ad_return_complaint 1 "<li>
	[_ intranet-translation.lt_We_have_not_found_a_w]<br>
        [_ intranet-translation.lt_Please_start_Trados_a]"
    return
}

set trados_wordcount_file [lindex $files 0]

if {![file readable $trados_wordcount_file]} {
    set err_msg "[_ intranet-translation.lt_Unable_to_read_the_fi]
[_ intranet-translation.lt_Please_check_the_file]"
    ad_return_complaint 1 $err_msg
    return
}

set import_method "Asp"

ad_returnredirect trados-import?[export_url_vars project_id return_url trados_wordcount_file import_method]

