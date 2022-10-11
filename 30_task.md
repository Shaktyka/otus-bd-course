# Резервное копирование и восстановление

**Задача - восстановить конкретную таблицу из сжатого и шифрованного бэкапа**

В материалах приложен файл бэкапа backup.xbstream.gz.des3 и дамп структуры базы otus - otus-db.dmp
Бэкап был выполнен с помощью команды
```
xtrabackup --databases='otus' --backup --stream=xbstream | gzip - | openssl des3 -salt -k "password" > backup.xbstream.gz.des3
```

Требуется восстановить таблицу otus.articles из бэкапа.

## Выполнение

1. Установить xtrabackup 

    [Документация](https://learn.percona.com/hubfs/Manuals/Percona_Xtra_Backup/Percona-XtraBackup-8.0/PerconaXtraBackup-8.0.29-22.pdf)

1. Создать БД и таблицу для неё

    ```
    DROP TABLE IF EXISTS `city`;
    /*!40101 SET @saved_cs_client     = @@character_set_client */;
    /*!50503 SET character_set_client = utf8mb4 */;
    CREATE TABLE `city` (
        `ID` int NOT NULL AUTO_INCREMENT,
        `Name` char(35) NOT NULL DEFAULT '',
        `CountryCode` char(3) NOT NULL DEFAULT '',
        `District` char(20) NOT NULL DEFAULT '',
        `Population` int NOT NULL DEFAULT '0',
        PRIMARY KEY (`ID`),
        KEY `CountryCode` (`CountryCode`)
    ) ENGINE=InnoDB AUTO_INCREMENT=4080 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
    ```

1. Загрузить бэкап в дректорию на сервер

    ```
    sudo mkdir -p /tmp/backups/world
    sudo chmod -R 777 /tmp/backups/world
    cd /tmp/backups/
    ```

1. Расшифровываем файл

    ```
    openssl des3 -salt -k "password" -d -in /tmp/backups/world/backup_des.xbstream.gz-195395-7bc8ae.des3 -out /tmp/backups/world/backup_des.xbstream.gz
    ```

1. Распаковываем из gz

    `gzip -d backup_des.xbstream.gz `

1. Распаковать бэкап после xbstream
    
    `mkdir stream`

    `cd stream`

    `xbstream -x < ../backup_des.xbstream`

    ```
    -rw-r----- 1 root root      475 Oct 11 05:26 backup-my.cnf
    -rw-r----- 1 root root      156 Oct 11 05:26 binlog.000018
    -rw-r----- 1 root root       16 Oct 11 05:26 binlog.index
    -rw-r----- 1 root root     3381 Oct 11 05:26 ib_buffer_pool
    -rw-r----- 1 root root 12582912 Oct 11 05:26 ibdata1
    drwxr-x--- 2 root root     4096 Oct 11 05:26 mysql
    -rw-r----- 1 root root 25165824 Oct 11 05:26 mysql.ibd
    drwxr-x--- 2 root root     4096 Oct 11 05:26 performance_schema
    drwxr-x--- 2 root root     4096 Oct 11 05:26 sys
    -rw-r----- 1 root root 16777216 Oct 11 05:26 undo_001
    -rw-r----- 1 root root 16777216 Oct 11 05:26 undo_002
    drwxr-x--- 2 root root     4096 Oct 11 05:26 world
    -rw-r----- 1 root root       18 Oct 11 05:26 xtrabackup_binlog_info
    -rw-r----- 1 root root      102 Oct 11 05:26 xtrabackup_checkpoints
    -rw-r----- 1 root root      508 Oct 11 05:26 xtrabackup_info
    -rw-r----- 1 root root     2560 Oct 11 05:26 xtrabackup_logfile
    -rw-r----- 1 root root       39 Oct 11 05:26 xtrabackup_tablespaces
    ```

Percona XtraBackup can export a table that is contained in its own .ibd file
This method only works on individual .ibd files.

1. После расшифровки нужна подготовка:

    > Note that the streamed backup will need to be prepared before restoration. 
    > Streaming mode does not prepare the backup.

    `xtrabackup --prepare --target-dir=/data/backup/`

1. Из всего бэкапа извлечь бэкап отдельной таблицы

    ``

1. Отключение таблицы от tablespace

    ```
    ALTER TABLE test.export_test DISCARD TABLESPACE; 
    ALTER TABLE test.export_test IMPORT TABLESPACE;
    ```

1. Запускаем восстановление бэкапа:

    ``

