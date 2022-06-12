# Проект Coffee Shop

Цель проекта - формирование базы данных для владельца и менеджеров интернет-магазина кофе и аксессуаров. В базе данных будет храниться и обрабатываться информация о клиентах магазина, их заказах, о поставщиках и ассортименте магазина.

## Бизнес-задачи, которые решает БД

1. Ведение клиентской базы, базы поставщиков и производителей.
1. Регистрация и отслеживание процесса выполнения заказов товаров.
1. Построение отчетов о продажах.

## Оглавление

1. [Описание сущностей БД](/entities.md)
1. [Возможные запросы](/queries.md)

## Описание предметной области

1. Интернет-магазин предлагает покупателям кофе и аксессуары. Товары разносятся по нескольким категориям, причём категории могут быть вложенными друг в друга, но у каждого товара может быть только одна категория (система вложенных категорий).
1. На страницах сайта предполагается выводить списки новых и наиболее часто покупаемых товаров (разные варианты выборки товаров).
1. Товары могут быть представлены в разной фасовке, например, кофе "Arabica" может продаваться пачками по 250 гр и 500 гр. Карточка товара в таких случаях предусматривает выбор нужной фасовки. Цена при этом изменяется (разные прайсы на виды фасовки товаров).
1. Продажа и доставка производится только по России, поэтому оплата происходит в рублях. Оплатить покупки можно картой или наличными (разные способы оплаты).
1. Пользователи регистрируются на сайте и указывают в специальной форме адрес доставки. Доставка осуществляется только на этот адрес курьером или по почте (для упрощения). Способы доставки могут быть разными.
1. В заказе может быть от 1 до нескольких товаров.
1. Для отслеживания состояний пользователей, заказов, товаров и т.д. предусмотрена система статусов. Смена статусов заказов фиксируется, чтобы строить отчёты.
1. Поставки товаров регистрируются в отдельной таблице. Есть система работы с прайсами.

## Структура сущностей в БД

### Общие справочники

1. Группы статусов
1. Статусы
1. Пользователи (физлица)

### Товары (склад)

1. Производители
1. Поставщики
1. Категории товаров
1. Единицы измерения
1. Товары
1. Характеристики товаров
1. Связь товаров с характеристиками

### Цены

1. Способ оплаты
1. Цены (прайсы)
1. Прайслисты
1. Сзязь прайслистов с товарами

### Поставки товаров

1. Поставки
1. Товары в поставке

### Заказы и Доставка

1. Способы доставки
1. Заказы
1. Товары в заказе
1. Доставки

### Процессы

1. История заказов

## Ссылка на схему базы данных

https://dbdiagram.io/d/62a36b9892b33b4f513fcf9a

Также можно посмотреть [скриншот](/images/scheme_11-06-2022.png) схемы БД.
