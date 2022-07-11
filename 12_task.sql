/*
Посчитать кол-во очков по всем игрокам за текущий год и за предыдущий. 

1. Создайте таблицу и наполните ее данными 
CREATE TABLE statistic( 
    player_name VARCHAR(100) NOT NULL, 
    player_id INT NOT NULL, 
    year_game SMALLINT NOT NULL CHECK (year_game > 0), 
    points DECIMAL(12,2) CHECK (points >= 0), 
    PRIMARY KEY (player_name,year_game) 
);

2. заполнить данными 
INSERT INTO statistic(player_name, player_id, year_game, points) 
    VALUES 
    ('Mike',1,2018,18), ('Jack',2,2018,14), ('Jackie',3,2018,30), ('Jet',4,2018,30), ('Luke',1,2019,16), 
    ('Mike',2,2019,14), ('Jack',3,2019,15), ('Jackie',4,2019,28), ('Jet',5,2019,25), ('Luke',1,2020,19), 
    ('Mike',2,2020,17), ('Jack',3,2020,18), ('Jackie',4,2020,29), ('Jet',5,2020,27);

3. написать запрос суммы очков с группировкой и сортировкой по годам

4. написать cte показывающее тоже самое

5. используя функцию LAG вывести кол-во очков по всем игрокам за текущий код и за предыдущий.
*/



-- 1. Таблица создана https://prnt.sc/ZqZuQS2TsKux 

-- 2. Данные добавлены https://prnt.sc/p86l096pqvGL 

-- 3. Запрос суммы очков с группировкой и сортировкой по годам

-- Простой запрос без оконных ф-ций:
SELECT 
    s.year_game,
    SUM(s.points) as sum_points
FROM statistic AS s
GROUP BY s.year_game
ORDER BY s.year_game;

-- С оконной функцией:
SELECT
    DISTINCT s.year_game,
    SUM(s.points) OVER w AS points_sum
FROM statistic AS s
WINDOW w AS (
  PARTITION BY s.year_game
)
ORDER BY s.year_game DESC;

-- Результат при выполнении обоих запросов: https://prnt.sc/orraqM6dth9Z 

-- 4. cte, показывающее то же самое (группировка и сортировка по годам)
WITH cte AS (
    SELECT
        s.year_game,
        SUM(s.points) OVER w AS points_sum
    FROM statistic AS s
    WINDOW w AS (
      PARTITION BY s.year_game
    )
)
SELECT 
    year_game,
    points_sum
FROM cte 
GROUP BY year_game, points_sum
ORDER BY year_game;

-- Результат: https://prnt.sc/QD4qrecJZEba 

-- 5. Вывод кол-ва очков по всем игрокам за текущий год и за предыдущий, используя функцию LAG
WITH cte AS (
	SELECT 
		s.year_game, 
		SUM(s.points) as sum_points
	FROM statistic AS s
	GROUP BY s.year_game
	ORDER BY s.year_game
) 
SELECT
	year_game, 
	sum_points AS year_points,
	LAG(sum_points,1) OVER (
		ORDER BY year_game
	) as prev_year_poins
FROM cte;

-- Результат: https://prnt.sc/UUAAepMmR1qZ 



-- Если применить другие оконные функции к этому набору:

-- Рейтинги игроков по годам:
SELECT
    s.year_game,
    dense_rank() over w AS rank,
    s.player_id,
    s.player_name,
    s.points
FROM statistic AS s
WINDOW w AS (
    PARTITION BY s.year_game
    ORDER BY s.points DESC
)
ORDER BY s.year_game, s.points DESC;

-- Результат: https://prnt.sc/vLnmT-7TNTqb

-- Рейтинги игроков по годам по отношению к среднему значению года (дельта):
SELECT
    s.year_game,
    s.player_id,
    s.player_name,
    s.points,
    (avg(s.points) over w)::numeric(12,2) as avg_points,
    s.points - (avg(s.points) over w)::numeric(12,2) as delta
FROM statistic AS s
WINDOW w AS (
    PARTITION BY s.year_game
    ORDER BY s.year_game
)
ORDER BY s.year_game, s.points - (avg(s.points) over w)::numeric(12,2) desc;

-- Результат: https://prnt.sc/wz9dYsLuveIv

-- Вывод самых "успешных" игроков по годам
with cte as (   
    select
        dense_rank() over w as rank,
        s.year_game,
        s.player_id,
        s.player_name,
        s.points
    from statistic AS s
    window w as (
        PARTITION BY s.year_game
        order by s.year_game, s.points desc
    )
)
select 
    year_game,
    player_id,
    player_name,
    points
from cte
where rank = 1
order by year_game, points desc;

-- Результат: https://prnt.sc/tOTcq6GSUsNg 

-- Можно вывести данные игроков с наименьшим и наибольшим числом очков по годам:
select
    s.year_game,
    s.player_id,
    s.player_name,
    s.points,
    first_value(s.points) over w as low_points,
    last_value(s.points) over w as max_points
from statistic as s
window w as (
    partition by s.year_game
    order by s.points
    rows between unbounded preceding and unbounded following
)
order by s.year_game;

-- Результат: https://prnt.sc/HmTlf7fQJfUu
