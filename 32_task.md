# Анализ и профилирование запроса

Возьмите сложную выборку из предыдущих ДЗ с несколькими join и подзапросами
Востройте EXPLAIN в 3 формата
Оцените план прохождения запроса, найдите самые тяжелые места
Попробуйте оптимизировать запрос (можно использовать индексы, хинты, сбор статистики, гистограммы)
Все действия и результаты опишите в README.md

Использована БД Northwind

## Исходный запрос

**Задача**

Вывести данные сотрудников, количество оплаченных заказов и общую сумму заказов по каждому сотруднику по годам. Отсортировать результат по сумме заказов в убывающем порядке.

**Запрос**

```
select 
    employees.*,
    a.`Количество заказов`,
    a.`Сумма заказов`
from (
	select 
		a.employee_id as 'id Работника',
		count(a.order_id) as 'Количество заказов',
		sum(a.sum) as 'Сумма заказов'
	from (
		select 
			orders.employee_id,
			YEAR(orders.order_date),
			order_details.order_id,
			(order_details.quantity * order_details.unit_price) as sum,
			order_details.discount
		from orders
		left join order_details on orders.id = order_details.order_id
		where 
			YEAR(orders.order_date) in (select distinct YEAR(order_date) from orders)
			and orders.paid_date is not null 
			and order_details.order_id is not null 
			and (order_details.quantity * order_details.unit_price) is not null 
			and order_details.discount is not null 
		order by orders.employee_id
	) as a
	group by a.employee_id
	order by 3 desc
) as a
left join employees on a.`id Работника` = employees.id
order by a.`Сумма заказов` desc;
```

**Результат запроса**

![Скриншот](/images/1_res.jpg)

## Результаты EXPLAIN

**Прострой EXPLAIN**

![Скриншот](/images/1_simple.jpg)

**EXPLAIN в формате JSON**

```
{
  "query_block": {
    "select_id": 1,
    "cost_info": {
      "query_cost": "20.07"
    },
    "nested_loop": [
      {
        "table": {
          "table_name": "a",
          "access_type": "ALL",
          "rows_examined_per_scan": 38,
          "rows_produced_per_join": 38,
          "filtered": "100.00",
          "cost_info": {
            "read_cost": "2.98",
            "eval_cost": "3.80",
            "prefix_cost": "6.78",
            "data_read_per_join": "1K"
          },
          "used_columns": [
            "id Работника",
            "Количество заказов",
            "Сумма заказов"
          ],
          "materialized_from_subquery": {
            "using_temporary_table": true,
            "dependent": false,
            "cacheable": true,
            "query_block": {
              "select_id": 2,
              "cost_info": {
                "query_cost": "34.91"
              },
              "ordering_operation": {
                "using_filesort": true,
                "grouping_operation": {
                  "using_temporary_table": true,
                  "using_filesort": false,
                  "nested_loop": [
                    {
                      "table": {
                        "table_name": "orders",
                        "access_type": "ALL",
                        "possible_keys": [
                          "PRIMARY",
                          "employee_id",
                          "employee_id_2",
                          "id",
                          "id_2",
                          "id_3"
                        ],
                        "rows_examined_per_scan": 48,
                        "rows_produced_per_join": 43,
                        "filtered": "90.00",
                        "cost_info": {
                          "read_cost": "0.73",
                          "eval_cost": "4.32",
                          "prefix_cost": "5.05",
                          "data_read_per_join": "42K"
                        },
                        "used_columns": [
                          "id",
                          "employee_id",
                          "order_date",
                          "paid_date"
                        ],
                        "attached_condition": "((`northwind`.`orders`.`paid_date` is not null) and (`northwind`.`orders`.`id` is not null))"
                      }
                    },
                    {
                      "table": {
                        "table_name": "order_details",
                        "access_type": "ref",
                        "possible_keys": [
                          "fk_order_details_orders1_idx"
                        ],
                        "key": "fk_order_details_orders1_idx",
                        "used_key_parts": [
                          "order_id"
                        ],
                        "key_length": "4",
                        "ref": [
                          "northwind.orders.id"
                        ],
                        "rows_examined_per_scan": 1,
                        "rows_produced_per_join": 38,
                        "filtered": "90.00",
                        "cost_info": {
                          "read_cost": "10.80",
                          "eval_cost": "3.89",
                          "prefix_cost": "20.17",
                          "data_read_per_join": "2K"
                        },
                        "used_columns": [
                          "id",
                          "order_id",
                          "quantity",
                          "unit_price",
                          "discount"
                        ],
                        "attached_condition": "(((`northwind`.`order_details`.`quantity` * `northwind`.`order_details`.`unit_price`) is not null) and (`northwind`.`order_details`.`discount` is not null))"
                      }
                    },
                    {
                      "table": {
                        "table_name": "<subquery4>",
                        "access_type": "eq_ref",
                        "key": "<auto_distinct_key>",
                        "key_length": "5",
                        "ref": [
                          "func"
                        ],
                        "rows_examined_per_scan": 1,
                        "attached_condition": "(year(`northwind`.`orders`.`order_date`) = `<subquery4>`.`YEAR(order_date)`)",
                        "materialized_from_subquery": {
                          "using_temporary_table": true,
                          "query_block": {
                            "table": {
                              "table_name": "orders",
                              "access_type": "ALL",
                              "rows_examined_per_scan": 48,
                              "rows_produced_per_join": 48,
                              "filtered": "100.00",
                              "cost_info": {
                                "read_cost": "0.25",
                                "eval_cost": "4.80",
                                "prefix_cost": "5.05",
                                "data_read_per_join": "46K"
                              },
                              "used_columns": [
                                "id",
                                "order_date"
                              ]
                            }
                          }
                        }
                      }
                    }
                  ]
                }
              }
            }
          }
        }
      },
      {
        "table": {
          "table_name": "employees",
          "access_type": "eq_ref",
          "possible_keys": [
            "PRIMARY"
          ],
          "key": "PRIMARY",
          "used_key_parts": [
            "id"
          ],
          "key_length": "4",
          "ref": [
            "a.id Работника"
          ],
          "rows_examined_per_scan": 1,
          "rows_produced_per_join": 38,
          "filtered": "100.00",
          "cost_info": {
            "read_cost": "9.50",
            "eval_cost": "3.80",
            "prefix_cost": "20.07",
            "data_read_per_join": "59K"
          },
          "used_columns": [
            "id",
            "company",
            "last_name",
            "first_name",
            "email_address",
            "job_title",
            "business_phone",
            "home_phone",
            "mobile_phone",
            "fax_number",
            "address",
            "city",
            "state_province",
            "zip_postal_code",
            "country_region",
            "web_page",
            "notes",
            "attachments"
          ]
        }
      }
    ]
  }
}
```

**EXPLAIN в формате TREE**

```
-> Nested loop left join  (cost=12.00 rows=0)
    -> Table scan on a  (cost=2.50..2.50 rows=0)
        -> Materialize  (cost=2.50..2.50 rows=0)
            -> Sort: `Сумма заказов` DESC
                -> Table scan on <temporary>
                    -> Aggregate using temporary table
                        -> Nested loop inner join  (cost=27.95 rows=39)
                            -> Nested loop inner join  (cost=20.17 rows=39)
                                -> Filter: ((orders.paid_date is not null) and (orders.id is not null))  (cost=5.05 rows=43)
                                    -> Table scan on orders  (cost=5.05 rows=48)
                                -> Filter: (((order_details.quantity * order_details.unit_price) is not null) and (order_details.discount is not null))  (cost=0.25 rows=1)
                                    -> Index lookup on order_details using fk_order_details_orders1_idx (order_id=orders.id)  (cost=0.25 rows=1)
                            -> Filter: (year(orders.order_date) = `<subquery4>`.`YEAR(order_date)`)  (cost=0.08..0.08 rows=1)
                                -> Single-row index lookup on <subquery4> using <auto_distinct_key> (YEAR(order_date)=year(orders.order_date))
                                    -> Materialize with deduplication  (cost=9.85..9.85 rows=48)
                                        -> Filter: (year(orders.order_date) is not null)  (cost=5.05 rows=48)
                                            -> Table scan on orders  (cost=5.05 rows=48)
    -> Single-row index lookup on employees using PRIMARY (id=a.`id Работника`)  (cost=0.25 rows=1)
```

## Оценка плана выполнения запроса

(написать)
(индексы, хинты, сбор статистики, гистограммы)

## Проблемы с запросом

1. Переусложение запроса, скриптовый стиль построения, слишком много подзапросов.
1. Лишние условия из-за некорректно подобранных джойнов.
1. Лишние сортировки внутри подзапросов.
1. Несоблюдение стандартов написания ключевых слов в запросе (всё в одном регистре, кроме названия функции извлечения года).
1. Запрос тяжело читается из-за отсутствия алиасов.
1. Избыточные вычисления. 
1. Выборка всех данных (*) из таблицы вместо определённых столбцов. Вряд ли для отчёта реально нужны все данные работников.
1. Названия столбцов кириллицей с пробелами.
1. Разные символы для ограничения названия строк.
1. Сортировка с использованием порядкового номера.

## Приёмы оптимизации запроса

- Переписать запрос, упростить, убрать лишние вычисления и столбцы.
- Вынести подзапрос в CTE для лучшей читаемости.
- Добавить краткие понятные алиасы для таблиц и столбцов.
- Избавиться от кириллических названий столбцов.
- Использовать более подходящие джойны для уменьшения объёма данных и избавления от ненужных фильтров.
- Добавим округление сумм заказов до 2 знаков после запятой.

## Результат оптимизации запроса

```
WITH orders AS (
	SELECT 
		o.employee_id,
		YEAR(o.order_date) AS order_year,
		od.order_id,
		ROUND((od.quantity * od.unit_price), 2) AS order_sum
	FROM orders AS o -- берём таблицу, где записей меньше
	INNER JOIN order_details AS od ON o.id = od.order_id -- джойним таблицу, где записей больше
	WHERE o.paid_date IS NOT NULL -- оплаченные 
) 
SELECT 
	orders.employee_id,
    orders.order_year as year,
    em.last_name,
    em.first_name,
	COUNT(orders.order_id) AS orders,
	SUM(orders.order_sum) AS sum,
    em.email_address,
    em.city
FROM orders
LEFT JOIN employees AS em ON orders.employee_id = em.id
GROUP BY orders.employee_id, year, em.last_name, em.first_name
ORDER BY year DESC, sum DESC;
```

В таблице данные представлены только за 2006 год, можно было сразу его написать, если бы у нас было партицирование по годам и нужно было только за 2006 год данные анализировать, но предполагаем, что тут могут быть разные года.

**Результат выполнения запроса**

![Скриншот](/images/2_result.jpg)

**Результаты EXPLAIN**

**Простой EXPLAIN**

![Скриншот](/images/2_simple.jpg)

**EXPLAIN c типом JSON**

```
{
  "query_block": {
    "select_id": 1,
    "cost_info": {
      "query_cost": "35.29"
    },
    "ordering_operation": {
      "using_filesort": true,
      "grouping_operation": {
        "using_temporary_table": true,
        "using_filesort": false,
        "nested_loop": [
          {
            "table": {
              "table_name": "o",
              "access_type": "ALL",
              "possible_keys": [
                "PRIMARY",
                "id",
                "id_2",
                "id_3"
              ],
              "rows_examined_per_scan": 48,
              "rows_produced_per_join": 43,
              "filtered": "90.00",
              "cost_info": {
                "read_cost": "0.73",
                "eval_cost": "4.32",
                "prefix_cost": "5.05",
                "data_read_per_join": "42K"
              },
              "used_columns": [
                "id",
                "employee_id",
                "order_date",
                "paid_date"
              ],
              "attached_condition": "(`northwind`.`o`.`paid_date` is not null)"
            }
          },
          {
            "table": {
              "table_name": "em",
              "access_type": "eq_ref",
              "possible_keys": [
                "PRIMARY"
              ],
              "key": "PRIMARY",
              "used_key_parts": [
                "id"
              ],
              "key_length": "4",
              "ref": [
                "northwind.o.employee_id"
              ],
              "rows_examined_per_scan": 1,
              "rows_produced_per_join": 43,
              "filtered": "100.00",
              "cost_info": {
                "read_cost": "10.80",
                "eval_cost": "4.32",
                "prefix_cost": "20.17",
                "data_read_per_join": "68K"
              },
              "used_columns": [
                "id",
                "last_name",
                "first_name",
                "email_address",
                "city"
              ]
            }
          },
          {
            "table": {
              "table_name": "od",
              "access_type": "ref",
              "possible_keys": [
                "fk_order_details_orders1_idx"
              ],
              "key": "fk_order_details_orders1_idx",
              "used_key_parts": [
                "order_id"
              ],
              "key_length": "4",
              "ref": [
                "northwind.o.id"
              ],
              "rows_examined_per_scan": 1,
              "rows_produced_per_join": 43,
              "filtered": "100.00",
              "cost_info": {
                "read_cost": "10.80",
                "eval_cost": "4.32",
                "prefix_cost": "35.29",
                "data_read_per_join": "2K"
              },
              "used_columns": [
                "id",
                "order_id",
                "quantity",
                "unit_price"
              ]
            }
          }
        ]
      }
    }
  }
}
```

**EXPLAIN c типом TREE**

```
-> Sort: orders.`year` DESC, sum DESC
    -> Table scan on <temporary>
        -> Aggregate using temporary table
            -> Nested loop inner join  (cost=35.29 rows=43)
                -> Nested loop left join  (cost=20.17 rows=43)
                    -> Filter: (o.paid_date is not null)  (cost=5.05 rows=43)
                        -> Table scan on o  (cost=5.05 rows=48)
                    -> Single-row index lookup on em using PRIMARY (id=o.employee_id)  (cost=0.25 rows=1)
                -> Index lookup on od using fk_order_details_orders1_idx (order_id=o.id)  (cost=0.25 rows=1)

```

**Выводы**

(написать)

**SHOW WARNINGS**

`SHOW WARNINGS` для этого запроса показал такой вывод:

```
select 
`northwind`.`o`.`employee_id` AS `employee_id`,
year(`northwind`.`o`.`order_date`) AS `year`,
`northwind`.`em`.`last_name` AS `last_name`,
`northwind`.`em`.`first_name` AS `first_name`,
count(`northwind`.`od`.`order_id`) AS `orders`,
sum(round((`northwind`.`od`.`quantity` * `northwind`.`od`.`unit_price`),2)) AS `sum`,
`northwind`.`em`.`email_address` AS `email_address`,
`northwind`.`em`.`city` AS `city` 
from `northwind`.`orders` `o` 
join `northwind`.`order_details` `od` 
left join `northwind`.`employees` `em` on((`northwind`.`em`.`id` = `northwind`.`o`.`employee_id`)) 
where ((`northwind`.`od`.`order_id` = `northwind`.`o`.`id`) and (`northwind`.`o`.`paid_date` is not null)) 
group by `northwind`.`o`.`employee_id`,`year`,`northwind`.`em`.`last_name`,`northwind`.`em`.`first_name` 
order by `year` desc,`sum` desc;
```