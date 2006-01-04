
-- -------------------------------------------------------------------
-- Make the size column only visible for users with privilege
-- view_trans_proj_detail

delete from im_view_columns where column_id = 2023;

insert into im_view_columns (
	column_id, view_id, 
	group_id, column_name, 
	column_render_tcl, extra_select, 
	extra_where, sort_order, 
	visible_for
) values (
	2023,20,
	NULL,'Size',
	'$trans_size','',
	'',90,
	'im_permission $user_id view_trans_proj_detail'
);


