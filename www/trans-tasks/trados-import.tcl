# /www/intranet/projects/task-save.tcl

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
    trados_wordcount_file
    {import_method "Asp"}
}

# ---------------------------------------------------------------------
# Defaults & security
# ---------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
im_project_permissions $user_id $project_id view read write admin
if {!$write} {
    append 1 "<li>You have insufficient privileges to view this page.\n"
    return
}

set target_language_ids [im_target_language_ids $project_id im_projects]
if {0 == [llength $target_language_ids]} {
    ad_return_complaint 1 "<li>The project has no target language defined,
        so we are unable to add translation tasks to the project.<BR>
        Please back up to the project page and add at least one
        target language to the project."
    return
}

set project_path [im_filestorage_project_path $project_id]

set page_title "Trados Upload"
set context_bar [ad_context_bar [list /intranet/projects/ "Projects"] $page_title]

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
        c.customer_name as customer_short_name,
        p.source_language_id,
        p.project_type_id
from
        im_projects p,
        im_customers c
where
        p.project_id=:project_id
        and p.customer_id=c.customer_id(+)"



if { ![db_0or1row projects_info_query $project_query] } {
    ad_return_complaint 1 "Can't find the project with group 
    id of $project_id"
    return
}


# ---------------------------------------------------------------------
# Start parsing the wordcount file
# ---------------------------------------------------------------------

append page_body "
<P><A HREF=$return_url>Return to previous page</A></P>
<table cellpadding=0 cellspacing=2 border=0>
"

set trados_files_content [exec /bin/cat $trados_wordcount_file]
set trados_files [split $trados_files_content "\n"]
set trados_files_len [llength $trados_files]
set trados_header [lindex $trados_files 1]
set trados_headers [split $trados_header ";"]

# Distinguish between Trados 3 and Trados 5.5 files
#
set line2 [lindex $trados_files 2]
set line2_len [llength [split $line2 ";"]]
switch $line2_len {
    39 { set trados_version "5.5" }
    38 { set trados_version "5.0" }
    25 { set trados_version "3" }
    default { set trados_version "unknown" }
}

append page_body "
<P>
<tr><td colspan=2 class=rowtitle align=center>
  Wordcount Import
</td></tr>
<tr><td>Trados-Version</td><td>$trados_version</td></tr>
<tr><td>Project Path</td><td>$project_path</td></tr>
</table>

<P>

<table cellpadding=0 cellspacing=2 border=0>
<tr>
  <td class=rowtitle align=center>Filename</td>
  <td class=rowtitle align=center>Task Name</td>
  <td class=rowtitle align=center>100%</td>
  <td class=rowtitle align=center>95%</td>
  <td class=rowtitle align=center>85%</td>
  <td class=rowtitle align=center>75%</td>
  <td class=rowtitle align=center>50%</td>
  <td class=rowtitle align=center>0%</td>
  <td class=rowtitle align=center>Weighted</td>
</tr>
"

if {[string equal "unknown" $trados_version]} {
    ad_return_complaint 1 "
        <li>Unknown Trados Version<br>
	Your file '$trados_wordcount_file' has not been<BR>
	created with one of the supported Trados versions (3.0 and 5.5).<BR>
	Please try to repeat your Trados analsyis or inform the
	system administrator."
    return
}

# Determine the common filename components in the list of 
# trados files. These components are chopped off later in
# the loop.
# This procedure is not necessary for LocalFs import.
set common_filename_comps 0

ns_log Notice "import_method=$import_method"
if {[string equal $import_method "Asp"]} {
    set first_trados_line [lindex $trados_files 2]
    set first_trados_fields [split $first_trados_line ";"]
    set first_filename [lindex $first_trados_fields 0]
    set first_filename_comps [split $first_filename "\\"]

    ns_log Notice "first_trados_line=$first_trados_line"
    ns_log Notice "first_trados_fields=$first_trados_fields"
    ns_log Notice "first_filename=$first_filename"
    ns_log Notice "first_filename_comps=$first_filename_comps"

    set all_the_same 1
    set ctr 0

    while {$all_the_same} {
	set common_component [lindex $first_filename_comps $ctr]
	ns_log Notice "common_component=$common_component"
	if {"" == $common_component} {
	    # We have reached the end of the reference filename.
	    # This is probably because our file list only contains
	    # a single file.

	    break
	}

	for {set i 2} {$i < $trados_files_len} {incr i} {
	    set trados_line [lindex $trados_files $i]
	    set trados_fields [split $trados_line ";"]
	    set filename [lindex $trados_fields 0]
	    set filename_comps [split $filename "\\"]
	    set this_component [lindex $filename_comps $ctr]
	    ns_log Notice "this_component=$this_component"

	    if {![string equal $common_component $this_component]} {
		set all_the_same 0
		break
	    }

	}
	incr ctr
    }
    set common_filename_comps [expr $ctr - 1]
}

ns_log Notice "common_filename_comps=$common_filename_comps"

db_transaction {

    set ctr 0
    for {set i 2} {$i < $trados_files_len} {incr i} {
	incr ctr
	set trados_line [lindex $trados_files $i]
	set trados_fields [split $trados_line ";"]
	
	set filename    	[lindex $trados_fields 0]
	set tagging_errors	[lindex $trados_fields 1]
	set chars_per_word	[lindex $trados_fields 2]

	if {[string equal $trados_version "3"]} {
	    set rep_segments	[lindex $trados_fields 3]
	    set rep_words	[lindex $trados_fields 4]
	    set rep_placeables	[lindex $trados_fields 5]
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
	if {[string equal $trados_version "5.5"] || [string equal $trados_version "5.0"]} {
	    set rep_segments	[lindex $trados_fields 7]
	    set rep_words	[lindex $trados_fields 8]
	    set rep_placeables	[lindex $trados_fields 9]

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
		ad_return_complaint 1 "<LI>Internal error: Unknown Input
		method '$inport_method'.
		return
	    }
	}

	# SLS Formula to count repeated words:
	# The valuation factor depends on the type of repetition.
	#
	set nomatch_words [expr $p75_words+$p50_words+$p0_words]
	set task_units [expr ($p100_words*0.25)+($p95_words*0.3)+($p85_words*0.5)+$nomatch_words]

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

	    set insert_sql "<tr><td colspan=10>INSERT INTO im_trans_tasks VALUES
(im_trans_tasks_seq.nextval, $task_name, $project_id, $task_type_id, 
$task_status_id, $task_description, $source_language_id, $target_language_id, 
$task_units, $billable_units, $task_uom_id)</td></tr>\n"

	    set sql "
INSERT INTO im_trans_tasks (
	task_id, task_name, project_id, task_type_id, 
	task_status_id, description, source_language_id, target_language_id, 
	task_units, billable_units, task_uom_id,
	match100, match95, match85, match0
) VALUES (
	im_trans_tasks_seq.nextval, :task_name, :project_id, :task_type_id, 
	:task_status_id, :task_description, :source_language_id, :target_language_id, 
	:task_units, :billable_units, :task_uom_id, 
	:p100_words, :p95_words, :p85_words, :nomatch_words
)"

            if { [catch {
	        db_dml insert_tasks $sql
	    } err_msg] } {
		incr err_count
	        append page_body "
<tr><td colspan=10>$insert_sql</td></tr>
<tr><td colspan=10><font color=red>$err_msg</font></td></tr>
"
	    }

	}
    }
}

append page_body "</table>\n"
append page_body "\n<P><A HREF=$return_url>Return to previous page</A></P>\n"

if {0 == $err_count} {
    # No errors - return to the $return_url
    ad_returnredirect $return_url
    return
}

db_release_unused_handles
doc_return  200 text/html [im_return_template]
