/* Принципы формирования ограничений
    - я считаю, что реализацию основной массы ограничений, таких как длина строк и другие вариативные вещи, которые могут меняться со временем, лучше отдать на откуп бэкенда,
    - но наиболее стабильные и очевидные ограничения лучше реализовывать на базе данных,
    - часть проверок (сложных, хитрых) лучше вынести в триггеры,
    - первичный ключ создаётся с ограничением UNIQUE и NOT NULL во избежание вставок NULL и неуникальных значений при вставке вручную,
    - для поля dttmcr (дата и время создания записи) добавляется ограничение DEFAULT со значением now(), чтобы при добавлении записи не нужно было явно задавать это значение, 
    - при назначении первичного ключа, а также ограничения UNIQUE, индексы создаются автоматически (PostgreSQL),
    - при определении foreign key (внешнего ключа) индексы нужно заводить вручную,
    - в целом, кроме самых очевидных, индексы стоит добавлять после анализа "проблемных" запросов, т.е. не на старте создания таблиц и заведения значений.
*/

-------------------------
-- ОБЩИЕ СПРАВОЧНИКИ
-------------------------

-- Таблица "Группы статусов"
/*
    Ограничения:

    1) Название группы status_group:
    - NOT NULL - поле обязательное для заполнения, не может быть пустым
    - UNIQUE - название должно быть уникальным
*/

CREATE TABLE IF NOT EXISTS status_groups (
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    status_group text NOT NULL UNIQUE
);

-- Запросы будут только в админке, значений будет немного, поэтому дополнительные индексы не делаем.

-- Таблица "Статусы"
/*
    Ограничения:

    1) Идентификатор группы статусов status_group_id: 
    - FK на таблицу status_groups,
    - не должно содержать NULL, поэтому ограничение NOT NULL,
    - UNIQUE - название статуса должно быть уникальным
*/

CREATE TABLE IF NOT EXISTS statuses
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    status_group_id int NOT NULL REFERENCES status_groups (id),
    status_name text NULL UNIQUE
);

-- Индекс на поле status_group_id с FK для быстрого поиска при JOIN:
CREATE INDEX ON statuses (status_group_id);

-- Запросы названия статуса будут в отчётах, при выводе списков товаров/заказов с определённым статусом, но поиск будет по id, в целом статусов будет немного, поэтому дополнительные индексы нет смысла создавать.
-- Искать по названию статуса не будут.

-- Таблица "Пользователи"
/* 
    Ограничения:

    1) first_name:
    - фамилия и отчество могут отсутствовать, но имя пользователь должен заводить,
    2) email:
    - поле не должно содержать NULL-значения
    - значение поля должно быть уникальным в пределах всей базы
    3) password_hash:
    - поле не должно содержать NULL-значения
    4) пол пользователя:
    - может быть только одним из 2 значений, по умолчанию (DEFAULT) выбрано 1 (мужской, 2 - женский)
    5) phone:
    - обязательное поле, не должно быть пустым.
*/

CREATE TABLE IF NOT EXISTS users
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    last_name text,
    first_name text NOT NULL,
    middle_name text,
    birth_date date,
    email text UNIQUE NOT NULL,
    password_hash text NOT NULL,
    phone text NOT NULL,
    gender smallint DEFAULT 1 CHECK (gender IN (1, 2)),
    status_id int NOT NULL REFERENCES statuses (id)
);

/*
    Наиболее вероятны запросы на вывод списка пользователей: 
    - по определённому статусу,
    - поиск определённого пользователя по email, телефону, фамилии и имени,
    - можно создать индексы на эти поля.
*/

-- Индекс на поле status_id с FK для быстрого поиска при JOIN:
-- кардинальность будет невыскокой
CREATE INDEX ON users (status_id);

-- Индекс на поля email и пароль для поиска при аутентификации:
-- кардинальность будет высокой
CREATE INDEX ON users (email) INCLUDE (password_hash);

-- Индекс на поле телефон:
CREATE INDEX ON users (phone);

-- Индекс на поиск по фамилии и имени (их чаще всего заполняют):
CREATE INDEX user_names ON users ((last_name || ' ' || first_name));

-- Таблица "Типы сущностей"
/*
    Ограничения:
    1) поле с названием типа должно быть уникальным и должно быть заполнено, поэтому добавляются ограничение NOT NULL и UNIQUE
*/
CREATE TABLE IF NOT EXISTS object_types (
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    object_type text NOT NULL UNIQUE
);
-- Дополнительных индексов здесь нет.

-- Таблица "Адреса"
/*
    Ограничения:

    - поле object_type - FK на справочник object_types,
    - для этого поля целесообразно установить дефолтное значение на тип "Пользователь", т.к. в основном адреса будут относиться к пользователям,
    - поле object_id не является FK на определённую таблицу, это идентификатор записи в соотв-щей таблице по типу в object_type.
*/
CREATE TABLE IF NOT EXISTS adresses
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    object_type int NOT NULL REFERENCES object_types(id),
    object_id int,
    address_object jsonb,
    address_full_str text,
    postal_code text,
    country text,
    region text,
    settlement_type text,
    settlement text,
    street text,
    house text,
    block_val text,
    flat text
);

-- При выводе адресов будет поиск по object_type и object_id, поэтому для поиска нужно сделать индекс, но не уникальный, т.к. адресов может быть много:
CREATE INDEX type_id_connect_idx ON (object_id, object_type);

-- Для поиска по некоторым составным частям адресов имеет смысл сделать отдельные индексы (наиболее вероятен поиск):
CREATE INDEX ON adresses (postal_code);
CREATE INDEX ON adresses (country);
CREATE INDEX ON adresses (region);

-------------------------
-- ТОВАРЫ (СКЛАД)
-------------------------

-- Таблица "Производители"
/*
    Ограничения:
    1) manufacturer:
    - NULL - поле не д/б пустым
    - UNIQUE - название д/б уникальным
    2) поле ссылки на иконку не д/б NULL. 
*/
CREATE TABLE IF NOT EXISTS manufacturers
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    manufacturer text NOT NULL UNIQUE,
    logo_link text NOT NULL,
    site_link text
);

-- Индекс на название производителя, т.к. возможен поиск по названию.
-- В целом производителей будет немного. В основном будут выводить производителей по id, а это поле везде проиндексировано.
CREATE INDEX ON manufacturers (manufacturer);

-- Таблица "Поставщики"
/*
    Ограничения:
    1) supplier:
    - NULL - поле не д/б пустым
    - UNIQUE - название д/б уникальным
*/
CREATE TABLE IF NOT EXISTS suppliers
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    supplier text NOT NULL UNIQUE,
    company_phone text,
    manager_id int NOT NULL REFERENCES users(id),
    site_link text
);

-- Запросы будут в основном на поиск определённого поставщика по названию, либо вывод списка поставщиков по адресам, либо вывод поставщиков по продукту.
-- Имеет смысл добавить индекс на название поставщика:
CREATE INDEX ON suppliers (supplier);

-- Нужен индекс на поле manager_id, т.к. поле - FK.
-- Кардинальность будет достаточно высокой
CREATE INDEX ON suppliers (manager_id);

-- Таблица "Категории товаров"
/*
    Ограничения:

    1) parent_id: FK на эту же таблицу для создания древовидных связей, 
    2) category: название д/б уникальным.
*/
CREATE TABLE IF NOT EXISTS categories
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    parent_id int NOT NULL REFERENCES categories(id),
    category text NOT NULL UNIQUE
);

-- Индекс на столбец parent_id как FK:
-- кардинальность будет хорошей
CREATE INDEX ON categories (parent_id);

-- Индекс на название категории, по ней может быть поиск на сайте + список актуальных категорий будет выводиться на сайте:
CREATE INDEX ON categories (category);

-- Таблица "Единицы измеренения"
/*
    Ограничения:

    1) unit: поле д/б заполнено, значение д/б уникально
*/
CREATE TABLE IF NOT EXISTS units
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcl timestamptz,
    unit text NOT NULL UNIQUE
);

-- Дополнительных индексов нет: значений немного, искать по названию в админке вряд ли будут.

-- Таблица "Товары"
/*
    Ограничения:

    1) NOT NULL на поля vendor_code, product, manufacturer_id, supplier_id, category_id, status_id, т.к. эти поля обязательно должны иметь значения,
    2) поля manufacturer_id, supplier_id, category_id и status_id - являются внешними ключами с ограничением REFERENCES.
*/
CREATE TABLE IF NOT EXISTS products
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    vendor_code text NOT NULL,
    product text NOT NULL,
    manufacturer_id int NOT NULL REFERENCES manufacturers(id),
    supplier_id int NOT NULL REFERENCES suppliers(id),
    category_id int NOT NULL REFERENCES categories(id),
    photos text[],
    description_text text,
    status_id int NOT NULL REFERENCES statuses(id)
);

-- Запросы могут часто включать поиск по артикулу (vendor_code), названию и категории, поэтому по этим полям можно сделать составной индекс:
CREATE INDEX vendcode_product_category_idx ON products (vendor_code, product, category_id);

-- Также можно создать составной индекс на поля производителя и поставщика:
CREATE INDEX supplier_manufacturer_idx ON products (supplier_id, manufacturer_id);
-- Поле supplier_id имеет большую кардинальность, поэтому идёт первым

-- Также создадим индекс на поле FK по статусу заказа:
CREATE INDEX ON products (status_id);

-- Таблица "Характеристики товаров"
/*
    Ограничения:

    1) parameter: поле обязательно д/б заполнено и значение должно быть уникальным.
*/
CREATE TABLE IF NOT EXISTS parameters
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcl timestamptz,
    parameter text NOT NULL UNIQUE
);

-- Характеристику по названию в админке вряд ли будут искать, значений будет немного, поэтому дополнительные индексы не добавляем пока.

-- Таблица "Товар_характеристика"
/*
    Ограничения:

    1) сочетание полей product_id и parameter_id является PK в пределах таблицы. Индекс создаётся автоматически.
    2) поля для корректного задания значения характеристики будут проверяться триггером.
*/
CREATE TABLE IF NOT EXISTS product_params
(
    dttmcr timestamptz NOT NULL DEFAULT now(),
    product_id int NOT NULL REFERENCES products (id),
    parameter_id int NOT NULL REFERENCES parameters (id),
    value_int int,
    value_text text,
    value_numeric numeric,
    value_int_arr int[],
    value_text_arr text[],
    value_jsonb jsonb,
    PRIMARY KEY (product_id, parameter_id)
);

-- Дополнительных индексов нет.

-------------------------
-- ЦЕНЫ
-------------------------

-- Таблица "Способ оплаты"
/*
    Ограничения:

    1) поле pay_method не должно содержать NULL значения и должно быть уникальным
*/
CREATE TABLE IF NOT EXISTS pay_methods
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    pay_method text NOT NULL UNIQUE
);

-- Дополнительных индексов нет: будет мало значений. Джойны будут по PK, на который уже есть индекс.

-- Таблица "Цены" (своего рода справочник цен)
/*
    Ограничения:

    1) поля product_id и unit_id - FK на соответствующие таблицы и не должны быть NULL,
    2) unit_amount имеет значение по умолчанию 1 и должно быть больше 0,
    3) mass (вес) может быть либо NULL либо, если задан, больше 0,
    4) цена price должна быть всегда > 0.

    Значений в таблице будет много.
*/
CREATE TABLE IF NOT EXISTS prices
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    product_id int NOT NULL REFERENCES products(id),
    unit_id int NOT NULL REFERENCES units(id),
    unit_amount int NOT NULL DEFAULT 1 CHECK (unit_amount > 0),
    mass numeric CHECK (unit_amount is null or unit_amount > 0),
    price numeric NOT NULL CHECK (price > 0)
);

-- Индексы на поля с FK:
CREATE INDEX prices (product_id);
CREATE INDEX prices (unit_id);

-- Таблица "Прайслисты"
/*
    Ограничения:

    1) дата актуальности прайса actuality_date не может быть NULL,
    2) maneger_id - FK на таблицу пользователей
*/
CREATE TABLE IF NOT EXISTS pricelists
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    actuality_date date NOT NULL,
    manаger_id int NOT NULL REFERENCES users(id)
);

-- Значений будет достаточно много, если прайс-листы будут часто добавляться

-- Индекс на поле даты актуальности для быстрого поиска при построении списка товаров с ценами по актуальному прайслисту:
CREATE INDEX ON pricelists (actuality_date);

-- Индекс для поля с FK:
CREATE INDEX ON pricelists (manаger_id);

-- Таблица "Прайслист_товары"
/*
    Ограничения:

    1) поля pricelist_id, product_id, price_id являются FK, сссылаясь на соответствующие таблицы.
    2) сочетание из 3х полей становится PK, уникализируя каждую запись и автоматически создавая индекс.
*/
CREATE TABLE IF NOT EXISTS pricelist_products
(
    dttmcr timestamptz NOT NULL DEFAULT now(),
    pricelist_id int NOT NULL REFERENCES pricelists(id),
    product_id int NOT NULL REFERENCES products(id),
    price_id int NOT NULL REFERENCES prices(id),
    PRIMARY KEY (product_id, price_id, pricelist_id)
);

-- Значений в таблице будет очень много, т.к. для каждого прайс-листа нужно будет собрать список товаров с их ценами на разные фасовки.
-- Дополнительных индексов нет

-------------------------
-- ПОСТАВКИ ТОВАРОВ
-------------------------

-- Таблица "Поставки"
/*
    Ограничения:

    1) тип операции operation может быть либо 1 - поступление, либо 0 - возврат поставщику, что и проверяется ограничением,
    2) поле supplier_id - FK на таблицу поставщиков.
*/
CREATE TABLE IF NOT EXISTS deliveries
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    operation smallint NOT NULL DEFAULT 1 CHECK (operation IN (1, 0)),
    supplier_id int NOT NULL REFERENCES suppliers(id)
);

-- Возможны запросы на вывод списка поставок и товаров по поставщикам.

-- Индекс на поле supplier_id, т.к. оно - внешний ключ.
CREATE INDEX ON deliveries (supplier_id);

-- Таблица "Товары в поставке"
/*
    Ограничения:

    1) поля delivery_id, product_id, price_id должны быть уникальными в пределах всей таблицы, поэтому становятся первичным ключом; на них автоматически создастся индекс,
    2) поле количества amount должно быть больше 0.
*/
CREATE TABLE IF NOT EXISTS delivery_items
(
    dttmcr timestamptz NOT NULL DEFAULT now(),
    delivery_id int NOT NULL REFERENCES deliveries(id),
    product_id int NOT NULL REFERENCES products(id),
    price_id int NOT NULL REFERENCES prices(id),
    amount int CHECK (amount > 0),
    PRIMARY KEY (delivery_id, product_id, price_id)
);

-- Возможны запросы на выборки товаров в поставках, подсчёт запасов товаров на складе.
-- Записей в таблице с течением времени будет очень много.
-- Дополнительных индексов нет

--------------------------------------
-- ЗАКАЗЫ ПОЛЬЗОВАТЕЛЕЙ И ДОСТАВКА
--------------------------------------

-- Таблица "Способ доставки"
/*
    Ограничения:

    1) поле метода доставки ship_method не должно содержать значения NULL и д/б уникальным. Значений будет мало.
*/
CREATE TABLE IF NOT EXISTS ship_methods
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    ship_method text NOT NULL UNIQUE
);

-- Дополнительных индексов нет (мало значений). Поиск по названию вряд ли будет.

-- Таблица "Заказы"
/*
    Ограничения:

    1) поля user_id, pay_method_id, ship_method_id, address_id и last_status_id 
    являются FK на соответствующие таблицы, поэтому не должны содержать NULL-значения,
    2) поле order_sum м/б больше 0, что проверяется ограничением CHECK.
*/
CREATE TABLE IF NOT EXISTS orders
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    user_id int NOT NULL REFERENCES users(id),
    order_sum numeric NOT NULL CHECK (order_sum > 0),
    pay_method_id int NOT NULL REFERENCES pay_methods(id),
    ship_method_id int NOT NULL REFERENCES ship_methods(id),
    address_id int NOT NULL REFERENCES adresses(id),
    last_status_id int NOT NULL REFERENCES statuses(id)
);

-- По таблицам заказов и товарам в заказах будет много запросов и отчётов. Поля с FK получают свои индексы для ускорения джойнов.

-- Индексы на поля FK:
CREATE INDEX ON orders (user_id);
CREATE INDEX ON orders (pay_method_id);
CREATE INDEX ON orders (ship_method_id);
CREATE INDEX ON orders (address_id);
CREATE INDEX ON orders (last_status_id);

-- Таблица "Товары в заказе"
/*
    Ограничения:

    1) поля order_id, product_id, price_id д/б уникальными в пределах таблицы, поэтому становятся первичным ключом
    2) кол-во позиций не может быть NULL, поэтому добавляются ограничения NOT NULL и CHECK.
*/
CREATE TABLE IF NOT EXISTS order_items
(
    dttmcr timestamptz NOT NULL DEFAULT now(),
    order_id int NOT NULL REFERENCES orders(id),
    product_id int NOT NULL REFERENCES products(id),
    price_id int NOT NULL REFERENCES orders(id),
    amount int NOT NULL DEFAULT 1 CHECK (amount > 0),
    PRIMARY KEY (order_id, product_id, price_id)
);

-- В таблице со временем будет очень много записей, т.к. в заказе может быть много товаров. По таблице будет много джойнов для отчётов.
-- Дополнительных индексов нет

-- Таблица "Доставка"
/*
    Ограничения:

    1) поля order_id, ship_method_id, status_id являются внешними ключами на соответствующие таблицы,
    2) дата доставки не м/б меньше сегодня, поэтому добавляется ограничение CHECK,
    3) стоимость доставки ship_price м/б равна 0 или больше 0, поэтому добавляется CHECK.
*/
CREATE TABLE IF NOT EXISTS shipping
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    order_id bigint NOT NULL REFERENCES orders(id),
    ship_method_id int NOT NULL REFERENCES ship_methods(id),
    ship_date date CHECK (ship_date >= current_date),
    ship_price numeric DEFAULT 0 CHECK (ship_price = 0 or ship_price > 0),
    status_id int NOT NULL REFERENCES statuses(id)
);

-- Возможные запросы: поиск доставки по id, проверка статуса и даты доставки заказов. Имеет смысл сделать составной индекс:
CREATE INDEX order_date_status_idx ON shipping (order_id, ship_date, status_id);

-- Индекс на поле способа доставки с FK:
CREATE INDEX ON shipping (ship_method_id);

-------------------------
-- ПРОЦЕССЫ
-------------------------

-- Таблица "История смены статусов"
/*
    Ограничения:

    1) поле object_type - тип сущности, чтобы отличать записи в таблице и избежать путаницы идентификаторов,
    1) поле status_id является FK на соответствующую таблицу,
    2) dttmend - дата завершения текущего статуса, м/б NULL или >= даты присвоения статуса, поэтому добавлено ограничение.
*/
CREATE TABLE IF NOT EXISTS statuses_history
(
    id bigserial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    dttmend timestamptz CHECK (dttmend IS NULL or dttmend >= dttmcr)
    object_type int NOT NULL REFERENCES object_types(id),
    object_id int NOT NULL,
    status_id int NOT NULL REFERENCES statuses(id)
);

-- При построении отчётов будут джойны по полям с идентификаторами записей и статусов. 
-- Поэтому имеет смысл сделать составной индекс на 3 поля.
-- При этом наибольшей кардинальностью будет обладать поле object_id, затем status_id и меньше всего - type_id.
CREATE INDEX object_status_type_idx ON statuses_history (object_id, status_id, type_id);
