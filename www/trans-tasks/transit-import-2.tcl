# /packages/intranet-translation/www/trans-tasks/transit-import-2.tcl
#
# Copyright (c) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Purpose: Import the contents of a wordcount.rep file
    into the current projects as a list of "im_task"s

    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    return_url
    project_id:integer
    task_type_id:integer
    { target_language_id "" }
    { import_method "Asp" }
    { import_p:array }
    filename_list:array
    { task_type_list:array }
    px_words_list:array
    prep_words_list:array
    p100_words_list:array
    p95_words_list:array
    p85_words_list:array
    p75_words_list:array
    p50_words_list:array
    p0_words_list:array
    repetitions:array
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

set page_title [lang::message::lookup "" intranet-translation.Transit_Upload_Wizard "Transit Upload Wizard"]
set context_bar [im_context_bar [list /intranet/projects/ "[_ intranet-translation.Projects]"] $page_title]

set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"
set err_count 0

set interco_p [parameter::get_from_package_key -package_key "intranet-translation" -parameter "EnableInterCompanyInvoicingP" -default 0]

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
	        LEFT JOIN im_companies c USING (company_id)
	where
	        p.project_id = :project_id
"

if { ![db_0or1row projects_info_query $project_query] } {
    ad_return_complaint 1 "[_ intranet-translation.lt_Cant_find_the_project]"
    return
}

set target_language_ids [im_target_language_ids $project_id]
if {"" != $target_language_id} {
    set target_language_ids $target_language_id
}


set page_body "
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

foreach ctr [array names filename_list] {

    set filename		$filename_list($ctr)
    set px_words		$px_words_list($ctr)
    if { "Asp" == $import_method } {	
	 set prep_words		$repetitions($ctr)
    } else { 
         set prep_words		$rep_words_list($ctr)
    }
    set p100_words		$p100_words_list($ctr)
    set p95_words		$p95_words_list($ctr)
    set p85_words		$p85_words_list($ctr)
    set p75_words		$p75_words_list($ctr)
    set p50_words		$p50_words_list($ctr)
    set p0_words		$p0_words_list($ctr)
    set task_type_id            $task_type_list($ctr)
    set task_name $filename

    set checked_p 0

    if {[info exists import_p($ctr)]} { set checked_p $import_p($ctr) }

    # Determine the wordcount of the task:
    # Get the "task_units" from the company "default_freelance"
    # and the "billable_units" form the project's customer:
    #
    set task_units [im_trans_trados_matrix_calculate [im_company_freelance] $px_words $prep_words $p100_words $p95_words $p85_words $p75_words $p50_words $p0_words]
    
    set billable_units [im_trans_trados_matrix_calculate $customer_id $px_words $prep_words $p100_words $p95_words $p85_words $p75_words $p50_words $p0_words]
    
    
    set task_status_id 340
    set task_description ""
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
    if {$checked_p} {

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

		if { !$interco_p } {
		db_dml update_task "
		    UPDATE im_trans_tasks SET
			tm_integration_type_id = [im_trans_tm_integration_type_external],
			task_name = :task_name,
			task_filename = :task_name,
			description = :task_description,
			task_units = :task_units,
			billable_units = :billable_units,
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
		} else {
		       
		    set interco_company_id [db_string get_interco_company "select interco_company_id from im_projects where project_id=$project_id" -default ""]
		    if {"" == $interco_company_id} {
			set interco_company_id $customer_id
		    }
		    set billable_units_interco [im_trans_trados_matrix_calculate $interco_company_id $px_words $prep_words $p100_words $p95_words $p85_words $p75_words $p50_words $p0_words]
		    
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
		append page_body "<tr><td colspan=10>$insert_sql</td></tr><tr><td colspan=10><font color=red>$err_msg</font></td></tr>"

	    } else {
	    
		# Successfully created translation task
		# Call user_exit to let TM know about the event
		im_user_exit_call trans_task_create $new_task_id
		im_audit -object_type "im_trans_task" -object_id $new_task_id -action "after_create" -status_id $task_status_id -type_id $task_type_id
		
	    }
	
	}
    }
}

append page_body "</table>\n"
append page_body "\n<P><A HREF=$return_url>[_ intranet-translation.lt_Return_to_previous_pa]</A></P>\n"



if {0 == $err_count} {
    # No errors - return to the $return_url
    ad_returnredirect $return_url
    return
}

db_release_unused_handles
ad_return_template
