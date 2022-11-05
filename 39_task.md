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

Загрузка образа MongoDB:
```
docker pull mongo
```

Результат:
```
REPOSITORY       TAG       IMAGE ID       CREATED        SIZE
mongo            latest    1a5c8f74cf95   9 days ago     667MB
```

Создание VOLUME для хранения данных:

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

Добавление данных в коллекцию customers:
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

### запросы на выборку

Посчитаем количество неактивных пользователей:
```
db.customers.find({isActive: false}).count()
```

Результат (4 документа):
```
customersDB> db.customers.find({isActive: false}).count()
4
```

Выведем пользователей женского пола:
```
db.customers.find({gender: "female"})
```

Результат: 4 документа с id 3, 4, 7, 10. Как пример - одна из записей:
```
{
    _id: '10',
    index: 9,
    guid: '580f29bf-8f0f-407c-a08a-7bf94061e365',
    isActive: true,
    balance: '$2,724.64',
    picture: 'http://placehold.it/32x32',
    age: 32,
    eyeColor: 'brown',
    name: 'Alyssa Martinez',
    gender: 'female',
    company: 'PHARMACON',
    email: 'alyssamartinez@pharmacon.com',
    phone: '+1 (891) 501-2384',
    address: '393 Lloyd Street, Cazadero, Oklahoma, 819',
    about: 'Officia exercitation veniam laboris occaecat ea ea laborum. Eu voluptate aute quis do anim. Eu pariatur qui eu tempor nisi sunt sunt incididunt. Enim quis minim fugiat et aute sint eiusmod anim. Non ullamco aliquip labore aliqua qui qui anim nostrud Lorem ex. Amet aute amet irure Lorem duis amet voluptate ex aliqua adipisicing incididunt in. Labore cillum amet laborum exercitation proident eiusmod sunt incididunt sunt.\r\n',
    registered: '2016-01-23T08:46:59 -05:00',
    latitude: -23.622055,
    longitude: 8.871669,
    tags: [ 'tempor', 'ullamco', 'et', 'ut', 'ea', 'exercitation', 'Lorem' ],
    friends: [
      { id: 0, name: 'Aurelia Rivas' },
      { id: 1, name: 'Estes Sanford' },
      { id: 2, name: 'Victoria Winters' }
    ]
  }
```

Найдём пользователей, у которых в массиве друзей имя первого друга `Aurelia Rivas`
```
db.customers.find({"friends.0.name": "Aurelia Rivas"})
```

Результат в примере выше, это пользователь с id 10

Выведем имена пользователей с сортировкой их по именам:
```
db.customers.find({}, {name:1, _id: 0}).sort({name: 1})
```

Результат:
```
[
  { name: 'Alyssa Martinez' },
  { name: 'Carrillo Simmons' },
  { name: 'Cherie Velasquez' },
  { name: 'Ford Nieves' },
  { name: 'Frost Watkins' },
  { name: 'Guadalupe Hyde' },
  { name: 'Hall Phillips' },
  { name: 'Kinney Cooke' },
  { name: 'Rosetta Wiley' },
  { name: 'Vang Stout' }
]
```

Посмотрим, какие уникальные цвета глаз присутствуют у наших пользователей:
```
db.customers.distinct("eyeColor")
```

Результат:
```
customersDB> db.customers.distinct("eyeColor")
[ 'blue', 'brown', 'green' ]
```

Найдём пользователей, у которых возрас меньше 30:
```
db.customers.find ({age: {$lt : 30}})
```

Результат: 2 записи с id 1 и 9 и возрастом 26 и 23 соответственно.

### запросы на обновление

Обновим возраст пользователя с id 1 с 26 до 25:
```
db.customers.updateOne({_id : "1"}, {$set: {age : 25}})
```

Результат:
```
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
```

Новые данные в документе:
```
{
    _id: '1',
    index: 0,
    guid: '1a22d584-02a7-4914-bf40-a69f89dcc549',
    isActive: true,
    balance: '$3,976.47',
    picture: 'http://placehold.it/32x32',
    age: 25,
    ...
```

Добавим во все документы поле languages с английским языком по умолчанию:
```
db.customers.updateMany({}, {$set: {languages: ["english"]}})
```

Результат:
```
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 10,
  modifiedCount: 10,
  upsertedCount: 0
}
```

На примере пользователя с id 2 посмотрим результат:
```
_id: '2',
index: 1,
...
languages: [ 'english' ]
```

Пользователю с id 1 добавим новый тег в массив тегов:
```
db.customers.updateOne({_id: "1"}, {$addToSet: {tags: "special"}})
```

Результат:
```
tags: [
      'cupidatat', 'deserunt',
      'eu',        'laborum',
      'ad',        'ut',
      'quis',      'special'
    ],
```

Этому же пользователю добавим ещё одного друга:
```
db.customers.updateOne({_id: "1"}, {$addToSet: {friends: { id: 3, name: "Helen Blane" }}})
```

Результат:
```
friends: [
    { id: 0, name: 'Wilson Fields' },
    { id: 1, name: 'Brenda Gallagher' },
    { id: 2, name: 'Collier Bond' },
    { id: 3, name: 'Helen Blane' }
]
```

## Создание индексов и сравнение производительности

