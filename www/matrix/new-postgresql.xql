<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-translation/www/matrix/new-postgresql.xql -->
<!-- @author  (juanjoruizx@yahoo.es) -->
<!-- @creation-date 2004-09-20 -->
<!-- @arch-tag 87578c83-1d83-421c-8239-032abfe06103 -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  
  
  <fullquery name="matrix_select">
    <querytext>

select
        m.*,
        acs_object__name(o.object_id) as object_name
from
        acs_objects o
      LEFT JOIN
        im_trans_trados_matrix m USING (object_id)
where
        o.object_id = :object_id

    </querytext>
  </fullquery>

</queryset>
