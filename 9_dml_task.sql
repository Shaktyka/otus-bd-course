
-- Напишите запрос по своей базе с регулярным выражением, 
-- добавьте пояснение, что вы хотите найти.

-- 1) Найти пользователя по инициалам 'ФИВ', он оставил негативный отзыв на сайте:

SELECT id, last_name, first_name, middle_name
FROM dicts.users
WHERE concat( last_name, ' ', first_name, ' ', middle_name ) SIMILAR TO 'Ф% И% В%';

-- 2) Найти всех пользователей, у которых в фамилиях одна или 2 буквы 'л'.
-- Был звонок от такого пользователя, фамилию не уточнили:

SELECT id, last_name, first_name, phone 
FROM dicts.users
WHERE last_name ~ '.*(л|лл).*'
AND first_name ~* '^артур$';

-- Напишите запрос по своей базе с использованием LEFT JOIN и INNER JOIN, 
-- как порядок соединений во FROM влияет на результат? Почему?

/*
    Исследуем связи товаров и категорий, тут используются 3 таблицы: товары, товары-категории, категории.

    Запрос c LEFT JOIN: получаем список товаров слева, список категорий справа и видим, что товару с id 4 категория не назначена.
    Здесь выборка происходит по "левой" таблице (products).
    Важно, что присоединять третью таблицу (categories) нужно также через LEFT JOIN, иначе в выборке
    окажутся только общие для всех 3х таблиц записи.
*/
SELECT 
    p.id as product_id,
    p.product,
    pc.product_id,
    pc.category_id,
    ct.category
FROM warehouse.products AS p
LEFT JOIN warehouse.product_category AS pc ON p.id = pc.product_id
LEFT JOIN warehouse.categories AS ct ON pc.category_id = ct.id;

/*
    Запрос с INNER JOIN: получаем только "общие" записи, имеющиеся во всех 3х таблицах 
    и не видим товары без категорий.
*/
SELECT 
    p.id as product_id,
    p.product,
    pc.product_id,
    pc.category_id,
    ct.category
FROM warehouse.products AS p
INNER JOIN warehouse.product_category AS pc ON p.id = pc.product_id
LEFT JOIN warehouse.categories AS ct ON pc.category_id = ct.id;

/*
    Если же в первом запросе таблицу категорий присоединить через RIGHT JOIN,
    то можно увидеть категории, не назначенные ни для одного товара. Это тоже бывает полезно.
    Таким образом, способ соединения таблиц важен.
*/
SELECT 
    p.id as product_id,
    p.product,
    pc.product_id,
    pc.category_id,
    ct.category
FROM warehouse.products AS p
LEFT JOIN warehouse.product_category AS pc ON p.id = pc.product_id
RIGHT JOIN warehouse.categories AS ct ON pc.category_id = ct.id;

/*
    А вот в случае соединений таблиц через перечисление во FROM c условием в WHERE, порядок 
    соединения таблиц не важен, т.к. в этом случае выборка работает как INNER JOIN: 
    выберутся только общие для всех трёх таблиц записи:
*/
SELECT 
    p.id as product_id,
    p.product,
    pc.product_id,
    pc.category_id,
    ct.id,
    ct.category
FROM warehouse.categories AS ct, warehouse.products AS p, warehouse.product_category AS pc
WHERE pc.category_id = ct.id AND p.id = pc.product_id;

-- Напишите запрос на добавление данных с выводом информации о добавленных строках.

INSERT INTO dicts.object_types (object_type) VALUES
('Пользователи'),
('Поставщики'),
('Заказы') 
RETURNING *;

-- Напишите запрос с обновлением данные используя UPDATE FROM.

-- UPDATE здесь - это обновление таблицы склада (товары в наличии) в результате поставок по № поставки, например.
-- Учесть UPSERT


UPDATE
  <table1>
SET
  customer=subquery.customer,
  address=subquery.address,
  partn=subquery.partn
FROM
  (
    SELECT
      address_id, customer, address, partn
    FROM  table_name
  ) AS subquery
WHERE
  dummy.address_id=subquery.address_id;

UPDATE alias1
SET column1 = alias2.value1
FROM table1 as alias1
JOIN table2 as alias2 ON table1.id = table2.id
WHERE alias1.column2 = value2; 

-- Напишите запрос для удаления данных с оператором DELETE 
-- используя join с другой таблицей с помощью using.

-- Удаление товаров определённого производителя со склада (таблица warehouse) 
-- в результате отзыва поставки поставщиком, например:

DELETE FROM table_name row1 
USING table_name row2 WHERE condition;

-- Приведите пример использования утилиты COPY (по желанию)

-- COPY служит для перемещения данных между таблицами PostgreSQL и файлами
-- Варианты использования:
-- 1) выгрузить данные из таблицы в файл в файловой системе;
-- 2) загрузить данные из файла в таблицу.
-- Используется для загрузки внешних данных в БД или выгрузки каких-то данных из БД. 

-- Привожу команды для использования в среде psql:

-- Пример 1: загрузить в БД данные из файла CSV (файлы XLS предварительно нужно преобразовать в CSV)
\copy warehouse.manufacturers(manufacturer,site_link,logo_link,reg_date) 
FROM '/Users/elena/Desktop/projects/otus-bd-course/files/Производители_кофе.csv' 
DELIMITER ';' 
CSV HEADER;

-- Пример 2: выгрузить данные из таблицы в файл формата CSV 
\copy warehouse.manufacturers TO '/Users/elena/Desktop/projects/otus-bd-course/files/manufacturers.csv' 
DELIMITER ';' 
CSV HEADER;

-- Также можно выгрузить результаты запроса:
\copy (SELECT * FROM warehouse.manufacturers) to '/Users/elena/Desktop/projects/otus-bd-course/files/manufacturers_1.csv' with csv;
