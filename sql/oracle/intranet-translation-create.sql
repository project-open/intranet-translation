-- /packages/intranet-translation/sql/oracle/intranet-translation-create.sql
--
-- Copyright (c) 2003-2004 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

-----------------------------------------------------------
-- Translation Sector Specific Extensions
--
-- Projects in the translation sector are typically much
-- smaller and more frequent than in other sectors. They 
-- are organized around documents that pass through a rigid 
-- workflow.
-- Another speciality are the tight access permissions,
-- because translation agencies don't let translators know,
-- who is going to edit their documents and vice versa.
-- Freelancers and even employees should not get any
-- information about clients, because of the low barries
-- to entry in the sector.


-----------------------------------------------------------
-- Projects (Extensions)
--
-- Add some translation specific fields to a project.

alter table im_projects add	company_project_nr	varchar(50);
alter table im_projects add	company_contact_id	integer references users;
alter table im_projects add	source_language_id	references im_categories;
alter table im_projects add	subject_area_id		references im_categories;
alter table im_projects add	expected_quality_id	references im_categories;
alter table im_projects add	final_company		varchar(50);

-- An approximate value for the size (number of words) of the project
alter table im_projects add	trans_project_words	number(12,0);
alter table im_projects add	trans_project_hours	number(12,0);


-----------------------------------------------------------
-- Tasks
--
-- - Every project can have any number of "Tasks".
-- - Each task represents a work unit that can be billed
--   independently and that will appear as a line in
--   the final invoice to be printed.

create sequence im_trans_tasks_seq start with 1;
create table im_trans_tasks (
	task_id			integer 
				constraint im_trans_tasks_pk
				primary key,
	project_id		integer not null 
				constraint im_trans_tasks_project_fk
				references im_projects,
	target_language_id	integer
				constraint im_trans_tasks_target_lang_fk
				references im_categories,
				-- task_name take a filename for the
				-- language processing application
	task_name		varchar(1000),
				-- task_filename!=null indicates a file task
	task_filename		varchar(1000) default null,
	task_type_id		integer not null 
				constraint im_trans_tasks_type_fk
				references im_categories,
	task_status_id		integer not null 
				constraint im_trans_tasks_status_fk
				references im_categories,
	description		varchar(4000),
	source_language_id	integer not null
				constraint im_trans_tasks_source_fk
				references im_categories,
				-- fees: N units of "UoM" (Unit of Measurement)
				-- raw units to be delivered to the client
	task_units		number(12,1),
				-- sometimes, not all units can be billed...
	billable_units		number(12,1),
				-- UoM=Unit of Measure (hours, words, ...)
	task_uom_id		integer not null 
				constraint im_trans_tasks_uom_fk
				references im_categories,
				-- references to financial documents: helps to make
				-- sure a single task isn't invoiced twice or not
				-- being invoiced at all...
				-- invoice_id=null => needs to be invoiced still
				-- invoice_id!= null => has already been invoiced
	invoice_id		integer 
				constraint im_trans_tasks_invoice_fk
				references im_invoices,
				-- "Trados Matrix" determine duplicated words
	match_x			number(12,0),
	match_rep		number(12,0),
	match100		number(12,0),
	match95			number(12,0),
	match85			number(12,0),
	match75			number(12,0),
	match50			number(12,0),
	match0			number(12,0),
				-- Translation Workflow
	trans_id		integer 
				constraint im_trans_tasks_trans_fk
				references users,
	edit_id			integer 
				constraint im_trans_tasks_edit_fk
				references users,
	proof_id		integer 
				constraint im_trans_tasks_proof_fk
				references users,
	other_id		integer 
				constraint im_trans_tasks_other_fk
				references users
);
-- make sure a task doesn't get defined twice for a project:
create unique index im_trans_tasks_unique_idx on im_trans_tasks 
(task_name, project_id, target_language_id);

-- Speedup lookups by project
create index im_trans_tasks_project_id_idx on im_trans_tasks(project_id);


-- Trados Matrix by object (normally by company)
create table im_trans_trados_matrix (
	object_id		integer 
				constraint im_trans_matrix_cid_fk
				references acs_objects
				constraint im_trans_matrix_pk
				primary key,
        match_x			number(12,4),
        match_rep		number(12,4),
        match100                number(12,4),
        match95                 number(12,4),
        match85                 number(12,4),
	match75			number(12,4),
	match50			number(12,4),
        match0                  number(12,4)
);


-- actions that have occured around im_trans_tasks: upload, download, ...
create sequence im_task_actions_seq start with 1;
create table im_task_actions (
	action_id		integer primary key,
	action_type_id		references im_categories,
	user_id			not null references users,
	task_id			not null references im_trans_tasks,
	action_date		date,
	old_status_id		references im_categories,
	new_status_id		references im_categories
);


-- define into which language we have to translate a certain project.
create table im_target_languages (
	project_id		not null 
				constraint im_target_lang_proj_fk
				references im_projects,
	language_id		not null 
				constraint im_target_lang_lang_fk
				references im_categories,
	primary key (project_id, language_id)
);



-----------------------------------------------------------
-- Views



-- Add a columns to the projects view showing the "trans_project_size":
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2023,20,NULL,'Appr. Size',
'[if {"" == $trans_project_words} {
        set t ""
} else {
        set t "${trans_project_words}w ${trans_project_hours}h"
}]','','',15,'');





insert into im_views (view_id, view_name, visible_for) values (90, 'trans_task_list', 'view_trans_tasks');


-- Translation TasksListPage columns
--
delete from im_view_columns where column_id >= 9000 and column_id <= 9099;
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9001,90,NULL,'Task Name','$task_name_splitted',
'','',10,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9003,90,NULL,'Target Lang','$target_language',
'','',10,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9004,90,NULL,'XTr','$match_x',
'','',10,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9005,90,NULL,'Rep','$match_rep',
'','',10,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9006,90,NULL,'100 %','$match100',
'','',10,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9007,90,NULL,'95 %','$match95',
'','',10,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9008,90,NULL,'85 %','$match85',
'','',10,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9009,90,NULL,'75 %','$match75',
'','',10,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9010,90,NULL,'50 %','$match50',
'','',10,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9011,90,NULL,'0 %','$match0',
'','',10,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9013,90,NULL,'Units','$task_units $uom_name',
'','',10,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9015,90,NULL,'Bill. Units','$billable_items_input',
'','',10,'expr $project_write');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9017,90,NULL,'Task','$type_name',
'','',10,'expr $project_write');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9019,90,NULL,'Status','$status_select',
'','',10,'expr $project_write');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9021,90,NULL,'[im_gif delete "Delete the Task"]','$del_checkbox',
'','',10,'expr $project_write');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9023,90,NULL,'Assigned','$assignments',
'','',10,'expr $project_write');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9025,90,NULL,'Message','$message',
'','',10,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9027,90,NULL,'[im_gif save "Download files"]','$download_link',
'','',10,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9029,90,NULL,'[im_gif open "Upload files"]','$upload_link',
'','',10,'');
--
commit;


create or replace view im_task_status as 
select category_id as task_status_id, category as task_status
from im_categories 
where category_type = 'Intranet Translation Task Status';


-- -------------------------------------------------------------------
-- Translation Plugins for ProjectViewPage
-- -------------------------------------------------------------------


-- Show the translation specific fields in the ProjectViewPage
--
declare
    v_plugin            integer;
begin
    v_plugin := im_component_plugin.new (
        plugin_name =>  'Company Trados Matrix',
        package_name => 'intranet-translation',
        page_url =>     '/intranet/companies/view',
        location =>     'left',
        sort_order =>   70,
        component_tcl =>
        'im_trans_trados_matrix_component \
                $user_id \
                $company_id \
                $return_url'
    );
end;
/


-- Show the translation specific fields in the ProjectViewPage
--
declare
    v_plugin            integer;
begin
    v_plugin := im_component_plugin.new (
        plugin_name =>  'Project Translation Details',
        package_name => 'intranet-translation',
        page_url =>     '/intranet/projects/view',
        location =>     'left',
        sort_order =>   10,
        component_tcl =>
        'im_trans_project_details_component \
                $user_id \
                $project_id \
                $return_url'
    );
end;
/





-- Show the translation tasks for freelancers on the first page
--
declare
    v_plugin            integer;
begin
    v_plugin := im_component_plugin.new (
        plugin_name =>  'Project Freelance Tasks',
        package_name => 'intranet-translation',
        page_url =>     '/intranet/projects/view',
        location =>     'bottom',
        sort_order =>   10,
        component_tcl =>
        'im_task_freelance_component \
                $user_id \
                $project_id \
                $return_url'
    );
end;
/


-- Show the task component in project page
--
declare
    v_plugin            integer;
begin
    v_plugin := im_component_plugin.new (
	plugin_name =>	'Project Translation Task Status',
	package_name =>	'intranet-translation',
        page_url =>     '/intranet/projects/view',
        location =>     'bottom',
        sort_order =>   10,
        component_tcl => 
	'im_task_status_component \
		$user_id \
		$project_id \
		$return_url'
    );

    -- Show the upload task component in project page

    v_plugin := im_component_plugin.new (
	plugin_name =>	'Project Translation Error Component',
	package_name =>	'intranet-translation',
        page_url =>     '/intranet/projects/view',
        location =>     'bottom',
        sort_order =>   20,
        component_tcl => 
	'im_task_error_component \
		$user_id \
		$project_id \
		$return_url'
    );
end;
/

-- Create Translation specific privileges
begin
    -- Freelancers should normally not see the translation tasks(?)
    acs_privilege.create_privilege(
	'view_trans_tasks',
	'View Trans Tasks',
	'View Trans Tasks');
    acs_privilege.add_child('admin', 'view_trans_task');


    -- Should Freelancers see the Trados matrix for the translation tasks?
    acs_privilege.create_privilege(
	'view_trans_task_matrix',
	'View Trans Task Matrix',
	'View Trans Task Matrix');
    acs_privilege.add_child('admin', 'view_trans_task_matrix');

    -- Should Freelancers see the translation status report?
    acs_privilege.create_privilege(
	'view_trans_task_status',
	'View Trans Task Status',
	'View Trans Task Status');
    acs_privilege.add_child('admin', 'view_trans_task_status');

    -- Should Freelancers see the translation project details?
    -- Everybody can see subject area, source and target language,
    -- but the company project#, delivery date and company contact
    -- are normally reserved for employees.
    acs_privilege.create_privilege(
	'view_trans_proj_detail',
	'View Trans Project Details',
	'View Trans Project Details');
    acs_privilege.add_child('admin', 'view_trans_proj_detail');

end;
/

begin
    im_priv_create('view_trans_tasks', 'Employees');
    im_priv_create('view_trans_tasks', 'Project Managers');
    im_priv_create('view_trans_tasks', 'Senior Managers');
    im_priv_create('view_trans_tasks', 'P/O Admins');
end;
/

begin
    im_priv_create('view_trans_task_matrix', 'Employees');
    im_priv_create('view_trans_task_matrix', 'Project Managers');
    im_priv_create('view_trans_task_matrix', 'Senior Managers');
    im_priv_create('view_trans_task_matrix', 'P/O Admins');
end;
/

begin
    im_priv_create('view_trans_task_status', 'Employees');
    im_priv_create('view_trans_task_status', 'Project Managers');
    im_priv_create('view_trans_task_status', 'Senior Managers');
    im_priv_create('view_trans_task_status', 'P/O Admins');
end;
/




-- -------------------------------------------------------------------
-- Translation Menu Extension for Project
-- -------------------------------------------------------------------

declare
	-- Menu IDs
	v_menu			integer;
	v_project_menu		integer;

	-- Groups
	v_employees		integer;
	v_accounting		integer;
	v_senman		integer;
	v_companies		integer;
	v_freelancers		integer;
	v_proman		integer;
	v_admins		integer;
begin

    select group_id into v_admins from groups where group_name = 'P/O Admins';
    select group_id into v_senman from groups where group_name = 'Senior Managers';
    select group_id into v_proman from groups where group_name = 'Project Managers';
    select group_id into v_accounting from groups where group_name = 'Accounting';
    select group_id into v_employees from groups where group_name = 'Employees';
    select group_id into v_companies from groups where group_name = 'Companies';
    select group_id into v_freelancers from groups where group_name = 'Freelancers';

    select menu_id
    into v_project_menu
    from im_menus
    where label='project';

    v_menu := im_menu.new (
	package_name =>	'intranet',
	label =>	'project_trans_tasks',
	name =>		'Tasks',
	url => '/intranet-translation/trans-tasks/task-list?view_name=trans_tasks',
	sort_order =>	50,
	parent_menu_id => v_project_menu
    );

    acs_permission.grant_permission(v_menu, v_admins, 'read');
    acs_permission.grant_permission(v_menu, v_senman, 'read');
    acs_permission.grant_permission(v_menu, v_proman, 'read');
    acs_permission.grant_permission(v_menu, v_accounting, 'read');
    acs_permission.grant_permission(v_menu, v_employees, 'read');
    acs_permission.grant_permission(v_menu, v_companies, 'read');
    -- no freelancers!


    v_menu := im_menu.new (
	package_name =>	'intranet',
	label =>	'project_trans_task_assignments',
	name =>		'Assignments',
	url =>	'/intranet-translation/trans-tasks/task-assignments?view=standard',
	sort_order =>	60,
	parent_menu_id => v_project_menu
    );

    acs_permission.grant_permission(v_menu, v_admins, 'read');
    acs_permission.grant_permission(v_menu, v_senman, 'read');
    acs_permission.grant_permission(v_menu, v_proman, 'read');
    acs_permission.grant_permission(v_menu, v_accounting, 'read');
    acs_permission.grant_permission(v_menu, v_employees, 'read');
    acs_permission.grant_permission(v_menu, v_companies, 'read');
    -- no freelancers!
end;
/
commit;



-- -------------------------------------------------------------------
-- Categories
-- -------------------------------------------------------------------


insert into im_categories values (87,  'Trans + Edit',  
'',  'Intranet Project Type','category','t','f');
insert into im_categories values (88,  'Edit Only',  '',  
'Intranet Project Type','category','t','f');
insert into im_categories values (89,  'Trans + Edit + Proof',  
'',  'Intranet Project Type','category','t','f');
insert into im_categories values (90,  'Linguistic Validation',  
'',  'Intranet Project Type','category','t','f');
insert into im_categories values (91,  'Localization',  
'',  'Intranet Project Type','category','t','f');
insert into im_categories values (92,  'Technology',  
'',  'Intranet Project Type','category','t','f');
insert into im_categories values (93,  'Trans Only',  
'',  'Intranet Project Type','category','t','f');
insert into im_categories values (94,  'Trans + Int. Spotcheck',  
'',  'Intranet Project Type','category','t','f');
insert into im_categories values (95,  'Proof Only',  
'',  'Intranet Project Type','category','t','f');
insert into im_categories values (96,  'Glossary Compilation',  
'',  'Intranet Project Type','category','t','f');


-- -------------------------------------------------------------------
-- Category Hierarchy
-- -------------------------------------------------------------------

-- 2500-2599    Translation Hierarchy

insert into im_categories values (2500,  'Translation Project',  
'',  'Intranet Project Type','category','t','f');

insert into im_category_hierarchy values (2500,87);
insert into im_category_hierarchy values (2500,88);
insert into im_category_hierarchy values (2500,89);
insert into im_category_hierarchy values (2500,90);
insert into im_category_hierarchy values (2500,91);
insert into im_category_hierarchy values (2500,92);
insert into im_category_hierarchy values (2500,93);
insert into im_category_hierarchy values (2500,94);
insert into im_category_hierarchy values (2500,95);
insert into im_category_hierarchy values (2500,96);


-- -------------------------------------------------------------------
-- Other Categories
-- -------------------------------------------------------------------

-- Intranet Quality
INSERT INTO im_categories VALUES (110,'Premium Quality','Premium Quality','Intranet Quality','category','t','f');
INSERT INTO im_categories VALUES (111,'High Quality','High Quality','Intranet Quality','category','t','f');
INSERT INTO im_categories VALUES (112,'Average Quality','Average Quality','Intranet Quality','category','t','f');
INSERT INTO im_categories VALUES (113,'Draft Quality','Draft Quality','Intranet Quality','category','t','f');


-- Setup the most frequently used language (lang, sort_key, name)
INSERT INTO im_categories VALUES (250,'es','Spanish','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (251,'es_ES','Spanish (Spain)','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (252,'es_LA','Spanish (Latin America)','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (253,'es_US','Spanish (US)','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (254,'es_MX','Spanish (Mexico)','Intranet Translation Language','category','t','f');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(255,'es_VE','Intranet Translation Language','Spanish (Venezuea)');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(256,'es_PE','Intranet Translation Language','Spanish (Peru)');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(257,'es_AR','Intranet Translation Language','Spanish (Argentina)');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(258,'es_UY','Intranet Translation Language','Spanish (Uruguay)');

INSERT INTO im_categories VALUES (261,'en','English','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (262,'en_US','English (US)','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (263,'en_UK','English (UK)','Intranet Translation Language','category','t','f');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(264,'en_CA','Intranet Translation Language','English (Canada)');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(265,'en_IE','Intranet Translation Language','English (Ireland)');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(266,'en_AU','Intranet Translation Language','English (Australia)');


INSERT INTO im_categories (category_id, category, category_type, category_description) VALUES
(268,'it','Intranet Translation Language','Italian');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(269,'it_IT','Intranet Translation Language','Italian Italy');

INSERT INTO im_categories VALUES (271,'fr','French','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (272,'fr_FR','French (France)','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (273,'fr_BE','French (Belgium)','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (274,'fr_CH','French (Switzerland)','Intranet Translation Language','category','t','f');

INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(276,'pt','Intranet Translation Language','Portuguese');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(277,'pt_PT','Intranet Translation Language','Portuguese (Portugal)');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(278,'pt_BR','Intranet Translation Language','Portuguese (Brazil)');

INSERT INTO im_categories VALUES (281,'de','German','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (282,'de_DE','German German','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (283,'de_CH','Swiss German','Intranet Translation Language','category','t','f');

INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(285,'ru','Intranet Translation Language','Russian');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(286,'ru_RU','Intranet Translation Language','Russian (Russian Federation)');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(287,'ru_UA','Intranet Translation Language','Russian (Ukrainia)');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(288,'da','Intranet Translation Language','Danish');


INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(290,'nl','Intranet Translation Language','Dutch');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(291,'nl_NL','Intranet Translation Language','Duch (The Netherlands)');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(292,'nl_BE','Intranet Translation Language','Duch (Belgium)');

INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(294,'ca_ES','Intranet Translation Language','Catalan (Spain)');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(295,'gr','Intranet Translation Language','Greek');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(296,'gl','Intranet Translation Language','Galician');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(297,'eu','Intranet Translation Language','Euskera');

INSERT INTO im_categories VALUES (299,'none','No Language','Intranet Translation Language','category','t','f');


-- Additional UoM categories for translation
INSERT INTO im_categories VALUES (323,'Page','','Intranet UoM','category','t','f');
INSERT INTO im_categories VALUES (324,'S-Word','','Intranet UoM','category','t','f');
INSERT INTO im_categories VALUES (325,'T-Word','','Intranet UoM','category','t','f');
INSERT INTO im_categories VALUES (326,'S-Line','','Intranet UoM','category','t','f');
INSERT INTO im_categories VALUES (327,'T-Line','','Intranet UoM','category','t','f');


-- Task Status
INSERT INTO im_categories VALUES (340,'Created','','Intranet Translation Task Status','category','t','f');
INSERT INTO im_categories VALUES (342,'for Trans','','Intranet Translation Task Status','category','t','f');
INSERT INTO im_categories VALUES (344,'Trans-ing','','Intranet Translation Task Status','category','t','f');
INSERT INTO im_categories VALUES (346,'for Edit','','Intranet Translation Task Status','category','t','f');
INSERT INTO im_categories VALUES (348,'Editing','','Intranet Translation Task Status','category','t','f');
INSERT INTO im_categories VALUES (350,'for Proof','','Intranet Translation Task Status','category','t','f');
INSERT INTO im_categories VALUES (352,'Proofing','','Intranet Translation Task Status','category','t','f');
INSERT INTO im_categories VALUES (354,'for QCing','','Intranet Translation Task Status','category','t','f');
INSERT INTO im_categories VALUES (356,'QCing','','Intranet Translation Task Status','category','t','f');
INSERT INTO im_categories VALUES (358,'for Deliv','','Intranet Translation Task Status','category','t','f');
INSERT INTO im_categories VALUES (360,'Delivered','','Intranet Translation Task Status','category','t','f');
INSERT INTO im_categories VALUES (365,'Invoiced','','Intranet Translation Task Status','category','t','f');
INSERT INTO im_categories VALUES (370,'Payed','','Intranet Translation Task Status','category','t','f');
INSERT INTO im_categories VALUES (372,'Deleted','','Intranet Translation Task Status','category','t','f');
-- reserved until 399


-- Subject Areas
INSERT INTO im_categories VALUES (500,'Bio','','Intranet Translation Subject Area','category','t','f');
INSERT INTO im_categories VALUES (505,'Biz','','Intranet Translation Subject Area','category','t','f');
INSERT INTO im_categories VALUES (510,'Com','','Intranet Translation Subject Area','category','t','f');
INSERT INTO im_categories VALUES (515,'Eco','','Intranet Translation Subject Area','category','t','f');
INSERT INTO im_categories VALUES (520,'Gen','','Intranet Translation Subject Area','category','t','f');
INSERT INTO im_categories VALUES (525,'Law','','Intranet Translation Subject Area','category','t','f');
INSERT INTO im_categories VALUES (530,'Lit','','Intranet Translation Subject Area','category','t','f');
INSERT INTO im_categories VALUES (535,'Loc','','Intranet Translation Subject Area','category','t','f');
INSERT INTO im_categories VALUES (540,'Mkt','','Intranet Translation Subject Area','category','t','f');
INSERT INTO im_categories VALUES (545,'Med','','Intranet Translation Subject Area','category','t','f');
INSERT INTO im_categories VALUES (550,'Tec','','Intranet Translation Subject Area','category','t','f');
INSERT INTO im_categories VALUES (555,'Tec-Auto','','Intranet Translation Subject Area','category','t','f');
INSERT INTO im_categories VALUES (560,'Tec-Telecos','','Intranet Translation Subject Area','category','t','f');
INSERT INTO im_categories VALUES (565,'Tec-Gen','','Intranet Translation Subject Area','category','t','f');
INSERT INTO im_categories VALUES (570,'Tec-Mech. eng','','Intranet Translation Subject Area','category','t','f');
-- reserved until 599


prompt Create the "Tigerpond" company
DECLARE
    v_office_id		integer;
    v_company_id	integer;
BEGIN
    -- First setup the main office
    v_office_id := im_office.new(
        object_type     => 'im_office',
        office_name     => 'Tigerpond Main Office',
        office_path     => 'tigerpond_main_office'
    );

    v_company_id := im_company.new(
	object_type	=> 'im_company',
	company_name	=> 'Tigerpond',
	company_path	=> 'tigerpond',
	main_office_id	=> v_office_id,
	-- Translation Agency
	company_type_id => 54,
	-- 'Active' status
	company_status_id => 46
    );
end;
/
commit;



prompt Create a "Tigerpond" project
declare
	v_project_id		integer;
	v_company_id		integer;
	v_rel_id		integer;
	v_user_id		integer;
begin
	select company_id
	into v_company_id
	from im_companies
	where company_path = 'tigerpond';

	v_project_id := im_project.new(
		object_type	=> 'im_project',
		project_name	=> 'Large Translation Project',
		project_nr	=> '2004_0001',
		project_path	=> '2004_0001',
		company_id	=> v_company_id,
		-- Trans+Edit+Proof Project
		project_type_id	=> 89
	);

	-- Add some users
	-- 1300 is full member, 1301 is PM, 1302 is Key Account
	select party_id	into v_user_id
	from parties where email='project.manager@project-open.com';
	v_rel_id := im_biz_object_member.new (
        	object_id       => v_project_id,
        	user_id         => v_user_id,
        	object_role_id  => 1301
	);

	select party_id	into v_user_id
	from parties where email='staff.member2@project-open.com';
	v_rel_id := im_biz_object_member.new (
        	object_id       => v_project_id,
        	user_id         => v_user_id,
        	object_role_id  => 1300
	);

	select party_id	into v_user_id
	from parties where email='senior.manager@project-open.com';
	v_rel_id := im_biz_object_member.new (
        	object_id       => v_project_id,
        	user_id         => v_user_id,
        	object_role_id  => 1300
	);

	select party_id	into v_user_id
	from parties where email='free.lance2@project-open.com';
	v_rel_id := im_biz_object_member.new (
        	object_id       => v_project_id,
        	user_id         => v_user_id,
        	object_role_id  => 1300
	);
end;
/
commit;
