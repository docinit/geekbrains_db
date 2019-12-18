use shop3;
-- 1
/*Создайте таблицу logs типа Archive. Пусть при каждом создании записи в таблицах users,
 * catalogs и products в таблицу logs помещается время и дата создания записи,
 * название таблицы, идентификатор первичного ключа и содержимое поля name.
*/
show tables;
select * from users;
select * from catalogs;
select * from products;
select * from logs;
desc users;
drop table if exists logs;
create table logs (
	id int AUTO_INCREMENT PRIMARY key not null,
	added_at_date DATE not null,
	added_at_time time not null,
	table_header varchar(15) not null,
	table_id int not null,
	table_name varchar(255) not null
) comment = 'Архив' ENGINE = Archive;

-- создаем 3 триггера для каждой таблицы из задания; в них определяем переменные - и вызываем процедуру внесения значений в архивную таблицу;
-- если таблицы будут сохранять свою структуру и названия столбцов, это позволит унифицировать процесс архивирования (и м.б. другие операции)
-- первый
create trigger archive_trigger_users AFTER insert on users
for each ROW
BEGIN
	set @tablename = 'users';
	set @newid = new.id;
	set @newname = new.name;
	call archivator(@tablename,@newid,@newname);
end//
-- второй
create trigger archive_trigger_catalogs AFTER insert on catalogs
for each ROW
BEGIN
	set @tablename = 'catalogs';
	set @newid = new.id;
	set @newname = new.name;
	call archivator(@tablename,@newid,@newname);
end//
-- третий
create trigger archive_trigger_products AFTER insert on products
for each ROW
BEGIN
	set @tablename = 'products';
	set @newid = new.id;
	set @newname = new.name;
	call archivator(@tablename,@newid,@newname);
end//
-- процедура, которая вызывается в каждом из триггеров и сохраняет заданные столбцы в таблицу logs
create procedure archivator(in tablename text, newid int, newname varchar(255))
BEGIN
	insert into logs (added_at_date,added_at_time,table_header,table_id,table_name) VALUES (date(now()),time(now()),tablename,newid,newname);
END//


-- проверка работы триггеров
insert into users (name,birthday_at) values ('Таня','1989-10-01');
insert into products (name,catalog_id) values ('Еще один Самый лучший процессор',7);
insert into catalogs (name) values ('2 - Лучшие процессоры');
select * from users;
select * from catalogs;
select * from products;
select * from logs;




-- 2
/*(по желанию) Создайте SQL-запрос, который помещает в таблицу users миллион записей.
*/
-- создание таблицы, которая будет заполняться
drop table if exists user2;
create table user2 (id int PRIMARY KEY UNIQUE not null AUTO_INCREMENT,
user_name varchar(10),
user_lastname varchar(10),
birthday date
);
-- создание процедуры для заполнения таблицы
create procedure million_rows()
begin
drop table if EXISTS temp1;
create TEMPORARY table temp1  (id int PRIMARY KEY UNIQUE not null AUTO_INCREMENT,
user_name varchar(10),
user_lastname varchar(10),
birthday date
);
set @i = 0;
while @i < 1000000 do
	insert into temp1 (user_name, user_lastname,birthday) values (
	right(MD5(rand()), 10),
	right(MD5(rand()), 10),
	date(concat(round(1950+rand()*50,0),'-', round(1+rand()*11,0), '-', round(1+rand()*27,0))));
	set @i = @i+1;
end while;
insert into user2 (select * from temp1);
end//

select * from user2;
select * from temp1;




/*
PS
из заданий к 10 уроку: исправлены средние значения и подсчет суммы
*/

-- 2.2 С оконными функциями
 select
	distinct c.name,
	c.user_id as author,
	count(cu.user_id / cu.user_id) over (PARTITION by c.name) as summary,
	count(cu.user_id) over () / count(c.id) over () as average,
	(
	select
		first_name
	from
		users
	join profiles on
		users.id = profiles.user_id
	where
		birthday = (
		select
			min(birthday)
		from
			profiles
		where
			profiles.user_id in (
			select
				user_id
			from
				communities_users
			where
				community_id = cu.community_id))
	limit 1) as max_age,
	(
	select
		first_name
	from
		users
	join profiles on
		users.id = profiles.user_id
	where
		birthday = (
		select
			max(birthday)
		from
			profiles
		where
			profiles.user_id in (
			select
				user_id
			from
				communities_users
			where
				community_id = cu.community_id))
	limit 1 ) as min_age,
	@a := count(u.id) over w as 'total per group',
	count(u.id) over () as total,
	round(count(u.id) over w / count(u.id) over () * 100, 2) as '%%'
from
	(communities c
join communities_users cu on
	cu.community_id = c.id
join users u on
	cu.user_id = u.id
join profiles p on
	p.user_id = u.id ) window w as (PARTITION by cu.community_id)
order by
	c.name;
	


-- II. NoSQL
/*
 * 1. В базе данных Redis подберите коллекцию для подсчета посещений с определенных IP-адресов.
 */
-- 1) создание множества с перечислением ip посетивших пользователей.
-- множество гарантирует уникальность записей;
-- значения записей увеличивается при помощи hincrby name_множества key 1_(шаг увеличения)
-- пример
hincrby visitors_ip 127.100.100.1 1
/*
	127.0.0.1:6379> hincrby visitors2 127.100.100.1 1
	(integer) 1
	127.0.0.1:6379> hincrby visitors2 127.100.100.1 1
	(integer) 2
	127.0.0.1:6379> hincrby visitors2 127.100.100.1 1
	(integer) 3
	127.0.0.1:6379> hincrby visitors2 127.100.100.1 1
	(integer) 4
	127.0.0.1:6379> hincrby visitors2 127.100.100.1 1
	(integer) 5
	127.0.0.1:6379> hincrby visitors2 127.100.100.1 1
	(integer) 6
	127.0.0.1:6379> hincrby visitors2 127.100.195.1 1
	(integer) 1
*/
hgetall visitors2
/*
	1) "127.100.100.1"
	2) "6"
	3) "127.100.195.1"
	4) "1"
*/


/*
 * 2. При помощи базы данных Redis решите задачу поиска имени пользователя по электронному адресу и наоборот, поиск электронного адреса пользователя по его имени.
 * 
 */
-- поиск осуществляется по ключу: в ключе сохраняем имя - по нему получаем email
127.0.0.1:6379> hmset users_mail user1 user1@mail.ru user2 user2@mail.ru user3 user3@mail.ru
OK
127.0.0.1:6379> hget users_mail user1
"user1@mail.ru"
-- в ключе сохраняем email - по нему получаем имя
127.0.0.1:6379> hmset users_mail2 user1@mail.ru user1 user2@mail.ru user2 user3@mail.ru user3
OK
127.0.0.1:6379> hget users_mail2 user1@mail.ru
"user1"
-- если запросом сразу создавать 2 множества, в одном из которых сохранять в качестве ключа имя, а в другом - email, то в зависимости от цели поиска, можно обращаться к первому или второму множеству.


/*
 * Организуйте хранение категорий и товарных позиций учебной базы данных shop в СУБД MongoDB.
 */
-- 1) создаем новую базу данных shop
> use shop
switched to db shop
 -- 2) добавляем данные в базу данных
> db.shop.insert({product_name: 'Intel Core i3-8100', category: 'Процессоры'})
> db.shop.insert({product_name: 'Intel Core i5-7400', category: 'Процессоры'})
> db.shop.insert({product_name: 'AMD FX-8320E', category: 'Процессоры'})
> db.shop.insert({product_name: 'AMD FX-8320', category: 'Процессоры'})
> db.shop.insert({product_name: 'ASUS ROG MAXIMUS X HERO', category: 'Материнские платы'})
> db.shop.insert	({product_name: 'Gigabyte H310M S2H', category: 'Материнские платы'})
> db.shop.insert({product_name: 'MSI B250M GAMING PRO', category: 'Материнские платы'})
> db.shop.find()
{ "_id" : ObjectId("5df97426708fa205bc4d4f8b"), "product_name" : "Intel Core i3-8100", "category" : "Процессоры" }
{ "_id" : ObjectId("5df97432708fa205bc4d4f8c"), "product_name" : "Intel Core i5-7400", "category" : "Процессоры" }
{ "_id" : ObjectId("5df9744f708fa205bc4d4f8d"), "product_name" : "AMD FX-8320E", "category" : "Процессоры" }
{ "_id" : ObjectId("5df97460708fa205bc4d4f8e"), "product_name" : "AMD FX-8320", "category" : "Процессоры" }
{ "_id" : ObjectId("5df97483708fa205bc4d4f8f"), "product_name" : "ASUS ROG MAXIMUS X HERO", "category" : "Материнские платы" }
{ "_id" : ObjectId("5df9749c708fa205bc4d4f90"), "product_name" : "Gigabyte H310M S2H", "category" : "Материнские платы" }
{ "_id" : ObjectId("5df974b5708fa205bc4d4f91"), "product_name" : "MSI B250M GAMING PRO", "category" : "Материнские платы" }
-- Каждому товару можно добавить дополнительный признак, например, цену.
> db.shop.update({product_name: 'MSI B250M GAMING PRO', category: 'Материнские платы'},{$set{price:5060}})











