<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-translation/tcl/intranet-trans-procs-postgresql.xql -->
<!-- @author  (nsadmin@barna.competitiveness.com) -->
<!-- @creation-date 2004-09-17 -->
<!-- @arch-tag 29eff3df-80e9-4e9c-bbd1-88e2c3d03e17 -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  


  <fullquery name="im_trans_trados_matrix_project.matrix_select">
    <querytext>

select
        m.*,
        acs_object__name(o.object_id) as object_name
from
        acs_objects o
      LEFT JOIN
        im_trans_trados_matrix m USING (object_id)
where
        o.object_id = :project_id
      
    </querytext>
  </fullquery>


  <fullquery name="im_trans_trados_matrix_company.matrix_select">
    <querytext>

select
        m.*,
        acs_object__name(o.object_id) as object_name
from
        acs_objects o
      LEFT JOIN
        im_trans_trados_matrix m USING (object_id)
where
        o.object_id = :company_id
      
    </querytext>
  </fullquery>


  <fullquery name="im_trans_trados_matrix_internal.matrix_select">
    <querytext>

select
        m.*,
        acs_object__name(o.object_id) as object_name
from
        acs_objects o
      LEFT JOIN
        im_trans_trados_matrix m USING (object_id)
where
        o.object_id = :company_id
      
    </querytext>
  </fullquery>

  <fullquery name="im_task_status_component.task_status_sql">
    <querytext>
select
	u.user_id,
	im_name_from_user_id (u.user_id) as user_name,
	CASE WHEN c.trans_ass is null THEN 0 ELSE c.trans_ass END as trans_ass,
	CASE WHEN c.edit_ass is null THEN 0 ELSE c.edit_ass END as edit_ass,
	CASE WHEN c.proof_ass is null THEN 0 ELSE c.proof_ass END as proof_ass,
	CASE WHEN c.other_ass is null THEN 0 ELSE c.other_ass END as other_ass,
	CASE WHEN c.trans_words is null THEN 0 ELSE c.trans_words END as trans_words,
	CASE WHEN c.edit_words is null THEN 0 ELSE c.edit_words END as edit_words,
	CASE WHEN c.proof_words is null THEN 0 ELSE c.proof_words END as proof_words,
	CASE WHEN c.other_words is null THEN 0 ELSE c.other_words END as other_words,
	s.trans_down,
	s.trans_up,
	s.edit_down,
	s.edit_up,
	s.proof_down,
	s.proof_up,
	s.other_down,
	s.other_up
from
	acs_rels r,
	users u
      LEFT JOIN
	($task_status_sql) s USING (user_id)
      LEFT JOIN
	($task_filecount_sql) c USING (user_id)
where
	r.object_id_one = :project_id
	and r.object_id_two = u.user_id

    </querytext>
  </fullquery>


  <fullquery name="im_task_error_component.select_tasks">
    <querytext>

	select
	        min(t.task_id) as task_id,
	        t.task_name,
	        t.task_filename,
	        t.task_units,
	        im_category_from_id(t.source_language_id) as source_language,
	        uom_c.category as uom_name,
	        type_c.category as type_name
	from
	        im_trans_tasks t
		LEFT JOIN im_categories uom_c ON t.task_uom_id = uom_c.category_id
		LEFT JOIN im_categories type_c ON t.task_type_id = type_c.category_id
	where
	        project_id=:project_id
	        and t.task_status_id <> 372
	group by
	        t.task_name,
	        t.task_filename,
	        t.task_units,
	        t.source_language_id,
	        uom_c.category,
	        type_c.category

    </querytext>
  </fullquery>

  <fullquery name="im_task_component.select_tasks">
    <querytext>
select 
	t.*,
	p.subject_area_id,
	p.source_language_id,
	im_category_from_id(t.tm_integration_type_id) as tm_integration_type,
	to_char(t.end_date, :date_format) as end_date_formatted,
        im_category_from_id(t.source_language_id) as source_language,
        im_category_from_id(t.target_language_id) as target_language,
        im_category_from_id(t.task_status_id) as task_status,
	im_category_from_id(t.task_uom_id) as uom_name,
	im_category_from_id(t.task_type_id) as type_name,
        im_initials_from_user_id (t.trans_id) as trans_name,
        im_initials_from_user_id (t.edit_id) as edit_name,
        im_initials_from_user_id (t.proof_id) as proof_name,
        im_initials_from_user_id (t.other_id) as other_name
	$extra_select
from 
	im_projects p,
	im_trans_tasks t
	$extra_from
where
	t.project_id = p.project_id and
	$project_where
	$extra_where
order by
	t.task_name,
	t.target_language_id

    </querytext>
  </fullquery>


  <fullquery name="im_task_missing_file_list.projects_info_query">
    <querytext>

select
        p.project_nr as project_short_name,
        c.company_name as company_short_name,
        p.source_language_id,
        im_category_from_id(p.source_language_id) as source_language,
        p.project_type_id
from
        im_projects p
      LEFT JOIN
        im_companies c USING (company_id)
where
        p.project_id=:project_id

    </querytext>
  </fullquery>


</queryset>
