<master src="../../../intranet-core/www/master">
<property name="title">@page_title;noquote@</property>

<%= [im_costs_navbar "none" "/intranet/invoices/index" "" "" [list]] %>

<form action=new-2 method=POST>
<%= [export_form_vars invoice_id project_id return_url] %>

<table border=0 width=100%>
<tr><td>

  <table cellpadding=0 cellspacing=0 bordercolor=#6699CC border=0 width=100%>
    <tr valign=top> 
      <td>

        <table border=0 cellPadding=0 cellspacing=2 width=100%>


	        <tr><td align=middle class=rowtitle colspan=2>#intranet-translation.cost_type_Data#</td></tr>
	        <tr>
	          <td  class=rowodd>#intranet-translation.cost_type_nr#</td>
	          <td  class=rowodd> 
	            <input type=text name=invoice_nr size=15 value='@invoice_nr@'>
	          </td>
	        </tr>
	        <tr> 
	          <td  class=roweven>#intranet-translation.cost_type_date#</td>
	          <td  class=roweven> 
	            <input type=text name=invoice_date size=15 value='@effective_date@'>
	          </td>
	        </tr>
	        <tr> 
	          <td class=roweven>#intranet-translation.Payment_terms#</td>
	          <td class=roweven> 
	            <input type=text name=payment_days size=5 value='@payment_days@'>
	            #intranet-translation.days#</td>
	        </tr>
<if @invoice_or_bill_p@>
	        <tr> 
	          <td class=rowodd>#intranet-translation.Payment_Method#</td>
	          <td class=rowodd>@payment_method_select;noquote@</td>
	        </tr>
</if>
	        <tr> 
	          <td class=roweven> #intranet-translation.cost_type_template#</td>
	          <td class=roweven>@template_select;noquote@</td>
	        </tr>
	        <tr> 
	          <td class=rowodd>#intranet-translation.cost_type_status#</td>
	          <td class=rowodd>@status_select;noquote@</td>
	        </tr>
	        <tr> 
	          <td class=roweven>#intranet-translation.cost_type_type#</td>
	          <td class=roweven>@type_select;noquote@</td>
	        </tr>

        </table>

      </td>
      <td></td>
      <td align=right>
        <table border=0 cellspacing=2 cellpadding=0 width=100%>

<if @invoice_or_quote_p@>
<!-- Let the user select the company. Provider=Internal -->

		<tr>
		  <td align=center valign=top class=rowtitle colspan=2>#intranet-translation.Company#</td>
		</tr>
		<tr>
		  <td class=roweven>#intranet-translation.Company_1#</tr>
		  <td class=roweven>@company_select;noquote@</td>
		</tr>
		<input type=hidden name=provider_id value=0>

</if>
<else>

		<tr>
		  <td align=center valign=top class=rowtitle colspan=2>#intranet-translation.Provider#</td>
		</tr>
		<tr>
		  <td class=roweven>#intranet-translation.Provider_1#</tr>
		  <td class=roweven>@provider_select;noquote@</td>
		</tr>
		<input type=hidden name=company_id value=0>

</else>


        </table>
    </tr>
  </table>

</td></tr>
<tr><td>

  <table width=100%>
    <tr>
      <td align=right>
 	<table border=0 cellspacing=2 cellpadding=1 width=100%>

	<!-- the list of task sums, distinguised by type and UOM -->
	@task_sum_html;noquote@

        <tr>
          <td> 
          </td>
          <td colspan=99 align=right> 
            <table border=0 cellspacing=1 cellpadding=0>
              <tr> 
                <td>#intranet-translation.VATnbsp#</td>
                <td><input type=text name=vat value='@vat@' size=4> % &nbsp;</td>
              </tr>
            </table>
          </td>
        </tr>
        <tr> 
          <td> 
          </td>
          <td colspan=99 align=right> 
            <table border=0 cellspacing=1 cellpadding=0>
              <tr> 
                <td>#intranet-translation.TAXnbsp#</td>
                <td><input type=text name=tax value='@tax@' size=4> % &nbsp;</td>
              </tr>
            </table>
          </td>
        </tr>
        <tr> 
          <td>&nbsp; </td>
          <td colspan=6 align=right> 
              <input type=submit name=submit value='@button_text@'>
          </td>
        </tr>

        </table>
      </td>
    </tr>
  </table>


</td></tr>
</table>

</form>

