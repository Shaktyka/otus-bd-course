# Типы данных в MySQL

## Описание проекта quizgame

1. Quizgame - веб-приложение для прохождения тестов. 
1. Пользователи могут регистрироваться и проходить уже существующие тесты или создавать свои. 
1. Тесты создаются по темам (программирование, математика и т.д.), внутри которых размещаются по категориям (например, внутри программирования: базы данных, Python, JavaScript и т.д.).
1. Тесты могут быть публичными (от разработчиков сайта для всех) и приватными (видимыми только своему создателю).
1. Тест состоит из вопросов с возможностью выбора одного или нескольких ответов. Можно создавать много вопросов для теста, но ограничить количество вопросов для сессии (по умолчанию 10). 
1. Вопросы в тесте могут выводиться в случайном порядке и и нет - это определяется конфигом теста.
1. Вопросы в тестах могут быть разных типов, т.е. cпособ выбора ответов может различаться (так называемый тип игры). 
1. После каждого прохождения теста пользователю показывается результат.
1. Пользователь может видеть историю прохождения тестов.

## Скрипты создания сущностей

Схема базы данных - по ссылке https://dbdiagram.io/d/61cca2dc3205b45b73d13086 

Общие принципы выбора типов:
1. Для всех идентификаторов строк выбран тип int AUTO_INCREMENT, в проекте наверняка не будет больших чисел, поэтому bigint не использовала. 
1. UUID также не использовала - глобальная уникальность не нужна.
1. У каждой записи есть дата и время создания, выбрала тип timestamp, он занимает меньше места. 
1. Для текстовых типов данных использовала тип varchar с ограничением по длине. Этот тип хорошо подходит для хранения небольших строк текста.

### Пользователи

При регистрации в таблицу записываются email с ограничением UNIQUE для всей таблицы, хэш пароля, дата рождения с типом date. Пользователи могут приходить по реферальным ссылкам, поэтому предусмотрена запись id пригласившего пользователя.

```
CREATE TABLE IF NOT EXISTS users (
    id int PRIMARY KEY AUTO_INCREMENT,
    dttmcr timestamp NOT NULL default CURRENT_TIMESTAMP,
    bdate date,
    email varchar(100) UNIQUE NOT NULL,
    password_hash varchar(100) NOT NULL,
    referrer_id int
);
```

Внешний ключ на поле id этой же таблицы пользователей (id реферера):

`ALTER TABLE users ADD FOREIGN KEY (referrer_id) REFERENCES users (id);`

### Темы тестов

Темы для главной страницы. Крупные разделы, задаваемые разработчиками. Название темы небольшое, описание - внутреннее поле, может быть довольно длинным. У каждой темы есть пиктограмма, в таблице на неё хранится ссылка с макимальной длиной 150 символов.

```
CREATE TABLE IF NOT EXISTS themes (
    id int PRIMARY KEY AUTO_INCREMENT,
    dttmcr timestamp NOT NULL default CURRENT_TIMESTAMP,
    theme varchar(100) UNIQUE NOT NULL,
    image_link varchar(255) NOT NULL,
    description varchar(255)
);
```

### Категории тестов

Внутри темы тесты разбиваются по категориям. У каждой категории есть ссылка на идентификатор темы, к которой она относится. Название категории достаточно короткое, в пределах 100 символов. Есть небольшое описание description, которое может быть внешним. Категории создаются разработчиками.

```
CREATE TABLE IF NOT EXISTS categories (
    id int PRIMARY KEY AUTO_INCREMENT,
    dttmcr timestamp NOT NULL default CURRENT_TIMESTAMP,
    theme_id int NOT NULL,
    category varchar(100) NOT NULL,
    description varchar(255)
);
```

Внешний ключ к таблице тем (themes):

`ALTER TABLE categories ADD FOREIGN KEY (theme_id) REFERENCES themes (id);`

### Тесты

Таблица для описания сущностей "тест". Тесты создаются разработчиками и пользователями, поэтому есть ссылка на таблицу пользователей (user_id). У теста может быть одна категория (ссылка category_id), достаточно длинное название и описание, которые отображаются на сайте.

Есть флаг is_public, который показывает, является ли тест "публичным", т.е. доступен ли всем пользователям сайта или нет.

Поле статус status представляет собой тип ENUM: ограниченный список возможных значений состояния теста: в разработке, на модерации, опубликован. ENUM для этого хорошо подходит.

В поле test_config может записываться пользовательская конфигурация теста, например, количество вопросов для показа за одну игру, брать ли случайные вопросы и т.п. Специальных настроек может не быть, серфис предполагает наличие дефолтного конфига, поэтому это поле не обязательное. 

Пример структуры JSON test_config:

```
{
    "custom_questions_amount": 12,
    "shuffled_questions": true,
    "shuffled_answers": true
}
```

```
CREATE TABLE IF NOT EXISTS tests (
    id int PRIMARY KEY AUTO_INCREMENT,
    dttmcr timestamp NOT NULL default CURRENT_TIMESTAMP,
    user_id int NOT NULL, 
    category_id int NOT NULL,
    name varchar(120) NOT NULL, 
    description varchar(255), 
    test_config json,
    is_public boolean DEFAULT FALSE,
    status ENUM('in_progress', 'on_moderation', 'publicated', 'deleted') NOT NULL
);
```

Добавляет внешний ключ на таблицу пользователей:

`ALTER TABLE tests ADD FOREIGN KEY (user_id) REFERENCES users (id);`

Добавляет внешний ключ на таблицу категорий:

`ALTER TABLE tests ADD FOREIGN KEY (category_id) REFERENCES categories (id);`

### Типы вопросов

По сути, типы игры: способы выбора ответов на вопросы. 
Имеет короткое название и небольшое описание для внутреннего использования. Каждый тип имеет свои настройки, собранные в конфиг с типом JSON, что позволяет расширять конфиги в дальнейшем. Типов вопросов будет немного, поэтому JSON будет быстро парситься. 

```
CREATE TABLE IF NOT EXISTS question_types (
    id int PRIMARY KEY AUTO_INCREMENT,
    dttmcr timestamp NOT NULL default CURRENT_TIMESTAMP,
    type_name varchar(100) NOT NULL,
    description varchar(255),
    config json 
);
```

### Вопросы теста

Список вопросов, относящихся к тестам, - это определяется ссылкой на таблицу tests (поле test_id). Вопрос может иметь достаточно длинное название и описание, отображаемые на сайте. У каждого вопроса есть обязательная ссылка на тип вопроса - поле question_type_id.
У вопроса может быть иллюстрация, ссылка на неё в типе varchar записывается в поле image_link.

Возможно, ответы для вопросов можно было бы собрать в поле с типом json вместо того, чтобы выносить в отдельную таблицу.

```
CREATE TABLE IF NOT EXISTS questions (
    id int PRIMARY KEY AUTO_INCREMENT,
    dttmcr timestamp NOT NULL default CURRENT_TIMESTAMP,
    test_id int NOT NULL,
    question varchar(255) NOT NULL,
    description varchar(400),
    question_type_id int NOT NULL,
    image_link varchar(255)
);
```

Добавляет внешний ключ на таблицу tests:

`ALTER TABLE questions ADD FOREIGN KEY (test_id) REFERENCES tests (id);`

Добавляет внешний ключ на таблицу question_types:

`ALTER TABLE questions ADD FOREIGN KEY (question_type_id) REFERENCES question_types (id);`

### Ответы на вопросы

Списки ответов на вопросы конкретных тестов.
Для каждого вопроса предполагается 4 варианта ответа. 
Один или более ответов могут быть правильными, но обязательно один из ответов должен быть правильным.
Правильные ответы отмечаются единичкой в поле is_right c типом boolean. Добавлено дефолтное значение FALSE, которое говорит о том, что по умолчанию ответ считается неверным. 
У каждого ответа есть обязательная ссылка на вопрос (поле question_id).
Ответ может содержать иллюстрацию (поле image_link).

```
CREATE TABLE IF NOT EXISTS answers (
    id int PRIMARY KEY AUTO_INCREMENT,
    dttmcr timestamp NOT NULL default CURRENT_TIMESTAMP,
    question_id int NOT NULL,
    answer varchar(255) NOT NULL, 
    image_link varchar(255),
    is_right boolean NOT NULL DEFAULT FALSE 
);
```

Добавляет внешний ключ на таблицу questions:

`ALTER TABLE answers ADD FOREIGN KEY (question_id) REFERENCES questions (id);`

### Прохождение тестов (запуск тестов)

Это денормализованная таблица для записи тестов, запускаемых пользователем, и результатов тестов, соотвественно, чтобы было удобно считать и выводить статистику по каждому игроку и по базе в целом.
В поле dttmend записывается дата и время окончания теста, чтобы считать продолжительность прохождения теста.
В test_questions_amount записывается общее количество вопросов теста, которое при запуске игры берётся из конфига (чтобы правильно считать результаты, если со временем кол-во изменяется).
В поле right_answers_amount записывается количество вопросов, на которые игрок дал правильные ответы. Значение пополняется на +1 при записи правильного ответа в таблицу game_answers.

```
CREATE TABLE IF NOT EXISTS games (
    id int PRIMARY KEY AUTO_INCREMENT,
    dttmcr timestamp NOT NULL default CURRENT_TIMESTAMP,
    dttmend timestamp,
    user_id int NOT NULL,
    test_id int NOT NULL,
    test_questions_amount tinyint UNSIGNED NOT NULL, 
    right_answers_amount tinyint UNSIGNED NOT NULL DEFAULT 0
);
```

Добавляет внешний ключ на таблицу users:

`ALTER TABLE games ADD FOREIGN KEY (user_id) REFERENCES users (id);`

Добавляет внешний ключ на таблицу tests:

`ALTER TABLE games ADD FOREIGN KEY (test_id) REFERENCES tests (id);`

### Прохождение тестов (демонстрируемые вопросы)

Каждая строка таблицы - это результат ответа пользователя на каждый из вопросов теста из таблицы games.
Поля с идентификаторами игры и вопроса - обязательные.
В поле answers записывается json с ответами, которые дал пользователь, это удобно, если ответов предполагается много.
В поле result с типом boolean записывается, правильно ли пользователь ответил на вопрос или нет. 
По умолчанию стоит значение FALSE - пользователь ответил неверно.

```
CREATE TABLE IF NOT EXISTS game_answers (
    id int PRIMARY KEY AUTO_INCREMENT,
    dttmcr timestamp NOT NULL default CURRENT_TIMESTAMP,
    game_id int NOT NULL,
    question_id int NOT NULL,
    answers json, 
    result boolean NOT NULL DEFAULT FALSE 
);
```

Добавляет внешний ключ на таблицу games:

`ALTER TABLE game_answers ADD FOREIGN KEY (game_id) REFERENCES games (id);`

Добавляет внешний ключ на таблицу questions:

`ALTER TABLE game_answers ADD FOREIGN KEY (question_id) REFERENCES questions (id);`
