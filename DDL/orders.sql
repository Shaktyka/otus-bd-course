/*
    Скрипт для создания таблиц, представление и вью в схеме orders (заказы).
    Выполняется после создания БД, схем и выдачи прав.
*/

---------------------------------------
-- ЗАКАЗЫ и ДОСТАВКА (схема orders)
---------------------------------------
SET search_path TO warehouse, dicts, orders;

-- Таблица "Способ оплаты"
CREATE TABLE IF NOT EXISTS orders.pay_methods
(
    id serial NOT NULL UNIQUE PRIMARY KEY,
    dttmcr timestamptz NOT NULL DEFAULT now(),
    pay_method text NOT NULL UNIQUE
);
ALTER TABLE pay_methods OWNER to justcoffee;
COMMENT ON TABLE pay_methods IS 'Способ оплаты';

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


------------------------------------------------
-- ПРЕДСТАВЛЕНИЯ (views)
------------------------------------------------

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

ALTER VIEW orders.v_new_shippings OWNER TO justcoffee;

-- Создаёт материализованное представление для сборки массива категорий для товаров, 
-- чтобы при формировании списка продуктов быстро получать список категорий.
-- Обновляться будет по триггеру на таблице warehouse.product_category (товар-категория).

CREATE MATERIALIZED VIEW orders.products_cat_arr AS 
    SELECT
        pc.product_id,
        array_agg(pc.category_id) as cat_arr
    FROM warehouse.product_category AS pc
    JOIN products AS p ON pc.product_id = p.id
    GROUP BY pc.product_id;

ALTER VIEW orders.products_cat_arr OWNER TO justcoffee;

CREATE INDEX ON products_cat_arr (product_id);
