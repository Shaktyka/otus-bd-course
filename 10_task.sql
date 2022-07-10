-- Написать комментарии к каждому из индексов
-- Описать что и как делали и с какими проблемами столкнулись

/* 
    1
    Создать индекс к какой-либо из таблиц вашей БД
    Прислать текстом результат команды explain, в которой используется данный индекс.

    statuses - таблица статусов, у неё есть поле status_group_id - 
    ссылка на идентификатор группы, к которой относится этот статус. 
    Это поле - foreign key, поэтому для ускорения поиска имеет смысл добавить индекс.
    Чтобы было более показательно, я добавила в таблицу ещё 3200 искусственно сгенерированных строк.
*/
CREATE INDEX ON statuses (status_group_id);

-- Запрос:
select * from dicts.statuses
where status_group_id = 3;

-- Запускает сбор аналитики:
ANALYZE dicts.statuses;

-- Вывод EXPLAIN ANALIZE:
Index Scan using statuses_status_group_id_idx on statuses as statuses (rows=403 loops=1)
Index Cond: (status_group_id = 3)

/*
    2
    Реализовать индекс для полнотекстового поиска

    Пример на таблице products (товары). У каждого товара есть поля название (product) и описание (descr_text), 
    по которым может быть реализован полнотекстовый поиск. Для реализации полнотекстового поиска я добавлю 
    GIN-индекс на объединённое поле "название + описание", причём сделать так, чтобы это поле генерировалось само.
*/

-- Добавляет в таблицу генерируемое поле, которое будет содержать 
-- разобранные на лексемы значения полей названия и описание товара:

ALTER TABLE products
ADD COLUMN product_descr_search tsvector
GENERATED ALWAYS AS (to_tsvector('russian', product || ' ' || coalesce(descr_text, ''))) STORED;

-- Добавляет GIN-индекс:
CREATE INDEX product_descr_search_idx 
ON products USING GIN (product_descr_search);

-- Выполняет запрос:
SELECT product, descr_text
FROM products
WHERE product_descr_search @@ to_tsquery('berry & малина');

-- Результат, который и ожидался:
"Berry Blend" "В аромате жасмин, карамель и черная смородина Во вкусе черника, сухофрукты и малина"

-- Результат EXPLAIN ANALIZE:
Seq Scan on warehouse.products  (cost=0.00..5.68 rows=1 width=64) (actual time=0.132..0.349 rows=2 loops=1)
    Output: product, descr_text
    Filter: (products.product_descr_search @@ to_tsquery('berry & малина'::text))
    Rows Removed by Filter: 10
Planning Time: 2.901 ms
Execution Time: 0.370 ms

-- После выполнения сбора статистики результат EXPLAIN оказался немного получше:
Seq Scan on warehouse.products  (cost=0.00..5.15 rows=1 width=359) (actual time=0.094..0.182 rows=2 loops=1)
    Output: product, descr_text
    Filter: (products.product_descr_search @@ to_tsquery('berry & малина'::text))
    Rows Removed by Filter: 10
Planning Time: 13.824 ms
Execution Time: 0.199 ms

/*
    3
    Реализовать индекс на часть таблицы 

    Частичный индекс был добавлен на таблицу склада warehouse, поле status_id со значением 6 ('Закончился'), 
    чтобы менеджер мог быстро получать списки таких товаров.
    Для реализации задачи в таблицу было сгенерировано 3000 записей.
*/

-- Создаёт индекс:
CREATE INDEX ending_prod_idx 
ON warehouse (status_id)
WHERE status_id = 6;

-- После сбора статистики видим результат с использованием созданного индекса:
Bitmap Heap Scan on warehouse.warehouse  (cost=9.72..41.47 rows=300 width=36) (actual time=0.052..0.149 rows=300 loops=1)
    Output: id, dttmcr, product_id, articul, pricelist_id, amount, status_id
    Recheck Cond: (warehouse.status_id = 6)
    Heap Blocks: exact=27
    ->  Bitmap Index Scan on ending_prod_idx  (cost=0.00..9.65 rows=300 width=0) (actual time=0.042..0.042 rows=300 loops=1)
Planning Time: 0.122 ms
Execution Time: 0.184 ms

-- Пример запроса, где будет использоваться этот индекс: выбрать все товары поставщика с id 1, которые закончились:
SELECT 
    w.product_id,
    w.articul,
    w.pricelist_id
FROM warehouse AS w
INNER JOIN pricelists AS p ON w.pricelist_id = p.id
WHERE 
    w.status_id = 6
    AND p.supplier_id = 1;

/*
    4
    Реализовать индекс на поле с функцией

    Функциональный индекс был добавлен на таблицу пользователей на объединённые поля фамилии (last_name) 
    и имени (first_name), т.к. по этим данным наверняка будет поиск в админке. Причём нужно учесть,
    что, скорее всего, вводить данные будут в разные поля и строчными буквами.
*/

-- Создаёт индекс:
CREATE INDEX last_first_name_idx 
ON users(( lower(last_name) || ' ' || lower(first_name) ));

-- Результат EXPLAIN:
Index Scan using last_first_name_idx on dicts.users u  (cost=0.28..8.31 rows=1 width=81) (actual time=0.066..0.067 rows=1 loops=1)
   Output: concat(last_name, ' ', first_name, ' ', middle_name), to_char((birth_date)::timestamp with time zone, 'DD.MM.YYYY'::text), email, phone
   Index Cond: (((lower(u.last_name) || ' '::text) || lower(u.first_name)) = concat('quhbrdeot'::text, ' ', 'qypdede'::text))
Planning Time: 0.744 ms
Execution Time: 0.093 ms

-- Запрос, который использует индекс:
SELECT 
    concat(u.last_name, ' ', u.first_name, ' ', u.middle_name) as fio,
    to_char(u.birth_date, 'DD.MM.YYYY') as birth_date,
    u.email,
    u.phone
FROM users AS u
WHERE (lower(last_name) || ' ' || lower(first_name)) = concat( lower('Quhbrdeot'), ' ', lower('Qypdede') );

/*
    5
    Создать индекс на несколько полей

    Составной индекс был добавлен на таблицу доставки (shipping) на поля метод доставки (ship_method_id) и дата доставки (ship_date).
    Это может понадобиться для случаев, когда нужно выбрать список доставок на определённую дату по методу доставки.
*/

-- Создаёт индекс
CREATE INDEX ship_date_and_method_idx
ON orders.shipping (ship_method_id, ship_date);

-- Результат EXPLAIN
Bitmap Heap Scan on orders.shipping  (cost=4.32..16.08 rows=4 width=41) (actual time=0.104..0.106 rows=4 loops=1)
    Output: id, dttmcr, order_id, order_date, ship_method_id, ship_date, ship_price, status_id
    Recheck Cond: ((shipping.ship_method_id = 5) AND (shipping.ship_date = CURRENT_DATE))
    Heap Blocks: exact=1
    ->  Bitmap Index Scan on ship_date_and_method_idx  (cost=0.00..4.32 rows=4 width=0) (actual time=0.079..0.080 rows=4 loops=1)
        Index Cond: ((shipping.ship_method_id = 5) AND (shipping.ship_date = CURRENT_DATE))
Planning Time: 0.634 ms
Execution Time: 0.173 ms

-- Запрос, где будет использован индекс:
SELECT *
FROM orders.shipping
WHERE 
    ship_method_id = 5
    AND ship_date = current_date;
