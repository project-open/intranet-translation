# /packages/intranet-translatin/www/matrix/new-2
#
# Copyright (C) 1998-2004 various parties
# The software is based on ArsDigita ACS 3.4
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

ad_page_contract {
    Purpose: verifies and stores project information to db.

    @author mbryzek@arsdigita.com
    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    return_url:optional
    object_id:integer
    match_x:float
    match_rep:float
    match100:float
    match95:float
    match85:float
    match75:float
    match50:float
    match0:float
}

# -----------------------------------------------------------------
# Defaults & Security
# -----------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]


# expect commands such as: "im_project_permissions" ...
#
set object_type [db_string acs_object_type "select object_type from acs_objects where object_id=:object_id"]
set perm_cmd "${object_type}_permissions \$user_id \$object_id view read write admin"
eval $perm_cmd

if {!$write} {
    ad_return_complaint 1 "[_ intranet-translation.lt_You_have_no_rights_to]
    return
}

# -----------------------------------------------------------------
# Update the object
# -----------------------------------------------------------------

set count [db_string matrix_count "select count(*) from im_trans_trados_matrix where object_id=:object_id"]

if {!$count} {
    db_dml insert_matrix "
insert into im_trans_trados_matrix 
(object_id, match_x, match_rep, match100, match95, match85, match75, match50, match0) values
(:object_id, :match_x, :match_rep, :match100, :match95, :match85, :match75, :match50, :match0)"
}

db_dml update_matrix "
update im_trans_trados_matrix set
	match_x = :match_x,
	match_rep = :match_rep,
	match100 = :match100,
	match95 = :match95,
	match85 = :match85,
	match75 = :match75,
	match50 = :match50,
	match0 = :match0
where
	object_id = :object_id
"

ad_returnredirect $return_url
