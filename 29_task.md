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
        IN _product_name VARCHAR(100),
        IN _description VARCHAR(100),
        IN _list_price DECIMAL(19,4),
        IN _quantity_per_unit VARCHAR(20)
    )
    BEGIN

    SELECT 
        p.id, 
        p.product_code, 
        p.product_name, 
        p.category, 
        p.description, 
        p.standard_cost, 
        p.list_price, 
        p.quantity_per_unit,
        p.discontinued
    FROM products AS p
    WHERE 
        ( _product_code IS NULL OR p.product_code = _product_code )
        AND ( _product_name IS NULL OR p.product_name LIKE CONCAT('%', _product_name, '%') )
        AND ( _description IS NULL OR p.description LIKE CONCAT('%', _description, '%') )
        AND ( _category IS NULL OR p.category = _category )
        AND ( p.list_price >= COALESCE(_list_price, 0) )
        AND ( _quantity_per_unit IS NULL OR p.quantity_per_unit LIKE CONCAT('%', _quantity_per_unit, '%') )
        AND ( p.discontinued = COALESCE(_discontinued, 0) )
    ORDER BY p.product_name;

    END$$
    DELIMITER ;
    ```

**Пример 1**

Выберем все товары в наличии:

`call pr_get_filtered_products(0, null, null, null, null, null, null);`

![Пример 1](/images/pr_all.jpg)

**Пример 2** 

Выберем товары с фильтрами:

`call pr_get_filtered_products(0, null, null, null, null, 2, 'bags');`

![Пример 2](/images/pr_filter.jpg)


1. Также в качестве параметров **передавать по какому полю сортировать выборку**, и параметры **постраничной выдачи**

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

    Даём права на запуск процедуры пользователю client
    `GRANT EXECUTE ON pr_get_filtered_products TO 'client'@'%';`


1. **Создать процедуру get_orders**, которая позволяет просматривать отчет по продажам за определенный период (час, день, неделя) с различными уровнями группировки (по товару, по категории, по производителю)

    Даём права пользователю manager:
    `GRANT EXECUTE ON pr_sales_report TO 'manager'@'%';`

    Определение процедуры:

    ```

    ```
    