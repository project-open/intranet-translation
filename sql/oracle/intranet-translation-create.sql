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
alter table im_projects add	customer_contact_id	references users;
alter table im_projects add	source_language_id	references categories;
alter table im_projects add	subject_area_id		references categories;
alter table im_projects add	expected_quality_id	references categories;
alter table im_projects add	final_customer		varchar(50);


-----------------------------------------------------------
-- Tasks
--
-- - Every project can have any number of "Tasks".
-- - Each task represents a work unit that can be billed
--   independently and that will appear as a line in
--   the final invoice to be printed.

create sequence im_tasks_seq start with 1;
create table im_tasks (
	task_id			integer primary key,
	project_id		not null references im_projects,
	target_language_id	references categories,
				-- task_name will take a filename for the
				-- language processing application
	task_name		varchar(200),
	task_type_id		not null references categories,
	task_status_id		not null references categories,
	description		varchar(4000),
	source_language_id	references categories,
	-- fees: N units of "UoM" (Unit of Measurement)
				-- raw units to be delivered to the client
	task_units		number(12,1),
				-- sometimes, not all units can be billed...
	billable_units		number(12,1),
				-- UoM=Unit of Measure (hours, words, ...)
	task_uom_id		not null references categories,
	--  added later to avoid a cyclical reference:
	--  invoice_id			integer references im_invoices,
	-- SLS user fields to determine the work effort
	match100		number(12,0),
	match95			number(12,0),
	match85			number(12,0),
	match0			number(12,0),
	-- SLS Workflow
	trans_id		references users,
	edit_id			references users,
	proof_id		references users,
	other_id		references users
);
-- make sure a task doesn't get defined twice for a project:
create unique index im_tasks_name_project_idx on im_tasks 
(task_name, project_id, target_language_id);


-- actions that have occured around im_tasks: upload, download, ...
create sequence im_task_actions_seq start with 1;
create table im_task_actions (
	action_id		integer primary key,
	action_type_id		references categories,
	user_id			not null references users,
	task_id			not null references im_tasks,
	action_date		date,
	old_status_id		references categories,
	new_status_id		references categories
);


-- define into which language we have to translate a certain project.
create table im_target_languages (
				-- can refer to several target objects
	on_what_id		not null references im_projects,
				-- allow to be used on both im_projects 
				-- and im_tasks
	on_which_table		varchar(50),
	language_id		not null references categories,
	primary key (on_what_id, on_which_table, language_id)
);


create or replace view im_task_status as 
select category_id as task_status_id, category as task_status
from categories 
where category_type = 'Task Status';


-- insert into categories
delete from categories where category_id >= 2420 and category_id < 2430;
INSERT INTO categories VALUES (2420,'upload','This is the value of im_task_actions.action_type_id when a user uploads a task file.','Intranet Task Action Type',0,'f','');
INSERT INTO categories VALUES (2421,'download','','Intranet Task Action Type',0,'f','');


-- Show the task component in project page
--
declare
    v_plugin            integer;
begin
    v_plugin := im_component_plugin.new (
        plugin_id =>    null,
        object_type =>  'im_component_plugin',
        creation_date => sysdate,
        creation_user => 0,
        creation_ip =>  null,
        context_id =>   null,

	package_name =>	'intranet-translation',
        page_url =>     '/intranet/projects/view',
        location =>     'bottom',
        sort_order =>   10,
        component_tcl => 

	'im_task_status_component \
		$user_id \
		$project_id \
		$user_admin_p \
		$user_is_employee_p \
		$return_url'
    );

-- Show the upload task component in project page

    v_plugin := im_component_plugin.new (
        plugin_id =>    null,
        object_type =>  'im_component_plugin',
        creation_date => sysdate,
        creation_user => 0,
        creation_ip =>  null,
        context_id =>   null,

	package_name =>	'intranet-translation',
        page_url =>     '/intranet/projects/view',
        location =>     'bottom',
        sort_order =>   20,
        component_tcl => 

	'im_task_error_component \
		$user_id \
		$project_id \
		$user_admin_p \
		$user_is_employee_p \
		$return_url \
		$missing_task_list'
    );
end;
/



insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '86',  'Trans + Edit',  '',  'Intranet Project Type');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '87',  'Edit Only',  '',  'Intranet Project Type');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '88',  'Trans + Edit + Proof',  '',  'Intranet Project Type');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '89',  'Linguistic Validation',  '',  'Intranet Project Type');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '90',  'Localization',  '',  'Intranet Project Type');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '92',  'Technology',  '',  'Intranet Project Type');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '94',  'Trans + Int. Spotcheck',  '',  'Intranet Project Type');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '95',  'Proof Only',  '',  'Intranet Project Type');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '96',  'Glossary Compilation',  '',  'Intranet Project Type');


-- Intranet Quality
INSERT INTO categories VALUES (110,'Premium Quality','Premium Quality','Intranet Quality',1,'f','');
INSERT INTO categories VALUES (111,'High Quality','High Quality','Intranet Quality',1,'f','');
INSERT INTO categories VALUES (112,'Average Quality','Average Quality','Intranet Quality',1,'f','');
INSERT INTO categories VALUES (113,'Draft Quality','Draft Quality','Intranet Quality',1,'f','');






-- Setup the most frequently used language (lang, sort_key, name)
INSERT INTO categories VALUES (250,'es','Spanish','Intranet Translation Language',1,'f','');
INSERT INTO categories VALUES (251,'es_ES','Castilian Spanish','Intranet Translation Language',1,'f','');
INSERT INTO categories VALUES (252,'es_LA','Latin Americal Spanish','Intranet Translation Language',1,'f','');
INSERT INTO categories VALUES (253,'es_US','US Spanish','Intranet Translation Language',1,'f','');
INSERT INTO categories VALUES (254,'es_MX','Mexican Spanish','Intranet Translation Language',1,'f','');
INSERT INTO categories VALUES (261,'en','English','Intranet Translation Language',1,'f','');
INSERT INTO categories VALUES (262,'en_US','US English','Intranet Translation Language',1,'f','');
INSERT INTO categories VALUES (263,'en_UK','UK English','Intranet Translation Language',1,'f','');
INSERT INTO categories VALUES (271,'fr','French','Intranet Translation Language',1,'f','');
INSERT INTO categories VALUES (272,'fr_FR','French French','Intranet Translation Language',1,'f','');
INSERT INTO categories VALUES (273,'fr_BE','Belgian French','Intranet Translation Language',1,'f','');
INSERT INTO categories VALUES (274,'fr_CH','Swiss French','Intranet Translation Language',1,'f','');
INSERT INTO categories VALUES (281,'de','German','Intranet Translation Language',1,'f','');
INSERT INTO categories VALUES (282,'de_DE','German German','Intranet Translation Language',1,'f','');
INSERT INTO categories VALUES (283,'de_CH','Swiss German','Intranet Translation Language',1,'f','');
INSERT INTO categories VALUES (290,'none','No Language','Intranet Translation Language',1,'f','');





-- Unit or Mesurement
INSERT INTO categories VALUES (320,'Hour','','Intranet Translation UoM',1,'f','');
INSERT INTO categories VALUES (321,'Day','','Intranet Translation UoM',1,'f','');
-- INSERT INTO categories VALUES (322,'Week','','Intranet Translation UoM',1,'f','');
INSERT INTO categories VALUES (323,'Page','','Intranet Translation UoM',1,'f','');
INSERT INTO categories VALUES (324,'S-Word','','Intranet Translation UoM',1,'f','');
INSERT INTO categories VALUES (325,'T-Word','','Intranet Translation UoM',1,'f','');
INSERT INTO categories VALUES (326,'S-Line','','Intranet Translation UoM',1,'f','');
INSERT INTO categories VALUES (327,'T-Line','','Intranet Translation UoM',1,'f','');

-- Task Status
INSERT INTO categories VALUES (340,'Created','','Intranet Translation Task Status',1,'f','');
INSERT INTO categories VALUES (342,'for Trans','','Intranet Translation Task Status',1,'f','');
INSERT INTO categories VALUES (344,'Trans-ing','','Intranet Translation Task Status',1,'f','');
INSERT INTO categories VALUES (346,'for Edit','','Intranet Translation Task Status',1,'f','');
INSERT INTO categories VALUES (348,'Editing','','Intranet Translation Task Status',1,'f','');
INSERT INTO categories VALUES (350,'for Proof','','Intranet Translation Task Status',1,'f','');
INSERT INTO categories VALUES (352,'Proofing','','Intranet Translation Task Status',1,'f','');
INSERT INTO categories VALUES (354,'for QCing','','Intranet Translation Task Status',1,'f','');
INSERT INTO categories VALUES (356,'QCing','','Intranet Translation Task Status',1,'f','');
INSERT INTO categories VALUES (358,'for Deliv','','Intranet Translation Task Status',1,'f','');
INSERT INTO categories VALUES (360,'Delivered','','Intranet Translation Task Status',1,'f','');
INSERT INTO categories VALUES (365,'Invoiced','','Intranet Translation Task Status',1,'f','');
INSERT INTO categories VALUES (370,'Payed','','Intranet Translation Task Status',1,'f','');
INSERT INTO categories VALUES (372,'Deleted','','Intranet Translation Task Status',1,'f','');
-- reserved until 399


-- Employee/Freelance Pipeline Status
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '450',  'Potential',  '',  'Intranet Employee Pipeline State');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '451',  'Received Translation Test',  '',  'Intranet Employee Pipeline State');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '452',  'Failed Translation Test',  '',  'Intranet Employee Pipeline State');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '453',  'Aproved Translation Test',  '',  'Intranet Employee Pipeline State');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '454',  'Active',  '',  'Intranet Employee Pipeline State');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('0',  '',  'f',  '455',  'Past',  '',  'Intranet Employee Pipeline State');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('0',  '',  'f',  '456',  'Deleted',  '',  'Intranet Employee Pipeline State');

-- Subject Areas
INSERT INTO categories VALUES (500,'Bio','','Intranet Translation Subject Area',1,'f','');
INSERT INTO categories VALUES (505,'Biz','','Intranet Translation Subject Area',1,'f','');
INSERT INTO categories VALUES (510,'Com','','Intranet Translation Subject Area',1,'f','');
INSERT INTO categories VALUES (515,'Eco','','Intranet Translation Subject Area',1,'f','');
INSERT INTO categories VALUES (520,'Gen','','Intranet Translation Subject Area',1,'f','');
INSERT INTO categories VALUES (525,'Law','','Intranet Translation Subject Area',1,'f','');
INSERT INTO categories VALUES (530,'Lit','','Intranet Translation Subject Area',1,'f','');
INSERT INTO categories VALUES (535,'Loc','','Intranet Translation Subject Area',1,'f','');
INSERT INTO categories VALUES (540,'Mkt','','Intranet Translation Subject Area',1,'f','');
INSERT INTO categories VALUES (545,'Med','','Intranet Translation Subject Area',1,'f','');
INSERT INTO categories VALUES (550,'Tec','','Intranet Translation Subject Area',1,'f','');
INSERT INTO categories VALUES (555,'Tec-Auto','','Intranet Translation Subject Area',1,'f','');
INSERT INTO categories VALUES (560,'Tec-Telecos','','Intranet Translation Subject Area',1,'f','');
INSERT INTO categories VALUES (565,'Tec-Gen','','Intranet Translation Subject Area',1,'f','');
INSERT INTO categories VALUES (570,'Tec-Mech. eng','','Intranet Translation Subject Area',1,'f','');
-- reserved until 599

