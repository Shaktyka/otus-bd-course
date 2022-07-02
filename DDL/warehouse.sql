/*
    Скрипт для создания таблиц, представление и вью в схеме warehouse (склад).
    Выполняется после создания БД, схем и выдачи прав.
*/

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
    site_link text,
    reg_date date
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
    site_link text
);

ALTER TABLE suppliers OWNER to justcoffee;

COMMENT ON TABLE suppliers IS 'Поставщики';

-- Индексы:
CREATE INDEX ON suppliers (supplier);

-- Таблица "Категории товаров"
CREATE TABLE IF NOT EXISTS warehouse.categories
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    category text NOT NULL UNIQUE,
    slug text NOT NULL UNIQUE
);

ALTER TABLE categories OWNER to justcoffee;

COMMENT ON TABLE categories IS 'Категории товаров';

-- Индексы
CREATE INDEX ON categories (category, slug);

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
    photos text[],
    description_text text
);

ALTER TABLE products OWNER to justcoffee;

COMMENT ON TABLE products IS 'Товары';

-- Индексы
CREATE INDEX vendcode_product_idx ON products (vendor_code, product);
CREATE INDEX supplier_manufacturer_idx ON products (supplier_id, manufacturer_id);

-- Таблица "Продукт-категория"
CREATE TABLE IF NOT EXISTS warehouse.product_category
(
    product_id int NOT NULL REFERENCES products(id),
    category_id int NOT NULL REFERENCES categories(id),
    PRIMARY KEY (product_id, category_id)
);

ALTER TABLE product_category OWNER to justcoffee;

COMMENT ON TABLE product_category IS 'Связь товара и категории';

-- Таблица "Характеристики товаров"
CREATE TABLE IF NOT EXISTS warehouse.parameters
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
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

-- Таблица "Склад" (товары и их количества)
-- Добавляем сюда товары после поставок и списываем отсюда в ходе продаж.
CREATE TABLE IF NOT EXISTS warehouse.warehouse
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    product_id int NOT NULL REFERENCES products(id),
    article text NOT NULL,
    pricelist_id int NOT NULL REFERENCES pricelists(id),
    unit_id int NOT NULL REFERENCES units(id),
    unit_amount int NOT NULL DEFAULT 1 CHECK (unit_amount > 0),
    mass numeric CHECK (mass is null or mass > 0),
    price numeric NOT NULL CHECK (price > 0),
    amount int NOT NULL CHECK (amount >= 0)
);

ALTER TABLE warehouse OWNER to justcoffee;

COMMENT ON TABLE warehouse IS 'Товары и их количества на складе';
