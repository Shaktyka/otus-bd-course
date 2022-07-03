------------------------------------------------------
-- СКЛАД (схема warehouse)
-- Таблицы, представления и др. сущности для склада
------------------------------------------------------
/*
  -- Единицы измеренения
  -- Производители
  -- Поставщики
  -- Категории товаров
  -- Характеристики товаров
  -- Товары
  -- Товар-категория
  -- Товар-характеристика
  -- Прайслисты
  -- Прайслист-товары
  -- Поставки
  -- Товары в поставке
  -- Склад
*/

SET search_path TO warehouse, dicts;


-- Таблица "Единицы измеренения"
CREATE TABLE IF NOT EXISTS warehouse.units
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcl timestamptz,
    unit text NOT NULL UNIQUE
);
ALTER TABLE units OWNER to justcoffee;
COMMENT ON TABLE units IS 'Единицы измеренения';


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
-- Индексы
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


-- Таблица "Характеристики товаров"
CREATE TABLE IF NOT EXISTS warehouse.parameters
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    parameter text NOT NULL UNIQUE
);
ALTER TABLE parameters OWNER to justcoffee;
COMMENT ON TABLE parameters IS 'Характеристики товаров';


-- Таблица "Товары"
CREATE TABLE IF NOT EXISTS warehouse.products
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    upc text NOT NULL UNIQUE,
    product text NOT NULL,
    photo text,
    descr_text text,
    unit_id int REFERENCES units(id),
    amount int NOT NULL DEFAULT 1,
    mass numeric
);
ALTER TABLE products OWNER to justcoffee;
COMMENT ON TABLE products IS 'Товары';
-- Индексы
CREATE INDEX upc_product_idx ON products (upc, product);


-- Таблица "Товар-категория"
CREATE TABLE IF NOT EXISTS warehouse.product_category
(
    product_id int NOT NULL REFERENCES products(id),
    category_id int NOT NULL REFERENCES categories(id),
    PRIMARY KEY (product_id, category_id)
);
ALTER TABLE product_category OWNER to justcoffee;
COMMENT ON TABLE product_category IS 'Связь товара и категории';


-- Таблица "Товар_характеристика"
CREATE TABLE IF NOT EXISTS warehouse.product_params
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    product_id int NOT NULL REFERENCES products (id),
    parameter_id int NOT NULL REFERENCES parameters (id),
    value_int int,
    value_text text,
    value_numeric numeric,
    value_int_arr int[],
    value_text_arr text[],
    value_jsonb jsonb
);
ALTER TABLE product_params OWNER to justcoffee;
COMMENT ON TABLE parameters IS 'Связь товара с характеристикой';
CREATE UNIQUE INDEX product_parameter_idx ON product_params (product_id, parameter_id);


-- Таблица "Прайслисты" (шапка прайслиста)
CREATE TABLE IF NOT EXISTS warehouse.pricelists
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    date_beg date NOT NULL,
    date_end date NOT NULL,
    supplier_id int REFERENCES suppliers(id)
);
ALTER TABLE pricelists OWNER to justcoffee;
COMMENT ON TABLE pricelists IS 'Прайслисты';
-- Индексы
CREATE INDEX ON pricelists (date_beg, date_end, supplier_id);


-- Таблица "Прайслист_товары"
CREATE TABLE IF NOT EXISTS warehouse.pricelist_items
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    pricelist_id int NOT NULL REFERENCES pricelists(id),
    upc text NOT NULL,
    manufacturer_id int NOT NULL REFERENCES manufacturers(id),
    price_per_unit numeric NOT NULL
);
ALTER TABLE pricelist_items OWNER to justcoffee;
COMMENT ON TABLE pricelist_products IS 'Списки товаров в прайслистах';
-- Индексы
CREATE INDEX ON pricelist_items (pricelist_id);
CREATE INDEX ON pricelist_items (manufacturer_id);


-- Таблица "Поставки" 
-- 1 - приход, 0 - возврат
CREATE TABLE IF NOT EXISTS warehouse.deliveries
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    operation smallint NOT NULL DEFAULT 1 CHECK (operation IN (1, 0)),
    supplier_id int NOT NULL REFERENCES suppliers(id),
    pricelist_id int NOT NULL REFERENCES pricelists(id)
);

ALTER TABLE deliveries OWNER to justcoffee;
COMMENT ON TABLE deliveries IS 'Поставки';
-- Индексы
CREATE INDEX ON deliveries (supplier_id, pricelist_id);


-- Таблица "Товары в поставке"
CREATE TABLE IF NOT EXISTS warehouse.delivery_items
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    delivery_id int NOT NULL REFERENCES deliveries(id),
    upc text NOT NULL,
    amount int NOT NULL DEFAULT 1 CHECK (amount > 0)
);
ALTER TABLE delivery_items OWNER to justcoffee;
COMMENT ON TABLE delivery_items IS 'Товары в поставке';
-- Индексы
CREATE INDEX ON delivery_items (delivery_id, upc);


-- Таблица "Склад" (товары и их количества)
-- Добавляем сюда товары после поставок и списываем отсюда в ходе продаж
CREATE TABLE IF NOT EXISTS warehouse.warehouse
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    product_id int NOT NULL REFERENCES products(id),
    articul text NOT NULL,
    pricelist_id int NOT NULL REFERENCES pricelists(id),
    amount int NOT NULL CHECK (amount >= 0),
    status_id int NOT NULL REFERENCES statuses(id)
);
ALTER TABLE warehouse OWNER to justcoffee;
COMMENT ON TABLE warehouse IS 'Товары и их количества на складе';
-- Индексы
CREATE INDEX ON warehouse (articul, product_id) INCLUDE (pricelist_id);
