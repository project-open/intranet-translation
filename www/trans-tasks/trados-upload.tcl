# /packages/intranet-translation/www/trans-tasks/trados-upload.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Upload a Trados wordcount (.CSV) file and convert
    every line of it into an im_task for the Translation
    Workflow.
    The main work is done by "trados-import.tcl", so we
    basicly only have to provide the trados file.

    @author frank.bergmann@project-open.com
} {
    project_id:integer
    return_url
    upload_file
} 

# ---------------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
im_project_permissions $user_id $project_id view read write admin
if {!$write} {
    ad_return_complaint 1 "<li>You have insufficient privileges to view this page.\n"
    return
}

# ---------------------------------------------------------------------
# Process the upload file
# ---------------------------------------------------------------------

# Get the file from the user.
# number_of_bytes is the upper-limit
set max_n_bytes [ad_parameter -package_id [im_package_filestorage_id] MaxNumberOfBytes "" 0]
set tmp_filename [ns_queryget upload_file.tmpfile]
set trados_wordcount_file "$tmp_filename.copy"

ns_log Notice "trados-upload: max_n_bytes=$max_n_bytes"
ns_log Notice "trados-upload: tmp_filename=$tmp_filename"

if { ![empty_string_p $max_n_bytes] && ([file size $tmp_filename] > $max_n_bytes) } {
    ad_return_complaint 1 "Your file is larger than the maximum permissible upload size:  [util_commify_number $max_n_bytes] bytes"
    return 0
}

set file_extension [string tolower [file extension $upload_file]]
ns_log Notice "trados-upload: file_extension=$file_extension"

if {![string equal $file_extension ".csv"]} {
    ad_return_complaint 1 "<li>Your file is not a trados wordcount file.<br>
    Please upload a file with the extension \".CSV\"."
    return 0
}

# Make a copy of the file because AOLServer deletes the file 
# after leaving this page.
set copy_result [exec /bin/cp $tmp_filename $trados_wordcount_file]

set import_method "Asp"

ad_returnredirect trados-import?[export_url_vars project_id return_url trados_wordcount_file import_method]
