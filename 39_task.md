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

Подключение к MongoDB в контейнере:
```
docker exec -it mongodb mongosh
```

Для запуска и остановки контейнера:
```
docker stop mongodb
docker start mongodb
```

## Заполнение данными

Для генерации JSON-данных был использован сервис https://json-generator.com/

Создаёт базу данных customersDB:
```
use customersDB
```

Добавляет данные в коллекцию customers:
```
db.customers.insertMany( <данные_из_файла_generated.json> )
```

Результат добавления:
```
{
  acknowledged: true,
  insertedIds: {
    '0': '1',
    '1': '2',
    '2': '3',
    '3': '4',
    '4': '5',
    '5': '6',
    '6': '7',
    '7': '8',
    '8': '9',
    '9': '10'
  }
}
```

Можно загрузить данные сразу из файла. Для этого запишем команду сразу в файл в формате:
```
db.customers.insertMany([
{...},
{...},
{...}
])
```

Затем с помощью функции load() загрузим данные из файла:
```
load("files/generated.json")
```

## Запросы данных на выборку и обновление

## Создание индексов и сравнение производительности

