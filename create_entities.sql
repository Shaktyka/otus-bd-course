/* Принципы формирования ограничений
    - я считаю, что реализацию основной массы ограничений, таких как длина строк и другие вариативные вещи, которые могут меняться со временем, лучше отдать на откуп бэкенда,
    - но наиболее стабильные и очевидные ограничения лучше реализовывать на базе данных,
    - часть проверок может быть вынесена в триггеры,
    - первичный ключ создаётся с ограничением UNIQUE и NOT NULL во избежание вставок NULL и неуникальных значений при вставке вручную,
    - для поля dttmcr (дата и время создания записи) добавляется ограничение DEFAULT со значением now(), чтобы при добавлении записи не нужно было явно задавать это значение, 
    - при назначении первичного ключа автоматически создастся индекс,
    - при добавлении ограничения UNIQUE также автоматически создастся индекс.
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
    dttmup timestamptz,
    dttmcl timestamptz,
    status_group text NOT NULL UNIQUE,
    note text
);

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
    dttmup timestamptz,
    dttmcl timestamptz,
    status_group_id int NOT NULL REFERENCES status_groups (id),
    status_name text NULL UNIQUE,
    note text
);

-- Индекс на поле status_group_id с FK для быстрого поиска при JOIN:
CREATE INDEX ON statuses (status_group_id);

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
    - может быть только одним из 2 значений, по умолчанию (DEFAULT) выбрано 1
    5) phone:
    - обязательное поле, не должно быть пустым.
*/

CREATE TABLE IF NOT EXISTS users
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    dttmup timestamptz,
    dttmcl timestamptz,
    last_name text,
    first_name text NOT NULL,
    middle_name text,
    birth_date date,
    email text UNIQUE NOT NULL,
    password_hash text NOT NULL,
    address_full jsonb,
    phone text NOT NULL,
    gender smallint DEFAULT 1 CHECK (gender IN (1, 2)),
    status_id int NOT NULL REFERENCES statuses (id)
);

-- Индекс на поле status_id с FK для быстрого поиска при JOIN:
-- кардинальность будет не оч. большой
CREATE INDEX ON users (status_id);

-- Индекс на поля email и пароль для поиска при аутентификации:
-- кардинальность будет большой
CREATE INDEX ON users (email) INCLUDE (password_hash);

-- Таблица "Адреса"
/*
    Ограничения:

    - для поля object_type устанавливается дефолтное значение с проверкой на выбор одного из 3х значений
    - таблица заполняется по триггеру из других таблиц с полем адреса в формате jsonb, поэтому поле object_id тут не является FK на какую-либо таблицу. 
*/
CREATE TABLE IF NOT EXISTS adresses
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    dttmup timestamptz,
    dttmcl timestamptz,
    object_type smallint DEFAULT 1 CHECK (object_type IN (1, 2, 3)),
    object_id int,
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

-- Индексы: для поиска по некоторым составным частям адресов имеет смысл сделать отдельные индексы:
CREATE INDEX ON adresses (postal_code);
CREATE INDEX ON adresses (country);
CREATE INDEX ON adresses (region);
CREATE INDEX ON adresses (settlement) INCLUDE (street, house, block_val, flat);

-------------------------
-- ТОВАРЫ (СКЛАД)
-------------------------

-- Таблица "Производители"
/*
    Ограничения:
    1) manufacturer:
    - NULL - поле не д/б пустым
    - UNIQUE - название д/б уникальным

    Индексы:
    дополнительных нет
*/
CREATE TABLE IF NOT EXISTS manufacturers
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    dttmup timestamptz,
    dttmcl timestamptz,
    manufacturer text NOT NULL UNIQUE,
    address_full jsonb,
    logo_link text,
    site_link text
);

-- Таблица "Поставщики"
/*
    Ограничения:
    1) supplier:
    - NULL - поле не д/б пустым
    - UNIQUE - название д/б уникальным
    2) address_full:
    - NULL - поле не д/б пустым, адрес поставщика важен
*/
CREATE TABLE IF NOT EXISTS suppliers
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    dttmup timestamptz,
    dttmcl timestamptz,
    supplier text NOT NULL UNIQUE,
    company_phone text,
    address_full jsonb NOT NULL,
    manager_id int NOT NULL REFERENCES users(id),
    site_link text,
    note text
);

-- Нужен индекс на поле manager_id, т.к. поле - FK
-- кардинальность будет хорошей
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
    dttmup timestamptz,
    dttmcl timestamptz,
    parent_id int NOT NULL REFERENCES categories(id),
    category text NOT NULL UNIQUE,
    note text
);

-- Индекс на столбец parent_id как FK:
-- кардинальность будет хорошей
CREATE INDEX ON categories (parent_id);

-- Таблица "Единицы измеренения"
/*
    Ограничения:

    1) unit: поле д/б заполнено, значение д/б уникально
*/
CREATE TABLE IF NOT EXISTS units
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    dttmup timestamptz,
    dttmcl timestamptz,
    unit text NOT NULL UNIQUE
);

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
    dttmup timestamptz,
    dttmcl timestamptz,
    vendor_code text NOT NULL,
    product text NOT NULL,
    manufacturer_id int NOT NULL REFERENCES manufacturers(id),
    supplier_id int NOT NULL REFERENCES suppliers(id),
    category_id int NOT NULL REFERENCES categories(id),
    photos text[],
    description_text text,
    status_id int NOT NULL REFERENCES statuses(id)
);

-- Продавцы могут часто искать по артикулу (vendor_code), поэтому по этому полю можно сделать индекс:
CREATE INDEX ON products (vendor_code);

-- Индексы на поля с FK, т.к. они будут участвовать в JOIN-запросах:
CREATE INDEX ON products (manufacturer_id);
CREATE INDEX ON products (supplier_id);
CREATE INDEX ON products (category_id);
CREATE INDEX ON products (status_id);

-- Таблица "Характеристики товаров"
/*
    Ограничения:

    1) parameter: поле обязательно д/б заполнено и значение должно быть уникальным.
*/
CREATE TABLE IF NOT EXISTS parameters
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    dttmup timestamptz,
    dttmcl timestamptz,
    parameter text NOT NULL UNIQUE
);

-- Таблица "Товар_характеристика"
/*
    Ограничения:

    1) Поля product_id и parameter_id являются FK на соответствующие таблицы
*/
CREATE TABLE IF NOT EXISTS product_params
(
    dttmcr timestamptz NOT NULL DEFAULT now(),
    dttmup timestamptz,
    dttmcl timestamptz,
    product_id int NOT NULL REFERENCES products (id),
    parameter_id int NOT NULL REFERENCES parameters (id),
    value_int int CHECK (value_int IS NOT NULL and value_text IS NULL and value_numeric IS NULL and value_int_arr IS NULL and value_text_arr IS NULL and value_jsonb IS NULL),
    value_text text,
    value_numeric numeric,
    value_int_arr int[],
    value_text_arr text[],
    value_jsonb jsonb,
    PRIMARY KEY (product_id, parameter_id)
);

-- Индекс на уникальное сочетание product_id и parameter_id создаётся автоматически, т.к. поля объявлены как PK.

-- !!! Проверка, что задано только одно значение параметра

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
    dttmup timestamptz,
    dttmcl timestamptz,
    pay_method text NOT NULL UNIQUE
);

-- Таблица "Цены"
/*
    Ограничения:

    1) поля product_id и unit_id - FK на соответствующие таблицы и не должны быть NULL,
    2) unit_amount имеет значение по умолчанию 1 и должно быть больше 0,
    3) mass (вес) может быть либо NULL либо, если задан, больше 0,
    4) цена price должна быть всегда > 0.
*/
CREATE TABLE IF NOT EXISTS prices
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    dttmup timestamptz,
    dttmcl timestamptz,
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
    dttmup timestamptz,
    dttmcl timestamptz,
    actuality_date date NOT NULL,
    manаger_id int NOT NULL REFERENCES users(id),
    note text
);

-- Индекс для поля с FK:
CREATE INDEX ON pricelists (manаger_id);

-- Таблица "Прайслист_товары"
/*

*/
CREATE TABLE IF NOT EXISTS pricelist_products
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    dttmup timestamptz,
    dttmcl timestamptz,
    pricelist_id int NOT NULL REFERENCES pricelists(id),
    product_id int NOT NULL REFERENCES products(id),
    price_id int NOT NULL REFERENCES prices(id)
);

-- Как отдать прайсы товару?
-- Как определить, какой прайс выбран при покупке товара?

-------------------------
-- ПОСТАВКИ ТОВАРОВ
-------------------------

-- Таблица "Поставки"

-- ограничение на тип операции: 1 или 0
CREATE TABLE IF NOT EXISTS deliveries
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    dttmup timestamptz,
    dttmcl timestamptz,
    operation smallint NOT NULL DEFAULT 1,
    supplier_id int NOT NULL REFERENCES suppliers(id)
);

-- Таблица "Товары в поставке"
-- amount > 0
CREATE TABLE IF NOT EXISTS delivery_items
(
    id bigserial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    dttmup timestamptz,
    dttmcl timestamptz,
    delivery_id int NOT NULL REFERENCES deliveries(id),
    product_id int NOT NULL REFERENCES products(id),
    price_id int NOT NULL REFERENCES prices(id),
    amount int 
);

-------------------------
-- ЗАКАЗЫ И ДОСТАВКА
-------------------------

-- Таблица "Способ доставки"
CREATE TABLE IF NOT EXISTS ship_methods
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    dttmup timestamptz,
    dttmcl timestamptz,
    ship_method text NOT NULL UNIQUE
);

-- Таблица "Заказы"
CREATE TABLE IF NOT EXISTS orders
(
    id bigserial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    dttmup timestamptz,
    dttmcl timestamptz,
    user_id int NOT NULL REFERENCES users(id),
    order_sum numeric NOT NULL,
    pay_method_id int NOT NULL REFERENCES pay_methods(id),
    ship_method_id int NOT NULL REFERENCES ship_methods(id),
    last_status_id int NOT NULL REFERENCES statuses(id)
);

-- Таблица "Товары в заказе"
CREATE TABLE IF NOT EXISTS order_items
(
    id bigserial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    dttmup timestamptz,
    dttmcl timestamptz,
    order_id bigint NOT NULL REFERENCES orders(id),
    product_id int NOT NULL REFERENCES products(id),
    price_id int NOT NULL REFERENCES orders(id),
    amount int NOT NULL DEFAULT 1
);

-- здесь просится создать уникальный индекс на 3 столбца

-- Таблица "Доставка"
CREATE TABLE IF NOT EXISTS shipping
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    dttmup timestamptz,
    dttmcl timestamptz,
    order_id bigint NOT NULL REFERENCES orders(id),
    ship_method_id int NOT NULL REFERENCES ship_methods(id),
    ship_date date,
    ship_price numeric DEFAULT 0,
    status_id int NOT NULL REFERENCES statuses(id)
);

-------------------------
-- ПРОЦЕССЫ
-------------------------

-- Таблица "История заказов"
CREATE TABLE IF NOT EXISTS order_history
(
    id bigserial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    dttmup timestamptz,
    dttmcl timestamptz,
    order_id bigint NOT NULL REFERENCES orders(id),
    status_id int NOT NULL REFERENCES statuses(id)
);
