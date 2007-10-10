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

    @param project_id The parent project
    @param return_url Where to go after the work is done?
    @param wordcount_application Allows to upload data from
           various Translation Memories
    @param tm_type_id Really necessary? Not used yet, 
           because the TM type is given from the wordcount_app
    @param task_type_id determines the task type
    @param upload_file The filename to be uploaded - according
           to AOLServer conventions

    @author frank.bergmann@project-open.com
} {
    project_id:integer
    return_url
    { wordcount_application "trados" }
    { task_type_id 0 }
    { target_language_id "" }
    upload_file
} 

# ---------------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
im_project_permissions $user_id $project_id view read write admin
if {!$write} {
    ad_return_complaint 1 "<li>[_ intranet-translation.lt_You_have_insufficient_3]"
    return
}

# ---------------------------------------------------------------------
# Process the upload file
# ---------------------------------------------------------------------

# Get the file from the user.
# number_of_bytes is the upper-limit
set max_n_bytes [ad_parameter -package_id [im_package_filestorage_id] MaxNumberOfBytes "" 0]
set tmp_filename [ns_queryget upload_file.tmpfile]
set wordcount_file "$tmp_filename.copy"

ns_log Notice "trados-upload: max_n_bytes=$max_n_bytes"
ns_log Notice "trados-upload: tmp_filename=$tmp_filename"

if { $max_n_bytes && ([file size $tmp_filename] > $max_n_bytes) } {
    ad_return_complaint 1 "[_ intranet-translation.lt_Your_file_is_larger_t]:  [util_commify_number $max_n_bytes] bytes"
    return 0
}

set file_extension [string tolower [file extension $upload_file]]
ns_log Notice "trados-upload: file_extension=$file_extension"

# ".rep" is uniquely used for transit
if {[string equal $file_extension ".rep"]} { set wordcount_application "transit" }

if {![string equal $file_extension ".csv"] && ![string equal $file_extension ".txt"] && ![string equal $file_extension ".rep"]} {
    ad_return_complaint 1 "<li>
	[lang::message::lookup "" intranet-translation.Your_file_is_not_a_wordcount_file "Your file is not a valid wordcount file"]<br>
	[lang::message::lookup "" intranet-translation.Please_upload_cvs_txt "Please upload a file with the extension '.csv' or '.txt'."]"
    return 0
}

# Make a copy of the file because AOLServer deletes the file 
# after leaving this page.
set copy_result [exec /bin/cp $tmp_filename $wordcount_file]

set import_method "Asp"

switch $wordcount_application {
    trados {
	ad_returnredirect trados-import?[export_url_vars project_id task_type_id target_language_id return_url wordcount_file import_method]
    }
    transit {
	ad_returnredirect transit-import?[export_url_vars project_id task_type_id target_language_id return_url wordcount_file import_method]
    }
    freebudget {
	ad_returnredirect freebudget-import?[export_url_vars project_id task_type_id target_language_id return_url wordcount_file import_method]
    }
    webbudget {
	ad_returnredirect webbudget-import?[export_url_vars project_id task_type_id target_language_id return_url wordcount_file import_method]
    }
}

ad_return_complaint 1 "Wrong translation memory type selected"