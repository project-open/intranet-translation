-- /packages/intranet-translation/sql/oracle/intranet-translation-create.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

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
-- Views

-- Add a columns to the projects view showing the "trans_project_size":
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2023,20,NULL,'Size',
'$trans_size','','',90,'im_permission $user_id view_trans_proj_detail');



-- trans_task_list
insert into im_views (view_id, view_name, visible_for) 
values (90, 'trans_task_list', 'view_trans_tasks');


-- Translation TasksListPage columns
--
delete from im_view_columns where view_id = 90;
--



-- Allow translation tasks to be checked/unchecked all together
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (9000,90,NULL,'<input type=checkbox name=_dummy onclick=\\"acs_ListCheckAll(''task'',this.checked)\\">','$del_checkbox','','', 0,'expr $project_write');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9010,90,NULL,'Task Name','$task_name_splitted','','',100,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9012,90,NULL,'Target Lang','$target_language','','',120,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9014,90,NULL,'XTr','$match_x','','',140,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9016,90,NULL,'Rep','$match_rep','','',150,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9018,90,NULL,'100 %','$match100','','',180,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9020,90,NULL,'95 %','$match95','','',200,'im_permission $user_id view_trans_task_matrix');
-- 9021 blocked, this was the old checkbox column
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9022,90,NULL,'85 %','$match85','','',220,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9024,90,NULL,'75 %','$match75','','',240,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9026,90,NULL,'50 %','$match50','','',260,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9028,90,NULL,'0 %','$match0','','',280,'im_permission $user_id view_trans_task_matrix');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9040,90,NULL,'Units','$task_units $uom_name','','',400,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9042,90,NULL,'Bill. Units','$billable_items_input','','',420,'expr $project_write');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9044,90,NULL,'Bill. Units Interco','$billable_items_input_interco','','',440,'expr $project_write && $interco_p');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9050,90,NULL,'Quoted Price','$quoted_price','','',500,'im_permission $user_id view_finance');

-- Show cost and margin only to WhP
-- insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
-- values (9052,90,NULL,'Ordered Cost','$po_cost','','',520,'im_permission $user_id view_finance');
-- insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
-- values (9054,90,NULL,'Gross Margin','$gross_margin','','',540,'im_permission $user_id view_finance');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9060,90,NULL,'End Date','$end_date_formatted','','',600,'expr !$project_write');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9062,90,NULL,'End Date','$end_date_input','','',620,'expr $project_write');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9064,90,NULL,'Task Type','$type_select','','',640,'expr $project_write');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9066,90,NULL,'Task Status','$status_select','','',660,'expr $project_write');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9080,90,NULL,'Assigned','$assignments','','',800,'expr $project_write');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9082,90,NULL,'Message','$message','','',820,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9084,90,NULL,'[im_gif save "Download files"]','$download_link','','',840,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9086,90,NULL,'[im_gif open "Upload files"]','$upload_link','','',860,'');


create or replace view im_task_status as 
select category_id as task_status_id, category as task_status
from im_categories 
where category_type = 'Intranet Translation Task Status';


-- -------------------------------------------------------------------
-- Categories
-- -------------------------------------------------------------------

-- Fixed thanks to Bohumil Gorcic:
-- Maybe these lines have got here as part of testing the code?
--
-- delete from im_biz_object_role_map where object_type_id in (
-- 	select category_id from im_categories where category_type = 'Intranet Project Type');
-- delete from im_category_hierarchy where parent_id in (
--	select category_id from im_categories where category_type = 'Intranet Project Type');
--delete from im_categories where category_type = 'Intranet Project Type';



SELECT im_category_new (87, 'Trans + Edit', 'Intranet Project Type');
SELECT im_category_new (88, 'Edit Only', 'Intranet Project Type');
SELECT im_category_new (89, 'Trans + Edit + Proof', 'Intranet Project Type');
SELECT im_category_new (90, 'Linguistic Validation', 'Intranet Project Type');
SELECT im_category_new (91, 'Localization', 'Intranet Project Type');
SELECT im_category_new (92, 'Technology', 'Intranet Project Type');
SELECT im_category_new (93, 'Trans Only', 'Intranet Project Type');
SELECT im_category_new (94, 'Trans + Int. Spotcheck', 'Intranet Project Type');
SELECT im_category_new (95, 'Proof Only', 'Intranet Project Type');
SELECT im_category_new (96, 'Glossary Compilation', 'Intranet Project Type');


-- -------------------------------------------------------------------
-- Category Hierarchy
-- -------------------------------------------------------------------

-- 2500-2599  Translation Hierarchy

SELECT im_category_new (2500,  'Translation Project',  'Intranet Project Type');

insert into im_category_hierarchy values (2500,87);
insert into im_category_hierarchy values (2500,88);
insert into im_category_hierarchy values (2500,89);
insert into im_category_hierarchy values (2500,90);
insert into im_category_hierarchy values (2500,91);
insert into im_category_hierarchy values (2500,92);
insert into im_category_hierarchy values (2500,93);
insert into im_category_hierarchy values (2500,94);
insert into im_category_hierarchy values (2500,95);
insert into im_category_hierarchy values (2500,96);


-- -------------------------------------------------------------------
-- Other Categories
-- -------------------------------------------------------------------

-- Intranet Quality
SELECT im_category_new (110,'Premium Quality','Intranet Quality');
SELECT im_category_new (111,'High Quality','Intranet Quality','category');
SELECT im_category_new (112,'Average Quality','Intranet Quality');
SELECT im_category_new (113,'Draft Quality','Intranet Quality');


-- Setup the most frequently used language (lang, sort_key, name)
SELECT im_category_new (21010,'none','Intranet Translation Language','No Language');
SELECT im_category_new (21020,'af','Intranet Translation Language','Afrikaans');
SELECT im_category_new (21030,'ar','Intranet Translation Language','Arabic');
SELECT im_category_new (21040,'be','Intranet Translation Language','Byelorussian');
SELECT im_category_new (21050,'bg','Intranet Translation Language','Bulgarian');
SELECT im_category_new (21060,'bs','Intranet Translation Language','Bosnian');
SELECT im_category_new (21070,'ca','Intranet Translation Language','Catalan');
SELECT im_category_new (21080,'cs','Intranet Translation Language','Czech');
SELECT im_category_new (21090,'da','Intranet Translation Language','Danish');
SELECT im_category_new (21100,'de','Intranet Translation Language','German');
SELECT im_category_new (21110,'de_CH','Intranet Translation Language','Swiss German');
SELECT im_category_new (21120,'de_DE','Intranet Translation Language','German German');
SELECT im_category_new (21130,'en','Intranet Translation Language','English');
SELECT im_category_new (21140,'en_AU','Intranet Translation Language','English (Australia)');
SELECT im_category_new (21150,'en_CA','Intranet Translation Language','English (Canada)');
SELECT im_category_new (21160,'en_IE','Intranet Translation Language','English (Ireland)');
SELECT im_category_new (21170,'en_UK','Intranet Translation Language','English (UK)');
SELECT im_category_new (21180,'en_US','Intranet Translation Language','English (US)');
SELECT im_category_new (21190,'es','Intranet Translation Language','Spanish');
SELECT im_category_new (21200,'es_ES','Intranet Translation Language','Spanish (Spain)');
SELECT im_category_new (21210,'es_LA','Intranet Translation Language','Spanish (Latin America)');
SELECT im_category_new (21220,'et','Intranet Translation Language','Estonian');
SELECT im_category_new (21230,'eu','Intranet Translation Language','Euskera');
SELECT im_category_new (21240,'fa','Intranet Translation Language','Farsi');
SELECT im_category_new (21250,'fi','Intranet Translation Language','Finnish');
SELECT im_category_new (21260,'fr','Intranet Translation Language','French');
SELECT im_category_new (21270,'fr_BE','Intranet Translation Language','French (Belgium)');
SELECT im_category_new (21280,'fr_CH','Intranet Translation Language','French (Switzerland)');
SELECT im_category_new (21290,'fr_FR','Intranet Translation Language','French (France)');
SELECT im_category_new (21300,'gl','Intranet Translation Language','Galician');
SELECT im_category_new (21310,'gr','Intranet Translation Language','Greek');
SELECT im_category_new (21320,'hr','Intranet Translation Language','Croatian');
SELECT im_category_new (21330,'hu','Intranet Translation Language','Hungarian');
SELECT im_category_new (21340,'hy','Intranet Translation Language','Armenian');
SELECT im_category_new (21350,'in','Intranet Translation Language','Indonesian');
SELECT im_category_new (21360,'is','Intranet Translation Language','Islandic');
SELECT im_category_new (21370,'it','Intranet Translation Language','Italian');
SELECT im_category_new (21380,'he','Intranet Translation Language','Hebrew');
SELECT im_category_new (21390,'jp','Intranet Translation Language','Japanese');
SELECT im_category_new (21400,'ko','Intranet Translation Language','Korean');
SELECT im_category_new (21410,'lt','Intranet Translation Language','Lithuanian');
SELECT im_category_new (21420,'lv','Intranet Translation Language','Latvian');
SELECT im_category_new (21430,'mk','Intranet Translation Language','Macedonian');
SELECT im_category_new (21440,'mo','Intranet Translation Language','Moldavian');
SELECT im_category_new (21450,'ms_MY','Intranet Translation Language','Malaysian');
SELECT im_category_new (21460,'nl','Intranet Translation Language','Dutch (Standard)');
SELECT im_category_new (21470,'nl_BE','Intranet Translation Language','Duch (Belgium)');
SELECT im_category_new (21480,'no','Intranet Translation Language','Norwegian');
SELECT im_category_new (21490,'pl','Intranet Translation Language','Polish');
SELECT im_category_new (21500,'pl','Intranet Translation Language','Polish');
SELECT im_category_new (21510,'pl','Intranet Translation Language','Polish');
SELECT im_category_new (21520,'pt','Intranet Translation Language','Portuguese');
SELECT im_category_new (21530,'pt_BR','Intranet Translation Language','Portuguese (Brazil)');
SELECT im_category_new (21540,'pt_PT','Intranet Translation Language','Portuguese (Portugal)');
SELECT im_category_new (21550,'ro','Intranet Translation Language','Romanian');
SELECT im_category_new (21560,'ru','Intranet Translation Language','Russian');
SELECT im_category_new (21570,'ru_RU','Intranet Translation Language','Russian (Russian Federation)');
SELECT im_category_new (21580,'ru_UA','Intranet Translation Language','Russian (Ukrainia)');
SELECT im_category_new (21590,'sh','Intranet Translation Language','Serbo-Croatian');
SELECT im_category_new (21600,'sk','Intranet Translation Language','Slovak');
SELECT im_category_new (21610,'sl','Intranet Translation Language','Slovenian');
SELECT im_category_new (21620,'so','Intranet Translation Language','Somali');
SELECT im_category_new (21630,'sq','Intranet Translation Language','Albanian');
SELECT im_category_new (21640,'sr','Intranet Translation Language','Serbian');
SELECT im_category_new (21650,'sv','Intranet Translation Language','Swedish');
SELECT im_category_new (21660,'sw','Intranet Translation Language','Swahili');
SELECT im_category_new (21670,'th','Intranet Translation Language','Thai');
SELECT im_category_new (21680,'tl','Intranet Translation Language','Tagalog');
SELECT im_category_new (21690,'tr','Intranet Translation Language','Turkish');
SELECT im_category_new (21700,'ts','Intranet Translation Language','Tsonga');
SELECT im_category_new (21710,'tw','Intranet Translation Language','Taiwanese (traditional Chinese)');
SELECT im_category_new (21720,'ur','Intranet Translation Language','Urdu');
SELECT im_category_new (21730,'vi','Intranet Translation Language','Vietnamese');
SELECT im_category_new (21740,'zh','Intranet Translation Language','Chinese');



-- Additional UoM categories for translation
SELECT im_category_new (323,'Page','Intranet UoM');
SELECT im_category_new (324,'S-Word','Intranet UoM');
SELECT im_category_new (325,'T-Word','Intranet UoM');
SELECT im_category_new (326,'S-Line','Intranet UoM');
SELECT im_category_new (327,'T-Line','Intranet UoM');


-- Task Status
delete from im_categories where category_type = 'Intranet Translation Task Status';

SELECT im_category_new (340,'Created','Intranet Translation Task Status');
SELECT im_category_new (342,'for Trans','Intranet Translation Task Status');
SELECT im_category_new (344,'Trans-ing','Intranet Translation Task Status');
SELECT im_category_new (346,'for Edit','Intranet Translation Task Status');
SELECT im_category_new (348,'Editing','Intranet Translation Task Status');
SELECT im_category_new (350,'for Proof','Intranet Translation Task Status');
SELECT im_category_new (352,'Proofing','Intranet Translation Task Status');
SELECT im_category_new (354,'for QCing','Intranet Translation Task Status');
SELECT im_category_new (356,'QCing','Intranet Translation Task Status');
SELECT im_category_new (358,'for Deliv','Intranet Translation Task Status');
SELECT im_category_new (360,'Delivered','Intranet Translation Task Status');
SELECT im_category_new (365,'Invoiced','Intranet Translation Task Status');
SELECT im_category_new (370,'Payed','Intranet Translation Task Status');
SELECT im_category_new (372,'Deleted','Intranet Translation Task Status');
-- reserved until 399


-- Subject Areas
delete from im_categories where category_type = 'Intranet Translation Subject Area';

SELECT im_category_new (500,'Bio','Intranet Translation Subject Area');
SELECT im_category_new (505,'Biz','Intranet Translation Subject Area');
SELECT im_category_new (510,'Com','Intranet Translation Subject Area');
SELECT im_category_new (515,'Eco','Intranet Translation Subject Area');
SELECT im_category_new (520,'Gen','Intranet Translation Subject Area');
SELECT im_category_new (525,'Law','Intranet Translation Subject Area');
SELECT im_category_new (530,'Lit','Intranet Translation Subject Area');
SELECT im_category_new (535,'Loc','Intranet Translation Subject Area');
SELECT im_category_new (540,'Mkt','Intranet Translation Subject Area');
SELECT im_category_new (545,'Med','Intranet Translation Subject Area');
SELECT im_category_new (550,'Tec','Intranet Translation Subject Area');
SELECT im_category_new (555,'Tec-Auto','Intranet Translation Subject Area');
SELECT im_category_new (560,'Tec-Telecos','Intranet Translation Subject Area');
SELECT im_category_new (565,'Tec-Gen','Intranet Translation Subject Area');
SELECT im_category_new (570,'Tec-Mech. eng','Intranet Translation Subject Area');
-- reserved until 599




-- -------------------------------------------------------------------
-- Translation Memory (TM) Types for the translation workflow
-- -------------------------------------------------------------------

-- 4200-4299	Intranet Trans TM Type
SELECT im_category_new (4200,'External', 'Intranet TM Integration Type','Trados is integrated by up/downloading files');
SELECT im_category_new (4202,'Ophelia', 'Intranet TM Integration Type','Ophelia in integrated via UserExists');
SELECT im_category_new (4204,'None', 'Intranet TM Integration Type','No integration - not a TM task');
