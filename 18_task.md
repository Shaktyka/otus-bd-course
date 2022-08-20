# Подготовка

1. Есть VPS c ОС Ubuntu 22.04 
1. На сервер установлена СУБД PostgreSQL 14
1. Добавлены ещё 2 кластера main2 и main3, кроме основного main3

Итого, есть 3 работающих кластера на одном сервере:

[скриншот](/images/log_repl/clusters.jpg)

# Логическая репликация

1. На основном кластере main создана база данных justcoffee и пользователь rep_user с правами на репликацию:

    CREATE DATABASE justcoffee
        WITH
        OWNER = postgres
        ENCODING = 'UTF8'
        LC_COLLATE = 'C.UTF-8'
        LC_CTYPE = 'C.UTF-8'
        TABLESPACE = pg_default
        CONNECTION LIMIT = -1;

    [скриншот](/images/log_repl/bd.jpg)

1. Здесь же создана таблица methods с названиями методов доставки. В таблицу добавлены данные:

    CREATE TABLE IF NOT EXISTS methods
    (
        id serial NOT NULL UNIQUE PRIMARY KEY,
        dttmcr timestamp with time zone NOT NULL DEFAULT now(),
        method_name text NOT NULL
    )
    TABLESPACE pg_default;

    [скриншот](/images/log_repl/create_table.jpg)

    INSERT INTO methods (method_name) 
    VALUES ('Почта'), ('Курьер'), ('Самовывоз');

    [скриншот](/images/log_repl/insert.jpg)

1. Для базы данных установлен параметр wal_level:

    ALTER SYSTEM SET wal_level = logical;

1. На этом же кластере main создана публикация таблицы methods:

    CREATE PUBLICATION pub_method FOR TABLE methods;

1. После перезагрузки конфигурации делаем проверку, что подписка создана:

    SELECT * FROM pg_publication;
    SELECT * FROM pg_publication_tables;

    [скриншот](/images/log_repl/%D0%BF%D1%80%D0%BE%D0%B2%D0%B5%D1%80%D0%BA%D0%B0.jpg)

1. На кластере main2 так же создаётся база данных justcoffee. Структура таблицы через бэкап передаётся с кластера main на кластер main2: 

    pg_dump -t methods -s justcoffee -p 5432 | psql -p 5433 justcoffee;

1. На кластере main2 добавляется подписка на публикацию таблицы methods с кластера main:

    CREATE SUBSCRIPTION sub_methods 
    CONNECTION 'dbname=justcoffee host=127.0.0.1 user=rep_user port=5432 password=123' 
    PUBLICATION pub_method;

    [скриншот](/images/log_repl/create_subscription.jpg)

1. Проверка работы репликации. На основном кластере main в таблицу добавляются данные, на кластере с подпиской данные также появляются. 

    INSERT INTO methods (method_name) VALUES ('Олени'), ('Голубиная почта');

    [скриншот](/images/log_repl/%D0%BF%D1%80%D0%BE%D0%B2%D0%B5%D1%80%D0%BA%D0%B0_%D1%80%D0%B5%D0%BF%D0%BB%D0%B8%D0%BA%D0%B0%D1%86%D0%B8%D0%B8.jpg)

    Репликация работает также при использовании операций UPDATE, DELETE и TRUNCATE:

    UPDATE methods SET method_name = 'Северные олени' WHERE id = 4;

    Данные появились в реплицированной таблице:
    
    [скриншот](/images/log_repl/repl_update.jpg)
    

# Физическая репликация
