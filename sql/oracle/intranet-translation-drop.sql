-- /packages/intranet-translation/sql/oracle/intranet-translation.sql
--
-- Copyright (c) 2003-2004 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com




-----------------------------------------------------------
-- Translation Remove


BEGIN
    im_menu.del_module(module_name => 'intranet-translation');
    im_component_plugin.del_module(module_name => 'intranet-translation');
END;
/
show errors


drop view im_task_status;
drop table im_target_languages;
drop table im_task_actions;
drop sequence im_task_actions_seq;
drop table im_trans_tasks;
drop sequence im_trans_tasks_seq;


