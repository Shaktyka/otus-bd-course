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
    CREATE PROCEDURE pr_get_filtered_sorted_products(
        IN _discontinued INT,
        IN _product_code VARCHAR(15),
        IN _category VARCHAR(30),
        IN _product_name VARCHAR(100),
        IN _description VARCHAR(100),
        IN _list_price DECIMAL(19,4),
        IN _quantity_per_unit VARCHAR(20),
        IN _sort_field varchar(30),
        IN _sort_dir varchar(4),
        IN _limit SMALLINT UNSIGNED,
        IN _offset SMALLINT UNSIGNED
    )
    BEGIN
    
    -- Определяет список полей выборки:
    SET @fields = 'id, product_code, product_name, category, `description`, standard_cost, list_price, quantity_per_unit, discontinued';
    
    -- Задаёт стартовое значение списку фильтров WHERE:
    SET @where = concat( 'discontinued = ', COALESCE(_discontinued, 0) );
    
    -- Передан ли код товара:
    IF _product_code IS NOT NULL THEN
        SET @p_code = concat( ' product_code = "', _product_code, '"' );
        SET @where = concat( @where, ' AND ', @p_code );
    END IF;
    
    -- Передана ли категория товара:
    IF _category IS NOT NULL THEN
        SET @category = concat( ' category = "', _category, '"' );
        SET @where = concat( @where, ' AND ', @category );
    END IF;
    
    -- Передано ли название товара:
    IF _product_name IS NOT NULL THEN
        SET @p_name = concat( ' product_name LIKE "', CONCAT('%', _product_name, '%'), '"' );
        SET @where = concat( @where, ' AND ', @p_name );
    END IF;
    
    -- Передано ли описание товара:
    IF _description IS NOT NULL THEN
        SET @p_descr = concat( ' description LIKE "', CONCAT('%', _description, '%'), '"' );
        SET @where = concat( @where, ' AND ', @p_descr );
    END IF;
    
    -- Передана ли цена:
    IF _list_price IS NOT NULL THEN
        SET @p_lprice = concat( 'list_price >= ', COALESCE(_list_price, 0) );
        SET @where = concat( @where, ' AND ', @p_lprice );
    END IF;
    
    -- Передано ли описание упаковки:
    IF _quantity_per_unit IS NOT NULL THEN
        SET @p_quantity = concat( 'quantity_per_unit LIKE "', CONCAT('%', _quantity_per_unit, '%'), '"' );
        SET @where = concat( @where, ' AND ', @p_quantity );
    END IF;
    
    -- Собирает запрос:
    SET @query = CONCAT (
        'SELECT ', @fields, ' ',
        'FROM products WHERE', ' ', @where, ' ',
        'ORDER BY (', _sort_field, ') ', COALESCE(_sort_dir, 'ASC'), ' ',
        'LIMIT ', COALESCE(_limit, 5), ' ',
        'OFFSET ', COALESCE(_offset, 0)
    );
    
    -- Готовит и выполняет запрос
    PREPARE stmt FROM @query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    END$$
    DELIMITER ;
    ```

    Даём права на запуск последней процедуры пользователю client

    `GRANT EXECUTE ON pr_get_filtered_sorted_products TO 'client'@'%';`

    Пример вызова процедуры:

    `call pr_1(0, NULL, 'Beverages', 'Tea', NULL, 0, 20, 'category', 'asc', 10, NULL);`

    Результат выполнения:

    ![Результат выполнения процедуры с сортировкой](/images/order_proc.jpg)


1. **Создать процедуру get_orders**, которая позволяет просматривать отчет по продажам за определенный период (час, день, неделя) с различными уровнями группировки (по товару, по категории, по производителю)

    `DROP PROCEDURE IF EXISTS get_orders;`

    Определение процедуры:

    ```
    DELIMITER $$
    CREATE PROCEDURE adventureworks.get_orders (
	    IN _per_beg timestamp, 
        IN _per_end timestamp, 
        IN _group_cols text
    )
    BEGIN
    -- Объявляет переменные:
    DECLARE per_beg text;
    DECLARE per_end text;
    DECLARE select_cols text;
    DECLARE group_by_cols text;
    DECLARE query_str text;

    -- Определяет фильтр по началу периода:
    IF _per_beg IS NOT NULL THEN
	    SET @period_beg = concat('s.OrderDate >= ', _per_beg);
    END IF;

    -- Определяет фильтр по концу периода:
    IF _per_end IS NOT NULL THEN
	    SET @per_end = concat('s.OrderDate <= ', _per_end);
    END IF;

    -- Определяет столбцы для выборки и группировки:
    IF _group_cols IS NOT NULL THEN
        SET @group_by_cols = concat('GROUP BY ', _group_cols);
        SET @select_cols = concat(_group_cols, ', ', 'ROUND(SUM(od.LineTotal), 2) AS SumPrice');
    ELSE
        SET @select_cols = ' * ';
    END IF;

    -- Собирает запрос:
    SET @query_str = CONCAT_WS ( 
        ' ', 
	    'SELECT', @select_cols,
	    'FROM salesorderheader AS s
        INNER JOIN salesorderdetail AS od ON s.SalesOrderID = od.SalesOrderID
	    INNER JOIN product AS p ON od.ProductID = p.ProductID
	    LEFT JOIN productsubcategory AS ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
	    LEFT JOIN productcategory AS pc ON ps.ProductCategoryID = pc.ProductCategoryID',
        @group_by_cols
    );

    -- Готовит и выполняет запрос
    PREPARE stmt FROM @query_str;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    END$$
    DELIMITER ;
    ```

    Даём права пользователю manager:

    `GRANT EXECUTE ON get_orders TO 'manager'@'%';`
    
    Вызовем процедуру, чтобы получить суммы продаж по категориям за 2002 год:
    
    `call get_orders('2002-01-01', '2002-12-31', 'ps.ProductCategoryID');`

    Результат:

    ![Результат вызова процедуры 3](/images/proc_res_1.jpg)

