<master src="../../../intranet-core/www/master">

<property name="title">#intranet-translation.Trados_Matrix#</property>
<property name="context">#intranet-translation.context#</property>
<property name="main_navbar_label">finance</property>

<property name="focus">@focus;noquote@</property>


<form action=new-2 method=POST>
@export_vars;noquote@
<table border=0>
<tr>
  <td colspan=2 class=rowtitle align=middle>
    #intranet-translation.Trados_Matrix#
  </td>
</tr>
<tr>
  <td>#intranet-translation.X_Trans#</td>
  <td><input type=text name=match_x size=8 value=@match_x@></td>
</tr>
<tr>
  <td>#intranet-translation.Repetitions#</td>
  <td><input type=text name=match_rep size=8 value=@match_rep@></td>
</tr>
<tr>
  <td>100%</td>
  <td><input type=text name=match100 size=8 value=@match100@></td>
</tr>
<tr>
  <td>95% - 99%</td>
  <td><input type=text name=match95 size=8 value=@match95@></td>
</tr>
<tr>
  <td>85% - 94%</td>
  <td><input type=text name=match85 size=8 value=@match85@></td>
</tr>
<tr>
  <td>75% - 84%</td>
  <td><input type=text name=match75 size=8 value=@match75@></td>
</tr>
<tr>
  <td>50% - 74%</td>
  <td><input type=text name=match50 size=8 value=@match50@></td>
</tr>
<tr>
  <td>#intranet-translation.No_Match#</td>
  <td><input type=text name=match0 size=8 value=@match0@></td>
</tr>
<tr>
  <td colspan=2 align=middle>
    <input type=submit value=Save>
  </td>
</tr>
</table>
</form>


