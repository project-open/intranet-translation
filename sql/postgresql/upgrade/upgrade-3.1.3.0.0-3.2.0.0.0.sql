-- upgrade-3.1.3.0.0-3.2.0.0.0.sql

SELECT acs_log__debug('/packages/intranet-translation/sql/postgresql/upgrade/upgrade-3.1.3.0.0-3.2.0.0.0.sql','');


-----------------------------------------------------------
-- Convert im_trans_task to an object
-----------------------------------------------------------

select acs_object_type__create_type (
	'im_trans_task',		-- object_type
	'Translation Task',		-- pretty_name
	'Translation Tasks',		-- pretty_plural
	'acs_object',			-- supertype
	'im_trans_tasks',		-- table_name
	'task_id',			-- id_column
	'im_trans_task',		-- package_name
	'f',				-- abstract_p
	null,				-- type_extension_table
	'im_trans_task__name'   	-- name_method
);


-- Create entries for URL to allow editing TransTasks in
-- list pages with mixed object types
--
delete from im_biz_object_urls where object_type = 'im_trans_task';
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_trans_task','view','/intranet-translation/view?task_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_trans_task','edit','/intranet-translation/new?task_id=');



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
	v_task_id	alias for $1;
BEGIN
	-- Erase all the priviledges
	delete from acs_permissions
	where object_id = v_task_id;

	-- Erase task_actions:
	delete from im_task_actions
	where task_id = v_task_id;
	
	-- Erase the im_trans_tasks item associated with the id
	delete from im_trans_tasks
	where task_id = v_task_id;

	PERFORM acs_object__delete(v_task_id);

	return 0;
end;' language 'plpgsql';


create or replace function im_trans_task__name (integer) returns varchar as '
DECLARE
	v_task_id	alias for $1;
	v_name	varchar;
BEGIN
	select  task_name into v_name from im_trans_tasks
	where   task_id = v_task_id;

	return v_name;
end;' language 'plpgsql';




-----------------------------------------------------------
-- Prepare converting im_trans_task to object
-----------------------------------------------------------


-- -----------------------------------------------------
-- Remove the RI constraint from translation quality
-- if it exist
--
create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select  count(*) into v_count from user_tab_columns
	where   lower(table_name) = ''im_trans_quality_reports'';
	if v_count = 0 then return 0; end if;

	alter table im_trans_quality_reports drop constraint im_transq_task_fk;

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


-- -----------------------------------------------------
-- Remove the RI constraint from im_trans_task_actions
--
create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select  count(*) into v_count from pg_constraint
	where   lower(conname) = ''im_task_action_task_fk'';
	if v_count = 0 then return 0; end if;

	alter table im_task_actions drop constraint im_task_action_task_fk;

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select  count(*) into v_count from pg_constraint
	where   lower(conname) = ''im_trans_task_id_fk'';
	if v_count = 0 then return 0; end if;

	alter table im_trans_tasks drop constraint im_trans_task_id_fk;

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


-----------------------------------------------------------
-- Actually convert im_trans_task to object
--
create or replace function im_trans_tasks2objects ()
returns integer as '
DECLARE
	row	RECORD;
	v_oid	integer;

	v_quality_count		integer;
BEGIN
	select  count(*) into v_quality_count from user_tab_columns
	where   lower(table_name) = ''im_trans_quality_reports'';

	for row in
		select	*
		from	im_trans_tasks
		where	task_id not in (
				select	object_id
				from	acs_objects
				where	object_type = ''im_trans_task''
			)
		order by task_id
	loop

		-- Create a new object for the task
		v_oid := acs_object__new (
			null,''im_trans_task'',now(),
			624,''0.0.0.0'',null
		);
		RAISE NOTICE ''im_trans_task: task_id=%, new oid=%'', row.task_id, v_oid;
	
		-- Update Task Actions
		update	im_task_actions
		set	task_id = v_oid
		where	task_id = row.task_id;
	
		-- Update Translation Quality
		if v_quality_count > 0 then
			update	im_trans_quality_reports
			set	task_id = v_oid
			where	task_id = row.task_id;
		end if;
	
		-- Finally update the TransTask table itself
		update	im_trans_tasks
		set	task_id = v_oid
		where	task_id = row.task_id;

	end loop;
	return 0;
END;' language 'plpgsql';
select im_trans_tasks2objects ();
drop function im_trans_tasks2objects ();


--------------------------------------------
-- Add the constraint again.
-- Now im_trans_task.task_id is an object.

-- im_trans_tasks now need to reference objects
alter table im_trans_tasks
add constraint im_trans_task_id_fk foreign key (task_id) references acs_objects;


alter table im_task_actions 
add constraint im_task_action_task_fk foreign key (task_id) references im_trans_tasks;


-- Add constraint only if table exists
--
create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select  count(*) into v_count from user_tab_columns
	where   lower(table_name) = ''im_trans_quality_reports'';
	if v_count = 0 then return 0; end if;

	alter table im_trans_quality_reports
	add constraint im_transq_task_fk
	foreign key (task_id) references im_trans_tasks;

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


-- No need anymore for the task sequence. Do this
-- to make sure that there are no further tasks
-- being generated somewhere in the system.
--
create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select  count(*) into v_count from pg_class
	where	lower(relname) = ''im_trans_tasks_seq'';
	if v_count = 0 then return 0; end if;

	drop sequence im_trans_tasks_seq;

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-----------------------------------------------------------
-- Clone the translation tasks of a project to another
-- project
-----------------------------------------------------------


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


