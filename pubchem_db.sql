-- 1 создание базы данных
create database pubchem;
use pubchem;
-- 2 Разделы. На портале имеется 3 основных раздела, которые содержат основную информацию.
-- Данная таблица содрежит название, описание и ссылку на эти разделы. Id служит для отнесения содержимого других таблиц к этим разделам.
create table partitions (
	id TINYINT(4) UNSIGNED PRIMARY KEY AUTO_INCREMENT NOT NULL,
	name varchar(50) NOT NULL,
	description varchar(255) NOT NULL,
	href varchar(255) NOT NULL
);
-- 3 Media. В таблице media содержится информация о файлах, доступных к загрузке; файлы сгруппированны по разделам, иммется информация о дате их изменения.
create table media (
	id serial AUTO_INCREMENT PRIMARY KEY,
	user_id bigint unsigned NOT NULL,
	file_name varchar(25) NOT NULL,
	file_size_mb float(3) unsigned NOT NULL,
	partition_id TINYINT(4) unsigned NOT NULL,
	updated_date date not null
);

-- posts. На портале есть раздел "Блоги", в котором публикуются новости.
-- Авторы блогов не обязательно входят в список авторов статей.
drop table posts;
CREATE TABLE posts (
  id serial,
  user_id bigint unsigned NOT NULL,
  topic varchar(255) not null,
  description varchar(1000) DEFAULT '',
  href varchar(128) not null,
  author_id bigint(20) unsigned,
  created_at date not null,
  references_id bigint unsigned NOT NULL
);
-- favourites. Каждый пользователь может добавить нужную ему статью в "выбранные".
CREATE TABLE favourites (
  id serial,
  user_id bigint(20) unsigned NOT NULL,
  source_type_id tinyint unsigned NOT NULL,
  source_id bigint(20) unsigned NOT NULL
);
-- users. В таблице пользователи - информация о пользователях.
CREATE TABLE users (
  id serial,
  login varchar(20) NOT NULL,
  first_name varchar(50) NOT NULL,
  last_name varchar(50) NOT NULL,
  email varchar(125) NOT NULL,
  registred_at datetime not null,
  birthday datetime NOT NULL,
  company_id int(10) UNSIGNED
);
-- bibliography. Кроме списка стетей "выбранные" пользователям может понадобиться раздел "библиография" - для составления списка статей для своих собственных работ.
CREATE TABLE bibliography (
  id serial,
  user_id bigint(20) unsigned NOT NULL,
  survey_name varchar(10) NOT NULL, -- название исследования, над которым работает пользователь.
  source_type_id tinyint unsigned NOT NULL,
  source_id bigint(20) unsigned NOT NULL
);
-- articles - статьи, которые могут быть загружены пользователями портала или опубликованы журналами
create table articles (
	id serial,
	topic varchar(255) not NULL,
	description varchar(1000) not null,
	author_id bigint(20) unsigned not null,
	created_at date not null,
	updated_at date not null,
	href varchar(128) not null,
	references_id bigint unsigned not null,
	user_id bigint(20) unsigned not null, -- статья должна быть опубликована кем-то из ползователей
	company_id int UNSIGNED default 0
);
-- references_list
create table references_list (
	id serial,
	user_id bigint UNSIGNED not null,
	name varchar(255) not null,
	source_id  varchar (10),
	source_type_id tinyint(4) UNSIGNED not NULL,
	href varchar(512) not null,
	publication_date date not null
);
-- source_type
create table source_types (
	id tinyint(4) UNSIGNED not NULL AUTO_INCREMENT PRIMARY KEY,
	source_type varchar (10)
);
-- authors: таблица для сохранения авторов, добавляемых пользователями при публикации постов и статей.
-- список может быть использован для упрощения ввода автора, если он уже был кем-то добавлен, и снижения кол-ва вариантов написания фамилий;
create table authors (
	id serial,
 	first_name varchar(50) not null,
 	last_name varchar(50) not null,
 	country varchar (20) not null,
 	spec_id int not null
);
create table specialization (
	id int AUTO_INCREMENT PRIMARY KEY,
	spec varchar(50)
);
-- Данные об организациях, предоставляющих контент
-- companies
create table companies (
	id int UNSIGNED not null AUTO_INCREMENT PRIMARY KEY,
	name varchar(100) not null,
	href varchar(512) not null,
	category_id int(10) UNSIGNED not null,
	Contact_Name varchar(255) not null,
	Address varchar(255) not null,
	updated_at date not null,
	phone int(13) not null
);
-- категории компаний
create table category (
	id int UNSIGNED not null AUTO_INCREMENT PRIMARY KEY,
	category_name varchar(50)
);
-- архивная таблица для сохранения информации об удаленных пользователях
create table archive_user (
  id serial,
  login varchar(20) NOT NULL,
  first_name varchar(50) NOT NULL,
  last_name varchar(50) NOT NULL,
  email varchar(125) NOT NULL,
  registred_at datetime not null,
  birthday datetime NOT NULL,
  company_id int(10) UNSIGNED
);


/*
 * Связи
 */
use pubchem;

alter table media
 	add CONSTRAINT media_partition_id_fk
 	FOREIGN KEY (partition_id) REFERENCES partitions(id),
 	add CONSTRAINT media_user_id_fk
 	FOREIGN KEY (user_id) REFERENCES users(id);
 	
alter table users
 	add CONSTRAINT users_company_id_fk
 	FOREIGN KEY (company_id) REFERENCES companies(id);
 	
alter table companies
 	add CONSTRAINT companies_category_id_fk
 	FOREIGN KEY (category_id) REFERENCES category(id);
 	
alter table posts
 	add CONSTRAINT posts_user_id_fk
 	FOREIGN KEY (user_id) REFERENCES users(id);
alter table posts
 	add CONSTRAINT posts_references_id_fk
 	FOREIGN KEY (references_id) REFERENCES references_list(id),
	add CONSTRAINT posts_author_id_fk
	FOREIGN key (author_id) REFERENCES authors(id);
 
 
alter table articles
 	add CONSTRAINT articles_user_id_fk
 	FOREIGN KEY (user_id) REFERENCES users(id),
 	add CONSTRAINT articles_references_id_fk
 	FOREIGN KEY (references_id) REFERENCES references_list(id);
alter table articles
	add CONSTRAINT articles_author_id_fk
	FOREIGN key (author_id) REFERENCES authors(id);


alter table references_list
	add constraint references_list_user_id_fk
	FOREIGN KEY (user_id) REFERENCES users(id),
	add constraint references_list_source_type_id_fk
	FOREIGN KEY (source_type_id) REFERENCES source_types(id);

alter table bibliography
	add CONSTRAINT bibliography_user_id_fk
	FOREIGN KEY (user_id) references users(id) ON DELETE CASCADE,
	add CONSTRAINT bibliography_source_type_id
	FOREIGN KEY (source_type_id) REFERENCES source_types(id);

alter table favourites
	add CONSTRAINT favourites_user_id_fk
	FOREIGN KEY (user_id) references users(id) ON DELETE CASCADE,
	add CONSTRAINT favourites_source_type_id
	FOREIGN KEY (source_type_id) REFERENCES source_types(id);

alter table authors
	add CONSTRAINT authors_spec_id_fk
	FOREIGN KEY (spec_id) REFERENCES specialization(id);
/*
Индексы
*/
use pubchem;
create index companies_href_idx on companies(href);
create index companies_name_idx on companies(name);
create index users_company_id_idx on users(company_id);
create index users_email_idx on users(email);
create index users_first_name_idx on users(first_name);
create index users_last_name_idx on users(last_name);
create index posts_author_id_idx on posts(author_id);
create index posts_created_at_idx on posts(created_at);
create index posts_description_idx on posts(description(50));
create index posts_href_idx on posts(href);
create index posts_references_id_idx on posts(references_id);
create index posts_topic_idx on posts(topic);
create index posts_user_id_idx on posts(user_id);
create index references_list_href_idx on references_list(href);
create index references_list_name_idx on references_list(name);
create index references_list_publication_date_idx on references_list(publication_date);
create index references_list_source_id_idx on references_list(source_id);
create index references_list_source_type_id_idx on references_list(source_type_id);
create index references_list_user_id_idx on references_list(user_id);
create index media_file_name_idx on media(file_name);
create index media_file_size_mb_idx on media(file_size_mb);
create index articles_author_id_idx on articles(author_id);
create index articles_created_at_idx on articles(created_at);
create index articles_description_idx on articles(description(50));
create index articles_href_idx on articles(href);
create index articles_references_id_idx on articles(references_id);
create index articles_topic_idx on articles(topic);
create index articles_updated_at_idx on articles(updated_at);
create index articles_user_id_idx on articles(user_id);
create index favourites_source_type_id_source_id on favourites(source_type_id,source_id);
create index bibliography_source_type_id_source_id on bibliography(source_type_id,source_id);
create index references_list_source_type_id_source_id on references_list(source_type_id,source_id);

/*
 * Заготовки запросов
 */

use pubchem;
-- вывод всех статей, добавленных в библиографические списки пользователей;
select distinct b.user_id User_ID, s.source_type Type_math, a.topic Topic, concat(ath.first_name,ath.last_name) as Author_full_name
from bibliography b
join source_types s on b.source_type_id=s.id
join articles a on b.user_id=a.user_id
join authors ath on a.author_id=ath.id
having Type_math = 'Статьи'
order by User_ID, Type_math, topic, Author_full_name;



-- вывод 10 статей, которые наиболее часто оказываются в библиографических списках;
select distinct count(b.user_id) users_count, a.topic Topic, max(a.href)
from bibliography b
join source_types s on b.source_type_id=s.id
join articles a on b.user_id=a.user_id
join authors ath on a.author_id=ath.id
where s.source_type = 'Статьи'
group by Topic
order by users_count desc limit 10;


-- вывод 10 статей пользователей, которые загрузили больше всего файлов
-- можно использовать для выявления наиболее требовательных к памяти разделов;
-- например, сейчас видно, что больше всего файлов загружено в раздел Substance.
select a.topic Topic, max(a.href) Link_to_essay, max(p.name) Partitions, count(m.id) Media_downloaded
from media m, articles a, users u, partitions p
where a.user_id = m.user_id and m.user_id = u.id and p.id = m.partition_id
group by Topic
order by Media_downloaded desc limit 10;

-- триггер: добавление пользователя возможно только при его возрасте более 18 лет
create TRIGGER check_age_of_user before INSERT on users
for each row
BEGIN
	if year(now()) - year(new.birthday) < 18 then
	SIGNAL SQLSTATE '45000'
	SET MESSAGE_TEXT = 'You are not allowed to register here! Ask for your parents or tutor, please.';
	end if;
END;

-- триггер: при удалении пользователя его данные должны записаться в архивную таблицу
create TRIGGER user_archvator before DELETE on users
for each row
BEGIN
	insert into archive_user (login, first_name, last_name, email, registred_at, birthday, company_id)
	values  (OLD.login, OLD.first_name, OLD.last_name, OLD.email, OLD.registred_at, OLD.birthday, OLD.company_id);
END;

-- VIEW для просмотра авторов всех статей;
create view articles_and_authors as
select topic, concat(first_name,last_name) 'Author\'s full_name' from articles, authors where author_id = authors.id;
select * from articles_and_authors order by topic;
-- VIEW (используются вложенные запросы) для просмотра статистики: количество статей, постов, пользователей и загруженных файлов
create view statistics as
select (select count(id) from articles) as articles,
	(select count(id) from posts) as posts,
	(select count(id) from users) as users,
	(select count(id) from media) as media;
select * from statistics;


