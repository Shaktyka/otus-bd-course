# Базовые возможности mongodb

Необходимо:

- установить MongoDB одним из способов: ВМ, докер;
- заполнить данными;
- написать несколько запросов на выборку и обновление данных

Сдача ДЗ осуществляется в виде миниотчета.

Задание повышенной сложности*

- создать индексы и сравнить производительность.

## Установка MongoDB

MongoDB была установлена на MacOS в докер-контейнер.

```
docker pull mongo
```

Результат:
```
REPOSITORY       TAG       IMAGE ID       CREATED        SIZE
mongo            latest    1a5c8f74cf95   9 days ago     667MB
```

Создаёт VOLUME для хранения данных:

```
cd /Users/elena/Documents
mkdir mongodata
```

Запуск контейнера с MongoDB:

```
docker run -it -v /Users/elena/Documents/mongodata:/data/db -p 27017:27017 --name mongodb -d mongo
```

Подключение к контейнеру:
```
docker exec -it mongodb bash
mongo -host localhost -port 27017  
```

Для запуска и остановки контейнера:
```
docker stop mongodb
docker start mongodb
```

## Заполнение данными

## Запросы данных на выборку и обновление

## Создание индексов и сравнение производительности

