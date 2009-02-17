-- /packages/intranet-translation/sql/oracle/intranet-translation-backup.sql
--
-- Copyright (C) 2004 - 2009 ]project-open[
--
-- This program is free software. You can redistribute it
-- and/or modify it under the terms of the GNU General
-- Public License as published by the Free Software Foundation;
-- either version 2 of the License, or (at your option)
-- any later version. This program is distributed in the
-- hope that it will be useful, but WITHOUT ANY WARRANTY;
-- without even the implied warranty of MERCHANTABILITY or
-- FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details.
--
-- @author	frank.bergmann@project-open.com


-- 100  im_projects
-- 101  im_project_roles
-- 102  im_customers
-- 103  im_customer_roles
-- 104  im_offices
-- 105  im_office_roles
-- 106  im_categories
-- 107	im_employees
--
-- 110  users
-- 111  im_profiles
--
-- 120  im_freelancers
-- 121  im_freelance_skills
--
-- 130  im_forum_topics
-- 131	im_forum_folders
-- 132	im_forum_topic_user_map
--
-- 140  im_filestorage
--
-- 150  im_translation
-- 151	im_target_languages
-- 152	im_project_trans_details
--
-- 160  im_quality
--
-- 170  im_marketplace
--
-- 180  im_hours
-- 181  im_absences
--
-- 190  im_costs
-- 191  im_payments
-- 192  im_invoices
-- 193  im_invoice_items
-- 194  im_project_invoice_map
-- 195  im_trans_prices
-- 196	im_cost_centers
-- 197	im_investments

---------------------------------------------------------
-- Backup Translation Project Details
--

delete from im_view_columns where view_id = 152;
delete from im_views where view_id = 152;
insert into im_views (
	view_id, view_name, view_type_id, sort_order, view_sql
) values (
	152, 'im_trans_project_details', 1410, 150, '
SELECT
	p.*,
	im_category_from_id(p.source_language_id) as source_language,
	im_category_from_id(subject_area_id) as subject_area,
	im_category_from_id(expected_quality_id) as expected_quality,
	im_email_from_user_id(p.customer_contact_id) as customer_contact_email
FROM
	im_projects p
');


delete from im_view_columns where column_id > 15200 and column_id < 15299;
--
insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (15201,152,NULL,'project_nr','$project_nr','','',1,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (15203,152,NULL,'customer_project_nr',
'[ns_urlencode $customer_project_nr]','','',3,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (15205,152,NULL,'customer_contact_email',
'$customer_contact_email','','',5,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (15207,152,NULL,'source_language','$source_language','','',7,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (15209,152,NULL,'subject_area','$subject_area','','',9,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (15211,152,NULL,'final_customer','[ns_urlencode $final_customer]',
'','',11,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (15213,152,NULL,'expected_quality','$expected_quality','','',13,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (15214,152,NULL,'trans_project_words','$trans_project_words','','',14,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (15217,152,NULL,'trans_project_hours','$trans_project_hours','','',17,'');


---------------------------------------------------------
-- Backup Translation Tasks
--

delete from im_view_columns where view_id = 150;
delete from im_views where view_id = 150;
insert into im_views (
	view_id, view_name, view_type_id, sort_order, view_sql
) values (
	150, 'im_trans_tasks', 1410, 160, '
SELECT
	t.*,
	p.project_name,
	im_category_from_id(t.source_language_id) as source_language,
	im_category_from_id(t.target_language_id) as target_language,
	im_category_from_id(t.task_type_id) as task_type,
	im_category_from_id(t.task_status_id) as task_status,
	im_category_from_id(t.task_uom_id) as task_uom,
	im_email_from_user_id(t.trans_id) as trans_email,
	im_email_from_user_id(t.edit_id) as edit_email,
	im_email_from_user_id(t.proof_id) as proof_email,
	im_email_from_user_id(t.other_id) as other_email
FROM
	im_trans_tasks t,
	im_projects p
WHERE
	t.project_id = p.project_id
');

delete from im_view_columns where column_id > 15000 and column_id < 15099;
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (15001,150,NULL,'project_name','$project_name','','',1,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (15003,150,NULL,'target_language','$target_language','','',3,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (15005,150,NULL,'task_name','$task_name','','',5,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (15007,150,NULL,'task_filename','$task_filename','','',7,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (15009,150,NULL,'task_type','$task_type','','',9,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (15011,150,NULL,'task_status','$task_status','','',11,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (15013,150,NULL,'description','$description','','',13,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (15015,150,NULL,'source_language','$source_language','','',15,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (15017,150,NULL,'task_units','$task_units','','',17,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (15019,150,NULL,'billable_units','$billable_units','','',19,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (15021,150,NULL,'task_uom','$task_uom','','',21,'');
--insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
--extra_select, extra_where, sort_order, visible_for) values (15023,150,NULL,'invoice_nr','$invoice_nr','','',23,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (15024,150,NULL,'match_x','$match_x','','',24,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (15025,150,NULL,'match100','$match100','','',25,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (15026,150,NULL,'match_rep','$match_rep','','',26,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (15027,150,NULL,'match95','$match95','','',27,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (15029,150,NULL,'match85','$match85','','',29,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (15030,150,NULL,'match75','$match75','','',30,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (15031,150,NULL,'match0','$match0','','',31,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (15033,150,NULL,'trans_email','$trans_email','','',33,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (15035,150,NULL,'edit_email','$edit_email','','',35,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (15037,150,NULL,'proof_email','$proof_email','','',37,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (15039,150,NULL,'other_email','$other_email','','',39,'');
--
-- commit;



---------------------------------------------------------
-- Backup Translation Languages
--

delete from im_view_columns where view_id = 151;
delete from im_views where view_id = 151;
insert into im_views (
	view_id, view_name, view_type_id, sort_order, view_sql
) values (151, 'im_target_languages', 1410, 170, '
SELECT
	t.*,
	p.project_name,
	im_category_from_id(t.language_id) as language
FROM
	im_target_languages t,
	im_projects p
WHERE
	t.project_id = p.project_id
');

delete from im_view_columns where column_id > 15100 and column_id < 15199;
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (15101,151,NULL,'project_name','$project_name','','',1,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (15103,151,NULL,'language','$language','','',3,'');
--
-- commit;



