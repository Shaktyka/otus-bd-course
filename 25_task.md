# Транзакции

## Описать пример транзакции из своего проекта 
C изменением данных в нескольких таблицах. Реализовать в виде хранимой процедуры.

Создадим процедуру, которая будет добавлять тест и вопросы для него, а также добавит записи в таблицу логирования. Схема базы данных - по ссылке https://dbdiagram.io/d/61cca2dc3205b45b73d13086 

Процедура получит данные теста, а также список вопросов для него. Вопросы имеет смысл добавлять только после того, как будет добавлен сам тест. (Пример немного вырожденный, т.к., по идее, вопросы могут добавляться и после создания тестов, но для выполнения задания и демонстрации - ОК)

Предполагаем, что процедура будет получать следующие структуры данных:

Данные теста для таблицы тестов:
```
{
    "user_fk": 2, 
    "category_fk": 1, 
    "name": "SQL DDL уровень 2", 
    "description": "Тест для проверки продвинутых навыков написания DDL запросов", 
    "test_config": null, 
    "is_public": FALSE, 
    "status": "in_progress"
}
```

Массив вопросов тестов для таблицы вопросов:
```
[
    {
        "question_type_fk": 1, 
        "question": "Команда для добавления столбца в таблицу", 
        "image_link": NULL, 
        "description": "Выберите верный ответ из представленных ниже", 
        "variants": {
            "terms": [
                {
                    "variant_id": 1,
                    "text": "CREATE COLUMN"
                },
                {
                    "variant_id": 2,
                    "text": "ADD COLUMN"
                },
                {
                    "variant_id": 3,
                    "text": "ALTER TABLE"
                },
                {
                    "variant_id": 4,
                    "text": "ADD CONSTRAINT"
                }
            ]
        }, 
        "right_variants": '[2, 3]'
    },
    {
        "question_type_fk": 1, 
        "question": "Команда для удаления столбца из таблицы", 
        "image_link": NULL, 
        "description": "Выберите верный ответ из представленных ниже", 
        "variants": {
            "terms": [
                {
                    "variant_id": 1,
                    "text": "DELETE COLUMN"
                },
                {
                    "variant_id": 2,
                    "text": "DROP COLUMN"
                },
                {
                    "variant_id": 3,
                    "text": "ALTER COLUMN"
                },
                {
                    "variant_id": 4,
                    "text": "THROW TABLE"
                }
            ]
        }, 
        "right_variants": '[2]'
    }
]
```

Определение процедуры:
```
    DELIMITER $$
    CREATE PROCEDURE pr_insert_test(
        IN _test_data JSON,
        IN _questions_data JSON
    )
    BEGIN
	DECLARE _test_id INT;
    DECLARE _result INT DEFAULT = 0; -- по умолчанию, результат - неудачная запись
    
    SET AUTOCOMMIT=0;
    START TRANSACTION;
    
    -- Добавляем данные в таблицу тестов:
    INSERT INTO tests (user_fk, category_fk, `name`, `description`, test_config, is_public, `status`)
    VALUES (
        _test_data->>"$.user_fk", 
        _test_data->>"$.category_fk",
        _test_data->>"$.name", 
        _test_data->>"$.description",
        _test_data->>"$.test_config", 
        _test_data->>"$.is_public",
        _test_data->>"$.status"
	);
    
    SELECT LAST_INSERT_ID() INTO _test_id;
    
    IF _test_id IS NULL THEN
        ROLLBACK;
	
    ELSE
        
        -- Добавляет записи в таблицу вопросов:
        INSERT INTO questions (test_fk, question_type_fk, question, image_link, description, variants, right_variants)
            SELECT
                _test_id,
                qd.question_type_fk,
                qd.question,
                qd.image_link,
                qd.description,
                qd.variants,
                qd.right_variants
            FROM JSON_TABLE(
                _questions_data,
                '$[*]' COLUMNS( 
                    question_type_fk INT PATH '$.question_type_fk',
                    question TEXT PATH '$.question',
                    image_link TEXT PATH '$.image_link',
                    `description` TEXT PATH '$.description',
                    variants JSON PATH '$.variants',
                    right_variants JSON PATH '$.right_variants'
                )
            ) as qd;

            SET _result = 1; -- результат - успешная запись
    
    END IF;

    -- Логирует данные:
	INSERT INTO log (user_id, new_data, old_data, action_name, source, result)
	VALUES (0, JSON_OBJECT('test_data', _test_data, 'questions_data', _questions_data), NULL, 'insert', 'pr_insert_test', _result);

    COMMIT;

    END$$
    DELIMITER ;
```

При успешной отработке процедуры данные будут добавлены во все 3 таблицы, иначе, если в первую запись не удалось вставить, всё откатится назад.

Процедура протестирована со следующими данными:
```
CALL pr_insert_test(JSON_OBJECT('user_fk',2,'category_fk',1,'name','SQL DDL уровень 3','description',
'555 Тест для проверки продвинутых навыков написания DDL запросов','test_config',null,'is_public',0,'status','in_progress'), 
JSON_ARRAY(json_object('question_type_fk',1, 'question','555 Команда для добавления столбца в таблицу',  
'image_link',NULL, 'description','Выберите верный ответ из представленных ниже', 
'variants','{}','right_variants','{}'), json_object('question_type_fk',1, 'question','666 Команда для добавления столбца в таблицу',  
'image_link',NULL, 'description','Выберите верный ответ из представленных ниже', 
'variants','{}','right_variants','{}')));
```

[Добавлена запись в таблицу тестов](/images/log_insert.jpg)

[Добавлены 2 записи в таблицу вопросов](/images/log_insert.jpg)

[Добавлена запись в таблицу логов](/images/log_insert.jpg)

## Загрузить данные из приложенных в материалах csv.

На лекции было сказано, что важнее всё-таки загрузить данные, чем определить всё множество столбцов таблицы, я, после многочисленных безуспешных попыток загрузить один из этих файлов, реализовала загрузку на более простом примере. В файле я специально имитировала NULL значения, чтобы было похоже на реальные данные. 

[Данные в файле до имитации](/images/product_data.png)

### Реализация через LOAD DATA

Создаём таблицу для загружаемых данных в БД

```
CREATE TABLE products (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    article text,
    category text,
    title text,
    short_descr text,
    pacage text,
    price decimal
);
```

Файл будем сначала загружать на сервер, а потом уже в таблицу базы данных.

Запрашиваем путь, куда можно загружать файлы на сервер для MySQL:

`SHOW VARIABLES LIKE "secure_file_priv";`

Получаем `/var/lib/mysql-files/`

Из консоли на локальной машине загружаем файл на сервер с помощью scp:

`scp /Users/elena/Downloads/products_simple.csv root@more-mysql:/var/lib/mysql-files/`

Файл на сервере:

`-rw-r--r--  1 root  root    1527 Sep 24 15:56 products_simple.csv`

Переходим в консоль mysql и загружаем данные в таблицу:

```
LOAD DATA INFILE '/var/lib/mysql-files/products_simple.csv' 
INTO TABLE products 
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(article, @category, title, @short_descr, pacage, price)
SET
short_descr = nullif(@short_descr,''),
category = nullif(@category,'');
```

Данные успешно загружены:

```
*************************** 1. row ***************************
         id: 1
    article: 1171417
   category: КОФЕ В ЗЕРНАХ И МОЛОТЫЙ
      title: Индия Монсунд Малабар
short_descr: NULL
     pacage: 250 г
      price: 560
*************************** 2. row ***************************
         id: 2
    article: 1171417
   category: NULL
      title: Индия Монсунд Малабар
short_descr: В аромате свежая выпечка и яркие цветочные ноты
     pacage: 1000 г
      price: 2040
*************************** 3. row ***************************
         id: 3
    article: 1171417
   category: КОФЕ В ЗЕРНАХ И МОЛОТЫЙ
      title: Индия Монсунд Малабар
short_descr: В аромате свежая выпечка и яркие цветочные ноты
     pacage: 2 по 1000
      price: 4080
```

### Реализация через mysqlimport

Запускаем из консоли сервера, настройки похожи на соответствующие для LOAD DATA.

```
mysqlimport --local -v -d --ignore-lines=1 --fields-terminated-by="," --lines-terminated-by="\n" --fields-optionally-enclosed-by='"' --columns=article,category,title,short_descr,pacage,price quizgame '/var/lib/mysql-files/products_simple.csv'
```

Непонятно, как прописать замену пустых строк на NULL через переменные, примеров не нашла, в документации не описано.

Результат выполнения:

```
Connecting to localhost
Selecting database quizgame
Loading data from LOCAL file: /var/lib/mysql-files/products_simple.csv into products_simple
quizgame.products_simple: Records: 9  Deleted: 0  Skipped: 0  Warnings: 0
Disconnecting from localhost
```

Результат выборки данных:

```
*************************** 1. row ***************************
         id: 1
    article: 1171417
   category: КОФЕ В ЗЕРНАХ И МОЛОТЫЙ
      title: Индия Монсунд Малабар
short_descr: В аромате свежая выпечка и яркие цветочные ноты
     pacage: 250 г
      price: 560
*************************** 2. row ***************************
         id: 2
    article: 1171417
   category:
      title: Индия Монсунд Малабар
short_descr: В аромате свежая выпечка и яркие цветочные ноты
     pacage: 1000 г
      price: 2040
*************************** 3. row ***************************
         id: 3
    article: 1171417
   category: КОФЕ В ЗЕРНАХ И МОЛОТЫЙ
      title: Индия Монсунд Малабар
short_descr:
     pacage: 2 по 1000
      price: 4080
```

## Реализовать загрузку через fifo
Задание повышенной сложности*

Непонятно, что это. Гугл тоже не особо помог.
