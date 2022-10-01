# Добавляем в базу хранимые процедуры и триггеры

Для создания процедур использована БД Northwind и таблица products.

1. **Создать пользователей client, manager**

    `CREATE USER 'client'@'localhost' IDENTIFIED BY '12345';`

    `CREATE USER 'manager'@'localhost' IDENTIFIED BY '67890';`

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

    ```
    DELIMITER $$
    CREATE PROCEDURE pr_get_filtered_products_sort(
        IN _discontinued TINYINT(1),
        IN _product_code VARCHAR(15),
        IN _category VARCHAR(20),
        IN _product_name VARCHAR(50),
        IN _description VARCHAR(100),
        IN _standard_cost DECIMAL,
        IN _quantity_per_unit VARCHAR(20),
        IN _sort_field varchar(20),
        IN _limit SMALLINT UNSIGNED,
        IN _offset SMALLINT UNSIGNED
    )
    BEGIN

    SET _standard_cost = COALESCE(_standard_cost, 0);
    SET _sort_field    = COALESCE(_sort_field, 'p.id DESC'); -- по умолчанию сортируем по id продукта в обратном порядке
    SET _limit         = COALESCE(_standard_cost, 10); -- по умолчанию 10 строк
    SET _offset        = COALESCE(_offset, 0);

    SELECT 
        p.id, 
        p.product_code, 
        p.product_name, 
        p.category, 
        p.description, 
        p.standard_cost, 
        p.list_price, 
        p.quantity_per_unit
    FROM products AS p
    WHERE 
        p.discontinued = _discontinued
        AND ( _product_code IS NULL OR p.product_code = _product_code )
        AND ( _category IS NULL OR p.category = _category )
        AND ( p.standard_cost >= _standard_cost )
        AND ( _product_name IS NULL OR p.product_name LIKE concat('%', _product_name, '%') )
        AND ( _description IS NULL OR p.description LIKE concat('%', _description, '%') )
        AND ( _quantity_per_unit IS NULL OR p.quantity_per_unit LIKE concat('%', _quantity_per_unit, '%') )
    ORDER BY _sort_field
    LIMIT _limit
    OFFSET _offset;

    END$$
    DELIMITER ;
    ```

1. **Дать права на запуск процедуры пользователю client**

    `GRANT EXECUTE ON pr_get_filtered_products TO 'client'@'localhost';`

1. **Создать процедуру get_orders**, которая позволяет просматривать отчет по продажам за определенный период (час, день, неделя) с различными уровнями группировки (по товару, по категории, по производителю)



1. **Дать права пользователю manager**

    `GRANT EXECUTE ON pr_sales_report TO 'manager'@'localhost';`
