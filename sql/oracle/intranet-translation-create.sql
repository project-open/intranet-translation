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



-- insert component into Project/View.tcl
-- 
insert into im_component_plugins (
        plugin_id,
        sort_order,
        page_url,
        bay_name,
        component_tcl
)values (
	im_component_plugins_seq.nextval,
	2,
	'/intranet/projects/view',
	'bottom',
	'im_task_component \
		$user_id \
		$project_id \
		$user_admin_p \
		$user_is_employee_p \
		$return_url'
);

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
        bay_name =>     'bottom',
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
        bay_name =>     'bottom',
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

