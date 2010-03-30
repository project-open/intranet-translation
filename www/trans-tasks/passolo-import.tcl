# /packages/intranet-translation/www/trans-tasks/passolo-import.tcl
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
# Security
# ---------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set ip_address [ad_conn peeraddr]
im_project_permissions $user_id $project_id view read write admin
if {!$write} {
    append 1 "<li>[_ intranet-translation.lt_You_have_insufficient_3]"
    return
}

# Check for accents and other non-ascii characters
set charset [ad_parameter -package_id [im_package_filestorage_id] FilenameCharactersSupported "" "alphanum"]

# Inter-Company invoicing enabled?
set interco_p [parameter::get_from_package_key -package_key "intranet-translation" -parameter "EnableInterCompanyInvoicingP" -default 0]


# ---------------------------------------------------------------------
# Get the file and deal with Unicode encoding...
# ---------------------------------------------------------------------


ns_log Notice "passolo-import: wordcount_file=$wordcount_file"

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
ns_log Notice "passolo-import: encoding_hex=$encoding_hex"

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

set page_title "[_ intranet-translation.Passolo_Upload]"
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
	        and p.company_id = c.company_id
"



if { ![db_0or1row projects_info_query $project_query] } {
    ad_return_complaint 1 "[_ intranet-translation.lt_Cant_find_the_project]"
	ad_script_abort
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
    set passolo_files_content [read $fl]
    close $fl
} err]} {
    ad_return_complaint 1 "Unable to open file $wordcount_file:<br><pre>\n$err</pre>"
    ad_script_abort
}


#Check the Xml document whether it is Passolo or not
if {[catch {
	set doc [dom parse $passolo_files_content]
} err]} {
    ad_return_complaint 1 "Unable to parse file $wordcount_file "
    ad_script_abort
}

set root_element [$doc documentElement]
set nodeName [$root_element nodeName] 

if { [string tolower $nodeName] == "report" } {
    ns_log Notice "passolo-import: The valid Passolo xml file detected."       
} else {
    ns_log Notice "passolo-import: Non-valid Passolo xml file detected."
    ad_return_complaint 1 "Unable to detect the version of the Passolo file. Please, check if it is a valid one."
    ad_script_abort
}  

#Gather task name from the <projectpath> element
set projectpaths [$root_element getElementsByTagName "projectpath"]
set node_projectpath [lindex $projectpaths 0]
set filename [$node_projectpath text]  

#get the name of the file
set filename_comps [split $filename "\\"]
set len [expr [llength $filename_comps] - 1]
set task_name [lindex $filename_comps $len]
set filename [join $filename_comps "/"]

#Setting of default values
set px_words	0
set prep_words	0
set p100_words	0
set p95_words	0
set p85_words	0
set p75_words	0
set p50_words	0
set p0_words	0

set attr_stat_words "stat_words"

#Gather analysis data from the <statistics> element
set statistics [$root_element getElementsByTagName "statistics"]
set node_statistics [lindex $statistics 0]

foreach statisticsChildElement [$node_statistics childNodes] {
    set elementName [string tolower [$statisticsChildElement nodeName]]
	
    switch $elementName {
	"stat_untranslated_repeated" {
	    set stat_words	[$statisticsChildElement getElementsByTagName $attr_stat_words]
	    set node_stat_word [lindex $stat_words 0]
	    set prep_words [string map -nocase {"," "" "." ""} [$node_stat_word text]]	
	}
	"stat_untranslated" {
	    set stat_words	[$statisticsChildElement getElementsByTagName $attr_stat_words]
	    set node_stat_word [lindex $stat_words 0]
	    set p0_words [string map -nocase {"," "" "." ""} [$node_stat_word text]]	
	}
	"stat_autotrans" {
	    set stat_words	[$statisticsChildElement getElementsByTagName $attr_stat_words]
	    set node_stat_word [lindex $stat_words 0]
	    set words_value [string map -nocase {"," "" "." ""} [$node_stat_word text]]
	    set range [$statisticsChildElement getAttribute "range"]
	    
	    switch $range {
		"100%" 		{ set p100_words $words_value}
		"95% - 99%" { set p95_words $words_value}
		"85% - 94%" { set p85_words $words_value}
		"75% - 84%" { set p75_words $words_value}
		"50% - 74%" { set p50_words $words_value}
	    }
	}
    }
}

append page_body "
	<P>
	<tr><td colspan=2 class=rowtitle align=center>
	  [_ intranet-translation.Wordcount_Import]
	</td></tr>
	<tr><td>Passolo</td><td>test</td></tr>
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
		<tr>
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
	ns_log Notice "passolo-import: Creating new task ( $task_name )."
	
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
		
	ns_log Notice "passolo-import: Updating new task ( $task_name ) ."

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
	ns_log Notice "passolo-import: New task ( $task_name ) updated."
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
ns_log Notice "passolo-import: Import done..."

db_release_unused_handles
ad_return_template
