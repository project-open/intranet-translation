-- /packages/intranet-translation/sql/oracle/intranet-translation-create.sql
--
-- Copyright (c) 2003-2004 Project/Open
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
'[if {"" == $trans_project_words} {
        set t ""
} else {
        set t "${trans_project_words}w ${trans_project_hours}h"
}]','','',15,'');




-- trans_task_list
insert into im_views (view_id, view_name, visible_for) 
values (90, 'trans_task_list', 'view_trans_tasks');


-- Translation TasksListPage columns
--
delete from im_view_columns where column_id >= 9000 and column_id <= 9099;
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9001,90,NULL,'Task Name','$task_name_splitted',
'','',1,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9003,90,NULL,'Target Lang','$target_language',
'','',3,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9004,90,NULL,'XTr','$match_x',
'','',4,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9005,90,NULL,'Rep','$match_rep',
'','',5,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9006,90,NULL,'100 %','$match100',
'','',6,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9007,90,NULL,'95 %','$match95',
'','',7,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9008,90,NULL,'85 %','$match85',
'','',8,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9009,90,NULL,'75 %','$match75',
'','',9,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9010,90,NULL,'50 %','$match50',
'','',10,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9011,90,NULL,'0 %','$match0',
'','',11,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9013,90,NULL,'Units','$task_units $uom_name',
'','',13,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9015,90,NULL,'Bill. Units','$billable_items_input',
'','',15,'expr $project_write');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9017,90,NULL,'Task Type','$type_select',
'','',17,'expr $project_write');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9019,90,NULL,'Task Status','$status_select',
'','',19,'expr $project_write');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9021,90,NULL,'[im_gif delete "Delete the Task"]','$del_checkbox',
'','',21,'expr $project_write');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9023,90,NULL,'Assigned','$assignments',
'','',23,'expr $project_write');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9025,90,NULL,'Message','$message',
'','',25,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9027,90,NULL,'[im_gif save "Download files"]','$download_link',
'','',27,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (9029,90,NULL,'[im_gif open "Upload files"]','$upload_link',
'','',29,'');



create or replace view im_task_status as 
select category_id as task_status_id, category as task_status
from im_categories 
where category_type = 'Intranet Translation Task Status';


-- -------------------------------------------------------------------
-- Categories
-- -------------------------------------------------------------------


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
insert into im_categories values (93,  'Trans Only',  
'',  'Intranet Project Type','category','t','f');
insert into im_categories values (94,  'Trans + Int. Spotcheck',  
'',  'Intranet Project Type','category','t','f');
insert into im_categories values (95,  'Proof Only',  
'',  'Intranet Project Type','category','t','f');
insert into im_categories values (96,  'Glossary Compilation',  
'',  'Intranet Project Type','category','t','f');


-- -------------------------------------------------------------------
-- Category Hierarchy
-- -------------------------------------------------------------------

-- 2500-2599    Translation Hierarchy

insert into im_categories values (2500,  'Translation Project',  
'',  'Intranet Project Type','category','t','f');

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
INSERT INTO im_categories VALUES (110,'Premium Quality','Premium Quality','Intranet Quality','category','t','f');
INSERT INTO im_categories VALUES (111,'High Quality','High Quality','Intranet Quality','category','t','f');
INSERT INTO im_categories VALUES (112,'Average Quality','Average Quality','Intranet Quality','category','t','f');
INSERT INTO im_categories VALUES (113,'Draft Quality','Draft Quality','Intranet Quality','category','t','f');


-- Setup the most frequently used language (lang, sort_key, name)
INSERT INTO im_categories VALUES (250,'es','Spanish','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (251,'es_ES','Spanish (Spain)','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (252,'es_LA','Spanish (Latin America)','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (253,'es_US','Spanish (US)','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (254,'es_MX','Spanish (Mexico)','Intranet Translation Language','category','t','f');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(255,'es_VE','Intranet Translation Language','Spanish (Venezuea)');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(256,'es_PE','Intranet Translation Language','Spanish (Peru)');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(257,'es_AR','Intranet Translation Language','Spanish (Argentina)');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(258,'es_UY','Intranet Translation Language','Spanish (Uruguay)');

INSERT INTO im_categories VALUES (261,'en','English','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (262,'en_US','English (US)','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (263,'en_UK','English (UK)','Intranet Translation Language','category','t','f');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(264,'en_CA','Intranet Translation Language','English (Canada)');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(265,'en_IE','Intranet Translation Language','English (Ireland)');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(266,'en_AU','Intranet Translation Language','English (Australia)');


INSERT INTO im_categories (category_id, category, category_type, category_description) VALUES
(268,'it','Intranet Translation Language','Italian');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(269,'it_IT','Intranet Translation Language','Italian Italy');

INSERT INTO im_categories VALUES (271,'fr','French','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (272,'fr_FR','French (France)','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (273,'fr_BE','French (Belgium)','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (274,'fr_CH','French (Switzerland)','Intranet Translation Language','category','t','f');

INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(276,'pt','Intranet Translation Language','Portuguese');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(277,'pt_PT','Intranet Translation Language','Portuguese (Portugal)');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(278,'pt_BR','Intranet Translation Language','Portuguese (Brazil)');

INSERT INTO im_categories VALUES (281,'de','German','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (282,'de_DE','German German','Intranet Translation Language','category','t','f');
INSERT INTO im_categories VALUES (283,'de_CH','Swiss German','Intranet Translation Language','category','t','f');

INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(285,'ru','Intranet Translation Language','Russian');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(286,'ru_RU','Intranet Translation Language','Russian (Russian Federation)');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(287,'ru_UA','Intranet Translation Language','Russian (Ukrainia)');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(288,'da','Intranet Translation Language','Danish');


INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(290,'nl','Intranet Translation Language','Dutch');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(291,'nl_NL','Intranet Translation Language','Duch (The Netherlands)');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(292,'nl_BE','Intranet Translation Language','Duch (Belgium)');

INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(294,'ca_ES','Intranet Translation Language','Catalan (Spain)');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(295,'gr','Intranet Translation Language','Greek');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(296,'gl','Intranet Translation Language','Galician');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(297,'eu','Intranet Translation Language','Euskera');

INSERT INTO im_categories VALUES (299,'none','No Language','Intranet Translation Language','category','t','f');


-- Additional UoM categories for translation
INSERT INTO im_categories VALUES (323,'Page','','Intranet UoM','category','t','f');
INSERT INTO im_categories VALUES (324,'S-Word','','Intranet UoM','category','t','f');
INSERT INTO im_categories VALUES (325,'T-Word','','Intranet UoM','category','t','f');
INSERT INTO im_categories VALUES (326,'S-Line','','Intranet UoM','category','t','f');
INSERT INTO im_categories VALUES (327,'T-Line','','Intranet UoM','category','t','f');


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


