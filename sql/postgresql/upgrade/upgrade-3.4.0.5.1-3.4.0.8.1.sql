--  upgrade-3.4.0.5.1-3.4.0.8.1.sql

SELECT acs_log__debug('/packages/intranet-translation/sql/postgresql/upgrade/upgrade-3.4.0.5.1-3.4.0.8.1.sql','');

-- Create a  material for translation tasks

create or replace function inline_0 ()
returns integer as '
declare
        v_count         integer;
begin
        select  count(*) into v_count from im_materials where material_name = ''Translation Task'';
        if v_count = 0 then

	perform im_material__new (
        	 acs_object_id_seq.nextval::integer, ''im_material'', now(), null, ''0.0.0.0'', null,
	        ''Translation Task'', ''tr_task'', 9000, 9100, 320, ''Translation Task''
	);
        end if;

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-- Allow translation tasks to be checked/unchecked all together
--
delete from im_view_columns where column_id = 9021;
insert into im_view_columns (
        column_id, view_id, group_id, column_name,
        column_render_tcl, extra_select, extra_where,
        sort_order, visible_for
) values (
        9021,90,NULL,
        '<input type=checkbox name=_dummy onclick=acs_ListCheckAll(''task'',this.checked)>',
        '$del_checkbox','','',
        0,'expr $project_write'
);

