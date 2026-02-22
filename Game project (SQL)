/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Владимиров Николай Александрович
 * Дата: 18.08.2025
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:
WITH pay_users AS
(
	SELECT 
		COUNT(id) AS count_users_pay
	FROM fantasy.users
	WHERE payer = 1
)	
SELECT 
	COUNT(id) AS count_users,
	(SELECT count_users_pay FROM pay_users) AS pay_users,
	((SELECT count_users_pay FROM pay_users)::float / COUNT(id)) AS share_pay_users --доля платящих игроков
FROM fantasy.users;
/*
count_users|pay_users|share_pay_users    |
-----------+---------+-------------------+
      22214|     3929|0.17687044206356353|     */
--Для онланй игр доля платящих игроков обычно варьируется от 2 до 10% взависимости от жанра, в нашем проекте «Секреты Темнолесья» мы имеем хороший показатель 17,6% платящих игроков

-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
WITH count_races_pay AS
(
 SELECT 
	race_id,
	COUNT(id) AS count_race_pay
 FROM fantasy.users 
 WHERE payer = 1
 GROUP BY race_id
),
count_races_users_all AS
(
 SELECT 
	race_id,
	COUNT(id) AS count_race_users
 FROM fantasy.users
 GROUP BY race_id
)
SELECT
	DISTINCT r.race,
	p.count_race_pay,
	ua.count_race_users,
	ROUND(p.count_race_pay / ua.count_race_users::numeric, 2) AS share_pay_users
FROM fantasy.users AS u 
LEFT JOIN count_races_pay AS p ON u.race_id = p.race_id
LEFT JOIN count_races_users_all AS ua ON u.race_id = ua.race_id
LEFT JOIN fantasy.race AS r ON u.race_id = r.race_id
ORDER BY p.count_race_pay DESC, ua.count_race_users DESC;


/*
race    |count_race_pay|count_race_users|share_pay_users|
--------+--------------+----------------+---------------+
Human   |          1114|            6328|           0.18|
Hobbit  |           659|            3648|           0.18|
Orc     |           636|            3619|           0.18|
Northman|           626|            3562|           0.18|
Elf     |           427|            2501|           0.17|
Demon   |           238|            1229|           0.19|
Angel   |           229|            1327|           0.17|*/

--Самая большая доля платящих игроков у расы Demon 19%, но эта раса имеет самое маленькое количество зарегистрированных пользователей.
--Разница в долях платящих игроков в разрезе рас минимальна. Минимальный 17% максимальный 19% - это указывает на внутриигровой баланс сил рас.
--Самая популярная раса среди игроков Human, число игроков 6328, платящих из них 1114.
--Стоит провести дальнейшее исследование расы Human и ее популярности и понять как можно это монетизировать.
--У расы Demon 1229 игроков платящих 238, высокая доля 19% платящих игроков может говорить о том, что раса предлагает уникальные преимущества или контент, который стимулирует игроков к покупкам. 
--Стоит провести дальнейшее исследование расы Demon и понять как можно увеличить ее популярность среди игроков.


-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
SELECT 
	COUNT(transaction_id) AS count_pays,
	SUM(amount) AS sum_pays,
	MIN(amount) AS min_amount,
	MAX(amount) AS max_amount,
	ROUND(AVG(amount)::numeric, 2) AS avg_amount,
	ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY amount)::numeric, 2) AS mediana_pay,
	ROUND(STDDEV(amount)::numeric, 2) AS std_amount
FROM fantasy.events;
/*
count_pays|sum_pays |min_amount|max_amount|avg_amount|mediana_pay|std_amount|
----------+---------+----------+----------+----------+-----------+----------+
   1307678|686615040|       0.0|  486615.1|    525.69|      74.86|   2517.35|     */

--Данные имеют аномальные нулевые покупки, нужно провести исследование и понять что это такое
--Самая большая покупка 486615.1 внутриигровой валюты, большая разница с среднем показателем всех покупок 525.69 и медианой 74.86. 
--Всего совершено 1 307 678 покупок на сумму 686 615 040 «райские лепестки» с среднем показателем всех покупок 525.69 и медианой 74.86 райских лепестков. Разница указывает на наличии игроков с большими покупками.
--Выскокое стандартное отклонение подтверждает наличие игроков с крупными покупками. Следует проанализировать такие покупки и игроков(китов), чтобы оптимизировать монитизацию. 
--В среднем игроки покупают на 525.69 райских лепестков

-- 2.2: Аномальные нулевые покупки:
WITH pays_0 AS
(
 SELECT 
	COUNT(DISTINCT transaction_id) AS count_pays_0
 FROM fantasy.events
 WHERE amount = 0
),
pays AS
(
 SELECT 
	COUNT(DISTINCT transaction_id) AS count_pays
 FROM fantasy.events
)
SELECT
	p0.count_pays_0,
	p.count_pays,
	ROUND(p0.count_pays_0::NUMERIC/p.count_pays, 4) AS share_pays_0
FROM pays_0 AS p0 
CROSS JOIN pays AS p;

/*
count_pays_0|count_pays|share_pays_0|
------------+----------+------------+
         907|   1307678|      0.0007|*/
--Аномальные покупки с нулевой стоимостью присутствуют их 907 из 1 307 678 что составляет 0.07%
--Доля транзакций с 0 стоимостью меньше 0,1%, такие данные не повлияют на отчетность, но их можно легко исключить

-- 2.3: Популярные эпические предметы:

/*Общее количество внутриигровых продаж в абсолютном и относительном значениях. 
 * Относительное значение должно быть долей продажи каждого предмета от всех продаж.
Долю игроков, которые хотя бы раз покупали этот предмет, от общего числа внутриигровых покупателей.*/
WITH count_pays_item AS
(
	SELECT
		item_code,
		COUNT(transaction_id) AS count_pays,
		COUNT(DISTINCT id) AS count_users_pay_item
	FROM fantasy.events
	GROUP BY item_code
),
total_count AS 
(
	SELECT
		COUNT(transaction_id) AS total_count
	FROM fantasy.events
),
total_users_pay AS
(
	SELECT
		COUNT(DISTINCT id) AS count_all_pay_users
	FROM fantasy.events
)
SELECT
	ci.item_code,
	i.game_items,
	ci.count_pays,
	ROUND(ci.count_pays::numeric / t.total_count, 4) AS share_counts_pay,
	ROUND(ci.count_users_pay_item::NUMERIC / up.count_all_pay_users) AS share_pay_user_item
FROM count_pays_item AS ci
LEFT JOIN fantasy.items AS i ON ci.item_code = i.item_code
CROSS JOIN total_count AS t
CROSS JOIN total_users_pay AS up
ORDER BY count_pays DESC;

/*
item_code|game_items               |count_pays|share_counts_pay|share_pay_user_item|
---------+-------------------------+----------+----------------+-------------------+
     6010|Book of Legends          |   1005423|          0.7689|                  1|
     6011|Bag of Holding           |    271875|          0.2079|                  1|
     6012|Necklace of Wisdom       |     13828|          0.0106|                  0|
     6536|Gems of Insight          |      3833|          0.0029|                  0|
     5964|Treasure Map             |      3084|          0.0024|                  0|
     4112|Amulet of Protection     |      1078|          0.0008|                  0|
     5411|Silver Flask             |       795|          0.0006|                  0|
     5691|Strength Elixir          |       580|          0.0004|                  0|
     5541|Glowing Pendant          |       563|          0.0004|                  0|
     5999|Gauntlets of Might       |       514|          0.0004|                  0|
     7995|Sea Serpent Scale        |       458|          0.0004|                  0|
     5661|Ring of Wisdom           |       379|          0.0003|                  0|
     5261|Potion of Speed          |       375|          0.0003|                  0|*/

--Самые популярные предметы для покупок у игроков это "Book of Legends" 1 005 423 продаж с долей от всех покупок 76,9 % 
-- и второй популярны предмет "Bag of Holding" 271 875 продаж с долей 20,8% от всех продаж
--Проверить, почему эти два предмета пользуются такой популярностью, может это связано с их ценой, доступностью, полезностью
--Для менее популярных предметов проанализирвоать цену, доступность, ценность, ограничения на покупку(уровень персонажа)

-- Часть 2. Решение ad hoc-задачи
-- Задача: Зависимость активности игроков от расы персонажа:

WITH total_count_users AS --количество всех игрков
(
	SELECT
		race_id,
		COUNT(DISTINCT id) AS total_users
	FROM fantasy.users
	GROUP BY race_id
),
count_users_buys AS --количество игроков совершающих внутриигровые покупки
(
	SELECT
		u.race_id,
		COUNT(DISTINCT e.id) AS count_users_buy,
		COUNT(e.transaction_id) AS count_trans,
		ROUND(AVG(e.amount)::NUMERIC, 2) AS avg_amount,
		SUM(e.amount) AS total_sum
	FROM fantasy.users AS u
	JOIN fantasy.events AS e ON u.id = e.id
	WHERE e.amount > 0
	GROUP BY race_id
),
count_users_paysOFbuys AS --количество платящих игроков совершивших внутриигровые покупки
(
	SELECT
		u.race_id,
		COUNT(DISTINCT e.id) AS count_users_pay
	FROM fantasy.users AS u
	JOIN fantasy.events AS e ON u.id = e.id
	WHERE u.payer = 1 AND e.amount > 0
	GROUP BY race_id
)
SELECT
	DISTINCT r.race,
	tu.total_users,
	ub.count_users_buy,
	ROUND(ub.count_users_buy::NUMERIC / tu.total_users, 2) AS share_user_buy,
	ROUND(up.count_users_pay::NUMERIC / ub.count_users_buy, 2) AS share_user_payOFbuys,-- доля платящих игроков среди тех кто соврешал внутриигровые покупки
	ROUND(ub.count_trans::NUMERIC / ub.count_users_buy, 2) AS avg_user_buys, --среднее количество покупок на одного игрока, совершившего внутриигровые покупки
	ub.avg_amount,
	ROUND(ub.total_sum::NUMERIC  / ub.count_users_buy, 2) AS avg_sum_buys -- средняя сумма покупки
FROM fantasy.race AS r
LEFT JOIN total_count_users AS tu ON r.race_id = tu.race_id
LEFT JOIN count_users_buys AS ub ON r.race_id = ub.race_id
LEFT JOIN count_users_paysOFbuys AS up ON r.race_id = up.race_id
ORDER BY tu.total_users DESC;

/*
race    |total_users|count_users_buy|share_user_buy|share_user_payofbuys|avg_user_buys|avg_amount|avg_sum_buys|
--------+-----------+---------------+--------------+--------------------+-------------+----------+------------+
Human   |       6328|           3921|          0.62|                0.18|       121.40|    403.13|    48935.22|
Hobbit  |       3648|           2266|          0.62|                0.18|        86.13|    552.90|    47621.80|
Orc     |       3619|           2276|          0.63|                0.17|        81.74|    510.90|    41761.03|
Northman|       3562|           2229|          0.63|                0.18|        82.10|    761.50|    62518.17|
Elf     |       2501|           1543|          0.62|                0.16|        78.79|    682.33|    53761.70|
Angel   |       1327|            820|          0.62|                0.17|       106.80|    455.68|    48665.73|
Demon   |       1229|            737|          0.60|                0.20|        77.87|    529.06|    41194.84|*/

--По выгруженным данным видно, что среднее количество покупок эпических предметов на одного игрока выше у рас "Human" 121.40 покупок и "Angel" 106.80.
--Это сильно выше, чем у других рас (например, "Demon" — 77.87)
--Можно предположить что прохождение игры за эти расы требует больше ресурсов, следует детальнее изучить внутригровой баланс этих рас и прохождение игры за эти расы
--Доля платящих игроков 16%-20% - хороший показетель если сравнивать с другими похожими проектами. 
--Высокие средние чеки внутриигровых покупок у рас "Northman" 761.50 и "Elf" 682.33 и большие общие траты внутриигровой валюты 62518.17 у "Northman" и 53761.70 у "Elf"
--Это сильно больше, чем у других рас например Human — 403.13
--Это может говорить о скоплении "китов" игроков с большими запасами внутреигровой валюты у игроков данных рас. 
--Можно ввести дополнительные поощрительные акции для таких игроков, увеличив монетизацию.































