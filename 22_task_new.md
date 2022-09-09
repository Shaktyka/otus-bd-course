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

Схема базы данных - по ссылке https://dbdiagram.io/d/631b69b50911f91ba574c6ac  

Общие принципы выбора типов:
1. Для всех идентификаторов строк выбран тип int AUTO_INCREMENT, в проекте наверняка не будет больших чисел, поэтому bigint не использовала. 
1. UUID также не использовала - глобальная уникальность не нужна.
1. У каждой записи есть дата и время создания, выбрала тип timestamp, он занимает меньше места. 
1. Для текстовых типов данных использовала тип varchar с ограничением по длине. Этот тип хорошо подходит для хранения небольших строк текста.

### Пользователи

При регистрации в таблицу записываются email с ограничением UNIQUE для всей таблицы, md5 хэш пароля, дата рождения с типом date. Пользователи могут приходить по реферальным ссылкам, поэтому предусмотрена запись id пригласившего пользователя.

```
CREATE TABLE IF NOT EXISTS users (
    id int PRIMARY KEY AUTO_INCREMENT,
    created_at timestamp NOT NULL default CURRENT_TIMESTAMP,
    nick varchar(100) NOT NULL,
    bdate date,
    email varchar(100) UNIQUE NOT NULL,
    password_hash varchar(32) NOT NULL,
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
    created_at timestamp NOT NULL default CURRENT_TIMESTAMP,
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
    created_at timestamp NOT NULL default CURRENT_TIMESTAMP,
    theme_id int NOT NULL,
    category varchar(100) NOT NULL,
    description varchar(200)
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
    created_at timestamp NOT NULL default CURRENT_TIMESTAMP,
    user_id int NOT NULL, 
    category_id int NOT NULL,
    name varchar(120) NOT NULL, 
    description varchar(255), 
    test_config json,
    is_public boolean DEFAULT FALSE,
    status ENUM('in_progress','on_moderation','publicated','deleted') NOT NULL
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
    created_at timestamp NOT NULL default CURRENT_TIMESTAMP,
    code varchar(10) NOT NULL,
    name varchar(100) NOT NULL,
    description varchar(200),
    config json 
);
```

### Вопросы теста

Список вопросов, относящихся к тестам, - это определяется ссылкой на таблицу tests (поле test_id). Вопрос может иметь достаточно длинное название и описание, отображаемые на сайте. У каждого вопроса есть обязательная ссылка на тип вопроса - поле question_type_id.
У вопроса может быть иллюстрация, ссылка на неё в типе varchar записывается в поле image_link.

Ответы на вопросы записываются в поле variants типа JSON. 

Для типа игры с выбором 1 или нескольких правильных ответов структура данных будет следующей:

```
{
    "terms": [
        {
            "variant_id": 1,
            "text": "one",
            "image_link": "link_1"
        },
        {
            "variant_id": 2,
            "text": "two",
            "image_link": "link_2"
        },
        {
            "variant_id": 3,
            "text": "three",
            "image_link": "link_3"
        },
        {
            "variant_id": 4,
            "text": "four",
            "image_link": "link_4"
        }
    ]
}
```

Правильные ответы предполагается записывать в массив JSON в поле right_variants, для данного вопроса [2, 3].
Ответы пользователя также будут приходить в виде массива id вариантов, например, `[1, 2]`.
Тогда легко будет сравнить правильные варианты и неправильные.

Для типа игры на нахождение пар (сопоставление) структура данных будет следующей:

{
    "terms": [
        {
            "variant_id": 1,
            "text": "one"
        },
        {
            "variant_id": 2,
            "text": "two"
        }
    ],
    "definitions": [
        {
            "variant_id": 3,
            "text": "ONE"
        },
        {
            "variant_id": 4,
            "text": "TWO"
        }
    ]
}

Для этого варианта структура данных ответа будет в виде вложенных массивов, т.к. важно точное сопоставление термина и определения: `[ [1, 3], [2, 4] ]`

Для третьего типа игры (расставь по порядку) структура данных будет как в первом варианте, и формат правильных ответов будет также массив, но в этом случае важно будет проверять последовательность идентификаторов и их количество.

```
CREATE TABLE IF NOT EXISTS questions (
    id int PRIMARY KEY AUTO_INCREMENT,
    created_at timestamp NOT NULL default CURRENT_TIMESTAMP,
    test_id int NOT NULL,
    question_type_id int NOT NULL,
    question varchar(255) NOT NULL,
    image_link varchar(255),
    description varchar(400),
    variants json NOT NULL,
    right_variants json NOT NULL
);
```

Добавляет внешний ключ на таблицу tests:

`ALTER TABLE questions ADD FOREIGN KEY (test_id) REFERENCES tests (id);`

Добавляет внешний ключ на таблицу question_types:

`ALTER TABLE questions ADD FOREIGN KEY (question_type_id) REFERENCES question_types (id);`

### Прохождение тестов (запуск тестов)

Это денормализованная таблица для записи тестов, запускаемых пользователем, и результатов тестов, соотвественно, чтобы было удобно считать и выводить статистику по каждому игроку и по базе в целом.
В поле dttmend записывается дата и время окончания теста, чтобы считать продолжительность прохождения теста.
В test_questions_amount записывается общее количество вопросов теста, которое при запуске игры берётся из конфига (чтобы правильно считать результаты, если со временем кол-во изменяется).
В поле right_answers_amount записывается количество вопросов, на которые игрок дал правильные ответы. Значение пополняется на +1 при записи правильного ответа в таблицу game_answers.

```
CREATE TABLE IF NOT EXISTS games (
    id int PRIMARY KEY AUTO_INCREMENT,
    created_at timestamp NOT NULL default CURRENT_TIMESTAMP,
    finished_at timestamp,
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
В поле user_answer записывается json с ответами, которые дал пользователь, это удобно, если ответов предполагается много. Структура этих данных описана выше.
В поле result с типом boolean записывается, правильно ли пользователь ответил на вопрос или нет (вычисляется при добавлении ответа в таблицу триггером). 
По умолчанию стоит значение FALSE - пользователь ответил неверно.

```
CREATE TABLE IF NOT EXISTS game_answers (
    id int PRIMARY KEY AUTO_INCREMENT,
    created_at timestamp NOT NULL default CURRENT_TIMESTAMP,
    game_id int NOT NULL,
    question_id int NOT NULL,
    user_answer json, 
    result boolean NOT NULL DEFAULT FALSE 
);
```

Добавляет внешний ключ на таблицу games:

`ALTER TABLE game_answers ADD FOREIGN KEY (game_id) REFERENCES games (id);`

Добавляет внешний ключ на таблицу questions:

`ALTER TABLE game_answers ADD FOREIGN KEY (question_id) REFERENCES questions (id);`

## Примеры запросов добавления данных

### Пример добавления пользователей

```
INSERT INTO users (nick, bdate, email, password_hash, referrer_id)
VALUES
('admin', '1998-05-20', 'admin@quizgame.com', '21232f297a57a5a743894a0e4a801fc3', NULL),
('SunFlower', '1990-10-05', 'sun_flower1990@gmail.com', '608333adc72f545078ede3aad71bfe74', 1),
('Vasya', '2000-11-13', 'vasyan@bk.ru', '49f68a5c8493ec2c0bf489821c21fc3b', NULL);
```

### Пример добавления тем

```
INSERT INTO themes (theme, image_link, description)
VALUES 
('Программирование', 'images/progr.png', 'Данная тема объединяет тесты по различным языкам программирования: как клиентским, так и серверным'),
('Математика', 'images/math.png', 'Данная тема объединяет тесты по различным аспектам математики'),
('Биология', 'images/biol.png', 'Данная тема объединяет тесты по различным направлениям биологии');
```

### Пример добавления категорий

```
INSERT INTO categories (theme_id, category, description)
VALUES
(1, 'SQL', 'SQL - язык структурированных запросов. Данная категория содержит тесты как по стандарту SQL, так и по реализациям различных баз данных'),
(2, 'Алгебра 6 класс', 'Школьный курс алгебры за 6 класс'),
(3, 'Ботаника', 'Школьный курс ботаники'),
(1, 'Машинное обучение', 'Всё о машинном обучении');
```

### Пример добавления типов вопросов тестов

```
INSERT INTO question_types (type_name, description, config)
VALUES
('simple_match', 'Простое соотвествие: выбрать правильные ответы', NULL),
('pairs_match', 'Сопоставить "термины" и "определения"', '{ "module": "pairs", "terms": "left" }'),
('constructor', 'Составить ответ, используя его части', '{ "module": "constructor", "align": "center" }');
```

### Пример добавления тестов

```
INSERT INTO tests (user_id, category_id, name, description, test_config, is_public, status)
VALUES
(2, 1, 'SQL уровень 1', 'Тест для проверки базовых навыков DML', '{ "custom_questions_amount": 12, "shuffled_answers": true }', TRUE, 'published'),
(2, 1, 'DDL (data definition language)', 'Тест для проверки владения DML', '{ "custom_questions_amount": 5, "shuffled_answers": true }', TRUE, 'in_progress');
```

### Пример добавления вопросов для теста

```
INSERT INTO questions (test_id, question, description, question_type_id )
VALUES
(1, 'Команда, используемая для добавления данных в таблицу', NULL, 1),
(2, 'Команда, используемая для добавления столбца в таблицу', NULL, 1),
(2, 'Выберите правильный запрос создания таблицы', NULL, 1),
(2, 'Команда для удаления таблицы', NULL, 1),
(2, 'Как называется столбец, значение которого вычисляется из других?', NULL, 1),
(2, 'Выберите команды, НЕ являющиеся ограничением', NULL, 1);
```

### Пример добавления ответов для теста

```
INSERT INTO answers (question_id, answer, is_right )
VALUES
(1, 'SELECT', FALSE),
(1, 'UPDATE', FALSE),
(1, 'INSERT', TRUE),
(1, 'DROP', FALSE),

(2, 'CREATE COLUMN', FALSE),
(2, 'ADD COLUMN', TRUE),
(2, 'ALTER TABLE', FALSE),
(2, 'ADD CONSTRAINT', FALSE),

(3, 'CREATE TABLE products (столбец1, столбец2)', FALSE),
(3, 'CREATE TABLE products ADD COLUMNS (столбец1 тип столбца, столбец2 тип столбца)', FALSE),
(3, 'CREATE TABLE products', FALSE),
(3, 'CREATE TABLE products (столбец1 тип столбца, столбец2 тип столбца)', TRUE),

(4, 'DROP TABLE', TRUE),
(4, 'DELETE TABLE', FALSE),
(4, 'TRUNCATE TABLE', FALSE),
(4, 'CLEAR TABLE', FALSE),

(5, 'Вычисляемый', FALSE),
(5, 'Генерируемый', TRUE),
(5, 'Производный', FALSE),
(5, 'Компилируемый', FALSE),

(6, 'NOT NULL', FALSE),
(6, 'UNIQUE', FALSE),
(6, 'CHECK', FALSE),
(6, 'VALID', TRUE),
(6, 'DUPLICATE', TRUE);
```

### Пример добавления запусков тестов пользователями

```
INSERT INTO games (created_at, user_id, test_id, test_questions_amount, right_answers_amount)
VALUES
    ( DATE_SUB(now(), INTERVAL 2 DAY), 3, 2, 5, 2 ),
    ( DATE_SUB(now(), INTERVAL 1 DAY), 3, 2, 5, 5 ),
    ( now(), 3, 1, 9, 0 );
```

### Пример добавления ответов пользователей на вопросы тестов

```
INSERT INTO game_answers (game_id, question_id, answers, result)
VALUES
    ( 1, 2, '{ "answers": "6" }', TRUE ),
    ( 1, 2, '{ "answers": "11" }', FALSE ),
    ( 1, 2, '{ "answers": "13,14" }', FALSE );
```
