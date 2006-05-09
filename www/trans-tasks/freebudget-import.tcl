# /packages/intranet-translation/www/trans-tasks/freebudget-import.tcl
#
# Copyright (C) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Purpose: Import the contents of a wordcount.txt file
    into the current projects as a list of "im_tasks"

    @param return_url the url to return to
    @param project_id group id
} {
    return_url
    project_id:integer
    wordcount_file
}

# ---------------------------------------------------------------------
# Security
# ---------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
im_project_permissions $user_id $project_id view read write admin
if {!$write} {
    append 1 "<li>[_ intranet-translation.lt_You_have_insufficient_3]"
    return
}

# Compatibility with old message...
set trados_wordcount_file $wordcount_file

# ---------------------------------------------------------------------
# Get the file and deal with Unicode encoding...
# ---------------------------------------------------------------------

ns_log Notice "freebudget-import: wordcount_file=$wordcount_file"

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
ns_log Notice "freebudget-import: encoding_hex=$encoding_hex"

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

set project_path [im_filestorage_project_path $project_id]

set page_title "[lang::message::lookup "" intranet-translation.Freebudget_Upload "FreeBudget Upload"]"
set context_bar [im_context_bar [list /intranet/projects/ "[_ intranet-translation.Projects]"] $page_title]

set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"

# Number of errors encountered
set err_count 0

# ---------------------------------------------------------------------
# Get some more information about the project
# ---------------------------------------------------------------------

if { ![db_0or1row projects_info_query ""] } {
    ad_return_complaint 1 "[_ intranet-translation.lt_Cant_find_the_project]"
    return
}


# ---------------------------------------------------------------------
# Start parsing the wordcount file
# ---------------------------------------------------------------------

append page_body "
<P><A HREF=$return_url>[_ intranet-translation.lt_Return_to_previous_pa]</A></P>
<table cellpadding=0 cellspacing=2 border=0>
"


if {[catch {
    set fl [open $wordcount_file]
    fconfigure $fl -encoding $encoding 
    set freebudget_files_content [read $fl]
    close $fl
} err]} {
    ad_return_complaint 1 "Unable to open file $wordcount_file:<br><pre>\n$err</pre>"
    return
}

set separator ","

set freebudget_files [split $freebudget_files_content "\n"]
set freebudget_files_len [llength $freebudget_files]
set freebudget_header [lindex $freebudget_files 0]
set freebudget_headers [split $freebudget_header $separator]
set freebudget_header_len [llength $freebudget_headers]

switch $freebudget_header_len {
    14 { set freebudget_version "5.0" }
    default { set freebudget_version "unknown" }
}

ns_log Notice "freebudget-import: freebudget_version=$freebudget_version, freebudget_header_len=$freebudget_header_len, separator=$separator"


append page_body "
<P>
<tr><td colspan=2 class=rowtitle align=center>
  [_ intranet-translation.Wordcount_Import]
</td></tr>
<tr><td>Freebudget-Version</td><td>$freebudget_version</td></tr>
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

if {[string equal "unknown" $freebudget_version]} {
    ad_return_complaint 1 "
        <li>[_ intranet-translation.lt_Unknown_Freebudget_Versio]<br>
	[_ intranet-translation.lt_Your_file_freebudget_word]<BR>
	[_ intranet-translation.lt_Please_try_to_repeat_]"
    return
}

# Determine the common filename components in the list of 
# freebudget files. These components are chopped off later in
# the loop.
# This procedure is not necessary for LocalFs import.
set common_filename_comps 0

set first_freebudget_line [lindex $freebudget_files 1]
set first_freebudget_fields [split $first_freebudget_line $separator]
set first_filename "[lindex $first_freebudget_fields 1][lindex $first_freebudget_fields 2]"
set first_filename_comps [split $first_filename "\\"]

ns_log Notice "freebudget-import: first_freebudget_line=$first_freebudget_line"
ns_log Notice "freebudget-import: first_freebudget_fields=$first_freebudget_fields"
ns_log Notice "freebudget-import: first_filename=$first_filename"
ns_log Notice "freebudget-import: first_filename_comps=$first_filename_comps"

set all_the_same 1
set ctr 0
set first_filename_comps_len [llength $first_filename_comps]

while {$all_the_same && $ctr < $first_filename_comps_len} {
    set common_component [lindex $first_filename_comps $ctr]
    ns_log Notice "freebudget-import: first_filename_comps: prefix=$common_component"
    ns_log Notice "freebudget-import: freebudget_files_len=$freebudget_files_len"

    for {set i 1} {$i < $freebudget_files_len} {incr i} {
	set freebudget_line [lindex $freebudget_files $i]
	if {0 == [string length $freebudget_line]} { continue }
	
	set freebudget_fields [split $freebudget_line $separator]
	set filename "[lindex $freebudget_fields 1][lindex $freebudget_fields 2]"

	if {"\"\"\"\"" == $filename} { continue }

	set filename_comps [split $filename "\\"]
	set this_component [lindex $filename_comps $ctr]

	ns_log Notice "freebudget-import: filename=$filename"
	ns_log Notice "freebudget-import: freebudget_line=$freebudget_line"
	ns_log Notice "freebudget-import: filename_comps=$filename_comps"
	ns_log Notice "freebudget-import: this_component=$this_component"
	ns_log Notice "freebudget-import: common_component=$common_component"
	
	if {![string equal $common_component $this_component]} {
	    set all_the_same 0
	    break
	}
    }
    incr ctr
}
set common_filename_comps [expr $ctr - 1]

ns_log Notice "freebudget-import: common_filename_comps=$common_filename_comps"


set ctr 0
for {set i 1} {$i < $freebudget_files_len} {incr i} {
    incr ctr
    set freebudget_line [lindex $freebudget_files $i]
    set freebudget_line "$freebudget_line $separator X"
    if {0 == [string length $freebudget_line]} { continue }

    set freebudget_fields [im_csv_split $freebudget_line $separator]

    # Replace "," by "." with European format...
    # May break with big files??
    regsub -all {\,} $freebudget_fields "\." freebudget_fields

    set status		[lindex $freebudget_fields 0]
    set path		[lindex $freebudget_fields 1]
    set file		[lindex $freebudget_fields 2]
    set fb_text		[lindex $freebudget_fields 3]
    set fb_headers	[lindex $freebudget_fields 4]
    set fb_footers	[lindex $freebudget_fields 5]
    set fb_footnotes	[lindex $freebudget_fields 6]
    set fb_endnotes	[lindex $freebudget_fields 7]
    set fb_text_in_shapes [lindex $freebudget_fields 8]
    set fb_annotations	[lindex $freebudget_fields 9]
    set fb_total_words	[lindex $freebudget_fields 10]
    set fb_price	[lindex $freebudget_fields 11]
    set fb_time		[lindex $freebudget_fields 12]
    set fb_repetitions	[lindex $freebudget_fields 13]

    if {"" == $fb_repetitions} { continue }

    set px_words 0
    set prep_words $fb_repetitions
    set p100_words 0
    set p95_words 0
    set p85_words 0
    set p75_words 0
    set p50_words 0
    set p0_words [expr int($fb_total_words - $fb_repetitions)]

    # Remove all common filename components from the task names

    set filename "$path$file"
    ns_log Notice "freebudget-import: filename='$filename', len=[string length $filename]"
    if {"" == $filename || "\"\"\"\"" == $filename} { continue }

    set filename_comps [split $filename "\\"]
    set len [expr [llength $filename_comps] - 1]
    set task_name_comps [lrange $filename_comps $common_filename_comps $len]
    set task_name [join $task_name_comps "/"]

    # Skip if it was an empty line

    if {"" == $px_words && "" == $prep_words && "" == $p100_words} {
	ns_log Notice "freebudget-import: found an empty line - maybe the last one..."
	continue
    }

    # Calculate the number of "effective" words based on
    # a valuation of repetitions
    
#    ad_return_complaint 1 "freebudget-import: im_trans_trados_matrix_calculate $company_id fb_total=$fb_total_words fb_rep=$fb_repetitions px=$px_words rep=$prep_words 100=$p100_words 95=$p95_words 85=$p85_words 75=$p75_words 50=$p50_words 0=$p0_words"

    ns_log Notice "freebudget-import: im_trans_trados_matrix_calculate $company_id $px_words $prep_words $p100_words $p95_words $p85_words $p75_words $p50_words $p0_words"


    set task_units [im_trans_trados_matrix_calculate $company_id $px_words $prep_words $p100_words $p95_words $p85_words $p75_words $p50_words $p0_words]
    
    set billable_units $task_units
    set task_type_id $project_type_id
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
			task_name = :task_name,
			task_filename = :task_name,
			description = :task_description,
			task_units = :billable_units,
			billable_units = :task_units,
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
	    incr err_count
	    append page_body "
<tr><td colspan=10>$insert_sql</td></tr>
<tr><td colspan=10><font color=red>$err_msg</font></td></tr>
"
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
