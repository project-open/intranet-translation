# /www/intranet/index.tcl

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    List all projects with dimensional sliders.

    @param order_by project display order 
    @param include_subprojects_p whether to include sub projects
    @param mine_p show my projects or all projects
    @param status_id criteria for project status
    @param type_id criteria for project_type_id
    @param letter criteria for im_first_letter_default_to_a(project_name)
    @param start_idx the starting index for query
    @param how_many how many rows to return

    @author mbryzek@arsdigita.com
    @cvs-id index.tcl,v 3.24.2.9 2000/09/22 01:38:44 kevin Exp
} {
    { order_by "Project #" }
    { include_subprojects_p "f" }
    { mine_p "f" }
    { status_id "" } 
    { type_id:integer "0" } 
    { user_id_from_search "0"}
    { customer_id:integer "0" } 
    { letter:trim "all" }
    { start_idx:integer "1" }
    { how_many "" }
    { view_name "project_list" }
}

# ---------------------------------------------------------------
# Project List Page
#
# This is a "classical" List-Page. It consists of the sections:
#    1. Page Contract: 
#	Receive the filter values defined as parameters to this page.
#    2. Defaults & Security:
#	Initialize variables, set default values for filters 
#	(categories) and limit filter values for unprivileged users
#    3. Define Table Columns:
#	Define the table columns that the user can see.
#	Again, restrictions may apply for unprivileged users,
#	for example hiding customer names to freelancers.
#    4. Define Filter Categories:
#	Extract from the database the filter categories that
#	are available for a specific user.
#	For example "potential", "invoiced" and "partially paid" 
#	projects are not available for unprivileged users.
#    5. Generate SQL Query
#	Compose the SQL query based on filter criteria.
#	All possible columns are selected from the DB, leaving
#	the selection of the visible columns to the table columns,
#	defined in section 3.
#    6. Format Filter
#    7. Format the List Table Header
#    8. Format Result Data
#    9. Format Table Continuation
#   10. Join Everything Together

# ---------------------------------------------------------------
# 2. Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters
set user_id [ad_get_user_id]
set current_user_id $user_id
set today [lindex [split [ns_localsqltimestamp] " "] 0]
set view_types [list "t" "Mine" "f" "All"]
set subproject_types [list "t" "Yes" "f" "No"]
set page_title "Projects"
set context_bar [ad_context_bar $page_title]
set page_focus "im_header_form.keywords"
set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]

set letter [string toupper $letter]

# Determine the default status if not set
if { [empty_string_p $status_id] } {
    # Default status is open
    set status_id [ad_parameter ProjectStatusOpen intranet 0]
}

# Unprivileged users (clients & freelancers) can only see their 
# own projects and no subprojects.
if {![im_permission $current_user_id "view_projects_of_others"]} {
    set mine_p "t"
    set include_subprojects_p "f"
    
    # Restrict status to "Open" projects only
    set status_id [ad_parameter ProjectStatusOpen intranet 0]
}

if { [empty_string_p $how_many] || $how_many < 1 } {
    set how_many [ad_parameter NumberResultsPerPage intranet 50]
}
set end_idx [expr $start_idx + $how_many - 1]


# ---------------------------------------------------------------
# 3. Defined Table Fields
# ---------------------------------------------------------------

# Define the column headers and column contents that 
# we want to show:
#
set view_id [db_string get_view_id "select view_id from im_views where view_name=:view_name"]
set column_headers [list]
set column_vars [list]

set column_sql "
select
	column_name,
	column_render_tcl,
	visible_for
from
	im_view_columns
where
	view_id=:view_id
	and group_id is null
order by
	sort_order"

db_foreach column_list_sql $column_sql {
    if {[eval $visible_for]} {
	lappend column_headers "$column_name"
	lappend column_vars "$column_render_tcl"
    }
}



# ---------------------------------------------------------------
# 4. Define Filter Categories
# ---------------------------------------------------------------

# status_types will be a list of pairs of (project_status_id, project_status)
set status_types [im_memoize_list select_project_status_types \
	"select project_status_id, project_status
         from im_project_status
         order by lower(project_status)"]
set status_types [linsert $status_types 0 0 All]

# project_types will be a list of pairs of (project_type_id, project_type)
set project_types [im_memoize_list select_project_types \
	"select project_type_id, project_type
         from im_project_types
        order by lower(project_type)"]
set project_types [linsert $project_types 0 0 All]


# ---------------------------------------------------------------
# 5. Generate SQL Query
# ---------------------------------------------------------------

set criteria [list]
if { ![empty_string_p $status_id] && $status_id > 0 } {
    lappend criteria "p.project_status_id=:status_id"
}
if { ![empty_string_p $type_id] && $type_id != 0 } {
    lappend criteria "p.project_type_id=:type_id"
}
if { 0 != $user_id_from_search} {
    lappend criteria "p.group_id in (select group_id from user_group_map where user_id = :user_id_from_search)"
}
if { ![empty_string_p $customer_id] && $customer_id != 0 } {
    lappend criteria "p.customer_id=:customer_id"
}
if { [string compare $mine_p "t"] == 0 } {
    lappend criteria "ad_group_member_p ( :user_id, p.group_id ) = 't'"
}
if { ![empty_string_p $letter] && [string compare $letter "ALL"] != 0 && [string compare $letter "SCROLL"] != 0 } {
    lappend criteria "im_first_letter_default_to_a(p.project_name)=:letter"
}
if { $include_subprojects_p == "f" } {
    lappend criteria "p.parent_id is null"
}


set order_by_clause "order by upper(group_name)"
switch $order_by {
    "Spend Days" { set order_by_clause "order by spend_days" }
    "Estim. Days" { set order_by_clause "order by estim_days" }
    "Start Date" { set order_by_clause "order by start_date" }
    "Delivery Date" { set order_by_clause "order by end_date" }
    "Create" { set order_by_clause "order by create_date" }
    "Quote" { set order_by_clause "order by quote_date" }
    "Open" { set order_by_clause "order by open_date" }
    "Deliver" { set order_by_clause "order by deliver_date" }
    "Close" { set order_by_clause "order by close_date" }
    "Type" { set order_by_clause "order by project_type" }
    "Status" { set order_by_clause "order by project_status_id" }
    "Delivery Date" { set order_by_clause "order by end_date" }
    "Client" { set order_by_clause "order by customer_name" }
    "Words" { set order_by_clause "order by task_words" }
    "Project #" { set order_by_clause "order by project_nr desc" }
    "Project Manager" { set order_by_clause "order by upper(lead_name)" }
    "URL" { set order_by_clause "order by upper(url)" }
    "Project Name" { set order_by_clause "order by upper(group_name)" }
}

set where_clause [join $criteria " and\n            "]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}


set additional_select "

        w.task_words,
        h.task_hours,
	ph.spend_hours,
	ph.spend_hours / 8 as spend_days,
	ed.est_days,

	s_create.when as create_date,
	s_open.when as open_date,
	s_quote.when as quote_date,
	s_deliver.when as deliver_date,
	s_invoice.when as invoice_date,
	s_close.when as close_date

"


set sql "
select
	p.*,
        c.customer_name,
        p.project_status_id,
	im_name_from_user_id(project_lead_id) as lead_name,
        im_category_from_id(p.project_type_id) as project_type, 
        im_category_from_id(p.project_status_id) as project_status,
        im_proj_url_from_type(p.project_id, 'website') as url,
	to_char(end_date, 'HH24:MI') as end_date_time
from 
	im_projects p, 
        im_customers c
where 
        p.customer_id=c.customer_id(+)
        $where_clause
	$order_by_clause
"




set additional_where "
        and p.group_id=w.project_id(+)
        and p.group_id=h.project_id(+)
        and p.group_id=ph.project_id(+)
	and p.group_id=ed.group_id(+)

--
	and p.group_id=s_create.group_id(+)
	and p.group_id=s_quote.group_id(+)
	and p.group_id=s_open.group_id(+)
	and p.group_id=s_deliver.group_id(+)
	and p.group_id=s_invoice.group_id(+)
	and p.group_id=s_close.group_id(+)
--

"


set additional_tables "
--
-- task words and hours
--
        (select project_id, sum(task_units) as task_words from im_tasks
	 where task_uom_id in (324, 325) group by project_id) w,
        (select project_id, sum(task_units) as task_hours from im_tasks
	 where task_uom_id in (320) group by project_id) h,
--
-- time spend on the project
--
	(select on_what_id as project_id, sum(hours) as spend_hours from im_hours 
	 where on_which_table='im_projects' group by on_what_id) ph,
--
-- project estimations
--
	(select map.group_id as group_id, sum(to_number(f.field_value)) as est_days
	 from users_active u, user_group_member_field_map f, user_group_map map
	 where map.user_id=u.user_id and u.user_id = f.user_id
	 and f.group_id=map.group_id and f.field_name='estimation_days'
	 group by map.group_id) ed,
--
-- Status change dates
--
	(select project_id, min(audit_date) as when from im_projects_status_audit
	group by project_id) s_create,
	(select min(audit_date) as when, project_id from im_projects_status_audit
	where project_status_id=74 group by project_id) s_quote,
	(select min(audit_date) as when, project_id from im_projects_status_audit
	where project_status_id=76 group by project_id) s_open,
	(select min(audit_date) as when, project_id from im_projects_status_audit
	where project_status_id=78 group by project_id) s_deliver,
	(select min(audit_date) as when, project_id from im_projects_status_audit
	where project_status_id=79 group by project_id) s_invoice,
	(select min(audit_date) as when, project_id from im_projects_status_audit
	where project_status_id in (77,81,82) group by project_id) s_close
"







#select 
#	on_what_id as project_id, 
#	sum(hours) as spend_hours
#from im_hours 
#	where on_which_table='im_projects'
#group by on_what_id


# ---------------------------------------------------------------
# 5a. Limit the SQL query to MAX rows and provide << and >>
# ---------------------------------------------------------------

# Limit the search results to N data sets only
# to be able to manage large sites
#

# !!!

if {1 || [string compare $letter "ALL"]} {
    # Set these limits to negative values to deactivate them
    set total_in_limited -1
    set how_many -1
    set selection "$sql"
} else {
    set limited_query [im_select_row_range $sql $start_idx $end_idx]

    # We can't get around counting in advance if we want to be able to 
    # sort inside the table on the page for only those users in the 
    # query results
    set total_in_limited [db_string projects_total_in_limited "
	select count(*) 
        from im_projects p 
        where 1=1 $where_clause"]

    set selection "select z.* from ($limited_query) z $order_by_clause"
}	

# ---------------------------------------------------------------
# 6. Format the Filter
# ---------------------------------------------------------------

# Note that we use a nested table because im_slider might
# return a table with a form in it (if there are too many
# options
set filter_html "
<form method=get action='/intranet/projects/index'>
[export_form_vars start_idx order_by how_many view_name include_subprojects_p letter]
<table border=0 cellpadding=0 cellspacing=0>
<tr> 
  <td colspan='2' class=rowtitle align=center>
Filter Projects [im_new_project_html $user_id]
  </td>
</tr>\n"

if {[im_permission $current_user_id "view_projects_of_others"]} { 
    append filter_html "
<tr>
  <td valign=top>View:</td>
  <td valign=top>[im_select mine_p $view_types ""]</td>
</tr>"
}

if {[im_permission $current_user_id "view_projects_of_others"]} {
    append filter_html "
<tr>
  <td valign=top>Project Status:</td>
  <td valign=top>[im_select status_id $status_types ""]</td>
</tr>"
}

append filter_html "
<tr>
  <td valign=top>Project Type:</td>
  <td valign=top>
    [im_select type_id $project_types ""]
	  <input type=submit value=Go name=submit>
  </td>
</tr>\n"

if {[im_permission $current_user_id "view_projects_of_others"]} { 
#    append filter_html "<a href=../allocations/index>Allocations</a> "
}
if {[im_permission $current_user_id "view_finance"]} { 
#    append filter_html "<a href=money>Financial View</a>"
}

append filter_html "
</table>
</form>
"

# ---------------------------------------------------------------
# 7. Format the List Table Header
# ---------------------------------------------------------------

# Set up colspan to be the number of headers + 1 for the # column
set colspan [expr [llength $column_headers] + 1]

set table_header_html ""
#<tr>
#  <td align=center valign=top colspan=$colspan><font size=-1>
#    [im_groups_alpha_bar [im_project_group_id] $letter "start_idx"]</font>
#  </td>
#</tr>"

# Format the header names with links that modify the
# sort order of the SQL query.
#
set url "index?"
set query_string [export_ns_set_vars url [list order_by]]
if { ![empty_string_p $query_string] } {
    append url "$query_string&"
}

append table_header_html "<tr>\n"
foreach col $column_headers {
    if { [string compare $order_by $col] == 0 } {
	append table_header_html "  <td class=rowtitle>$col</td>\n"
    } else {
	append table_header_html "  <td class=rowtitle><a href=\"${url}order_by=[ns_urlencode $col]\">$col</a></td>\n"
    }
}
append table_header_html "</tr>\n"


# ---------------------------------------------------------------
# 8. Format the Result Data
# ---------------------------------------------------------------

set table_body_html ""
set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "
set ctr 0
set idx $start_idx
db_foreach projects_info_query $selection {
    set url [im_maybe_prepend_http $url]
    if { [empty_string_p $url] } {
	set url_string "&nbsp;"
    } else {
	set url_string "<a href=\"$url\">$url</a>"
    }

    # Append together a line of data based on the "column_vars" parameter list
    append table_body_html "<tr$bgcolor([expr $ctr % 2])>\n"
    foreach column_var $column_vars {
	append table_body_html "\t<td valign=top>"
	set cmd "append table_body_html $column_var"
	eval $cmd
	append table_body_html "</td>\n"
    }
    append table_body_html "</tr>\n"

    incr ctr
    if { $how_many > 0 && $ctr >= $how_many } {
	break
    }
    incr idx
}

# Show a reasonable message when there are no result rows:
if { [empty_string_p $table_body_html] } {
    set table_body_html "
        <tr><td colspan=$colspan><ul><li><b> 
        There are currently no projects matching the selected criteria
        </b></ul></td></tr>"
}

if { $ctr == $how_many && $end_idx < $total_in_limited } {
    # This means that there are rows that we decided not to return
    # Include a link to go to the next page
    set next_start_idx [expr $end_idx + 1]
    set next_page_url "index?start_idx=$next_start_idx&[export_ns_set_vars url [list start_idx]]"
} else {
    set next_page_url ""
}

if { $start_idx > 1 } {
    # This means we didn't start with the first row - there is
    # at least 1 previous row. add a previous page link
    set previous_start_idx [expr $start_idx - $how_many]
    if { $previous_start_idx < 1 } {
	set previous_start_idx 1
    }
    set previous_page_url "index?start_idx=$previous_start_idx&[export_ns_set_vars url [list start_idx]]"
} else {
    set previous_page_url ""
}

# ---------------------------------------------------------------
# 9. Format Table Continuation
# ---------------------------------------------------------------

# Check if there are rows that we decided not to return
# => include a link to go to the next page 
#
if {$ctr==$how_many && $total_in_limited > 0 && $end_idx < $total_in_limited} {
    set next_start_idx [expr $end_idx + 1]
    set next_page "<a href=index?start_idx=$next_start_idx&[export_ns_set_vars url [list start_idx]]>Next Page</a>"
} else {
    set next_page ""
}

# Check if this is the continuation of a table (we didn't start with the 
# first row - there is at least 1 previous row.
# => add a previous page link
#
if { $start_idx > 1 } {
    set previous_start_idx [expr $start_idx - $how_many]
    if { $previous_start_idx < 1 } {
	set previous_start_idx 1
    }
    set previous_page "<a href=index?start_idx=$previous_start_idx&[export_ns_set_vars url [list start_idx]]>Previous Page</a>"
} else {
    set previous_page ""
}

set table_continuation_html "
<tr>
  <td align=center colspan=$colspan>
    [im_maybe_insert_link $previous_page $next_page]
  </td>
</tr>"


# ---------------------------------------------------------------
# 10. Join all parts together
# ---------------------------------------------------------------

set page_body "
$filter_html
[im_project_navbar $letter "/intranet/projects/index" $next_page_url $previous_page_url [list status_id customer_id type_id start_idx order_by how_many mine_p view_name letter include_subprojects_p]]

<table width=100% cellpadding=2 cellspacing=2 border=0>
  $table_header_html
  $table_body_html
  $table_continuation_html
</table>"

if {[im_permission $current_user_id "add_projects"]} {
    append page_body "<p><a href=/intranet/projects/new>Add New Project</a>\n"
}

db_release_unused_handles

# doc_return  200 text/html [im_return_template]
