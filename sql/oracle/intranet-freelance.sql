-----------------------------------------------------------
-- Freelance Management specific data model
--
-- "Freelancers" are a kind of users, exteded by payment
-- methods and a set of skills/tools/...

-----------------------------------------------------------
-- Freelancers
--
-- 
create table im_freelancers (
	user_id			primary key references users,
	web_site		varchar(1000),
	translation_rate	number(6,2),
	editing_rate		number(6,2),
	hourly_rate		number(6,2),
	bank_account		varchar(200),
	bank			varchar(100),
	payment_method_id	references im_categories,
	note			varchar(4000),
	private_note		varchar(4000),
	cv			clob
);

-----------------------------------------------------------
-- Skills
--
-- We want to say something like: This user claims he is excellent 
-- at translating into Spanish, but we haven't checked it yet.
-- So what we do is define a mapping between user_ids and 
-- skill_ids. Plus we need to reuse categories such as "Languages"
-- so that we need a "skill type".
-- So we define a "skill type", for example "target languages",
-- or "operating systems". And we define individual skills such
-- as "Castillian Spanish" or "Linux 2.4.x".
--

create table im_freelance_skills (
	user_id			not null references users,
	skill_id		not null references im_categories,
	skill_type_id		not null references im_categories,
	claimed_experience_id	references im_categories,
	confirmed_experience_id	references im_categories,
	confirmation_user_id	references users,
	confirmation_date	date,
	primary key (user_id, skill_id, skill_type_id)
);

create index im_freelance_skills_user_idx on im_freelance_skills(user_id);


create or replace view im_freelance_skill_types as 
select category_id as skill_type_id, category as skill_type
from im_categories 
where category_type = 'Intranet Skill Type';


-- We need to define this function as a type of "join(..., ", ") to
-- get the list of skills for each user and skill type.
--
-- select im_freelance_skill_list(26,2000) from dual; -> 'es es_LA'
--


create or replace function im_freelance_skill_list ( 
	p_user_id IN number,
	p_skill_type_id IN number) 
RETURN char
IS
	v_skills			varchar(4000);
	v_skill				varchar(4000);

    CURSOR c_user_skills (v_user_id IN number, v_skill_type_id IN number) IS
	select	c.category	
	from	im_freelance_skills s,
		im_categories c
	where  	s.user_id=v_user_id
		and s.skill_type_id=v_skill_type_id
		and s.skill_id=c.category_id
	order by c.category;
BEGIN
	v_skills := '';
	FOR val IN c_user_skills(p_user_id, p_skill_type_id) LOOP
		v_skills := CONCAT(v_skills, ' ');
		v_skills := CONCAT(v_skills, val.category);
	END LOOP;
	RETURN v_skills;
END;
/
show errors;


insert into im_views values (50, 'user_list_freelance', 'view_users', '');
insert into im_views values (51, 'user_view_freelance', 'view_users', '');


-- Freelance Skill Types
delete from im_categories where category_id >= 2000 and category_id < 2100;
INSERT INTO im_categories VALUES (2000,'Source Language','SLS Language','Intranet Skill Type','category','f');
INSERT INTO im_categories VALUES (2002,'Target Language','SLS Language','Intranet Skill Type','category','f');
INSERT INTO im_categories VALUES (2004,'Sworn Language','SLS Language','Intranet Skill Type','category','f');
INSERT INTO im_categories VALUES (2006,'TM Tools','Intranet TM Tool','Intranet Skill Type','category','f');
INSERT INTO im_categories VALUES (2008,'LOC Tools','Intranet LOC Tool','Intranet Skill Type','category','f');
INSERT INTO im_categories VALUES (2010,'Operating System','Intranet Operating System','Intranet Skill Type','category','f');
INSERT INTO im_categories VALUES (2014,'Subjects','Intranet subjects','Intranet Skill Type','category','f');

-- Freelance TM Tools
delete from im_categories where category_id >= 2100 and category_id < 2200;
INSERT INTO im_categories VALUES (2100,'Trados 3.x','','Intranet TM Tool','category','f');
INSERT INTO im_categories VALUES (2102,'Trados 5.x','','Intranet TM Tool','category','f');
INSERT INTO im_categories VALUES (2104,'Trados 5.5','','Intranet TM Tool','category','f');
INSERT INTO im_categories VALUES (2106,'Trados 6.x','','Intranet TM Tool','category','f');
INSERT INTO im_categories VALUES (2108,'IBM Translation Workbench','','Intranet TM Tool','category','f');


-- Languages experience
delete from im_categories where category_id >= 2200 and category_id < 2300;
INSERT INTO im_categories VALUES (2200, 'Unconfirmed','',
'Intranet Experience Level','category','f');
INSERT INTO im_categories VALUES (2201, 'Low','',
'Intranet Experience Level','category','f');
INSERT INTO im_categories VALUES (2202, 'Medium','',
'Intranet Experience Level','category','f');
INSERT INTO im_categories VALUES (2203, 'High','',
'Intranet Experience Level','category','f');


-- Freelance LOC Tools
delete from im_categories where category_id >= 2300 and category_id < 2400;
INSERT INTO im_categories VALUES (2300,'Pasolo ','','Intranet LOC Tool','category','f');
INSERT INTO im_categories VALUES (2302,'Catalyst','','Intranet LOC Tool','category','f');



-- Add 'user_list_freelance'
delete from im_view_columns where column_id >= 5000 and column_id < 5099;

insert into im_view_columns values (5000,50,NULL,'Name',
'"<a href=/intranet/users/view?user_id=$user_id>$name</a>"','',2,
'im_permission $user_id view_freelancers');
-- insert into im_view_columns values (5001,50,NULL,'Email',
-- '"<a href=mailto:$email>$email</a>"','',3,
-- 'im_permission $user_id view_freelancers');
-- insert into im_view_columns values (5002,50,NULL,'Status',
-- '$status','',4,'im_permission $user_id view_freelancers');
insert into im_view_columns values (5003,50,NULL,'Src Lang',
'$source_languages','',5,'im_permission $user_id view_freelancers');
insert into im_view_columns values (5004,50,NULL,'Tgt Lang',
'$target_languages','',6,'im_permission $user_id view_freelancers');
insert into im_view_columns values (5005,50,NULL,'Subj Area',
'$subjects','',7,'im_permission $user_id view_freelancers');
insert into im_view_columns values (5006,50,NULL,'Work Phone',
'$work_phone','',8,'im_permission $user_id view_freelancers');
insert into im_view_columns values (5007,50,NULL,'Cell Phone',
'$cell_phone','',9,'im_permission $user_id view_freelancers');
insert into im_view_columns values (5008,50,NULL,'Home Phone',
'$home_phone','',10,'im_permission $user_id view_freelancers');
commit;


-- Add 'user_view_freelance'
delete from im_view_columns where column_id >= 5100 and column_id < 5199;

insert into im_view_columns values (5100,51,NULL,'Web Site',
'"<A href=$web_site>$web_site</A>"','',0,
'im_permission $user_id view_freelancers');

insert into im_view_columns values (5102,51,NULL,'Trans Rate',
'$translation_rate','',2,
'im_permission $user_id view_freelancers');

insert into im_view_columns values (5104,51,NULL,'Editing Rate',
'$editing_rate','',4,
'im_permission $user_id view_freelancers');

insert into im_view_columns values (5106,51,NULL,'Hourly Rate',
'$hourly_rate','',6,
'im_permission $user_id view_freelancers');

insert into im_view_columns values (5108,51,NULL,'Bank Account',
'$bank_account','',8,
'im_permission $user_id view_freelancers');

insert into im_view_columns values (5110,51,NULL,'Bank',
'$bank','',10,
'im_permission $user_id view_freelancers');

insert into im_view_columns values (5112,51,NULL,'Payment Method',
'$payment_method','',12,
'im_permission $user_id view_freelancers');

insert into im_view_columns values (5114,51,NULL,'Note',
'<blockqote>$note</blockquote>','',14,
'im_permission $user_id view_freelancers');

insert into im_view_columns values (5116,51,NULL,'Private Note',
'<blockqote>$private_note</blockquote>','',16,
'im_permission $user_id view_freelancers');

commit;









-- Add 'users freelance' rows by "guillermo"

delete from im_view_columns where column_id > 500 and column_id < 520;

insert into im_view_columns values (502,13,NULL,'Web Site','$web_site','',1,
'im_view_user_permission $user_id $current_user_id $web_site view_users');

insert into im_view_columns values (504,13,NULL,'Translation Rate','$translation_rate','',2,
'im_view_user_permission $user_id $current_user_id $translation_rate view_users');

insert into im_view_columns values (506,13,NULL,'Editing Rate','$editing_rate','',3,
'im_view_user_permission $user_id $current_user_id $editing_rate view_users');

insert into im_view_columns values (508,13,NULL,'Hourly_rate','$hourly_rate','',4,
'im_view_user_permission $user_id $current_user_id $hourly_rate view_users');

insert into im_view_columns values (510,13,NULL,'Bank Account','$bank_account','',5,
'im_view_user_permission $user_id $current_user_id $bank_account view_users');

insert into im_view_columns values (512,13,NULL,'Bank','$bank','',6,
'im_view_user_permission $user_id $current_user_id $bank view_users');

insert into im_view_columns values (514,13,NULL,'Payment Method','$payment_method','',7,
'im_view_user_permission $user_id $current_user_id $payment_method view_users');

insert into im_view_columns values (516,13,NULL,'Note','$note','',8,
'im_view_user_permission $user_id $current_user_id $note view_users');

insert into im_view_columns values (518,13,NULL,'CV','$cv','',9,
'im_view_user_permission $user_id $current_user_id $cv view_users');

commit;



delete from im_view_columns where column_id > 500 and column_id < 520;

insert into im_view_columns values (502,13,NULL,'Web Site','$web_site','',1,
'im_permission $user_id view_users');

insert into im_view_columns values (504,13,NULL,'Translation Rate','$translation_rate','',2,
'im_permission $user_id view_users');

insert into im_view_columns values (506,13,NULL,'Editing Rate','$editing_rate','',3,
'im_permission $user_id view_users');

insert into im_view_columns values (508,13,NULL,'Hourly_rate','$hourly_rate','',4,
'im_permission $user_id view_users');

insert into im_view_columns values (510,13,NULL,'Bank Account','$bank_account','',5,
'im_permission $user_id view_users');

insert into im_view_columns values (512,13,NULL,'Bank','$bank','',6,
'im_permission $user_id view_users');

insert into im_view_columns values (514,13,NULL,'Payment Method','$payment_method','',7,
'im_permission $user_id view_users');

insert into im_view_columns values (516,13,NULL,'Note','$note','',8,
'im_permission $user_id view_users');

insert into im_view_columns values (518,13,NULL,'CV','$cv','',9,
'im_permission $user_id view_users');


commit;


