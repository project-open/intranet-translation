# /packages/intranet-translation/www/trans-tasks/trados-import.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Purpose: Import the contents of a wordcount.csv file
    into the current projects as a list of "im_task"s

    @param import_method = {LocalFs|Asp}
    	- LocalFs determines the "name" (=filename) of a task
	  by chopping off the local filesystem path from the
	  absolute path, because it asumes that the Trados
	  wordcount has been created on the same computer.
	- Asp determines the filename by identifying path 
	  components that are common to all files in the
	  .csv file.
	  This is the safer way to do it, but it elimiates
	  all comon subdirectories, which sometimes are
	  necesary for the user, for example when splittin
	  a large project in several smaller project according
	  to subdirectories.
    @param return_url the url to return to
    @param project_id group id
} {
    return_url
    project_id:integer
    task_type_id:integer
    wordcount_file
    { target_language_id "" }
    { import_method "Asp" }
    { upload_file "" }
}

# ---------------------------------------------------------------------
# Security
# ---------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set ip_address [ad_conn peeraddr]
im_project_permissions $user_id $project_id view read write admin
if {!$write} {
    ad_return_complaint 1 "<li>[_ intranet-translation.lt_You_have_insufficient_3]"
    ad_script_abort
}

# Compatibility with old message...
set trados_wordcount_file $wordcount_file
im_security_alert_check_tmpnam -location "trados-xml-import.tcl" -value $wordcount_file


# Check for accents and other non-ascii characters
set charset [ad_parameter -package_id [im_package_filestorage_id] FilenameCharactersSupported "" "alphanum"]

# Inter-Company invoicing enabled?
set interco_p [parameter::get_from_package_key -package_key "intranet-translation" -parameter "EnableInterCompanyInvoicingP" -default 0]


# ---------------------------------------------------------------------
# Get the file and deal with Unicode encoding...
# ---------------------------------------------------------------------

ns_log Notice "trados-import: wordcount_file=$wordcount_file"

if {[catch {
    set fl [open $wordcount_file]
    fconfigure $fl -encoding binary
    set binary_content [read $fl]
    close $fl
} err]} {
    ad_return_complaint 1 "Unable to open file $wordcount_file:<br><pre>\n$err</pre>"
    return
}

set encoding_bin [string range $binary_content 0 1]
binary scan $encoding_bin H* encoding_hex
ns_log Notice "trados-import: encoding_hex=$encoding_hex"

switch $encoding_hex {
    fffe {
	# Assume a UTF-16 file
	set encoding "unicode"
    }
    default {
	# Assume a UTF-8 file
	set encoding "utf-8"
    }
}


set target_language_ids [im_target_language_ids $project_id]
if {0 == [llength $target_language_ids]} {
    ad_return_complaint 1 "<li>[_ intranet-translation.lt_The_project_has_no_ta]<BR>
        Please back up to the project page and add at least one target language to the project.#>"
    return
}

# Explicitly specified? Then just take that one...
if {"" != $target_language_id} { 
    set target_language_ids $target_language_id 
}


set project_path [im_filestorage_project_path $project_id]

set page_title "[_ intranet-translation.Trados_Upload]"
set context_bar [im_context_bar [list /intranet/projects/ "[_ intranet-translation.Projects]"] $page_title]

set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"

# Number of errors encountered
set err_count 0

# ---------------------------------------------------------------------
# Get some more information about the project
# ---------------------------------------------------------------------

set project_query "
select
        p.project_nr as project_short_name,
	p.company_id as customer_id,
        c.company_name as company_short_name,
        p.source_language_id,
        p.project_type_id
from
        im_projects p,
        im_companies c
where
        p.project_id=:project_id
        and p.company_id=c.company_id(+)"



if { ![db_0or1row projects_info_query $project_query] } {
    ad_return_complaint 1 "[_ intranet-translation.lt_Cant_find_the_project]"
    return
}


# ---------------------------------------------------------------------
# Read the wordcount file from the /tmp directory
# ---------------------------------------------------------------------

append page_body "
<P><A HREF=$return_url>[_ intranet-translation.lt_Return_to_previous_pa]</A></P>
<table cellpadding=0 cellspacing=2 border=0>
"


if {[catch {
    set fl [open $wordcount_file]
    fconfigure $fl -encoding $encoding 
    set trados_files_content [read $fl]
    close $fl
} err]} {
    ad_return_complaint 1 "Unable to open file $wordcount_file:<br><pre>\n$err</pre>"
    return
}



# ---------------------------------------------------------------------
# Start parsing the file
# ---------------------------------------------------------------------

set trados_files [split $trados_files_content "\n"]
set trados_files_len [llength $trados_files]
set trados_header [lindex $trados_files 1]

set separator ";"

set trados_headers [split $trados_header $separator]

if {1 == [llength $trados_headers]} {
    # Probably got the wrong separator
    set separator ","
    set trados_headers [split $trados_header $separator]
}


# Distinguish between Trados 3 and Trados 5.5 files
#
set line2 [lindex $trados_files 2]
set line2_len [llength [split $line2 $separator]]

if {";" == $separator} {
    switch $line2_len {
	40 { set trados_version "6.5" }
	39 { set trados_version "5.5" }
	38 { set trados_version "5.0" }
	25 { set trados_version "3" }
	default { set trados_version "unknown" }
    }
} else {
    switch $line2_len {
	41 { set trados_version "7.0" }
	40 { set trados_version "6.5" }
	39 { set trados_version "6.0" }
	default { set trados_version "unknown" }
    }
}

ns_log Notice "trados-import: trados_version=$trados_version, line2_len=$line2_len, separator=$separator"


append page_body "
<P>
<tr><td colspan=2 class=rowtitle align=center>
  [_ intranet-translation.Wordcount_Import]
</td></tr>
<tr><td>Trados-Version</td><td>$trados_version</td></tr>
<tr><td>Project Path</td><td>$project_path</td></tr>
</table>

<P>

<table cellpadding=0 cellspacing=2 border=0>
<tr>
  <td class=rowtitle align=center>[_ intranet-translation.Filename]</td>
  <td class=rowtitle align=center>[_ intranet-translation.Task_Name]</td>
  <td class=rowtitle align=center>[_ intranet-translation.XTr]</td>
  <td class=rowtitle align=center>[_ intranet-translation.Rep]</td>
  <td class=rowtitle align=center>100%</td>
  <td class=rowtitle align=center>95%</td>
  <td class=rowtitle align=center>85%</td>
  <td class=rowtitle align=center>75%</td>
  <td class=rowtitle align=center>50%</td>
  <td class=rowtitle align=center>0%</td>
  <td class=rowtitle align=center>[_ intranet-translation.Weighted]</td>
</tr>
"

if {[string equal "unknown" $trados_version]} {
    ad_return_complaint 1 "
        <li>[_ intranet-translation.lt_Unknown_Trados_Versio]<br>
	[_ intranet-translation.lt_Your_file_trados_word]<BR>
	[_ intranet-translation.lt_Please_try_to_repeat_]"
    return
}

# Determine the common filename components in the list of 
# trados files. These components are chopped off later in
# the loop.
# This procedure is not necessary for LocalFs import.
set common_filename_comps 0

ns_log Notice "trados-import: import_method=$import_method"
if {[string equal $import_method "Asp"]} {
    set first_trados_line [lindex $trados_files 2]
    set first_trados_fields [split $first_trados_line $separator]
    set first_filename [lindex $first_trados_fields 0]
    set first_filename_comps [split $first_filename "\\"]

    ns_log Notice "trados-import: first_trados_line=$first_trados_line"
    ns_log Notice "trados-import: first_trados_fields=$first_trados_fields"
    ns_log Notice "trados-import: first_filename=$first_filename"
    ns_log Notice "trados-import: first_filename_comps=$first_filename_comps"

    set all_the_same 1
    set ctr 0
    set fist_filename_comps_len [llength $first_filename_comps]

    while {$all_the_same && $ctr < $fist_filename_comps_len} {
	set common_component [lindex $first_filename_comps $ctr]
#	ns_log Notice "trados-import: first_filename_comps: prefix=$common_component"

	for {set i 2} {$i < $trados_files_len} {incr i} {
	    set trados_line [lindex $trados_files $i]
	    if {0 == [string length $trados_line]} { continue }

	    set trados_fields [split $trados_line $separator]
	    set filename [lindex $trados_fields 0]
	    set filename_comps [split $filename "\\"]
	    set this_component [lindex $filename_comps $ctr]
	    ns_log Notice "trados-import: this_component=$this_component"
	    ns_log Notice "trados-import: common_component=$common_component"

	    if {![string equal $common_component $this_component]} {
		set all_the_same 0
		break
	    }

	}
	incr ctr
    }
    set common_filename_comps [expr $ctr - 1]
}

ns_log Notice "trados-import: common_filename_comps=$common_filename_comps"



    set ctr 0
    for {set i 2} {$i < $trados_files_len} {incr i} {
	incr ctr
	set trados_line [lindex $trados_files $i]
	if {0 == [string length $trados_line]} { continue }

	set trados_fields [split $trados_line $separator]
	set filename    	[lindex $trados_fields 0]
	set tagging_errors	[lindex $trados_fields 1]
	set chars_per_word	[lindex $trados_fields 2]

	if {[string equal $trados_version "3"]} {
	    set px_segments	0
	    set px_words	0
	    set px_placeables	0
	    set prep_segments	[lindex $trados_fields 3]
	    set prep_words	[lindex $trados_fields 4]
	    set prep_placeables	[lindex $trados_fields 5]
	    set p100_segments	[lindex $trados_fields 6]
	    set p100_words	[lindex $trados_fields 7]
	    set p100_placeables	[lindex $trados_fields 8]
	    set p95_segments	[lindex $trados_fields 9]
	    set p95_words	[lindex $trados_fields 10]
	    set p95_placeables	[lindex $trados_fields 11]
	    set p85_segments	[lindex $trados_fields 12]
	    set p85_words	[lindex $trados_fields 13]
	    set p85_placeables	[lindex $trados_fields 14]
	    set p75_segments	[lindex $trados_fields 15]
	    set p75_words	[lindex $trados_fields 16]
	    set p75_placeables	[lindex $trados_fields 17]
	    set p50_segments	[lindex $trados_fields 18]
	    set p50_words	[lindex $trados_fields 19]
	    set p50_placeables	[lindex $trados_fields 20]
	    set p0_segments	[lindex $trados_fields 21]
	    set p0_words	[lindex $trados_fields 22]
	    set p0_placeables	[lindex $trados_fields 23]
	}

	if {[string equal $trados_version "5.5"] || [string equal $trados_version "5.0"] || [string equal $trados_version "6.0"] || [string equal $trados_version "6.5"] || [string equal $trados_version "7.0"]} {

	    set px_segments	[lindex $trados_fields 3]
	    set px_words	[lindex $trados_fields 4]
	    set px_placeables	[lindex $trados_fields 5]

	    set prep_segments	[lindex $trados_fields 7]
	    set prep_words	[lindex $trados_fields 8]
	    set prep_placeables	[lindex $trados_fields 9]

	    set p100_segments	[lindex $trados_fields 11]
	    set p100_words	[lindex $trados_fields 12]
	    set p100_placeables	[lindex $trados_fields 13]

	    set p95_segments	[lindex $trados_fields 15]
	    set p95_words	[lindex $trados_fields 16]
	    set p95_placeables	[lindex $trados_fields 17]

	    set p85_segments	[lindex $trados_fields 19]
	    set p85_words	[lindex $trados_fields 20]
	    set p85_placeables	[lindex $trados_fields 21]

	    set p75_segments	[lindex $trados_fields 23]
	    set p75_words	[lindex $trados_fields 24]
	    set p75_placeables	[lindex $trados_fields 25]

	    set p50_segments	[lindex $trados_fields 27]
	    set p50_words	[lindex $trados_fields 28]
	    set p50_placeables	[lindex $trados_fields 29]

	    set p0_segments	[lindex $trados_fields 31]
	    set p0_words	[lindex $trados_fields 32]
	    set p0_placeables	[lindex $trados_fields 33]
	}

	switch $import_method {

	    "LocalFs" {

		# Remove the leading elements of the path from $filename
		set filename_comps [split $filename "\\"]

		# search for the common "projects" as the start of the main dir
		set path_index [lsearch -exact $filename_comps "projects"]

		# skip: +1:"projects", +2:client, +3:project +4:source dir
		set path_index [expr $path_index + 4]

		set len [expr [llength $filename_comps] - 1]
		set task_name_comps [lrange $filename_comps $path_index $len]
		set task_name [join $task_name_comps "/"]

	    }
	    "Asp" {

		# Remove all common filename components from the task names
		set filename_comps [split $filename "\\"]
		set len [expr [llength $filename_comps] - 1]
		set task_name_comps [lrange $filename_comps $common_filename_comps $len]
		set task_name [join $task_name_comps "/"]

	    }
	    default {
		ad_return_complaint 1 "<LI>[_ intranet-translation.Internal_error]: 
		[_ intranet-translation.lt_Unknown_Input_method_]"
		return
	    }
	}


	# Skip if it was an empty line

	if {"" == $px_words && "" == $prep_words && "" == $p100_words} {
	    ns_log Notice "trados-import: found an empty line - maybe the last one..."
	    continue
	}

	# Calculate the number of "effective" words based on
	# a valuation of repetitions

	
	# Determine the "effective" wordcount of the task:
	# Get the "task_units" from a special company called "default_freelance"
	#
        set task_units [im_trans_trados_matrix_calculate [im_company_freelance] $px_words $prep_words $p100_words $p95_words $p85_words $p75_words $p50_words $p0_words]

	# Determine the "billable_units" form the project's customer:
	#
        set billable_units [im_trans_trados_matrix_calculate $customer_id $px_words $prep_words $p100_words $p95_words $p85_words $p75_words $p50_words $p0_words]

	set billable_units_interco $billable_units
	if {$interco_p} {
            set interco_company_id [db_string get_interco_company "select interco_company_id from im_projects where project_id=$project_id" -default ""]
	    if {"" == $interco_company_id} { 
		set interco_company_id $customer_id 
	    }
	    set billable_units_interco [im_trans_trados_matrix_calculate $interco_company_id $px_words $prep_words $p100_words $p95_words $p85_words $p75_words $p50_words $p0_words]
	}

	set task_status_id 340
	set task_description ""
	# source_language_id defined by im_project
	# 324=Source words
	set task_uom_id 324	
	set invoice_id ""


	append page_body "
<tr $bgcolor([expr $ctr % 2])>
  <td>$filename</td>
  <td>$task_name</td>
  <td>$px_words</td>
  <td>$prep_words</td>
  <td>$p100_words</td>
  <td>$p95_words</td>
  <td>$p85_words</td>
  <td>$p75_words</td>
  <td>$p50_words</td>
  <td>$p0_words</td>
  <td>$task_units</td>
</tr>
"

	# Add a new task for every project target language
	set insert_sql ""
	foreach target_language_id $target_language_ids {

            if { [catch {

		set task_name_comps [split $task_name "/"]
                set task_name_len [expr [llength $task_name_comps] - 1]
                set task_name_body [lindex $task_name_comps $task_name_len]
		set filename $task_name_body

		if {![im_filestorage_check_filename $charset $filename]} {
		    return -code 10 [lang::message::lookup "" intranet-filestorage.Invalid_Character_Set "
			<b>Invalid Character(s) found</b>:<br>
			Your filename '%filename%' contains atleast one character that is not allowed
			in your character set '%charset%'."]
		}


		set new_task_id [im_exec_dml new_task "im_trans_task__new (
			null,			-- task_id
			'im_trans_task',	-- object_type
			now(),			-- creation_date
			:user_id,		-- creation_user
			:ip_address,		-- creation_ip	
			null,			-- context_id	

			:project_id,		-- project_id	
			:task_type_id,		-- task_type_id	
			:task_status_id,	-- task_status_id
			:source_language_id,	-- source_language_id
			:target_language_id,	-- target_language_id
			:task_uom_id		-- task_uom_id
		)"]

		db_dml update_task "
		    UPDATE im_trans_tasks SET
			tm_integration_type_id = [im_trans_tm_integration_type_external],
			task_name = :task_name,
			task_filename = :task_name,
			description = :task_description,
			task_units = :task_units,
			billable_units = :billable_units,
			billable_units_interco = :billable_units_interco,
			match_x = :px_words,
			match_rep = :prep_words,
			match100 = :p100_words, 
			match95 = :p95_words,
			match85 = :p85_words,
			match75 = :p75_words, 
			match50 = :p50_words,
			match0 = :p0_words
		    WHERE 
			task_id = :new_task_id
		"

	    } err_msg] } {

		# Failed to create translation task
		incr err_count
	        append page_body "
<tr><td colspan=10>$insert_sql</td></tr>
<tr><td colspan=10><font color=red>$err_msg</font></td></tr>
"

	    } else {

		# Successfully created translation task
		# Call user_exit to let TM know about the event
		im_user_exit_call trans_task_create $new_task_id
		im_audit -object_type "im_trans_task" -object_id $new_task_id -action "after_create" -status_id $task_status_id -type_id $task_type_id

	    }

	}
    }


append page_body "</table>\n"
append page_body "\n<P><A HREF=$return_url>[_ intranet-translation.lt_Return_to_previous_pa]</A></P>\n"


# Remove the wordcount file
if { [catch {
    exec /bin/rm $wordcount_file
} err_msg] } {
    ad_return_complaint 1 "<li>[_ intranet-translation.lt_Error_deleting_the_te]"
    return
}

if {0 == $err_count} {
    # No errors - return to the $return_url
    ad_returnredirect $return_url
    return
}

db_release_unused_handles
ad_return_template
