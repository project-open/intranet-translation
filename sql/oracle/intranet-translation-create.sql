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

create sequence im_tasks_seq start with 1;
create table im_tasks (
	task_id			integer primary key,
	project_id		not null references im_projects,
	target_language_id	references im_categories,
				-- task_name will take a filename for the
				-- language processing application
	task_name		varchar(200),
	task_type_id		not null references im_categories,
	task_status_id		not null references im_categories,
	description		varchar(4000),
	source_language_id	references im_categories,
	-- fees: N units of "UoM" (Unit of Measurement)
				-- raw units to be delivered to the client
	task_units		number(12,1),
				-- sometimes, not all units can be billed...
	billable_units		number(12,1),
				-- UoM=Unit of Measure (hours, words, ...)
	task_uom_id		not null references im_categories,
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
	action_type_id		references im_categories,
	user_id			not null references users,
	task_id			not null references im_tasks,
	action_date		date,
	old_status_id		references im_categories,
	new_status_id		references im_categories
);


-- define into which language we have to translate a certain project.
create table im_target_languages (
				-- can refer to several target objects
	on_what_id		not null references im_projects,
				-- allow to be used on both im_projects 
				-- and im_tasks
	on_which_table		varchar(50),
	language_id		not null references im_categories,
	primary key (on_what_id, on_which_table, language_id)
);


create or replace view im_task_status as 
select category_id as task_status_id, category as task_status
from im_categories 
where category_type = 'Intranet Translation Task Status';


-- insert into im_categories
delete from im_categories where category_id >= 2420 and category_id < 2430;
INSERT INTO im_categories VALUES (2420,'upload','This is the value of im_task_actions.action_type_id when a user uploads a task file.','Intranet Task Action Type','category','t','f');
INSERT INTO im_categories VALUES (2421,'download','','Intranet Task Action Type','category','t','f');


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
    acs_privilege.create_privilege('view_trans_tasks','View Trans Tasks','View Trans Tasks');
end;
/
begin
    im_priv_create('view_trans_tasks', 'Employees');
    im_priv_create('view_trans_tasks', 'Project Managers');
    im_priv_create('view_trans_tasks', 'Senior Managers');
end;
/


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

insert into im_categories values (97,  'Translation Project',  
'',  'Intranet Project Type','category','t','f');


insert into im_category_hierarchy values (97,87);
insert into im_category_hierarchy values (97,88);
insert into im_category_hierarchy values (97,89);
insert into im_category_hierarchy values (97,90);
insert into im_category_hierarchy values (97,91);
insert into im_category_hierarchy values (97,92);
insert into im_category_hierarchy values (97,94);
insert into im_category_hierarchy values (97,95);
insert into im_category_hierarchy values (97,96);


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

