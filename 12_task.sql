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

-- Данная задача решается, в принципе, и без оконных ф-ций:
SELECT 
    s.year_game,
    SUM(s.points) AS sum_points
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

-- Если выводить по каждому игроку:


-- Если по суммам очков по годам, то так:
WITH cte AS (
	SELECT 
		s.year_game, 
		SUM(s.points) AS sum_points
	FROM statistic AS s
	GROUP BY s.year_game
	ORDER BY s.year_game
) 
SELECT
	year_game, 
	sum_points AS year_points,
	LAG(sum_points,1) OVER (
		ORDER BY year_game
	) AS prev_year_poins
FROM cte;

-- Результат: https://prnt.sc/UUAAepMmR1qZ 



-- Если применить другие оконные функции к этому набору (в качестве экспериментов):

-- Рейтинги игроков по годам:
SELECT
    s.year_game,
    dense_rank() OVER w AS rank,
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
    (avg(s.points) OVER w)::numeric(12,2) AS avg_points,
    s.points - (avg(s.points) OVER w)::numeric(12,2) AS delta
FROM statistic AS s
WINDOW w AS (
    PARTITION BY s.year_game
    ORDER BY s.year_game
)
ORDER BY s.year_game, s.points - (avg(s.points) OVER w)::numeric(12,2) DESC;

-- Результат: https://prnt.sc/wz9dYsLuveIv

-- Вывод самых успешных игроков по годам
WITH cte AS (   
    SELECT
        dense_rank() OVER w AS rank,
        s.year_game,
        s.player_id,
        s.player_name,
        s.points
    FROM statistic AS s
    WINDOW w AS (
        PARTITION BY s.year_game
        ORDER BY s.year_game, s.points DESC
    )
)
SELECT 
    year_game,
    player_id,
    player_name,
    points
FROM cte
WHERE rank = 1
ORDER BY year_game, points DESC;

-- Результат: https://prnt.sc/tOTcq6GSUsNg 

-- Можно вывести данные игроков с наименьшим и наибольшим числом очков по годам:
SELECT
    s.year_game,
    s.player_id,
    s.player_name,
    s.points,
    first_value(s.points) OVER w AS low_points,
    last_value(s.points) OVER w AS max_points
FROM statistic AS s
WINDOW w AS (
    PARTITION BY s.year_game
    ORDER BY s.points
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
)
ORDER BY s.year_game;

-- Результат: https://prnt.sc/HmTlf7fQJfUu
