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
load("files/generated.js")
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
    ...
    name: 'Alyssa Martinez',
    gender: 'female',
    company: 'PHARMACON',
    ...
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

Найдём пользователей, у которых возраст меньше 30:
```
db.customers.find ({age: {$lt : 30}})
```

Результат: 2 записи с id 1 и 9 и возрастом 26 и 23 соответственно.

Найдём пользователей, зарегистрировавшихся в сентябре 2020 года:
```
db.customers.find ({registered: {$regex : "2020-09"}})
```

Результат: 1 пользователь
```
[
  {
    _id: '5',
    ...
    registered: '2020-09-09T12:12:36 -05:00',
    ...
    languages: [ 'english' ]
  }
]
```

### Запросы на обновление

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

### Первый кейс

Использован датасет магазина Superstore (USA): https://www.kaggle.com/datasets/roopacalistus/superstore

Датасет содержит более 10 000 записей.

Данные были загружены с помощью MongoDB Compass в коллекцию `customersDB.superstore`.

![После загрузки](/images/mongo/loaded.jpg)

Посмотрим статистику при фильтрации данных по городу Henderson: выбран 51 документ. 

Чтобы немного увеличить время выполнения запроса, включила desc-сортировку ({field: -1}).

![Henderson](/images/mongo/henderson.jpg)

Создадим индекс по полю City с учётом обратной сортировки:
```
db.superstore.createIndex( {"City": -1} )
```

Посмотрим созданные индексы:
```	
db.superstore.getIndexes()
```

Результат в консоли:
```
[
  { v: 2, key: { _id: 1 }, name: '_id_' },
  { v: 2, key: { City: -1 }, name: 'City_-1', sparse: false }
]
```

После запуска Explain Plan видим, что 
- время выполнения запроса уменьшилось,
- был использован созданный индекс
- был прочитан всего 51 документ

Скриншот вкладки Explain Plan:

![После создания индекса](/images/mongo/index.jpg)

### Второй кейс

Коллекция пользователей `customersDB.managers` содержит 239 записей.

Данные искусственно сгенерированы, имеют следующую структуру:

```
[
  {
    _id: ObjectId("636688444032702512887fce"),
    id: '6366728df7d4153ed72613da',
    email: 'tameka_welch@letpro.tours',
    roles: [ 'owner', 'member' ],
    apiKey: '07c05d65-7418-4179-b14e-bc53df8bca8e',
    profile: {
      dob: '1991-09-29',
      name: 'Tameka Welch',
      about: 'Ad deserunt dolore incididunt aliqua adipisicing officia anim fugiat. Aliqua labore et culpa reprehenderit aute sunt aliqua tempor consequat minim do.',
      address: '35 Prescott Place, Strykersville, District Of Columbia',
      company: 'Letpro',
      location: { lat: -65.332318, long: 108.224043 }
    },
    username: 'tameka91',
    createdAt: '2012-11-30T08:29:33.889Z',
    updatedAt: '2012-12-01T08:29:33.889Z'
  }
]
```

Создадим индекс на поле, по которому хотим искать в тексте:
```
db.managers.createIndex({"profile.about": "text"})
```

Результат:
```
customersDB> db.managers.createIndex({"profile.about": "text"})
profile.about_text
```

Проверим в MongoDB Compass результаты запроса со следующим фильтром:
```
{$text: {$search: "Dolore"}}
```

Результат в Explayn Plan:

![текстовый_индекс](/images/mongo/text.jpg)

Видно использование индекса:

![текст_индекс](/images/mongo/text_index.jpg)
