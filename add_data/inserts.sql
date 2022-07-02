---------------------------------------------------------
-- Скрипты добавления данных
---------------------------------------------------------

-- Группы статусов
INSERT INTO dicts.status_groups (status_group) 
VALUES 
('Пользователи'), 
('Заказы'), 
('Доставка'), 
('Поставки'),
('Товары'),
('Склад');

-- Статусы
INSERT INTO dicts.statuses (status_group_id, status_name) 
VALUES 
(1, 'Новый'), 
(1, 'Подтверждённый'), 
(1, 'Заблокирован'), 
(2, 'Новый'), 
(2, 'В обработке'),
(2, 'Оплачен'),
(2, 'Отменён пользователем'),
(2, 'Завершён'),
(3, 'Новая'),
(3, 'В пути'),
(3, 'Завершена'),
(4, 'Новая'),
(6, 'Заканчивается'),
(6, 'Закончился');

-- Пользователи
INSERT INTO dicts.users (last_name, first_name, middle_name, birth_date, email, password_hash, phone, gender, status_id)
VALUES
( 'Акимов', 'Юрий', 'Владимирович', '1980-10-05', 'yura.akimov.21@bk.ru', md5('123'), '8(917)121-92-92', 1, 5 ),
( 'Сайфуллин', 'Артур', 'Зиннурович', '1981-01-19', '190181@list.ru', md5('456'), '8(917)411-32-30', 1, 5 ),
( null, 'Наталья', 'Александровна', '1985-04-28', 'kovtunec@yandex.ru', md5('789'), '8(861)693-38-09', 2, 5 ),
( 'Федорова', 'Ирина', 'Васильевна', '1977-07-01', 'i.fedorova77@mail.ru', md5('234'), '8(917)120-72-08', 2, 5 );

-- Категории товаров
INSERT INTO warehouse.categories (category, slug) 
VALUES
('Кофе', 'coffee'),
('Подарки', 'gifts'),
('Аксессуары', 'acessories'),
('Кофемолки', 'grinders'),
('Кофе для фильтра', 'filter_coffe'),
('Кофе для эспрессо', 'espresso_coffee'),
('Капсулы', 'capsules'),
('Кофе для офиса', 'office_coffee'),
('Весы', 'scales'),
('Латте/капучино', 'latte_cap');

-- Способы оплаты
INSERT INTO warehouse.pay_methods (pay_method) 
VALUES
('Карта'),
('СМС'),
('Наличные'),
('Перевод');

-- Способы доставки
INSERT INTO orders.ship_methods (ship_method) 
VALUES
('Курьер'),
('Почта'),
('Служба доставки'),
('Самовывоз');

-- Поставщики
INSERT INTO warehouse.suppliers (supplier, company_phone, site_link) 
VALUES
('Нестле', '8(800)200-7-200', 'https://www.nestle.ru/'),
('КрафтФудс', '8(812)309-96-99', 'https://www.kraftfoods.ru/'),
('Монтана Кофе', '8(499)272-19-25', 'https://montana.ru/'),
('Паулиг Кофе', '8(800)550-20-87', 'https://www.paulig.ru/');

-- Характеристики товаров
INSERT INTO warehouse.parameters (parameter) 
VALUES
('Страна производства'),
('Насыщенность'),
('Способ приготовления'),
('Кислотность'),
('Плотность'),
('Метод обработки');

-- Товары
INSERT INTO warehouse.products (vendor_code, product, manufacturer_id, supplier_id, description_text)
VALUES
('1290018', 'Berry Blend', 1, 1, 'В аромате жасмин, карамель и черная смородина Во вкусе черника, сухофрукты и малина'),
('1171495', 'Никарагуа Марагоджип', 1, 2, 'В аромате выпечка, желтые фрукты и карамель Во вкусе красное яблоко, цедра лимона и карамель'),
('1344437', 'Капсулы Гватемала Сейба 10 шт', 2, 2, 'В аромате - миндаль, белый изюм, вишневое варенье. Во вкусе - красное яблоко, молочный шоколад.'),
('1301825', 'Кофемолка ручная Timemore Chestnut C2, чёрная', 3, 3, 'Профессиональная ручная кофемолка с коническими стальными жерновами.'),
('1278672', 'Кофейная пара Loveramics (Лаврамикс) Egg, 200ml, ягодная', 3, 4, 'Кофейная пара Egg объемом 200 мл от Гонконгской компании Loveramics.'),
('1170883', 'Весы Brewista V2.0 BSSRB2 (6 режимов) с подсветкой Черные', 2, 3, 'Компактные, настольные весы точностью 0,1 гр. помогут приготовить идеальный эспрессо за счет 4 автоматических и 2 ручных режимов работы.');

-- Связи "Товар-категория"
INSERT INTO warehouse.product_category (product_id, category_id) 
VALUES
(1, 1),
(2, 1),
(3, 1),
(3, 8),
(4, 4),
(5, 11),
(6, 10),
(5, 3),
(6, 3);

-- Связи "Товар-характеристика"
INSERT INTO warehouse.product_params 
(product_id, parameter_id, value_int, value_text, value_numeric, value_int_arr, value_text_arr, value_jsonb) 
VALUES
(1, 1, null, 'Эфиопия', null, null, null, null),
(1, 2, 4, null, null,null, null, null),
(1, 4, 3, null, null,null, null, null),
(2, 1, null, 'Хинотега', null, null, null, null),
(2, 2, 2, null, null,null, null, null),
(2, 4, 3, null, null,null, null, null),
(3, 1, null, 'Уэуэтенанго', null, null, null, null),
(3, 4, 4, null, null,null, null, null),
(3, 5, 5, null, null,null, null, null),
(3, 6, null, 'Мытая', null,null, null, null);
