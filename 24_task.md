# SQL-выборка

## Напишите запрос по своей базе с inner join

Выбрать темы, для которых созданы категории, для вывода на главной странице приложения:

```
SELECT
    t.id,
    t.theme,
    t.image_link
FROM themes AS t
INNER JOIN categories AS c ON t.id = c.theme_id; 
```

## Напишите запрос по своей базе с left join

Выбрать пользователей, которые ещё не создали ни одного теста, чтобы отправить им рассылку с призывом создать свой первый тест:

```
SELECT
    u.id,
    u.nick,
    u.email
FROM users AS u
LEFT JOIN tests AS t ON u.id = t.user_id
WHERE t.user_id is null
ORDER BY u.dttmcr;
```

## Напишите 5 запросов с WHERE с использованием разных операторов 

Опишите, для чего вам в проекте нужна такая выборка данных.

### Выборка по полю JSON-типа

Выбрать пользователей и тесты, в которых количество вопросов больше 15. Мы считаем, что слишком длинные сессии плохо влияют на удержание пользователей.

```
SELECT
    u.id,
    u.nick,
    t.id,
    t.name
FROM users AS u
INNER JOIN tests AS t ON u.id = t.user_id
WHERE t.test_config->>'$.custom_questions_amount' > 15;
```

### Выбрать пользователей, зарегистрировавшихся в августе 2022 года

Такие выборки могут использоваться для когортного анализа, например, для подсчёта количества успешно пройденных тестов по каждому пользователю (см. ниже).

```
SELECT 
    u.id
FROM users AS u
WHERE MONTH(u.dttmcr) = 8 AND YEAR(u.dttmcr) = 2022;
```

### Выбрать идентификаторы определённой группы пользователей и количество успешно пройденных ими тестов

Запрос с подзапросом и использованием IN.

```
SELECT
    g.user_id,
    count(*) as win_games
FROM games AS g
WHERE g.user_id IN (
    SELECT 
        u.id
    FROM users AS u
    WHERE MONTH(u.dttmcr) = 8 AND YEAR(u.dttmcr) = 2022
)
WHERE g.test_questions_amount = g.right_answers_amount
GROUP BY g.user_id;
```

### Выбрать все тесты для 9 класса

В приложении есть простой поиск по названиям тестов.

```
SELECT
  t.id,
  DATE_FORMAT(t.dttmcr, '%m.%d.%Y') AS dt_create,
  u.nick,
  c.category,
  t.name,
  t.description,
  t.test_config
FROM tests AS t
INNER JOIN users AS u ON t.user_id = u.id
INNER JOIN categories AS c ON t.category_id = c.id
WHERE 
    t.name LIKE '%SQL%'
    AND t.is_public = TRUE
    AND t.status = 'publicated'
ORDER BY t.name;
```

### Посчитать, сколько тестов запускалось по дням с 1 по 10 сентября включительно

Хотим оценить вовлечённость пользователей в первой декаде сентября, и если это количество ниже наших метрик, предпринять действия для повышения активности.

```
SELECT 
    DATE(t.dttmcr) as date,
    count(*) AS tests_amount
FROM games AS t
WHERE DATE(t.dttmcr) BETWEEN '2022-09-01' AND '2022-09-10'
GROUP BY DATE(t.dttmcr)
ORDER BY date;
```
