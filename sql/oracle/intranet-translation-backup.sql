-- /packages/intranet-translation/sql/oracle/intranet-translation-backup.sql
--
-- Copyright (C) 2004 Project/Open
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

-- 100	im_projects
-- 101	im_project_roles
-- 102	im_customers
-- 103	im_customer_roles
-- 104	im_offices
-- 105	im_office_roles
-- 106	im_categories
--
-- 110	users
-- 111	im_profiles
-- 115	im_employees
--
-- 120	im_freelancers
--
-- 130	im_forums
--
-- 140	im_filestorage
--
-- 150	im_translation
--
-- 160	im_quality
--
-- 170	im_marketplace
--
-- 180	im_hours
--
-- 190	im_invoices
--
-- 200

---------------------------------------------------------
-- Backup Translation Project Details
--

delete from im_view_columns where view_id = 152;
delete from im_views where view_id = 152;
insert into im_views (view_id, view_name, view_sql
) values (152, 'im_trans_project_details', '
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
--
commit;

