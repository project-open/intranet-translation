<master src="../../../intranet-core/www/master">

<property name="title">Companies</property>
<property name="context">context</property>

<property name="focus">@focus;noquote@</property>


<form action=new-2 method=POST>
@export_vars;noquote@
<table border=0>
<tr>
  <td colspan=2 class=rowtitle align=middle>
    Trados Matrix
  </td>
</tr>
<tr>
  <td>X Trans</td>
  <td><input type=text name=match_x size=5 value=@match_x@></td>
</tr>
<tr>
  <td>Repetitions</td>
  <td><input type=text name=match_rep size=5 value=@match_rep@></td>
</tr>
<tr>
  <td>100%</td>
  <td><input type=text name=match100 size=5 value=@match100@></td>
</tr>
<tr>
  <td>95% - 99%</td>
  <td><input type=text name=match95 size=5 value=@match95@></td>
</tr>
<tr>
  <td>85% - 94%</td>
  <td><input type=text name=match85 size=5 value=@match85@></td>
</tr>
<tr>
  <td>75% - 84%</td>
  <td><input type=text name=match75 size=5 value=@match75@></td>
</tr>
<tr>
  <td>50% - 74%</td>
  <td><input type=text name=match50 size=5 value=@match50@></td>
</tr>
<tr>
  <td>No Match</td>
  <td><input type=text name=match0 size=5 value=@match0@></td>
</tr>
<tr>
  <td colspan=2 align=middle>
    <input type=submit value=Save>
  </td>
</tr>
</table>
</form>

