ad_page_contract {
    Upload a Trados wordcount (.CSV) file and convert
    every line of it into an im_task for the Translation
    Workflow.
    The main work is done by "trados-import.tcl", so we
    basicly only have to provide the trados file.
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
    append 1 "<li>You have insufficient privileges to view this page.\n"
    return
}

# ---------------------------------------------------------------------
# Process the upload file
# ---------------------------------------------------------------------

# Get the file from the user.
# number_of_bytes is the upper-limit
set max_n_bytes [ad_parameter MaxNumberOfBytes fs]
set tmp_filename [ns_queryget upload_file.tmpfile]

if { ![empty_string_p $max_n_bytes] && ([file size $tmp_filename] > $max_n_bytes) } {
    ad_return_complaint 1 "Your file is larger than the maximum permissible upload size:  [util_commify_number $max_n_bytes] bytes"
    return 0
}

set file_extension [string tolower [file extension $upload_file]]

if {![string equal $file_extension ".csv"]} {
    ad_return_complaint 1 "<li>Your file is not a trados wordcount file.<br>
    Please upload a file with the extension \".CSV\"."
    return 0
}

set trados_wordcount_file $tmp_filename
set import_method "Asp"

ad_returnredirect trados-import?[export_url_vars project_id return_url trados_wordcount_file import_method]
