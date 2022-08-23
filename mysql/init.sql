CREATE DATABASE quizgame CHARACTER SET utf8 COLLATE utf8_general_ci;
USE quizgame;

/*
Скрипт создания пользователя - админа БД quizgame с выдачей прав:

CREATE USER 'admin'@'%' IDENTIFIED BY '1234' COMMENT 'Админ для базы quizgame';

GRANT ALL PRIVILEGES ON quizgame.* TO 'admin'@'%';

FLUSH PRIVILEGES;
*/

-- СХЕМА БД quizgame для сайта с тестами

-- Состояния (тестов, пользователей и др.)
CREATE TABLE `states` (
  `id` int UNIQUE PRIMARY KEY NOT NULL AUTO_INCREMENT,
  `dttmcr` timestamp NOT NULL default now(),
  `code` char(3) NOT NULL, -- код принадлежности состояния к типу (состояние теста, пользователя и т.п.)
  `state` varchar(100) NOT NULL,
  `description` varchar(255)
);

-- Пользователи
-- Регистрируются, создают и проходят тесты
CREATE TABLE users (
  `id` int UNIQUE PRIMARY KEY NOT NULL AUTO_INCREMENT,
  `dttmcr` timestamp NOT NULL default now(),
  `bdate` date,
  `email` varchar(100) UNIQUE NOT NULL,
  `password` varchar(100) NOT NULL,
  `state_id` int NOT NULL
);

ALTER TABLE `users` ADD FOREIGN KEY (`state_id`) REFERENCES `states` (`id`);

-- Категории тестов, один тест относится только к 1 категории
CREATE TABLE `categories` (
  `id` int UNIQUE PRIMARY KEY NOT NULL AUTO_INCREMENT,
  `dttmcr` timestamp NOT NULL default now(),
  `category` varchar(100) UNIQUE NOT NULL,
  `description` varchar(255)
);

-- Тест (набор вопросов)
CREATE TABLE `tests` (
  `id` int UNIQUE PRIMARY KEY NOT NULL AUTO_INCREMENT,
  `dttmcr` timestamp NOT NULL default now(),
  `user_id` int NOT NULL, -- кто создал
  `category_id` int NOT NULL,
  `name` varchar(255) NOT NULL, -- название
  `description` varchar(400), -- описание
  `is_public` boolean DEFAULT 0, -- публичный или приватный
  `state_id` int NOT NULL
);

ALTER TABLE `tests` ADD FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);
ALTER TABLE `tests` ADD FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`);
ALTER TABLE `tests` ADD FOREIGN KEY (`state_id`) REFERENCES `states` (`id`);

-- Тип вопроса: способы выбора ответов, могут быть разными
CREATE TABLE `question_types` (
  `id` int UNIQUE PRIMARY KEY NOT NULL AUTO_INCREMENT,
  `dttmcr` timestamp NOT NULL default now(),
  `type_name` varchar(100) NOT NULL,
  `config` json -- собираем сюда разные настройки для проигрывания теста
);

-- Вопросы теста
CREATE TABLE `questions` (
  `id` int UNIQUE PRIMARY KEY NOT NULL AUTO_INCREMENT,
  `dttmcr` timestamp NOT NULL default now(),
  `test_id` int NOT NULL,
  `question` varchar(255) NOT NULL,
  `description` varchar(400),
  `question_type_id` int NOT NULL
);

ALTER TABLE `questions` ADD FOREIGN KEY (`test_id`) REFERENCES `tests` (`id`);
ALTER TABLE `questions` ADD FOREIGN KEY (`question_type_id`) REFERENCES `question_types` (`id`);

-- Ответы на вопросы
CREATE TABLE `answers` (
  `id` int UNIQUE PRIMARY KEY NOT NULL AUTO_INCREMENT,
  `dttmcr` timestamp NOT NULL default now(),
  `question_id` int NOT NULL,
  `answer` varchar(255) NOT NULL, -- ответ на вопрос (один из)
  `is_right` boolean DEFAULT 0 -- верный ответ или нет
);

ALTER TABLE `answers` ADD FOREIGN KEY (`question_id`) REFERENCES `questions` (`id`);

-- Тесты, которые проходят пользователи
CREATE TABLE `games` (
  `id` int UNIQUE PRIMARY KEY NOT NULL AUTO_INCREMENT,
  `dttmcr` timestamp NOT NULL default now(),
  `user_id` int NOT NULL,
  `test_id` int NOT NULL,
  `question_id` int NOT NULL,
  `answers` json, -- список id ответов на вопрос, но мог ничего не выбрать и закрыть страницу
  `result` boolean DEFAULT 0 -- правильно ответил или нет
);

ALTER TABLE `games` ADD FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

ALTER TABLE `games` ADD FOREIGN KEY (`test_id`) REFERENCES `tests` (`id`);

ALTER TABLE `games` ADD FOREIGN KEY (`question_id`) REFERENCES `questions` (`id`);
