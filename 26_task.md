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