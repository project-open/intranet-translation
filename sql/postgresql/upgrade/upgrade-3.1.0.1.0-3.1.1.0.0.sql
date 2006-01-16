

-- Make sure the invoice_id actually references an invoice
--
alter table im_trans_tasks
add constraint im_trans_tasks_invoice_fk 
foreign key (invoice_id) references im_invoices;

alter table im_trans_tasks
add quote_id integer;

alter table im_trans_tasks
add constraint im_trans_tasks_quote_fk 
foreign key (quote_id) references im_invoices;


