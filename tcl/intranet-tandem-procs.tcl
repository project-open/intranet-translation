# /packages/intranet-translation/tcl/intranet-tandem-procs.tcl
#
# Copyright (C) 2004-2009 ]project-open[
#
# All rights reserved (this is not GPLed software!).
# Please check http://www.project-open.com/ for licensing
# details.

ad_library {
    Specific stuff for tandem programming.
    Developed for a specific Danish customer.

    @author frank.bergmann@project-open.com
}


# ------------------------------------------------------
# Tandem component to allow selecting tandem partners
# ------------------------------------------------------

ad_proc im_trans_tandem_partner_component {
    -project_id:required
    -return_url:required
} {
    Returns a formatted HTML table to allow a user to a the "tandem partners"
    (habitual editor for...) of the current users.
} {
    if {![im_project_has_type $project_id "Translation Project"]} { return "" }

    im_project_permissions [ad_get_user_id] $project_id view read write admin
    if {!$write} { return "" }

    set params [list \
                    [list project_id $project_id] \
                    [list return_url $return_url] \
		    ]

    set result ""
    if {[catch {
        set result [ad_parse_template -params $params "/packages/intranet-translation/www/tandem/tandem-partners"]
    } err_msg]} {
        set result "Error in Tandem Partner Component:<p><pre>$err_msg</pre>"
    }

    return $result
}




# ------------------------------------------------------
# Tandem component to allow selecting tandem partners
# ------------------------------------------------------

ad_proc im_trans_task_action_list_component {
    -project_id:required
} {
    Returns a formatted HTML table showing the task up-/download  activities
} {
    if {![im_project_has_type $project_id "Translation Project"]} { return "" }
    set return_url [im_url_with_query]

    # Security...
    im_project_permissions [ad_get_user_id] $project_id view read write admin
    if {!$read} { return "" }

    set params [list \
                    [list project_id $project_id] \
                    [list return_url $return_url] \
		    ]

    set result ""
    if {[catch {
        set result [ad_parse_template -params $params "/packages/intranet-translation/www/trans-tasks/task-action-list"]
    } err_msg]} {
        set result "Error in Task Action List Component:<p><pre>$err_msg</pre>"
    }

    return $result
}

