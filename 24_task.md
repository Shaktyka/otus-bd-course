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

### 1

```

```

### 2

```

```

### 3

```

```

### 4

```

```

### 5

```

```