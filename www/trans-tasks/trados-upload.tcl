ad_page_contract {
    Upload a Trados wordcount (.CSV) file and convert
    every line of it into an im_task for the Translation
    Workflow.
    The main work is done by "trados-import.tcl", so we
    basicly only have to provide the trados file.
} {
    group_id:integer
    return_url
    upload_file
} 

# ---------------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set user_is_group_admin_p [im_can_user_administer_group $group_id $user_id]
set user_is_wheel_p [ad_user_group_member [im_wheel_group_id] $user_id]
set user_admin_p [|| $user_is_admin_p $user_is_group_admin_p]
set user_admin_p [|| $user_admin_p $user_is_wheel_p]

set project_id $group_id

# check the user input first
#
set exception_text ""
set exception_count 0
if {!$user_admin_p} {
    append exception_text "<li>You are not a member of this project.\n"
    incr exception_count
}
if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
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

ad_returnredirect trados-import?[export_url_vars group_id return_url trados_wordcount_file import_method]
