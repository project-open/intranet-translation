<if @rowcount@ ne 0>
    <table>
	<form method=POST action=/intranet/member-add-2>
	<%= [export_form_vars object_id return_url] %>
	<input type=hidden name=target value=<%= [im_url_stub]/member-add-2 %>>
	<input type=hidden name=passthrough value='object_id role return_url also_add_to_group_id'>

	@html;noquote@

	<tr>
	<td colspan=@colspan@ align=right>

	      <%= [_ intranet-core.add_as] %>
	      <%= [im_biz_object_roles_select role_id $project_id $default_role_id] %><br>
	      <input type=submit name=submit_add value="<%= [_ intranet-core.Add] %>">
	      <input type=checkbox name=notify_asignee value=1 checked><%= [_ intranet-freelance.Notify] %>
	</td>
	</tr>



	</form>
    </table>
</if>

