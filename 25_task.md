# Транзакции

## Описать пример транзакции из своего проекта 
C изменением данных в нескольких таблицах. Реализовать в виде хранимой процедуры.

Создадим процедуру, которая будет добавлять тест и вопросы для него, а также добавит записи в таблицу логирования. Схема базы данных - по ссылке https://dbdiagram.io/d/61cca2dc3205b45b73d13086 

Процедура получит данные теста, а также список вопросов для него. Вопросы имеет смысл добавлять только после того, как будет добавлен сам тест. (Пример немного вырожденный, т.к., по идее, вопросы могут добавляться и после создания тестов, но для выполнения задания и демонстрации - ОК)

Предполагаем, что процедура будет получать следующие структуры данных:

Данные теста для таблицы тестов:
```
{
    "user_id": 2, 
    "category_id": 1, 
    "name": "SQL DDL уровень 2", 
    "description": "Тест для проверки продвинутых навыков написания DDL запросов", 
    "test_config": null, 
    "is_public": FALSE, 
    "status": "new"
}
```

Данные вопросов для таблицы вопросов:
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
        "right_variants": [2, 3]
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
        "right_variants": [2]
    }
]
```

Определение процедуры:



При успешной отработке процедуры данные будут добавлены во все 3 таблицы:



## Загрузить данные из приложенных в материалах csv.

Так как на лекции было сказано, что важнее всё-таки загрузить данные, чем определить все 100500 столбцов таблицы, я, после многочисленных безуспешных попыток загрузить один из этих файлов, реализовала загрузку на более простом примере. В файле я специально имитировала NULL значения, чтобы было похоже на реальные данные. 

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
