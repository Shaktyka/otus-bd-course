/* 
    1
    Создать индекс к какой-либо из таблиц вашей БД
    Прислать текстом результат команды explain, в которой используется данный индекс.
    Написать комментарии к каждому из индексов
    Описать что и как делали и с какими проблемами столкнулись

    statuses - таблица статусов, у неё есть поле status_group_id - ссылка на идентификатор группы, к которой относится этот статус. 
    Это поле - foreign key, поэтому для ускорения поиска имеет смысл добавить индекс.
    Чтобы было более показательно, я добавила в таблицу ещё 3200 искусственно сгенерированных строк.
*/
CREATE INDEX ON statuses (status_group_id);

-- Запрос:
select * from dicts.statuses
where status_group_id = 3;

-- Вывод EXPLAIN ANALIZE:
Index Scan using statuses_status_group_id_idx on statuses as statuses (rows=403 loops=1)
Index Cond: (status_group_id = 3)

/*
    3
    Реализовать индекс для полнотекстового поиска

    Пример на таблице products (товары). У каждого товара есть поля название (product) и описание (descr_text), 
    по которым может быть реализован полнотекстовый поиск. Для реализации такого поиска я добавила 
    GIN-индекс на объединённое поле "название + описание".
*/

-- Создаёт индекс:
CREATE INDEX products_search_idx ON products 
USING GIN (to_tsvector('russian', product || ' ' || descr_text));

-- Выполняет запрос:
SELECT 
    p.upc,
    p.product,
    p.descr_text,
    p.amount,
    p.mass
FROM products AS p
WHERE to_tsvector('russian', p.product || ' ' || p.descr_text) @@ to_tsquery('америка & арабика');

-- Результат поиска:
"1254881" "Rose Blend" "Смесь специально создана для тех, кто любит выраженный кофе с молоком. Мы подобрали наилучшее соотношение арабик из Южной Америки и Эфиопии и растянули профиль обжарки так, чтобы снизить кислотность и усилить сладкие оттенки вкуса." 1 820

-- Результат EXPLAIN:
Bitmap Heap Scan on warehouse.products p (cost=12.25..16.77 rows=1 width=494) (actual time=0.047..0.048 rows=1 loops=1)
    Output: upc, product, descr_text, amount, mass
    Recheck Cond: (to_tsvector('russian'::regconfig, ((p.product || ' '::text) || p.descr_text)) @@ to_tsquery('америка & арабика'::text))
    Heap Blocks: exact=1
    ->  Bitmap Index Scan on products_search_idx  (cost=0.00..12.25 rows=1 width=0) (actual time=0.040..0.040 rows=1 loops=1)
        Index Cond: (to_tsvector('russian'::regconfig, ((p.product || ' '::text) || p.descr_text)) @@ to_tsquery('америка & арабика'::text))
Planning Time: 0.451 ms
Execution Time: 0.081 ms

/*
    4.1
    Реализовать индекс на часть таблицы 

    Частичный индекс был добавлен на таблицу склада warehouse, поле status_id со значением 6 ('Закончился'), 
    чтобы менеджер мог быстро получать и дозаказывать списки таких товаров.
    Для реализации задачи в таблицу было сгенерировано 3000 записей.
*/

-- Создаёт индекс:
CREATE INDEX ending_prod_idx 
ON warehouse (status_id)
WHERE status_id = 6;

-- После сбора статистики результат EXPLAIN ANALYSE:
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
    4.2
    Реализовать индекс на поле с функцией

    Функциональный индекс был добавлен на таблицу пользователей на объединённые поля фамилии (last_name) 
    и имени (first_name), т.к. по этим данным наверняка будет поиск в админке. Причём нужно учесть,
    что, скорее всего, вводить данные будут в разные поля и строчными буквами.
*/

-- Создаёт индекс:
CREATE INDEX last_first_name_idx 
ON users(( lower(COALESCE(last_name,'')) || ' ' || lower(first_name,'') ));
-- Учитываем случаи, когда фамилия может быть NULL

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
