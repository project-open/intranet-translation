-- /packages/intranet-translation/sql/oracle/intranet-translation.sql
--
-- Copyright (c) 2003-2004 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com



-- Remove added fields to im_projects
alter table im_projects drop column company_project_nr;
alter table im_projects drop column company_contact_id;
alter table im_projects drop column source_language_id;
alter table im_projects drop column subject_area_id;
alter table im_projects drop column expected_quality_id;
alter table im_projects drop column final_company;

-- An approximate value for the size (number of words) of the project
alter table im_projects drop column trans_project_words;
alter table im_projects drop column trans_project_hours;


-----------------------------------------------------------
-- Translation Remove


BEGIN
    im_menu.del_module(module_name => 'intranet-translation');
    im_component_plugin.del_module(module_name => 'intranet-translation');
END;
/
show errors


-- drop categories
delete from im_category_hierarchy where parent_id = 2500;
delete from im_categories where category_id = 2500;
delete from im_categories where category_id >= 87 and category_id <= 96;
delete from im_categories where category_id >= 110 and category_id <= 113;
delete from im_categories where category_id >= 250 and category_id <= 299;
delete from im_categories where category_id >= 323 and category_id <= 327;
delete from im_categories where category_id >= 340 and category_id <= 372;
delete from im_categories where category_id >= 500 and category_id <= 570;


-- before remove priviliges remove granted permissions
delete from acs_permissions where privilege = 'view_trans_tasks';
delete from acs_permissions where privilege = 'view_trans_task_matrix';
delete from acs_permissions where privilege = 'view_trans_task_status';
delete from acs_permissions where privilege = 'view_trans_proj_detail';
commit;

--drop privileges
BEGIN
        acs_privilege.remove_child('admin','view_trans_tasks');
        acs_privilege.remove_child('admin','view_trans_task_matrix');
        acs_privilege.remove_child('admin','view_trans_task_status');
        acs_privilege.remove_child('admin','view_trans_proj_detail');
END;
/
commit;

BEGIN
	acs_privilege.drop_privilege('view_trans_tasks');
	acs_privilege.drop_privilege('view_trans_task_matrix');
	acs_privilege.drop_privilege('view_trans_task_status');
	acs_privilege.drop_privilege('view_trans_proj_detail');
END;
/
commit;

drop view im_task_status;
drop table im_target_languages;
drop table im_task_actions;
drop sequence im_task_actions_seq;
drop table im_trans_tasks;
drop sequence im_trans_tasks_seq;
drop table im_trans_trados_matrix;

-- Delete intranet views
delete from im_view_columns where column_id >= 9000 and column_id <= 9099;
delete from im_views where view_id = 90;
delete from im_view_columns where column_id = 2023;


