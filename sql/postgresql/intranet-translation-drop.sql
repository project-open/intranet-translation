-- /packages/intranet-translation/sql/postgresql/intranet-translation-drop.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com
-- @author juanjoruizx@yahoo.es



-- Remove added fields to im_projects

-- These fields are used everywhere now...
-- alter table im_projects drop     company_project_nr;
-- alter table im_projects drop     company_contact_id;
-- alter table im_projects drop     final_company;

alter table im_projects drop     source_language_id;
alter table im_projects drop     subject_area_id;
alter table im_projects drop     expected_quality_id;


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
drop table im_trans_task_progress;

-- ToDo: Add drop for im_trans_task object type



-- Translation Quality Views
delete from im_view_columns where view_id = 250;
delete from im_view_columns where view_id = 251;
delete from im_views where view_id = 250;
delete from im_views where view_id = 251;

-- Delete intranet views
delete from im_view_columns where view_id = 90;
delete from im_view_columns where view_id = 150;
delete from im_view_columns where view_id = 151;
delete from im_view_columns where view_id = 152;
delete from im_view_columns where view_id = 152;

delete from im_views where view_id = 90;
delete from im_views where view_id = 150;
delete from im_views where view_id = 151;
delete from im_views where view_id = 152;
delete from im_views where view_id = 152;


-- Categories

delete from im_trans_task_progress where task_type_id in (87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 2500, 2503);
delete from im_invoice_items where item_type_id in (87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 2500, 2503);
update im_projects set project_type_id = 86 where project_type_id in (87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 2500, 2503);
delete from  where  in (87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 2500, 2503);

delete from im_dynfield_type_attribute_map where object_type_id in (87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 2500, 2503);
delete from im_category_hierarchy where child_id in (87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 2500, 2503);
delete from im_categories where category_id in (87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 2500, 2503);



delete from im_categories where category_type = 'Intranet Trans RFQ Type';
delete from im_categories where category_type = 'Intranet Trans RFQ Status';
delete from im_categories where category_type = 'Intranet Trans RFQ Overall Status';
delete from im_categories where category_type = 'Intranet Translation Task Status';
delete from im_categories where category_type = 'Intranet Translation Subject Area';
delete from im_categories where category_type = 'Intranet Translation Quality Type';
delete from im_categories where category_type = 'Intranet Translation Language';
delete from im_categories where category_type = 'Intranet TM Integration Type';
delete from im_categories where category_type = 'Intranet Quality';
delete from im_categories where category_type = 'Intranet LOC Tool';



-- Delete SQL metadata and the object type itself
delete from acs_object_type_tables
where object_type = 'im_trans_task';

delete from im_rest_object_types
where object_type = 'im_trans_task';

SELECT acs_object_type__drop_type ('im_trans_task', 't');



------------------------------------------------------------------
-- Cleanup other translation stuff
-- 
-- intranet-translation should be the last translation package
-- to uninstall, so this is a reasonable place to clean up some
-- stuff left by other packages.


ALTER TABLE ONLY public.im_trans_rfqs DROP CONSTRAINT im_trans_rfq_uom_wf_key_fk;
ALTER TABLE ONLY public.im_trans_rfqs DROP CONSTRAINT im_trans_rfq_uom_units_fk;
ALTER TABLE ONLY public.im_trans_rfqs DROP CONSTRAINT im_trans_rfq_type_fk;
ALTER TABLE ONLY public.im_trans_rfqs DROP CONSTRAINT im_trans_rfq_status_fk;
ALTER TABLE ONLY public.im_trans_rfqs DROP CONSTRAINT im_trans_rfq_project_fk;
ALTER TABLE ONLY public.im_trans_rfqs DROP CONSTRAINT im_trans_rfq_id_fk;
ALTER TABLE ONLY public.im_trans_rfq_answers DROP CONSTRAINT im_trans_rfq_answer_user_fk;
ALTER TABLE ONLY public.im_trans_rfq_answers DROP CONSTRAINT im_trans_rfq_answer_type_fk;
ALTER TABLE ONLY public.im_trans_rfq_answers DROP CONSTRAINT im_trans_rfq_answer_status_fk;
ALTER TABLE ONLY public.im_trans_rfq_answers DROP CONSTRAINT im_trans_rfq_answer_rfq_fk;
ALTER TABLE ONLY public.im_trans_rfq_answers DROP CONSTRAINT im_trans_rfq_answer_project_fk;
ALTER TABLE ONLY public.im_trans_rfq_answers DROP CONSTRAINT im_trans_rfq_answer_price_currency_fk;
ALTER TABLE ONLY public.im_trans_rfq_answers DROP CONSTRAINT im_trans_rfq_answer_overall_fk;
ALTER TABLE ONLY public.im_trans_rfq_answers DROP CONSTRAINT im_trans_rfq_answer_id_fk;
DROP INDEX public.im_trans_rfq_answers_un;
ALTER TABLE ONLY public.im_trans_rfqs DROP CONSTRAINT im_trans_rfq_id_pk;
ALTER TABLE ONLY public.im_trans_rfq_answers DROP CONSTRAINT im_trans_rfq_answer_id_pk;
DROP TABLE public.im_trans_rfqs;
DROP VIEW public.im_trans_rfq_type;
DROP VIEW public.im_trans_rfq_status;
DROP VIEW public.im_trans_rfq_overall_status;
DROP TABLE public.im_trans_rfq_answers;



DROP FUNCTION public.im_transq_weighted_error_sum(integer, integer, integer, integer, integer);
DROP FUNCTION public.im_trans_tasks_calendar_update_tr();
DROP FUNCTION public.im_trans_task__project_clone(integer, integer);
DROP FUNCTION public.im_trans_task__new(integer, character varying, timestamp with time zone, 
integer, character varying, integer, integer, integer, integer, integer, integer, integer);
DROP FUNCTION public.im_trans_task__name(integer);
DROP FUNCTION public.im_trans_task__delete(integer);
DROP FUNCTION public.im_trans_rfq_answer__new(integer, character varying, timestamp with time zone, 
integer, character varying, integer, integer, integer, integer, integer, integer);
DROP FUNCTION public.im_trans_rfq_answer__name(integer);
DROP FUNCTION public.im_trans_rfq_answer__delete(integer);
DROP FUNCTION public.im_trans_rfq__new(integer, character varying, timestamp with time zone, 
integer, character varying, integer, character varying, integer, integer, integer);
DROP FUNCTION public.im_trans_rfq__new(integer, character varying, timestamp with time zone, 
integer, character varying, integer, character varying, integer, timestamp with time zone, 
character, integer, integer, integer, integer, numeric, numeric, numeric, character varying, 
character varying, character varying, character varying, integer, character, numeric, integer, integer, integer);
DROP FUNCTION public.im_trans_rfq__name(integer);
DROP FUNCTION public.im_trans_rfq__delete(integer);
DROP FUNCTION public.im_trans_project_target_languages(integer);



alter table im_materials drop column source_language_id;
alter table im_materials drop column target_language_id;
alter table im_materials drop column subject_area_id;
alter table im_materials drop column file_type_id;
alter table im_materials drop column trans_task_id;
alter table im_materials drop column task_type_id;
alter table im_materials drop column task_uom_id;


-- Delete invoice lines with translation UoM units
delete from im_invoice_items where item_uom_id in (323,324,325,326,327);


delete from im_freelance_skills
where skill_id in (select category_id from im_categories where category_type = 'Intranet Translation Language');
delete from im_freelance_skills
where skill_id in (select category_id from im_categories where category_type = 'Intranet TM Tool');
delete from im_freelance_skills
where skill_id in (select category_id from im_categories where category_type = 'Intranet Translation Subject Area');

delete from im_object_freelance_skill_map
where skill_id in (select category_id from im_categories where category_type = 'Intranet Translation Language');
delete from im_object_freelance_skill_map
where skill_id in (select category_id from im_categories where category_type = 'Intranet TM Tool');
delete from im_object_freelance_skill_map
where skill_id in (select category_id from im_categories where category_type = 'Intranet Translation Subject Area');



delete from im_categories where category_type = 'Intranet Translation Language';
delete from im_categories where category_type = 'Intranet Translation Subject Area';
delete from im_categories where category_type = 'Intranet TM Tool';

delete from im_categories where category_type = 'Intranet Freelance RFQ Answer Status';
delete from im_categories where category_type = 'Intranet Freelance RFQ Answer Type';
delete from im_categories where category_type = 'Intranet Freelance RFQ Status';
delete from im_categories where category_type = 'Intranet Freelance RFQ Type';


delete from im_materials where material_uom_id in (323,324,325,326,327);


delete from im_categories where category_type = 'Intranet UoM' and category = 'Page';
delete from im_categories where category_type = 'Intranet UoM' and category = 'S-Word';
delete from im_categories where category_type = 'Intranet UoM' and category = 'T-Word';
delete from im_categories where category_type = 'Intranet UoM' and category = 'S-Line';
delete from im_categories where category_type = 'Intranet UoM' and category = 'T-Line';
