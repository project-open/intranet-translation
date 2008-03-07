-- upgrade-3.3.1.0.0-3.3.1.1.0.sql


-- Allow translation tasks to be checked/unchecked all together

delete from im_view_columns where column_id = 9021;

insert into im_view_columns (
	column_id, view_id, group_id, column_name, 
	column_render_tcl, extra_select, extra_where, 
	sort_order, visible_for
) values (
	9021,90,NULL,
	'<input type=checkbox name=_dummy onclick=\\"acs_ListCheckAll(''task'',this.checked)\\">',
	'$del_checkbox','','',
	21,'expr $project_write'
);


-- Add a new column to im_task_actions to record the file
-- that the translator has actually uploaded.
--
alter table im_task_actions add column upload_file varchar(1000);


-- Make column a timestamp in order to record the delivery time
-- of freelancers
alter table im_task_actions alter column action_date type timestamptz;



-- Show the up-/download details for a project
--
select im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Project Translation Task Action Log',	-- plugin_name
	'intranet-translation',		-- package_name
	'bottom',			-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	50,				-- sort_order
	'im_trans_task_action_list_component -project_id $project_id'
);


-- insert into im_view_columns (
-- 	column_id, view_id, group_id, column_name, 
-- 	column_render_tcl, extra_select, extra_where, 
-- 	sort_order, visible_for
-- ) values (
-- 	9021,90,NULL,'[im_gif delete "Delete the Task"]',
-- 	'$del_checkbox','','',
-- 	21,'expr $project_write'
-- );

