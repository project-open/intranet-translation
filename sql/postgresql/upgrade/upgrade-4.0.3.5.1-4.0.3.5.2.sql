-- upgrade-4.0.3.5.1-4.0.3.5.2.sql

SELECT acs_log__debug('/packages/intranet-translation/sql/postgresql/upgrade/upgrade-4.0.3.5.1-4.0.3.5.2.sql','');

create or replace function inline_0 ()
returns integer as $body$
declare
        v_count integer;
begin
        -- Locked
        select count(*) into v_count from user_tab_columns
        where lower(table_name) = 'im_trans_trados_matrix' and lower(column_name) = 'locked';
        IF v_count = 0 THEN
	   alter table im_trans_trados_matrix add column locked numeric(12,4);
        END IF;

        -- crossfilerepeated
        select count(*) into v_count from user_tab_columns
        where lower(table_name) = 'im_trans_tasks' and lower(column_name) = 'locked';
        IF v_count = 0 THEN
	   alter table im_trans_tasks add column locked numeric(12,0);
        END IF;

        return 0;

end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as $body$
declare
        v_count integer;
begin
        -- Locked
        select count(*) into v_count from im_view_columns where column_id = 9088;

        IF v_count = 0 THEN
	   insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
	   values (9088,90,NULL,'Lck','$locked','','',160,'im_permission $user_id view_trans_task_matrix');
	ELSE 
	     RAISE NOTICE '/intranet-translation/sql/postgresql/upgrade/upgrade-4.0.3.5.1-4.0.3.5.2.sql: Not able to create column "Locked"';
	END IF;
	
        return 0;

end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




-- set default for locked for "Default Freelancer Provider 
create or replace function inline_0 ()
returns integer as $body$
declare
        v_company_id integer;
begin
	select company_id into v_company_id from im_companies where company_type_id = 53 and company_path = 'default_freelance' LIMIT 1; 
	update im_trans_trados_matrix set locked = 0 where object_id = v_company_id;

        return 0;

end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

-- set default for locked for "Internal Company"
create or replace function inline_0 ()
returns integer as $body$
declare
        v_company_id integer;
begin
        select company_id into v_company_id from im_companies where company_type_id = 53 and company_status_id = 46 LIMIT 1;
        update im_trans_trados_matrix set locked = 1 where object_id = v_company_id;
        return 0;

end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

-- set default values for "Freelance Provider" 
update im_trans_trados_matrix set locked = 0 where object_id in (select company_id from im_companies where company_type_id = 58);

-- set set default for all other Customer Companies 
update im_trans_trados_matrix set locked = 1 where object_id not in (select company_id from im_companies where company_type_id = 58);





