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

alter table im_projects add	customer_project_nr	varchar(50);
alter table im_projects add	customer_contact_id	integer references users;
alter table im_projects add	source_language_id	references im_categories;
alter table im_projects add	subject_area_id		references im_categories;
alter table im_projects add	expected_quality_id	references im_categories;
alter table im_projects add	final_customer		varchar(50);


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
				--  added later to avoid a cyclical reference:
	-- invoice_id		integer 
	--			constraint im_trans_tasks_invoice_fk
	--			references im_invoices,
				-- SLS user fields to determine the work effort
	match100		number(12,0),
	match95			number(12,0),
	match85			number(12,0),
	match0			number(12,0),
				-- SLS Workflow
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

insert into im_views (view_id, view_name, visible_for) values (90, 'trans_task_list', 'view_trans_tasks');


-- Tranlation TasksListPage columns
--
delete from im_view_columns where column_id >= 9000 and column_id <= 9099;
--
insert into im_view_columns values (9001,90,NULL,'Task Name','$task_name_splitted','','',10,'');
insert into im_view_columns values (9003,90,NULL,'Target Lang','$target_language','','',10,'');
insert into im_view_columns values (9005,90,NULL,'100 %','$match100','','',10,
'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns values (9007,90,NULL,'95 %','$match95','','',10,
'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns values (9009,90,NULL,'85 %','$match85','','',10,
'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns values (9011,90,NULL,'0 %','$match0','','',10,
'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns values (9013,90,NULL,'Units','$task_units $uom_name','','',10,'');
insert into im_view_columns values (9015,90,NULL,'Bill. Units','$billable_items_input','','',10,'');
insert into im_view_columns values (9017,90,NULL,'Task','$type_name','','',10,'');
insert into im_view_columns values (9019,90,NULL,'Status','$status_select','','',10,'');
insert into im_view_columns values (9021,90,NULL,'[im_gif delete "Delete the Task"]','$del_checkbox','','',10,'');
insert into im_view_columns values (9023,90,NULL,'Assigned','$assignments','','',10,'');
insert into im_view_columns values (9025,90,NULL,'Message','$message','','',10,'');
insert into im_view_columns values (9027,90,NULL,'[im_gif save "Download files"]','$download_link','','',10,'');
insert into im_view_columns values (9029,90,NULL,'[im_gif open "Upload files"]','$upload_link','','',10,'');
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
        plugin_name =>  'Project Translation Details',
        package_name => 'intranet-translation',
        page_url =>     '/intranet/projects/view',
        location =>     'left',
        sort_order =>   10,
        component_tcl =>
        'im_trans_project_details \
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

    -- Should Freelancers see the Trados matrix for the translation tasks?
    acs_privilege.create_privilege(
	'view_trans_task_matrix',
	'View Trans Task Matrix',
	'View Trans Task Matrix');

    -- Should Freelancers see the translation status report?
    acs_privilege.create_privilege(
	'view_trans_task_status',
	'View Trans Task Status',
	'View Trans Task Status');
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
	v_customers		integer;
	v_freelancers		integer;
	v_proman		integer;
	v_admins		integer;
begin

    select group_id into v_admins from groups where group_name = 'P/O Admins';
    select group_id into v_senman from groups where group_name = 'Senior Managers';
    select group_id into v_proman from groups where group_name = 'Project Managers';
    select group_id into v_accounting from groups where group_name = 'Accounting';
    select group_id into v_employees from groups where group_name = 'Employees';
    select group_id into v_customers from groups where group_name = 'Customers';
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
    acs_permission.grant_permission(v_menu, v_customers, 'read');
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
    acs_permission.grant_permission(v_menu, v_customers, 'read');
    -- no freelancers!
end;
/
commit;



-- -------------------------------------------------------------------
-- Categories
-- -------------------------------------------------------------------


-- insert into im_categories
delete from im_categories where category_id >= 2420 and category_id < 2430;
INSERT INTO im_categories VALUES (2420,'upload','This is the value of im_task_actions.action_type_id when a user uploads a task file.','Intranet Task Action Type','category','t','f');
INSERT INTO im_categories VALUES (2421,'download','','Intranet Task Action Type','category','t','f');



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
INSERT INTO im_categories VALUES (251,'es_ES','Castilian Spanish','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (252,'es_LA','Latin Americal Spanish','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (253,'es_US','US Spanish','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (254,'es_MX','Mexican Spanish','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (261,'en','English','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (262,'en_US','US English','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (263,'en_UK','UK English','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (271,'fr','French','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (272,'fr_FR','French French','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (273,'fr_BE','Belgian French','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (274,'fr_CH','Swiss French','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (281,'de','German','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (282,'de_DE','German German','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (283,'de_CH','Swiss German','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (290,'none','No Language','Intranet Translation Language','category','t','f');





-- Unit or Mesurement
INSERT INTO im_categories VALUES (320,'Hour','','Intranet Translation UoM','category','t','f');
INSERT INTO im_categories VALUES (321,'Day','','Intranet Translation UoM','category','t','f');
-- INSERT INTO im_categories VALUES (322,'Week','','Intranet Translation UoM','category','t','f');
INSERT INTO im_categories VALUES (323,'Page','','Intranet Translation UoM','category','t','f');
INSERT INTO im_categories VALUES (324,'S-Word','','Intranet Translation UoM','category','t','f');
INSERT INTO im_categories VALUES (325,'T-Word','','Intranet Translation UoM','category','t','f');
INSERT INTO im_categories VALUES (326,'S-Line','','Intranet Translation UoM','category','t','f');
INSERT INTO im_categories VALUES (327,'T-Line','','Intranet Translation UoM','category','t','f');

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


-- Employee/Freelance Pipeline Status
insert into im_categories values ('450',  'Potential',  '',  'Intranet Employee Pipeline State','category','t','f');
insert into im_categories values ('451',  'Received Translation Test',  '',  'Intranet Employee Pipeline State','category','t','f');
insert into im_categories values ('452',  'Failed Translation Test',  '',  'Intranet Employee Pipeline State','category','t','f');
insert into im_categories values ('453',  'Aproved Translation Test',  '',  'Intranet Employee Pipeline State','category','t','f');
insert into im_categories values ('454',  'Active',  '',  'Intranet Employee Pipeline State','category','t','f');
insert into im_categories values ('455',  'Past',  '',  'Intranet Employee Pipeline State','category','t','f');
insert into im_categories values ('456',  'Deleted',  '',  'Intranet Employee Pipeline State','category','t','f');

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


prompt Create the "Tigerpond" customer
DECLARE
    v_office_id		integer;
    v_customer_id	integer;
BEGIN
    -- First setup the main office
    v_office_id := im_office.new(
        object_type     => 'im_office',
        office_name     => 'Tigerpond Main Office',
        office_path     => 'tigerpond_main_office'
    );

    v_customer_id := im_customer.new(
	object_type	=> 'im_customer',
	customer_name	=> 'Tigerpond',
	customer_path	=> 'tigerpond',
	main_office_id	=> v_office_id,
	-- Translation Agency
	customer_type_id => 54,
	-- 'Active' status
	customer_status_id => 46
    );
end;
/
commit;



prompt Create a "Tigerpond" project
declare
	v_project_id		integer;
	v_customer_id		integer;
	v_rel_id		integer;
	v_user_id		integer;
begin
	select customer_id
	into v_customer_id
	from im_customers
	where customer_path = 'tigerpond';

	v_project_id := im_project.new(
		object_type	=> 'im_project',
		project_name	=> 'Large Translation Project',
		project_nr	=> '2004_0001',
		project_path	=> '2004_0001',
		customer_id	=> v_customer_id,
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
