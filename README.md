# Проект Coffee Shop

Цель проекта - формирование базы данных для владельца и менеджеров интернет-магазина кофе и аксессуаров. В базе данных будет храниться и обрабатываться информация о клиентах магазина, их заказах, о поставщиках и ассортименте магазина.

## Бизнес-задачи, которые решает БД

1. Ведение клиентской базы, базы поставщиков и производителей.
1. Регистрация и отслеживание процесса выполнения заказов товаров.
1. Построение отчетов о продажах.

## Оглавление

1. [Описание сущностей БД](entities.md)
1. [Определение сущностей: ограничения, индексы](create_entities.sql)
1. [Возможные запросы](queries.md)
1. [Создание сущностей](DDL/)
1. [Скрипты проекта](scripts.sql)
1. [Запросы на вставку данных](add_data/)
1. [DML: вставка, обновление, удаление, выборка данных](9_dml_task.sql)
1. [Индексы PostgreSQL](10_task.sql)
1. [DML: агрегация и сортировка, CTE, аналитические функции](12_task.sql)
1. [Репликация PostgreSQL](18_task.md)
1. [Внутренняя архитектура СУБД MySQL](21_task.md)
1. [Типы данных в MySQL](22_task_new.md)
1. [DML: вставка, обновление, удаление, выборка данных в MySQL](24_task.md)
1. [Транзакции, MVCC, ACID в MySQL](25_task.md)
1. [DML: агрегация и сортировка в MySQL](26_task.sql)
1. [Индексы в MySQL](27_task.md)
1. [Хранимые процедуры и триггеры в MySQL](29_task.md)
1. [Репликация](31_task.md)
1. [Анализ и профилирование запросов](32_task.md)
1. [Строим модель данных](34_task.md)

## Описание предметной области

1. Интернет-магазин предлагает покупателям кофе и аксессуары. Товары разносятся по нескольким категориям, один товар может относиться к нескольким категориям.
1. На страницах сайта предполагается выводить списки новых и наиболее часто покупаемых товаров (разные варианты выборки товаров).
1. Товары могут быть представлены в разной фасовке, например, кофе "Arabica" может продаваться пачками по 250 гр и 500 гр. Карточка товара в таких случаях предусматривает выбор нужной фасовки. Цена при этом изменяется (разные прайсы на виды фасовки товаров).
1. Продажа и доставка производится только по России, поэтому оплата происходит в рублях. Оплатить покупки можно картой или наличными (разные способы оплаты).
1. Пользователи регистрируются на сайте и указывают в специальной форме адрес доставки (система поддерживает несколько адресов). Доставка осуществляется курьером или по почте (разные способы доставки).
1. В заказе может быть от 1 до нескольких товаров.
1. Для отслеживания состояний пользователей, заказов, товаров и т.д. предусмотрена система статусов. Смена статусов заказов фиксируется, чтобы строить отчёты.
1. Поставки товаров регистрируются в отдельной таблице.
1. На сайте магазина предусмотрен поиск по названию товара.

## Структура сущностей в БД

### Общие справочники

1. Группы статусов
1. Статусы
1. Типы сущностей
1. Пользователи
1. Адреса 

### Товары (склад)

1. Производители
1. Поставщики
1. Единицы измерения
1. Категории товаров
1. Товары
1. Связь товаров с категориями
1. Характеристики товаров
1. Связь товаров с характеристиками
1. Склад

### Заказы и доставка

1. Способ оплаты
1. Способы доставки
1. Заказы
1. Товары в заказе
1. Продажи (пока нет)
1. Доставка

### Процессы

1. История смены статусов

## Ссылка на схемы базы данных

https://dbdiagram.io/d/62c0585e69be0b672c884978 - поставки и склад
https://dbdiagram.io/d/62c05a2f69be0b672c885305 - заказы и доставка
https://dbdiagram.io/d/62a36b9892b33b4f513fcf9a - общее

Также можно посмотреть [скриншот](https://prnt.sc/I_-8K97PwVWW) схемы БД.
