-- /packages/intranet-translation/sql/postgresql/intranet-translation.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
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

create or replace function inline_01 ()
returns integer as '
DECLARE
    v_menu_id           integer;
BEGIN
	select menu_id  into v_menu_id
        from im_menus
        where label = ''project_trans_tasks'';
	PERFORM im_menu__delete(v_menu_id);

        select menu_id  into v_menu_id
        from im_menus
        where label = ''project_trans_tasks_assignments'';
	PERFORM im_menu__delete(v_menu_id);

    return 0;
end;' language 'plpgsql';

select inline_01 ();

drop function inline_01 ();


-- ----------------------------------------------------------------
-- Drop categories

-- Project Types
-- update im_projects 
-- set project_type_id=85 
-- where project_type_id in (2500,87,88,89,90,91,92,93,94,95,96);

-- update im_invoice_items 
-- set item_type_id=85 
-- where item_type_id in (2500,87,88,89,90,91,92,93,94,95,96);

-- delete from im_category_hierarchy 
-- where parent_id in (2500,87,88,89,90,91,92,93,94,95,96)
-- 	or child_id in (2500,87,88,89,90,91,92,93,94,95,96);

-- delete from im_categories 
-- where category_id in (2500,87,88,89,90,91,92,93,94,95,96);

-- delete from im_categories where category_id >= 110 and category_id <= 113;
-- delete from im_categories where category_id >= 250 and category_id <= 299;
-- delete from im_categories where category_id >= 323 and category_id <= 327;
-- delete from im_categories where category_id >= 340 and category_id <= 372;
-- delete from im_categories where category_id >= 500 and category_id <= 570;


-- before remove priviliges remove granted permissions
create or replace function inline_revoke_permission (varchar)
returns integer as '
DECLARE
        p_priv_name     alias for $1;
BEGIN
     lock table acs_permissions_lock;

     delete from acs_permissions
     where privilege = p_priv_name;

     return 0;

end;' language 'plpgsql';

select inline_revoke_permission ('view_trans_tasks');
select inline_revoke_permission ('view_trans_task_matrix');
select inline_revoke_permission ('view_trans_task_status');
select inline_revoke_permission ('view_trans_proj_detail');


--drop privileges
select acs_privilege__remove_child('admin','view_trans_tasks');
select acs_privilege__remove_child('admin','view_trans_task_matrix');
select acs_privilege__remove_child('admin','view_trans_task_status');
select acs_privilege__remove_child('admin','view_trans_proj_detail');
select acs_privilege__drop_privilege('view_trans_tasks');
select acs_privilege__drop_privilege('view_trans_task_matrix');
select acs_privilege__drop_privilege('view_trans_task_status');
select acs_privilege__drop_privilege('view_trans_proj_detail');

-- drop tables and views
drop view im_task_status;
drop table im_target_languages;
drop table im_task_actions;
drop sequence im_task_actions_seq;
drop table im_trans_tasks;
drop table im_trans_trados_matrix;

-- ToDo: Add drop for im_trans_task object type


-- Delete intranet views
delete from im_view_columns where column_id >= 9000 and column_id <= 9099;
delete from im_views where view_id = 90;
delete from im_view_columns where column_id = 2023;


-----------------------------------------------------------
-- Remove backup views 
--
delete from im_view_columns where view_id = 150;
delete from im_views where view_id = 150;

delete from im_view_columns where view_id = 151;
delete from im_views where view_id = 151;

delete from im_view_columns where view_id = 152;
delete from im_views where view_id = 152;

