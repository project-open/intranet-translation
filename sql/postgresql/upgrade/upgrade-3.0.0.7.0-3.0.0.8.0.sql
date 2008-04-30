-- upgrade-3.0.0.7.0-3.0.0.8.0.sql

SELECT acs_log__debug('/packages/intranet-translation/sql/postgresql/upgrade/upgrade-3.0.0.7.0-3.0.0.8.0.sql','');



-- -------------------------------------------------------------------
-- Table for calculating Trans Project progress
-- -------------------------------------------------------------------

create table im_trans_task_progress (
	task_type_id		integer not null
				constraint im_trans_task_progres_type_fk
				references im_categories,
	task_status_id		integer not null
				constraint im_trans_task_progres_status_fk
				references im_categories,
	percent_completed	numeric(6,2)
);

create unique index im_trans_task_progress_idx 
on im_trans_task_progress
(task_type_id, task_status_id);

-- Task Status
--
-- 340	Created
-- 342 	for Trans
-- 344 	Trans-ing
-- 346 	for Edit
-- 348 	Editing
-- 350 	for Proof
-- 352 	Proofing
-- 354 	for QCing
-- 356 	QCing
-- 358 	for Deliv
-- 360 	Delivered
-- 365 	Invoiced
-- 370 	Payed
-- 372 	Deleted

-- Task Types
--
-- 85  	Unknown  		
-- 86 	Other 		
-- 87 	Trans + Edit 	Translation Project 	
-- 88 	Edit Only 	Translation Project 	
-- 89 	Trans + Edit + Proof 	Translation Project 	
-- 90 	Linguistic Validation 	Translation Project 	
-- 91 	Localization 	Consulting Project 
-- 92 	Technology 	Translation Project 	
-- 93 	Trans Only 	Translation Project 	
-- 94 	Trans + Int. Spotcheck 	Translation Project 	
-- 95 	Proof Only 	Translation Project 	
-- 96 	Glossary Compilation 	Translation Project 	


-- values for 340 and 342 are 0 for all task types
-- values for 354, 356, 358, 360, 365, 370, 372 are always 100%

-- Trans + Edit
insert into im_trans_task_progress values (87, 344, 40);
insert into im_trans_task_progress values (87, 346, 80);
insert into im_trans_task_progress values (87, 348, 90);
insert into im_trans_task_progress values (87, 350, 100);
insert into im_trans_task_progress values (87, 352, 100);

-- Edit
insert into im_trans_task_progress values (88, 344, 0);
insert into im_trans_task_progress values (88, 346, 0);
insert into im_trans_task_progress values (88, 348, 50);
insert into im_trans_task_progress values (88, 350, 100);
insert into im_trans_task_progress values (88, 352, 100);

-- Trans + Edit + Proof
insert into im_trans_task_progress values (89, 344, 35);
insert into im_trans_task_progress values (89, 346, 70);
insert into im_trans_task_progress values (89, 348, 80);
insert into im_trans_task_progress values (89, 350, 90);
insert into im_trans_task_progress values (89, 352, 95);

-- Trans Only
insert into im_trans_task_progress values (93, 344, 50);
insert into im_trans_task_progress values (93, 346, 100);
insert into im_trans_task_progress values (93, 348, 100);
insert into im_trans_task_progress values (93, 350, 100);
insert into im_trans_task_progress values (93, 352, 100);

-- Trans + Intl. Spotcheck
insert into im_trans_task_progress values (94, 344, 44);
insert into im_trans_task_progress values (94, 346, 80);
insert into im_trans_task_progress values (94, 348, 90);
insert into im_trans_task_progress values (94, 350, 100);
insert into im_trans_task_progress values (94, 352, 100);

-- Proof
insert into im_trans_task_progress values (95, 344, 0);
insert into im_trans_task_progress values (95, 346, 0);
insert into im_trans_task_progress values (95, 348, 0);
insert into im_trans_task_progress values (95, 350, 0);
insert into im_trans_task_progress values (95, 352, 50);


-- values for 340 and 342 are 0 for all task types
insert into im_trans_task_progress values (85, 340, 0);
insert into im_trans_task_progress values (86, 340, 0);
insert into im_trans_task_progress values (87, 340, 0);
insert into im_trans_task_progress values (88, 340, 0);
insert into im_trans_task_progress values (89, 340, 0);
insert into im_trans_task_progress values (90, 340, 0);
insert into im_trans_task_progress values (91, 340, 0);
insert into im_trans_task_progress values (92, 340, 0);
insert into im_trans_task_progress values (93, 340, 0);
insert into im_trans_task_progress values (94, 340, 0);
insert into im_trans_task_progress values (95, 340, 0);
insert into im_trans_task_progress values (96, 340, 0);

-- values for 340 and 342 are 0 for all task types
insert into im_trans_task_progress values (85, 342, 0);
insert into im_trans_task_progress values (86, 342, 0);
insert into im_trans_task_progress values (87, 342, 0);
insert into im_trans_task_progress values (88, 342, 0);
insert into im_trans_task_progress values (89, 342, 0);
insert into im_trans_task_progress values (90, 342, 0);
insert into im_trans_task_progress values (91, 342, 0);
insert into im_trans_task_progress values (92, 342, 0);
insert into im_trans_task_progress values (93, 342, 0);
insert into im_trans_task_progress values (94, 342, 0);
insert into im_trans_task_progress values (95, 342, 0);
insert into im_trans_task_progress values (96, 342, 0);

-- values for 354, 356, 358, 360, 365, 370, 372 are always 100%
insert into im_trans_task_progress values (85, 354, 100);
insert into im_trans_task_progress values (86, 354, 100);
insert into im_trans_task_progress values (87, 354, 100);
insert into im_trans_task_progress values (88, 354, 100);
insert into im_trans_task_progress values (89, 354, 100);
insert into im_trans_task_progress values (90, 354, 100);
insert into im_trans_task_progress values (91, 354, 100);
insert into im_trans_task_progress values (92, 354, 100);
insert into im_trans_task_progress values (93, 354, 100);
insert into im_trans_task_progress values (94, 354, 100);
insert into im_trans_task_progress values (95, 354, 100);
insert into im_trans_task_progress values (96, 354, 100);

-- values for 354, 356, 358, 360, 365, 370, 372 are always 100%
insert into im_trans_task_progress values (85, 356, 100);
insert into im_trans_task_progress values (86, 356, 100);
insert into im_trans_task_progress values (87, 356, 100);
insert into im_trans_task_progress values (88, 356, 100);
insert into im_trans_task_progress values (89, 356, 100);
insert into im_trans_task_progress values (90, 356, 100);
insert into im_trans_task_progress values (91, 356, 100);
insert into im_trans_task_progress values (92, 356, 100);
insert into im_trans_task_progress values (93, 356, 100);
insert into im_trans_task_progress values (94, 356, 100);
insert into im_trans_task_progress values (95, 356, 100);
insert into im_trans_task_progress values (96, 356, 100);

-- values for 354, 356, 358, 360, 365, 370, 372 are always 100%
insert into im_trans_task_progress values (85, 358, 100);
insert into im_trans_task_progress values (86, 358, 100);
insert into im_trans_task_progress values (87, 358, 100);
insert into im_trans_task_progress values (88, 358, 100);
insert into im_trans_task_progress values (89, 358, 100);
insert into im_trans_task_progress values (90, 358, 100);
insert into im_trans_task_progress values (91, 358, 100);
insert into im_trans_task_progress values (92, 358, 100);
insert into im_trans_task_progress values (93, 358, 100);
insert into im_trans_task_progress values (94, 358, 100);
insert into im_trans_task_progress values (95, 358, 100);
insert into im_trans_task_progress values (96, 358, 100);

-- values for 354, 356, 358, 360, 365, 370, 372 are always 100%
insert into im_trans_task_progress values (85, 360, 100);
insert into im_trans_task_progress values (86, 360, 100);
insert into im_trans_task_progress values (87, 360, 100);
insert into im_trans_task_progress values (88, 360, 100);
insert into im_trans_task_progress values (89, 360, 100);
insert into im_trans_task_progress values (90, 360, 100);
insert into im_trans_task_progress values (91, 360, 100);
insert into im_trans_task_progress values (92, 360, 100);
insert into im_trans_task_progress values (93, 360, 100);
insert into im_trans_task_progress values (94, 360, 100);
insert into im_trans_task_progress values (95, 360, 100);
insert into im_trans_task_progress values (96, 360, 100);

-- values for 354, 356, 358, 360, 365, 370, 372 are always 100%
insert into im_trans_task_progress values (85, 365, 100);
insert into im_trans_task_progress values (86, 365, 100);
insert into im_trans_task_progress values (87, 365, 100);
insert into im_trans_task_progress values (88, 365, 100);
insert into im_trans_task_progress values (89, 365, 100);
insert into im_trans_task_progress values (90, 365, 100);
insert into im_trans_task_progress values (91, 365, 100);
insert into im_trans_task_progress values (92, 365, 100);
insert into im_trans_task_progress values (93, 365, 100);
insert into im_trans_task_progress values (94, 365, 100);
insert into im_trans_task_progress values (95, 365, 100);
insert into im_trans_task_progress values (96, 365, 100);

-- values for 354, 356, 358, 360, 365, 370, 372 are always 100%
insert into im_trans_task_progress values (85, 370, 100);
insert into im_trans_task_progress values (86, 370, 100);
insert into im_trans_task_progress values (87, 370, 100);
insert into im_trans_task_progress values (88, 370, 100);
insert into im_trans_task_progress values (89, 370, 100);
insert into im_trans_task_progress values (90, 370, 100);
insert into im_trans_task_progress values (91, 370, 100);
insert into im_trans_task_progress values (92, 370, 100);
insert into im_trans_task_progress values (93, 370, 100);
insert into im_trans_task_progress values (94, 370, 100);
insert into im_trans_task_progress values (95, 370, 100);
insert into im_trans_task_progress values (96, 370, 100);

-- values for 354, 356, 358, 360, 365, 370, 372 are always 100%
insert into im_trans_task_progress values (85, 372, 100);
insert into im_trans_task_progress values (86, 372, 100);
insert into im_trans_task_progress values (87, 372, 100);
insert into im_trans_task_progress values (88, 372, 100);
insert into im_trans_task_progress values (89, 372, 100);
insert into im_trans_task_progress values (90, 372, 100);
insert into im_trans_task_progress values (91, 372, 100);
insert into im_trans_task_progress values (92, 372, 100);
insert into im_trans_task_progress values (93, 372, 100);
insert into im_trans_task_progress values (94, 372, 100);
insert into im_trans_task_progress values (95, 372, 100);
insert into im_trans_task_progress values (96, 372, 100);



-- New field to indicate translators when to finish...
alter table im_trans_tasks add
        end_date                timestamptz
;


-- New form of adding the approximate size of the project:
-- Text format, because there are just too many UoMs around
-- that are necessary to consider
alter table im_projects add     trans_size              varchar(200);


-- Add a column to show the end_date of the translation tasks
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9016,90,NULL,'End Date','$end_date_input',
'','',16,'expr $project_write');

-- And this one for the people who cant _write_ on the project:
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9014,90,NULL,'End Date','$end_date_formatted',
'','',14,'expr !$project_write');



-- Replace the previous Project Size field with a more generic
-- one that takes into account T-Lines etc.
--
delete from im_view_columns where column_id = 2023;
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2023,20,NULL,'Size',
'$trans_size','','',90,'');


