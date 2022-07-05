-- Написать комментарии к каждому из индексов
-- Описать что и как делали и с какими проблемами столкнулись

/* 
    1
    Создать индекс к какой-либо из таблиц вашей БД
    Прислать текстом результат команды explain, в которой используется данный индекс
*/

/*  
    statuses - таблица статусов, у неё есть поле status_group_id - ссылка на идентификатор группы, к которой относится этот статус. 
    Это поле - FK, поэтому для ускорения поиска имеет смысл добавить индекс.
    Чтобы индекс использовался, в таблицу было добавлено 3200 строк.
    В итоге для поиска по номеру группы был использован BITMAP INDEX SCAN,
    что объясняется не очень высокой селективностью запроса. 
*/
CREATE INDEX ON statuses (status_group_id);

-- Запрос:
select * from dicts.statuses
where status_group_id = 3;

-- Вывод EXPLAIN:
Bitmap Heap Scan on statuses  (cost=7.40..39.44 rows=403 width=32)
Recheck Cond: (status_group_id = 3)
->  Bitmap Index Scan on statuses_status_group_id_idx  (cost=0.00..7.30 rows=403 width=0)
    Index Cond: (status_group_id = 3)

-- Если структурировать данные в индексе по этому полю, то можно сократить время для выборки:
CLUSTER dicts.statuses USING statuses_status_group_id_idx;

ANALYZE dicts.statuses;

-- И тогда EXPLAIN станет следующим: 
-- видно использование индекса и сокращение времени в 2 раза, что для данных, которые редко меняются, очень хорошо
Index Scan using statuses_status_group_id_idx on statuses  (cost=0.28..18.33 rows=403 width=32)
Index Cond: (status_group_id = 3)

/*
    2
    Реализовать индекс для полнотекстового поиска

    Пример на таблице products (товары). У каждого товара есть поля название (product) и описание (descr_text), 
    по которым может быть реализован полнотекстовый поиск. Можно добавить GIN-индекс 
    на объединённое поле, причём сделать так, чтобы это поле генерировалось само.
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

/*
    3
    Реализовать индекс на часть таблицы 
*/

/*
    Частичный индекс был добавлен на 
*/



/*
    4
    Реализовать индекс на поле с функцией

    Функциональный индекс был добавлен на 
*/

CREATE INDEX user_names ON users ((last_name || ' ' || first_name));

/*
    5
    Создать индекс на несколько полей
*/

CREATE INDEX ON pricelists (date_beg, date_end) INCLUDE supplier_id;
