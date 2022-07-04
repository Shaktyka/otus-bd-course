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

-- Поставщики
INSERT INTO warehouse.suppliers (supplier, company_phone, site_link) 
VALUES
('Нестле', '8(800)200-7-200', 'https://www.nestle.ru/'),
('КрафтФудс', '8(812)309-96-99', 'https://www.kraftfoods.ru/'),
('Монтана Кофе', '8(499)272-19-25', 'https://montana.ru/'),
('Паулиг Кофе', '8(800)550-20-87', 'https://www.paulig.ru/');

-- Единицы измерения
INSERT INTO warehouse.units (unit) 
VALUES
('Упаковка'),
('Штука'),
('Пакет'),
('Набор');

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
INSERT INTO warehouse.products (upc, product, photo, descr_text, unit_id, amount, mass )
VALUES
('1290018', 'Berry Blend', 'https://i1.proimagescdn.ru/images/bimages/1171/06022020-DIZIGN-4-011-D_1.webp', 
 'В аромате жасмин, карамель и черная смородина Во вкусе черника, сухофрукты и малина',
1, 1, 250),
('1171495', 'Никарагуа Марагоджип', 'https://i1.proimagescdn.ru/images/bimages/1290/06022020-DIZIGN-3-050-D_1.webp', 
 'В аромате выпечка, желтые фрукты и карамель Во вкусе красное яблоко, цедра лимона и карамель', 1, 1, 500),
('1344437', 'Капсулы Гватемала Сейба 10 шт', 'https://i1.proimagescdn.ru/images/bimages/1344/11052022-9706-022-A_1.webp', 
 'В аромате - миндаль, белый изюм, вишневое варенье. Во вкусе - красное яблоко, молочный шоколад.', 1, 1, null),
('1301825', 'Кофемолка ручная Timemore Chestnut C2, чёрная', 'https://i1.proimagescdn.ru/images/bimages/1301/20052021-9501-003ab_1.webp',
 'Профессиональная ручная кофемолка с коническими стальными жерновами.', 2, 1, null),
('1278672', 'Кофейная пара Loveramics (Лаврамикс) Egg, 200ml, ягодная', 'https://i1.proimagescdn.ru/images/bimages/1220/31082018-7672-020_1.webp', 
 'Кофейная пара Egg объемом 200 мл от Гонконгской компании Loveramics.', 4, 1, null),
('1170883', 'Весы Brewista V2.0 BSSRB2 (6 режимов) с подсветкой Черные', 'https://i1.proimagescdn.ru/images/bimages/1340/03022022-9662-003-A_1.webp', 
 'Компактные, настольные весы точностью 0,1 гр. помогут приготовить идеальный эспрессо за счет 4 автоматических и 2 ручных режимов работы.', 2, 1, null),
('1290018', 'Berry Blend', 'https://i1.proimagescdn.ru/images/bimages/1171/06022020-DIZIGN-4-011-D_1.webp', 
 'В аромате жасмин, карамель и черная смородина Во вкусе черника, сухофрукты и малина', 1, 1, 1000);

-- ПЕРЕДЕЛАТЬ
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

-- ПЕРЕДЕЛАТЬ
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

-- Прайслисты "шапка"
INSERT INTO warehouse.pricelists (date_beg, date_end, supplier_id)
VALUES 
('2022-07-01', '2022-07-31', 1),
('2022-06-01', '2022-08-31', 2),
('2022-07-03', '2022-09-03', 3),
('2022-03-01', '2022-07-31', 4);

-- Прайслисты товары
-- Прайслисты_товары
INSERT INTO warehouse.pricelist_items (pricelist_id, upc, manufacturer_id, price_per_unit)
VALUES 
( 1, '1290018250', 2, 250 ),
( 1, '12900181000', 2, 1000 ),
( 2, '1278672', 1, 1200 ),
( 2, '1170883', 1, 800 );

-- Поставки "шапка"
INSERT INTO warehouse.deliveries (operation, supplier_id, invoice_id, pricelist_id)
VALUES 
(1, 1, 1, 1), (1, 2, 2, 2), (1, 3, 3, 3), (1, 4, 4, 4);

-- Поставки_товары
INSERT INTO warehouse.delivery_items (delivery_id, upc, amount)
VALUES 
( 1, '1290018250', 10 ),
( 1, '12900181000', 15 ),
( 2, '1278672', 5 ),
( 2, '1170883', 13 );

-- Склад
INSERT INTO warehouse.warehouse (product_id, articul, pricelist_id, amount, status_id)
VALUES
( 22, '1290018250', 1, 0, 19 ),
( 28, '12900181000', 1, 1, 18 ),
( 27, '1170883', 2, 5, 17 ),
( 26, '1278672', 2, 5, 17 );

-- Добавление товаров на склад как копия:
INSERT INTO warehouse (product_id, articul, pricelist_id, amount, status_id)
    SELECT product_id, articul, pricelist_id, 0, status_id FROM warehouse
    WHERE id IN (5, 6);
