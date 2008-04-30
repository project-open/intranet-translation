-- upgrade-3.1.0.1.0-3.1.1.0.0.sql

SELECT acs_log__debug('/packages/intranet-translation/sql/postgresql/upgrade/upgrade-3.1.0.1.0-3.1.1.0.0.sql','');


-- Make sure the invoice_id actually references an invoice
--

create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select  count(*) into v_count from pg_constraint
	where   lower(conname) = ''im_trans_tasks_invoice_fk'';
	if v_count > 0 then return 0; end if;

	alter table im_trans_tasks
	add constraint im_trans_tasks_invoice_fk foreign key (invoice_id) references im_invoices;

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();






create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select  count(*) into v_count from user_tab_columns
	where   lower(table_name) = ''im_trans_tasks'' and lower(column_name) = ''quote_id'';
	if v_count > 0 then return 0; end if;

	alter table im_trans_tasks add quote_id integer;
	
	alter table im_trans_tasks
	add constraint im_trans_tasks_quote_fk foreign key (quote_id) references im_invoices;

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
