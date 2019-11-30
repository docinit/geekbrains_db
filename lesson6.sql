-- Задание 1
/* Мои исправления:
 1. в строчке с примерами (первый вариант из предложений от студентов) "CREATE TABLE likes (  id INT UNSIGNED NOT AUTO_INCREMENT PRIMARY KEY..."
пропущено слово NULL, из-за чего скрипт неверно обрабатывается.

2. targe_id и target_type_id можно преобразовать в "словарь" (использовать JSON): target_id:target_type_id.
alter table likes add likes_json json;
тогда target_id и target_type_id можно убрать

3. для целей уменьшения размера (хотя, конечно, незначительно), можно учесть, что количество типов лайков не будет очень большим,
поэтому можно использовать tinyint
*/
use vk;
select * from messages;
/*
задание 2
Пусть задан некоторый пользователь. 
Из всех друзей этого пользователя найдите человека, который больше всех общался с нашим пользователем.

решение: смотрим, какому из пользователей больше всего писали другие пользователи - и выберем этого пользователя
для нашей задачи.
*/
select to_user_id, count(*) as count from messages group by  to_user_id order by count desc;
-- видно, какому пользователю писали больше всех (в моей БД - это пользователь 92)
select * from friendship where user_id=92;
-- но у него всего 1 друг; м.б. ему писал только он или не его друзья (спам?)
-- попробуем другого
select * from friendship where user_id=38;
-- то же самое...
-- ищем, у какого пользователя больше всего друзей, считаем отправленные им сообщения
select to_user_id, count(*) as count, (select count(*) from friendship where user_id=to_user_id) from messages group by  to_user_id order by count desc;
-- у всех пользователей по одному другу...
-- обновим информацию о них в таблице friendship, чтобы изменить данную ситуацию в тестовой базе.
select * from friendship;
update friendship set user_id = floor(1+rand()*100);
select to_user_id, count(*) as count, (select count(*) from friendship where user_id=to_user_id) as f_count from messages group by  to_user_id order by f_count desc, count desc;
-- после обновления в тестовой базе: максимальное кол-во сообщений (5 шт.) получил пользователь 65, который имеет 2 друзей.
-- попробуем проверить его.
select friend_id, (select count(*) from messages where from_user_id = friend_id) as message_numbers from friendship where user_id = 65;
-- у него всего 1 сообщение от друга с id 33;
-- получается, что пользователю 65 почти не общался с друзьями, а 4 из 5 сообщений, которые ему отправлялись, возможно, являются рекламными рассылками/спамом от других пользователей.


-- Задание 3. Подсчитать общее количество лайков, которые получили 10 самых молодых пользователей.
select sum(COUNT) as "Сумма лайков у 10 наиболее молодых пользователей" from (select user_id, count(*) as COUNT,
 (select timestampdiff(year, birthday, now()) as ages from profiles as p where p.user_id = l.user_id order by ages)
as age from likes as l
group by user_id limit 10) as RESULT;

-- Задание 4. Определить кто больше поставил лайков (всего) - мужчины или женщины?
select USER_SEX as "Ответ на вопрос \"Кто больше лайкал (мужчины или женищины)?\"",sum(COUNT) as "Количество оставленных лайков" from 
(select user_id, count(*) as COUNT,
 (select
		(case when sex = 'f' then 'женщины'
		when sex = 'm' then 'мужчины' end)
 from profiles as p where p.user_id=l.user_id) as USER_SEX from likes as l group by user_id)
 as RESULT group  by USER_SEX limit 1;
 
 -- Задание 5. Найти 10 пользователей, которые проявляют наименьшую активность в использовании социальной сети.
 -- Решение методом использования суммарного показателя по работе пользователя в сети (= количество отправленных сообщений + созданных постов + оставленных лайков + прикрепленных файлов + имеющихся друзей).
 select id, 
 (select count(from_user_id) from messages m where m.from_user_id = u.id)
 +
 (select count(user_id) from posts p where p.user_id = u.id)
 +
 (select count(user_id) from likes l where l.user_id = u.id)
 +
 (select count(user_id) from media med where med.user_id = u.id)
 +
 (select count(user_id) from friendship f where f.user_id = u.id)
 as activity
 from users u
 order by activity limit 10;