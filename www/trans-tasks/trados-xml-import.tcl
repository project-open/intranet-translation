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
    {import_method "Asp"}
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

# Check for accents and other non-ascii characters
set charset [ad_parameter -package_id [im_package_filestorage_id] FilenameCharactersSupported "" "alphanum"]

# Inter-Company invoicing enabled?
set interco_p [parameter::get_from_package_key -package_key "intranet-translation" -parameter "EnableInterCompanyInvoicingP" -default 0]

# Check if the wordcount_file is from the /tmp/ location
im_security_alert_check_tmpnam -location "trados-xml-import.tcl" -value $wordcount_file


# ---------------------------------------------------------------------
# Get the file and deal with Unicode encoding...
# ---------------------------------------------------------------------

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
		im_projects p
	      LEFT JOIN
		im_companies c USING (company_id)
	where
		p.project_id=:project_id
"

if { ![db_0or1row projects_info_query $project_query] } {
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
    set trados_files_content [read $fl]
    close $fl
} err]} {
    ad_return_complaint 1 "Unable to open file $wordcount_file:<br><pre>\n$err</pre>"
    return
}

# ---------------------------------------------------------------------
# Define some constants
# ---------------------------------------------------------------------

set attr_segments "segments"
set attr_words "words"
set attr_characters "characters"
set attr_placeables "placeables"
set attr_characters "characters"
set attr_min "min"
set attr_max "max"
set attr_name "name"

# Parse the Trados 9.0 XML
#
if {[catch {set doc [dom parse $trados_files_content]} err_msg]} {
 
    ad_return_complaint 1 "Error parsing Trados XML:<br><pre>$err_msg</pre>"
    ad_script_abort
}

# TRADOS version 9.0 XML test logic 
set root_element [$doc documentElement]
set nodeName [$root_element nodeName] 

# Make sure the root element is "task"
#
if { [string tolower $nodeName] == "task" } {

    set trados_version "9.0"
    set list_files [$root_element getElementsByTagName "file"]       
    set trados_files_len [llength $list_files]

} else {

    ad_return_complaint 1 "Unable to detect the version of the Trados file:<br>
	Please, check if the uploaded file is a valid Trados XML analysis."
    ad_script_abort

}  

# Loop through all "task" elements in the Trados XML structure
set ctr 0
for {set i 0} {$i < $trados_files_len} {incr i} {

    if {[string equal $trados_version "9.0"]} {
	set childnode [lindex $list_files $i]
	set filename [$childnode getAttribute $attr_name]
	
	ns_log Notice "trados-import: Xml import of the $filename file."
	set analyseElement [$childnode firstChild] 
	
	foreach analyseChildElement [$analyseElement childNodes] {
	    set elementName [string tolower [$analyseChildElement nodeName]]
	    
	    #going through the attributes of the "analyse" element
	    switch $elementName {
		"incontextexact" {
		    set px_segments [$analyseChildElement getAttribute $attr_segments]
		    set px_words [$analyseChildElement getAttribute $attr_words] 
		    set px_placeables [$analyseChildElement getAttribute $attr_placeables]  
		}
		"exact" {
		    set p100_segments [$analyseChildElement getAttribute $attr_segments]
		    set p100_words [$analyseChildElement getAttribute $attr_words] 
		    set p100_placeables [$analyseChildElement getAttribute $attr_placeables]		    
		}
		"repeated" {
		    set prep_segments [$analyseChildElement getAttribute $attr_segments]
		    set prep_words [$analyseChildElement getAttribute $attr_words] 
		    set prep_placeables [$analyseChildElement getAttribute $attr_placeables]
		}
		"new" {
		    set p0_segments [$analyseChildElement getAttribute $attr_segments]
		    set p0_words [$analyseChildElement getAttribute $attr_words] 
		    set p0_placeables [$analyseChildElement getAttribute $attr_placeables]
		}
		"fuzzy" {
		    
		    #going through all "fuzzy" elements
		    switch [$analyseChildElement getAttribute $attr_min] {
			"95" {
			    set p95_segments [$analyseChildElement getAttribute $attr_segments]
			    set p95_words [$analyseChildElement getAttribute $attr_words] 
			    set p95_placeables [$analyseChildElement getAttribute $attr_placeables]
			}
			"85" {
			    set p85_segments [$analyseChildElement getAttribute $attr_segments]
			    set p85_words [$analyseChildElement getAttribute $attr_words] 
			    set p85_placeables [$analyseChildElement getAttribute $attr_placeables]			  
			}
			"75" {
			    set p75_segments [$analyseChildElement getAttribute $attr_segments]
			    set p75_words [$analyseChildElement getAttribute $attr_words] 
			    set p75_placeables [$analyseChildElement getAttribute $attr_placeables]			  
			}
			"50" {
			    set p50_segments [$analyseChildElement getAttribute $attr_segments]
			    set p50_words [$analyseChildElement getAttribute $attr_words] 
			    set p50_placeables [$analyseChildElement getAttribute $attr_placeables]			  
			}				
		    } 
		} 
	    }  
	}  
    } 
    
  
    set task_name $filename

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

	    db_transaction {
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
	    }

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
	    im_audit -object_type "im_trans_task" -action after_create -object_id $new_task_id -status_id $task_status_id -type_id $task_type_id
	    
	}
	
    } 
    # end of foreach
}
#end of the for loop


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
