# /packages/intranet-translation/www/matrix/new.tcl

ad_page_contract {
    Purpose: form to add a new matrix or edit an existing one

    @author frank.bergmann@matrix-open.com
} {
    object_id:integer
    return_url:optional
}

set user_id [ad_maybe_redirect_for_registration]

# expect commands such as: "im_project_permissions" ...
#
set object_type [db_string acs_object_type "select object_type from acs_objects where object_id=:object_id"]
set perm_cmd "${object_type}_permissions \$user_id \$object_id view read write admin"
eval $perm_cmd

if {!$read} {
    ad_return_complaint 1 "[_ intranet-translation.lt_You_have_no_rights_to_1]"
    return
}

set export_vars [export_form_vars object_id return_url]

# Get match100, match95, ...
db_1row matrix_select "
select
	m.*,
	acs_object.name(o.object_id) as object_name
from
	acs_objects o,
	im_trans_trados_matrix m
where
	o.object_id = :object_id
	and o.object_id = m.object_id(+)
"

# Get the default trados matrix
array set default [im_trans_trados_matrix_internal]

if {"" == $match0} { set match0 $default(0) }
if {"" == $match50} { set match50 $default(50) }
if {"" == $match75} { set match75 $default(75) }
if {"" == $match85} { set match85 $default(85) }
if {"" == $match95} { set match95 $default(95) }
if {"" == $match100} { set match100 $default(100) }
if {"" == $match_rep} { set match_rep $default(rep) }
if {"" == $match_x} { set match_x $default(x) }


set page_title "[_ intranet-translation.lt_Edit_Trados_Matrix_of]"
if {"" != $match100} { set page_title "[_ intranet-translation.lt_New_Trados_Matrix_of_]" }
set context_bar [im_context_bar $page_title]
set focus {}

