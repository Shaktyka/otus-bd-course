# Типы данных в MySQL

Описание/Пошаговая инструкция выполнения домашнего задания:
1) Проанализировать типы данных в своем проекте, изменить при необходимости. 
В README указать, что на что поменялось и почему.
2) Добавить тип JSON в структуру. Проанализировать какие данные могли бы там храниться. 
Привести примеры SQL для добавления записей и выборки.

Первая версия создания БД и сущностей приведена в файле /mysql/init.sql.

## Описание БД quizgame

1. Quizgame - веб-приложение для прохождения тестов. 
1. Пользователи могут регистрироваться и проходить уже существующие тесты или создавать свои. 
1. Тесты создаются по темам (программирование, математика и т.д.), внутри которых размещаются по категориям (например, внутри программирования: базы данных, Python, JavaScript и т.д.).
1. Ттесты могут быть публичными (от разработчиков сайта для всех) и приватными (видимыми только своему создателю).
1. У тестов может быть один из статусов, например: в разработке, на модерации, опубликован.
1. Тест состоит из вопросов с возможностью выбора одного или нескольких ответов. Можно создавать много вопросов для теста, но ограничить количество вопросов для сессии (по умолчанию 10). 
1. Можно настроить вывод вопросов в тесте в случайном порядке.
1. Вопросы в тестах могут быть разных типов, т.е. вопросы могут отличаться способом выбора ответов. 
1. После каждого прохождения теста пользователю показывается результат игры.
1. Пользователь может видеть историю прохождения тестов.

## Скрипты создания сущностей

Схема базы данных - по ссылке https://dbdiagram.io/d/61cca2dc3205b45b73d13086 

### Состояния (статусы)

```
CREATE TABLE states (
    id int UNIQUE PRIMARY KEY NOT NULL AUTO_INCREMENT,
    dttmcr timestamp NOT NULL default now(),
    code char(3) NOT NULL, 
    state varchar(100) NOT NULL,
    description varchar(255)
);
```

### Пользователи

```
CREATE TABLE users (
    id int UNIQUE PRIMARY KEY NOT NULL AUTO_INCREMENT,
    dttmcr timestamp NOT NULL default now(),
    bdate date,
    email varchar(100) UNIQUE NOT NULL,
    password varchar(100) NOT NULL,
    referrer_id int,
    state_id int NOT NULL
);
```

```ALTER TABLE users ADD FOREIGN KEY (state_id) REFERENCES states (id);```

```ALTER TABLE users ADD FOREIGN KEY (referrer_id) REFERENCES users (id);```

### Темы тестов

```
CREATE TABLE themes (
    id int UNIQUE PRIMARY KEY NOT NULL AUTO_INCREMENT,
    dttmcr timestamp NOT NULL default now(),
    theme varchar(100) UNIQUE NOT NULL,
    description varchar(255)
);
```

### Категории тестов

```
CREATE TABLE categories (
    id int UNIQUE PRIMARY KEY NOT NULL AUTO_INCREMENT,
    dttmcr timestamp NOT NULL default now(),
    theme_id int NOT NULL,
    category varchar(100) NOT NULL,
    description varchar(255)
);
```

```ALTER TABLE categories ADD FOREIGN KEY (theme_id) REFERENCES themes (id);```

### Тесты

```
CREATE TABLE tests (
    id int UNIQUE PRIMARY KEY NOT NULL AUTO_INCREMENT,
    dttmcr timestamp NOT NULL default now(),
    user_id int NOT NULL, 
    category_id int NOT NULL,
    name varchar(255) NOT NULL, 
    description varchar(400), 
    is_public boolean DEFAULT 0, 
    state_id int NOT NULL
);
```

```ALTER TABLE tests ADD FOREIGN KEY (user_id) REFERENCES users (id);```

```ALTER TABLE tests ADD FOREIGN KEY (category_id) REFERENCES categories (id);```

```ALTER TABLE tests ADD FOREIGN KEY (state_id) REFERENCES states (id);```

### Типы вопросов

```
CREATE TABLE question_types (
    id int UNIQUE PRIMARY KEY NOT NULL AUTO_INCREMENT,
    dttmcr timestamp NOT NULL default now(),
    type_name varchar(100) NOT NULL,
    config json 
);
```

### Вопросы теста

```
CREATE TABLE questions (
    id int UNIQUE PRIMARY KEY NOT NULL AUTO_INCREMENT,
    dttmcr timestamp NOT NULL default now(),
    test_id int NOT NULL,
    question varchar(255) NOT NULL,
    description varchar(400),
    question_type_id int NOT NULL
);
```

```ALTER TABLE questions ADD FOREIGN KEY (test_id) REFERENCES tests (id);```

```ALTER TABLE questions ADD FOREIGN KEY (question_type_id) REFERENCES question_types (id);```

### Ответы на вопросы

```
CREATE TABLE answers (
    id int UNIQUE PRIMARY KEY NOT NULL AUTO_INCREMENT,
    dttmcr timestamp NOT NULL default now(),
    question_id int NOT NULL,
    answer varchar(255) NOT NULL, 
    is_right boolean DEFAULT 0 
);
```

```ALTER TABLE answers ADD FOREIGN KEY (question_id) REFERENCES questions (id);```

### Прохождение тестов

```
CREATE TABLE games (
    id int UNIQUE PRIMARY KEY NOT NULL AUTO_INCREMENT,
    dttmcr timestamp NOT NULL default now(),
    user_id int NOT NULL,
    test_id int NOT NULL,
    question_id int NOT NULL,
    answers json, 
    result boolean DEFAULT 0 
);
```

```ALTER TABLE games ADD FOREIGN KEY (user_id) REFERENCES users (id);```

```ALTER TABLE games ADD FOREIGN KEY (test_id) REFERENCES tests (id);```

```ALTER TABLE games ADD FOREIGN KEY (question_id) REFERENCES questions (id);```

## Запросы для добавления данных



## Запросы для извлечения данных

