-- /packages/intranet-translation/sql/postgresql/intranet-translation-create.sql
--
-- Copyright (c) 2003-2004 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com
-- @author juanjoruizx@yahoo.es

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
alter table im_projects add     company_contact_id      integer;
alter table im_projects add FOREIGN KEY (company_contact_id) references users;
alter table im_projects add source_language_id integer;
alter table im_projects add FOREIGN KEY (source_language_id) references im_categories;
alter table im_projects add subject_area_id integer;
alter table im_projects add FOREIGN KEY (subject_area_id) references im_categories;
alter table im_projects add expected_quality_id integer;
alter table im_projects add FOREIGN KEY (expected_quality_id) references im_categories;
alter table im_projects add	final_company		varchar(50);

-- An approximate value for the size (number of words) of the project
alter table im_projects add	trans_project_words	numeric(12,0);
alter table im_projects add	trans_project_hours	numeric(12,0);


-----------------------------------------------------------
-- Tasks
--
-- - Every project can have any number of "Tasks".
-- - Each task represents a work unit that can be billed
--   independently and that will appear as a line in
--   the final invoice to be printed.

create sequence im_trans_tasks_seq start 1;
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
	task_units		numeric(12,1),
				-- sometimes, not all units can be billed...
	billable_units		numeric(12,1),
				-- UoM=Unit of Measure (hours, words, ...)
	task_uom_id		integer not null 
				constraint im_trans_tasks_uom_fk
				references im_categories,
				-- references to financial documents: helps to make
				-- sure a single task isn't invoiced twice or not
				-- being invoiced at all...
				-- invoice_id=null => needs to be invoiced still
				-- invoice_id!= null => has already been invoiced
	invoice_id		integer , -- Todo: remove comments when toni finish invoices
--				constraint im_trans_tasks_invoice_fk
--				references im_invoices,
				-- "Trados Matrix" determine duplicated words
	match_x			numeric(12,0),
	match_rep		numeric(12,0),
	match100		numeric(12,0),
	match95			numeric(12,0),
	match85			numeric(12,0),
	match75			numeric(12,0),
	match50			numeric(12,0),
	match0			numeric(12,0),
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
        match_x			numeric(12,4),
        match_rep		numeric(12,4),
        match100                numeric(12,4),
        match95                 numeric(12,4),
        match85                 numeric(12,4),
	match75			numeric(12,4),
	match50			numeric(12,4),
        match0                  numeric(12,4)
);


-- actions that have occured around im_trans_tasks: upload, download, ...
create sequence im_task_actions_seq start 1;
create table im_task_actions (
	action_id		integer constraint im_task_actions_pk primary key,
	action_type_id		integer 
	                        constraint im_task_action_type_fk
				references im_categories,
	user_id			integer	not null 
				constraint im_task_action_user_fk
				references users,
	task_id			integer not null 
				constraint im_task_action_task_fk
				references im_trans_tasks,
	action_date		date,
	old_status_id		integer
                                constraint im_task_action_old_fk
				references im_categories,
	new_status_id		integer
                                constraint im_task_action_new_fk
				references im_categories
);


-- define into which language we have to translate a certain project.
create table im_target_languages (
	project_id		integer not null 
				constraint im_target_lang_proj_fk
				references im_projects,
	language_id		integer not null 
				constraint im_target_lang_lang_fk
				references im_categories,
	primary key (project_id, language_id)
);



-- -------------------------------------------------------------------
-- Translation Plugins for ProjectViewPage
-- -------------------------------------------------------------------


-- Show the translation specific fields in the ProjectViewPage
--
select im_component_plugin__new (
        null,                           -- plugin_id
        'acs_object',                   -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Company Trados Matrix',        -- plugin_name
        'intranet-translation',         -- package_name
        'left',                         -- location
        '/intranet/companies/view',     -- page_url
        null,                           -- view_name
        70,                             -- sort_order
        'im_trans_trados_matrix_component $user_id $company_id $return_url'
    );


-- Show the translation specific fields in the ProjectViewPage
--
select im_component_plugin__new (
        null,                           -- plugin_id
        'acs_object',                   -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Project Translation Details',  -- plugin_name
        'intranet-translation',         -- package_name
        'left',                         -- location
        '/intranet/projects/view',      -- page_url
        null,                           -- view_name
        10,                             -- sort_order
        'im_trans_project_details_component $user_id $project_id $return_url'
    );



-- Show the translation tasks for freelancers on the first page
--
select im_component_plugin__new (
        null,                           -- plugin_id
        'acs_object',                   -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Project Freelance Tasks',      -- plugin_name
        'intranet-translation',         -- package_name
        'left',                         -- location
        '/intranet/projects/view',       -- page_url
        null,                           -- view_name
        70,                             -- sort_order
        'im_task_freelance_component $user_id $project_id $return_url'
    );


-- Show the task component in project page
--
select im_component_plugin__new (
        null,                           -- plugin_id
        'acs_object',                   -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Project Translation Task Status',  -- plugin_name
        'intranet-translation',         -- package_name
        'bottom',                       -- location
        '/intranet/projects/view',       -- page_url
        null,                           -- view_name
        10,                             -- sort_order
	'im_task_status_component $user_id $project_id $return_url'
    );


-- Show the upload task component in project page

select im_component_plugin__new (
        null,                           -- plugin_id
        'acs_object',                   -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Project Translation Error Component',  -- plugin_name
        'intranet-translation',         -- package_name
        'bottom',                       -- location
        '/intranet/projects/view',      -- page_url
        null,                           -- view_name
        20,                             -- sort_order
	'im_task_error_component $user_id $project_id $return_url'
    );


-- Create Translation specific privileges

    -- Freelancers should normally not see the translation tasks(?)
select acs_privilege__create_privilege(	'view_trans_tasks',	'View Trans Tasks',	'View Trans Tasks');
select acs_privilege__add_child('admin', 'view_trans_tasks');


    -- Should Freelancers see the Trados matrix for the translation tasks?
select acs_privilege__create_privilege(	'view_trans_task_matrix','View Trans Task Matrix','View Trans Task Matrix');
select acs_privilege__add_child('admin', 'view_trans_task_matrix');

    -- Should Freelancers see the translation status report?
select acs_privilege__create_privilege(	'view_trans_task_status','View Trans Task Status','View Trans Task Status');
select acs_privilege__add_child('admin', 'view_trans_task_status');


    -- Should Freelancers see the translation project details?
    -- Everybody can see subject area, source and target language,
    -- but the company project#, delivery date and company contact
    -- are normally reserved for employees__
select acs_privilege__create_privilege(	'view_trans_proj_detail','View Trans Project Details','View Trans Project Details');
select acs_privilege__add_child('admin', 'view_trans_proj_detail');

select im_priv_create('view_trans_tasks', 'Employees');
select im_priv_create('view_trans_tasks', 'Project Managers');
select im_priv_create('view_trans_tasks', 'Senior Managers');
select im_priv_create('view_trans_tasks', 'P/O Admins');


select im_priv_create('view_trans_task_matrix', 'Employees');
select im_priv_create('view_trans_task_matrix', 'Project Managers');
select im_priv_create('view_trans_task_matrix', 'Senior Managers');
select im_priv_create('view_trans_task_matrix', 'P/O Admins');



select im_priv_create('view_trans_task_status', 'Employees');
select im_priv_create('view_trans_task_status', 'Project Managers');
select im_priv_create('view_trans_task_status', 'Senior Managers');
select im_priv_create('view_trans_task_status', 'P/O Admins');





-- -------------------------------------------------------------------
-- Translation Menu Extension for Project
-- -------------------------------------------------------------------

create or replace function inline_0 ()
returns integer as '
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

    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';
    select group_id into v_proman from groups where group_name = ''Project Managers'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';
    select group_id into v_employees from groups where group_name = ''Employees'';
    select group_id into v_companies from groups where group_name = ''Customers'';
    select group_id into v_freelancers from groups where group_name = ''Freelancers'';

    select menu_id
    into v_project_menu
    from im_menus
    where label=''project'';

    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet'',     -- package_name
        ''project_trans_tasks'', -- label
        ''Tasks'',               -- name
        ''/intranet-translation/trans-tasks/task-list?view_name=trans_tasks'', -- url
        50,                     -- sort_order
        v_project_menu,         -- parent_menu_id
        ''[im_project_has_type [ns_set get $bind_vars project_id] "Translation Project"]'' -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_companies, ''read'');
    -- no freelancers!


    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet'',     -- package_name
        ''project_trans_tasks_assignments'', -- label
        ''Assignments'',        -- name
        ''/intranet-translation/trans-tasks/task-assignments?view=standard'', -- url
        60,                     -- sort_order
        v_project_menu,         -- parent_menu_id
        ''[im_project_has_type [ns_set get $bind_vars project_id] "Translation Project"]''  -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_companies, ''read'');
    -- no freelancers!

    return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();


-- -------------------------------------------------------------------
-- Table for calculating Trans Project progress
-- -------------------------------------------------------------------


create table im_trans_task_progress (
	task_type_id		integer not null
				constraint im_trans_task_progres_type_fk
				references im_categories,
	task_status_id		integer not null
				constraint im_trans_task_progres_status_fk
				references im_categories,
	percent_completed	numeric(6,2)
);

create unique index im_trans_task_progress_idx 
on im_trans_task_progress
(task_type_id, task_status_id);

-- Task Status
--
-- 340	Created
-- 342 	for Trans
-- 344 	Trans-ing
-- 346 	for Edit
-- 348 	Editing
-- 350 	for Proof
-- 352 	Proofing
-- 354 	for QCing
-- 356 	QCing
-- 358 	for Deliv
-- 360 	Delivered
-- 365 	Invoiced
-- 370 	Payed
-- 372 	Deleted

-- Task Types
--
-- 85  	Unknown  		
-- 86 	Other 		
-- 87 	Trans + Edit 	Translation Project 	
-- 88 	Edit Only 	Translation Project 	
-- 89 	Trans + Edit + Proof 	Translation Project 	
-- 90 	Linguistic Validation 	Translation Project 	
-- 91 	Localization 	Consulting Project 
-- 92 	Technology 	Translation Project 	
-- 93 	Trans Only 	Translation Project 	
-- 94 	Trans + Int. Spotcheck 	Translation Project 	
-- 95 	Proof Only 	Translation Project 	
-- 96 	Glossary Compilation 	Translation Project 	


-- values for 340 and 342 are 0 for all task types
-- values for 354, 356, 358, 360, 365, 370, 372 are always 100%

-- Trans + Edit
insert into im_trans_task_progress values (87, 344, 40);
insert into im_trans_task_progress values (87, 346, 80);
insert into im_trans_task_progress values (87, 348, 90);
insert into im_trans_task_progress values (87, 350, 100);
insert into im_trans_task_progress values (87, 352, 100);

-- Edit
insert into im_trans_task_progress values (88, 344, 0);
insert into im_trans_task_progress values (88, 346, 0);
insert into im_trans_task_progress values (88, 348, 50);
insert into im_trans_task_progress values (88, 350, 100);
insert into im_trans_task_progress values (88, 352, 100);

-- Trans + Edit + Proof
insert into im_trans_task_progress values (89, 344, 35);
insert into im_trans_task_progress values (89, 346, 70);
insert into im_trans_task_progress values (89, 348, 80);
insert into im_trans_task_progress values (89, 350, 90);
insert into im_trans_task_progress values (89, 352, 95);

-- Trans Only
insert into im_trans_task_progress values (93, 344, 50);
insert into im_trans_task_progress values (93, 346, 100);
insert into im_trans_task_progress values (93, 348, 100);
insert into im_trans_task_progress values (93, 350, 100);
insert into im_trans_task_progress values (93, 352, 100);

-- Trans + Intl. Spotcheck
insert into im_trans_task_progress values (94, 344, 44);
insert into im_trans_task_progress values (94, 346, 80);
insert into im_trans_task_progress values (94, 348, 90);
insert into im_trans_task_progress values (94, 350, 100);
insert into im_trans_task_progress values (94, 352, 100);

-- Proof
insert into im_trans_task_progress values (95, 344, 0);
insert into im_trans_task_progress values (95, 346, 0);
insert into im_trans_task_progress values (95, 348, 0);
insert into im_trans_task_progress values (95, 350, 0);
insert into im_trans_task_progress values (95, 352, 50);


-- values for 340 and 342 are 0 for all task types
insert into im_trans_task_progress values (85, 340, 0);
insert into im_trans_task_progress values (86, 340, 0);
insert into im_trans_task_progress values (87, 340, 0);
insert into im_trans_task_progress values (88, 340, 0);
insert into im_trans_task_progress values (89, 340, 0);
insert into im_trans_task_progress values (90, 340, 0);
insert into im_trans_task_progress values (91, 340, 0);
insert into im_trans_task_progress values (92, 340, 0);
insert into im_trans_task_progress values (93, 340, 0);
insert into im_trans_task_progress values (94, 340, 0);
insert into im_trans_task_progress values (95, 340, 0);
insert into im_trans_task_progress values (96, 340, 0);

-- values for 340 and 342 are 0 for all task types
insert into im_trans_task_progress values (85, 342, 0);
insert into im_trans_task_progress values (86, 342, 0);
insert into im_trans_task_progress values (87, 342, 0);
insert into im_trans_task_progress values (88, 342, 0);
insert into im_trans_task_progress values (89, 342, 0);
insert into im_trans_task_progress values (90, 342, 0);
insert into im_trans_task_progress values (91, 342, 0);
insert into im_trans_task_progress values (92, 342, 0);
insert into im_trans_task_progress values (93, 342, 0);
insert into im_trans_task_progress values (94, 342, 0);
insert into im_trans_task_progress values (95, 342, 0);
insert into im_trans_task_progress values (96, 342, 0);

-- values for 354, 356, 358, 360, 365, 370, 372 are always 100%
insert into im_trans_task_progress values (85, 354, 100);
insert into im_trans_task_progress values (86, 354, 100);
insert into im_trans_task_progress values (87, 354, 100);
insert into im_trans_task_progress values (88, 354, 100);
insert into im_trans_task_progress values (89, 354, 100);
insert into im_trans_task_progress values (90, 354, 100);
insert into im_trans_task_progress values (91, 354, 100);
insert into im_trans_task_progress values (92, 354, 100);
insert into im_trans_task_progress values (93, 354, 100);
insert into im_trans_task_progress values (94, 354, 100);
insert into im_trans_task_progress values (95, 354, 100);
insert into im_trans_task_progress values (96, 354, 100);

-- values for 354, 356, 358, 360, 365, 370, 372 are always 100%
insert into im_trans_task_progress values (85, 356, 100);
insert into im_trans_task_progress values (86, 356, 100);
insert into im_trans_task_progress values (87, 356, 100);
insert into im_trans_task_progress values (88, 356, 100);
insert into im_trans_task_progress values (89, 356, 100);
insert into im_trans_task_progress values (90, 356, 100);
insert into im_trans_task_progress values (91, 356, 100);
insert into im_trans_task_progress values (92, 356, 100);
insert into im_trans_task_progress values (93, 356, 100);
insert into im_trans_task_progress values (94, 356, 100);
insert into im_trans_task_progress values (95, 356, 100);
insert into im_trans_task_progress values (96, 356, 100);

-- values for 354, 356, 358, 360, 365, 370, 372 are always 100%
insert into im_trans_task_progress values (85, 358, 100);
insert into im_trans_task_progress values (86, 358, 100);
insert into im_trans_task_progress values (87, 358, 100);
insert into im_trans_task_progress values (88, 358, 100);
insert into im_trans_task_progress values (89, 358, 100);
insert into im_trans_task_progress values (90, 358, 100);
insert into im_trans_task_progress values (91, 358, 100);
insert into im_trans_task_progress values (92, 358, 100);
insert into im_trans_task_progress values (93, 358, 100);
insert into im_trans_task_progress values (94, 358, 100);
insert into im_trans_task_progress values (95, 358, 100);
insert into im_trans_task_progress values (96, 358, 100);

-- values for 354, 356, 358, 360, 365, 370, 372 are always 100%
insert into im_trans_task_progress values (85, 360, 100);
insert into im_trans_task_progress values (86, 360, 100);
insert into im_trans_task_progress values (87, 360, 100);
insert into im_trans_task_progress values (88, 360, 100);
insert into im_trans_task_progress values (89, 360, 100);
insert into im_trans_task_progress values (90, 360, 100);
insert into im_trans_task_progress values (91, 360, 100);
insert into im_trans_task_progress values (92, 360, 100);
insert into im_trans_task_progress values (93, 360, 100);
insert into im_trans_task_progress values (94, 360, 100);
insert into im_trans_task_progress values (95, 360, 100);
insert into im_trans_task_progress values (96, 360, 100);

-- values for 354, 356, 358, 360, 365, 370, 372 are always 100%
insert into im_trans_task_progress values (85, 365, 100);
insert into im_trans_task_progress values (86, 365, 100);
insert into im_trans_task_progress values (87, 365, 100);
insert into im_trans_task_progress values (88, 365, 100);
insert into im_trans_task_progress values (89, 365, 100);
insert into im_trans_task_progress values (90, 365, 100);
insert into im_trans_task_progress values (91, 365, 100);
insert into im_trans_task_progress values (92, 365, 100);
insert into im_trans_task_progress values (93, 365, 100);
insert into im_trans_task_progress values (94, 365, 100);
insert into im_trans_task_progress values (95, 365, 100);
insert into im_trans_task_progress values (96, 365, 100);

-- values for 354, 356, 358, 360, 365, 370, 372 are always 100%
insert into im_trans_task_progress values (85, 370, 100);
insert into im_trans_task_progress values (86, 370, 100);
insert into im_trans_task_progress values (87, 370, 100);
insert into im_trans_task_progress values (88, 370, 100);
insert into im_trans_task_progress values (89, 370, 100);
insert into im_trans_task_progress values (90, 370, 100);
insert into im_trans_task_progress values (91, 370, 100);
insert into im_trans_task_progress values (92, 370, 100);
insert into im_trans_task_progress values (93, 370, 100);
insert into im_trans_task_progress values (94, 370, 100);
insert into im_trans_task_progress values (95, 370, 100);
insert into im_trans_task_progress values (96, 370, 100);

-- values for 354, 356, 358, 360, 365, 370, 372 are always 100%
insert into im_trans_task_progress values (85, 372, 100);
insert into im_trans_task_progress values (86, 372, 100);
insert into im_trans_task_progress values (87, 372, 100);
insert into im_trans_task_progress values (88, 372, 100);
insert into im_trans_task_progress values (89, 372, 100);
insert into im_trans_task_progress values (90, 372, 100);
insert into im_trans_task_progress values (91, 372, 100);
insert into im_trans_task_progress values (92, 372, 100);
insert into im_trans_task_progress values (93, 372, 100);
insert into im_trans_task_progress values (94, 372, 100);
insert into im_trans_task_progress values (95, 372, 100);
insert into im_trans_task_progress values (96, 372, 100);


-- -------------------------------------------------------------------
-- Source common code
-- -------------------------------------------------------------------

\i ../common/intranet-translation-common.sql
\i ../common/intranet-translation-backup.sql