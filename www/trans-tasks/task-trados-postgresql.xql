<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-translation/www/trans-tasks/task-trados-postgresql.xql -->
<!-- @author  (juanjoruizx@yahoo.es) -->
<!-- @creation-date 2004-09-20 -->
<!-- @arch-tag dc60b5d5-79fc-43ca-aa87-73712caa04fd -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  
  <fullquery name="projects_info_query">
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
