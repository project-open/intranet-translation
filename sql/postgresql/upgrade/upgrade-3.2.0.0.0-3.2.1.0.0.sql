-- upgrade-3.2.0.0.0-3.2.1.0.0.sql

SELECT acs_log__debug('/packages/intranet-translation/sql/postgresql/upgrade/upgrade-3.2.0.0.0-3.2.1.0.0.sql','');

\i ../../../../intranet-core/sql/postgresql/upgrade/upgrade-3.0.0.0.first.sql


-----------------------------------------------------------
-- Copy 'Intranet Project Type' Category into the range
-- of 4000-4099
-----------------------------------------------------------

-- 2006-05-28: Not possible: The static WF uses the hard
-- coded Intranet Project Type values...

-- Set the counter for the next categories to above the fixed
-- category range.


-----------------------------------------------------------
-- Add a "tm_type_id" field to im_trans_tasks and 
-- define categories

-- 4100-4199    Intranet Trans TM Type


SELECT im_category_new (4200,'External', 'Intranet TM Integration Type');
SELECT im_category_new (4202,'Ophelia', 'Intranet TM Integration Type');
SELECT im_category_new (4204,'None', 'Intranet TM Integration Type');


-- No default - default should be handled by TCL
-- alter table im_trans_tasks alter column tm_type_id 
-- set default 4100;

create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select  count(*) into v_count from user_tab_columns
	where   lower(table_name) = ''im_trans_tasks''
		and lower(column_name) = ''tm_integration_type_id'';
	if v_count = 1 then return 0; end if;

	alter table im_trans_tasks
	add tm_integration_type_id integer references im_categories;

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();













