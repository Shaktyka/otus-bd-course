
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
    Запрос с INNER JOIN: получаем только "общие" записи, имеющиеся во всех 3х таблицах и не видим товары без категорий.
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
    выберутся только общие для всех трёх таблиц записи. Но это актуально только для случаев, 
    когда все таблицы в запросе соединены между собой, как здесь:
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

/*
    Если же в запросе соединяются 3 или более таблиц, и JOIN или WHERE соединяют только 2 из них, 
    то произойдёт CROSS JOIN соединённых таблиц с неприсоединённой таблицей, 
    и в результате получится декартово произведение всех строк.
*/
-- Корректный запрос:
select 
    d.supplier_id, 
    d.pricelist_id,
    di.delivery_id, 
    di.upc, 
    di.amount
FROM warehouse AS w, deliveries AS d, delivery_items AS di
WHERE 
    di.delivery_id = d.id 
    AND w.articul = di.upc
    AND w.pricelist_id = d.pricelist_id;

-- Запрос, где получился CROSS JOIN:
select 
    d.supplier_id, 
    d.pricelist_id,
    di.delivery_id, 
    di.upc, 
    di.amount
FROM deliveries AS d, delivery_items AS di, warehouse AS w
WHERE 
    di.delivery_id = d.id;

-- Напишите запрос на добавление данных с выводом информации о добавленных строках.

INSERT INTO dicts.object_types (object_type) VALUES
('Пользователи'),
('Поставщики'),
('Заказы') 
RETURNING *;

-- Напишите запрос с обновлением данные используя UPDATE FROM.

-- UPDATE здесь - это обновление таблицы склада после поставки по № поставки и идентификатору поставщика
-- С CTE:
with cte (pl_id, del_id, upc, amount) as (
    select 
        d.pricelist_id, di.delivery_id, di.upc, di.amount
    from delivery_items as di
    join deliveries AS d ON di.delivery_id = d.id
    where 
        d.supplier_id = 1
        and d.id = 1
)
UPDATE warehouse
SET amount = (warehouse.amount + cte.amount)
FROM cte
WHERE warehouse.articul = cte.upc AND warehouse.pricelist_id = cte.pl_id;

-- Или с помощью подрапроса:
UPDATE warehouse
SET amount = (warehouse.amount + cte.amount)
FROM (
    select 
        d.pricelist_id, di.delivery_id, di.upc, di.amount
    from delivery_items as di
    join deliveries AS d ON di.delivery_id = d.id
    where 
        d.supplier_id = 2
        and d.id = 2
) as cte
WHERE warehouse.articul = cte.upc AND warehouse.pricelist_id = cte.pricelist_id;

-- Напишите запрос для удаления данных с оператором DELETE 
-- используя join с другой таблицей с помощью using.

-- Удаление товаров определённого производителя со склада (таблица warehouse) 
-- в результате отзыва поставки поставщиком, например:

DELETE FROM table_name row1 
USING table_name row2 WHERE condition;

-- Приведите пример использования утилиты COPY (по желанию)

/* COPY служит для перемещения данных между таблицами PostgreSQL и файлами
  Варианты использования:
  1) выгрузить данные из таблицы в файл в файловой системе,
  2) загрузить данные из файла в таблицу.
*/

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
