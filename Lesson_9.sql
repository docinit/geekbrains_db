
use shop;
-- I-- 
/*В базе данных shop и sample присутствуют одни и те же таблицы, учебной базы данных. 
 * Переместите запись id = 1 из таблицы shop.users в таблицу sample.users. Используйте транзакции.
 */
start TRANSACTION;
drop database if exists sample;
create database sample;
create table sample.users (id bigint(20) UNSIGNED AUTO_INCREMENT PRIMARY key, name varchar(255), birthday DATE, created_at DATETIME, updated DATETIME);

set @id = 1;
set @name = (select name from shop.users where id=@id);
set @birthday = (select birthday from shop.users where id=@id);
set @created_at = (select created_at from shop.users where id=@id);
set @updated = (select updated from shop.users where id=@id);
insert into sample.users (name,birthday, created_at, updated) values
(
@name, @birthday, @created_at, @updated
);
delete from users where id = 1;
COMMIT;
select * from sample.users;
select * from users;

-- 2 Создайте представление, которое выводит название name товарной позиции из таблицы products
-- и соответствующее название каталога name из таблицы catalogs.
-- 2.1
prepare prod_name_cat from 'select p.name as product, c.name as catalog from products p, catalogs c where p.catalog_id=c.id';
execute prod_name_cat;
-- 2.2
create view prod_view as
select p.name as product, c.name as catalog from products p join catalogs c on p.catalog_id=c.id;
select * from prod_view;

-- 3 Пусть имеется таблица с календарным полем created_at.
-- В ней размещены разряженые календарные записи за август 2018 года '2018-08-01', '2016-08-04', '2018-08-16' и 2018-08-17.
-- Составьте запрос, который выводит полный список дат за август, выставляя в соседнем поле значение 1,
-- если дата присутствует в исходном таблице и 0, если она отсутствует.
-- 3.1
drop table if exists data_rows;
create table data_rows (id int AUTO_INCREMENT PRIMARY KEY, data_values date, assign_clue bool);
insert into data_rows (data_values) values ('2018-08-01'), ('2018-08-04'), ('2018-08-16'), ('2018-08-17');
select * from data_rows;
-- создаем процедуру
create procedure date_proc()
BEGIN
	set @data = '2018-08-01';
	set @first_day = date(concat(year(@data),'-',month(@data),'-','01'));
	set @next_day = @first_day+interval 1 day;
	if @first_day in (select data_values from data_rows) then update data_rows set assign_clue = TRUE where data_values=@first_day;
	end if;
	if @last_day in (select data_values from data_rows) then update data_rows set assign_clue = TRUE where data_values=@last_day;
	end if;
	while @next_day between @first_day and @last_day do
	if @next_day in (select data_values from data_rows) then update data_rows set assign_clue = TRUE where data_values=@next_day;
	ELSE insert into data_rows (data_values, assign_clue) values (@next_day, FALSE);
	end if;
	set @next_day = @next_day+interval 1 day;
	end WHILE;
END;
-- запуск процедуры
call date_proc();
-- проверка результата
select * from data_rows;

-- 3.2
drop table if exists date_table;
create table date_table (id int AUTO_INCREMENT PRIMARY KEY, data_values date, assign_clue bool);
insert into date_table (data_values) values ('2018-08-01'), ('2018-08-04'), ('2018-08-16'), ('2018-08-17');
update date_table set assign_clue = 1;
set @data_i = date('2018-07-31');
-- повторить 30 раз
set @data_i = @data_i + interval 1 day;
insert into date_table (data_values, assign_clue) select @data_i + interval 1 day, 0
where not exists (select data_values from date_table having data_values = @data_i + interval 1 day)
and @data_i < date('2018-08-31');
-- закончить повторения
select * from date_table;
select @data_i;


-- II -- 
/* 1 Создайте двух пользователей которые имеют доступ к базе данных shop. 
 *Первому пользователю shop_read должны быть доступны только запросы на чтение данных,
 * второму пользователю shop — любые операции в пределах базы данных shop.
 */
create user shop_u1 identified with sha256_password by 'uU%12345678';
create user shop_u2 identified with sha256_password by 'uU%22345678';

GRANT ALL PRIVILEGES ON shop.* TO 'shop_user1'@'localhost'; -- не работает на моем сервере, хотя по описанию, вроде, должно срабатывать.

-- III-- Практическое задание по теме “Хранимые процедуры и функции, триггеры"
/* 1.  Создайте хранимую функцию hello(), которая будет возвращать приветствие,
 * в зависимости от текущего времени суток.
 * С 6:00 до 12:00 функция должна возвращать фразу "Доброе утро",
 * с 12:00 до 18:00 функция должна возвращать фразу "Добрый день",
 * с 18:00 до 00:00 — "Добрый вечер", с 00:00 до 6:00 — "Доброй ночи".
 */
drop function if exists hello;
create function hello ()
returns text deterministic
BEGIN
	RETURN
	case when hour(now()) > 5 and hour(now()) < 12 then 'Доброе утро'
	when hour(now()) > 11 and hour(now())<18 then 'Добрый день'
	when hour(now()) > 17 and hour(now())<24 then 'Добрый вечер'
	END;
end

/* 2. В таблице products есть два текстовых поля: name с названием товара и description с его описанием.
 * Допустимо присутствие обоих полей или одно из них. Ситуация, когда оба поля принимают неопределенное значение NULL неприемлема.
 * Используя триггеры, добейтесь того, чтобы одно из этих полей или оба поля были заполнены.
 * При попытке присвоить полям NULL-значение необходимо отменить операцию.
 */

create TRIGGER check_name_or_description_is_filled after insert on products
for each row
BEGIN
	if new.name is NULL and new.description is NULL then
	delete from products where name = new.name;
	end if;
END

/* 3. Напишите хранимую функцию для вычисления произвольного числа Фибоначчи.
 * Числами Фибоначчи называется последовательность в которой число равно сумме двух предыдущих чисел.
 * Вызов функции FIBONACCI(10) должен возвращать число 55.
 */
create PROCEDURE FIBONACCI (in value int)
BEGIN
	drop table if exists temp_f;
	create TEMPORARY table temp_f (ii int, ff int);
-- первые значения уже известны: первое (ноль) и второе (1) числа вычислять не нужно - просто сохраним их
	insert into temp_f values (0,0),(1,1);
	set @i = 1;
	while @i < value do
	-- подавляем вывод select, чтобы не занимать экран
	set @f = (select sum(ff) from (select ff from temp_f order by ff desc limit 2) as temp_f_second);
	insert into temp_f values (@i,@f);
	set @i=@i+1;
	end while;
	select ff from temp_f order by ff desc limit 1;
END



