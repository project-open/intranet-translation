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

alter table im_projects add	company_project_nr	text;
alter table im_projects add	company_contact_id	integer references users;
alter table im_projects add	source_language_id	references im_categories;
alter table im_projects add	subject_area_id		references im_categories;
alter table im_projects add	expected_quality_id	references im_categories;
alter table im_projects add	final_company		text;

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
	description		text,
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
    acs_privilege.add_child('admin', 'view_trans_tasks');


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
    select group_id into v_companies from groups where group_name = 'Customers';
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
	parent_menu_id => v_project_menu,
	visible_tcl => '[im_project_has_type [ns_set get $bind_vars project_id] "Translation Project"]'
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
	parent_menu_id => v_project_menu,
	visible_tcl => '[im_project_has_type [ns_set get $bind_vars project_id] "Translation Project"]'
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

@../common/intranet-translation-common.sql
@../common/intranet-translation-backup.sql