-- Скрипты для одномоментного развёртывания базы данных проекта JustCoffee

------------------------------------------
-- СОЗДАНИЕ ПОЛЬЗОВАТЕЛЯ - ВЛАДЕЛЬЦА БД
------------------------------------------

-- Создаёт роль (пользователя) с правом логина

-- DROP ROLE IF EXISTS justcoffee;

CREATE ROLE justcoffee WITH
  LOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION;

COMMENT ON ROLE justcoffee IS 'Пользователь для БД JustCoffee';

------------------------------------------
-- СОЗДАНИЕ БД
------------------------------------------

-- Создаёт БД justcoffee
CREATE DATABASE justcoffee
    WITH
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

-- Запрещает всем польз-лям создание объектов в схеме public
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

-- Создаёт схему БД для проекта (схема одна)
-- DROP SCHEMA justcoffee CASCADE;
CREATE SCHEMA justcoffee AUTHORIZATION justcoffee;

-- Устанавливает путь поиска на схему justcoffee
SET search_path TO justcoffee;

------------------------------------------
-- СОЗДАНИЕ СУЩНОСТЕЙ БД
------------------------------------------

-- ОБЩИЕ СУЩНОСТИ

-- Таблица "Группы статусов"
CREATE TABLE IF NOT EXISTS justcoffee.status_groups (
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    status_group text NOT NULL UNIQUE
);

ALTER TABLE status_groups OWNER to justcoffee;

COMMENT ON TABLE status_groups IS 'Группы статусов';

-- Таблица "Статусы"
CREATE TABLE IF NOT EXISTS justcoffee.statuses
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
CREATE TABLE IF NOT EXISTS justcoffee.users
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
CREATE TABLE IF NOT EXISTS justcoffee.object_types (
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    object_type text NOT NULL UNIQUE
);

ALTER TABLE object_types OWNER to justcoffee;

COMMENT ON TABLE object_types IS 'Типы сущностей';

-- Таблица "Адреса"
CREATE TABLE IF NOT EXISTS justcoffee.adresses
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
CREATE INDEX type_id_connect_idx ON (object_id, object_type);
CREATE INDEX ON adresses (postal_code);
CREATE INDEX ON adresses (country);
CREATE INDEX ON adresses (region);


-- ТОВАРЫ (СКЛАД)

-- Таблица "Производители"
CREATE TABLE IF NOT EXISTS justcoffee.manufacturers
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    manufacturer text NOT NULL UNIQUE,
    logo_link text NOT NULL,
    site_link text
);

ALTER TABLE manufacturers OWNER to justcoffee;

COMMENT ON TABLE status_groups IS 'Производители';

-- Индексы
CREATE INDEX ON manufacturers (manufacturer);

-- Таблица "Поставщики"

CREATE TABLE IF NOT EXISTS justcoffee.suppliers
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
CREATE TABLE IF NOT EXISTS justcoffee.categories
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
CREATE TABLE IF NOT EXISTS justcoffee.units
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcl timestamptz,
    unit text NOT NULL UNIQUE
);

ALTER TABLE units OWNER to justcoffee;

COMMENT ON TABLE units IS 'Единицы измеренения';

-- Таблица "Товары"
CREATE TABLE IF NOT EXISTS justcoffee.products
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
CREATE TABLE IF NOT EXISTS justcoffee.parameters
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcl timestamptz,
    parameter text NOT NULL UNIQUE
);

ALTER TABLE parameters OWNER to justcoffee;

COMMENT ON TABLE parameters IS 'Характеристики товаров';

-- Таблица "Товар_характеристика"
CREATE TABLE IF NOT EXISTS justcoffee.product_params
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


-- ЦЕНЫ

-- Таблица "Способ оплаты"
CREATE TABLE IF NOT EXISTS justcoffee.pay_methods
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    pay_method text NOT NULL UNIQUE
);

ALTER TABLE pay_methods OWNER to justcoffee;

COMMENT ON TABLE pay_methods IS 'Способ оплаты';

-- Таблица "Цены"
CREATE TABLE IF NOT EXISTS justcoffee.prices
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
CREATE INDEX prices (product_id);
CREATE INDEX prices (unit_id);

-- Таблица "Прайслисты"
CREATE TABLE IF NOT EXISTS justcoffee.pricelists
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
CREATE TABLE IF NOT EXISTS justcoffee.pricelist_products
(
    dttmcr timestamptz NOT NULL DEFAULT now(),
    pricelist_id int NOT NULL REFERENCES pricelists(id),
    product_id int NOT NULL REFERENCES products(id),
    price_id int NOT NULL REFERENCES prices(id),
    PRIMARY KEY (product_id, price_id, pricelist_id)
);

ALTER TABLE pricelist_products OWNER to justcoffee;

COMMENT ON TABLE pricelist_products IS 'Связь прайслистов с товарами';


-- ПОСТАВКИ ТОВАРОВ

-- Таблица "Поставки"
CREATE TABLE IF NOT EXISTS justcoffee.deliveries
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
CREATE TABLE IF NOT EXISTS justcoffee.delivery_items
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


-- ЗАКАЗЫ ПОЛЬЗОВАТЕЛЕЙ И ДОСТАВКА

-- Таблица "Способ доставки"
CREATE TABLE IF NOT EXISTS justcoffee.ship_methods
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    ship_method text NOT NULL UNIQUE
);

ALTER TABLE ship_methods OWNER to justcoffee;

COMMENT ON TABLE ship_methods IS 'Способ доставки';

-- Таблица "Заказы"
CREATE TABLE IF NOT EXISTS justcoffee.orders
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

ALTER TABLE orders OWNER to justcoffee;

COMMENT ON TABLE orders IS 'Заказы';

-- Индексы
CREATE INDEX ON orders (user_id);
CREATE INDEX ON orders (pay_method_id);
CREATE INDEX ON orders (ship_method_id);
CREATE INDEX ON orders (address_id);
CREATE INDEX ON orders (last_status_id);

-- Таблица "Товары в заказе"
CREATE TABLE IF NOT EXISTS justcoffee.order_items
(
    dttmcr timestamptz NOT NULL DEFAULT now(),
    order_id int NOT NULL REFERENCES orders(id),
    product_id int NOT NULL REFERENCES products(id),
    price_id int NOT NULL REFERENCES orders(id),
    amount int NOT NULL DEFAULT 1 CHECK (amount > 0),
    PRIMARY KEY (order_id, product_id, price_id)
);

ALTER TABLE order_items OWNER to justcoffee;

COMMENT ON TABLE order_items IS 'Товары в заказе';

-- Таблица "Доставка"
CREATE TABLE IF NOT EXISTS justcoffee.shipping
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    order_id bigint NOT NULL REFERENCES orders(id),
    ship_method_id int NOT NULL REFERENCES ship_methods(id),
    ship_date date CHECK (ship_date >= current_date),
    ship_price numeric DEFAULT 0 CHECK (ship_price = 0 or ship_price > 0),
    status_id int NOT NULL REFERENCES statuses(id)
);

ALTER TABLE shipping OWNER to justcoffee;

COMMENT ON TABLE shipping IS 'Доставка';

-- Индексы
CREATE INDEX order_date_status_idx ON shipping (order_id, ship_date, status_id);
CREATE INDEX ON shipping (ship_method_id);
 

-- ПРОЦЕССЫ

-- Таблица "История смены статусов"
CREATE TABLE IF NOT EXISTS justcoffee.statuses_history
(
    id bigserial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    dttmend timestamptz CHECK (dttmend IS NULL or dttmend >= dttmcr)
    object_type int NOT NULL REFERENCES object_types(id),
    object_id int NOT NULL,
    status_id int NOT NULL REFERENCES statuses(id)
);

ALTER TABLE statuses_history OWNER to justcoffee;

COMMENT ON TABLE statuses_history IS 'История смены статусов';

-- Индексы
CREATE INDEX object_status_type_idx ON statuses_history (object_id, status_id, type_id);
