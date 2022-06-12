-- ОБЩИЕ СПРАВОЧНИКИ

-- Таблица "Группы статусов"

CREATE TABLE IF NOT EXISTS status_groups (
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    dttmup timestamptz,
    dttmcl timestamptz,
    status_group text NOT NULL UNIQUE,
    description text
);

-- Таблица "Статусы"
CREATE TABLE IF NOT EXISTS statuses
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    dttmup timestamptz,
    dttmcl timestamptz,
    status_group_id int NOT NULL REFERENCES status_groups (id) ON DELETE CASCADE,
    status text NULL UNIQUE,
    description text
);

-- Таблица "Пользователи"
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
    address jsonb,
    phone text,
    gender smallint DEFAULT 1, -- как прописать ограничение на 1 или 2? тип создать?
    status_id int NOT NULL REFERENCES statuses (id)
);

-- ТОВАРЫ (СКЛАД)

-- Таблица "Производители"
CREATE TABLE IF NOT EXISTS manufacturers
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    dttmup timestamptz,
    dttmcl timestamptz,
    manufacturer text NOT NULL UNIQUE,
    address jsonb,
    logo text,
    site text
);

-- Таблица "Поставщики"
CREATE TABLE IF NOT EXISTS suppliers
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    dttmup timestamptz,
    dttmcl timestamptz,
    supplier text NOT NULL UNIQUE,
    company_phone text,
    address_full jsonb NOT NULL,
    postal_code text,
    country text,
    region text,
    city text,
    address text,
    contacts_full jsonb,
    manager_id int NOT NULL REFERENCES users(id),
    site text,
    description text
);

-- Таблица "Категории товаров"
CREATE TABLE IF NOT EXISTS categories
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    dttmup timestamptz,
    dttmcl timestamptz,
    parent_id int NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    category text NOT NULL UNIQUE,
    description text
);

-- Таблица "Единицы измеренения"
CREATE TABLE IF NOT EXISTS units
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    dttmup timestamptz,
    dttmcl timestamptz,
    unit text NOT NULL UNIQUE
);

-- Таблица "Товары"
CREATE TABLE IF NOT EXISTS products
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    dttmup timestamptz,
    dttmcl timestamptz,
    vendor_code text NOT NULL,
    product text NOT NULL,
    manufacturer_id int NOT NULL REFERENCES manufacturers(id) ON DELETE CASCADE,
    supplier_id int NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
    category_id int NOT NULL REFERENCES categories(id),
    photos text[],
    description text,
    status_id int NOT NULL REFERENCES statuses(id)
);

-- Таблица "Характеристики товаров"
CREATE TABLE IF NOT EXISTS parameters
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    dttmup timestamptz,
    dttmcl timestamptz,
    parameter text NOT NULL UNIQUE
);

-- Таблица "Товар_характеристика"
-- Здесь д/б ограничение на ввод значений только в одном столбце из группы
CREATE TABLE IF NOT EXISTS product_params
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    dttmup timestamptz,
    dttmcl timestamptz,
    product_id int NOT NULL REFERENCES products (id) ON DELETE CASCADE,
    parameter_id int NOT NULL REFERENCES parameters (id) ON DELETE CASCADE,
    value_int int,
    value_text text,
    value_numeric numeric,
    value_int_arr int[],
    value_text_arr text[],
    value_jsonb jsonb
);

-- ЦЕНЫ

-- Таблица "Способ оплаты"
CREATE TABLE IF NOT EXISTS pay_methods
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    dttmup timestamptz,
    dttmcl timestamptz,
    pay_method text NOT NULL UNIQUE
);

-- Таблица "Цены"
CREATE TABLE IF NOT EXISTS prices
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    dttmup timestamptz,
    dttmcl timestamptz,
    product_id int NOT NULL REFERENCES products(id),
    unit_id int NOT NULL REFERENCES units(id),
    unit_amount int NOT NULL,
    weight int,
    price numeric NOT NULL
);

-- Таблица "Прайслисты"
CREATE TABLE IF NOT EXISTS pricelists
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    dttmup timestamptz,
    dttmcl timestamptz,
    actuality_date date NOT NULL,
    maneger_id int NOT NULL REFERENCES users(id),
    description text
);

-- Таблица "Прайслист_товары"
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

-- ПОСТАВКИ ТОВАРОВ

-- Таблица "Поставки"

-- ограничение на тип операции: 1 или 0
CREATE TABLE IF NOT EXISTS deliveries
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    dttmup timestamptz,
    dttmcl timestamptz,
    operation tinyint NOT NULL DEFAULT 1,
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

-- ЗАКАЗЫ И ДОСТАВКА

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

-- Таблица "Способ доставки"
CREATE TABLE IF NOT EXISTS ship_methods
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    dttmup timestamptz,
    dttmcl timestamptz,
    ship_method text NOT NULL UNIQUE
);

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

-- ПРОЦЕССЫ

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
