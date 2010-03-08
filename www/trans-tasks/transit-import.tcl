# /packages/intranet-translation/www/trans-tasks/transit-import.tcl
#
# Copyright (c) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Purpose: Import the contents of a wordcount.rep file
    into the current projects as a list of "im_task"s

    This screen lets the user choose between importing all Transit tasks
    as one "batch" or to load the files one-by-one.

    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    return_url
    project_id:integer
    task_type_id:integer
    wordcount_file
    { upload_file "transit.rep" }
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

# Compatibility with old message...
set transit_wordcount_file $wordcount_file
im_security_alert_check_tmpnam -location "transit-import.tcl" -value $wordcount_file

# Check for accents and other non-ascii characters
set charset [ad_parameter -package_id [im_package_filestorage_id] FilenameCharactersSupported "" "alphanum"]

set org_task_type_id $task_type_id

set transit_batch_default_p 1

# Extract the file body
set upload_file_pieces [split $upload_file "."]
set upload_file_body [join [lrange $upload_file_pieces 0 end-1] "."]

# ---------------------------------------------------------------------
# Get the file and deal with Unicode encoding...
# ---------------------------------------------------------------------

ns_log Notice "transit-import: wordcount_file=$wordcount_file"

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
ns_log Notice "transit-import: encoding_hex=$encoding_hex"

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

set page_title [lang::message::lookup "" intranet-translation.Transit_Upload_Wizard "Transit Upload Wizard"]
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
	LEFT JOIN im_companies c USING (company_id)
where
        p.project_id = :project_id
"

if { ![db_0or1row projects_info_query $project_query] } {
    ad_return_complaint 1 "[_ intranet-translation.lt_Cant_find_the_project]"
    return
}


# ---------------------------------------------------------------------
# Start parsing the wordcount file
# A typical file looks like this:
#
# File	Pretranslated	Partially pretranslated	Fuzzy 100 - 95%	Fuzzy 94 - 85%	Fuzzy 84 - 75%	Fuzzy 74 - 50%	\
# Remaining not translated units	Total:
# Konditionen_Integrator	9	1	0	0	0	3	497	510
# Konditionen_Reseller	12	1	0	1	0	3	431	448
# SW_Pflegevertrag	5	0	0	0	0	70	606	681
# Vertrag Integrator	126	6	46	22	31	54	2397	2682
# Vertrag Reseller	125	7	46	22	31	54	2276	2561
# Totals not reduced by repetitions	277	15	92	45	62	184	6207	6882
# Repetitions found (reduced by limit)	0	0	46	22	31	58	1868	2025
# Totals reduced by repetitions	277	15	46	23	31	126	4339	4857
# Totals with weighting factor	277	15	46	23	31	126	4339	4857
# Totals with expansion factor	277	0	0	0	0	0	0	277
#
# ---------------------------------------------------------------------

if {[catch {
    set fl [open $wordcount_file]
    fconfigure $fl -encoding $encoding 
    set transit_files_content [read $fl]
    close $fl
} err]} {
    ad_return_complaint 1 "Unable to open file $wordcount_file:<br><pre>\n$err</pre>"
    return
}

set transit_files [split $transit_files_content "\n"]
set transit_files_len [llength $transit_files]
set transit_header [lindex $transit_files 0]

set separator "	"

set transit_headers [split $transit_header $separator]

if {1 == [llength $transit_headers]} {
    # Probably got the wrong separator
    set separator ","
    set transit_headers [split $transit_header $separator]
}

set transit_version "all"


set task_html "
	<table cellpadding=0 cellspacing=2 border=0>
	<tr>
          <td class=rowtitle>&nbsp;</td>
	  <td class=rowtitle align=center>[_ intranet-translation.Filename]</td>
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

# Determine the common filename components in the list of 
# transit files. These components are chopped off later in
# the loop.
# This procedure is not necessary for LocalFs import.
set common_filename_comps 0

ns_log Notice "transit-import: import_method=$import_method"
if {[string equal $import_method "Asp"]} {
    set first_transit_line [lindex $transit_files 2]
    set first_transit_fields [split $first_transit_line $separator]
    set first_filename [lindex $first_transit_fields 0]
    set first_filename_comps [split $first_filename "\\"]

    ns_log Notice "transit-import: first_transit_line=$first_transit_line"
    ns_log Notice "transit-import: first_transit_fields=$first_transit_fields"
    ns_log Notice "transit-import: first_filename=$first_filename"
    ns_log Notice "transit-import: first_filename_comps=$first_filename_comps"

    set all_the_same 1
    set ctr 0
    set fist_filename_comps_len [llength $first_filename_comps]

    while {$all_the_same && $ctr < $fist_filename_comps_len} {
	set common_component [lindex $first_filename_comps $ctr]
#	ns_log Notice "transit-import: first_filename_comps: prefix=$common_component"

	for {set i 2} {$i < $transit_files_len} {incr i} {
	    set transit_line [lindex $transit_files $i]
	    if {0 == [string length $transit_line]} { continue }

	    set transit_fields [split $transit_line $separator]
	    set filename [lindex $transit_fields 0]
	    set filename_comps [split $filename "\\"]
	    set this_component [lindex $filename_comps $ctr]
	    ns_log Notice "transit-import: this_component=$this_component"
	    ns_log Notice "transit-import: common_component=$common_component"

	    if {![string equal $common_component $this_component]} {
		set all_the_same 0
		break
	    }

	}
	incr ctr
    }
    set common_filename_comps [expr $ctr - 1]
}

ns_log Notice "transit-import: common_filename_comps=$common_filename_comps"

set sum_px_words 0
set sum_prep_words 0
set sum_p100_words 0
set sum_p95_words 0
set sum_p85_words 0
set sum_p75_words 0
set sum_p50_words 0
set sum_p0_words 0

set ctr 0
for {set i 1} {$i < $transit_files_len} {incr i} {
    incr ctr
    set transit_line [lindex $transit_files $i]

    # Remove empty lines    
    if {0 == [string length $transit_line]} { continue }

    set checked_p "checked"

    if {[regexp {^Totals not reduced by repetitions} $transit_line]} { set checked_p "" }
    if {[regexp {^Totals reduced by repetitions} $transit_line]} { set checked_p "" }
    if {[regexp {^Totals with weighting factor} $transit_line]} { set checked_p "" }
    if {[regexp {^Totals with expansion factor} $transit_line]} { set checked_p "" }

    if {[regexp {^Totales reducidos por repeticiones} $transit_line]} { set checked_p "" }
    if {[regexp {^Totales sin reducc} $transit_line]} { set checked_p "" }
    if {[regexp {^Totales con factor de pondera} $transit_line]} { set checked_p "" }
    if {[regexp {^Totales con factor de expan} $transit_line]} { set checked_p "" }

    set transit_fields [split $transit_line $separator]

#	0	File	
#	1	Pretranslated	
#	2	Partially pretranslated	
#	3	Fuzzy 100 - 95%	
#	4	Fuzzy 94 - 85%	
#	5	Fuzzy 84 - 75%	
#	6	Fuzzy 74 - 50%
#	7	Remaining not translated units
#	8	Total:

    set filename                [lindex $transit_fields 0]
    set px_words                [lindex $transit_fields 1]
#   set prep_words              0
    set p100_words              [lindex $transit_fields 2]
    set p95_words               [lindex $transit_fields 3]
    set p85_words               [lindex $transit_fields 4]
    set p75_words               [lindex $transit_fields 5]
    set p50_words               [lindex $transit_fields 6]
    set p0_words                [lindex $transit_fields 7]
    set prep_words              [lindex $transit_fields 8]
    set task_type_id            $org_task_type_id

    # Special treatment of repetitions - count them as negative in a separate task
    set rep_found_p [expr \
			 [regexp {^Repetitions found} $transit_line] + \
			 [regexp {^Repeticiones encontradas} $transit_line] \
     ]

    if {$rep_found_p} {
	set repetitions         $prep_words
	set px_words		[expr -$px_words]
	set prep_words		[expr -$prep_words]
	set p100_words		[expr -$p100_words]
	set p95_words		[expr -$p95_words]
	set p85_words		[expr -$p85_words]
	set p75_words		[expr -$p75_words]
	set p50_words		[expr -$p50_words]
	set p0_words		[expr -$p0_words]
	set task_type_id [im_project_type_translation]
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
	ns_log Notice "transit-import: found an empty line - maybe the last one..."
	continue
    }
    
    # Calculate the number of "effective" words based on
    # a valuation of repetitions
    
    
    # Determine the wordcount of the task:
    # Get the "task_units" from the company "default_freelance"
    # and the "billable_units" form the project's customer:
    #
    #ad_return_complaint 1 "im_trans_trados_matrix_calculate [im_company_freelance] $px_words $prep_words $p100_words $p95_words $p85_words $p75_words $p50_words $p0_words"
    
    
    set task_units [im_trans_trados_matrix_calculate [im_company_freelance] $px_words $prep_words $p100_words $p95_words $p85_words $p75_words $p50_words $p0_words]
    
    set billable_units [im_trans_trados_matrix_calculate $customer_id $px_words $prep_words $p100_words $p95_words $p85_words $p75_words $p50_words $p0_words]
    
   
    # 060605 fraber: Not necesary anymore: We now have a specific task type
    #	set task_type_id $project_type_id
    
    set task_status_id 340
    set task_description ""
    # source_language_id defined by im_project
    # 324=Source words
    set task_uom_id 324	
    set invoice_id ""
    

    append task_html "
	<tr $bgcolor([expr $ctr % 2])>
          <td>
                <input type=checkbox name=import_p.$ctr value=1 $checked_p>
          </td>
          <td>
                $filename
                <input type=hidden name=filename_list.$ctr value=\"$filename\">
                <input type=hidden name=task_type_list.$ctr value=\"$task_type_id\">
          </td>
	  <td>$px_words		<input type=hidden name=px_words_list.$ctr value=\"$px_words\">	</td>
	  <td>$prep_words	<input type=hidden name=prep_words_list.$ctr value=\"$prep_words\">	</td>
	  <td>$p100_words	<input type=hidden name=p100_words_list.$ctr value=\"$p100_words\">	</td>
	  <td>$p95_words	<input type=hidden name=p95_words_list.$ctr value=\"$p95_words\">	</td>
	  <td>$p85_words	<input type=hidden name=p85_words_list.$ctr value=\"$p85_words\">	</td>
	  <td>$p75_words	<input type=hidden name=p75_words_list.$ctr value=\"$p75_words\">	</td>
	  <td>$p50_words	<input type=hidden name=p50_words_list.$ctr value=\"$p50_words\">	</td>
	  <td>$p0_words		<input type=hidden name=p0_words_list.$ctr value=\"$p0_words\">	</td>
	  <td>$task_units	</td>
	</tr>
    "

    if {"" != $checked_p} {
	set sum_px_words [expr $sum_px_words + $px_words]
	set sum_prep_words [expr $sum_prep_words + $prep_words]
	set sum_p100_words [expr $sum_p100_words + $p100_words]
	set sum_p95_words [expr $sum_p95_words + $p95_words]
	set sum_p85_words [expr $sum_p85_words + $p85_words]
	set sum_p75_words [expr $sum_p75_words + $p75_words]
	set sum_p50_words [expr $sum_p50_words + $p50_words]
	set sum_p0_words [expr $sum_p0_words + $p0_words]
   }
}


append task_html "</table>\n"

