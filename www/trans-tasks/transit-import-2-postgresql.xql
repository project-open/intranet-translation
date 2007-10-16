<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-translation/www/trans-tasks/transit-import-postgresql.xql -->
<!-- @author  (juanjoruizx@yahoo.es) -->
<!-- @creation-date 2004-09-20 -->
<!-- @arch-tag 232ff8e4-83ff-42af-9f88-88d6d946c21c -->
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
        p.company_id as customer_id,
        c.company_name as company_short_name,
        p.source_language_id,
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
