# /www/intranet/projects/task-save.tcl

ad_page_contract {
    Purpose: Determines the exact filename of the 
    wordcount.cvs file and passes on to uploading
    the content of the wordcount.cvs file.

    @param return_url the url to return to
    @param group_id group id
} {
    return_url:optional
    group_id:integer
}

# ---------------------------------------------------------------------
# Defaults & security
# ---------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set user_is_wheel_p [ad_user_group_member [im_wheel_group_id] $user_id]
set user_is_group_member_p [ad_user_group_member $group_id $user_id]
set user_is_group_admin_p [im_can_user_administer_group $group_id $user_id]
set user_admin_p [expr $user_is_admin_p || $user_is_wheel_p]

if {!$user_admin_p && !$user_is_group_admin_p} {
    ad_return_complaint 1 "You have insufficient permissions to view this page"
    return
}

set target_language_ids [im_target_language_ids $group_id im_projects]

if { ![exists_and_not_null return_url] } {
    set return_url "[im_url_stub]/projects/view?[export_url_vars group_id]"
}


# ---------------------------------------------------------------------
# Find a "wordcount.csv" in the project folder
# ---------------------------------------------------------------------


# ----------------- old 3.4 query

set query1 "
select
	g.short_name as project_short_name, 
	g2.short_name as customer_short_name,
        p.source_language_id,
        p.project_type_id
from
	im_projects p, 
	groups g, 
	groups g2
where 
	p.group_id=:group_id
	and p.group_id=g.group_id
	and p.customer_id=g2.group_id(+)"

# ----------------- new 5.0 query

set query "
select
        p.project_nr as project_short_name,
        c.customer_name as customer_short_name,
        p.source_language_id,
        im_category_from_id(p.source_language_id) as source_language,
        p.project_type_id
from
        im_projects p,
        im_customers c
where
        p.project_id=:group_id
        and p.customer_id=c.customer_id(+)"


if { ![db_0or1row projects_info_query $query] } {
    ad_return_complaint 1 "Can't find the project with group 
    id of $project_id"
    return
}

set project_path [im_filestorage_project_path $group_id]

if { [catch {
    set file_list [exec /usr/bin/find $project_path -name wordcount.csv]
} err_msg] } {
    # No "wordcount.csv" present or permission error
    ns_log Notice "trados-upload: $err_msg"
}
ns_log Notice "file_list=$file_list\n"
    
set files [split $file_list "\n"]
if {[llength $files] > 1} {
    # Too many files
    ad_return_complaint 1 "<li>
    We have found more then one 'wordcount.csv' files in
    the project path '$project_path'. Please determine the valid file
    and delete or rename the other ones."
    return
}
    
if {[llength $files] == 0} {
    # No file found
    ad_return_complaint 1 "<li>
	We have not found a 'wordcount.csv' file in the project path
	'$project_path'.<br>
	Please start Trados and generate a file for this folder."
    return
}

set trados_wordcount_file [lindex $files 0]

if {![file readable $trados_wordcount_file]} {
    set err_msg "Unable to read the file '$trados_wordcount_file'. 
Please check the file permissions or contact your system administrator.\n"
    append page_body "\n$err_msg\n"
    doc_return  200 text/html [im_return_template]
    return
}

set import_method "Asp"

ad_returnredirect trados-import?[export_url_vars group_id return_url trados_wordcount_file import_method]

