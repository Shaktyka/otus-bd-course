# Создаём отчетные выборки

Группировки с ипользованием CASE, HAVING, ROLLUP, GROUPING():
для магазина к предыдущему списку продуктов добавить максимальную и минимальную цену и кол-во предложений
также сделать выборку показывающую самый дорогой и самый дешевый товар в каждой категории
сделать rollup с количеством товаров по категориям

---

Использована база данных AdwentureWorks.

### Для магазина к предыдущему списку продуктов добавить максимальную и минимальную цену и кол-во предложений

Формулировка задания не очень понятная, сделала на примере поставщиков и их поставок.

Для поставщиков посчитать максимальную и минимальную сумму заказов и количество заказов за всё время.
Вывести столбцы: название и идентификатор поставщика, минимальная сумма заказа, максимальная сумма заказа, общее количество заказов. Отсортировать по названию поставщика.

```
SELECT
    v.VendorID AS vendor_id,
    v.Name AS vendor_name,
    max(ph.TotalDue) AS max_order_sum,
    min(ph.TotalDue) AS min_order_sum,
    count(ph.PurchaseOrderID) as orders_amount
FROM vendor AS v
INNER JOIN purchaseorderheader AS ph ON v.VendorID = ph.VendorID
INNER JOIN purchaseorderdetail AS pd ON ph.PurchaseOrderID = pd.PurchaseOrderID
GROUP BY v.VendorID, v.Name
ORDER BY v.Name;
```

Результат выборки: 

![Статистика по поставщикам](/images/vendors.jpg)

Если по спискам продуктов в AdwentureWorks, то сделала группировку по категориям товаров: id, название категории, максимальная и минимальная цена, кол-во позиций.

```
SELECT
	PC.ProductCategoryID AS category_id,
	PC.Name AS category,
	max(P.ListPrice) AS max_price,
	min(P.ListPrice) AS min_price,
	count(P.ProductID) as amount
FROM productcategory AS PC
INNER JOIN productsubcategory AS PSC ON PC.ProductCategoryID = PSC.ProductCategoryID
INNER JOIN product AS P ON PSC.ProductSubcategoryID = P.ProductSubcategoryID
WHERE 
	ListPrice > 0
	AND DiscontinuedDate IS NULL
GROUP BY PC.ProductCategoryID, PC.Name
ORDER BY amount DESC;
```

Результат выборки:

![Статистика по категориям](/images/statistics.jpg)

### Сделать выборку, показывающую самый дорогой и самый дешевый товар в каждой категории

В AdwentureWorks есть много товаров с одной ценой, пришлось сконкатенировать в одну строку.

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
