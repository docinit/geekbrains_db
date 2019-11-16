use vk;
show tables;
-- ТАБЛИЦА USERS
select * from users limit 10;
-- id - данные соответствуют условиям; являются уникальными; все ОКALTER
-- first_name and last_name - все OK, данные соответствуют условиям;
-- email - данные соответствуют условиям: содержатся примеры возможных реальных email
-- phone - данные м.б. нормальные, но форматированы по-разному; нужно их немного исправить
update users set phone=CONCAT('+',FLOOR(rand()*(9999999999-1000000000+1))+1000000000);
-- created_at содержит удовлетворительные значения полей; можно оставить как есть;
-- только надо проверить размах (минимальные и максимальные значения)
select min(created_at) from users;
-- минимальное значение = '1971-07-22 23:39:07'
select max(created_at) from users;
-- максимальное значение = '2019-08-22 19:29:08'
-- также надо проверить, чтобы значение created_at не было больше, чем updated_at на каждой строке
-- т.е. чтобы обновление не было раньше создания
select created_at, updated_at from users where created_at>updated_at;
-- в результате выполнения запроса видно, что таких полей нет
-- однако видно, что updated_at имеет одни и те же значения во всех строках;
-- это может быть правдой, но выглядит не совсем естественно;
select updated_at from users;
-- сделаем дату update_at равной случайной дате в интервале от created_at до + 1 года;
update users set updated_at = created_at + interval FLOOR(rand()*(365))+1 day;
-- проверим еще раз отношения created_at и updated_at
select created_at, updated_at from users where created_at>updated_at;
-- ошибок нет (т.к. нет данных, удовлетворяющих условиям);
-- проверим максимальное значение updated_at - оно не должно быть больше настоящего времени;
select created_at, updated_at from users where updated_at > current_timestamp();
-- было найдено 1 значение; изменим его на текущее время - так будет более естественно
update users set updated_at = current_timestamp() where updated_at>current_timestamp();
-- теперь подобных ошибок быть не должно;
select created_at, updated_at from users where updated_at > current_timestamp();
-- их нет;
-- ТАБЛИЦА PROFILES
select * from profiles limit 20;
-- столбец id выглядит как и следует ожидать;
-- столбец sex - проблем не обнаружено;
-- столбец birthday - даты правильно сформированы;
-- но они должны быть не больше текущей даты (таких нет - см код ниже) + не больше даты создания профилей;
select birthday from profiles where birthday > curdate();
select birthday, user_id, id, date(created_at) from profiles, users where birthday>created_at and user_id=id;
-- найдено очень много (40) значений; их нужно исправить; например, можно установить дату рождения как минимум за 18 лет до создания профиля;
update profiles set birthday = (select date(created_at) - interval FLOOR(rand()*(65-1))+18 year from users where user_id=id);
-- теперь ошибок нет; проверяем:
select birthday, user_id, id, created_at from profiles, users where birthday>created_at and user_id=id;
-- видно, что самый старший user родился в 19 веке; такие даты можно использовать для проверки юзеров с маркером "умер", если это будет использоваться.
select * from profiles limit 100;
-- поле hometown содержит названия автоматически сгенерированных названий городов; оставим как есть;
-- photo_id содержит указатель на id из таблицы photo или media

-- ТАБЛИЦА MESSAGES
select * from messages;
-- в данной таблице id выглядит соответствующим образом;
-- поле from_user выглядит отсортированным; каждому user'у соответствует одно сообщение; такое может быть, тем  более - в тестовой базе;
-- можно оставить как есть;
-- поле to_user_id содержит случайные числа от 1 до 100; получилось, что каждый пользователь написал кому-то сообщение;
select from_user_id, to_user_id from messages where from_user_id=to_user_id;
-- видно, что в одном случае пользователь написал сообщение сам себе; такое возможно, но при желании данную "ошибку" можно исправить,
-- как было предложено на уроке
update messages set
	to_user_id = FLOOR(1+(rand()*100)),
    from_user_id = FLOOR(1+(rand()*100));
-- теперь все значения пересчитались, совпадений (писем самому себе) нет;
-- поле created_at должно быть заполнено датой более поздней, чем создание аккаунта; исправляю так же, как раньше;
select from_user_id from messages as m, users as u where m.created_at<u.created_at and m.from_user_id=u.id;
-- 44 строки содержат сообщения, созданные ранее создания аккаунта; исправляем прежним способом;
update messages set created_at = (select created_at + interval FLOOR(rand()*365) day from users where from_user_id=id);

-- В таблице media_types использованы названия типов медиа-контента; на данном этапе разработки это невозможно использовать;
-- будем использовать вариант из урока
select * from media_types;
truncate media_types;
insert into media_types (name) values ('audio'), ('photo'), ('video');
-- теперь в таблице хранятся id, указывающие на определенный тип файлов; их можно использовать в следующей таблице media;

select * from media;
-- поле id сформировано правильно (авто-инкремент);
-- поле media_type_id должно ссылаться на значения в таблице media_types, но части значений там просто нет;
-- заполняю их правильными (возможными) значениями, содержащимися в таблице media_types
update media set media_type_id = floor(rand()*3+1);
-- теперь там только те значения, которые есть в таблице media_types
select * from media;
-- столбец user_id содержит значения id пользователей, которые есть в базе данных (от 1 до 100) - ничего менять не надо
-- столбец filename содержит автоматически сгенерированные названия файлов; все значения текстовые и допустимые - ничего не меняю
-- столбец size содержит данные о размере файл; предположим, что это - килобайты (просто запомним);
-- в столбце metadata содержится некое текстовое (сгенерированное) описание; может быть, для мета-данных о сайте такое подойдет, но для файлов
-- применим метод, который был на уроке
update media set metadata = concat('{"',filename,'":"',size,'Kb,',created_at,',',updated_at,'"}');
alter table media modify metadata JSON;
-- снова нужно проверить, что created_at не позже updated_at и created_at в данной таблице - не раньше, чем создан пользователь;
select created_at, updated_at from media where created_at>updated_at;
-- хорошо, что таких нет; проверяем следующую часть:
select user_id from media as m, users as u where m.created_at<u.created_at and m.user_id=u.id;
-- получен список из 58 пользователей; исправим путем обновления значений сразу для всех, как в предыдущем примере;
update media set created_at = (select created_at + interval FLOOR(rand()*365) day from users where user_id=id);
-- теперь таких записей нет:
select user_id from media as m, users as u where m.created_at<u.created_at and m.user_id=u.id;

-- ТАБЛИЦА FRIENDSHIP
select * from friendship;
-- видимых проблем с user_id нет; в поле friend_id содержатся отличные от user_id значения;
-- status_id ссылается на id в таблице status (еще не создана) - теоретически значения id не должны быть ограничены, так что пока проблем нет.
-- проверяем даты;
select requested_at, confirmed_at from friendship where requested_at>confirmed_at;
-- получен список из 47 случаев, когда запрос дружбы происходил после подтверждения; такого быть не должно; исправляем;
update friendship set confirmed_at = requested_at + interval floor(rand()*365)+1 day;
-- проверяем еще раз - таких значений больше нет;
select requested_at, confirmed_at from friendship where requested_at>confirmed_at;
-- проверяем существование пользователя на момент запроса дружбы
select user_id from friendship as f, users as u where f.requested_at<u.created_at and f.user_id=u.id;
-- получили 62 подобных случая
update friendship set requested_at = (select created_at + interval FLOOR(rand()*365) day from users where user_id=id);
-- проверяем еще раз то же самое условие; подобных случае больше нет;
-- проверяем существование потенциального друга на момент запроса дружбы и ее подтверждения
select friend_id from friendship as f, users as u where f.confirmed_at<u.created_at and f.friend_id=u.id;
-- получено 57 подобных вариантов (когда "друга" еще нет, а дружбу уже запросили)
update friendship set confirmed_at = (select created_at + interval FLOOR(rand()*365) day from users where friend_id=id);
-- такого больше нет
select friend_id from friendship as f, users as u where f.confirmed_at<u.created_at and f.friend_id=u.id;
-- но надо снова "синхронизировать" время запроса дружбы и ее подтверждения - опять есть 49 случаев подтверждения дружбы до запроса
select requested_at, confirmed_at from friendship where requested_at>confirmed_at;
# теперь сделаем наоборот - requested в зависимости от confirmed
update friendship set requested_at = confirmed_at - interval floor(rand()*365)+1 day;
-- и все равно полной синхронизации пока не добиться, т.к. пользователи "посылают" сообщения случайным пользователям;

-- ТАБЛИЦА communities
select * from communities;
-- тут никаких видимых проблем: случайные названия + автоматически назначенный id;

-- ТАБЛИЦА communities users;
select * from communities_users;
-- видимых проблем нет: community_id указывает на существующие id  из таблицы communities;
-- а user_id - на поле id в таблице users;

-- создаем таблицу photo - как в уроке
-- id - как везде: serial, primary key
-- media_type_id - нужно не на media_type_id, а media_id - ссылка на id в таблице media
-- дополнительно нужно сделать проверку на то, что media_id указывает на файл с id из media_types, соответствующим типу  photo
-- user_id - ссылка на user в данном случае излишняя, т.к. она есть в таблице media; авторство и принадлежность
-- кому-то другому может не мешать ссылаться на этот файл и делать фотографией профиля, но это, в общем-то не хорошо;
-- filename - тоже лишнее по той же причине
-- size - то же самое, как и поля с датами создания и обновления.

-- таким образом, photo-таблицу можно не создавать, а сделать ссылку на файл, на который и будет указывать 
-- столбец photo_id в таблице profiles

ALTER TABLE users ADD COLUMN is_banned BOOLEAN AFTER phone;
ALTER TABLE users ADD COLUMN is_active BOOLEAN DEFAULT  TRUE AFTER is_banned;

UPDATE users SET is_banned = TRUE WHERE id IN (12, 56, 66, 83);
UPDATE users SET is_active = FALSE WHERE id IN (8, 32, 77, 98) or is_banned=TRUE;
INSERT INTO friendship_statuses VALUES (DEFAULT, "Rejected");

ALTER TABLE communities ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP AFTER name;
ALTER TABLE communities ADD COLUMN is_closed BOOLEAN AFTER created_at;
ALTER TABLE communities ADD COLUMN closed_at TIMESTAMP AFTER is_closed;
ALTER TABLE communities add column user_id int unsigned;
update communities set user_id = floor(rand()*100+1);
UPDATE communities SET is_closed = TRUE WHERE id IN (3, 14, 27, 56);
UPDATE communities SET closed_at = NOW() WHERE is_closed IS TRUE;
select * from communities;

ALTER TABLE communities_users ADD column is_banned BOOLEAN AFTER user_id;
ALTER TABLE communities_users ADD column is_admin BOOLEAN AFTER user_id;
UPDATE communities_users SET is_banned = TRUE WHERE user_id IN (66, 87);
UPDATE communities_users SET is_admin = TRUE WHERE user_id IN (12,56,74,66);

ALTER TABLE messages ADD COLUMN header VARCHAR(255) AFTER to_user_id;
UPDATE messages SET header = SUBSTRING(body, 1, 50);
ALTER TABLE messages ADD column attached_media_id INT UNSIGNED AFTER body;
UPDATE messages SET attached_media_id = (
  SELECT id FROM media WHERE user_id = from_user_id LIMIT 1
);

CREATE TABLE relations (
  id serial PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL,
  relative_id INT UNSIGNED NOT NULL,
  relation_status_id INT UNSIGNED NOT NULL
);

CREATE TABLE relation_statuses (
  id serial PRIMARY KEY,
  name VARCHAR(100)
);

INSERT INTO relation_statuses (name) VALUES 
  ('son'),
  ('daughter'),
  ('mother'),
  ('father'),
  ('wife'),
  ('husband'),
  ('grandparent')
;

INSERT INTO relations 
  SELECT 
    id*floor(rand()*90+1), 
    FLOOR(1 + (RAND() * 100)), 
    FLOOR(1 + (RAND() * 100)),
    FLOOR(1 + (RAND() * 7)) 
  FROM relation_statuses;
truncate relations;
select * from relations;
select * from relation_statuses;
select * from messages;
select * from communities_users;
select * from communities;
select * from users;

-- Сервис-образец для курсовой работы: смотрю на различные базы данных медицинских статей; например, pubmed, elibrary (https://www.ncbi.nlm.nih.gov/pubmed/,
-- и https://elibrary.ru/defaultx.asp)