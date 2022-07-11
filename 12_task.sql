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
