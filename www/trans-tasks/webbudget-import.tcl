# /packages/intranet-translation/www/trans-tasks/webbudget-import.tcl
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
set webbudget_wordcount_file $wordcount_file

# ---------------------------------------------------------------------
# Get some more information about the project
# ---------------------------------------------------------------------

set customer_id ""
set project_query "
	select
	        p.project_nr as project_short_name,
	        p.company_id as customer_id,
	        c.company_name as company_short_name,
	        p.source_language_id,
	        p.project_type_id
	from
	        im_projects p
	      LEFT JOIN
	        im_companies c on (p.company_id = c.company_id)
	where
	        p.project_id = :project_id
"

if { ![db_0or1row projects_info_query $project_query] } {
    ad_return_complaint 1 "[_ intranet-translation.lt_Cant_find_the_project]"
    return
}

if {"" == $customer_id} {
    ad_return_complaint 1 "[_ intranet-translation.lt_Cant_find_the_project]"
    return
}

# ---------------------------------------------------------------------
# Get the file and deal with Unicode encoding...
# ---------------------------------------------------------------------

ns_log Notice "webbudget-import: wordcount_file=$wordcount_file"

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
ns_log Notice "webbudget-import: encoding_hex=$encoding_hex"

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

set page_title "[lang::message::lookup "" intranet-translation.Webbudget_Upload "Webbudget Upload"]"
set context_bar [im_context_bar [list /intranet/projects/ "[_ intranet-translation.Projects]"] $page_title]

set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"

# Number of errors encountered
set err_count 0

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
    set webbudget_files_content [read $fl]
    close $fl
} err]} {
    ad_return_complaint 1 "Unable to open file $wordcount_file:<br><pre>\n$err</pre>"
    return
}


# Extract the header line from the file
set separator "\t"
set webbudget_files [split $webbudget_files_content "\n"]
set webbudget_files_len [llength $webbudget_files]
set webbudget_header [lindex $webbudget_files 0]
set webbudget_headers [im_csv_split $webbudget_header $separator]
set webbudget_header_len [llength $webbudget_headers]

ns_log Notice "webbudget-import: webbudget_header='$webbudget_header'"
ns_log Notice "webbudget-import: webbudget_headers='$webbudget_headers'"
ns_log Notice "webbudget-import: webbudget_header_len=$webbudget_header_len"


# "Normalize" the header line to make the strings suitable as variables. 
# There is an ugly double-space in the "Total  Words" string that we 
# reduce to a single space. Also, we might want to normalize other 
# changes in the next versions
set headers [list]
foreach h $webbudget_headers {
    set h [string tolower [string map -nocase {"  " "_" " " "_" "'" "" "/" "_" "-" "_"} $h]]
    lappend headers $h
}
set webbudget_headers $headers
# ad_return_complaint 1 "<pre>$webbudget_headers</pre>"


# Determine the Webbudget version -
# Very easy right now, just check if "total_words" is there...
set webbudget_version "unknown"
if {[lsearch $webbudget_headers "total_words"] >= 0} { set webbudget_version "3.9" }
ns_log Notice "webbudget-import: webbudget_version=$webbudget_version, webbudget_header_len=$webbudget_header_len, separator=$separator"
if {[string equal "unknown" $webbudget_version]} {
    ad_return_complaint 1 "
        <li>[_ intranet-translation.Unknown_Webbudget_Version]<br>
	[_ intranet-translation.Your_file_webbudget_word]<BR>
	[_ intranet-translation.Please_repeat_your_ana]"
    return
}

# ---------------------------------------------------------------------
# Split the file into a two-dimensinal array
# ---------------------------------------------------------------------

set values_list_of_lists [im_csv_get_values $webbudget_files_content $separator]
set values_list_len [llength $values_list_of_lists]


set ttt ""
foreach line $values_list_of_lists {
    set len [llength $line]
    append ttt "$line  - $len\n"
}
# ad_return_complaint 1 "<pre>$ttt</pre>"


# ---------------------------------------------------------------------
# Determine the common filename components in the list of 
# webbudget files. These components are chopped off later in
# the loop.
# ---------------------------------------------------------------------

set first_line [lindex $values_list_of_lists 0]
set first_filename [lindex $first_line 1]
set first_filename_comps [split $first_filename "\\"]
ns_log Notice "webbudget-import: first_filename=$first_filename"
ns_log Notice "webbudget-import: first_filename_comps=$first_filename_comps"


set common_filename_comps 0
set all_the_same 1
set ctr 0
set first_filename_comps_len [llength $first_filename_comps]

while {$all_the_same && $ctr < $first_filename_comps_len} {
    set common_component [lindex $first_filename_comps $ctr]
    ns_log Notice "webbudget-import: $ctr: first_filename_comps: prefix=$common_component"
    ns_log Notice "webbudget-import: $ctr: num_of_lines: $values_list_len"

    for {set i 1} {$i < $values_list_len} {incr i} {
	set webbudget_fields [lindex $values_list_of_lists $i]
	if {0 == [llength $webbudget_fields]} { continue }
	set filename [lindex $webbudget_fields 1]
	if {"\"\"\"\"" == $filename} { continue }
	if {"" == [lindex $webbudget_fields 2]} { continue }
	set filename_comps [split $filename "\\"]
	set this_component [lindex $filename_comps $ctr]

	ns_log Notice "webbudget-import: $ctr: $i: webbudget_fields=$webbudget_fields"
	ns_log Notice "webbudget-import: $ctr: $i: filename=$filename"
	ns_log Notice "webbudget-import: $ctr: $i: filename_comps=$filename_comps"
	ns_log Notice "webbudget-import: $ctr: $i: this_component=$this_component"
	ns_log Notice "webbudget-import: $ctr: $i: common_component=$common_component"
	
	if {![string equal $common_component $this_component]} {
	    ns_log Notice "webbudget-import: $ctr: $i: Found '$this_component' which does not suit the common_component '$common_component', aborting"
	    set all_the_same 0
	    break
	}
    }
    incr ctr
}
set common_filename_comps [expr $ctr - 1]
ns_log Notice "webbudget-import: common_filename_comps=$common_filename_comps"



# ---------------------------------------------------------------------
# Start rendering the page
# ---------------------------------------------------------------------

append page_body "
<P>
<tr><td colspan=2 class=rowtitle align=center>
  [_ intranet-translation.Wordcount_Import]
</td></tr>
<tr><td>Webbudget-Version</td><td>$webbudget_version</td></tr>
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


# ---------------------------------------------------------------------
# Start processing the page
# ---------------------------------------------------------------------


set ctr 0
foreach line_fields $values_list_of_lists {

    ns_log Notice "webbudget-import: line='$line_fields'"

    if {"" == [lindex $line_fields 2]} { continue }


    # Set the variables to "", because they might not be present
    # in the CSV file. In Webbudget you can choose the number of
    # fields to export...
    set info ""
    set name ""
    set total_words ""
    set time ""
    set repetitions ""


    # -------------------------------------------------------
    # Extract variables from the CSV file
    #
    set var_name_list [list]
    for {set j 0} {$j < $webbudget_header_len} {incr j} {

        set var_name [string trim [lindex $webbudget_headers $j]]
        if {"" == $var_name} {
            # No variable name - probably an empty column
            continue
        }

        lappend var_name_list $var_name
        ns_log notice "webbudget-import: varname([lindex $webbudget_headers $j]) = $var_name"

        set var_value [string trim [lindex $line_fields $j]]
        if {[string equal "NULL" $var_value]} { set var_value ""}

	# Normalize the variable. Replace komma by dot (European decimals)
	set var_value [string map -nocase {"," "."} $var_value]

        set cmd "set $var_name \"$var_value\""
        ns_log Notice "webbudget-import: cmd=$cmd"
        set result [eval $cmd]
    }

    if {![string is double $total_words]} { continue }

    if {"" == $repetitions} { set repetitions 0 }

    set px_words 0
    set prep_words $repetitions
    set p100_words 0
    set p95_words 0
    set p85_words 0
    set p75_words 0
    set p50_words 0
    set p0_words [expr int($total_words - $repetitions)]

    # Remove all common filename components from the task names

    set filename $name
    ns_log Notice "webbudget-import: filename='$filename', len=[string length $filename]"
    if {"" == $filename || "\"\"\"\"" == $filename} { continue }

    set filename_comps [split $filename "\\"]
    set len [expr [llength $filename_comps] - 1]
    set task_name_comps [lrange $filename_comps $common_filename_comps $len]
    set task_name [join $task_name_comps "/"]

    # Skip if it was an empty line

    if {"" == $total_words && "" == $repetitions} {
	ns_log Notice "webbudget-import: found an empty line - maybe the last one..."
	continue
    }

    # Calculate the number of "effective" words based on
    # a valuation of repetitions

    set task_units [im_trans_trados_matrix_calculate [im_company_freelance] $px_words $prep_words $p100_words $p95_words $p85_words $p75_words $p50_words $p0_words]

    set billable_units [im_trans_trados_matrix_calculate $customer_id $px_words $prep_words $p100_words $p95_words $p85_words $p75_words $p50_words $p0_words]

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
			'0.0.0.0',		-- creation_ip	
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
        } else {

	    # Successfully created translation task
	    # Call user_exit to let TM know about the event
	    im_user_exit_call trans_task_create $new_task_id
	    im_audit -object_type "im_trans_task" -action after_create -object_id $new_task_id -status_id $task_status_id -type_id $task_type_id
	    
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
