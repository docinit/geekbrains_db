use shop3;
-- 1 задание.
-- Составьте список пользователей users, которые осуществили хотя бы один заказ orders в интернет магазине.
SELECT 
    u.name AS name
FROM
    users u,
    orders o
WHERE
    u.id = o.user_id
GROUP BY name;


-- 2 задание
-- Выведите список товаров products и разделов catalogs, который соответствует товару.
SELECT 
    p.name, c.name
FROM
    products p,
    catalogs c
WHERE
    p.catalog_id = c.id;

-- 3 задание
-- (по желанию) Пусть имеется таблица рейсов flights (id, from, to) и таблица городов cities (label, name).
-- Поля from, to и label содержат английские названия городов, поле name — русское.
-- Выведите список рейсов flights с русскими названиями городов.
CREATE TABLE flights (
    id SERIAL PRIMARY KEY,
    `from` VARCHAR(15),
    `to` VARCHAR(15)
);
insert into flights (`from`, `to`)
values
('moscow', 'omsk'),
('novgorod','kazan'),
('irkutsk','moscow'),
('omsk','irkutsk'),
('moscow','kazan');
SELECT 
    *
FROM
    flights;

CREATE TABLE cities (
    label VARCHAR(15) PRIMARY KEY,
    name VARCHAR(15)
);

insert into cities values
('moscow','Москва'),
('irkutsk','Иркутск'),
('novgorod','Новгород'),
('kazan','Казань'),
('omsk','Омск');

SELECT 
    *
FROM
    cities;

SELECT 
    flights_table.id, from_city, to_city
FROM
    flights AS flights_table,
    (SELECT 
        f.id, c.name AS from_city
    FROM
        cities c, flights f
    WHERE
        c.label = f.from) AS from_table,
    (SELECT 
        f.id, c.name AS to_city
    FROM
        cities c, flights f
    WHERE
        c.label = f.to) AS to_table
WHERE
    flights_table.id = from_table.id
        AND flights_table.id = to_table.id;