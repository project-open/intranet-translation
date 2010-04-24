<master>
<property name="title">@page_title@</property>
<property name="context">@context;noquote@</property>
<property name="focus">@focus;noquote@</property>
<property name="main_navbar_label">projects</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>

<if @message@ not nil>
  <div class="general-message">@message@</div>
</if>

<formtemplate id="task"></formtemplate>

