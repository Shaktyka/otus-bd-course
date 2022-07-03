-- Способы оплаты
INSERT INTO orders.pay_methods (pay_method) 
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
