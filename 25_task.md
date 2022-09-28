# Транзакции

## Описать пример транзакции из своего проекта 
C изменением данных в нескольких таблицах. Реализовать в виде хранимой процедуры.

Процедура должна добавить новые продукты и данные для них в БД за один раз. Предполагаем, что данные о продуктах мы загружаем, допустим, из CSV, превращаем их в JSON и отдаём на вход функци вставки.
Данные о продуктах хранятся в таблице products.
Данные о характеристиках хранятся в таблице characteristcs со ссылкой на products.
Процедура принимает данные по продуктам и данные по характеристикам в массиве JSON.
Перебираем массив, добавляем товар и если запись произошла добавляем характеристики.
Надо проверить, что это - новый товар, и тогда делаем INSERT, иначе надо сделать UPDATE.

-- Дату ещё учесть

Предполагаем, что структура данных может быть такой:
[
    {
        "title": "Кофе Мария",
        "characteristics": [
            {
                "brand": "Chibo",
                "country": "Mexico",
                "pacage": "200 г",
                "price": "450 р",
                "amount": 10
            }
        ]
    },
    {
        "title": "Кофе Joanna",
        "characteristics": [
            {
                "brand": "Golden Coffee",
                "country": "UK",
                "pacage": "500 г",
                "price": "800 р",
                "amount": 15
            }
        ]
    },
    {
        "title": "Кофе Helen",
        "characteristics": [
            {
                "brand": "Mega Cup",
                "country": "Russia",
                "pacage": "290 г",
                "price": "599 р",
                "amount": 9
            }
        ]
    }
]

-- Таблица продуктов:
CREATE TABLE products (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    title varchar(150)
);

-- Таблица характеристик:
CREATE TABLE characteristics (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    product_id int NOT NULL UNSIGNED FOREIGN_KEY REFERENCES products(id),
    brand varchar(120),
    country varchar(100),
    pacage varchar(20)
);

-- Сама процедура
CREATE procedure add_new_products_data(_products json, _characteristics json)
 
BEGIN
 
    BEGIN;
    INSERT INTO user (id, nik) VALUES (1, 'nikola');
    INSERT INTO user_info (id, id_user, item_name, item_value) VALUES (1, 1, 'Имя', 'Николай'); 
    INSERT INTO user_info (id, id_user, item_name, item_value) VALUES (2, 1, 'Возраст', '24');
    COMMIT;

END;

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
