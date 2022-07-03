---------------------------------------
-- ОБЩИЕ СУЩНОСТИ (схема dicts)
-- Таблицы, представления и др. сущности
---------------------------------------
/*
    -- Группы статусов
    -- Статусы
    -- Пользователи
    -- Типы сущностей
    -- Адреса
    -- view Неподтверждённые польз-ли
*/

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
    status_name text NULL
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


------------------------------------------------
-- ПРЕДСТАВЛЕНИЯ (views)
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
    WHERE u.status_id = 5  -- условно предполагаем, что статус такой
    ORDER BY u.dttmcr DESC;

ALTER VIEW dicts.v_unconfirmed_users OWNER TO justcoffee;
