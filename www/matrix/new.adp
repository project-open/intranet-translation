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
  <td>Match 100</td>
  <td><input type=text name=match100 size=5 value=@match100@></td>
</tr>
<tr>
  <td>Match 95</td>
  <td><input type=text name=match95 size=5 value=@match95@></td>
</tr>
<tr>
  <td>Match 85</td>
  <td><input type=text name=match85 size=5 value=@match85@></td>
</tr>
<tr>
  <td>Match 75</td>
  <td><input type=text name=match75 size=5 value=@match75@></td>
</tr>
<tr>
  <td>Match 50</td>
  <td><input type=text name=match50 size=5 value=@match50@></td>
</tr>
<tr>
  <td>Match 0</td>
  <td><input type=text name=match0 size=5 value=@match0@></td>
</tr>
<tr>
  <td colspan=2 align=middle>
    <input type=submit value=Save>
  </td>
</tr>
</table>
</form>

