# Установка СУБД PostgreSQL

1. СУБД PostgreSQL 14 версии установлена локально на MacOS.

    [Установка Postgres 14](/images/install_bd.png.png)

1. С помощью pgAdmin cоздан кластер dev для подключения и создания базы данных проекта

    [Создано подключение dev](/images/create_cluster.png)

1. Создана БД justcoffe и одноимённый пользователь, который стал владельцем этой БД.
   Отдельный пользователь создан для реализации базовых настроек безопасности и разделения прав.

    [База данных и пользователь](/images/create_bd_for_user.png)

    Скрипт создания пользователя:

    CREATE ROLE justcoffee WITH
        LOGIN
        NOSUPERUSER
        INHERIT
        NOCREATEDB
        NOCREATEROLE
        NOREPLICATION
        ENCRYPTED PASSWORD 'ххххх';

    COMMENT ON ROLE justcoffee IS 'Пользователь для БД JustCoffee';

1. Создан и протестирован коннект пользователя justcoffee к одноимённой БД 

    [Подключение пользователя работает](/images/user_connect.png)
