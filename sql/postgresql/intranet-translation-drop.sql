-- /packages/intranet-translation/sql/postgresql/intranet-translation.sql
--
-- Copyright (c) 2003-2004 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com
-- @author juanjoruizx@yahoo.es


-- Remove added fields to im_projects
alter table im_projects drop     company_project_nr;
alter table im_projects drop     company_contact_id;
alter table im_projects drop     source_language_id;
alter table im_projects drop     subject_area_id;
alter table im_projects drop     expected_quality_id;
alter table im_projects drop     final_company;

-- An approximate value for the size (number of words) of the project
alter table im_projects drop     trans_project_words;
alter table im_projects drop     trans_project_hours;


-----------------------------------------------------------
-- Translation Remove

select im_menu__del_module('intranet-translation');
select im_component_plugin__del_module('intranet-translation');


drop view im_task_status;
drop table im_target_languages;
drop table im_task_actions;
drop sequence im_task_actions_seq;
drop table im_trans_tasks;
drop sequence im_trans_tasks_seq;


