# Описание ДЗ

1. Забрать стартовый репозиторий https://github.com/aeuge/otus-mysql-docker

    готово

1. Прописать sql скрипт для создания своей БД в init.sql

    Добавила скрипт создания базы данных.
    Разработала схему для БД сайта тестов quizgame, чтобы было с чем работать.

    [init.sql](/mysql/init.sql)

    Настроила docker-compose для работы со своей базой данных.

    [docker-compose.yml](/mysql/docker-compose.yml)

1. Проверить запуск и работу контейнера, следуя описанию в репозитории

    По описанию в репозитории не удалось запустить. Скачала image mysql:8 и внесла некоторые правки.

    Запустила процесс командой `docker-compose up quizgame`

    Контейнер запустила из десктопного приложения docker.

    Для подключения к БД использовала строку `mysql -u root -p12345 --port=3306 --protocol=tcp quizgame`

    [БД и объекты в ней](/mysql/bd.jpg)

1. Прописать кастомный конфиг - настроить innodb_buffer_pool и другие параметры по желанию

    Прописала несколько настроек в файле my.cnf

    [ссылка](/mysql/custom.conf/my.cnf)

    Значения переменных [до настройки](/mysql/settings_before.jpg)

    Значения переменных [после настройки и перезапуска](/mysql/settings_after.jpg)

## Задание повышенной сложности*

    Протестить сисбенчем - результат теста приложить в README

1. Подготовка: MySQL установлена на Ubyntu 22.04.

1. Создаём пользователя для тестов

    `CREATE USER test_user@'localhost' IDENTIFIED BY '5678';`
    `GRANT ALL PRIVILEGES on quizgame.* to test_user@'localhost';`
    
1.  Подключение пользователя осуществляется с помощью команды:

    `mysql -u otus -p'5678'`

1. В БД создано несколько таблиц (скрипты в файле /mysql/init.sql), все таблицы по умолчанию с движком InnoDB:

    +--------------------+
    | Tables_in_quizgame |
    +--------------------+
    | answers            |
    | categories         |
    | games              |
    | question_types     |
    | questions          |
    | states             |
    | tests              |
    | users              |
    +--------------------+

1. Подготовим таблицу

    `sysbench --mysql-host=localhost --mysql-user=test_user --mysql-password='5678' --db-driver=mysql --mysql-db=quizgame /usr/share/sysbench/oltp_read_write.lua prepare`
    
    Вывод в консоли:

    Creating table 'sbtest1'...
    Inserting 10000 records into 'sbtest1'
    Creating a secondary index on 'sbtest1'...

1. Потестим для начала производительность процессоров:

    `sysbench --test=cpu run`

    Результат: [ссылка](/mysql/result_cpu.jpg)

1. Запустим тест innodb

    `sysbench --mysql-host=localhost --mysql-user=test_user --mysql-password='5678' --db-driver=mysql --mysql-db=quizgame /usr/share/sysbench/oltp_read_write.lua run`

    Результат: [ссылка](/mysql/result_innodb.jpg)
    
1. Поменяем движок таблиц на Myisam.
    
    Пример на одной: `ALTER TABLE users engine myisam;`

    Выполним тест:

    `sysbench --mysql-host=localhost --mysql-user=test_user --mysql-password='5678' --db-driver=mysql --mysql-db=quizgame /usr/share/sysbench/oltp_read_write.lua run`

    Результат: [ссылка](/mysql/result_myisam.jpg)
    
1. Поменяем движок таблиц на Memory:
    
    Пример на одной: `ALTER TABLE states engine memory;`
    
    Выполним тест:

    `sysbench --mysql-host=localhost --mysql-user=test_user --mysql-password='5678' --db-driver=mysql --mysql-db=quizgame /usr/share/sysbench/oltp_read_write.lua run`

    Результат: [ссылка](/mysql/result_memory.jpg)

