
-- 1.Проанализировать какие запросы могут выполняться наиболее часто в процессе работы приложения и добавить необходимые индексы.
 /*
 * В базе данных социальных сетей наиболее частыми запросами могут стать запросы, направленные на получение информации:
 * - о пользователях: фио, д.р., город,телефон, email - к тому же, их не придется часто обновлять + друзья
 * - о сообщениях: дата обращения (в списках сообщений все сообщения должны быть отсортированы, поэтому будут выполняться одни и те же соответствующие запросы),
 * 					заголовок (выводится каждый раз при открытии списка сообщений), информация поля "от кого".
 * - о файлах: дата создания, название, размер (?)
 * - о "лайках": саму таблицу likes, возможно, индексировать не нужно; все зависит от информации,
 * 				которую будут предалагать пользователям;
 * 				например, если выводить будут только кол-во лайков на каждого пользователя,
 * 				то есть смысл индексировать созданную для этого таблицу.
 * - о постах: дата написания (как в случае сообщений), кол-во лайков
 * - о группах: автор, название группы, дата создания (их не придется часто обновлять)
 */
-- Создаем индексы по указанным features
-- users
 create index users_first_name_idx on
users(first_name);

create index users_last_name_idx on
users(last_name);

create index users_email_idx on
users(email);

create index users_phone_idx on
users(phone);
-- profiles
 create index profiles_birthday_idx on
profiles(birthday);

create index profiles_hometown_idx on
profiles(hometown);
-- messages
 create index messages_from_user_id_idx on
messages(from_user_id);

create index messages_header_idx on
messages(header);

create index messages_created_at_idx on
messages(created_at);
-- media
 create index media_created_at_idx on
media(created_at);

create index media_filename_idx on
media(filename);

create index media_size_idx on
media(size);
-- likes + likes_for_users (a view of likes): просто пример реализации, набор столбцов нужно продумать отдельно
 create table likes_for_users_table (
select
	users.*,
	count(user_id) as Likes_number
from
	likes
right join users on
	likes.user_id = users.id
group by
	users.id ) ;

create index likes_for_users_table_Likes_number_idx on
likes_for_users_table(Likes_number);
-- posts
 create index posts_header_idx on
posts(header);

create index posts_user_id_idx on
posts(user_id);
-- communities
 create index communities_name_idx on
communities(name);

create index communities_created_at_idx on
communities(created_at);

create index communities_user_id_idx on
communities(user_id);

select
	*
from
	communities;

/* 2.Построить запрос, который будет выводить следующие столбцы:
имя группы
среднее количество пользователей в группах
самый молодой пользователь в группе
самый пожилой пользователь в группе
общее количество пользователей в группе
всего пользователей в системе
отношение в процентах (общее количество пользователей в группе / всего пользователей в системе) * 100
*/
-- 2.1 Без оконных функций
 use vk;

select
	c.name,
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
	limit 1) as min_age,
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
	count(u.id) as 'total per group',
	@a := (
	select
		count(user_id)
	from
		communities_users) as 'total users',
	round(count(u.id) / @a * 100, 2) as 'users per group, %'
from
	communities c
join communities_users cu on
	cu.community_id = c.id
join users u on
	u.id = cu.user_id
join profiles p on
	u.id = p.user_id
group by
	c.name
order by
	c.name;
-- 2.2 С оконными функциями
 select
	distinct c.name,
	max(c.user_id) over w as userid,
	sum(cu.user_id / cu.user_id) over (PARTITION by c.name) as summary,
	avg(cu.user_id / cu.user_id) over (PARTITION by c.name) as average,
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
-- 3
 /*
 * 3. (по желанию) Задание на денормализацию

Разобраться как построен и работает следующий запрос:
Найти 10 пользователей, которые проявляют наименьшую активность в использовании социальной сети.

SELECT users.id,
COUNT(DISTINCT messages.id) +
COUNT(DISTINCT likes.id) +
COUNT(DISTINCT media.id) AS activity
FROM users
LEFT JOIN messages
ON users.id = messages.from_user_id
LEFT JOIN likes
ON users.id = likes.user_id
LEFT JOIN media
ON users.id = media.user_id
GROUP BY users.id
ORDER BY activity
LIMIT 10;

Правильно-ли он построен?
Какие изменения, включая денормализацию, можно внести в структуру БД
чтобы существенно повысить скорость работы этого запроса?
*/
SELECT
	users.id,
	COUNT(DISTINCT messages.id) + COUNT(DISTINCT likes.id) + COUNT(DISTINCT media.id) AS activity
FROM
	users
LEFT JOIN messages ON
	users.id = messages.from_user_id
LEFT JOIN likes ON
	users.id = likes.user_id
LEFT JOIN media ON
	users.id = media.user_id
GROUP BY
	users.id
ORDER BY
	activity
LIMIT 10;
-- от DISTINCT можно избавится, т.к. подсчет идет по id - они и так не будут дублироваться.
 SELECT
	users.id,
	COUNT(messages.id) + COUNT(likes.id) + COUNT(media.id) AS activity
FROM
	users
LEFT JOIN messages ON
	users.id = messages.from_user_id
LEFT JOIN likes ON
	users.id = likes.user_id
LEFT JOIN media ON
	users.id = media.user_id
GROUP BY
	users.id
ORDER BY
	activity
LIMIT 10;

/*
 * В запросе используется таблица users - она позволяет перечислить всех пользователей в системе
 * после этого перечисления к ней добавляются столбцы из других таблиц (messages, likes, media),
 * в которых подсчитывается сумма строк, в которых встречается id каждого пользователя из таблицы users
 * (каждого, т.к. в users перечисляются все пользователи).
 * После этого выводится таблица с группировкой результатов по полю users.id
 * делается сортировка и ограничивается число записей для вывода.
 */
-- одно из решений - использовать уже готовые значения: так сократится кол-во расчетов
 create table messages_from_user (
select
	users.id,
	count(from_user_id) as number_of_messages
from
	messages
right join users on
	users.id = messages.from_user_id
group by
	users.id );

select
	*
from
	messages_from_user;

create table likes_from_user (
select
	users.id,
	count(user_id) as number_of_likes
from
	likes
right join users on
	users.id = likes.user_id
group by
	users.id );

select
	*
from
	likes_from_user;

create table media_from_user (
select
	users.id,
	count(user_id) as number_of_media
from
	media
right join users on
	users.id = media.user_id
group by
	users.id );

select
	*
from
	media_from_user;
-- итоговый запрос
 select
	users.id,
	number_of_messages + number_of_likes + number_of_media as activity
from
	users
left join media_from_user mfu on
	users.id = mfu.id
left join likes_from_user lfu on
	users.id = lfu.id
left join messages_from_user mesfu on
	users.id = mesfu.id
order by
	activity
limit 10;
