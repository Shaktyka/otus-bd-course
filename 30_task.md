# Резервное копирование и восстановление

Задача - восстановить конкретную таблицу из сжатого и шифрованного бэкапа.

В материалах приложен файл бэкапа backup.xbstream.gz.des3 и дамп структуры базы otus - otus-db.dmp
Бэкап был выполнен с помощью команды
xtrabackup --databases='otus' --backup --stream=xbstream | gzip - | openssl des3 -salt -k "password" > backup.xbstream.gz.des3
Требуется восстановить таблицу otus.articles из бэкапа.
