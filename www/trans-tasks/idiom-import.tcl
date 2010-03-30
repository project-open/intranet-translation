# /packages/intranet-translation/www/trans-tasks/idiom-import.tcl
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
    {import_method "Asp"}
}

# ---------------------------------------------------------------------
# 
# ---------------------------------------------------------------------

proc im_translation_idiomimport_error_message { header_name } {
	ad_return_complaint 1 "The file is not valid: There is no $header_name column header"
	ad_script_abort
    return
}

# ---------------------------------------------------------------------
# Security
# ---------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set ip_address [ad_conn peeraddr]
im_project_permissions $user_id $project_id view read write admin
if {!$write} {
    append 1 "<li>[_ intranet-translation.lt_You_have_insufficient_3]"
    return
}

# Compatibility with old message...
set idiom_wordcount_file $wordcount_file

# Check for accents and other non-ascii characters
set charset [ad_parameter -package_id [im_package_filestorage_id] FilenameCharactersSupported "" "alphanum"]

# Inter-Company invoicing enabled?
set interco_p [parameter::get_from_package_key -package_key "intranet-translation" -parameter "EnableInterCompanyInvoicingP" -default 0]


# ---------------------------------------------------------------------
# Get the file and deal with Unicode encoding...
# ---------------------------------------------------------------------

ns_log Notice "idiom-import: wordcount_file=$wordcount_file"


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
ns_log Notice "idiom-import: encoding_hex=$encoding_hex"

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



# ---------------------------------------------------------------------
# Title and bread crum
# ---------------------------------------------------------------------

set project_path [im_filestorage_project_path $project_id]

set page_title [lang::message::lookup "" intranet-translation.Idiom_Upload "Idiom Upload"]
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
	        p.project_id = :project_id
	        and p.company_id=c.company_id
"



if { ![db_0or1row projects_info_query $project_query] } {
    ad_return_complaint 1 "[_ intranet-translation.lt_Cant_find_the_project]"
    ad_script_abort
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
    set idiom_files_content [read $fl]
    close $fl
} err]} {
    ad_return_complaint 1 "Unable to open file $wordcount_file:<br><pre>\n$err</pre>"
	ad_script_abort
    return
}


set idiom_files [split $idiom_files_content "\n"]
set idiom_files_len [llength $idiom_files]
set idiom_header [lindex $idiom_files 0]
set idiom_total [lindex $idiom_files $idiom_files_len-1]

set separator ","
set idiom_headers [split $idiom_header $separator]

if {1 == [llength $idiom_headers]} {
    # Probably got the wrong separator
    set separator ";"
    set idiom_headers [split $idiom_header $separator]
}

# Check the header
# if there is the target language (target locale) as the first column
set column_shift 0
if {[string first "target locale" [string tolower [lindex $idiom_headers 0]]] != -1} {
	ns_log Notice "idiom-import: The first column is 'target locale' and must be left out."
	set	column_shift 1
}

#check if it has all range columns like Trados: 100%,100-95%,95-85%,85-75%,75-50%,50-0%,Repetition

if {[lsearch -nocase $idiom_headers "100%"] == -1} {
    im_translation_idiomimport_error_message "100%"
}
if {[lsearch -nocase $idiom_headers "Repetition"] == -1} {
    im_translation_idiomimport_error_message "Repetition"
}
if {[lsearch -nocase $idiom_headers "100-95%"] == -1} {
    im_translation_idiomimport_error_message "100-95%"
}
if {[lsearch -nocase $idiom_headers "95-85%"] == -1} {
    im_translation_idiomimport_error_message "95-85%"
}
if {[lsearch -nocase $idiom_headers "85-75%"] == -1} {
    im_translation_idiomimport_error_message "85-75%"
}
if {[lsearch -nocase $idiom_headers "75-50%"] == -1} {
    im_translation_idiomimport_error_message "75-50%"
}
if {[lsearch -nocase $idiom_headers "50-0%"] == -1} {
    im_translation_idiomimport_error_message "50-0%"
}

append page_body "
	<P>
	<tr><td colspan=2 class=rowtitle align=center>
	  [_ intranet-translation.Wordcount_Import]
	</td></tr>
	<tr><td>Idiom-Version</td><td>test</td></tr>
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

set common_filename_comps 0

ns_log Notice "idiom-import: import_method=$import_method"

set first_idiom_line [lindex $idiom_files 1]
set first_idiom_fields [split $first_idiom_line $separator]
set first_filename [lindex $first_idiom_fields 1]
set first_filename_comps [split $first_filename "/"]

ns_log Notice "idiom-import: first_idiom_line=$first_idiom_line"
ns_log Notice "idiom-import: first_idiom_fields=$first_idiom_fields"
ns_log Notice "idiom-import: first_filename=$first_filename"
ns_log Notice "idiom-import: first_filename_comps=$first_filename_comps"


set all_the_same 1
set ctr 0
set fist_filename_comps_len [llength $first_filename_comps]

set common_filename_comps [expr $ctr - 1]
ns_log Notice "idiom-import: common_filename_comps=$common_filename_comps"

set ctr 0
for {set i 1} {$i < $idiom_files_len} {incr i} {
    incr ctr
    set idiom_line [lindex $idiom_files $i]
    
    set idiom_fields 	[split $idiom_line $separator]
    set filename    	[lindex $idiom_fields $column_shift+0]
    set px_words	[lindex $idiom_fields $column_shift+2]
    set prep_words	[lindex $idiom_fields $column_shift+9]
    set p100_words	[lindex $idiom_fields $column_shift+3]
    set p95_words	[lindex $idiom_fields $column_shift+4]
    set p85_words	[lindex $idiom_fields $column_shift+5]
    set p75_words	[lindex $idiom_fields $column_shift+6]
    set p50_words	[lindex $idiom_fields $column_shift+7]
    set p0_words	[lindex $idiom_fields $column_shift+8]
    
    set task_name $filename

    # Skip if it was an empty line
    if {"" == $px_words && "" == $prep_words && "" == $p100_words} {
	ns_log Notice "idiom-import: found an empty line - maybe the last one..."
	continue
    }
	
    if { [string first "total" [string tolower $filename]] != -1 } {
	#ad_return_complaint 1 "Idiom import> $task_name $filename $px_words $prep_words $p100_words $p95_words $p85_words $p75_words $p50_words $p0_words"
	ns_log Notice "idiom-import: found a total line - maybe the last one... The name of the Total row: $filename"
	continue
    }
	
    #get the name of the file
    set filename [string map -nocase {"\"" ""} $filename] 
    set filename_comps [split $filename "/"]
    set len [expr [llength $filename_comps] - 1]
    set task_name [lindex $filename_comps $len]
    set task_name_comps [lrange $filename_comps $common_filename_comps $len]
    set filename [join $task_name_comps "/"]
    
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
	    
	    ns_log Notice "idiom-import: Creating new task ( $task_name )."
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
		
	    ns_log Notice "idiom-import: Updating new task ( $task_name ) ."
	    
	    db_dml update_task "
		    UPDATE im_trans_tasks SET
			tm_integration_type_id = [im_trans_tm_integration_type_external],
			task_name = :task_name,
			task_filename = :filename,
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
	    ns_log Notice "idiom-import: New task ( $task_name ) updated."
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
ns_log Notice "idiom-import: Import done..."

db_release_unused_handles
ad_return_template
