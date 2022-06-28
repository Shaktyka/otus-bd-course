/*
    Скрипт предназначен для последовательного выполнения в pgAdmin частями.
*/

--------------------------------------------------
-- ОТКЛЮЧАЕТ КОННЕКТЫ И УДАЛЯЕТ СУЩЕСТВУЮЩУЮ БД
--------------------------------------------------

-- Переключиться суперпользователем на БД postgres;

-- Отключает все активные коннекты от удаляемой БД
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'justcoffee';

-- Удаляет БД:
DROP DATABASE justcoffee;

-- Удаляет пользователя-владельца БД:
DROP ROLE justcoffee;

------------------------------------------
-- СОЗДАЁТ ПОЛЬЗОВАТЕЛЯ - ВЛАДЕЛЬЦА БД
------------------------------------------

-- Создаёт роль (пользователя) с правом логина

CREATE ROLE justcoffee WITH
  LOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION
  PASSWORD '9996';

COMMENT ON ROLE justcoffee IS 'Пользователь для БД JustCoffee';

------------------------------------------
-- СОЗДАЁТ БД 
------------------------------------------

-- Создаёт БД justcoffee
CREATE DATABASE justcoffee
WITH
    TEMPLATE = template0
    OWNER = justcoffee
    ENCODING = 'UTF8'
    LC_COLLATE = 'ru_RU.UTF-8'
    LC_CTYPE = 'ru_RU.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

COMMENT ON DATABASE justcoffee
    IS 'База данных, владельцем которой будет пользователь justcoffee';

-- Даёт все права доступа пользователю justcoffee
GRANT ALL ON DATABASE justcoffee TO justcoffee;

------------------------------------------
-- СОЗДАТЬ СХЕМЫ
------------------------------------------

-- Подключиться к созданной БД

-- Запрещает всем польз-лям создание объектов в схеме public:
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

-- Создаёт схемы БД для проекта:
CREATE SCHEMA dicts;      -- справочники и т.п.
CREATE SCHEMA warehouse;  -- склад
CREATE SCHEMA orders;     -- заказы
CREATE SCHEMA processes;  -- процессы

---------------------------------------
-- ОБЩИЕ СУЩНОСТИ (схема dicts)
---------------------------------------

SET search_path TO dicts;

-- Таблица "Группы статусов"
CREATE TABLE IF NOT EXISTS dicts.status_groups (
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    status_group text NOT NULL UNIQUE
);

ALTER TABLE status_groups OWNER to justcoffee;

COMMENT ON TABLE status_groups IS 'Группы статусов';

-- Таблица "Статусы"
CREATE TABLE IF NOT EXISTS dicts.statuses
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    status_group_id int NOT NULL REFERENCES status_groups (id),
    status_name text NULL UNIQUE
);

ALTER TABLE statuses OWNER to justcoffee;

COMMENT ON TABLE statuses IS 'Статусы';

-- Индексы
CREATE INDEX ON statuses (status_group_id);

-- Таблица "Пользователи"
CREATE TABLE IF NOT EXISTS dicts.users
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
    gender smallint NOT NULL DEFAULT 1 CHECK (gender IN (1, 2)),
    status_id int NOT NULL REFERENCES statuses (id)
);

ALTER TABLE users OWNER to justcoffee;

COMMENT ON TABLE users IS 'Пользователи';

-- Индексы
CREATE INDEX ON users (status_id);
CREATE INDEX ON users (email) INCLUDE (password_hash);
CREATE INDEX ON users (phone);
CREATE INDEX user_names ON users ((last_name || ' ' || first_name));

-- Таблица "Типы сущностей"
CREATE TABLE IF NOT EXISTS dicts.object_types (
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    object_type text NOT NULL UNIQUE
);

ALTER TABLE object_types OWNER to justcoffee;

COMMENT ON TABLE object_types IS 'Типы сущностей';

-- Таблица "Адреса"
CREATE TABLE IF NOT EXISTS dicts.adresses
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

ALTER TABLE adresses OWNER to justcoffee;

COMMENT ON TABLE adresses IS 'Адреса';

-- Индексы
CREATE INDEX type_id_connect_idx ON adresses (object_id, object_type);
CREATE INDEX ON adresses (postal_code);
CREATE INDEX ON adresses (country);
CREATE INDEX ON adresses (region);

---------------------------
-- СКЛАД (схема warehouse)
---------------------------
SET search_path TO warehouse, dicts;

-- Таблица "Производители"
CREATE TABLE IF NOT EXISTS warehouse.manufacturers
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    manufacturer text NOT NULL UNIQUE,
    logo_link text NOT NULL,
    site_link text
);

ALTER TABLE manufacturers OWNER to justcoffee;

COMMENT ON TABLE manufacturers IS 'Производители';

-- Индексы
CREATE INDEX ON manufacturers (manufacturer);

-- Таблица "Поставщики"
CREATE TABLE IF NOT EXISTS warehouse.suppliers
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    supplier text NOT NULL UNIQUE,
    company_phone text,
    manager_id int NOT NULL REFERENCES users(id),
    site_link text
);

ALTER TABLE suppliers OWNER to justcoffee;

COMMENT ON TABLE suppliers IS 'Поставщики';

-- Индексы:
CREATE INDEX ON suppliers (supplier);
CREATE INDEX ON suppliers (manager_id);

-- Таблица "Категории товаров"
CREATE TABLE IF NOT EXISTS warehouse.categories
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    parent_id int NOT NULL REFERENCES categories(id),
    category text NOT NULL UNIQUE
);

ALTER TABLE categories OWNER to justcoffee;

COMMENT ON TABLE categories IS 'Категории товаров';

-- Индексы
CREATE INDEX ON categories (parent_id);
CREATE INDEX ON categories (category);

-- Таблица "Единицы измеренения"
CREATE TABLE IF NOT EXISTS warehouse.units
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcl timestamptz,
    unit text NOT NULL UNIQUE
);

ALTER TABLE units OWNER to justcoffee;

COMMENT ON TABLE units IS 'Единицы измеренения';

-- Таблица "Товары"
CREATE TABLE IF NOT EXISTS warehouse.products
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

ALTER TABLE products OWNER to justcoffee;

COMMENT ON TABLE products IS 'Товары';

-- Индексы
CREATE INDEX vendcode_product_category_idx ON products (vendor_code, product, category_id);
CREATE INDEX supplier_manufacturer_idx ON products (supplier_id, manufacturer_id);
CREATE INDEX ON products (status_id);

-- Таблица "Характеристики товаров"
CREATE TABLE IF NOT EXISTS warehouse.parameters
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcl timestamptz,
    parameter text NOT NULL UNIQUE
);

ALTER TABLE parameters OWNER to justcoffee;

COMMENT ON TABLE parameters IS 'Характеристики товаров';

-- Таблица "Товар_характеристика"
CREATE TABLE IF NOT EXISTS warehouse.product_params
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

ALTER TABLE product_params OWNER to justcoffee;

COMMENT ON TABLE parameters IS 'Связь товара с характеристикой';

-- Таблица "Способ оплаты"
CREATE TABLE IF NOT EXISTS warehouse.pay_methods
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    pay_method text NOT NULL UNIQUE
);

ALTER TABLE pay_methods OWNER to justcoffee;

COMMENT ON TABLE pay_methods IS 'Способ оплаты';

-- Таблица "Цены"
CREATE TABLE IF NOT EXISTS warehouse.prices
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    product_id int NOT NULL REFERENCES products(id),
    unit_id int NOT NULL REFERENCES units(id),
    unit_amount int NOT NULL DEFAULT 1 CHECK (unit_amount > 0),
    mass numeric CHECK (unit_amount is null or unit_amount > 0),
    price numeric NOT NULL CHECK (price > 0)
);

ALTER TABLE prices OWNER to justcoffee;

COMMENT ON TABLE prices IS 'Цены';

-- Индексы: 
CREATE INDEX ON prices (product_id);
CREATE INDEX ON prices (unit_id);

-- Таблица "Прайслисты"
CREATE TABLE IF NOT EXISTS warehouse.pricelists
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    actuality_date date NOT NULL,
    manаger_id int NOT NULL REFERENCES users(id)
);

ALTER TABLE pricelists OWNER to justcoffee;

COMMENT ON TABLE pricelists IS 'Прайслисты';

-- Индексы
CREATE INDEX ON pricelists (actuality_date);
CREATE INDEX ON pricelists (manаger_id);

-- Таблица "Прайслист_товары"
CREATE TABLE IF NOT EXISTS warehouse.pricelist_products
(
    dttmcr timestamptz NOT NULL DEFAULT now(),
    pricelist_id int NOT NULL REFERENCES pricelists(id),
    product_id int NOT NULL REFERENCES products(id),
    price_id int NOT NULL REFERENCES prices(id),
    PRIMARY KEY (product_id, price_id, pricelist_id)
);

ALTER TABLE pricelist_products OWNER to justcoffee;

COMMENT ON TABLE pricelist_products IS 'Связь прайслистов с товарами';

-- Таблица "Поставки"
CREATE TABLE IF NOT EXISTS warehouse.deliveries
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    operation smallint NOT NULL DEFAULT 1 CHECK (operation IN (1, 0)),
    supplier_id int NOT NULL REFERENCES suppliers(id)
);

ALTER TABLE deliveries OWNER to justcoffee;

COMMENT ON TABLE deliveries IS 'Поставки';

-- Индексы
CREATE INDEX ON deliveries (supplier_id);

-- Таблица "Товары в поставке"
CREATE TABLE IF NOT EXISTS warehouse.delivery_items
(
    dttmcr timestamptz NOT NULL DEFAULT now(),
    delivery_id int NOT NULL REFERENCES deliveries(id),
    product_id int NOT NULL REFERENCES products(id),
    price_id int NOT NULL REFERENCES prices(id),
    amount int NOT NULL DEFAULT 1 CHECK (amount > 0),
    PRIMARY KEY (delivery_id, product_id, price_id)
);

ALTER TABLE delivery_items OWNER to justcoffee;

COMMENT ON TABLE delivery_items IS 'Товары в поставке';

---------------------------------------
-- ЗАКАЗЫ и ДОСТАВКА (схема orders)
---------------------------------------
SET search_path TO warehouse, dicts, orders;

-- Таблица "Способ доставки"
CREATE TABLE IF NOT EXISTS orders.ship_methods
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    ship_method text NOT NULL UNIQUE
);

ALTER TABLE ship_methods OWNER to justcoffee;

COMMENT ON TABLE ship_methods IS 'Способ доставки';

-- Таблица "Заказы" (партицированная)
CREATE TABLE orders.orders
(
    id serial NOT NULL,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    user_id int NOT NULL REFERENCES users(id),
    order_sum numeric NOT NULL CHECK (order_sum > 0),
    pay_method_id int NOT NULL REFERENCES pay_methods(id),
    ship_method_id int NOT NULL REFERENCES ship_methods(id),
    address_id int NOT NULL REFERENCES adresses(id),
    last_status_id int NOT NULL REFERENCES statuses(id),
    PRIMARY KEY (id, dttmcr)
) PARTITION BY RANGE (dttmcr);

CREATE TABLE orders_y2022 PARTITION OF orders
    FOR VALUES FROM ('2022-01-01') TO ('2023-01-01');
    
CREATE TABLE orders_y2023 PARTITION OF orders
    FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');

CREATE TABLE orders_y2024 PARTITION OF orders
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

ALTER TABLE orders OWNER to justcoffee;

COMMENT ON TABLE orders IS 'Заказы';

-- Индексы
CREATE INDEX ON orders(id, dttmcr); -- по ключу партицирования

CREATE INDEX ON orders (user_id);
CREATE INDEX ON orders (pay_method_id);
CREATE INDEX ON orders (ship_method_id);
CREATE INDEX ON orders (address_id);
CREATE INDEX ON orders (last_status_id);

-- Товары в заказе:
CREATE TABLE IF NOT EXISTS orders.order_items
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    order_id int NOT NULL,
    order_date timestamptz NOT NULL,
    product_id int NOT NULL REFERENCES products(id),
    price_id int NOT NULL REFERENCES prices(id),
    amount int NOT NULL DEFAULT 1 CHECK (amount > 0),
    FOREIGN KEY (order_id, order_date) REFERENCES orders (id, dttmcr)
);

ALTER TABLE order_items OWNER to justcoffee;

COMMENT ON TABLE order_items IS 'Товары в заказе';

-- Таблица "Доставка"
CREATE TABLE IF NOT EXISTS orders.shipping
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    order_id int NOT NULL,
    order_date timestamptz NOT NULL,
    ship_method_id int NOT NULL REFERENCES ship_methods(id),
    ship_date date CHECK (ship_date >= current_date),
    ship_price numeric DEFAULT 0 CHECK (ship_price = 0 or ship_price > 0),
    status_id int NOT NULL REFERENCES statuses(id),
    FOREIGN KEY (order_id, order_date) REFERENCES orders (id, dttmcr)
);

ALTER TABLE shipping OWNER to justcoffee;

COMMENT ON TABLE shipping IS 'Доставка';

-- Индексы
CREATE INDEX order_date_status_idx ON shipping (order_id, ship_date, status_id);
CREATE INDEX ON shipping (ship_method_id);

-------------------------------
-- ПРОЦЕССЫ (схема processes)
-------------------------------

SET search_path TO warehouse, dicts, orders, processes;

-- Таблица "История смены статусов" (партицированая по типу объектов)
CREATE TABLE IF NOT EXISTS processes.statuses_history
(
    id bigserial NOT NULL,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    dttmend timestamptz CHECK (dttmend IS NULL or dttmend >= dttmcr),
    object_type int NOT NULL REFERENCES object_types(id),
    object_id int NOT NULL,
    status_id int NOT NULL REFERENCES statuses(id),
    PRIMARY KEY (id, object_type)
) PARTITION BY LIST (object_type);

-- Партиция по типу объекта 1
CREATE TABLE statuses_history_t1 PARTITION OF statuses_history
    FOR VALUES IN (1);

-- Партиция по типу объекта 2
CREATE TABLE statuses_history_t2 PARTITION OF statuses_history
    FOR VALUES IN (2);

-- Партиция по типу объекта 3
CREATE TABLE statuses_history_t3 PARTITION OF statuses_history
    FOR VALUES IN (3);

ALTER TABLE statuses_history OWNER to justcoffee;

COMMENT ON TABLE statuses_history IS 'История смены статусов';

-- Индексы
CREATE INDEX object_status_type_idx ON statuses_history (object_id, status_id, object_type);

------------------------------------------------
-- СОЗДАЁТ ПРЕДСТАВЛЕНИЯ (views)
------------------------------------------------

-- Список неподтверждённых пользователей (по статусу):
CREATE OR REPLACE VIEW dicts.v_unconfirmed_users AS
    SELECT
        u.id,
        to_char(u.dttmcr, 'DD.MM.YYYY') as reg_date,
        concat( u.last_name || ' ', u.first_name, ' ' || u.middle_name ) as fio,
        u.email,
        u.phone
    FROM dicts.users AS u
    WHERE u.status_id = 1  -- условно предполагаем, что статус такой
    ORDER BY u.dttmcr DESC;


-- Список новых доставок за сегодня:
CREATE OR REPLACE VIEW orders.v_new_shipping AS
    SELECT
        s.id,
        s.dttmcr,
        s.order_id,
        o.user_id,
        sm.ship_method,
        to_char(s.ship_date, 'DD.MM.YYYY') as ship_date,
        s.ship_price
    FROM orders.shipping AS s
    INNER JOIN orders.orders AS o ON s.order_id = o.id
    LEFT JOIN orders.ship_methods AS sm ON s.ship_method_id = s.id
    WHERE 
        s.dttmcr::date >= current_date
        and s.status_id = 2; -- условно предполагаем, что статус такой
