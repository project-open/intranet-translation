<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-translation/www/projects/edit-trans-data-postgresql.xql -->
<!-- @author  (juanjoruizx@yahoo.es) -->
<!-- @creation-date 2004-09-20 -->
<!-- @arch-tag 9e9d5231-7131-40f4-a920-4784b078a990 -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  
  <fullquery name="projects_info_query">
    <querytext>

select
        p.*,
        p.company_project_nr,
        c.company_name
from
        im_projects p
      LEFT JOIN
        im_companies c ON p.project_id=c.company_id
where
        p.project_id=:project_id

    </querytext>
  </fullquery>
</queryset>
