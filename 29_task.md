# Добавляем в базу хранимые процедуры и триггеры

Для создания процедур использована БД Northwind и таблица products.

1. **Создать пользователей client, manager**

    `CREATE USER 'client'@'%' IDENTIFIED BY '12345';`

    `CREATE USER 'manager'@'%' IDENTIFIED BY '67890';`

1. **Создать процедуру выборки товаров с использованием различных фильтров**: категория, цена, производитель, различные дополнительные параметры

```
DELIMITER $$
CREATE PROCEDURE pr_get_filtered_products(
	IN _discontinued INT,
    IN _product_code VARCHAR(15),
    IN _category VARCHAR(20),
    IN _product_name VARCHAR(50),
    IN _description VARCHAR(100),
    IN _standard_cost DECIMAL,
    IN _quantity_per_unit VARCHAR(20)
)
BEGIN

set _standard_cost = COALESCE(_standard_cost, 0);

select 
    p.id, 
    p.product_code, 
    p.product_name, 
    p.category, 
    p.description, 
    p.standard_cost, 
    p.list_price, 
    p.quantity_per_unit
from products as p
where 
	p.discontinued = _discontinued
    and ( _product_code is null or p.product_code = _product_code )
    and ( _category is null or p.category = _category )
    and ( p.standard_cost >= _standard_cost )
    and ( _product_name is null or p.product_name like concat('%', _product_name, '%') )
    and ( _description is null or p.description like concat('%', _description, '%') )
    and ( _quantity_per_unit is null or p.quantity_per_unit like concat('%', _quantity_per_unit, '%') )
;

END$$
DELIMITER ;
```

1. Также в качестве параметров **передавать по какому полю сортировать выборку**, и параметры постраничной выдачи



1. **Дать права на запуск процедуры пользователю client**

    `GRANT EXECUTE ON pr_get_filtered_products TO 'client'@'%';`

1. **Создать процедуру get_orders**, которая позволяет просматривать отчет по продажам за определенный период (час, день, неделя) с различными уровнями группировки (по товару, по категории, по производителю)



1. **Дать права пользователю manager**

    `GRANT EXECUTE ON pr_filtered_products TO 'manager'@'%';`
