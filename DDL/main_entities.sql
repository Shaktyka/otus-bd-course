/*
    Скрипт предназначен для последовательного выполнения в pgAdmin частями.
    Включает:
    -- удаление БД 
    -- создание пользователей
    -- создание БД и схем
    -- выдачу прав
*/

--------------------------------------------------
-- ОТКЛЮЧАЕТ КОННЕКТЫ И УДАЛЯЕТ СУЩЕСТВУЮЩУЮ БД
--------------------------------------------------

-- Переключиться суперпользователем к БД postgres;

-- Отключает все активные коннекты от удаляемой БД
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'justcoffee';

-- Удаляет БД:
DROP DATABASE justcoffee;

------------------------------------------
-- СОЗДАЁТ РОЛИ И ПОЛЬЗОВАТЕЛЕЙ
------------------------------------------

-- Создаёт роль (пользователя) с правами логина, наследования, создания БД и ролей, чтобы работать из-под него:
CREATE ROLE justcoffee WITH
    LOGIN
    NOSUPERUSER
    INHERIT
    CREATEDB
    CREATEROLE
    NOREPLICATION
    PASSWORD '****';

COMMENT ON ROLE justcoffee IS 'Пользователь-админ БД JustCoffee';

-- Создаёт роль для команды разработчиков:
CREATE ROLE developer;

-- Создаёт роль "читателя данных", например, для аналитика:
CREATE ROLE reporting_user;

-- Срздаёт пользователя-разработчика:
CREATE USER dev_yura WITH LOGIN PASSWORD '****';

-- Создаёт пользователя-аналитика:
CREATE USER report_mihail WITH LOGIN PASSWORD '****';

-- Присоедняет пользователей к ролям:
GRANT developer TO dev_yura;

GRANT reporting_user TO report_mihail;

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

------------------------------------------
-- СОЗДАЁТ СХЕМЫ
------------------------------------------

-- Подключиться к созданной БД

-- Даёт все права на БД пользователю justcoffee
GRANT ALL ON DATABASE justcoffee TO justcoffee;

-- Запрещает всем польз-лям создание объектов в схеме public:
REVOKE CREATE ON SCHEMA public FROM public;

-- запрещает коннектиться к БД из-под пароля public:
REVOKE ALL ON DATABASE justcoffee FROM public;

-- Создаёт схемы БД для проекта:
CREATE SCHEMA dicts AUTHORIZATION justcoffee;      -- справочники и т.п.
CREATE SCHEMA warehouse AUTHORIZATION justcoffee;  -- склад
CREATE SCHEMA orders AUTHORIZATION justcoffee;     -- заказы
CREATE SCHEMA processes AUTHORIZATION justcoffee;  -- процессы

-- Даёт права польз-лям (на примере аналитика) на использование схем:

GRANT USAGE ON SHEMA dicts TO reporting_user;
GRANT USAGE ON SHEMA warehouse TO reporting_user;
GRANT USAGE ON SHEMA orders TO reporting_user;
GRANT USAGE ON SHEMA processes TO reporting_user;
GRANT CREATE ON SCHEMA processes TO reporting_user; -- аналитик сможет создавать тут отчёты

-- Дальше нужно будет дать права на таблицы в этих схемах
