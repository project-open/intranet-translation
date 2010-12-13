-- /packages/intranet-translation/sql/postgresql/intranet-translation-create.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
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

-- -------------------------------------------------------------------
-- Source common code
-- -------------------------------------------------------------------

\i ../common/intranet-translation-common.sql
\i ../common/intranet-translation-backup.sql

-----------------------------------------------------------
-- Projects (Extensions)
--
-- Add some translation specific fields to a project.

alter table im_projects add source_language_id integer;
alter table im_projects add FOREIGN KEY (source_language_id) references im_categories;

alter table im_projects add subject_area_id integer;
alter table im_projects add FOREIGN KEY (subject_area_id) references im_categories;

alter table im_projects add expected_quality_id integer;
alter table im_projects add FOREIGN KEY (expected_quality_id) references im_categories;


-- An approximate value for the size (number of words) of the project
alter table im_projects add trans_project_words	numeric(12,0);
alter table im_projects add trans_project_hours	numeric(12,0);

-- New form of adding the approximate size of the project:
-- Text format, because there are just too many UoMs around
-- that are necessary to consider
alter table im_projects add	trans_size		varchar(200);


-----------------------------------------------------------
-- Intranet Translation Tasks
--
-- - Every project can have any number of "Tasks".
-- - Each task represents a work unit that can be billed
--   independently and that will appear as a line in
--   the final invoice to be printed.

-- Create a new Object Type
select acs_object_type__create_type (
	'im_trans_task',	-- object_type
	'Translation Task',	-- pretty_name
	'Translation Tasks',	-- pretty_plural
	'acs_object',		-- supertype
	'im_trans_tasks',	-- table_name
	'task_id',		-- id_column
	'im_trans_task',	-- package_name
	'f',			-- abstract_p
	null,			-- type_extension_table
	'im_trans_task__name'	-- name_method
);

insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_trans_task', 'im_trans_tasks', 'task_id');

-- Create entries for URL to allow editing TransTasks in
-- list pages with mixed object types
--
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_trans_task','view','/intranet-translation/trans-tasks/new?form_mode=display&task_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_trans_task','edit','/intranet-translation/trans-tasks/new?form_mode=edit&task_id=');



update acs_object_types set
        status_type_table = 'im_trans_tasks',
        status_column = 'task_status_id',
        type_column = 'task_type_id'
where object_type = 'im_trans_task';



-- Main Object Table
create table im_trans_tasks (
	task_id			integer 
				constraint im_trans_tasks_pk
				primary key
				constraint im_trans_task_id_fk
				references acs_objects,
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
				-- Trados or Ophelia or Xxxx
				-- not a Not Null constraint yet
	tm_type_id		integer
				constraint im_trans_tasks_tm_type_fk
				references im_categories,
	description		text,
	source_language_id	integer not null
				constraint im_trans_tasks_source_fk
				references im_categories,
				-- fees: N units of "UoM" (Unit of Measurement)
				-- raw units to be delivered to the client
	task_units		numeric(12,1),
				-- sometimes, not all units can be billed...
	billable_units		numeric(12,1),
				-- ... and not everything to internal customers
	billable_units_interco	numeric(12,1),
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
	quote_id		integer
				constraint im_trans_tasks_quote_fk
				references im_invoices,
				-- New field to indicate translators when
				-- this task should be finished.
				-- Defaults to project end_date
	end_date		timestamptz,
	tm_integration_type_id	integer 
				constraint im_trans_tm_integration_type_fk
				references im_categories,
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




-- ------------------------------------------------------------
-- Translation Task Methods
-- ------------------------------------------------------------


create or replace function im_trans_task__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	integer, integer, integer, integer, integer, integer
) returns integer as '
DECLARE
	p_task_id		alias for $1;
	p_object_type		alias for $2;
	p_creation_date		alias for $3;
	p_creation_user		alias for $4;
	p_creation_ip		alias for $5;
	p_context_id		alias for $6;

	p_project_id		alias for $7;
	p_task_type_id		alias for $8;
	p_task_status_id	alias for $9;
	p_source_language_id	alias for $10;
	p_target_language_id	alias for $11;
	p_task_uom_id		alias for $12;

	v_task_id	integer;
BEGIN
	v_task_id := acs_object__new (
		p_task_id,
		p_object_type,
		p_creation_date,
		p_creation_user,
		p_creation_ip,
		p_context_id
	);

	insert into im_trans_tasks (
		task_id, project_id,
		task_type_id, task_status_id,
		source_language_id, target_language_id,
		task_uom_id
	) values (
		v_task_id, p_project_id,
		p_task_type_id, p_task_status_id,
		p_source_language_id, p_target_language_id,
		p_task_uom_id
	);

	return v_task_id;
end;' language 'plpgsql';


create or replace function im_trans_task__delete (integer) returns integer as '
DECLARE
	v_task_id	 alias for $1;
BEGIN
	-- ToDo: Check if there is a WF case associated with the object(?)

	-- Erase the im_trans_tasks item associated with the id
	delete from     im_trans_tasks
	where	   task_id = v_task_id;

	-- Erase all the priviledges
	delete from     acs_permissions
	where	   object_id = v_task_id;

	PERFORM acs_object__delete(v_task_id);

	return 0;
end;' language 'plpgsql';


create or replace function im_trans_task__name (integer) returns varchar as '
DECLARE
	v_task_id    alias for $1;
	v_name	  varchar;
BEGIN
	select  task_name
	into    v_name
	from    im_trans_tasks
	where   task_id = v_task_id;

	return v_name;
end;' language 'plpgsql';


-- ------------------------------------------------------------
-- Code to clone a project
-- ------------------------------------------------------------


create or replace function im_trans_task__project_clone (integer, integer) 
returns integer as '
DECLARE
	p_parent_project_id	alias for $1;
	p_clone_project_id	alias for $2;

        row		RECORD;
        v_task_id	integer;
BEGIN
    FOR row IN
	select	t.*
	from	im_trans_tasks t
	where	project_id = p_parent_project_id
    LOOP
	v_task_id := im_trans_task__new(
		null,			-- task_id
		''im_trans_task'',	-- object_type
		now(),			-- creation_date
		0,			-- creation_user
		''0.0.0.0'',		-- creation_ip
		null,			-- context_id
		p_clone_project_id,	-- project_id
		row.task_type_id,	-- task_type_id
		row.task_status_id,	-- task_status_id
		row.source_language_id,	-- source_language_id
		row.target_language_id,	-- target_language_id
		row.task_uom_id		-- task_uom_id
	);

	UPDATE im_trans_tasks SET
		task_name = row.task_name,
		task_filename = row.task_filename,
		description = row.description,
		task_units = row.task_units,
		billable_units = row.billable_units,
		match100 = row.match100,
		match95 = row.match95,
		match85 = row.match85,
		match0 = row.match0
	WHERE 
		task_id = v_task_id
	;
    END LOOP;
    return 0;
end;' language 'plpgsql';




-- ------------------------------------------------------------
-- Return a list of target languages for a project
-- ------------------------------------------------------------

create or replace function im_trans_project_target_languages (integer) 
returns varchar as '
DECLARE
	p_project_id		alias for $1;

        row			RECORD;
	v_result		varchar;
BEGIN
    v_result := '''';

    FOR row IN
	select	tl.*,
		im_category_from_id(tl.language_id) as language
	from	im_target_languages tl
	where	tl.project_id = p_project_id
    LOOP
	IF '''' != v_result THEN v_result := v_result || '', ''; END IF;
	v_result := v_result || row.language;
    END LOOP;

    return v_result;
end;' language 'plpgsql';


-- ------------------------------------------------------------
-- Trados Matrix
-- ------------------------------------------------------------

-- Trados Matrix by object (normally by company)
create table im_trans_trados_matrix (
	object_id		integer 
				constraint im_trans_matrix_cid_fk
				references acs_objects
				constraint im_trans_matrix_pk
				primary key,
	match_x			numeric(12,4),
	match_rep		numeric(12,4),
	match100		numeric(12,4),
	match95		 numeric(12,4),
	match85		 numeric(12,4),
	match75			numeric(12,4),
	match50			numeric(12,4),
	match0		  numeric(12,4)
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
				references im_categories,
	upload_file		text
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
	null,			   -- plugin_id
	'acs_object',		   -- object_type
	now(),			  -- creation_date
	null,			   -- creation_user
	null,			   -- creation_ip
	null,			   -- context_id
	'Company Trados Matrix',	-- plugin_name
	'intranet-translation',	 -- package_name
	'left',			 -- location
	'/intranet/companies/view',     -- page_url
	null,			   -- view_name
	70,			     -- sort_order
	'im_trans_trados_matrix_component $user_id $company_id $return_url'
    );


-- Show the translation specific fields in the ProjectViewPage
--
select im_component_plugin__new (
	null,			   -- plugin_id
	'acs_object',		   -- object_type
	now(),			  -- creation_date
	null,			   -- creation_user
	null,			   -- creation_ip
	null,			   -- context_id
	'Project Translation Details',  -- plugin_name
	'intranet-translation',	 -- package_name
	'left',			 -- location
	'/intranet/projects/view',      -- page_url
	null,			   -- view_name
	10,			     -- sort_order
	'im_trans_project_details_component $user_id $project_id $return_url'
    );



-- Show the translation tasks for freelancers on the first page
--
select im_component_plugin__new (
	null,			   -- plugin_id
	'acs_object',		   -- object_type
	now(),			  -- creation_date
	null,			   -- creation_user
	null,			   -- creation_ip
	null,			   -- context_id
	'Project Freelance Tasks',      -- plugin_name
	'intranet-translation',	 -- package_name
	'left',			 -- location
	'/intranet/projects/view',       -- page_url
	null,			   -- view_name
	70,			     -- sort_order
	'im_task_freelance_component $user_id $project_id $return_url'
    );


-- Show the task component in project page
--
select im_component_plugin__new (
	null,			   -- plugin_id
	'acs_object',		   -- object_type
	now(),			  -- creation_date
	null,			   -- creation_user
	null,			   -- creation_ip
	null,			   -- context_id
	'Project Translation Task Status',  -- plugin_name
	'intranet-translation',	 -- package_name
	'bottom',		       -- location
	'/intranet/projects/view',       -- page_url
	null,			   -- view_name
	10,			     -- sort_order
	'im_task_status_component $user_id $project_id $return_url'
    );


-- Show the upload task component in project page

select im_component_plugin__new (
	null,			   -- plugin_id
	'acs_object',		   -- object_type
	now(),			  -- creation_date
	null,			   -- creation_user
	null,			   -- creation_ip
	null,			   -- context_id
	'Project Translation Error Component',  -- plugin_name
	'intranet-translation',	 -- package_name
	'bottom',		       -- location
	'/intranet/projects/view',      -- page_url
	null,			   -- view_name
	20,			     -- sort_order
	'im_task_error_component $user_id $project_id $return_url'
    );


-- Create Translation specific privileges

-- Freelancers should normally not see the translation tasks(?)
select acs_privilege__create_privilege('view_trans_tasks',
	'View Trans Tasks','View Trans Tasks');
select acs_privilege__add_child('admin', 'view_trans_tasks');


-- Should Freelancers see the Trados matrix for the translation tasks?
select acs_privilege__create_privilege('view_trans_task_matrix',
	'View Trans Task Matrix','View Trans Task Matrix');
select acs_privilege__add_child('admin','view_trans_task_matrix');

-- Should Freelancers see the translation status report?
select acs_privilege__create_privilege('view_trans_task_status',
	'View Trans Task Status','View Trans Task Status');
select acs_privilege__add_child('admin','view_trans_task_status');


-- Should Freelancers see the translation project details?
-- Everybody can see subject area, source and target language,
-- but the company project#, delivery date and company contact
-- are normally reserved for employees__
select acs_privilege__create_privilege('view_trans_proj_detail',
	'View Trans Project Details','View Trans Project Details');
select acs_privilege__add_child('admin','view_trans_proj_detail');

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
	null,		   -- p_menu_id
	''acs_object'',	 -- object_type
	now(),		  -- creation_date
	null,		   -- creation_user
	null,		   -- creation_ip
	null,		   -- context_id
	''intranet'',     -- package_name
	''project_trans_tasks'', -- label
	''Trans Tasks'',	       -- name
	''/intranet-translation/trans-tasks/task-list?view_name=trans_tasks'', -- url
	50,		     -- sort_order
	v_project_menu,	 -- parent_menu_id
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
	null,		   -- p_menu_id
	''acs_object'',	 -- object_type
	now(),		  -- creation_date
	null,		   -- creation_user
	null,		   -- creation_ip
	null,		   -- context_id
	''intranet'',     -- package_name
	''project_trans_tasks_assignments'', -- label
	''Assignments'',	-- name
	''/intranet-translation/trans-tasks/task-assignments?view=standard'', -- url
	60,		     -- sort_order
	v_project_menu,	 -- parent_menu_id
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
				constraint im_trans_task_progress_ck
				check(percent_completed >= 0 and percent_completed <= 100)
);


create unique index im_trans_task_progress_idx 
on im_trans_task_progress (task_type_id, task_status_id);

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





-----------------------------------------------------------
-- 60000-60999  Intranet Translation Task CSV Importer (1000)
--
-- This range allows to plug-in additional CSV importers
-- into the translation package. Please contact 
-- support@project-open.com if you need a constant from 
-- this range.

-- The following importers are defined in intranet-cust-moravia:
-- 60000	Idiom (Beta)
-- 60010	Passolo (Beta)
-- 60010	Helium (Beta)
-- 60099	reserved (last Moravia importer)
-- 60100	free until 60999




-----------------------------------------------------------
-- Trans Task Progress - how many % is a task of a specific
-- type advanced in a specific state?
--
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
-- Set default only after sourcing the categories
-- -------------------------------------------------------------------

-- alter table im_trans_tasks
-- alter column tm_type_id
-- set default 4100;


-- -------------------------------------------------------------------
-- Add source_language_id to list of project DynFields
-- in order to allow for "Advanced Filtering" to include this field.
-- -------------------------------------------------------------------


-----------------------------------------------------------
-- DynFields
-----------------------------------------------------------


---------------------------------------------------
-- Widgets to render DynFields
--
select im_dynfield_widget__new (
	null,					-- widget_id
	'im_dynfield_widget',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'translation_languages',		-- widget_name
	'#intranet-translation.Trans_Langs#',	-- pretty_name
	'#intranet-translation.Trans_Langs#',	-- pretty_plural
	10007,					-- storage_type_id
	'integer',				-- acs_datatype
	'im_category_tree',			-- widget
	'integer',				-- sql_datatype
	'{custom {category_type "Intranet Translation Language"}}' -- parameters
);

select im_dynfield_widget__new (
	null,					-- widget_id
	'im_dynfield_widget',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'translation_subject_area',		-- widget_name
	'#intranet-translation.Subject_Area#',	-- pretty_name
	'#intranet-translation.Subject_Area#',	-- pretty_plural
	10007,					-- storage_type_id
	'integer',				-- acs_datatype
	'im_category_tree',			-- widget
	'integer',				-- sql_datatype
	'{custom {category_type "Intranet Translation Subject Area"}}' -- parameters
);

select im_dynfield_widget__new (
	null,					-- widget_id
	'im_dynfield_widget',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'translation_quality_type',		-- widget_name
	'#intranet-translation.Quality_Level#',	-- pretty_name
	'#intranet-translation.Quality_Level#',	-- pretty_plural
	10007,					-- storage_type_id
	'integer',				-- acs_datatype
	'im_category_tree',			-- widget
	'integer',				-- sql_datatype
	'{custom {category_type "Intranet Translation Quality Type"}}' -- parameters
);

select im_dynfield_widget__new (
	null,					-- widget_id
	'im_dynfield_widget',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'translation_file_type',		-- widget_name
	'#intranet-translation.File_Type#',	-- pretty_name
	'#intranet-translation.File_Type#',	-- pretty_plural
	10007,					-- storage_type_id
	'integer',				-- acs_datatype
	'im_category_tree',			-- widget
	'integer',				-- sql_datatype
	'{custom {category_type "Intranet Translation File Type"}}' -- parameters
);


---------------------------------------------------
-- DynFields for im_project
--

alter table im_projects add column source_language_id integer
constraint im_projects_source_lang_fk references im_categories;

SELECT im_dynfield_attribute_new (
	'im_project',
	'source_language_id',
	'Translation Source Lang',
	'translation_languages',
	'integer',
	'f',
	'99',
	't'
);

alter table im_projects add column subject_area_id integer
constraint im_projects_source_lang_fk references im_categories;

SELECT im_dynfield_attribute_new (
	'im_project',
	'subject_area_id',
	'Translation Subject Area',
	'translation_subject_area',
	'integer',
	'f',
	'99',
	't'
);



---------------------------------------------------
-- DynFields for im_company
--

-- alter table im_companies drop column default_pm_fee_percentage;
-- alter table im_companies add default_pm_fee_percentage float;
alter table im_companies add default_pm_fee_perc numeric(12,2);
alter table im_companies add default_surcharge_perc numeric(12,2);
alter table im_companies add default_discount_perc numeric(12,2);
SELECT im_dynfield_attribute_new ('im_company', 'default_pm_fee_perc', 'Default PM Fee Percentage', 'numeric', 'float', 'f');
SELECT im_dynfield_attribute_new ('im_company', 'default_surcharge_perc', 'Default Surcharge Percentage', 'numeric', 'float', 'f');
SELECT im_dynfield_attribute_new ('im_company', 'default_discount_perc', 'Default Discount Percentage', 'numeric', 'float', 'f');



---------------------------------------------------
-- DynFields for im_material
--

alter table im_materials add column task_uom_id integer
constraint im_materials_task_uom_fk references im_categories;

SELECT im_dynfield_attribute_new (
	'im_material',
	'task_uom_id',
	'Translation UoM Type',
	'units_of_measure',
	'integer',
	'f',
	'0',
	't'
);


alter table im_materials add column trans_task_id integer
constraint im_materials_trans_task_fk references im_categories;

SELECT im_dynfield_attribute_new (
	'im_material',
	'task_type_id',
	'Translation Task Type',
	'trans_task_types',
	'integer',
	'f',
	'100',
	't'
);


alter table im_materials add column source_language_id integer
constraint im_materials_source_lang_fk references im_categories;

SELECT im_dynfield_attribute_new (
	'im_material',
	'source_language_id',
	'Translation Source Lang',
	'translation_languages',
	'integer',
	'f',
	'200',
	't'
);

alter table im_materials add column target_language_id integer
constraint im_materials_target_lang_fk references im_categories;

SELECT im_dynfield_attribute_new (
	'im_material',
	'target_language_id',
	'Translation Target Lang',
	'translation_languages',
	'integer',
	'f',
	'300',
	't'
);

alter table im_materials add column subject_area_id integer
constraint im_materials_source_lang_fk references im_categories;

SELECT im_dynfield_attribute_new (
	'im_material',
	'subject_area_id',
	'Translation Subject Area',
	'translation_subject_area',
	'integer',
	'f',
	'400',
	't'
);


alter table im_materials add column file_type_id integer
constraint im_materials_file_type_fk references im_categories;

SELECT im_dynfield_attribute_new (
	'im_material',
	'file_type_id',
	'Translation File Type',
	'trans_file_types',
	'integer',
	'f',
	'500',
	't'
);

