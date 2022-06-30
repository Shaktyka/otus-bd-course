
-- Напишите запрос по своей базе с регулярным выражением, 
-- добавьте пояснение, что вы хотите найти.

-- 1) Найти пользователя по инициалам 'ФИВ', оставил отзыв на сайте:

SELECT id, last_name, first_name, middle_name
FROM dicts.users
WHERE concat( last_name, ' ', first_name, ' ', middle_name ) LIKE 'Ф% И% В%';

-- 2) Найти всех пользователей, у которых в фамилиях одна или 2 буквы 'л'.
-- Был звонок от такого пользователя, фамилию не уточнили:

SELECT id, last_name, first_name, phone 
FROM dicts.users
WHERE last_name SIMILAR TO '%(л|лл)%'
AND first_name = 'Артур';

-- Напишите запрос по своей базе с использованием LEFT JOIN и INNER JOIN, 
-- как порядок соединений во FROM влияет на результат? Почему?


-- Напишите запрос на добавление данных с выводом информации о добавленных строках.

INSERT INTO dicts.object_types (object_type) VALUES
('Пользователи'),
('Поставщики'),
('Заказы') 
RETURNING *;

-- Напишите запрос с обновлением данные используя UPDATE FROM.


-- Напишите запрос для удаления данных с оператором DELETE 
-- используя join с другой таблицей с помощью using.


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
