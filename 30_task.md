# Резервное копирование и восстановление

**Задача - восстановить конкретную таблицу из сжатого и шифрованного бэкапа**

В материалах приложен файл бэкапа backup.xbstream.gz.des3 и дамп структуры базы otus - otus-db.dmp
Бэкап был выполнен с помощью команды
```
xtrabackup --databases='otus' --backup --stream=xbstream | gzip - | openssl des3 -salt -k "password" > backup.xbstream.gz.des3
```

Требуется восстановить таблицу otus.articles из бэкапа.

## Выполнение

1. Создать таблицу в БД.

1. Загрузить бэкап куда-то на сервер.

    ```
    sudo mkdir -p /tmp/backups/world
    sudo chmod -R 777 /tmp/backups/world
    cd /tmp/backups/
    ```

1. Расшифровываем файл

    `xtrabackup --decrypt=AES256 --encrypt-key="U2FsdGVkX19VPN7VM+lwNI0fePhjgnhgqmDBqbF3Bvs=" --target-dir=/data/backup/`

1. Распаковываем из gz

    `gzip -dk backup.xbstream.gz`

1. Распаковать бэкап после xbstream
    
    `xbstream -x < backup.xbstream`

1. После расшифровки нужна подготовка:

    > Note that the streamed backup will need to be prepared before restoration. 
    > Streaming mode does not prepare the backup.

    `xtrabackup --prepare --target-dir=/data/backup/`

1. Останавливаем MySQL:

    `sudo systemctl stop mysql`

    Для восстановления одной таблицы как быть с каталогами mysql?

1. Запускаем восстановление бэкапа:

    ``

1. Запустить сервис MySQL:

    `sudo systemctl start mysql`


------------ Заметки -----------

?  
-- полное восстановление:
это скопировать резервную копию в datadir 
`xtrabackup --copy-back --target-dir=/mysql/backup`

?
--tables 

ALTER TABLE test.export_test DISCARD TABLESPACE; 
ALTER TABLE test.export_test IMPORT TABLESPACE;

To restore a backup with xtrabackup you can use the --copy-back or --move-back options.

Percona XtraBackup can export a table that is contained in its own .ibd file
This method only works on individual .ibd files.
