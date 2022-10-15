# Создаём отчетные выборки

Группировки с ипользованием CASE, HAVING, ROLLUP, GROUPING():
для магазина к предыдущему списку продуктов добавить максимальную и минимальную цену и кол-во предложений
также сделать выборку показывающую самый дорогой и самый дешевый товар в каждой категории
сделать rollup с количеством товаров по категориям

Использована база данных AdwentureWorks.

### Для магазина к предыдущему списку продуктов добавить максимальную и минимальную цену и кол-во предложений

-- Максимальная и минимальная цены товаров в каждой категории:
'2','Components','1431.5','20.24'
'4','Accessories','159','2.29'
'3','Clothing','89.99','8.99'
'1','Bikes','3578.27','539.99'




### Сделать выборку, показывающую самый дорогой и самый дешевый товар в каждой категории

```
WITH cte AS (
	SELECT DISTINCT
        PC.ProductCategoryID AS category_id,
        PC.Name AS category,
        max(P.ListPrice) OVER w AS max_price,
        min(P.ListPrice) OVER w AS min_price
    FROM productcategory AS PC
    INNER JOIN productsubcategory AS PSC ON PC.ProductCategoryID = PSC.ProductCategoryID
    INNER JOIN product AS P ON PSC.ProductSubcategoryID = P.ProductSubcategoryID
    WINDOW w AS (PARTITION BY PC.ProductCategoryID)
) 
SELECT
	cte.category_id,
    cte.category,
    cte.max_price,
    (SELECT GROUP_CONCAT(P1.name SEPARATOR ', ') FROM product AS P1 WHERE P1.ListPrice = cte.max_price) AS max_price_products,
    cte.min_price,
    (SELECT GROUP_CONCAT(P2.name SEPARATOR ', ') FROM product AS P2 WHERE P2.ListPrice = cte.min_price) AS min_price_products
FROM cte
ORDER BY cte.category;
```

Результат выборки:

![Самый дорогой и самый дешёвый товар](/images/by_boundaries_result.jpg)

### Сделать rollup с количеством товаров по категориям

**ROLLUP с количеством товаров по категориям**

```
SELECT 
	PC.ProductCategoryID AS categoryID,
    PC.Name AS category,
    count(*) AS amount
FROM productcategory AS PC
INNER JOIN productsubcategory AS PSC ON PC.ProductCategoryID = PSC.ProductCategoryID
INNER JOIN product AS P ON PSC.ProductSubcategoryID = P.ProductSubcategoryID
GROUP BY PC.ProductCategoryID, PC.Name
WITH ROLLUP;
```

Результат выборки:

![Кол-во товаров по категориям](/images/cat_result_1.jpg)

**ROLLUP с количеством товаров ещё и по подкатегориям**

```
SELECT 
	PC.ProductCategoryID AS categoryID,
    PC.Name AS category,
    PSC.Name AS subcategory,
    count(*) AS amount
FROM productcategory AS PC
INNER JOIN productsubcategory AS PSC ON PC.ProductCategoryID = PSC.ProductCategoryID
INNER JOIN product AS P ON PSC.ProductSubcategoryID = P.ProductSubcategoryID
GROUP BY PC.ProductCategoryID, PC.Name, PSC.Name
WITH ROLLUP;
```

Результат выборки:

![Кол-во товаров по категориям и подкатегориям](/images/cat_result_2.jpg)
